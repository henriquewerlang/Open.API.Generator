program Open.API.Generator.Test;

{$STRONGLINKTYPES ON}

uses
  Test.Insight.Framework,
  API.Generator.Test in 'Test\API.Generator.Test.pas',
  API.Generator in 'API.Generator.pas';

begin
  ReportMemoryLeaksOnShutdown := True;

  TTestInsightFramework.ExecuteTests;
end.
