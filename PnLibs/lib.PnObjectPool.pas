unit lib.PnObjectPool;

interface

uses
  System.Classes,
  System.SysUtils,
  lib.PnLocker,
  lib.PnObject;

type
  // TPNObjectNode节点
  PTPNObjectNode = ^TPNObjectNode;
  TPNObjectNode = record
    m_MapID: Integer; // MapID
    m_IsUsed: Boolean; // 是否为有效节点
    m_pPNObject: TPNObject; // TPNObject
  end;

  TPnQueue = class
  private
    FHead: TObject;
    FTail: TObject;
    FSize: Integer;
    procedure FreeNode(Value: TObject);
    function GetSize: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Push(Data: Pointer);
    function Pop: Pointer;
    property Size: Integer read GetSize;
  end;

  TPnSafeQueue = class
  private
    FLock: TPnLocker;
    FQueue: TPnQueue;
    function GetSize: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Push(Data: Pointer);
    function Pop: Pointer;
    property Size: Integer read GetSize;
  end;

  TPNObjectMgr = class
  private
    m_Buckets: TList; // 上下文数组
    m_FreeBuckets: TPnQueue; // 空闲节点
    m_nActiveCount: Integer; // Map中活动节点数
    m_nObjectCount: Integer; // Map中总数量
    m_ObjectMgrLock: TPnLocker; // 锁
  public
    function AddPNObject(const FObject: TPNObject): Boolean; // 增加PNObject到列表
    function RemovePNObject(const FObject: TPNObject): Boolean; // 把PNObject从列表中删除
    procedure FreeObjects; // 释放所有PNObject
    function GetActiveObjectCount: Integer; // 得到活动PNObject总数量
    function GetObjectCount: Integer; // 得到池内PNObject总数量

  published
    property FObjectMgrLock: TPnLocker read m_ObjectMgrLock;
    property FBuckets: TList read m_Buckets;// write m_Buckets;

  public
    constructor Create;
    destructor Destroy; override;
  end;

  // 创建对像事件
  TOnCreateObject  = function: TPNObject of object;

  TPNObjectRes = class
  private
    m_OnCreateObject: TOnCreateObject;
    m_ObjectResLock: TPnLocker; // 回收锁
    m_pFreeObjectList: TPNObject; // 链表指针
    m_nObjectResCount: Integer; // 空闲数量
    m_iMaxNumberOfFreeObject: Integer; // 池内最大数量，超过释放
    m_nNewObjectCount: Int64; // 物理申请内存数
    m_nFreeObjectCount: Int64; // 物理释放内存数
  published
    property FOnCreateObject: TOnCreateObject read m_OnCreateObject write m_OnCreateObject;
    property FObjectResLock: TPnLocker read m_ObjectResLock;
    property FNewObjectCount: Int64 read m_nNewObjectCount;
    property FFreeObjectCount: Int64 read m_nFreeObjectCount;
  public
    function AllocateFreeObjectFromPool: TPNObject; // 分配空闲PNObject
    procedure ReleaseObjectToPool(FObject: TPNObject); // 回收空闪PNObject
    procedure FreeObjects; // 释放所有PNObject
    function GetObjectCount: Integer; // 得到池内PNObject总数量
    procedure SetMaxFreeObject(const m_MaxNumber: Integer); // 设置池内最大允许数量
  published
    property FMaxNumberOfFreeObject: Integer read m_iMaxNumberOfFreeObject write SetMaxFreeObject;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  // PN对像池
  TPNObjectPool = class
  private
    m_OnCreateObject: TOnCreateObject;
    m_ObjectMgr: TPNObjectMgr; // 对像管理
    m_ObjectRes: TPNObjectRes; // 对像回收
  published
    property FOnCreateObject: TOnCreateObject read m_OnCreateObject write m_OnCreateObject;
    property FObjectMgr: TPNObjectMgr read m_ObjectMgr;
    property FObjectRes: TPNObjectRes read m_ObjectRes;
  public
    // 初始化对像池
    procedure InitObjectPool(m_nFreeObjects: Cardinal);
    // 分配Object
    function AllocateObject: TPNObject;
    // 回收Object
    function ReleaseObject(FObject: TPNObject): Boolean;
    // 查找Object
    function FindPNObject(m_nIndex: Cardinal): TPNObject;
    // 释放Object
    procedure FreeAllObjects;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TPNUnSafeObjectRes = class
  private
    m_OnCreateObject: TOnCreateObject;
    m_pFreeObjectList: TPNObject; // 链表指针
    m_nObjectResCount: Integer; // 空闲数量
    m_iMaxNumberOfFreeObject: Integer; // 池内最大数量，超过释放
    m_nNewObjectCount: Int64; // 物理申请内存数
    m_nFreeObjectCount: Int64; // 物理释放内存数
  published
    property FOnCreateObject: TOnCreateObject read m_OnCreateObject write m_OnCreateObject;
    property FNewObjectCount: Int64 read m_nNewObjectCount;
    property FFreeObjectCount: Int64 read m_nFreeObjectCount;
  public
    function AllocateFreeObjectFromPool: TPNObject; // 分配空闲PNObject
    procedure ReleaseObjectToPool(FObject: TPNObject); // 回收空闪PNObject
    procedure FreeObjects; // 释放所有PNObject
    function GetObjectCount: Integer; // 得到池内PNObject总数量
    procedure SetMaxFreeObject(const m_MaxNumber: Integer); // 设置池内最大允许数量
  published
    property FMaxNumberOfFreeObject: Integer read m_iMaxNumberOfFreeObject write SetMaxFreeObject;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  // PN对像池
  TPNUnSafeObjectPool = class
  private
    m_OnCreateObject: TOnCreateObject;
    m_ObjectRes: TPNObjectRes; // 对像回收
  published
    property FOnCreateObject: TOnCreateObject read m_OnCreateObject write m_OnCreateObject;
    property FObjectRes: TPNObjectRes read m_ObjectRes;
  public
    // 初始化对像池
    procedure InitObjectPool(m_nFreeObjects: Cardinal);
    // 分配Object
    function AllocateObject: TPNObject;
    // 回收Object
    function ReleaseObject(FObject: TPNObject): Boolean;
    // 释放Object
    procedure FreeAllObjects;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

