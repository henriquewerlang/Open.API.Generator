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
    [Test]
    procedure IfTheTypeDoesntExistsMustRaiseAnError;
    [Test]
    procedure WhenTheTypeOfAPropertyIsAnArrayMustDeclareThePropertyAsExpected;
    [Test]
    procedure WhenAPropertyHasAReferenceForATypeDefinitionMustLoadThePropetyAsExpected;
    [Test]
    procedure WhenTheReferenceOfAPropertyIsntDefinedMustRaiseAnError;
  end;

implementation

uses System.SysUtils, System.IOUtils;

{ TAPIGeneratorTest }

function TAPIGeneratorTest.Generate(const UnitName, JSON: String): TStringStream;
begin
  var Reader := TStreamReader.Create(FOutput);
  Result := FOutput;

  try
    FGenerator.Load(JSON);

    FGenerator.Generate(UnitName, FOutput);

    Reader.Rewind;

    while not Reader.EndOfStream do
      FLines.Add(Reader.ReadLine);
  finally
    Reader.Free;
  end;
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

procedure TAPIGeneratorTest.IfTheTypeDoesntExistsMustRaiseAnError;
begin
  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "properties": {
            "Prop": {
              "type": "wrong"
            }
          }
        }
      }
    }
    ''';

  Assert.WillRaise(
    procedure
    begin
      FGenerator.Load(JSON);
    end, EBasicTypeNotExists);
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
  var ExpectedClass :=
    '  TMyClass = class'#13#10 +
    '  private'#13#10 +
    '    FMyProperty: String;'#13#10 +
    '  public'#13#10 +
    '    property MyProperty: String read FMyProperty write FMyProperty;'#13#10 +
    '  end;'#13#10;

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
  var ExpectedClass :=
    '  TMyClass = class'#13#10 +
    '  private'#13#10 +
    '    FBooleanProperty: Boolean;'#13#10 +
    '  public'#13#10 +
    '    property BooleanProperty: Boolean read FBooleanProperty write FBooleanProperty;'#13#10 +
    '  end;'#13#10;

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

procedure TAPIGeneratorTest.WhenAPropertyHasAReferenceForATypeDefinitionMustLoadThePropetyAsExpected;
begin
  var ExpectedClass :=
    '  TMyClass = class'#13#10 +
    '  private'#13#10 +
    '    FReferenceProperty: Boolean;'#13#10 +
    '  public'#13#10 +
    '    property ReferenceProperty: Boolean read FReferenceProperty write FReferenceProperty;'#13#10 +
    '  end;'#13#10;

  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "properties": {
            "ReferenceProperty": {
              "$ref": "#/definitions/MyRef"
            }
          }
        },
        "MyRef": {
          "type": "boolean"
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Assert.AreEqual(ExpectedClass, GetClassDefinition('TMyClass'));
end;

procedure TAPIGeneratorTest.WhenDeclaringAClassMustDeclareAllPropertiesOfTheClass;
begin
  var ExpectedClass :=
    '  TMyClass = class'#13#10 +
    '  private'#13#10 +
    '    FProp1: Boolean;'#13#10 +
    '    FProp2: String;'#13#10 +
    '    FProp3: Integer;'#13#10 +
    '    FProp4: Double;'#13#10 +
    '  public'#13#10 +
    '    property Prop1: Boolean read FProp1 write FProp1;'#13#10 +
    '    property Prop2: String read FProp2 write FProp2;'#13#10 +
    '    property Prop3: Integer read FProp3 write FProp3;'#13#10 +
    '    property Prop4: Double read FProp4 write FProp4;'#13#10 +
    '  end;'#13#10;

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
            },
            "Prop4": {
              "type": "number"
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
  var UnitExpected :=
    'unit MyUnit;'#13#10 +
    #13#10 +
    'interface'#13#10 +
    #13#10 +
    'type'#13#10 +
    'implementation'#13#10 +
    #13#10 +
    'end.'#13#10;

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

procedure TAPIGeneratorTest.WhenTheReferenceOfAPropertyIsntDefinedMustRaiseAnError;
begin
  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "properties": {
            "ReferenceProperty": {
              "$ref": "#/definitions/MyRef"
            }
          }
        }
      }
    }
    ''';

  Assert.WillRaise(
    procedure
    begin
      Generate('MyUnit', JSON);
    end, EReferenceTypeNotExists);
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

procedure TAPIGeneratorTest.WhenTheTypeOfAPropertyIsAnArrayMustDeclareThePropertyAsExpected;
begin
  var ExpectedClass :=
    '  TMyClass = class'#13#10 +
    '  private'#13#10 +
    '    FProp: TArray<Boolean>;'#13#10 +
    '  public'#13#10 +
    '    property Prop: TArray<Boolean> read FProp write FProp;'#13#10 +
    '  end;'#13#10;

  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "properties": {
            "Prop": {
              "type": "array",
              "items": {
                "type": "boolean"
              }
            }
          }
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Assert.AreEqual(ExpectedClass, GetClassDefinition('TMyClass'));
end;

end.

