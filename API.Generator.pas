unit API.Generator;

interface

uses System.Classes, System.Generics.Collections, System.JSON, System.SysUtils;

type
  EBasicTypeNotExists = class(Exception);
  EReferenceTypeNotExists = class(Exception);

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

  TClassBaseType = class(TTypeDefinition)
  private
    FProperties: TList<TProperty>;
  public
    constructor Create;

    destructor Destroy; override;

    property Properties: TList<TProperty> read FProperties write FProperties;
  end;

  TClassType = class(TClassBaseType)
  end;

  TAllOfClassType = class(TTypeDefinition)
  private
    FDefinitions: TArray<TTypeDefinition>;
  public
    property Definitions: TArray<TTypeDefinition> read FDefinitions write FDefinitions;
  end;

  TAllOfSubClassType = class(TClassBaseType)
  end;

  TArrayType = class(TTypeDefinition)
  private
    FItemType: TTypeDefinition;
  public
    constructor Create;

    property ItemType: TTypeDefinition read FItemType write FItemType;
  end;

  TReferenceType = class(TTypeDefinition)
  private
    FReferenceName: String;
  public
    constructor Create(const Reference: String);

    property ReferenceName: String read FReferenceName write FReferenceName;
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

  TClassBaseTypeClass = class of TClassBaseType;

  TAPIGenerator = class
  private
    FTypes: TList<TTypeDefinition>;

    function CreateAllOfClassType(const TypeDeclaration: TJSONObject): TAllOfClassType;
    function CreateClassType(const TypeDeclaration: TJSONObject; const ClassType: TClassBaseTypeClass): TClassBaseType;
    function CreateType(const TypeDeclaration: TJSONObject; const ClassType: TClassBaseTypeClass): TTypeDefinition;
    function CreateTypeDefinition(const TypeDeclaration: TJSONPair): TTypeDefinition;
    function FindReferenceType(const ReferenceType: TReferenceType): TTypeDefinition;
    function FindTypeDefinition(const Name: String): TTypeDefinition;
    function FixDeclarationName(const Name: String): String;
    function IsClassDeclaration(const TypeDefinition: TTypeDefinition): Boolean;
    function IsObjectDeclaration(const &Type: TJSONValue): Boolean;

    procedure GenerateClassName(const ParentClass, TheClass: TTypeDefinition; const ClassName: String);
    procedure GeneratePropertyClassName(const TheClass: TClassType);
    procedure LoadProperties(const TheClass: TClassBaseType; const TypeDeclaration: TJSONObject);
  public
    constructor Create;

    destructor Destroy; override;

    procedure Generate(const UnitName: String; const Output: TStream); overload;
    procedure Generate(const UnitFileName: String); overload;
    procedure Load(const JSON: String);
    procedure LoadFromFile(const FileName: String);
  end;

implementation

uses System.IOUtils, System.Character;

{ TAPIGenerator }

procedure TAPIGenerator.Load(const JSON: String);
begin
  var OpenAPIObject := TJSONValue.ParseJSONValue(JSON, True, True) as TJSONObject;

  var DefinitionsObject := OpenAPIObject.Values['definitions'] as TJSONObject;

  try
    if Assigned(DefinitionsObject) then
      for var TypeDefinition in DefinitionsObject do
        CreateTypeDefinition(TypeDefinition);
  finally
    OpenAPIObject.Free;
  end;
end;

constructor TAPIGenerator.Create;
begin
  inherited;

  FTypes := TObjectList<TTypeDefinition>.Create;
end;

function TAPIGenerator.CreateAllOfClassType(const TypeDeclaration: TJSONObject): TAllOfClassType;
begin
  Result := TAllOfClassType.Create;

  for var Item in TypeDeclaration.Values['allOf'] as TJSONArray do
    Result.Definitions := Result.Definitions + [CreateType(Item as TJSONObject, TAllOfSubClassType)];
end;

function TAPIGenerator.CreateClassType(const TypeDeclaration: TJSONObject; const ClassType: TClassBaseTypeClass): TClassBaseType;
begin
  Result := ClassType.Create;

  try
    LoadProperties(Result, TypeDeclaration);
  except
    Result.Free;

    raise;
  end;
end;