type
  TPnNode = class
  private
    FNext: TPnNode;
    FData: Pointer;
  public
    property Next: TPnNode read FNext write FNext;
    property Data: Pointer read FData write FData;
  end;

{ TPnQueue }

procedure TPnQueue.FreeNode(Value: TObject);
var
  Tmp: TPnNode;
begin
  Tmp := TPnNode(Value).Next;
  TPnNode(Value).Free;
  if Tmp = nil then
    Exit;
  FreeNode(Tmp);
end;

constructor TPnQueue.Create;
begin
  FHead := nil;
  FTail := nil;
  FSize := 0;
end;

destructor TPnQueue.Destroy;
begin
  if FHead <> nil then
    FreeNode(FHead);
  inherited;
end;

function TPnQueue.Pop: Pointer;
var
  Tmp: TPnNode;
begin
  Result := nil;
  if FHead = nil then
    Exit;

  Result := TPnNode(FHead).Data;
  Tmp := TPnNode(FHead).Next;
  TPnNode(FHead).Free;
  FHead := Tmp;

  if Tmp = nil then
    FTail := nil;
  //FSize := FSize - 1;
  Dec(FSize);
end;

procedure TPnQueue.Push(Data: Pointer);
var
  Tmp: TPnNode;
begin
  if Data = nil then Exit;
  Tmp := TPnNode.Create;
  Tmp.Data := Data;
  Tmp.Next := nil;

  if FTail = nil then
  begin
    FTail := Tmp;
    FHead := Tmp;
  end
  else
  begin
    TPnNode(FTail).Next := Tmp;
    FTail := Tmp
  end;

  //FSize := FSize + 1;
  Inc(FSize);
