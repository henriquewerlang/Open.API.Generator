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

    function Generate(const UnitName, JSON: String): String;
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
    procedure WhenTheItemTypeOfAnArrayIsAReferenceTypeMustDeclareTheArrayWithTheReferenceName;
    [Test]
    procedure WhenAPropertyHasAReferenceForATypeDefinitionMustLoadThePropetyAsExpected;
    [Test]
    procedure WhenTheReferenceOfAPropertyIsntDefinedMustRaiseAnError;
    [Test]
    procedure WhenTheJSONHasAllOfTypeMustGenerateAClassWithAllPropertiesInThisSection;
    [Test]
    procedure WhenAnAllOfClassHasAReferenceToATypeMustLoadThePropertiesFromThisReferenceToGenerateTheClassDeclaration;
    [Test]
    procedure WhenTheClassHasntAnyPropertyMustCreateOnlyTheClassDeclaration;
    [Test]
    procedure WhenGeneratingTheUnitMustDeclareTheClassAliasOfAllClassesInTheDefinition;
    [Test]
    procedure WhenGenerateAnUnitUsingTheFileNameMustGenerateTheUnitWithTheFileName;
    [Test]
    procedure WhenAClassDeclarationHasAnotherClassDeclarationInsideMustGenerateTheClassesWithTheParentClassNameInTheClassName;
    [Test]
    procedure WhenThePropertyIsLowerCaseMustFixTheFieldDeclarationToTheNameExpectedByDelphi;
    [Test]
    procedure WhenTheSubclassDeclarationIsLowerCaseMustFixTheClassNameDeclaration;
    [Test]
    procedure WhenAnAllOfDeclarationHasASubObjectDeclarationTheClassGeneratedCantBeDeclaratedInTheGeneretedUnit;
    [Test]
    procedure WhenLoadMoreThenOnceTheJSONCantDuplicateTheTypesDeclaration;
    [Test]
    procedure WhenAPropertyUseAnEspecialNameMustScapeThePropertyName;
  end;

implementation

uses System.SysUtils, System.IOUtils;

{ TAPIGeneratorTest }

function TAPIGeneratorTest.Generate(const UnitName, JSON: String): String;
begin
  var Reader := TStreamReader.Create(FOutput);

  try
    FGenerator.Load(JSON);

    FGenerator.Generate(UnitName, FOutput);

    Reader.Rewind;

    while not Reader.EndOfStream do
      FLines.Add(Reader.ReadLine);

    Reader.Rewind;

    Result := Reader.ReadToEnd;
  finally
    Reader.Free;
  end;
end;

function TAPIGeneratorTest.GetClassDefinition(const ClassName: String): String;
begin
  Result := EmptyStr;
  var StartIndex := FLines.IndexOf(Format('  %s = class', [ClassName]));

  if StartIndex > -1 then
    for var A := StartIndex to Pred(FLines.Count) do
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

