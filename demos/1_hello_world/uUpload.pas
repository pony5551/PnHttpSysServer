unit uUpload;

interface

uses
  System.SysUtils,
  SynCommons,
  uPnHttpSys.Comm;

type
  TUpBuf = record
    buf: array of AnsiChar;
    buflen: Cardinal;
  end;

  //文件上传进度
  PUploadProcessInfo = ^TUploadProcessInfo;
  TUploadProcessInfo = record
  public
    TotalBytes: Int64;
    UploadedBytes: Int64;
    StartTime: Int64;
    LastActivity: Int64;
    ReadyState: string;
    boundaryStr: SockString;
    bufs: array of TUpBuf;

    procedure InitObj;
    //已上传秒数
    function GetElapsedSeconds: Int64;
    //已上传时间
    function GetElapsedTime: string;
    //传输速率
    function GetTransferRate: string;
    //完成百分比
    function GetPercentage: string;
    //估计剩余时间
    function TimeLeft: string;
  end;

implementation



{ TUploadProcessInfo }
procedure TUploadProcessInfo.InitObj;
begin
  TotalBytes := 0;
  UploadedBytes := 0;
  StartTime := GetTickCount64;
  LastActivity := GetTickCount64;
  ReadyState := 'uninitialized'; //uninitialized,loading,loaded,interactive,complete
end;

function TUploadProcessInfo.GetElapsedSeconds: Int64;
begin
  Result := (GetTickCount64 - StartTime) div 1000;
end;

function TUploadProcessInfo.GetElapsedTime: string;
var
  LElapsedSeconds: Int64;
begin
  LElapsedSeconds := GetElapsedSeconds;
  if LElapsedSeconds>3600 then
  begin
    Result := Format('%d 时 %d 分 %d 秒', [LElapsedSeconds div 3600, (LElapsedSeconds mod 3600) div 60, LElapsedSeconds mod 60]);
  end
  else if LElapsedSeconds>60 then
  begin
    Result := Format('%d 分 %d 秒', [LElapsedSeconds div 60, LElapsedSeconds mod 60]);
  end
  else begin
    Result := Format('%d 秒', [LElapsedSeconds mod 60]);
  end;
end;

function TUploadProcessInfo.GetTransferRate: string;
var
  LElapsedSeconds: Int64;
begin
  LElapsedSeconds := GetElapsedSeconds;
  if LElapsedSeconds>0 then
  begin
    Result := Format('%.2f K/秒', [UploadedBytes/1024/LElapsedSeconds]);
  end
  else
    Result := '0 K/秒';
end;

function TUploadProcessInfo.GetPercentage: string;
begin
  if TotalBytes>0 then
    Result := Format('%.2f', [UploadedBytes / TotalBytes * 100])+'%'
  else
    Result := '0%';
end;

function TUploadProcessInfo.TimeLeft: string;
var
  SecondsLeft: Int64;
begin
  if UploadedBytes>0 then
  begin
    SecondsLeft := GetElapsedSeconds * (TotalBytes div UploadedBytes - 1);
    if SecondsLeft > 3600 then
    begin
      Result := Format('%d 时 %d 分 %d 秒', [SecondsLeft div 3600, (SecondsLeft mod 3600) div 60, SecondsLeft mod 60]);
    end
    else if SecondsLeft > 60 then
    begin
      Result := Format('%d 分 %d 秒', [SecondsLeft div 60, SecondsLeft mod 60]);
    end
    else begin
      Result := Format('%d 秒', [SecondsLeft mod 60]);
    end;
  end
  else begin
    Result := '未知';
  end;
end;



end.