end;

function TPnQueue.GetSize: Integer;
begin
  Result := FSize;
end;


{ TPnSafeQueue }
constructor TPnSafeQueue.Create;
begin
  inherited;
  FLock := TPnLocker.Create('TPnSafeQueue_Lock');
  FQueue := TPnQueue.Create;
end;

destructor TPnSafeQueue.Destroy;
begin
  FreeAndNil(FQueue);
  FreeAndNil(FLock);
  inherited;
end;

procedure TPnSafeQueue.Push(Data: Pointer);
begin
  FLock.Lock;
  try
    FQueue.Push(Data);
  finally
    FLock.UnLock;
  end;
end;

function TPnSafeQueue.Pop: Pointer;
begin
  FLock.Lock;
  try
    Result := FQueue.Pop;
  finally
    FLock.UnLock;
  end;
end;

function TPnSafeQueue.GetSize: Integer;
begin
  FLock.Lock;
  try
    Result := FQueue.Size;
  finally
    FLock.UnLock;
  end;
end;


{ TPNObjectMgr }
constructor TPNObjectMgr.Create;
begin
  inherited Create;
  m_nActiveCount := 0;
  m_nObjectCount := 0;
  m_FreeBuckets := TPNQueue.Create;
  m_Buckets := TList.Create;
  m_ObjectMgrLock := TPnLocker.Create('m_ObjectMgrLock');
end;

destructor TPNObjectMgr.Destroy;
var
  I: Integer;
begin
  FreeObjects;
  m_ObjectMgrLock.Lock;
  for I := m_Buckets.Count - 1 downto 0 do
    Dispose(m_Buckets[I]);
  m_ObjectMgrLock.UnLock;

  FreeAndNil(m_Buckets);
  FreeAndNil(m_FreeBuckets);
  FreeAndNil(m_ObjectMgrLock);
  inherited Destroy;
end;

function TPNObjectMgr.GetActiveObjectCount: Integer;
begin
  Result := m_nActiveCount;
end;

function TPNObjectMgr.GetObjectCount: Integer;
//var
//  nNewValue: Integer;
begin
  Result := m_nObjectCount;
//  repeat
//    Result := m_nObjectCount;
//    nNewValue := Result + 0;
//  until AtomicCmpExchange(m_nObjectCount, nNewValue, Result) = Result;
end;

function TPNObjectMgr.AddPNObject(const FObject: TPNObject): Boolean;
var
  pNode: PTPNObjectNode;
begin
  Result := FALSE;
  if not Assigned(FObject) then
    Exit;

  m_ObjectMgrLock.Lock;
  try
    if m_FreeBuckets.Size>0 then
    begin
      pNode := PTPNObjectNode(m_FreeBuckets.Pop);
      pNode^.m_IsUsed := TRUE;
      pNode^.m_pPNObject := FObject;
      FObject.m_MapID := pNode^.m_MapID;
      Inc(m_nActiveCount);
    end
    else
    begin
      New(pNode);
      pNode^.m_pPNObject := FObject;
      pNode^.m_IsUsed := TRUE;
      pNode^.m_MapID := m_nObjectCount;
      FObject.m_MapID := m_nObjectCount;
      Inc(m_nActiveCount);
      Inc(m_nObjectCount);
      m_Buckets.Add(pNode);
    end;
    Result := True;
  finally
    m_ObjectMgrLock.UnLock;
  end;
//  {$IFDEF _ICOP_DEBUG}
//      _GlobalLogger.AppendErrorLogMessage('TPNObjectMgr.AddPNObject, MapID: %d, Count: %d.',
//                                          [FObject.m_MapID, m_nObjectCount]);
//  {$ENDIF}
end;

