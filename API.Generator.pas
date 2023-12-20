unit API.Generator;

interface

uses System.Classes, System.Generics.Collections;

type
  TTypeDefinition = class
  private
    FDelphiName: String;
    FName: String;
  public
    property DelphiName: String read FDelphiName write FDelphiName;
    property Name: String read FName write FName;
  end;

  TProperty = class
  private
    FName: String;
    FType: TTypeDefinition;
  public
    property Name: String read FName write FName;
    property &Type: TTypeDefinition read FType write FType;
  end;

  TClassType = class(TTypeDefinition)
  private
    FProperties: TList<TProperty>;
  public
    constructor Create;

    destructor Destroy; override;

    property Properties: TList<TProperty> read FProperties write FProperties;
  end;

  TBooleanType = class(TTypeDefinition)
  public
    constructor Create;
  end;

  TIntegerType = class(TTypeDefinition)
  public
    constructor Create;
  end;

  TNumberType = class(TTypeDefinition)
  public
    constructor Create;
  end;

  TStringType = class(TTypeDefinition)
  public
    constructor Create;
  end;

  TAPIGenerator = class
  private
    FTypes: TList<TTypeDefinition>;
  public
    constructor Create;

    destructor Destroy; override;

    procedure Generate(const UnitName: String; const Output: TStream);
    procedure Load(const JSON: String);
    procedure LoadFromFile(const FileName: String);
  end;

implementation

uses System.SysUtils, System.IOUtils, System.JSON;

{ TAPIGenerator }

procedure TAPIGenerator.Load(const JSON: String);

  function FindType(const TypeName: String): TTypeDefinition;
  begin
    Result := nil;

    for var TypeDefinition in FTypes do
      if TypeDefinition.Name = TypeName then
        Exit(TypeDefinition);
  end;

  function CreateClassType(const TypeDefinition: TJSONPair): TClassType;
  begin
    var PropertiesDefinition := TJSONObject(TypeDefinition.JsonValue).GetValue('properties') as TJSONObject;
    Result := TClassType.Create;
    Result.DelphiName := 'T' + TypeDefinition.JsonString.Value;

    if Assigned(PropertiesDefinition) then
      for var PropertyDefinition in PropertiesDefinition do
      begin
        var NewProperty := TProperty.Create;
        NewProperty.Name := PropertyDefinition.JsonString.Value;
        NewProperty.&Type := FindType(TJSONObject(PropertyDefinition.JsonValue).GetValue('type').Value);

        Result.Properties.Add(NewProperty);
      end;
  end;

  function CreateType(const TypeDefinition: TJSONPair): TTypeDefinition;
  begin
    var Definition := TypeDefinition.JsonValue as TJSONObject;
    var &Type := Definition.Values['type'];

    if not Assigned(&Type) or (&Type.Value = 'object') then
      Result := CreateClassType(TypeDefinition)
    else
      Result := TStringType.Create;

    Result.Name := TypeDefinition.JsonString.Value;
  end;

begin
  var OpenAPIObject := TJSONValue.ParseJSONValue(JSON, True, True) as TJSONObject;

  var DefinitionsObject := OpenAPIObject.Values['definitions'] as TJSONObject;

  if Assigned(DefinitionsObject) then
    for var TypeDefinition in DefinitionsObject do
      FTypes.Add(CreateType(TypeDefinition));

  OpenAPIObject.Free;
end;

constructor TAPIGenerator.Create;
begin
  inherited;

  FTypes := TObjectList<TTypeDefinition>.Create;

  FTypes.Add(TBooleanType.Create);

  FTypes.Add(TIntegerType.Create);

  FTypes.Add(TNumberType.Create);

  FTypes.Add(TStringType.Create);
end;

destructor TAPIGenerator.Destroy;
begin
  FTypes.Free;

  inherited;
end;

procedure TAPIGenerator.Generate(const UnitName: String; const Output: TStream);
var
  StreamWriter: TStreamWriter;

  procedure GenerateClass(AClass: TClassType);
  begin
    StreamWriter.WriteLine('  %s = class', [AClass.DelphiName]);

    StreamWriter.WriteLine('  private');

    for var AProperty in AClass.Properties do
      StreamWriter.WriteLine('    F%s: %s;', [AProperty.Name, AProperty.&Type.DelphiName]);

    StreamWriter.WriteLine('  public');

    for var AProperty in AClass.Properties do
      StreamWriter.WriteLine('    property %0:s: %1:s read F%0:s write F%0:s;', [AProperty.Name, AProperty.&Type.DelphiName]);

    StreamWriter.WriteLine('  end;');
  end;

begin
  StreamWriter := TStreamWriter.Create(Output);

  StreamWriter.WriteLine('''
    unit %s;

    interface

    type
    ''', [UnitName]);

  for var AType in FTypes do
    if AType is TClassType then
      GenerateClass(TClassType(AType));

  StreamWriter.WriteLine('''
    implementation

    end.
    ''');

  StreamWriter.Free;
end;

procedure TAPIGenerator.LoadFromFile(const FileName: String);
begin
  Load(TFile.ReadAllText(FileName));
end;

{ TClassType }

constructor TClassType.Create;
begin
  FProperties := TObjectList<TProperty>.Create;
end;

destructor TClassType.Destroy;
begin
  FProperties.Free;

  inherited;
end;

{ TBooleanType }

constructor TBooleanType.Create;
begin
  DelphiName := 'Boolean';
  Name := 'boolean';
end;

{ TIntegerType }

constructor TIntegerType.Create;
begin
  DelphiName := 'Integer';
  Name := 'integer';
end;

{ TNumberType }

constructor TNumberType.Create;
begin
  DelphiName := 'Double';
  Name := 'number';
end;

{ TStringType }

constructor TStringType.Create;
begin
  DelphiName := 'String';
  Name := 'string';
end;

end.

