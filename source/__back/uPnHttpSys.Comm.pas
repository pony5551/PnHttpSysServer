unit uPnHttpSys.Comm;

interface

uses
  System.SysUtils,
  Winapi.Windows,
  uPnHttpSys.Api,
  SynZip;

type
{$ifdef UNICODE}
  /// define the fastest Unicode string type of the compiler
  SynUnicode = UnicodeString;
  /// define a raw 8-bit storage string type, used for data buffer management
  SockString = type RawByteString;
{$else}
  /// define the fastest 16-bit Unicode string type of the compiler
  SynUnicode = WideString;
  {$ifdef HASCODEPAGE} // FPC may expect a CP, e.g. to compare two string constants
  SockString = type RawByteString;
  {$else}
  /// define a 8-bit raw storage string type, used for data buffer management
  SockString = type AnsiString;
  {$endif}
{$endif}
  /// points to a 8-bit raw storage variable, used for data buffer management
  PSockString = ^SockString;

  /// defines a dynamic array of SockString
  TSockStringDynArray = array of SockString;

{$ifdef DELPHI5OROLDER}
  // not defined in Delphi 5 or older
  PPointer = ^Pointer;
  TTextLineBreakStyle = (tlbsLF, tlbsCRLF);
  UTF8String = AnsiString;
  UTF8Encode = AnsiString;
{$endif}

{$ifndef FPC}

  /// FPC 64-bit compatibility integer type
  {$ifdef CPU64}
  PtrInt = NativeInt;
  PtrUInt = NativeUInt;
  {$else}
  PtrInt = integer;
  PtrUInt = cardinal;
  {$endif}
  /// FPC 64-bit compatibility pointer type
  PPtrInt = ^PtrInt;
  PPtrUInt = ^PtrUInt;

{$endif FPC}


//HTTP Status Code
const
  /// HTTP Status Code for "Success"
  STATUS_SUCCESS = 200;
  /// HTTP Status Code for "Created"
  STATUS_CREATED = 201;
  /// HTTP Status Code for "Accepted"
  STATUS_ACCEPTED = 202;
  /// HTTP Status Code for "No Content"
  STATUS_NOCONTENT = 204;
  /// HTTP Status Code for "Partial Content"
  STATUS_PARTIALCONTENT = 206;
  /// HTTP Status Code for "Not Modified"
  STATUS_NOTMODIFIED = 304;
  /// HTTP Status Code for "Bad Request"
  STATUS_BADREQUEST = 400;
  /// HTTP Status Code for "Unauthorized"
  STATUS_UNAUTHORIZED = 401;
  /// HTTP Status Code for "Forbidden"
  STATUS_FORBIDDEN = 403;
  /// HTTP Status Code for "Not Found"
  STATUS_NOTFOUND = 404;
  /// HTTP Status Code for "Not Acceptable"
  STATUS_NOTACCEPTABLE = 406;
  /// HTTP Status Code for "Payload Too Large"
  STATUS_PAYLOADTOOLARGE = 413;
  /// HTTP Status Code for "Internal Server Error"
  STATUS_SERVERERROR = 500;
  /// HTTP Status Code for "Not Implemented"
  STATUS_NOTIMPLEMENTED = 501;


  HTTP_RESP_STATICFILE = '!STATICFILE';
  HTTP_RESP_NORESPONSE = '!NORESPONSE';