function TPNObjectMgr.RemovePNObject(const FObject: TPNObject): Boolean;
begin
  Result := FALSE;
  if not Assigned(FObject) then
    Exit;

  m_ObjectMgrLock.Lock;
  try
    if not (FObject.m_MapID >= GetObjectCount) then
    begin
      if PTPNObjectNode(m_Buckets[FObject.m_MapID])^.m_IsUsed then
      begin
        PTPNObjectNode(m_Buckets[FObject.m_MapID])^.m_pPNObject := nil;
        PTPNObjectNode(m_Buckets[FObject.m_MapID])^.m_IsUsed := FALSE;
        m_FreeBuckets.Push(PTPNObjectNode(m_Buckets[FObject.m_MapID]));
        Dec(m_nActiveCount);
        Result := TRUE;
//        {$IFDEF _ICOP_DEBUG}
//           _GlobalLogger.AppendErrorLogMessage('RemovePNObject成功, MapID: %d, 活动Count: %d.',
//                                              [ FObject.m_MapID, m_nActiveCount]);
//        {$ENDIF}
      end;
    end;

  finally
    m_ObjectMgrLock.UnLock;
  end;
end;

procedure TPNObjectMgr.FreeObjects;
var
  I: Integer;
begin
  m_ObjectMgrLock.Lock;
  try
    for I := 0 to m_Buckets.Count-1 do
    begin
      if ( (PTPNObjectNode(m_Buckets[I])^.m_IsUsed) and
           (PTPNObjectNode(m_Buckets[I])^.m_pPNObject<>nil) ) then
      begin
        FreeAndNil(PTPNObjectNode(m_Buckets[I])^.m_pPNObject);
        PTPNObjectNode(m_Buckets[I])^.m_IsUsed := FALSE;
        PTPNObjectNode(m_Buckets[I])^.m_pPNObject := nil;
        Dec(m_nActiveCount);
      end;
    end;
  finally
    m_ObjectMgrLock.UnLock;
  end;
end;


{ TPNObjectRes }
constructor TPNObjectRes.Create;
begin
  inherited Create;
  m_nNewObjectCount := 0;
  m_nFreeObjectCount := 0;
  m_nObjectResCount := 0;
  m_iMaxNumberOfFreeObject := 10;
  m_pFreeObjectList := nil;
  m_ObjectResLock := TPnLocker.Create('m_ObjectResLock');
end;

destructor TPNObjectRes.Destroy;
begin
  FreeObjects;
  FreeAndNil(m_ObjectResLock);
  inherited Destroy;
end;

function TPNObjectRes.GetObjectCount: Integer;
begin
  Result := m_nObjectResCount;
end;

procedure TPNObjectRes.SetMaxFreeObject(const m_MaxNumber: Integer);
begin
  if m_MaxNumber>=0 then
    m_iMaxNumberOfFreeObject := m_MaxNumber;
end;

function TPNObjectRes.AllocateFreeObjectFromPool: TPNObject;
var
  m_pPNObject: TPNObject;
begin
  if not Assigned(m_OnCreateObject) then
  begin
    Result := nil;
    raise Exception.Create('m_OnCreateObject IS NULL.');
    Exit;
  end;

  m_ObjectResLock.Lock;
  if ( m_pFreeObjectList = nil ) then
  begin
    Inc(m_nNewObjectCount);
    m_ObjectResLock.UnLock;
    m_pPNObject := m_OnCreateObject;
  end
  else
  begin
    m_pPNObject := m_pFreeObjectList;
    m_pFreeObjectList := m_pFreeObjectList.m_pNext;
    Dec(m_nObjectResCount);
    m_ObjectResLock.UnLock;
  end;

  if m_pPNObject <> nil then
    m_pPNObject.InitObject;
  Result := m_pPNObject;
end;

procedure TPNObjectRes.ReleaseObjectToPool(FObject: TPNObject);
begin
  if not Assigned(FObject) then
    Exit;

  m_ObjectResLock.Lock;
  try
    if ( m_nObjectResCount < m_iMaxNumberOfFreeObject) then
    begin
      FObject.m_pNext := m_pFreeObjectList;
      m_pFreeObjectList := FObject;
      Inc(m_nObjectResCount);
    end
    else begin
      Inc(m_nFreeObjectCount);
      FreeAndNil(FObject);
    end;
  finally
    m_ObjectResLock.UnLock;
  end;
