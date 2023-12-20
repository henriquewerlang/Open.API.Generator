unit API.Generator.Test;

interface

uses System.Classes, System.Generics.Collections, Test.Insight.Framework, API.Generator;

type
  [TestFixture]
  TAPIGeneratorTest = class
  private
    FGenerator: TAPIGenerator;
    FLines: TList<String>;
    FOutput: TStringStream;

    function Generate(const UnitName, JSON: String): TStringStream;
    function GetClassDefinition(const ClassName: String): String;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure WhenGenerateTheFileWithoutAnyClassMustCreateADefaltUnitFile;
    [Test]
    procedure WhenTheJSONDoesntHaveTheDefinitionPropertyCantRaiseAnyErrorWhenGeneratingTheAPI;
    [Test]
    procedure WhenTheTypeDefinitionAsAnObjectDefinitionMustCreateAClassDeclarationInTheOutputFile;
    [Test]
    procedure OnlyObjectsMustBeGeneratedInTheOutputUnit;
    [Test]
    procedure WhenTheDefinitionDontHaveATypeTheDefaultTypeMustBeObject;
    [Test]
    procedure TheClassesMustBeCreatedWithThePropertiesLikeTheDefinitionFile;
    [Test]
    procedure ThePropertyMustBeDeclaredWithTheTypeInTheDefinition;
    [Test]
    procedure WhenDeclaringAClassMustDeclareAllPropertiesOfTheClass;
  end;

implementation

uses System.SysUtils, System.IOUtils;

{ TAPIGeneratorTest }

function TAPIGeneratorTest.Generate(const UnitName, JSON: String): TStringStream;
begin
  var Reader := TStreamReader.Create(FOutput);
  Result := FOutput;

  FGenerator.Load(JSON);

  FGenerator.Generate(UnitName, FOutput);

  Reader.Rewind;

  while not Reader.EndOfStream do
    FLines.Add(Reader.ReadLine);

  Reader.Free;
end;

function TAPIGeneratorTest.GetClassDefinition(const ClassName: String): String;
begin
  Result := EmptyStr;
  for var A := FLines.IndexOf(Format('  %s = class', [ClassName])) to Pred(FLines.Count) do
  begin
    Result := Result + FLines[A] + sLineBreak;

    if FLines[A] = '  end;' then
      Break;
  end;
end;

procedure TAPIGeneratorTest.OnlyObjectsMustBeGeneratedInTheOutputUnit;
begin
  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "type": "object"
        },
        "MyType": {
          "type": "string"
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Assert.IsTrue(FLines.IndexOf('  TMyClass = class') > -1);
  Assert.IsTrue(FLines.IndexOf('  TMyType = class') = -1);
end;

procedure TAPIGeneratorTest.Setup;
begin
  FGenerator := TAPIGenerator.Create;
  FLines := TList<String>.Create;
  FOutput := TStringStream.Create(EmptyStr);
end;

procedure TAPIGeneratorTest.TearDown;
begin
  FGenerator.Free;

  FLines.Free;

  FOutput.Free;
end;

procedure TAPIGeneratorTest.TheClassesMustBeCreatedWithThePropertiesLikeTheDefinitionFile;
begin
  var ExpectedClass := '''
      TMyClass = class
      private
        FMyProperty: String;
      public
        property MyProperty: String read FMyProperty write FMyProperty;
      end;

    ''';
  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "properties": {
            "MyProperty": {
              "type": "string"
            }
          }
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Assert.AreEqual(ExpectedClass, GetClassDefinition('TMyClass'));
end;

procedure TAPIGeneratorTest.ThePropertyMustBeDeclaredWithTheTypeInTheDefinition;
begin
  var ExpectedClass := '''
      TMyClass = class
      private
        FBooleanProperty: Boolean;
      public
        property BooleanProperty: Boolean read FBooleanProperty write FBooleanProperty;
      end;

    ''';
  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "properties": {
            "BooleanProperty": {
              "type": "boolean"
            }
          }
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Assert.AreEqual(ExpectedClass, GetClassDefinition('TMyClass'));
end;

procedure TAPIGeneratorTest.WhenDeclaringAClassMustDeclareAllPropertiesOfTheClass;
begin
  var ExpectedClass := '''
      TMyClass = class
      private
        FProp1: Boolean;
        FProp2: String;
        FProp3: Integer;
      public
        property Prop1: Boolean read FProp1 write FProp1;
        property Prop2: String read FProp2 write FProp2;
        property Prop3: Integer read FProp3 write FProp3;
      end;

    ''';
  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "properties": {
            "Prop1": {
              "type": "boolean"
            },
            "Prop2": {
              "type": "string"
            },
            "Prop3": {
              "type": "integer"
            }
          }
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Assert.AreEqual(ExpectedClass, GetClassDefinition('TMyClass'));
end;

procedure TAPIGeneratorTest.WhenGenerateTheFileWithoutAnyClassMustCreateADefaltUnitFile;
begin
  var UnitExpected := '''
    unit MyUnit;

    interface

    type
    implementation

    end.

    ''';

  Assert.AreEqual(UnitExpected, Generate('MyUnit', '{}').DataString);
end;

procedure TAPIGeneratorTest.WhenTheDefinitionDontHaveATypeTheDefaultTypeMustBeObject;
begin
  var JSON := '''
    {
      "definitions": {
        "MyClass": {
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Assert.IsTrue(FLines.IndexOf('  TMyClass = class') >= 0);
end;

procedure TAPIGeneratorTest.WhenTheJSONDoesntHaveTheDefinitionPropertyCantRaiseAnyErrorWhenGeneratingTheAPI;
begin
  Assert.WillNotRaise(
    procedure
    begin
      Generate('MyUnit', '{}');
    end);
end;

procedure TAPIGeneratorTest.WhenTheTypeDefinitionAsAnObjectDefinitionMustCreateAClassDeclarationInTheOutputFile;
begin
  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "type": "object"
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Assert.IsTrue(FLines.IndexOf('  TMyClass = class') >= 0);
end;

end.