type
{$IFDEF PNSTRING}
  PPNString = ^TPNString;
  TPNString = record
  public
    FValue: SockString;
  private
    m_Len: Integer;  //物理长度
    m_RealLen: Integer;  //实际长度
    function GetLen: Integer;
    procedure SetLen(const nValue: Integer);
    function GetLength: Integer;
    procedure SetLength(const nValue: Integer);
  public
    class operator Implicit(const S: SockString): TPNString;
    class operator Implicit(const S: TPNString): SockString;

    function From(p: PAnsiChar; ALen: Integer): PPNString;
    procedure InitAndClean(ALen: Integer = 1024);
    //物理长度
    property Len: Integer read GetLen write SetLen;
    //实际长度
    property Length: Integer read GetLength write SetLength;
  end;
{$ENDIF}

  /// event used to compress or uncompress some data during HTTP protocol
  // - should always return the protocol name for ACCEPT-ENCODING: header
  // e.g. 'gzip' or 'deflate' for standard HTTP format, but you can add
  // your own (like 'synlzo' or 'synlz')
  // - the data is compressed (if Compress=TRUE) or uncompressed (if
  // Compress=FALSE) in the Data variable (i.e. it is modified in-place)
  // - to be used with THttpSocket.RegisterCompress method
  // - DataRawByteStringtype should be a generic AnsiString/RawByteString, which
  // should be in practice a SockString or a RawByteString
  THttpSocketCompress = function(var DataRawByteString; Compress: boolean): AnsiString;

  /// used to maintain a list of known compression algorithms
  THttpSocketCompressRec = record
    /// the compression name, as in ACCEPT-ENCODING: header (gzip,deflate,synlz)
    Name: SockString;
    /// the function handling compression and decompression
    Func: THttpSocketCompress;
    /// the size in bytes after which compress will take place
    // - will be 1024 e.g. for 'zip' or 'deflate'
    // - could be 0 e.g. when encrypting the content, meaning "always compress"
    CompressMinSize: integer;
  end;

  /// list of known compression algorithms
  THttpSocketCompressRecDynArray = array of THttpSocketCompressRec;

  /// identify some items in a list of known compression algorithms
  THttpSocketCompressSet = set of 0..31;


  /// http.sys API 2.0 logging option flags
  // - used to alter the default logging behavior
  // - hlfLocalTimeRollover would force the log file rollovers by local time,
  // instead of the default GMT time
  // - hlfUseUTF8Conversion will use UTF-8 instead of default local code page
  // - only one of hlfLogErrorsOnly and hlfLogSuccessOnly flag could be set
  // at a time: if neither of them are present, both errors and success will
  // be logged, otherwise mutually exclusive flags could be set to force only
  // errors or success logging
  // - match low-level HTTP_LOGGING_FLAG_* constants as defined in HTTP 2.0 API
  THttpApiLoggingFlags = set of (
    hlfLocalTimeRollover, hlfUseUTF8Conversion,
    hlfLogErrorsOnly, hlfLogSuccessOnly);

  /// http.sys API 2.0 fields used for W3C logging
  // - match low-level HTTP_LOG_FIELD_* constants as defined in HTTP 2.0 API
  THttpApiLogFields = set of (
    hlfDate, hlfTime, hlfClientIP, hlfUserName, hlfSiteName, hlfComputerName,
    hlfServerIP, hlfMethod, hlfURIStem, hlfURIQuery, hlfStatus, hlfWIN32Status,
    hlfBytesSent, hlfBytesRecv, hlfTimeTaken, hlfServerPort, hlfUserAgent,
    hlfCookie, hlfReferer, hlfVersion, hlfHost, hlfSubStatus);



{ functions }
function CompressDeflateEx(var DataRawByteString; Compress: boolean): AnsiString;
function RetrieveHeaders(const Request: HTTP_REQUEST;
  const RemoteIPHeadUp: SockString; out RemoteIP: {$IFDEF PNSTRING}TPNString{$ELSE}SockString{$ENDIF}): SockString;
function ComputeContentEncoding(const Compress: THttpSocketCompressRecDynArray;
  P: PAnsiChar): THttpSocketCompressSet;
function RegisterCompressFunc(var Compress: THttpSocketCompressRecDynArray;
  aFunction: THttpSocketCompress; var aAcceptEncoding: SockString;
  aCompressMinSize: integer): SockString;
function CompressDataAndGetHeaders(Accepted: THttpSocketCompressSet;
  const Handled: THttpSocketCompressRecDynArray; const OutContentType: SockString;
  var OutContent: {$IFDEF PNSTRING}TPNString{$ELSE}SockString{$ENDIF}): SockString;
//{$ENDIF}
procedure GetDomainUserNameFromToken(UserToken: THandle; var result: SockString);
function GetCardinal(P: PAnsiChar): cardinal; overload;
function GetCardinal(P,PEnd: PAnsiChar): cardinal; overload;
function StatusCodeToReason(Code: Cardinal): SockString;
function IdemPChar(p, up: pAnsiChar): Boolean;
function IdemPCharArray(p: PAnsiChar; const upArray: array of PAnsiChar): integer;
function HtmlEncode(const s: SockString): SockString;
function GetNextItemUInt64(var P: PAnsiChar): ULONGLONG;
procedure AppendI64(value: Int64; var dest: shortstring);
procedure AppendChar(chr: AnsiChar; var dest: shortstring);

function DateTimeToGMTRFC822(const DateTime: TDateTime): string;
function GMTRFC822ToDateTime(const pSour: AnsiString): TDateTime;


implementation

