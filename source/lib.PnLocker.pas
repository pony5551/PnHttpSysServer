{******************************************************************************}
{ @UnitName     : lib.PnLocker.pas                                       }
{ @Project      : PonyWorkEx                                                       }
{ @Copyright    : -                                                            }
{ @Author       : 奔腾的心(7180001)                                            }
{ @Description  : PonyWorkEx 加强锁处理类                                          }
{ @FileVersion  : 1.0.0.1                                                      }
{ @CreateDate   : 2011-04-28                                                   }
{ @Comment      : -                                                            }
{ @LastUpdate   : 2011-07-09                                                   }
{******************************************************************************}
unit lib.PnLocker;

interface

{$DEFINE TMonitor}
{.$DEFINE CSLock}
{.$DEFINE TQSimpleLock}

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs;

type
  TQSimpleLock = class
  private
    FFlags: Integer;
  public
    constructor Create;
    procedure Enter; inline;
    procedure Leave; inline;
  end;

  TPnLocker = class
  private
    FLockName: string;
    {$IFDEF TMonitor}
    FLock: TObject;
    {$ELSEIF defined(CSLock)}
    FCSLock: TCriticalSection;
    {$ELSEIF defined(TQSimpleLock)}
    FQLock: TQSimpleLock;
    {$ENDIF}
    function GetLockName: string;
  public
    constructor Create(const ALockName: string);
    destructor Destroy; override;
    procedure Lock; inline;
    procedure UnLock; inline;

    property LockName: string read GetLockName;
  end;

implementation


//位与，返回原值
function AtomicAnd(var Dest: Integer; const AMask: Integer): Integer; inline;
var
  I:Integer;
begin
  repeat
    Result := Dest;
    I := Result and AMask;
  until AtomicCmpExchange(Dest, I, Result) = Result;
end;
//位或，返回原值
function AtomicOr(var Dest: Integer; const AMask: Integer): Integer; inline;
var
  I: Integer;
begin
  repeat
    Result := Dest;
    I := Result or AMask;
  until AtomicCmpExchange(Dest, I, Result) = Result;
end;

constructor TQSimpleLock.Create;
begin
  inherited;
  FFlags := 0;
end;

procedure TQSimpleLock.Enter;
begin
  while (AtomicOr(FFlags,$01) and $01)<>0 do
    begin
      {$IFDEF UNICODE}
      TThread.Yield;
      {$ELSE}
      SwitchToThread;
      {$ENDIF}
    end;
end;

procedure TQSimpleLock.Leave;
begin
  AtomicAnd(FFlags, Integer($FFFFFFFE));
end;

constructor TPnLocker.Create(const ALockName: string);
begin
  inherited Create;
  FLockName := ALockName;
  {$IFDEF TMonitor}
  FLock := TObject.Create;
  {$ELSEIF defined(CSLock)}
  FCSLock := TCriticalSection.Create;
  {$ELSEIF defined(TQSimpleLock)}
  FQLock := TQSimpleLock.Create;
  {$ENDIF}
end;

destructor TPnLocker.Destroy;
begin
  {$IFDEF TMonitor}
  FreeAndNil(FLock);
  {$ELSEIF defined(CSLock)}
  FreeAndNil(FCSLock);
  {$ELSEIF defined(TQSimpleLock)}
  FreeAndNil(FQLock);
  {$ENDIF}
  inherited Destroy;
end;

procedure TPnLocker.Lock;
begin
  {$IFDEF TMonitor}
  System.TMonitor.Enter(FLock);
  {$ELSEIF defined(CSLock)}
  FCSLock.Enter;
  {$ELSEIF defined(TQSimpleLock)}
  FQLock.Enter;
  {$ENDIF}
end;

procedure TPnLocker.UnLock;
begin
  {$IFDEF TMonitor}
  System.TMonitor.Exit(FLock);
  {$ELSEIF defined(CSLock)}
  FCSLock.Leave;
  {$ELSEIF defined(TQSimpleLock)}
  FQLock.Leave;
  {$ENDIF}
end;

function TPnLocker.GetLockName: string;
begin
  Result := FLockName;
end;

end.