function TAPIGenerator.CreateType(const TypeDeclaration: TJSONObject; const ClassType: TClassBaseTypeClass): TTypeDefinition;
begin
  var AllOf := TypeDeclaration.Values['allOf'];
  var Reference := TypeDeclaration.Values['$ref'];
  var &Type := TypeDeclaration.Values['type'];

  if Assigned(Reference) then
    Result := TReferenceType.Create(Reference.Value)
  else if Assigned(AllOf) then
    Result := CreateAllOfClassType(TypeDeclaration)
  else if IsObjectDeclaration(&Type) then
    Result := CreateClassType(TypeDeclaration, ClassType)
  else if &Type.Value = 'boolean' then
    Result := TBooleanType.Create
  else if &Type.Value = 'integer' then
    Result := TIntegerType.Create
  else if &Type.Value = 'number' then
    Result := TNumberType.Create
  else if &Type.Value = 'string' then
    Result := TStringType.Create
  else if &Type.Value = 'array' then
  begin
    var ArrayType := TArrayType.Create;
    ArrayType.ItemType := CreateType(TypeDeclaration.Get('items').JsonValue as TJSONObject, ClassType);

    Result := ArrayType;
  end
  else
    raise EBasicTypeNotExists.CreateFmt('The basic type %s declared don''t exsits!', [&Type.Value]);

  FTypes.Add(Result);
end;

function TAPIGenerator.CreateTypeDefinition(const TypeDeclaration: TJSONPair): TTypeDefinition;
begin
  var TypeName := TypeDeclaration.JsonString.Value;

  Result := FindTypeDefinition(TypeName);

  if not Assigned(Result) then
  begin
    Result := CreateType(TypeDeclaration.JsonValue as TJSONObject, TClassType);
    Result.Name := TypeName;

    if IsClassDeclaration(Result) then
    begin
      Result.DelphiName := 'T' + Result.Name;

      if Result is TClassType then
        GeneratePropertyClassName(TClassType(Result));
    end;
  end;
end;

destructor TAPIGenerator.Destroy;
begin
  FTypes.Free;

  inherited;
end;

function TAPIGenerator.FindReferenceType(const ReferenceType: TReferenceType): TTypeDefinition;
begin
  Result := FindTypeDefinition(ReferenceType.ReferenceName);

  if not Assigned(Result) then
    raise EReferenceTypeNotExists.CreateFmt('The reference type %s isn''t defined!', [ReferenceType.ReferenceName]);
end;

function TAPIGenerator.FindTypeDefinition(const Name: String): TTypeDefinition;
begin
  for var TypeDefinition in FTypes do
    if TypeDefinition.Name = Name then
      Exit(TypeDefinition);

  Result := nil;
end;

function TAPIGenerator.FixDeclarationName(const Name: String): String;
begin
  Result := Name[1].ToUpper + Name.SubString(1);
end;

procedure TAPIGenerator.Generate(const UnitFileName: String);
begin
  var OutputFile := TFile.Open(UnitFileName, TFileMode.fmOpenOrCreate);

  try
    Generate(TPath.GetFileNameWithoutExtension(UnitFileName), OutputFile);
  finally
    OutputFile.Free;
  end;
end;

procedure TAPIGenerator.GenerateClassName(const ParentClass, TheClass: TTypeDefinition; const ClassName: String);
begin
  TheClass.DelphiName := ParentClass.DelphiName + FixDeclarationName(ClassName);

  if TheClass is TClassType then
    GeneratePropertyClassName(TClassType(TheClass));
end;

procedure TAPIGenerator.GeneratePropertyClassName(const TheClass: TClassType);
begin
  for var PropertyDeclaration in TheClass.Properties do
    if IsClassDeclaration(PropertyDeclaration.&Type) then
      GenerateClassName(TheClass, PropertyDeclaration.&Type, PropertyDeclaration.Name);
end;

function TAPIGenerator.IsClassDeclaration(const TypeDefinition: TTypeDefinition): Boolean;
begin
  Result := (TypeDefinition is TClassType) or (TypeDefinition is TAllOfClassType);
end;

function TAPIGenerator.IsObjectDeclaration(const &Type: TJSONValue): Boolean;
begin
  Result := not Assigned(&Type) or (&Type.Value = 'object');
end;