uses
  System.Classes,
  SynWinSock,
  System.DateUtils;


{$IFDEF PNSTRING}
{ TPNString }
function TPNString.GetLen: Integer;
begin
  Result := m_Len;
end;

procedure TPNString.SetLen(const nValue: Integer);
begin
  m_Len := nValue;
  System.SetLength(FValue, m_Len);
end;

function TPNString.GetLength: Integer;
begin
  Result := m_RealLen;
end;

procedure TPNString.SetLength(const nValue: Integer);
begin
  if nValue>m_Len then
  begin
    m_Len := nValue;
    m_RealLen := nValue;
    System.SetLength(FValue, m_Len);
  end
  else begin
    m_RealLen := nValue;
  end;
end;

class operator TPNString.Implicit(const S: SockString): TPNString;
begin
  Result.From(PAnsiChar(S), System.Length(S));
end;

class operator TPNString.Implicit(const S: TPNString): SockString;
begin
  //Pointer(Result) := PAnsiChar(S.FValue);
  Result := S.FValue;
end;

function TPNString.From(p: PAnsiChar; ALen: Integer): PPNString;
begin
  SetLength(ALen);
  Move(p^, PAnsiChar(FValue)^, ALen);
  Result := @Self;
end;

procedure TPNString.InitAndClean(ALen: Integer);
begin
  SetLength(ALen);
  FillChar(PAnsiChar(FValue)^, m_Len, 0);
end;

{$ENDIF}


const
  HTTP_LEVEL = 1; // 6 is standard, but 1 is enough and faster

procedure CompressInternal(var Data: {$IFDEF PNSTRING}TPNString{$ELSE}SockString{$ENDIF}; Compress, ZLib: boolean);
var tmp: ZipString;
    DataLen: integer;
    LStream: TMemoryStream;
begin
  {$IFDEF PNSTRING}
  tmp := Data.FValue;
  DataLen := Data.Length;
  {$ELSE}
  tmp := Data;
  DataLen := Length(Data);
  {$ENDIF}
  if Compress then
  begin
    LStream := TMemoryStream.Create;
    try
      CompressStream(pointer(tmp),DataLen,LStream,HTTP_LEVEL,ZLib,0);
      LStream.Position := 0;
      {$IFDEF PNSTRING}
      Data.Length := LStream.Size;
      LStream.Read(PAnsiChar(Data.FValue)^, LStream.Size);
      {$ELSE}
      SetLength(Data, LStream.Size);
      LStream.Read(PAnsiChar(Data)^, LStream.Size);
      {$ENDIF}
    finally
      LStream.Free;
    end;
  end
  else begin
    LStream := TMemoryStream.Create;
    try
      UnCompressStream(pointer(tmp),DataLen,LStream,nil,ZLib,0);
      LStream.Position := 0;
      {$IFDEF PNSTRING}
      Data.Length := LStream.Size;
      LStream.Read(PAnsiChar(Data.FValue)^, LStream.Size);
      {$ELSE}
      SetLength(Data, LStream.Size);
      LStream.Read(PAnsiChar(Data)^, LStream.Size);
      {$ENDIF}
    finally
      LStream.Free;
    end;
  end;
end;

function CompressDeflateEx(var DataRawByteString; Compress: boolean): AnsiString;
var Data: {$IFDEF PNSTRING}TPNString{$ELSE}SockString{$ENDIF} absolute DataRawByteString;
begin
  CompressInternal(Data,Compress,false);
  result := 'deflate';
end;


{ functions }
function GetSinIP(const Sin: TVarSin): AnsiString;
var
  p: PAnsiChar;
  host: array[0..NI_MAXHOST] of AnsiChar;
  serv: array[0..NI_MAXSERV] of AnsiChar;
  hostlen, servlen: integer;
  r: integer;
begin
  result := '';
  if not IsNewApi(Sin.AddressFamily) then
  begin
    p := inet_ntoa(Sin.sin_addr);
    if p <> nil then
      result := p;
  end
  else begin
    hostlen := NI_MAXHOST;
    servlen := NI_MAXSERV;
    r := getnameinfo(@Sin, SizeOfVarSin(Sin), host, hostlen, serv, servlen,
      NI_NUMERICHOST + NI_NUMERICSERV);
    if r = 0 then
      result := host;
  end;
end;