end;

procedure TPNObjectRes.FreeObjects;
var
  m_pFreeObject: TPNObject;
  m_pNextObject: TPNObject;
begin
  m_pFreeObject := nil;

  m_ObjectResLock.Lock;
  try
    m_pFreeObject := m_pFreeObjectList;
    while (m_pFreeObject<> nil) do
    begin
      m_pNextObject := m_pFreeObject.m_pNext;
      if Assigned(m_pFreeObject) then
        FreeAndNil(m_pFreeObject);
      Dec(m_nObjectResCount);
      m_pFreeObject := m_pNextObject;
    end;
    m_pFreeObjectList := nil;
    m_nObjectResCount := 0;
  finally
    m_ObjectResLock.UnLock;
  end;
end;


{ TPNObjectPool }
constructor TPNObjectPool.Create;
begin
  inherited Create;
  m_ObjectRes := TPNObjectRes.Create;
  m_ObjectMgr := TPNObjectMgr.Create;
end;

destructor TPNObjectPool.Destroy;
begin
  FreeAndNil(m_ObjectMgr);
  FreeAndNil(m_ObjectRes);
  inherited Destroy;
end;

procedure TPNObjectPool.InitObjectPool(m_nFreeObjects: Cardinal);
var
  I: Integer;
  FFreeObject: TPNObject;
begin
  if not Assigned(m_OnCreateObject) then
  begin
    raise Exception.Create('m_OnCreateObject IS NULL.');
    Exit;
  end;
  FObjectRes.FOnCreateObject := m_OnCreateObject;
  FObjectRes.SetMaxFreeObject(m_nFreeObjects);
  for I := 1 to m_nFreeObjects do
  begin
    FFreeObject := m_OnCreateObject;
    m_ObjectRes.ReleaseObjectToPool(FFreeObject);
  end;
end;

function TPNObjectPool.AllocateObject: TPNObject;
begin
  Result := m_ObjectRes.AllocateFreeObjectFromPool;
  if not m_ObjectMgr.AddPNObject(Result) then
  begin
    m_ObjectRes.ReleaseObjectToPool(Result);
//    {$IFDEF _ICOP_DEBUGERR}
//        _GlobalLogger.AppendErrorLogMessage('TPNObjectPool.AllocateObject AddPNObject 失败', []);
//    {$ENDIF}
  end;
end;

function TPNObjectPool.ReleaseObject(FObject: TPNObject): Boolean;
begin
  if not Assigned(FObject) then
  begin
    Result := False;
    Exit;
  end;

  Result := m_ObjectMgr.RemovePNObject(FObject);
  if Result then
    m_ObjectRes.ReleaseObjectToPool(FObject);
end;

function TPNObjectPool.FindPNObject(m_nIndex: Cardinal): TPNObject;
begin
  Result := nil;
  if ( (m_nIndex < 0 ) or
       (m_nIndex > FObjectMgr.GetObjectCount-1) ) then
       Exit;

  if (PTPNObjectNode(FObjectMgr.FBuckets[m_nIndex])^.m_IsUsed) then
    Result := PTPNObjectNode(FObjectMgr.FBuckets[m_nIndex])^.m_pPNObject;
end;

procedure TPNObjectPool.FreeAllObjects;
begin
  m_ObjectMgr.FreeObjects;
  m_ObjectRes.FreeObjects;
end;


{ TPNUnSafeObjectRes }
constructor TPNUnSafeObjectRes.Create;
begin
  inherited Create;
  m_nNewObjectCount := 0;
  m_nFreeObjectCount := 0;
  m_nObjectResCount := 0;
  m_iMaxNumberOfFreeObject := 10;
  m_pFreeObjectList := nil;
end;

destructor TPNUnSafeObjectRes.Destroy;
begin
  FreeObjects;
  inherited Destroy;
