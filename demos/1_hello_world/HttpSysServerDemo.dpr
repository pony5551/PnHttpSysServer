program HttpSysServerDemo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  //FastMM4,
  SynCommons,
  System.SysUtils,
  SynZip,
  uPnHttpSys.Comm,
  uPnHttpSys.Api,
  uPNHttpSysServer,
  uPNSysThreadPool;

type
  TTestServer = class
  protected
    fWinThPool: TWinThreadPool;
    fPath: TFileName;
    fServer: TPnHttpSysServer;
    procedure WorkItemCallBack(Sender: TObject);
    procedure CallWorkItem(Ctxt: TPnHttpServerContext; AFileUpload: Boolean;
      AReadBuf: PAnsiChar; AReadBufLen: Cardinal);
    function Process(Ctxt: TPnHttpServerContext; AFileUpload: Boolean;
      AReadBuf: PAnsiChar; AReadBufLen: Cardinal): Cardinal;
  public
    constructor Create(const Path: TFileName);
    destructor Destroy; override;
  end;


{ TTestServer }
constructor TTestServer.Create(const Path: TFileName);
var
  aFilePath: string;
begin
  fWinThPool := TWinThreadPool.Create;
  fWinThPool.Start;
  fPath := IncludeTrailingPathDelimiter(Path);
  fServer := TPnHttpSysServer.Create(0,2000);
  fServer.AddUrl('/','8000',false,'+',true);
  fServer.RegisterCompress(CompressDeflate);
  //fServer.OnCallWorkItemEvent := CallWorkItem;
  fServer.OnRequest := Process;
  fServer.HTTPQueueLength := 100000;
  aFilePath := Format('%sw3log',[ExeVersion.ProgramFilePath]);
  //fServer.LogStart(aFilePath);
  fServer.Start;
end;

destructor TTestServer.Destroy;
begin
  fServer.LogStop;
  fServer.Free;
  fWinThPool.Free;
  inherited;
end;

procedure TTestServer.WorkItemCallBack(Sender: TObject);
var
  Ctxt: TPnHttpServerContext;
begin
  Ctxt := TPnHttpServerContext(Sender);

  Ctxt.OutContent := 'hello call';
  Ctxt.OutContentType := HTML_CONTENT_TYPE;
  Ctxt.OutStatusCode := 200;
  //使用CallWorkItem事件必须调用SendResponse
  Ctxt.SendResponse;
end;


procedure TTestServer.CallWorkItem(Ctxt: TPnHttpServerContext; AFileUpload: Boolean; AReadBuf: PAnsiChar; AReadBufLen: Cardinal);
begin
  //另开线程处理，不阻塞Io线程，会一定程度降低整体效率
  //如果服务器需要处理复杂算法或大文件处理等运算时间比较长时建议使用
  fWinThPool.QueueUserWorkItem(WorkItemCallBack, Ctxt);
end;


function TTestServer.Process(Ctxt: TPnHttpServerContext; AFileUpload: Boolean;
      AReadBuf: PAnsiChar; AReadBufLen: Cardinal): Cardinal;

const
  sBoundary: SockString = 'boundary=';

var
  W: TTextWriter;
  FileName: TFileName;
  FN, SRName, href: RawUTF8;
  i: integer;
  SR: TSearchRec;

  procedure hrefCompute;
  begin
    SRName := StringToUTF8(SR.Name);
    href := FN+StringReplaceChars(SRName,'\','/');
  end;

begin
  //writeln(Ctxt.Method,' ',Ctxt.URL);
  if IdemPChar(pointer(Ctxt.URL),'/hello') then begin
    Ctxt.OutContent := 'hello world';
    Ctxt.OutContentType := HTML_CONTENT_TYPE;
    result := 200;
    Exit;
  end;

  //文件及目录处理
  FN := StringReplaceChars(UrlDecode(copy(Ctxt.URL,1,maxInt)),'/','\');
  if PosEx('..',FN)>0 then begin
    result := 404; // circumvent obvious potential security leak
    exit;
  end;
  while (FN<>'') and (FN[1]='\') do
    delete(FN,1,1);
  while (FN<>'') and (FN[length(FN)]='\') do
    delete(FN,length(FN),1);
  FileName := fPath+UTF8ToString(FN);
  if DirectoryExists(FileName) then begin
    // reply directory listing as html
    W := TTextWriter.CreateOwnedStream;
    try
      W.Add('<html><body style="font-family: Arial">'+
        '<h3>%</h3><p><table>',[FN]);
      FN := StringReplaceChars(FN,'\','/');
      if FN<>'' then
        FN := FN+'/';
      if FindFirst(FileName+'\*.*',faDirectory,SR)=0 then begin
        repeat
          if (SR.Attr and faDirectory<>0) and (SR.Name<>'.') then begin
            hrefCompute;
            if SRName='..' then
            begin
              i := length(FN);
              while (i>0) and (FN[i]='/') do dec(i);
              while (i>0) and (FN[i]<>'/') do dec(i);
              href := copy(FN,1,i);
            end;
            W.Add('<tr><td><b><a href="/%">[%]</a></b></td></tr>',[href,SRName]);
          end;
        until FindNext(SR)<>0;
        FindClose(SR);
      end;
      if FindFirst(FileName+'\*.*',faAnyFile-faDirectory-faHidden,SR)=0 then begin
        repeat
          hrefCompute;
          if SR.Attr and faDirectory=0 then
            W.Add('<tr><td><b><a href="/%">%</a></b></td><td>%</td><td>%</td></td></tr>',
              [href,SRName,KB(SR.Size),DateTimeToStr(
                {$ifdef ISDELPHIXE2}SR.TimeStamp{$else}FileDateToDateTime(SR.Time){$endif})]);
        until FindNext(SR)<>0;
        FindClose(SR);
      end;
      W.AddShort('</table></p><p><i>Powered by httpapi <strong>');
      W.AddClassName(Ctxt.Server.ClassType);
      W.AddShort('</strong></i></p></body></html>');
      Ctxt.OutContent := W.Text;
      Ctxt.OutContentType := HTML_CONTENT_TYPE;
      result := 200;
    finally
      W.Free;
    end;
  end
  else begin
    // http.sys will send the specified file from kernel mode
    Ctxt.OutContent := StringToUTF8(FileName);
    Ctxt.OutContentType := HTTP_RESP_STATICFILE;
    result := 200; // THttpApiServer.Execute will return 404 if not found
  end;
end;



begin
  ReportMemoryLeaksOnShutDown := True;

  with TTestServer.Create(Format('%swww', [ExeVersion.ProgramFilePath])) do
  try
    write('Server is now running on http://localhost:8000/'#13#10#13#10+
      'Press [Enter] to quit');
    writeln('');
    readln;
  finally
    Free;
  end;
end.