procedure IP4Text(const ip4addr; var result: {$IFDEF PNSTRING}TPNString{$ELSE}SockString{$ENDIF});
var b: array[0..3] of byte absolute ip4addr;
begin
  if cardinal(ip4addr)=0 then
    result := ''
  else
    if cardinal(ip4addr)=$0100007f then
      result := '127.0.0.1'
    else
      result := SockString(Format('%d.%d.%d.%d',[b[0],b[1],b[2],b[3]]))
end;

procedure GetSinIPFromCache(const sin: TVarSin; var result: {$IFDEF PNSTRING}TPNString{$ELSE}SockString{$ENDIF});
begin
  if sin.sin_family=AF_INET then
    IP4Text(sin.sin_addr,result)
  else begin
    result := GetSinIP(sin); // AF_INET6 may be optimized in a future revision
    {$IFDEF PNSTRING}
    if result.FValue='::1' then
    {$ELSE}
    if result='::1' then
    {$ENDIF}
      result := '127.0.0.1'; // IP6 localhost loopback benefits of matching IP4
  end;
end;

const
  REMOTEIP_HEADERLEN = 10;
  REMOTEIP_HEADER: string[REMOTEIP_HEADERLEN] = 'RemoteIP: ';
  KNOWNHEADERS: array[HttpHeaderCacheControl..HttpHeaderUserAgent] of string[19] = (
    'Cache-Control','Connection','Date','Keep-Alive','Pragma','Trailer',
    'Transfer-Encoding','Upgrade','Via','Warning','Allow','Content-Length',
    'Content-Type','Content-Encoding','Content-Language','Content-Location',
    'Content-MD5','Content-Range','Expires','Last-Modified','Accept',
    'Accept-Charset','Accept-Encoding','Accept-Language','Authorization',
    'Cookie','Expect','From','Host','If-Match','If-Modified-Since',
    'If-None-Match','If-Range','If-Unmodified-Since','Max-Forwards',
    'Proxy-Authorization','Referer','Range','TE','Translate','User-Agent');

function RetrieveHeaders(const Request: HTTP_REQUEST;
  const RemoteIPHeadUp: SockString; out RemoteIP: {$IFDEF PNSTRING}TPNString{$ELSE}SockString{$ENDIF}): SockString;
var i, L, Lip: integer;
    H: HTTP_HEADER_ID;
    P: PHTTP_UNKNOWN_HEADER;
    D: PAnsiChar;
begin
  assert(low(KNOWNHEADERS)=low(Request.Headers.KnownHeaders));
  assert(high(KNOWNHEADERS)=high(Request.Headers.KnownHeaders));
  // compute remote IP
  L := length(RemoteIPHeadUp);
  if L<>0 then
  begin
    P := Request.Headers.pUnknownHeaders;
    if P<>nil then
    for i := 1 to Request.Headers.UnknownHeaderCount do
      if (P^.NameLength=L) and IdemPChar(PUTF8Char(P^.pName),Pointer(RemoteIPHeadUp)) then
      begin
        {$IFDEF PNSTRING}
        RemoteIP.From(p^.pRawValue,p^.RawValueLength);
        {$ELSE}
        SetString(RemoteIP,p^.pRawValue,p^.RawValueLength);
        {$ENDIF}
        break;
      end
      else
        inc(P);
  end;
  if (RemoteIP{$IFDEF PNSTRING}.FValue{$ENDIF}='') and (Request.Address.pRemoteAddress<>nil) then
    GetSinIPFromCache(PVarSin(Request.Address.pRemoteAddress)^,RemoteIP);
  // compute headers length
  {$IFDEF PNSTRING}
  Lip := RemoteIP.Length;
  {$ELSE}
  Lip := Length(RemoteIP);
  {$ENDIF}
  if Lip<>0 then
    L := (REMOTEIP_HEADERLEN+2)+Lip
  else
    L := 0;
  for H := low(KNOWNHEADERS) to high(KNOWNHEADERS) do
    if Request.Headers.KnownHeaders[h].RawValueLength<>0 then
      inc(L,Request.Headers.KnownHeaders[h].RawValueLength+ord(KNOWNHEADERS[h][0])+4);
  P := Request.Headers.pUnknownHeaders;
  if P<>nil then
    for i := 1 to Request.Headers.UnknownHeaderCount do
    begin
      inc(L,P^.NameLength+P^.RawValueLength+4); // +4 for each ': '+#13#10
      inc(P);
    end;
  // set headers content
  SetString(result,nil,L);
  D := pointer(result);
  for H := low(KNOWNHEADERS) to high(KNOWNHEADERS) do
    if Request.Headers.KnownHeaders[h].RawValueLength<>0 then
    begin
      move(KNOWNHEADERS[h][1],D^,ord(KNOWNHEADERS[h][0]));
      inc(D,ord(KNOWNHEADERS[h][0]));
      PWord(D)^ := ord(':')+ord(' ')shl 8;
      inc(D,2);
      move(Request.Headers.KnownHeaders[h].pRawValue^,D^,
        Request.Headers.KnownHeaders[h].RawValueLength);
      inc(D,Request.Headers.KnownHeaders[h].RawValueLength);
      PWord(D)^ := 13+10 shl 8;
      inc(D,2);
    end;
  P := Request.Headers.pUnknownHeaders;
  if P<>nil then
    for i := 1 to Request.Headers.UnknownHeaderCount do
    begin
      move(P^.pName^,D^,P^.NameLength);
      inc(D,P^.NameLength);
      PWord(D)^ := ord(':')+ord(' ')shl 8;
      inc(D,2);
      move(P^.pRawValue^,D^,P^.RawValueLength);
      inc(D,P^.RawValueLength);
      inc(P);
      PWord(D)^ := 13+10 shl 8;
      inc(D,2);
    end;
  if Lip<>0 then
  begin
    move(REMOTEIP_HEADER[1],D^,REMOTEIP_HEADERLEN);
    inc(D,REMOTEIP_HEADERLEN);
    {$IFDEF PNSTRING}
    move(pointer(RemoteIP.FValue)^,D^,Lip);
    {$ELSE}
    move(pointer(RemoteIP)^,D^,Lip);
    {$ENDIF}
    inc(D,Lip);
    PWord(D)^ := 13+10 shl 8;
  {$ifopt C+}
    inc(D,2);
  end;
  assert(D-pointer(result)=L);
  {$else}
  end;
  {$endif}
