unit Main.Form;

interface

uses Vcl.Forms, System.Classes, Vcl.Controls, Vcl.StdCtrls, Vcl.Dialogs;

type
  TMainForm = class(TForm)
    SelectFiles: TButton;
    Files: TOpenDialog;
    SaveFile: TSaveDialog;
    procedure SelectFilesClick(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses System.IOUtils, API.Generator;

{ TMainForm }

procedure TMainForm.SelectFilesClick(Sender: TObject);
begin
  var Generator := TAPIGenerator.Create;

  if Files.Execute then
    for var FileName in Files.Files do
      Generator.LoadFromFile(FileName);

  if SaveFile.Execute then
    Generator.Generate(SaveFile.FileName);
end;

end.
