unit API.Generator;

interface

uses System.Classes, System.Generics.Collections;

type
  TType = class
  end;

  TProperty = class
  private
    FName: String;
    FType: TType;
  public
    property Name: String read FName write FName;
    property &Type: TType read FType write FType;
  end;

  TClassType = class(TType)
  private
    FName: String;
    FProperties: TList<TProperty>;
  public
    constructor Create(const Name: String);

    property Name: String read FName write FName;
    property Properties: TList<TProperty> read FProperties write FProperties;
  end;

  TStringType = class(TType)
  end;

  TAPIGenerator = class
  private
    FTypes: TList<TType>;
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

  function CreateType(const TypeDefinition: TJSONPair): TType;
  begin
    var Definition := TypeDefinition.JsonValue as TJSONObject;

    if Definition.Values['type'].Value = 'object' then
      Result := TClassType.Create(TypeDefinition.JsonString.Value)
    else
      Result := TStringType.Create;
  end;

begin
  var OpenAPIObject := TJSONValue.ParseJSONValue(JSON) as TJSONObject;
  var DefinitionsObject := OpenAPIObject.Values['definitions'] as TJSONObject;

  if Assigned(DefinitionsObject) then
    for var TypeDefinition in DefinitionsObject do
      FTypes.Add(CreateType(TypeDefinition));

  OpenAPIObject.Free;
end;

constructor TAPIGenerator.Create;
begin
  inherited;

  FTypes := TObjectList<TType>.Create;
end;

destructor TAPIGenerator.Destroy;
begin
  FTypes.Free;

  inherited;
end;

procedure TAPIGenerator.Generate(const UnitName: String; const Output: TStream);
begin
  var StreamWriter := TStreamWriter.Create(Output);

  StreamWriter.WriteLine('''
    unit %s;

    interface

    type
    ''', [UnitName]);

  for var AType in FTypes do
    if AType is TClassType then
      StreamWriter.WriteLine('''
          T%s = class
          end;
        ''', [TClassType(AType).Name]);

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

constructor TClassType.Create(const Name: String);
begin
  inherited Create;

  FName := Name;
end;

end.

