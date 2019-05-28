unit lib.PnObject;

interface

type
  TPNObject = class
  public
    m_pNext: TPNObject;
    m_MapID: Cardinal;
  public
    constructor Create;
    destructor Destroy; override;
    procedure InitObject; virtual;

  end;

implementation

constructor TPNObject.Create;
begin
  inherited Create;
  InitObject;
end;

destructor TPNObject.Destroy;
begin
  inherited Destroy;
end;

procedure TPNObject.InitObject;
begin
  m_pNext := nil;
  m_MapID := 0;
end;

end.

