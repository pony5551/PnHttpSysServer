{******************************************************************************}
{                                                                              }
{       Delphi PnHttpSysServer                                                 }
{                                                                              }
{       Copyright (c) 2018 pony,光明(7180001@qq.com)                           }
{                                                                              }
{       Homepage: https://github.com/pony5551/PnHttpSysServer                  }
{                                                                              }
{******************************************************************************}
unit uPNObjectMgr;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  uPNObject,
  uPNCriticalSection;

//{$I PNIOCP.inc}
  
type
  // TPNObjectNode节点
  PTPNObjectNode = ^TPNObjectNode;
  TPNObjectNode = record
    m_MapID:      Integer;                                // MapID
    m_IsUsed:     Boolean;                                // 是否为有效节点
    m_pPNObject:  TPNObject;                              // TPNObject
  end;

  TPNObjectMgr = Class
  private
    m_Buckets:                TList;                      // 上下文数组
    m_FreeBuckets:            TQueue<PTPNObjectNode>;     // 空闲节点
    m_nActiveCount:           Integer;                    // Map中活动节点数
    m_nObjectCount:           Integer;                    // Map中总数量
    m_ObjectMgrLock:          TPNCriticalSection;         // 锁
  public
    function AddPNObject(FObject: TPNObject): Boolean;    // 增加PNObject到列表
    function RemovePNObject(FObject: TPNObject): Boolean; // 把PNObject从列表中删除
    procedure FreeObjects;                                // 释放所有PNObject
    function GetActiveObjectCount: Integer;               // 得到活动PNObject总数量
    function GetObjectCount: Integer;                     // 得到池内PNObject总数量

  published
    property FObjectMgrLock: TPNCriticalSection read m_ObjectMgrLock write m_ObjectMgrLock;
    property FBuckets: TList read m_Buckets write m_Buckets;

  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

constructor TPNObjectMgr.Create;
begin
  inherited Create;
  m_nActiveCount := 0;
  m_nObjectCount := 0;
  m_FreeBuckets := TQueue<PTPNObjectNode>.Create;
  m_Buckets := TList.Create;
  m_ObjectMgrLock := TPNCriticalSection.Create;
  m_ObjectMgrLock.SetLockName('TPNObjectMgr');
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
begin
  Result := m_nObjectCount;
end;

function TPNObjectMgr.AddPNObject(FObject: TPNObject): Boolean;
var
  pNode: PTPNObjectNode;
begin
  Result := FALSE;
  if not Assigned(FObject) then
    Exit;

  m_ObjectMgrLock.Lock;
  try
    if m_FreeBuckets.Count>0 then
    begin
      //出队
      pNode := m_FreeBuckets.Dequeue;
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
    Result := TRUE;
  finally
    m_ObjectMgrLock.UnLock;
  end;
//  {$IFDEF _ICOP_DEBUG}
//      _GlobalLogger.AppendErrorLogMessage('TPNObjectMgr.AddPNObject, MapID: %d, Count: %d.',
//                                          [FObject.m_MapID, m_nObjectCount]);
//  {$ENDIF}
end;

function TPNObjectMgr.RemovePNObject(FObject: TPNObject): Boolean;
begin
  Result := FALSE;
  if not Assigned(FObject) then
    Exit;

  m_ObjectMgrLock.Lock;
  try
    if not (FObject.m_MapID >= m_nObjectCount) then
    begin
      if PTPNObjectNode(m_Buckets[FObject.m_MapID])^.m_IsUsed then
      begin
        PTPNObjectNode(m_Buckets[FObject.m_MapID])^.m_pPNObject := nil;
        PTPNObjectNode(m_Buckets[FObject.m_MapID])^.m_IsUsed := FALSE;
        //入队
        m_FreeBuckets.Enqueue(PTPNObjectNode(m_Buckets[FObject.m_MapID]));
        Dec(m_nActiveCount);
        Result := TRUE;

//        {$IFDEF _ICOP_DEBUG}
//           _GlobalLogger.AppendErrorLogMessage('RemovePNObject成功, MapID: %d, 活动Count: %d.',
//                                              [ FObject.m_MapID, m_nActiveCount]);
//        {$ENDIF}
      end
      else
      begin
//        {$IFDEF _ICOP_DEBUGERR}
//           _GlobalLogger.AppendErrorLogMessage('RemovePNObject失败, MapID: %d, 活动Count: %d.',
//                                              [ FObject.m_MapID, m_nActiveCount]);
//        {$ENDIF}
      end;
    end
    else
    begin
//      {$IFDEF _ICOP_DEBUGERR}
//          _GlobalLogger.AppendErrorLogMessage('RemovePNObject错误, MapID: %d, Count: %d.',
//                                              [FObject.m_MapID, m_nObjectCount]);
//      {$ENDIF}
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

end.


