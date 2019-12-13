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
{.$DEFINE TSpinLock}

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs;

type
  TPnLocker = class
  private
    FLockName: string;
    {$IFDEF TMonitor}
    FLock: TObject;
    {$ELSEIF defined(CSLock)}
    FCSLock: TCriticalSection;
    {$ELSEIF defined(TSpinLock)}
    FSpLock: TSpinLock;
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


constructor TPnLocker.Create(const ALockName: string);
begin
  inherited Create;
  FLockName := ALockName;
  {$IFDEF TMonitor}
  FLock := TObject.Create;
  {$ELSEIF defined(CSLock)}
  FCSLock := TCriticalSection.Create;
  {$ELSEIF defined(TSpinLock)}
  FSpLock := TSpinLock.Create(False);
  {$ENDIF}
end;

destructor TPnLocker.Destroy;
begin
  {$IFDEF TMonitor}
  FreeAndNil(FLock);
  {$ELSEIF defined(CSLock)}
  FreeAndNil(FCSLock);
  {$ELSEIF defined(TSpinLock)}
  FreeAndNil(FSpLock);
  {$ENDIF}
  inherited Destroy;
end;

procedure TPnLocker.Lock;
begin
  {$IFDEF TMonitor}
  System.TMonitor.Enter(FLock);
  {$ELSEIF defined(CSLock)}
  FCSLock.Enter;
  {$ELSEIF defined(TSpinLock)}
  FSpLock.Enter;
  {$ENDIF}
end;

procedure TPnLocker.UnLock;
begin
  {$IFDEF TMonitor}
  System.TMonitor.Exit(FLock);
  {$ELSEIF defined(CSLock)}
  FCSLock.Leave;
  {$ELSEIF defined(TSpinLock)}
  FSpLock.Exit;
  {$ENDIF}
end;

function TPnLocker.GetLockName: string;
begin
  Result := FLockName;
end;

end.