end;

function TPNUnSafeObjectRes.GetObjectCount: Integer;
begin
  Result := m_nObjectResCount;
end;

procedure TPNUnSafeObjectRes.SetMaxFreeObject(const m_MaxNumber: Integer);
begin
  if m_MaxNumber>=0 then
    m_iMaxNumberOfFreeObject := m_MaxNumber;
end;

function TPNUnSafeObjectRes.AllocateFreeObjectFromPool: TPNObject;
var
  m_pPNObject: TPNObject;
begin
  if not Assigned(m_OnCreateObject) then
  begin
    Result := nil;
    raise Exception.Create('m_OnCreateObject IS NULL.');
    Exit;
  end;

  if ( m_pFreeObjectList = nil ) then
  begin
    Inc(m_nNewObjectCount);
    m_pPNObject := m_OnCreateObject;
  end
  else
  begin
    m_pPNObject := m_pFreeObjectList;
    m_pFreeObjectList := m_pFreeObjectList.m_pNext;
    Dec(m_nObjectResCount);
  end;

  if m_pPNObject <> nil then
    m_pPNObject.InitObject;
  Result := m_pPNObject;
end;

procedure TPNUnSafeObjectRes.ReleaseObjectToPool(FObject: TPNObject);
begin
  if not Assigned(FObject) then
    Exit;

  if ( m_nObjectResCount < m_iMaxNumberOfFreeObject) then
  begin
    FObject.m_pNext := m_pFreeObjectList;
    m_pFreeObjectList := FObject;
    Inc(m_nObjectResCount);
  end
  else begin
    Inc(m_nFreeObjectCount);
    FreeAndNil(FObject);
  end;
end;

procedure TPNUnSafeObjectRes.FreeObjects;
var
  m_pFreeObject: TPNObject;
  m_pNextObject: TPNObject;
begin
  m_pFreeObject := nil;

  m_pFreeObject := m_pFreeObjectList;
  while (m_pFreeObject<> nil) do
  begin
    m_pNextObject := m_pFreeObject.m_pNext;
    if Assigned(m_pFreeObject) then
      FreeAndNil(m_pFreeObject);
    Dec(m_nObjectResCount);
    m_pFreeObject := m_pNextObject;
  end;
  m_pFreeObjectList := nil;
  m_nObjectResCount := 0;
end;

{ TPNUnSafeObjectPool }
constructor TPNUnSafeObjectPool.Create;
begin
  inherited Create;
  m_ObjectRes := TPNObjectRes.Create;
end;

destructor TPNUnSafeObjectPool.Destroy;
begin
  FreeAndNil(m_ObjectRes);
  inherited Destroy;
end;

procedure TPNUnSafeObjectPool.InitObjectPool(m_nFreeObjects: Cardinal);
var
  I: Integer;
  FFreeObject: TPNObject;
begin
  if not Assigned(m_OnCreateObject) then
  begin
    raise Exception.Create('m_OnCreateObject IS NULL.');
    Exit;
  end;
  FObjectRes.FOnCreateObject := m_OnCreateObject;
  FObjectRes.SetMaxFreeObject(m_nFreeObjects);
  for I := 1 to m_nFreeObjects do
  begin
    FFreeObject := m_OnCreateObject;
    m_ObjectRes.ReleaseObjectToPool(FFreeObject);
  end;
end;

function TPNUnSafeObjectPool.AllocateObject: TPNObject;
begin
  Result := m_ObjectRes.AllocateFreeObjectFromPool;
end;

function TPNUnSafeObjectPool.ReleaseObject(FObject: TPNObject): Boolean;
begin
  if not Assigned(FObject) then
  begin
    Result := False;
    Exit;
  end;

  m_ObjectRes.ReleaseObjectToPool(FObject);
  Result := True;
end;

procedure TPNUnSafeObjectPool.FreeAllObjects;
begin
  m_ObjectRes.FreeObjects;
end;


end.


