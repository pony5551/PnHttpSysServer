unit uPNSysThreadPool;

//{$I Sparkle.Inc}

interface

// if needed, we should later make this cross-platform. Currently it's not needed
// since it's only being used by the server (which is windows-only)
{$IFDEF MSWINDOWS}

uses
  Classes, SyncObjs, SysUtils;

type
  TSysThreadPool = class
  private
    const DefaultStopTimeout = 20000;
  private
    FStopTimeout: integer;
    FStarted: boolean;
  protected
    function WaitWorkItems(const Timeout: Cardinal): boolean; virtual; abstract;
    procedure DoStart; virtual;
    procedure DoStop; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Start;
    function QueueUserWorkItem(Proc: TNotifyEvent; Context: TObject): boolean; virtual; abstract;
    function Stop: boolean;
    property StopTimeout: integer read FStopTimeout write FStopTimeout;
    property Started: boolean read FStarted;
  end;

  TWinThreadPool = class(TSysThreadPool)
  private
    FWorkCount: integer;
    FEvent: TEvent;
  protected
    function WaitWorkItems(const Timeout: Cardinal): boolean; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function QueueUserWorkItem(Proc: TNotifyEvent; Context: TObject): boolean; override;
    property WorkCount: Integer read FWorkCount write FWorkCount;
  end;

{$ENDIF}

implementation

{$IFDEF MSWINDOWS}

uses
  Winapi.Windows;

type
  PWinWorkItem = ^TWinWorkItem;
  TWinWorkItem = record
  private
    FPool: TWinThreadPool;
    FContext: TObject;
    FProc: TNotifyEvent;
  public
    procedure Create(AProc: TNotifyEvent; AContext: TObject; APool: TWinThreadPool);
    property Context: TObject read FContext;
    property Pool: TWinThreadPool read FPool;
    property Proc: TNotifyEvent read FProc;
  end;


function WorkItemFunction(lpThreadParameter: Pointer): Integer; stdcall;
var
  W: PWinWorkItem;
  Pool: TWinThreadPool;
begin
  Result := 0;
  W := PWinWorkItem(lpThreadParameter);
  try
    W.Proc(W.Context);
  finally
    Pool := W.Pool;
    Dispose(W);
    if InterlockedDecrement(Pool.FWorkCount) = 0 then
      Pool.FEvent.SetEvent;
  end;
end;

{ TWinThreadPool }

constructor TWinThreadPool.Create;
begin
  inherited;
  FEvent := TEvent.Create;
  FEvent.SetEvent;
end;

destructor TWinThreadPool.Destroy;
begin
  FEvent.Free;
  inherited;
end;

function TWinThreadPool.QueueUserWorkItem(Proc: TNotifyEvent; Context: TObject): boolean;
var
  WorkItem: PWinWorkItem;
begin
  New(WorkItem);
  try
    WorkItem.Create(Proc, Context, Self);
    InterlockedIncrement(FWorkCount);
    FEvent.ResetEvent;
    Result := Winapi.Windows.QueueUserWorkItem(WorkItemFunction, WorkItem, 0);
    if not Result then
      Dispose(WorkItem);
  except
    Dispose(WorkItem);
    raise;
  end;
end;

function TWinThreadPool.WaitWorkItems(const Timeout: Cardinal): boolean;
begin
  Result := WaitForSingleObject(FEvent.Handle, Timeout) = WAIT_OBJECT_0;
end;

{ TWinWorkItem }

procedure TWinWorkItem.Create(AProc: TNotifyEvent; AContext: TObject; APool: TWinThreadPool);
begin
  FContext := AContext;
  FPool := APool;
  FProc := AProc;
end;


{ TSysThreadPool }

constructor TSysThreadPool.Create;
begin
  FStopTimeout := DefaultStopTimeout;
  FStarted := false;
end;

destructor TSysThreadPool.Destroy;
begin
  Stop;
  inherited;
end;

procedure TSysThreadPool.DoStart;
begin
end;

procedure TSysThreadPool.DoStop;
begin
end;

procedure TSysThreadPool.Start;
begin
  if Started then Exit;
  DoStart;
  FStarted := true;
end;

function TSysThreadPool.Stop: boolean;
begin
  if not Started then Exit(true);
  FStarted := false;
  Result := WaitWorkItems(StopTimeout);
  DoStop;
end;

{$ENDIF}

end.