procedure TAPIGeneratorTest.WhenAClassDeclarationHasAnotherClassDeclarationInsideMustGenerateTheClassesWithTheParentClassNameInTheClassName;
begin
  var ExpectedClass :=
    '  TMyClassInsideAnotherClass = class'#13#10 +
    '  private'#13#10 +
    '    FProp: Boolean;'#13#10 +
    '  public'#13#10 +
    '    property Prop: Boolean read FProp write FProp;'#13#10 +
    '  end;'#13#10;

  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "type": "object",
          "properties": {
            "Inside": {
              "type": "object",
              "properties": {
                "AnotherClass": {
                  "type": "object",
                  "properties": {
                    "Prop": {
                      "type": "boolean"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Assert.AreEqual(ExpectedClass, GetClassDefinition('TMyClassInsideAnotherClass'));
end;

procedure TAPIGeneratorTest.WhenAnAllOfClassHasAReferenceToATypeMustLoadThePropertiesFromThisReferenceToGenerateTheClassDeclaration;
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
          "allOf": [
            {
              "$ref": "#/definitions/MyRef"
            }
          ]
        },
        "MyRef": {
          "type": "object",
          "properties": {
            "ReferenceProperty": {
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

procedure TAPIGeneratorTest.WhenAnAllOfDeclarationHasASubObjectDeclarationTheClassGeneratedCantBeDeclaratedInTheGeneretedUnit;
begin
  var ExpectedUnit :=
    'unit MyUnit;'#13#10 +
    #13#10 +
    'interface'#13#10 +
    #13#10 +
    'type'#13#10 +
    '  TMyClass = class;'#13#10 +
    #13#10 +
    '  TMyClass = class'#13#10 +
    '  private'#13#10 +
    '    FProp1: String;'#13#10 +
    '    FProp2: String;'#13#10 +
    '    FProp3: String;'#13#10 +
    '  public'#13#10 +
    '    property Prop1: String read FProp1 write FProp1;'#13#10 +
    '    property Prop2: String read FProp2 write FProp2;'#13#10 +
    '    property Prop3: String read FProp3 write FProp3;'#13#10 +
    '  end;'#13#10 +
    #13#10 +
    'implementation'#13#10 +
    #13#10 +
    'end.'#13#10;

  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "allOf": [
            {
              "type": "object",
              "properties": {
                "Prop1": {
                  "type": "string"
                }
              }
            },
            {
              "type": "object",
              "properties": {
                "Prop2": {
                  "type": "string"
                }
              }
            },
            {
              "type": "object",
              "properties": {
                "Prop3": {
                  "type": "string"
                }
              }
            }
          ]
        }
      }
    }
    ''';

  Assert.AreEqual(ExpectedUnit, Generate('MyUnit', JSON));
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

procedure TAPIGeneratorTest.WhenAPropertyUseAnEspecialNameMustScapeThePropertyName;
begin
  var ExpectedClass :=
    '  TMyClass = class'#13#10 +
    '  private'#13#10 +
    '    FUnit: Boolean;'#13#10 +
    '    FProperty: String;'#13#10 +
    '    FType: Integer;'#13#10 +
    '    FRecord: Double;'#13#10 +
    '  public'#13#10 +
    '    property &Unit: Boolean read FUnit write FUnit;'#13#10 +
    '    property &Property: String read FProperty write FProperty;'#13#10 +
    '    property &type: Integer read FType write FType;'#13#10 +
    '    property &record: Double read FRecord write FRecord;'#13#10 +
    '  end;'#13#10;

  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "properties": {
            "Unit": {
              "type": "boolean"
            },
            "Property": {
              "type": "string"
            },
            "type": {
              "type": "integer"
            },
            "record": {
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

procedure TAPIGeneratorTest.WhenGenerateAnUnitUsingTheFileNameMustGenerateTheUnitWithTheFileName;
begin
  var ExpectedUnit :=
    'unit %s;'#13#10 +
    #13#10 +
    'interface'#13#10 +
    #13#10 +
    'type'#13#10 +
    '  TMyClass = class;'#13#10 +
    #13#10 +
    '  TMyClass = class'#13#10 +
    '  end;'#13#10 +
    #13#10 +
    'implementation'#13#10 +
    #13#10 +
    'end.'#13#10;
  var FileName := TPath.GetTempFileName;
  var JSON := '''
    {
      "definitions": {
        "MyClass": {
        }
      }
    }
    ''';

  FGenerator.Load(JSON);

  FGenerator.Generate(FileName);

  Assert.AreEqual(Format(ExpectedUnit, [TPath.GetFileNameWithoutExtension(FileName)]), TFile.ReadAllText(FileName));
end;

procedure TAPIGeneratorTest.WhenGenerateTheFileWithoutAnyClassMustCreateADefaltUnitFile;
begin
  var UnitExpected :=
    'unit MyUnit;'#13#10 +
    #13#10 +
    'interface'#13#10 +
    #13#10 +
    'type'#13#10 +
    #13#10 +
    'implementation'#13#10 +
    #13#10 +
    'end.'#13#10;

  Assert.AreEqual(UnitExpected, Generate('MyUnit', '{}'));
end;

procedure TAPIGeneratorTest.WhenGeneratingTheUnitMustDeclareTheClassAliasOfAllClassesInTheDefinition;
begin
  var ExpectedUnit :=
    'unit MyUnit;'#13#10 +
    #13#10 +
    'interface'#13#10 +
    #13#10 +
    'type'#13#10 +
    '  TMyClass = class;'#13#10 +
    #13#10 +
    '  TMyClass = class'#13#10 +
    '  end;'#13#10 +
    #13#10 +
    'implementation'#13#10 +
    #13#10 +
    'end.'#13#10;

  var JSON := '''
    {
      "definitions": {
        "MyClass": {
        }
      }
    }
    ''';

  Assert.AreEqual(ExpectedUnit, Generate('MyUnit', JSON));
end;

procedure TAPIGeneratorTest.WhenLoadMoreThenOnceTheJSONCantDuplicateTheTypesDeclaration;
begin
  var ExpectedUnit :=
    'unit MyUnit;'#13#10 +
    #13#10 +
    'interface'#13#10 +
    #13#10 +
    'type'#13#10 +
    '  TMyClass = class;'#13#10 +
    #13#10 +
    '  TMyClass = class'#13#10 +
    '  end;'#13#10 +
    #13#10 +
    'implementation'#13#10 +
    #13#10 +
    'end.'#13#10;
  var JSON := '''
    {
      "definitions": {
        "MyClass": {
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Generate('MyUnit', JSON);

  FOutput.Size := 0;

  Assert.AreEqual(ExpectedUnit, Generate('MyUnit', JSON));
end;

procedure TAPIGeneratorTest.WhenTheClassHasntAnyPropertyMustCreateOnlyTheClassDeclaration;
begin
  var ExpectedClass :=
    '  TMyClass = class'#13#10 +
    '  end;'#13#10;

  var JSON := '''
    {
      "definitions": {
        "MyClass": {
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Assert.AreEqual(ExpectedClass, GetClassDefinition('TMyClass'));
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

procedure TAPIGeneratorTest.WhenTheItemTypeOfAnArrayIsAReferenceTypeMustDeclareTheArrayWithTheReferenceName;
begin
  var ExpectedClass :=
    '  TMyClass = class'#13#10 +
    '  private'#13#10 +
    '    FProp: TArray<TMyRef>;'#13#10 +
    '  public'#13#10 +
    '    property Prop: TArray<TMyRef> read FProp write FProp;'#13#10 +
    '  end;'#13#10;

  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "properties": {
            "Prop": {
              "type": "array",
              "items": {
                "$ref": "#/definitions/MyRef"
              }
            }
          }
        },
        "MyRef": {
          "type": "object",
          "properties": {
            "ReferenceProperty": {
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

procedure TAPIGeneratorTest.WhenTheJSONDoesntHaveTheDefinitionPropertyCantRaiseAnyErrorWhenGeneratingTheAPI;
begin
  Assert.WillNotRaise(
    procedure
    begin
      Generate('MyUnit', '{}');
    end);
end;

procedure TAPIGeneratorTest.WhenTheJSONHasAllOfTypeMustGenerateAClassWithAllPropertiesInThisSection;
begin
  var ExpectedClass :=
    '  TMyClass = class'#13#10 +
    '  private'#13#10 +
    '    FProp1: String;'#13#10 +
    '    FProp2: String;'#13#10 +
    '    FProp3: String;'#13#10 +
    '  public'#13#10 +
    '    property Prop1: String read FProp1 write FProp1;'#13#10 +
    '    property Prop2: String read FProp2 write FProp2;'#13#10 +
    '    property Prop3: String read FProp3 write FProp3;'#13#10 +
    '  end;'#13#10;

  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "allOf": [
            {
              "type": "object",
              "properties": {
                "Prop1": {
                  "type": "string"
                }
              }
            },
            {
              "type": "object",
              "properties": {
                "Prop2": {
                  "type": "string"
                }
              }
            },
            {
              "type": "object",
              "properties": {
                "Prop3": {
                  "type": "string"
                }
              }
            }
          ]
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Assert.AreEqual(ExpectedClass, GetClassDefinition('TMyClass'));
end;

procedure TAPIGeneratorTest.WhenThePropertyIsLowerCaseMustFixTheFieldDeclarationToTheNameExpectedByDelphi;
begin
  var ExpectedClass :=
    '  TMyClass = class'#13#10 +
    '  private'#13#10 +
    '    FPropertyName: Boolean;'#13#10 +
    '  public'#13#10 +
    '    property propertyName: Boolean read FPropertyName write FPropertyName;'#13#10 +
    '  end;'#13#10;

  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "properties": {
            "propertyName": {
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

procedure TAPIGeneratorTest.WhenTheSubclassDeclarationIsLowerCaseMustFixTheClassNameDeclaration;
begin
  var ExpectedClass :=
    '  TMyClassInsideAnotherClass = class'#13#10 +
    '  private'#13#10 +
    '    FProp: Boolean;'#13#10 +
    '  public'#13#10 +
    '    property Prop: Boolean read FProp write FProp;'#13#10 +
    '  end;'#13#10;

  var JSON := '''
    {
      "definitions": {
        "MyClass": {
          "type": "object",
          "properties": {
            "inside": {
              "type": "object",
              "properties": {
                "anotherClass": {
                  "type": "object",
                  "properties": {
                    "Prop": {
                      "type": "boolean"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    ''';

  Generate('MyUnit', JSON);

  Assert.AreEqual(ExpectedClass, GetClassDefinition('TMyClassInsideAnotherClass'));
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