procedure TAPIGenerator.Generate(const UnitName: String; const Output: TStream);
var
  StreamWriter: TStreamWriter;

  function GetTypeDeclaration(const &Type: TTypeDefinition): String;
  begin
    Result := &Type.DelphiName;

    if &Type is TArrayType then
      Result := Result + '<' + GetTypeDeclaration(TArrayType(&Type).ItemType) + '>'
    else if &Type is TReferenceType then
      Result := GetTypeDeclaration(FindReferenceType(TReferenceType(&Type)));
  end;

  procedure GenerateClassProperties(const AClass: TTypeDefinition; const Properties: TList<TProperty>);
  begin
    StreamWriter.WriteLine('  %s = class', [AClass.DelphiName]);

    if not Properties.IsEmpty then
    begin
      StreamWriter.WriteLine('  private');

      for var AProperty in Properties do
        StreamWriter.WriteLine('    F%s: %s;', [FixDeclarationName(AProperty.Name), GetTypeDeclaration(AProperty.&Type)]);

      StreamWriter.WriteLine('  public');

      for var AProperty in Properties do
        StreamWriter.WriteLine('    property %0:s: %1:s read F%2:s write F%2:s;', [AProperty.Name, GetTypeDeclaration(AProperty.&Type), FixDeclarationName(AProperty.Name)]);
    end;

    StreamWriter.WriteLine('  end;'#13#10);
  end;

  procedure GenerateClass(const AClass: TClassType);
  begin
    GenerateClassProperties(AClass, AClass.Properties);
  end;

  procedure GenerateAllOfClass(const AClass: TAllOfClassType);
  begin
    var Properties := TList<TProperty>.Create;

    for var TypeDefinition in AClass.Definitions do
      if TypeDefinition is TClassBaseType then
        Properties.AddRange(TClassBaseType(TypeDefinition).Properties)
      else if TypeDefinition is TReferenceType then
        Properties.AddRange((FindReferenceType(TReferenceType(TypeDefinition)) as TClassBaseType).Properties);

    GenerateClassProperties(AClass, Properties);

    Properties.Free;
  end;

begin
  StreamWriter := TStreamWriter.Create(Output, TEncoding.UTF8);

  try
    StreamWriter.Write(
      'unit %s;'#13#10 +
      #13#10 +
      'interface'#13#10 +
      #13#10 +
      'type'#13#10, [UnitName]);

    for var AType in FTypes do
      if IsClassDeclaration(AType) then
        StreamWriter.WriteLine(Format('  %s = class;', [AType.DelphiName]));

    StreamWriter.WriteLine;

    for var AType in FTypes do
      if AType is TClassType then
        GenerateClass(TClassType(AType))
      else if AType is TAllOfClassType then
        GenerateAllOfClass(TAllOfClassType(AType));

    StreamWriter.Write(
      'implementation'#13#10 +
      #13#10 +
      'end.'#13#10);
  finally
    StreamWriter.Free;
  end;
end;

procedure TAPIGenerator.LoadFromFile(const FileName: String);
begin
  Load(TFile.ReadAllText(FileName));
end;

procedure TAPIGenerator.LoadProperties(const TheClass: TClassBaseType; const TypeDeclaration: TJSONObject);
begin
  var Properties := TypeDeclaration.Get('properties');

  if Assigned(Properties) then
    for var PropertyDefinition in Properties.JsonValue as TJSONObject do
    begin
      var NewProperty := TProperty.Create;
      NewProperty.Name := PropertyDefinition.JsonString.Value;

      TheClass.Properties.Add(NewProperty);

      NewProperty.&Type := CreateType(TJSONObject(PropertyDefinition.JsonValue), TClassBaseTypeClass(TheClass.ClassType));
    end;
end;

{ TClassBaseType }

constructor TClassBaseType.Create;
begin
  FProperties := TObjectList<TProperty>.Create;
end;

destructor TClassBaseType.Destroy;
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

{ TArrayType }

constructor TArrayType.Create;
begin
  DelphiName := 'TArray';
  Name := 'array';
end;

{ TReferenceType }

constructor TReferenceType.Create(const Reference: String);
begin
  var List := Reference.Split(['/']);

  FReferenceName := List[High(List)];
end;

end.