end;

procedure GetDomainUserNameFromToken(UserToken: THandle; var result: SockString);
var Buffer: array[0..511] of byte;
    BufferSize, UserSize, DomainSize: DWORD;
    UserInfo: PSIDAndAttributes;
    NameUse: {$ifdef FPC}SID_NAME_USE{$else}Cardinal{$endif};
    tmp: SynUnicode;
    P: PWideChar;
begin
   if not GetTokenInformation(UserToken,TokenUser,@Buffer,SizeOf(Buffer),BufferSize) then
     exit;
   UserInfo := @Buffer;
   UserSize := 0;
   DomainSize := 0;
   LookupAccountSidW(nil,UserInfo^.Sid,nil,UserSize,nil,DomainSize,NameUse);
   if (UserSize=0) or (DomainSize=0) then
     exit;
   SetLength(tmp,UserSize+DomainSize-1);
   P := pointer(tmp);
   if not LookupAccountSidW(nil,UserInfo^.Sid,P+DomainSize,UserSize,P,DomainSize,NameUse) then
     exit;
   P[DomainSize] := '\';
   result := {$ifdef UNICODE}UTF8String{$else}UTF8Encode{$endif}(tmp);
end;

function GetCardinal(P: PAnsiChar): cardinal; overload;
var c: cardinal;
begin
  if P=nil then
  begin
    result := 0;
    exit;
  end;
  if P^=' ' then
    repeat inc(P) until P^<>' ';
  c := byte(P^)-48;
  if c>9 then
    result := 0
  else begin
    result := c;
    inc(P);
    repeat
      c := byte(P^)-48;
      if c>9 then
        break else
        result := result*10+c;
      inc(P);
    until false;
  end;
end;

function GetCardinal(P,PEnd: PAnsiChar): cardinal; overload;
var c: cardinal;
begin
  result := 0;
  if (P=nil) or (P>=PEnd) then
    exit;
  if P^=' ' then
    repeat
      inc(P);
      if P=PEnd then exit;
    until P^<>' ';
  c := byte(P^)-48;
  if c>9 then
    exit;
  result := c;
  inc(P);
  while P<PEnd do
  begin
    c := byte(P^)-48;
    if c>9 then
      break
    else
      result := result*10+c;
    inc(P);
  end;
end;


var
  ReasonCache: array[1..5,0..8] of SockString; // avoid memory allocation

