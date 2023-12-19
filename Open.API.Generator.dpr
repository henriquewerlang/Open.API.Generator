program Open.API.Generator;

uses
  Vcl.Forms,
  Main.Form in 'Main.Form.pas' {MainForm},
  API.Generator in 'API.Generator.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
