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