function StatusCodeToReasonInternal(Code: cardinal): SockString;
begin
  case Code of
    100: result := 'Continue';
    101: result := 'Switching Protocols';
    200: result := 'OK';
    201: result := 'Created';
    202: result := 'Accepted';
    203: result := 'Non-Authoritative Information';
    204: result := 'No Content';
    205: result := 'Reset Content';
    206: result := 'Partial Content';
    207: result := 'Multi-Status';
    300: result := 'Multiple Choices';
    301: result := 'Moved Permanently';
    302: result := 'Found';
    303: result := 'See Other';
    304: result := 'Not Modified';
    305: result := 'Use Proxy';
    307: result := 'Temporary Redirect';
    308: result := 'Permanent Redirect';
    400: result := 'Bad Request';
    401: result := 'Unauthorized';
    403: result := 'Forbidden';
    404: result := 'Not Found';
    405: result := 'Method Not Allowed';
    406: result := 'Not Acceptable';
    407: result := 'Proxy Authentication Required';
    408: result := 'Request Timeout';
    409: result := 'Conflict';
    410: result := 'Gone';
    411: result := 'Length Required';
    412: result := 'Precondition Failed';
    413: result := 'Payload Too Large';
    414: result := 'URI Too Long';
    415: result := 'Unsupported Media Type';
    416: result := 'Requested Range Not Satisfiable';
    426: result := 'Upgrade Required';
    500: result := 'Internal Server Error';
    501: result := 'Not Implemented';
    502: result := 'Bad Gateway';
    503: result := 'Service Unavailable';
    504: result := 'Gateway Timeout';
    505: result := 'HTTP Version Not Supported';
    511: result := 'Network Authentication Required';
    else result := 'Invalid Request';
  end;
end;

function StatusCodeToReason(Code: Cardinal): SockString;
var Hi,Lo: cardinal;
begin
  if Code=200 then
  begin // optimistic approach :)
    Hi := 2;
    Lo := 0;
  end
  else begin
    Hi := Code div 100;
    Lo := Code-Hi*100;
    if not ((Hi in [1..5]) and (Lo in [0..8])) then
    begin
      result := StatusCodeToReasonInternal(Code);
      exit;
    end;
  end;
  result := ReasonCache[Hi,Lo];
  if result<>'' then
    exit;
  result := StatusCodeToReasonInternal(Code);
  ReasonCache[Hi,Lo] := result;
end;

function IdemPChar(p, up: pAnsiChar): Boolean;
// if the beginning of p^ is same as up^ (ignore case - up^ must be already Upper)
var
  c: AnsiChar;
