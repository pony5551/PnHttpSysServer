unit ufrmMainEx;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.AppEvnts, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Buttons,
  SynCommons,
  SynZip,
  qlog, qstring,
  uPnHttpSysServer;

type
  TfrmMainEx = class(TForm)
    ApplicationEvents1: TApplicationEvents;
    pnl1: TPanel;
    pnl2: TPanel;
    pnl3: TPanel;
    mmo1: TMemo;
    chkLog: TCheckBox;
    lnklblLocalUrl: TLinkLabel;
    pnl4: TPanel;
    lbl1: TLabel;
    lbl2: TLabel;
    tmr1: TTimer;
    lbl3: TLabel;
    lbl4: TLabel;
    lblCopyRight: TLinkLabel;
    lbl5: TLabel;
    Label1: TLabel;
    pnl5: TPanel;
    pnl6: TPanel;
    btnStart: TBitBtn;
    btnStop: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure lnklblLocalUrlLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure tmr1Timer(Sender: TObject);
  private
    { Private declarations }
    FLogPath: string;
    m_StartRun, m_LastRun: Cardinal;
    m_nDayRun,
    m_nHourRun,
    m_nMinuteRun,
    m_nSecondRun: Cardinal;
    fServer: TPnHttpSysServer;
    function Process(Ctxt: TPnHttpServerContext; AFileUpload: Boolean;
          AReadBuf: PAnsiChar; AReadBufLen: Cardinal): Cardinal;
  public
    { Public declarations }
  end;

var
  frmMainEx: TfrmMainEx;

implementation

uses
  System.IOUtils,
  Winapi.ShellAPI,
  uPnHttpSys.Comm;

{$R *.dfm}

const
  ServerPorts = '8080,8081';

type
  TQLogVclMemoWriter = class(TQLogWriter)
  private
    FMemo: TMemo;
    FMaxLogLines: Word;
    procedure HandleNeeded; override;
  public
    constructor Create(AMemo: TMemo; AMaxLogLines: Word); overload;
    function WriteItem(AItem: PQLogItem): Boolean; override;
  end;

  TQLogErrorWriter = class(TQLogFileWriter)
  public
    function WriteItem(AItem: PQLogItem): Boolean; override;
  end;

{ TQLogVclMemoWriter }
constructor TQLogVclMemoWriter.Create(AMemo: TMemo; AMaxLogLines: Word);
begin
  inherited Create;
  FMemo := AMemo;
  FMaxLogLines := AMaxLogLines;
end;


function TQLogVclMemoWriter.WriteItem(AItem: PQLogItem): Boolean;
var
  s: QStringW;
begin
  if AItem.Level<>llMessage then
  begin
    Result := False;
    Exit;
  end;

  Result := True;
  s := FormatDateTime('hh:nn:ss.zzz', AItem.TimeStamp) + ' [' +
  IntToStr(AItem.ThreadId) + '] ' + StrDupX(@AItem.Text[0], AItem.MsgLen shr 1);

  //放入线程队列
  TThread.Queue(nil,
    procedure
    begin
      FMemo.Lines.BeginUpdate;
      try
        if FMemo.Lines.Count>FMaxLogLines then
          FMemo.Lines.Delete(0);
          FMemo.Lines.Add(s);
      finally
        FMemo.Lines.EndUpdate;
      end;
      SendMessage(FMemo.Handle, EM_SCROLLCARET, 0, 0);
    end);

end;


procedure TQLogVclMemoWriter.HandleNeeded;
begin

end;


{ TQLogErrorWriter }
function TQLogErrorWriter.WriteItem(AItem: PQLogItem): Boolean;
begin
  if AItem.Level<>llError then
  begin
    Result := False;
    Exit;
  end;

  inherited WriteItem(AItem);
end;


{ TfrmMainEx }
procedure TfrmMainEx.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
var
  sPorts: string;
  sPortArr: TArray<string>;
begin
  if Assigned(FServer) then
  begin
    if btnStart.Enabled then
    begin
      btnStart.Enabled := not FServer.IsRuning;
      btnStop.Enabled := FServer.IsRuning;
      chkLog.Enabled := not FServer.IsRuning;
      sPorts := ServerPorts;
      sPortArr := sPorts.Split([',']);
      lnklblLocalUrl.Caption := Format('<a href="http://localhost:%s">http://localhost:%s</a>', [sPortArr[0], sPortArr[0]]);
      lnklblLocalUrl.Enabled := FServer.IsRuning;
      Logs.Post(llMessage, '%s启动.', [Caption]);
      Logs.Post(llMessage, '服务器端口%s', [ServerPorts]);
    end;
  end
  else begin
    if not btnStart.Enabled then
    begin
      btnStart.Enabled := True;
      btnStop.Enabled := False;
      chkLog.Enabled := True;
      lnklblLocalUrl.Caption := '';
      lnklblLocalUrl.Enabled := False;
      Logs.Post(llMessage, '%s停止.', [Caption]);
    end;
  end;
