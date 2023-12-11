unit Main.Form;

interface

uses Vcl.Forms, System.Classes, Vcl.Controls, Vcl.StdCtrls;

type
  TMainForm = class(TForm)
    OpenAPIVersion: TComboBox;
    lblOpenAPIVersion: TLabel;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

end.