begin
  result := false;
  if p=nil then
    exit;
  if (up<>nil) and (up^<>#0) then
    repeat
      c := p^;
      if up^<>c then
        if c in ['a'..'z'] then
        begin
          dec(c,32);
          if up^<>c then
            exit;
        end
        else
          exit;
      inc(up);
      inc(p);
    until up^=#0;
  result := true;
end;

function IdemPCharArray(p: PAnsiChar; const upArray: array of PAnsiChar): integer;
var w: word;
begin
  if p<>nil then
  begin
    w := ord(p[0])+ord(p[1])shl 8;
    if p[0] in ['a'..'z'] then
      dec(w,32);
    if p[1] in ['a'..'z'] then
      dec(w,32 shl 8);
    for result := 0 to high(upArray) do
      if (PWord(upArray[result])^=w) and IdemPChar(p+2,upArray[result]+2) then
        exit;
  end;
  result := -1;
end;

/// decode 'CONTENT-ENCODING: ' parameter from registered compression list
function ComputeContentEncoding(const Compress: THttpSocketCompressRecDynArray;
  P: PAnsiChar): THttpSocketCompressSet;
var i: integer;
    aName: SockString;
    Beg: PAnsiChar;
begin
  integer(result) := 0;
  if P<>nil then
    repeat
      while P^ in [' ',','] do inc(P);
      Beg := P; // 'gzip;q=1.0, deflate' -> aName='gzip' then 'deflate'
      while not (P^ in [';',',',#0]) do inc(P);
      SetString(aName,Beg,P-Beg);
      for i := 0 to high(Compress) do
        if aName=Compress[i].Name then
          include(result,i);
      while not (P^ in [',',#0]) do inc(P);
    until P^=#0;
end;

function RegisterCompressFunc(var Compress: THttpSocketCompressRecDynArray;
  aFunction: THttpSocketCompress; var aAcceptEncoding: SockString;
  aCompressMinSize: integer): SockString;
var i, n: integer;
    dummy: {$IFDEF PNSTRING}TPNString{$ELSE}SockString{$ENDIF};
    aName: SockString;
begin
  result := '';
  if @aFunction=nil then
    exit;
  n := length(Compress);
  {$IFDEF PNSTRING}
  dummy.Len := 0;
  dummy.InitAndClean(16);
  {$ENDIF}
  aName := aFunction(dummy,true);
  for i := 0 to n-1 do
    with Compress[i] do
      if Name=aName then
      begin // already set
        if @Func=@aFunction then // update min. compress size value
          CompressMinSize := aCompressMinSize;
        exit;
      end;
  if n=sizeof(integer)*8 then
    exit; // fCompressHeader is 0..31 (casted as integer)
  SetLength(Compress,n+1);
  with Compress[n] do
  begin
    Name := aName;
    @Func := @aFunction;
    CompressMinSize := aCompressMinSize;
  end;
  if aAcceptEncoding='' then
    aAcceptEncoding := 'Accept-Encoding: '+aName
  else
    aAcceptEncoding := aAcceptEncoding+','+aName;
  result := aName;
end;

function CompressDataAndGetHeaders(Accepted: THttpSocketCompressSet;
  const Handled: THttpSocketCompressRecDynArray; const OutContentType: SockString;
  var OutContent: {$IFDEF PNSTRING}TPNString{$ELSE}SockString{$ENDIF}): SockString;
var i, OutContentLen: integer;
    compressible: boolean;
    OutContentTypeP: PAnsiChar absolute OutContentType;
begin
  if (integer(Accepted)<>0) and (OutContentType<>'') and (Handled<>nil) then
  begin
    {$IFDEF PNSTRING}
    OutContentLen := OutContent.Length;
    {$ELSE}
    OutContentLen := Length(OutContent);
    {$ENDIF}
    case IdemPCharArray(OutContentTypeP,['TEXT/','IMAGE/','APPLICATION/']) of
      0: compressible := true;
      1: compressible := IdemPCharArray(OutContentTypeP+6,['SVG','X-ICO'])>=0;
      2: compressible := IdemPCharArray(OutContentTypeP+12,['JSON','XML','JAVASCRIPT'])>=0;
    else
      compressible := false;
    end;
    for i := 0 to high(Handled) do
      if i in Accepted then
        with Handled[i] do
          if (CompressMinSize=0) or // 0 here means "always" (e.g. for encryption)
             (compressible and (OutContentLen>=CompressMinSize)) then
          begin
            // compression of the OutContent + update header
            result := Func(OutContent,true);
            exit; // first in fCompress[] is prefered
          end;
  end;
  result := '';
end;

function HtmlEncode(const s: SockString): SockString;
var i: integer;
begin // not very fast, but working
  result := '';
  for i := 1 to length(s) do
    case s[i] of
      '<': result := result+'&lt;';
      '>': result := result+'&gt;';
      '&': result := result+'&amp;';
      '"': result := result+'&quot;';
      else result := result+s[i];
    end;
end;

function GetNextItemUInt64(var P: PAnsiChar): ULONGLONG;
var c: PtrUInt;
begin
  result := 0;
  if P<>nil then
    repeat
      c := byte(P^)-48;
      if c>9 then
        break else
        result := result*10+ULONGLONG(c);
      inc(P);
    until false;
end; // P^ will point to the first non digit char

procedure AppendI64(value: Int64; var dest: shortstring);
var
  temp: shortstring;
begin
  str(value,temp);
  dest := dest+temp;
end;

procedure AppendChar(chr: AnsiChar; var dest: shortstring);
begin
  inc(dest[0]);
  dest[ord(dest[0])] := chr;
end;



//form http://blog.qdac.cc/?p=2573
const
  Convert: array[0..255] of Integer =
    (
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1,
     -1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
     -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
     );

function PCharToIntDef(const S: PAnsichar; Len: Integer; def: Integer = 0): Integer;
var
  I: Integer;
  v: Integer;
begin
  Result := 0;
  for I := 0 to len-1 do begin
    V := Convert[ord(s[i])];
    if V<0 then begin
      Result := def;
      Exit;
    end;
    result := (result * 10) + V;
  end;
end;

function LocalTimeZoneBias: Integer;
{$IFDEF LINUX}
var
  TV: TTimeval;
  TZ: TTimezone;
begin
  gettimeofday(TV, TZ);
  Result := TZ.tz_minuteswest;
end;
{$ELSE}
var
  TimeZoneInformation: TTimeZoneInformation;
  Bias: Longint;
begin
  case GetTimeZoneInformation(TimeZoneInformation) of
    TIME_ZONE_ID_STANDARD: Bias := TimeZoneInformation.Bias + TimeZoneInformation.StandardBias;
    TIME_ZONE_ID_DAYLIGHT: Bias := TimeZoneInformation.Bias + ((TimeZoneInformation.DaylightBias div 60) * -100);
  else
    Bias := TimeZoneInformation.Bias;
  end;
  Result := Bias;
end;
{$ENDIF}

var
  DLocalTimeZoneBias: Double = 0;

function DateTimeToGMT(const DT: TDateTime): TDateTime; inline;
begin
  Result := DT + DLocalTimeZoneBias;
end;

function GMTToDateTime(const DT: TDateTime): TDateTime; inline;
begin
  Result := DT - DLocalTimeZoneBias;
end;

function DateTimeToGMTRFC822(const DateTime: TDateTime): string;
const
  WEEK: array[1..7] of string = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
  STR_ENGLISH_M: array[1..12] of string = ('Jan', 'Feb', 'Mar', 'Apr', 'May',
    'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
var
  wWeek, wYear, wMonth, wDay, wHour, wMin, wSec, wMilliSec: Word;
begin
  DecodeDateTime(DateTimeToGMT(DateTime), wYear, wMonth, wDay, wHour, wMin, wSec, wMilliSec);
  wWeek := DayOfWeek(DateTimeToGMT(DateTime));
  Result := Format('%s, %.2d %s %.4d %.2d:%.2d:%.2d GMT',
    [WEEK[wWeek], wDay, STR_ENGLISH_M[wMonth], wYear, wHour, wMin, wSec]);
end;

function GMTRFC822ToDateTime(const pSour: AnsiString): TDateTime;

  function GetMonthDig(const Value: PAnsiChar): Integer;
  const
    STR_ENGLISH_M: array[1..12] of PAnsiChar = ('Jan', 'Feb', 'Mar', 'Apr', 'May',
      'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
  begin
    for Result := Low(STR_ENGLISH_M) to High(STR_ENGLISH_M) do begin
      if StrLIComp(Value, STR_ENGLISH_M[Result], 3) = 0 then
        Exit;
    end;
    Result := 0;
  end;
var
  P1, P2, PMax: PAnsiChar;
  wDay, wMonth, wYear, wHour, wMinute, wSec: SmallInt;
begin
  Result := 0;
  if Length(pSour) < 25 then Exit;
  P1 := Pointer(pSour);
  P2 := P1;
  PMax := P1 + Length(pSour);
  while (P1 < PMax) and (P1^ <> ',') do Inc(P1); Inc(P1);
  if (P1^ <> #32) and (P1 - P2 < 4) then Exit;
  Inc(P1); P2 := P1;
  while (P1 < PMax) and (P1^ <> #32) do Inc(P1);
  if (P1^ <> #32) then Exit;
  wDay := PCharToIntDef(P2, P1 - P2);
  if wDay = 0 then Exit;
  Inc(P1); P2 := P1;

  while (P1 < PMax) and (P1^ <> #32) do Inc(P1);
  if (P1^ <> #32) and (P1 - P2 < 3) then Exit;
  wMonth := GetMonthDig(P2);
  Inc(P1); P2 := P1;

  while (P1 < PMax) and (P1^ <> #32) do Inc(P1);
  if (P1^ <> #32) then Exit;
  wYear := PCharToIntDef(P2, P1 - P2);
  if wYear = 0 then Exit;
  Inc(P1); P2 := P1;

  while (P1 < PMax) and (P1^ <> ':') do Inc(P1);
  if (P1^ <> ':') then Exit;
  wHour := PCharToIntDef(P2, P1 - P2);
  if wHour = 0 then Exit;
  Inc(P1); P2 := P1;

  while (P1 < PMax) and (P1^ <> ':') do Inc(P1);
  if (P1^ <> ':') then Exit;
  wMinute := PCharToIntDef(P2, P1 - P2);
  if wMinute = 0 then Exit;
  Inc(P1); P2 := P1;

  while (P1 < PMax) and (P1^ <> #32) do Inc(P1);
  if (P1^ <> #32) then Exit;
  wSec := PCharToIntDef(P2, P1 - P2);
  if wSec = 0 then Exit;

  Result := GMTToDateTime(EnCodeDateTime(wYear, wMonth, wDay, wHour, wMinute, wSec, 0));
end;

initialization
  DLocalTimeZoneBias := LocalTimeZoneBias / 1440;

end.
