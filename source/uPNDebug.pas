unit uPNDebug;

interface

//{$DEFINE PNDEBUG}

uses
  System.SysUtils,
  Winapi.Windows;

procedure debug(s: string; const Args: array of const);
procedure debugEx(s: string; const Args: array of const);

implementation

procedure debug(s: string; const Args: array of const);
begin
  {$IFDEF PNDEBUG}
  OutputDebugString(PChar(Format(s, Args)));
  {$ELSE}
    {$IFDEF DEBUG}
  OutputDebugString(PChar(Format(s, Args)));
    {$ENDIF}
  {$ENDIF}
end;

procedure debugEx(s: string; const Args: array of const);
begin
  OutputDebugString(PChar(Format(s, Args)));
end;

end.

