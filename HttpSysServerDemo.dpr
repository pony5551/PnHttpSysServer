program HttpSysServerDemo;

{$APPTYPE CONSOLE}

{$R *.res}

//使用Synopse优化字符copy
{$I Synopse.inc}

uses
  System.SysUtils,
  SynCommons,
  SynZip,
  System.Classes,
  uPnHttpSys.Api in 'uPnHttpSys.Api.pas',
  uPnHttpSysServer in 'uPnHttpSysServer.pas',
  uPnHttpSys.Comm in 'uPnHttpSys.Comm.pas';

type
  TTestServer = class
  protected
    fServer: TPnHttpSysServer;
    function Process(Ctxt: TPnHttpServerContext): Cardinal;
  public
    constructor Create;
    destructor Destroy; override;
  end;

{ TTestServer }
constructor TTestServer.Create;
begin
  fServer := TPnHttpSysServer.Create(0,1000);
  fServer.AddUrl('/','8080',false,'+',true);
  fServer.RegisterCompress(CompressDeflate);
  fServer.OnRequest := Process;
  fServer.HTTPQueueLength := 100000;
  fServer.MaxConnections := 100000;
  fServer.Start;
end;

destructor TTestServer.Destroy;
begin
  fServer.Free;
  inherited;
end;

function TTestServer.Process(Ctxt: TPnHttpServerContext): Cardinal;
//var
//  sList: TStringList;
begin
//  sList := TStringList.Create;
//  sList.LoadFromFile('admin_index_Default.html', TEncoding.UTF8);
//  Ctxt.OutContent := StringToUTF8(sList.Text);
//  sList.Free;
  Ctxt.OutContent := 'hello world';
  Ctxt.OutContentType := HTML_CONTENT_TYPE;
  result := 200;
  Exit;
end;



begin
  ReportMemoryLeaksOnShutDown := True;

  with TTestServer.Create do
  try
    write('Server is now running on http://localhost:8080/'#13#10#13#10+
      'Press [Enter] to quit');
    readln;
  finally
    Free;
  end;
end.