end;

procedure TfrmMainEx.btnStartClick(Sender: TObject);
var
  sPorts: string;
  sPortArr: TArray<string>;
  I: Integer;
begin
  mmo1.Lines.Clear;
  if Assigned(FServer) then
    FreeAndNil(FServer);
  m_StartRun := GetTickCount64;
  m_LastRun := GetTickCount64;
  fServer := TPnHttpSysServer.Create(0, 100);
  sPorts := ServerPorts;
  sPortArr := sPorts.Split([',']);
  for I := 0 to Length(sPortArr)-1 do
  begin
    if sPortArr[I]<>'' then
      fServer.AddUrl('/',sPortArr[I].Trim,false,'+',true);
  end;
  fServer.RegisterCompress(CompressDeflateEx);
  fServer.OnRequest := Process;
  fServer.HTTPQueueLength := 100000;
  if chkLog.Checked then
    FServer.LogStart(Format('%sw3log', [ExeVersion.ProgramFilePath]))
  else
    FServer.LogStop;
  FServer.Start;
end;

procedure TfrmMainEx.btnStopClick(Sender: TObject);
begin
  if Assigned(FServer) then
    FreeAndNil(FServer);
end;

procedure TfrmMainEx.FormCreate(Sender: TObject);
var
  sPorts: string;
  sPortArr: TArray<string>;
  tag: string;
begin
  lblCopyRight.Caption := Format('Powered by <a href="http://#">%s</a>', [XPOWEREDVALUE]);
  //窗体消息日志
  mmo1.Lines.Clear;
  tag := FormatDateTime('yyyyMMddhhnnssms', Now());
  FLogPath := TPath.Combine(ExeVersion.ProgramFilePath, Format('%s\', ['logs']));
  Logs.Castor.AddWriter(TQLogVclMemoWriter.Create(mmo1, 100));
  //文件日志
  sPorts := ServerPorts;
  sPortArr := sPorts.Split([',']);
  Logs.Castor.AddWriter(TQLogFileWriter.Create(Format('%sq_%s_%s.log', [FLogPath, sPortArr[0], tag])));
  Logs.Castor.AddWriter(TQLogErrorWriter.Create(Format('%sq_%s_%s_error.log', [FLogPath, sPortArr[0], tag])));
end;

procedure TfrmMainEx.FormDestroy(Sender: TObject);
begin
  if Assigned(FServer) then
    FreeAndNil(FServer);
end;

procedure TfrmMainEx.lnklblLocalUrlLinkClick(Sender: TObject;
  const Link: string; LinkType: TSysLinkType);
begin
  ShellExecute(0, nil, PChar(Link), nil, nil, 1);
end;

function TfrmMainEx.Process(Ctxt: TPnHttpServerContext; AFileUpload: Boolean;
      AReadBuf: PAnsiChar; AReadBufLen: Cardinal): Cardinal;
var
  s: AnsiString;
begin
//  SetLength(s, 2048);
//  FillChar(PAnsiChar(s)^, 2048, 51);
//  Ctxt.OutContent := s;
  Ctxt.OutContent := 'PnHttpSysServerMain';
  Ctxt.OutContentType := AnsiString(HTML_CONTENT_TYPE);
  result := 200;
end;

procedure TfrmMainEx.tmr1Timer(Sender: TObject);
var
  buf: array[0..1023] of char;
begin
  if Assigned(fServer) then
  begin
    m_LastRun := GetTickCount;

    { 得到秒                            }
    m_nSecondRun := m_nSecondRun + (m_LastRun - m_StartRun) div 1000;
    { 修改起始时间   (最后时间-余数)    }
    m_StartRun := m_LastRun - (m_LastRun - m_StartRun) mod 1000;
    { 秒转成分                          }
    m_nMinuteRun := m_nMinuteRun + m_nSecondRun div 60;
    m_nSecondRun :=  m_nSecondRun mod 60;
    { 分转成时                          }
    m_nHourRun := m_nHourRun + m_nMinuteRun div 60;
    m_nMinuteRun :=  m_nMinuteRun mod 60;
    { 时转换成天                        }
    m_nDayRun := m_nDayRun + m_nHourRun div 24;
    m_nHourRun := m_nHourRun mod 24;


    lbl1.Caption := Format('%d/%d', [fServer.ReqCount, fServer.RespCount]);
    lbl2.Caption := Format('%d/%d', [fServer.ContextObjPool.FObjectMgr.GetActiveObjectCount, fServer.ContextObjPool.FObjectRes.GetObjectCount]);

    FillChar(buf, 1024, 0);
    lbl5.Caption := StrFmt(buf, ' %d 天  %d 时  %d 分  %d 秒 ',
      [m_nDayRun, m_nHourRun, m_nMinuteRun, m_nSecondRun]);

  end;
end;

end.
