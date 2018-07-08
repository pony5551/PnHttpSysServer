unit uPnHttpSys.Api;

//{$I Sparkle.Inc}
{$SCOPEDENUMS OFF}

interface

{$IFDEF MSWINDOWS}

uses
  System.SysUtils,
  Winapi.Windows,
  SynWinSock;
  //Winapi.WinSock;

{$MinEnumSize 4}
{$Align 8}

const
  HTTP_INITIALIZE_SERVER = $00000001;
  HTTP_INITIALIZE_CONFIG = $00000002;

type
  HTTP_SERVER_PROPERTY = (
    HttpServerAuthenticationProperty,
    HttpServerLoggingProperty,
    HttpServerQosProperty,
    HttpServerTimeoutsProperty,
    HttpServerQueueLengthProperty,
    HttpServerStateProperty,
    HttpServer503VerbosityProperty,
    HttpServerBindingProperty,
    HttpServerExtendedAuthenticationProperty,
    HttpServerListenEndpointProperty,
    HttpServerChannelBindProperty,
    HttpServerProtectionLevelProperty
  );

const
  HTTP_MAX_SERVER_QUEUE_LENGTH = $7FFFFFFF;
  HTTP_MIN_SERVER_QUEUE_LENGTH = 1;

type
  HTTP_PROPERTY_FLAGS = ULONG;
  PHTTP_PROPERTY_FLAGS = ^HTTP_PROPERTY_FLAGS;

const
  HTTP_PROPERTY_FLAG_NONE = $00000000;
  HTTP_PROPERTY_FLAG_PRESENT = $00000001;

type
  HTTP_ENABLED_STATE = (
    HttpEnabledStateActive,
    HttpEnabledStateInactive
  );

  HTTP_STATE_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    State: HTTP_ENABLED_STATE;
  end;
  PHTTP_STATE_INFO = ^HTTP_STATE_INFO;

  HTTP_503_RESPONSE_VERBOSITY = (
    Http503ResponseVerbosityBasic,
    Http503ResponseVerbosityLimited,
    Http503ResponseVerbosityFull
  );

  HTTP_QOS_SETTING_TYPE = (
    HttpQosSettingTypeBandwidth,
    HttpQosSettingTypeConnectionLimit,
    HttpQosSettingTypeFlowRate
  );

  HTTP_QOS_SETTING_INFO = record
    QosType: HTTP_QOS_SETTING_TYPE;
    QosSetting: PVOID;
  end;
  PHTTP_QOS_SETTING_INFO = ^HTTP_QOS_SETTING_INFO;

  HTTP_CONNECTION_LIMIT_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    MaxConnections: ULONG;
  end;
  PHTTP_CONNECTION_LIMIT_INFO = ^HTTP_CONNECTION_LIMIT_INFO;

  HTTP_BANDWIDTH_LIMIT_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    MaxBandwidth: ULONG;
  end;
  PHTTP_BANDWIDTH_LIMIT_INFO = ^HTTP_BANDWIDTH_LIMIT_INFO;

  HTTP_FLOWRATE_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    MaxBandwidth: ULONG;
    MaxPeakBandwidth: ULONG;
    BurstSize: ULONG;
  end;
  PHTTP_FLOWRATE_INFO = ^HTTP_FLOWRATE_INFO;

const
  HTTP_MIN_ALLOWED_BANDWIDTH_THROTTLING_RATE = ULONG(1024);
  HTTP_LIMIT_INFINITE = ULONG(-1);

type
  HTTP_SERVICE_CONFIG_TIMEOUT_KEY = (
    IdleConnectionTimeout = 0,
    HeaderWaitTimeout
  );

  HTTP_SERVICE_CONFIG_TIMEOUT_PARAM = USHORT;
  PHTTP_SERVICE_CONFIG_TIMEOUT_PARAM = ^HTTP_SERVICE_CONFIG_TIMEOUT_PARAM;

  HTTP_SERVICE_CONFIG_TIMEOUT_SET = record
    KeyDesc: HTTP_SERVICE_CONFIG_TIMEOUT_KEY;
    ParamDesc: HTTP_SERVICE_CONFIG_TIMEOUT_PARAM;
  end;
  PHTTP_SERVICE_CONFIG_TIMEOUT_SET = ^HTTP_SERVICE_CONFIG_TIMEOUT_SET;

  HTTP_TIMEOUT_LIMIT_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    EntityBody: USHORT;
    DrainEntityBody: USHORT;
    RequestQueue: USHORT;
    IdleConnection: USHORT;
    HeaderWait: USHORT;
    MinSendRate: ULONG;
  end;
  PHTTP_TIMEOUT_LIMIT_INFO = ^HTTP_TIMEOUT_LIMIT_INFO;

  HTTP_LISTEN_ENDPOINT_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    EnableSharing: Boolean;
  end;
  PHTTP_LISTEN_ENDPOINT_INFO = ^HTTP_LISTEN_ENDPOINT_INFO;

  HTTP_SERVER_AUTHENTICATION_DIGEST_PARAMS = record
    DomainNameLength: USHORT;
    DomainName: PWideChar;
    RealmLength: USHORT;
    Realm: PWideChar;
  end;
  PHTTP_SERVER_AUTHENTICATION_DIGEST_PARAMS = ^HTTP_SERVER_AUTHENTICATION_DIGEST_PARAMS;

  HTTP_SERVER_AUTHENTICATION_BASIC_PARAMS = record
    RealmLength: USHORT;
    Realm: PWideChar;
  end;
  PHTTP_SERVER_AUTHENTICATION_BASIC_PARAMS = ^HTTP_SERVER_AUTHENTICATION_BASIC_PARAMS;

const
  HTTP_AUTH_ENABLE_BASIC = $00000001;
  HTTP_AUTH_ENABLE_DIGEST = $00000002;
  HTTP_AUTH_ENABLE_NTLM = $00000004;
  HTTP_AUTH_ENABLE_NEGOTIATE = $00000008;
  HTTP_AUTH_ENABLE_KERBEROS = $00000010;
  HTTP_AUTH_ENABLE_ALL = $0000001F;

  HTTP_AUTH_EX_FLAG_ENABLE_KERBEROS_CREDENTIAL_CACHING = $01;
  HTTP_AUTH_EX_FLAG_CAPTURE_CREDENTIAL = $02;

type
  HTTP_SERVER_AUTHENTICATION_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    AuthSchemes: ULONG;
    ReceiveMutualAuth: BOOLEAN;
    ReceiveContextHandle: BOOLEAN;
    DisableNTLMCredentialCaching: BOOLEAN;
    ExFlags: UCHAR;
    DigestParams: HTTP_SERVER_AUTHENTICATION_DIGEST_PARAMS;
    BasicParams: HTTP_SERVER_AUTHENTICATION_BASIC_PARAMS;
  end;
  PHTTP_SERVER_AUTHENTICATION_INFO = ^HTTP_SERVER_AUTHENTICATION_INFO;

  HTTP_SERVICE_BINDING_TYPE = (
    HttpServiceBindingTypeNone = 0,
    HttpServiceBindingTypeW,
    HttpServiceBindingTypeA
  );

  HTTP_SERVICE_BINDING_BASE = record
    _Type: HTTP_SERVICE_BINDING_TYPE;
  end;
  PHTTP_SERVICE_BINDING_BASE = ^HTTP_SERVICE_BINDING_BASE;
  PPHTTP_SERVICE_BINDING_BASE = ^PHTTP_SERVICE_BINDING_BASE;

  HTTP_SERVICE_BINDING_A = record
    Base: HTTP_SERVICE_BINDING_BASE;
    Buffer: PAnsiChar;
    BufferSize: ULONG;
  end;
  PHTTP_SERVICE_BINDING_A = ^HTTP_SERVICE_BINDING_A;

  HTTP_SERVICE_BINDING_W = record
    Base: HTTP_SERVICE_BINDING_BASE;
    Buffer: PWCHAR;
    BufferSize: ULONG;
  end;
  PHTTP_SERVICE_BINDING_W = ^HTTP_SERVICE_BINDING_W;

  HTTP_AUTHENTICATION_HARDENING_LEVELS = (
    HttpAuthenticationHardeningLegacy = 0,
    HttpAuthenticationHardeningMedium,
    HttpAuthenticationHardeningStrict
  );

const
  HTTP_CHANNEL_BIND_PROXY = $1;
  HTTP_CHANNEL_BIND_PROXY_COHOSTING = $20;
  HTTP_CHANNEL_BIND_NO_SERVICE_NAME_CHECK = $2;
  HTTP_CHANNEL_BIND_DOTLESS_SERVICE = $4;
  HTTP_CHANNEL_BIND_SECURE_CHANNEL_TOKEN = $8;
  HTTP_CHANNEL_BIND_CLIENT_SERVICE = $10;

type
  HTTP_CHANNEL_BIND_INFO = record
    Hardening: HTTP_AUTHENTICATION_HARDENING_LEVELS;
    Flags: ULONG;
    ServiceNames: PPHTTP_SERVICE_BINDING_BASE;
    NumberOfServiceNames: ULONG;
  end;
  PHTTP_CHANNEL_BIND_INFO = ^HTTP_CHANNEL_BIND_INFO;

  HTTP_REQUEST_CHANNEL_BIND_STATUS = record
    ServiceName: PHTTP_SERVICE_BINDING_BASE;
    ChannelToken: PUCHAR;
    ChannelTokenSize: ULONG;
    Flags: ULONG;
  end;
  PHTTP_REQUEST_CHANNEL_BIND_STATUS = ^HTTP_REQUEST_CHANNEL_BIND_STATUS;

const
  HTTP_LOG_FIELD_DATE = $00000001;
  HTTP_LOG_FIELD_TIME = $00000002;
  HTTP_LOG_FIELD_CLIENT_IP = $00000004;
  HTTP_LOG_FIELD_USER_NAME = $00000008;
  HTTP_LOG_FIELD_SITE_NAME = $00000010;
  HTTP_LOG_FIELD_COMPUTER_NAME = $00000020;
  HTTP_LOG_FIELD_SERVER_IP = $00000040;
  HTTP_LOG_FIELD_METHOD = $00000080;
  HTTP_LOG_FIELD_URI_STEM = $00000100;
  HTTP_LOG_FIELD_URI_QUERY = $00000200;
  HTTP_LOG_FIELD_STATUS = $00000400;
  HTTP_LOG_FIELD_WIN32_STATUS = $00000800;
  HTTP_LOG_FIELD_BYTES_SENT = $00001000;
  HTTP_LOG_FIELD_BYTES_RECV = $00002000;
  HTTP_LOG_FIELD_TIME_TAKEN = $00004000;
  HTTP_LOG_FIELD_SERVER_PORT = $00008000;
  HTTP_LOG_FIELD_USER_AGENT = $00010000;
  HTTP_LOG_FIELD_COOKIE = $00020000;
  HTTP_LOG_FIELD_REFERER = $00040000;
  HTTP_LOG_FIELD_VERSION = $00080000;
  HTTP_LOG_FIELD_HOST = $00100000;
  HTTP_LOG_FIELD_SUB_STATUS = $00200000;

  HTTP_LOG_FIELD_CLIENT_PORT = $00400000;
  HTTP_LOG_FIELD_URI = $00800000;
  HTTP_LOG_FIELD_SITE_ID = $01000000;
  HTTP_LOG_FIELD_REASON = $02000000;
  HTTP_LOG_FIELD_QUEUE_NAME = $04000000;

type
  HTTP_LOGGING_TYPE = (
    HttpLoggingTypeW3C,
    HttpLoggingTypeIIS,
    HttpLoggingTypeNCSA,
    HttpLoggingTypeRaw
  );

  HTTP_LOGGING_ROLLOVER_TYPE = (
    HttpLoggingRolloverSize,
    HttpLoggingRolloverDaily,
    HttpLoggingRolloverWeekly,
    HttpLoggingRolloverMonthly,
    HttpLoggingRolloverHourly
  );

const
  HTTP_MIN_ALLOWED_LOG_FILE_ROLLOVER_SIZE = ULONG(1* 1024* 1024);

  HTTP_LOGGING_FLAG_LOCAL_TIME_ROLLOVER = $00000001;
  HTTP_LOGGING_FLAG_USE_UTF8_CONVERSION = $00000002;
  HTTP_LOGGING_FLAG_LOG_ERRORS_ONLY = $00000004;
  HTTP_LOGGING_FLAG_LOG_SUCCESS_ONLY = $00000008;

type
  HTTP_LOGGING_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    LoggingFlags: ULONG;
    SoftwareName: PWideChar;
    SoftwareNameLength: USHORT;
    DirectoryNameLength: USHORT;
    DirectoryName: PWideChar;
    Format: HTTP_LOGGING_TYPE;
    Fields: ULONG;
    pExtFields: PVOID;
    NumOfExtFields: USHORT;
    MaxRecordSize: USHORT;
    RolloverType: HTTP_LOGGING_ROLLOVER_TYPE;
    RolloverSize: ULONG;
    pSecurityDescriptor: PSECURITY_DESCRIPTOR;
  end;
  PHTTP_LOGGING_INFO = ^HTTP_LOGGING_INFO;

  HTTP_BINDING_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    RequestQueueHandle: THandle;
  end;
  PHTTP_BINDING_INFO = ^HTTP_BINDING_INFO;

  HTTP_PROTECTION_LEVEL_TYPE = (
    HttpProtectionLevelUnrestricted,
    HttpProtectionLevelEdgeRestricted,
    HttpProtectionLevelRestricted
  );

  HTTP_PROTECTION_LEVEL_INFO = record
    Flags: HTTP_PROPERTY_FLAGS;
    Level: HTTP_PROTECTION_LEVEL_TYPE;
  end;
  PHTTP_PROTECTION_LEVEL_INFO = ^HTTP_PROTECTION_LEVEL_INFO;

const
  HTTP_CREATE_REQUEST_QUEUE_FLAG_OPEN_EXISTING = $00000001;
  HTTP_CREATE_REQUEST_QUEUE_FLAG_CONTROLLER = $00000002;

  HTTP_RECEIVE_REQUEST_FLAG_COPY_BODY = $00000001;
  HTTP_RECEIVE_REQUEST_FLAG_FLUSH_BODY = $00000002;

  HTTP_RECEIVE_REQUEST_ENTITY_BODY_FLAG_FILL_BUFFER = $00000001;

  HTTP_SEND_RESPONSE_FLAG_DISCONNECT = $00000001;
  HTTP_SEND_RESPONSE_FLAG_MORE_DATA = $00000002;
  HTTP_SEND_RESPONSE_FLAG_BUFFER_DATA = $00000004;
  HTTP_SEND_RESPONSE_FLAG_ENABLE_NAGLING = $00000008;
  HTTP_SEND_RESPONSE_FLAG_PROCESS_RANGES = $00000020;

  HTTP_FLUSH_RESPONSE_FLAG_RECURSIVE = $00000001;

type
  HTTP_OPAQUE_ID = ULONGLONG;
  PHTTP_OPAQUE_ID = ^HTTP_OPAQUE_ID;

  HTTP_REQUEST_ID = HTTP_OPAQUE_ID;
  PHTTP_REQUEST_ID = ^HTTP_REQUEST_ID;

  HTTP_CONNECTION_ID = HTTP_OPAQUE_ID;
  PHTTP_CONNECTION_ID = ^HTTP_CONNECTION_ID;

  HTTP_RAW_CONNECTION_ID = HTTP_OPAQUE_ID;
  PHTTP_RAW_CONNECTION_ID = ^HTTP_RAW_CONNECTION_ID;

  HTTP_URL_GROUP_ID = HTTP_OPAQUE_ID;
  PHTTP_URL_GROUP_ID = ^HTTP_URL_GROUP_ID;

  HTTP_SERVER_SESSION_ID = HTTP_OPAQUE_ID;
  PHTTP_SERVER_SESSION_ID = ^HTTP_SERVER_SESSION_ID;

const
  HTTP_NULL_ID = ULONG(0);
  HTTP_BYTE_RANGE_TO_EOF = ULONGLONG(-1);

type
  HTTP_BYTE_RANGE = record
    StartingOffset: ULARGE_INTEGER;
    Length: ULARGE_INTEGER;
  end;
  PHTTP_BYTE_RANGE = ^HTTP_BYTE_RANGE;

  HTTP_VERSION = record
    MajorVersion: USHORT;
    MinorVersion: USHORT;
  end;
  PHTTP_VERSION = ^HTTP_VERSION;

const
  HTTP_VERSION_UNKNOWN: HTTP_VERSION = (MajorVersion: 0; MinorVersion: 0);
  HTTP_VERSION_0_9: HTTP_VERSION = (MajorVersion: 0; MinorVersion: 9);
  HTTP_VERSION_1_0: HTTP_VERSION = (MajorVersion: 1; MinorVersion: 0);
  HTTP_VERSION_1_1: HTTP_VERSION = (MajorVersion: 1; MinorVersion: 1);

type
  HTTP_VERB = (
    HttpVerbUnparsed,
    HttpVerbUnknown,
    HttpVerbInvalid,
    HttpVerbOPTIONS,
    HttpVerbGET,
    HttpVerbHEAD,
    HttpVerbPOST,
    HttpVerbPUT,
    HttpVerbDELETE,
    HttpVerbTRACE,
    HttpVerbCONNECT,
    HttpVerbTRACK,
    HttpVerbMOVE,
    HttpVerbCOPY,
    HttpVerbPROPFIND,
    HttpVerbPROPPATCH,
    HttpVerbMKCOL,
    HttpVerbLOCK,
    HttpVerbUNLOCK,
    HttpVerbSEARCH,
    HttpVerbMaximum
  );

  HTTP_HEADER_ID = (
    HttpHeaderCacheControl          = 0,    // general-header [section 4.5]
    HttpHeaderConnection            = 1,    // general-header [section 4.5]
    HttpHeaderDate                  = 2,    // general-header [section 4.5]
    HttpHeaderKeepAlive             = 3,    // general-header [not in rfc]
    HttpHeaderPragma                = 4,    // general-header [section 4.5]
    HttpHeaderTrailer               = 5,    // general-header [section 4.5]
    HttpHeaderTransferEncoding      = 6,    // general-header [section 4.5]
    HttpHeaderUpgrade               = 7,    // general-header [section 4.5]
    HttpHeaderVia                   = 8,    // general-header [section 4.5]
    HttpHeaderWarning               = 9,    // general-header [section 4.5]

    HttpHeaderAllow                 = 10,   // entity-header  [section 7.1]
    HttpHeaderContentLength         = 11,   // entity-header  [section 7.1]
    HttpHeaderContentType           = 12,   // entity-header  [section 7.1]
    HttpHeaderContentEncoding       = 13,   // entity-header  [section 7.1]
    HttpHeaderContentLanguage       = 14,   // entity-header  [section 7.1]
    HttpHeaderContentLocation       = 15,   // entity-header  [section 7.1]
    HttpHeaderContentMd5            = 16,   // entity-header  [section 7.1]
    HttpHeaderContentRange          = 17,   // entity-header  [section 7.1]
    HttpHeaderExpires               = 18,   // entity-header  [section 7.1]
    HttpHeaderLastModified          = 19,   // entity-header  [section 7.1]

    HttpHeaderAccept                = 20,   // request-header [section 5.3]
    HttpHeaderAcceptCharset         = 21,   // request-header [section 5.3]
    HttpHeaderAcceptEncoding        = 22,   // request-header [section 5.3]
    HttpHeaderAcceptLanguage        = 23,   // request-header [section 5.3]
    HttpHeaderAuthorization         = 24,   // request-header [section 5.3]
    HttpHeaderCookie                = 25,   // request-header [not in rfc]
    HttpHeaderExpect                = 26,   // request-header [section 5.3]
    HttpHeaderFrom                  = 27,   // request-header [section 5.3]
    HttpHeaderHost                  = 28,   // request-header [section 5.3]
    HttpHeaderIfMatch               = 29,   // request-header [section 5.3]

    HttpHeaderIfModifiedSince       = 30,   // request-header [section 5.3]
    HttpHeaderIfNoneMatch           = 31,   // request-header [section 5.3]
    HttpHeaderIfRange               = 32,   // request-header [section 5.3]
    HttpHeaderIfUnmodifiedSince     = 33,   // request-header [section 5.3]
    HttpHeaderMaxForwards           = 34,   // request-header [section 5.3]
    HttpHeaderProxyAuthorization    = 35,   // request-header [section 5.3]
    HttpHeaderReferer               = 36,   // request-header [section 5.3]
    HttpHeaderRange                 = 37,   // request-header [section 5.3]
    HttpHeaderTe                    = 38,   // request-header [section 5.3]
    HttpHeaderTranslate             = 39,   // request-header [webDAV, not in rfc 2518]
    HttpHeaderUserAgent             = 40,   // request-header [section 5.3]
    HttpHeaderRequestMaximum        = 41,

    // Response Headers
    HttpHeaderAcceptRanges          = 20,   // response-header [section 6.2]
    HttpHeaderAge                   = 21,   // response-header [section 6.2]
    HttpHeaderEtag                  = 22,   // response-header [section 6.2]
    HttpHeaderLocation              = 23,   // response-header [section 6.2]
    HttpHeaderProxyAuthenticate     = 24,   // response-header [section 6.2]
    HttpHeaderRetryAfter            = 25,   // response-header [section 6.2]
    HttpHeaderServer                = 26,   // response-header [section 6.2]
    HttpHeaderSetCookie             = 27,   // response-header [not in rfc]
    HttpHeaderVary                  = 28,   // response-header [section 6.2]
    HttpHeaderWwwAuthenticate       = 29,   // response-header [section 6.2]
    HttpHeaderResponseMaximum       = 30,

    HttpHeaderMaximum               = 41
  );

  HTTP_KNOWN_HEADER = record
    RawValueLength: USHORT;
    pRawValue: PAnsiChar;
  end;
  PHTTP_KNOWN_HEADER = ^HTTP_KNOWN_HEADER;

  HTTP_UNKNOWN_HEADER = record
    NameLength: USHORT;
    RawValueLength: USHORT;
    pName: PAnsiChar;
    pRawValue: PAnsiChar;
  end;
  PHTTP_UNKNOWN_HEADER = ^HTTP_UNKNOWN_HEADER;
  HTTP_UNKNOWN_HEADERs = array of HTTP_UNKNOWN_HEADER;

  HTTP_LOG_DATA_TYPE = (
    HttpLogDataTypeFields
  );

  HTTP_LOG_DATA = record
    _Type: HTTP_LOG_DATA_TYPE;
  end;
  PHTTP_LOG_DATA = ^HTTP_LOG_DATA;

  HTTP_LOG_FIELDS_DATA = record
    Base: HTTP_LOG_DATA;
    UserNameLength: USHORT;
    UriStemLength: USHORT;
    ClientIpLength: USHORT;
    ServerNameLength: USHORT;
    ServiceNameLength: USHORT;
    ServerIpLength: USHORT;
    MethodLength: USHORT;
    UriQueryLength: USHORT;
    HostLength: USHORT;
    UserAgentLength: USHORT;
    CookieLength: USHORT;
    ReferrerLength: USHORT;
    UserName: PWCHAR;
    UriStem: PWCHAR;
    ClientIp: PAnsiChar;
    ServerName: PAnsiChar;
    ServiceName: PAnsiChar;
    ServerIp: PAnsiChar;
    Method: PAnsiChar;
    UriQuery: PAnsiChar;
    Host: PAnsiChar;
    UserAgent: PAnsiChar;
    Cookie: PAnsiChar;
    Referrer: PAnsiChar;
    ServerPort: USHORT;
    ProtocolStatus: USHORT;
    Win32Status: ULONG;
    MethodNum: HTTP_VERB;
    SubStatus: USHORT;
  end;
  PHTTP_LOG_FIELDS_DATA = ^HTTP_LOG_FIELDS_DATA;

  HTTP_DATA_CHUNK_TYPE = (
    HttpDataChunkFromMemory,
    HttpDataChunkFromFileHandle,
    HttpDataChunkFromFragmentCache,
    HttpDataChunkFromFragmentCacheEx,
    HttpDataChunkMaximum
  );

  HTTP_DATA_CHUNK = record
    DataChunkType: HTTP_DATA_CHUNK_TYPE;
    case HTTP_DATA_CHUNK_TYPE of
      HttpDataChunkFromMemory: (
        pBuffer: PVOID;
        BufferLength: ULONG;
      );
      HttpDataChunkFromFileHandle: (
        ByteRange: HTTP_BYTE_RANGE;
			  FileHandle: THandle;
      );
      HttpDataChunkFromFragmentCache: (
        FragmentNameLength: USHORT;
        pFragmentName: PWideChar;
      );
      HttpDataChunkFromFragmentCacheEx: (
        ByteRangeEx: HTTP_BYTE_RANGE;
        pFragmentNameEx: PWideChar;
      );
  end;
  PHTTP_DATA_CHUNK = ^HTTP_DATA_CHUNK;

  HTTP_REQUEST_HEADERS = record
    UnknownHeaderCount: USHORT;
    pUnknownHeaders: PHTTP_UNKNOWN_HEADER;
    TrailerCount: USHORT;
    pTrailers: PHTTP_UNKNOWN_HEADER;
    KnownHeaders: array[Low(HTTP_HEADER_ID)..Pred(HttpHeaderRequestMaximum)] of HTTP_KNOWN_HEADER;
  end;
  PHTTP_REQUEST_HEADERS = ^HTTP_REQUEST_HEADERS;

  HTTP_RESPONSE_HEADERS = record
    UnknownHeaderCount: USHORT;
    pUnknownHeaders: PHTTP_UNKNOWN_HEADER;
    TrailerCount: USHORT;
    pTrailers: PHTTP_UNKNOWN_HEADER;
    KnownHeaders: Array[Low(HTTP_HEADER_ID)..Pred(HttpHeaderResponseMaximum)] of HTTP_KNOWN_HEADER;
  end;
  PHTTP_RESPONSE_HEADERS = ^HTTP_RESPONSE_HEADERS;

  HTTP_TRANSPORT_ADDRESS = record
    pRemoteAddress: PSOCKADDR;
    pLocalAddress: PSOCKADDR;
  end;
  PHTTP_TRANSPORT_ADDRESS = ^HTTP_TRANSPORT_ADDRESS;

  HTTP_COOKED_URL = record
    FullUrlLength: USHORT;
    HostLength: USHORT;
    AbsPathLength: USHORT;
    QueryStringLength: USHORT;
    pFullUrl: PWideChar;
    pHost: PWideChar;
    pAbsPath: PWideChar;
    pQueryString: PWideChar;
  end;
  PHTTP_COOKED_URL = ^HTTP_COOKED_URL;

  HTTP_URL_CONTEXT = ULONGLONG;

const
  HTTP_URL_FLAG_REMOVE_ALL = $00000001;

type
  HTTP_AUTH_STATUS = (
    HttpAuthStatusSuccess,
    HttpAuthStatusNotAuthenticated,
    HttpAuthStatusFailure
  );

  HTTP_REQUEST_AUTH_TYPE = (
    HttpRequestAuthTypeNone = 0,
    HttpRequestAuthTypeBasic,
    HttpRequestAuthTypeDigest,
    HttpRequestAuthTypeNTLM,
    HttpRequestAuthTypeNegotiate,
    HttpRequestAuthTypeKerberos
  );

  HTTP_SSL_CLIENT_CERT_INFO = record
    CertFlags: ULONG;
    CertEncodedSize: ULONG;
    pCertEncoded: PUCHAR;
    Token: THandle;
    CertDeniedByMapper: BOOLEAN;
  end;
  PHTTP_SSL_CLIENT_CERT_INFO = ^HTTP_SSL_CLIENT_CERT_INFO;

const
  HTTP_RECEIVE_SECURE_CHANNEL_TOKEN = $1;

type
  HTTP_SSL_INFO = record
    ServerCertKeySize: USHORT;
    ConnectionKeySize: USHORT;
    ServerCertIssuerSize: ULONG;
    ServerCertSubjectSize: ULONG;
    pServerCertIssuer: PAnsiChar;
    pServerCertSubject: PAnsiChar;
    pClientCertInfo: PHTTP_SSL_CLIENT_CERT_INFO;
    SslClientCertNegotiated: ULONG;
  end;
  PHTTP_SSL_INFO = ^HTTP_SSL_INFO;

  HTTP_REQUEST_INFO_TYPE = (
    HttpRequestInfoTypeAuth,
    HttpRequestInfoTypeChannelBind
  );

  HTTP_REQUEST_INFO = record
    InfoType: HTTP_REQUEST_INFO_TYPE;
    InfoLength: ULONG;
    pInfo: PVOID;
  end;
  PHTTP_REQUEST_INFO = ^HTTP_REQUEST_INFO;
  //pony add
  HTTP_REQUEST_INFOS = array[0..1000] of HTTP_REQUEST_INFO;
  PHTTP_REQUEST_INFOS = ^HTTP_REQUEST_INFOS;


  SECURITY_STATUS = LongInt;

const
  HTTP_REQUEST_AUTH_FLAG_TOKEN_FOR_CACHED_CRED = $00000001;

type
  HTTP_REQUEST_AUTH_INFO = record
    AuthStatus: HTTP_AUTH_STATUS;
    SecStatus: SECURITY_STATUS;
    Flags: ULONG;
    AuthType: HTTP_REQUEST_AUTH_TYPE;
    AccessToken: THandle;
    ContextAttributes: ULONG;
    PackedContextLength: ULONG;
    PackedContextType: ULONG;
    PackedContext: PVOID;
    MutualAuthDataLength: ULONG;
    pMutualAuthData: PChar;
    PackageNameLength: USHORT;
    pPackageName: PWideChar;
  end;
  PHTTP_REQUEST_AUTH_INFO = ^HTTP_REQUEST_AUTH_INFO;

  HTTP_REQUEST_V2 = record
    Flags: ULONG;
    ConnectionId: HTTP_CONNECTION_ID;
    RequestId: HTTP_REQUEST_ID;
    UrlContext: HTTP_URL_CONTEXT;
    Version: HTTP_VERSION;
    Verb: HTTP_VERB;
    UnknownVerbLength: USHORT;
    RawUrlLength: USHORT;
    pUnknownVerb: PAnsiChar;
    pRawUrl: PAnsiChar;
    CookedUrl: HTTP_COOKED_URL;
    Address: HTTP_TRANSPORT_ADDRESS;
    Headers: HTTP_REQUEST_HEADERS;
    BytesReceived: ULONGLONG;
    EntityChunkCount: USHORT;
    pEntityChunks: PHTTP_DATA_CHUNK;
    RawConnectionId: HTTP_RAW_CONNECTION_ID;
    pSslInfo: PHTTP_SSL_INFO;
    Dummy1: DWORD;
    RequestInfoCount: USHORT;
    //pRequestInfo: PHTTP_REQUEST_INFO;
    //pony modfy
    pRequestInfo: PHTTP_REQUEST_INFOS;
  end;
  PHTTP_REQUEST_V2 = ^HTTP_REQUEST_V2;

  HTTP_REQUEST = HTTP_REQUEST_V2;
  PHTTP_REQUEST = ^HTTP_REQUEST;

const
  HTTP_REQUEST_FLAG_MORE_ENTITY_BODY_EXISTS = $00000001;
  HTTP_REQUEST_FLAG_IP_ROUTED = $00000002;

const
  HTTP_RESPONSE_FLAG_MULTIPLE_ENCODINGS_AVAILABLE = $00000001;

type
  HTTP_RESPONSE_INFO_TYPE = (
    HttpResponseInfoTypeMultipleKnownHeaders,
    HttpResponseInfoTypeAuthenticationProperty,
    HttpResponseInfoTypeQoSProperty,
    HttpResponseInfoTypeChannelBind
  );

  HTTP_RESPONSE_INFO = record
    _Type: HTTP_RESPONSE_INFO_TYPE;
    Length: ULONG;
    pInfo: PVOID;
  end;
  PHTTP_RESPONSE_INFO = ^HTTP_RESPONSE_INFO;

const
  HTTP_RESPONSE_INFO_FLAGS_PRESERVE_ORDER = $00000001;

type
  HTTP_MULTIPLE_KNOWN_HEADERS = record
    HeaderId: HTTP_HEADER_ID;
    Flags: ULONG;
    KnownHeaderCount: USHORT;
    KnownHeaders: PHTTP_KNOWN_HEADER;
  end;
  PHTTP_MULTIPLE_KNOWN_HEADERS = ^HTTP_MULTIPLE_KNOWN_HEADERS;

  HTTP_RESPONSE_V2 = record
    Flags: ULONG;
    Version: HTTP_VERSION;
    StatusCode: USHORT;
    ReasonLength: USHORT;
    pReason: PAnsiChar;
    Headers: HTTP_RESPONSE_HEADERS;
    EntityChunkCount: USHORT;
    pEntityChunks: PHTTP_DATA_CHUNK;
    ResponseInfoCount: USHORT;
    pResponseInfo: PHTTP_RESPONSE_INFO;
  end;
  PHTTP_RESPONSE_V2 = ^HTTP_RESPONSE_V2;

  HTTP_RESPONSE = HTTP_RESPONSE_V2;
  PHTTP_RESPONSE = ^HTTP_RESPONSE;

  HTTPAPI_VERSION = record
    HttpApiMajorVersion: USHORT;
    HttpApiMinorVersion: USHORT;
  end;
  PHTTPAPI_VERSION = ^HTTPAPI_VERSION;

const
  HTTPAPI_VERSION_1: HTTPAPI_VERSION = (HttpApiMajorVersion: 1; HttpApiMinorVersion: 0);
  HTTPAPI_VERSION_2: HTTPAPI_VERSION = (HttpApiMajorVersion: 2; HttpApiMinorVersion: 0);

type
  HTTP_CACHE_POLICY_TYPE = (
    HttpCachePolicyNocache,
    HttpCachePolicyUserInvalidates,
    HttpCachePolicyTimeToLive,
    HttpCachePolicyMaximum
  );

  HTTP_CACHE_POLICY = record
    Policy: HTTP_CACHE_POLICY_TYPE;
    SecondsToLive: ULONG;
  end;
  PHTTP_CACHE_POLICY = ^HTTP_CACHE_POLICY;

  HTTP_SERVICE_CONFIG_ID = (
    HttpServiceConfigIPListenList,
    HttpServiceConfigSSLCertInfo,
    HttpServiceConfigUrlAclInfo,
    HttpServiceConfigTimeout,
    HttpServiceConfigCache,
    HttpServiceConfigMax
  );

  HTTP_SERVICE_CONFIG_QUERY_TYPE = (
    HttpServiceConfigQueryExact,
    HttpServiceConfigQueryNext,
    HttpServiceConfigQueryMax
  );

  HTTP_SERVICE_CONFIG_SSL_KEY = record
    pIpPort: PSOCKADDR;
  end;
  PHTTP_SERVICE_CONFIG_SSL_KEY = ^HTTP_SERVICE_CONFIG_SSL_KEY;

  HTTP_SERVICE_CONFIG_SSL_PARAM = record
    SslHashLength: ULONG;
    pSslHash: PVOID;
    AppId: TGUID;
    pSslCertStoreName: PWideChar;
    DefaultCertCheckMode: LongInt;
    DefaultRevocationFreshnessTime: LongInt;
    DefaultRevocationUrlRetrievalTimeout: LongInt;
    pDefaultSslCtlIdentifier: PWideChar;
    pDefaultSslCtlStoreName: PWideChar;
    DefaultFlags: LongInt;
  end;
  PHTTP_SERVICE_CONFIG_SSL_PARAM = ^HTTP_SERVICE_CONFIG_SSL_PARAM;

const
  HTTP_SERVICE_CONFIG_SSL_FLAG_USE_DS_MAPPER = $00000001;
  HTTP_SERVICE_CONFIG_SSL_FLAG_NEGOTIATE_CLIENT_CERT = $00000002;
  HTTP_SERVICE_CONFIG_SSL_FLAG_NO_RAW_FILTER = $00000004;

type
  HTTP_SERVICE_CONFIG_SSL_SET = record
    KeyDesc: HTTP_SERVICE_CONFIG_SSL_KEY;
    ParamDesc: HTTP_SERVICE_CONFIG_SSL_PARAM;
  end;
  PHTTP_SERVICE_CONFIG_SSL_SET = ^HTTP_SERVICE_CONFIG_SSL_SET;

  HTTP_SERVICE_CONFIG_SSL_QUERY = record
    QueryDesc: HTTP_SERVICE_CONFIG_QUERY_TYPE;
    KeyDesc: HTTP_SERVICE_CONFIG_SSL_KEY;
    dwToken: LongInt;
  end {_HTTP_SERVICE_CONFIG_SSL_QUERY};
  PHTTP_SERVICE_CONFIG_SSL_QUERY = ^HTTP_SERVICE_CONFIG_SSL_QUERY;

  HTTP_SERVICE_CONFIG_IP_LISTEN_PARAM = record
    AddrLength: USHORT;
    pAddress: PSOCKADDR;
  end;
  PHTTP_SERVICE_CONFIG_IP_LISTEN_PARAM = ^HTTP_SERVICE_CONFIG_IP_LISTEN_PARAM;

//  HTTP_SERVICE_CONFIG_IP_LISTEN_QUERY = record
//    AddrCount: ULONG;
//    AddrList: Array[0..0] of SOCKADDR_STORAGE;
//  end;
//  PHTTP_SERVICE_CONFIG_IP_LISTEN_QUERY = ^HTTP_SERVICE_CONFIG_IP_LISTEN_QUERY;

  HTTP_SERVICE_CONFIG_URLACL_KEY = record
    pUrlPrefix: PWideChar;
  end;
  PHTTP_SERVICE_CONFIG_URLACL_KEY = ^HTTP_SERVICE_CONFIG_URLACL_KEY;

  HTTP_SERVICE_CONFIG_URLACL_PARAM = record
    pStringSecurityDescriptor: PWideChar;
  end;
  PHTTP_SERVICE_CONFIG_URLACL_PARAM = ^HTTP_SERVICE_CONFIG_URLACL_PARAM;

  HTTP_SERVICE_CONFIG_URLACL_SET = record
    KeyDesc: HTTP_SERVICE_CONFIG_URLACL_KEY;
    ParamDesc: HTTP_SERVICE_CONFIG_URLACL_PARAM;
  end;
  PHTTP_SERVICE_CONFIG_URLACL_SET = ^HTTP_SERVICE_CONFIG_URLACL_SET;

  HTTP_SERVICE_CONFIG_URLACL_QUERY = record
    QueryDesc: HTTP_SERVICE_CONFIG_QUERY_TYPE;
    KeyDesc: HTTP_SERVICE_CONFIG_URLACL_KEY;
    dwToken: LongInt;
  end;
  PHTTP_SERVICE_CONFIG_URLACL_QUERY = ^HTTP_SERVICE_CONFIG_URLACL_QUERY;

  HTTP_SERVICE_CONFIG_CACHE_KEY = (
    MaxCacheResponseSize = 0,
    CacheRangeChunkSize
  );

  HTTP_SERVICE_CONFIG_CACHE_PARAM = ULONG;
  PHTTP_SERVICE_CONFIG_CACHE_PARAM = ^HTTP_SERVICE_CONFIG_CACHE_PARAM;

  HTTP_SERVICE_CONFIG_CACHE_SET = record
    KeyDesc: HTTP_SERVICE_CONFIG_CACHE_KEY;
    ParamDesc: HTTP_SERVICE_CONFIG_CACHE_PARAM;
  end {HTTP_SERVICE_CONFIG_CACHE_SET};
  PHTTP_SERVICE_CONFIG_CACHE_SET = ^HTTP_SERVICE_CONFIG_CACHE_SET;

// Specific Types (not present in original http.h)

const
  HttpVerbNames: array[HTTP_VERB] of string = (
    '',                 //HttpVerbUnparsed,
    '',                 //HttpVerbUnknown,
    '',                 //HttpVerbInvalid,
    'OPTIONS',          //HttpVerbOPTIONS,
    'GET',              //HttpVerbGET,
    'HEAD',             //HttpVerbHEAD,
    'POST',             //HttpVerbPOST,
    'PUT',              //HttpVerbPUT,
    'DELETE',           //HttpVerbDELETE,
    'TRACE',            //HttpVerbTRACE,
    'CONNECT',          //HttpVerbCONNECT,
    'TRACK',            //HttpVerbTRACK,
    'MOVE',             //HttpVerbMOVE,
    'COPY',             //HttpVerbCOPY,
    'PROPFIND',         //HttpVerbPROPFIND,
    'PROPPATCH',        //HttpVerbPROPPATCH,
    'MKCOL',            //HttpVerbMKCOL,
    'LOCK',             //HttpVerbLOCK,
    'UNLOCK',           //HttpVerbUNLOCK,
    'SEARCH',           //HttpVerbSEARCH,
    ''                  //HttpVerbMaximum
  );

  HttpRequestHeaderNames: array[HTTP_HEADER_ID] of string = (
    'cache-control',            //HttpHeaderCacheControl
    'connection',               //HttpHeaderConnection
    'date',                     //HttpHeaderDate
    'keep-alive',               //HttpHeaderKeepAlive
    'pragma',                   //HttpHeaderPragma
    'trailer',                  //HttpHeaderTrailer
    'transfer-encoding',        //HttpHeaderTransferEncoding
    'upgrade',                  //HttpHeaderUpgrade
    'via',                      //HttpHeaderVia
    'warning',                  //HttpHeaderWarning
    'allow',                    //HttpHeaderAllow
    'content-length',           //HttpHeaderContentLength
    'content-type',             //HttpHeaderContentType
    'content-encoding',         //HttpHeaderContentEncoding
    'content-language',         //HttpHeaderContentLanguage
    'content-location',         //HttpHeaderContentLocation
    'content-md5',              //HttpHeaderContentMd5
    'content-range',            //HttpHeaderContentRange
    'expires',                  //HttpHeaderExpires
    'last-modified',            //HttpHeaderLastModified
    'accept',                   //HttpHeaderAccept
    'accept-charset',           //HttpHeaderAcceptCharset
    'accept-encoding',          //HttpHeaderAcceptEncoding
    'accept-language',          //HttpHeaderAcceptLanguage
    'authorization',            //HttpHeaderAuthorization
    'cookie',                   //HttpHeaderCookie
    'expect',                   //HttpHeaderExpect
    'from',                     //HttpHeaderFrom
    'host',                     //HttpHeaderHost
    'if-match',                 //HttpHeaderIfMatch
    'if-modified-since',        //HttpHeaderIfModifiedSince
    'if-none-match',            //HttpHeaderIfNoneMatch
    'if-range',                 //HttpHeaderIfRange
    'if-unmodified-since',      //HttpHeaderIfUnmodifiedSince
    'max-forwards',             //HttpHeaderMaxForwards
    'proxy-authorization',      //HttpHeaderProxyAuthorization
    'referer',                  //HttpHeaderReferer
    'range',                    //HttpHeaderRange
    'te',                       //HttpHeaderTe
    'translate',                //HttpHeaderTranslate
    'user-agent',               //HttpHeaderUserAgent
    ''                          //HttpHeaderRequestMaximum
  );

  HttpResponseHeaderNames: array[HTTP_HEADER_ID] of string = (
    'cache-control',            //HttpHeaderCacheControl
    'connection',               //HttpHeaderConnection
    'date',                     //HttpHeaderDate
    'keep-alive',               //HttpHeaderKeepAlive
    'pragma',                   //HttpHeaderPragma
    'trailer',                  //HttpHeaderTrailer
    'transfer-encoding',        //HttpHeaderTransferEncoding
    'upgrade',                  //HttpHeaderUpgrade
    'via',                      //HttpHeaderVia
    'warning',                  //HttpHeaderWarning
    'allow',                    //HttpHeaderAllow
    'content-length',           //HttpHeaderContentLength
    'content-type',             //HttpHeaderContentType
    'content-encoding',         //HttpHeaderContentEncoding
    'content-language',         //HttpHeaderContentLanguage
    'content-location',         //HttpHeaderContentLocation
    'content-md5',              //HttpHeaderContentMd5
    'content-range',            //HttpHeaderContentRange
    'expires',                  //HttpHeaderExpires
    'last-modified',            //HttpHeaderLastModified
    'accept-ranges',            //HttpHeaderAcceptRanges
    'age',                      //HttpHeaderAge
    'etag',                     //HttpHeaderEtag
    'location',                 //HttpHeaderLocation
    'proxy-authenticate',       //HttpHeaderProxyAuthenticate
    'retry-after',              //HttpHeaderRetryAfter
    'server',                   //HttpHeaderServer
    'set-cookie',               //HttpHeaderSetCookie
    'vary',                     //HttpHeaderVary
    'www-authenticate',         //HttpHeaderWwwAuthenticate
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    ''                          //HttpHeaderMaximum
  );

var
  HttpInitialize: function(Version: HTTPAPI_VERSION; Flags: ULONG; pReserved: PVOID = nil): HRESULT; stdcall;
  HttpTerminate: function(Flags: ULONG; pReserved: PVOID = nil): HRESULT; stdcall;
  HttpCreateHttpHandle: function(var pReqQueueHandle: THandle; Reserved: ULONG = 0): HRESULT; stdcall;
  HttpCreateRequestQueue: function(Version: HTTPAPI_VERSION; pName: PWideChar; pSecurityAttributes: PSecurityAttributes;
    Flags: ULONG; var pReqQueueHandle: THandle): HRESULT; stdcall;
  HttpCloseRequestQueue: function(ReqQueueHandle: THandle): HRESULT; stdcall;
  HttpSetRequestQueueProperty: function(Handle: THandle; Property_: HTTP_SERVER_PROPERTY; pPropertyInformation: PVOID;
    PropertyInformationLength: ULONG; Reserved: ULONG = 0; pReserved: PVOID = nil): HRESULT; stdcall;
  HttpQueryRequestQueueProperty: function(Handle: THandle; Property_: HTTP_SERVER_PROPERTY; pPropertyInformation: PVOID;
    PropertyInformationLength: ULONG; Reserved: ULONG; var pReturnLength: ULONG; pReserved: PVOID = nil): HRESULT; stdcall;
  HttpShutdownRequestQueue: function(ReqQueueHandle: THandle): HRESULT; stdcall;
  HttpReceiveClientCertificate: function(ReqQueueHandle: THandle; ConnectionId: HTTP_CONNECTION_ID; Flags: ULONG;
    var pSslClientCertInfo: HTTP_SSL_CLIENT_CERT_INFO; SslClientCertInfoSize: ULONG; var pBytesReceived: ULONG; pOverlapped: POverlapped): HRESULT; stdcall;
  HttpCreateServerSession: function(Version: HTTPAPI_VERSION; var pServerSessionId: HTTP_SERVER_SESSION_ID; Reserved: ULONG = 0): HRESULT; stdcall;
  HttpCloseServerSession: function(ServerSessionId: HTTP_SERVER_SESSION_ID): HRESULT; stdcall;

//  HttpQueryServerSessionProperty: function(ServerSessionId: HTTP_SERVER_SESSION_ID; Property_: HTTP_SERVER_PROPERTY;
//    pPropertyInformation: PVOID; PropertyInformationLength: ULONG; pReturnLength: PULONG): HRESULT; stdcall;

  HttpSetServerSessionProperty: function(ServerSessionId: HTTP_SERVER_SESSION_ID; AProperty: HTTP_SERVER_PROPERTY;
    pPropertyInformation: PVOID; PropertyInformationLength: ULONG): HRESULT; stdcall;

  HttpAddUrl: function(ReqQueueHandle: THandle; pFullyQualifiedUrl: PWideChar; pReserved: PVOID = nil): HRESULT; stdcall;
  HttpRemoveUrl: function(ReqQueueHandle: THandle; pFullyQualifiedUrl: PWideChar): HRESULT; stdcall;
  HttpCreateUrlGroup: function(ServerSessionId: HTTP_SERVER_SESSION_ID; var pUrlGroupId: HTTP_URL_GROUP_ID; Reserved: ULONG = 0): HRESULT; stdcall;
  HttpCloseUrlGroup: function(UrlGroupId: HTTP_URL_GROUP_ID): HRESULT; stdcall;
  HttpAddUrlToUrlGroup: function(UrlGroupId: HTTP_URL_GROUP_ID; pFullyQualifiedUrl: PWideChar; UrlContext: HTTP_URL_CONTEXT; Reserved: ULONG = 0): HRESULT; stdcall;
  HttpRemoveUrlFromUrlGroup: function(UrlGroupId: HTTP_URL_GROUP_ID; pFullyQualifiedUrl: PWideChar; Flags: ULONG): HRESULT; stdcall;
  HttpSetUrlGroupProperty: function(UrlGroupId: HTTP_URL_GROUP_ID; Property_: HTTP_SERVER_PROPERTY;
    pPropertyInformation: PVOID; PropertyInformationLength: ULONG): HRESULT; stdcall;

//  HttpQueryUrlGroupProperty: function(UrlGroupId: HTTP_URL_GROUP_ID; var AProperty: HTTP_SERVER_PROPERTY;
//    pPropertyInformation: PVOID; PropertyInformationLength: ULONG; pReturnLength: PULONG = nil): HRESULT; stdcall;

  HttpReceiveHttpRequest: function(ReqQueueHandle: THandle; RequestId: HTTP_REQUEST_ID; Flags: ULONG;
    RequestBuffer: PHTTP_REQUEST; RequestBufferLength: ULONG; var pBytesReceived: ULONG; pOverlapped: POverlapped): HRESULT; stdcall;
  HttpReceiveRequestEntityBody: function(ReqQueueHandle: THandle; RequestId: HTTP_REQUEST_ID; Flags: ULONG;
    pBuffer: PVOID; BufferLength: ULONG; var pBytesReceived: ULONG; pOverlapped: POverlapped): HRESULT; stdcall;
  HttpSendHttpResponse: function(ReqQueueHandle: THandle; RequestId: HTTP_REQUEST_ID; Flags: ULONG;
    pHttpResponse: PHTTP_RESPONSE; pCachePolicy: PHTTP_CACHE_POLICY; var pBytesSend: ULONG; pReserved1: PVOID = nil;
    Reserved2: ULONG = 0; pOverlapped: POverlapped = nil; pLogData: PHTTP_LOG_DATA = nil): HRESULT; stdcall;
  HttpSendResponseEntityBody: function(ReqQueueHandle: THandle; RequestId: HTTP_REQUEST_ID; Flags: ULONG;
    EntityChunkCount: USHORT; pEntityChunks: PHTTP_DATA_CHUNK; var pBytesSent: ULONG; pReserved1: PVOID = nil;
    Reserved2: ULONG = 0; pOverlapped: POverlapped = nil; pLogData: PHTTP_LOG_DATA = nil): HRESULT; stdcall;
  HttpWaitForDisconnect: function(ReqQueueHandle: THandle; ConnectionId: HTTP_CONNECTION_ID; pOverlapped: POverlapped): HRESULT; stdcall;
  HttpCancelHttpRequest: function(ReqQueueHandle: THandle; RequestId: HTTP_REQUEST_ID; pOverlapped: POverlapped): HRESULT; stdcall;
  HttpWaitForDemandStart: function(ReqQueueHandle: THandle; pOverlapped: POverlapped): HRESULT; stdcall;
  HttpFlushResponseCache: function(ReqQueueHandle: THandle; pUrlPrefix: PWideChar; Flags: ULONG; pOverlapped: POverlapped): HRESULT; stdcall;
  HttpAddFragmentToCache: function(ReqQueueHandle: THandle; pUrlPrefix: PWideChar; pDataChunk: PHTTP_DATA_CHUNK;
    pCachePolicy: PHTTP_CACHE_POLICY; pOverlapped: POverlapped): HRESULT; stdcall;
  HttpReadFragmentFromCache: function(ReqQueueHandle: THandle; pUrlPrefix: PWideChar; pByteRange: PHTTP_BYTE_RANGE;
    pBuffer: PVOID; BufferLength: ULONG; var pBytesRead: ULONG; pOverlapped: POverlapped): HRESULT; stdcall;
  HttpSetServiceConfiguration: function(ServiceHandle: THandle; ConfigId: HTTP_SERVICE_CONFIG_ID;
    pConfigInformation: PVOID; ConfigInformationLength: ULONG; pOverlapped: POverlapped): HRESULT; stdcall;
  HttpDeleteServiceConfiguration: function(ServiceHandle: THandle; ConfigId: HTTP_SERVICE_CONFIG_ID;
    pConfigInformation: PVOID; ConfigInformationLength: ULONG; pOverlapped: POverlapped): HRESULT; stdcall;
  HttpQueryServiceConfiguration: function(ServiceHandle: THandle; ConfigId: HTTP_SERVICE_CONFIG_ID;
    pInputConfigInformation: PVOID; InputConfigInformationLength: ULONG;
    pOutputConfigInformation: PVOID; OutputConfigInformationLength: ULONG; var pReturnLength: Cardinal;
    pOverlapped: POverlapped): HRESULT; stdcall;

type
  EHttpApiException = class(Exception);

function LoadHttpApiLibrary: boolean;
procedure HttpCheck(HttpResult: HRESULT);

{$ENDIF}

implementation

{$IFDEF MSWINDOWS}

const
  HttpApiDllName = 'httpapi.dll';

var
  LibraryHandle: THandle;

procedure HttpCheck(HttpResult: HRESULT);
begin
  if HttpResult <> NO_ERROR then
    raise EHttpApiException.Create('HTTP Server API Error.' + sLineBreak + SysErrorMessage(HttpResult));
end;

function LoadHttpApiLibrary: boolean;

  function LoadProc(ProcName: string): Pointer;
  begin
    Result := GetProcAddress(LibraryHandle, PChar(ProcName));
    Assert(Assigned(Result), HttpApiDllName + ' - Could not find method: ' + ProcName);
  end;

begin
  if LibraryHandle <> 0 then
    Exit(True);

  Result := False;
  LibraryHandle := SafeLoadLibrary(PChar(HttpApiDllName));
  if (LibraryHandle <> 0) then
  begin
    Result := True;

    HttpInitialize := LoadProc('HttpInitialize');
    HttpTerminate := LoadProc('HttpTerminate');
    HttpCreateHttpHandle := LoadProc('HttpCreateHttpHandle');
    HttpCreateRequestQueue := LoadProc('HttpCreateRequestQueue');
    HttpCloseRequestQueue := LoadProc('HttpCloseRequestQueue');
    HttpSetRequestQueueProperty := LoadProc('HttpSetRequestQueueProperty');
    HttpQueryRequestQueueProperty := LoadProc('HttpQueryRequestQueueProperty');
    HttpShutdownRequestQueue := LoadProc('HttpShutdownRequestQueue');
    HttpReceiveClientCertificate := LoadProc('HttpReceiveClientCertificate');
    HttpCreateServerSession := LoadProc('HttpCreateServerSession');
    HttpCloseServerSession := LoadProc('HttpCloseServerSession');
    HttpSetServerSessionProperty := LoadProc('HttpSetServerSessionProperty');
    HttpAddUrl := LoadProc('HttpAddUrl');
    HttpRemoveUrl := LoadProc('HttpRemoveUrl');
    HttpCreateUrlGroup := LoadProc('HttpCreateUrlGroup');
    HttpCloseUrlGroup := LoadProc('HttpCloseUrlGroup');
    HttpAddUrlToUrlGroup := LoadProc('HttpAddUrlToUrlGroup');
    HttpRemoveUrlFromUrlGroup := LoadProc('HttpRemoveUrlFromUrlGroup');
    HttpSetUrlGroupProperty := LoadProc('HttpSetUrlGroupProperty');
    HttpReceiveHttpRequest := LoadProc('HttpReceiveHttpRequest');
    HttpReceiveRequestEntityBody := LoadProc('HttpReceiveRequestEntityBody');
    HttpSendHttpResponse := LoadProc('HttpSendHttpResponse');
    HttpSendResponseEntityBody := LoadProc('HttpSendResponseEntityBody');
    HttpWaitForDisconnect := LoadProc('HttpWaitForDisconnect');
    HttpCancelHttpRequest := LoadProc('HttpCancelHttpRequest');
    HttpWaitForDemandStart := LoadProc('HttpWaitForDemandStart');
    HttpFlushResponseCache := LoadProc('HttpFlushResponseCache');
    HttpAddFragmentToCache := LoadProc('HttpAddFragmentToCache');
    HttpReadFragmentFromCache := LoadProc('HttpReadFragmentFromCache');
    HttpSetServiceConfiguration := LoadProc('HttpSetServiceConfiguration');
    HttpDeleteServiceConfiguration := LoadProc('HttpDeleteServiceConfiguration');
    HttpQueryServiceConfiguration := LoadProc('HttpQueryServiceConfiguration');
  end;
end;

Initialization
  LibraryHandle := 0;

finalization
  if LibraryHandle <> 0 then
    FreeLibrary(LibraryHandle);

{$IFDEF WIN32}
  {$if sizeof(HTTP_REQUEST_V2) <> 472} {$message error 'HTTP_REQUEST sizeof error.'} {$ifend}
  {$if sizeof(HTTP_RESPONSE_V2) <> 288} {$message error 'HTTP_RESPONSE sizeof error.'} {$ifend}
  {$if sizeof(HTTP_COOKED_URL) <>  24} {$message error 'HTTP_COOKED_URL sizeof error.'} {$ifend}
  {$if sizeof(HTTP_DATA_CHUNK) <>  32} {$message error 'HTTP_DATA_CHUNK sizeof error.'} {$ifend}
  {$if sizeof(HTTP_REQUEST_HEADERS) <> 344} {$message error 'HTTP_REQUEST_HEADERS sizeof error.'} {$ifend}
  {$if sizeof(HTTP_RESPONSE_HEADERS) <> 256} {$message error 'HTTP_RESPONSE_HEADERS sizeof error.'} {$ifend}
  {$if sizeof(HTTP_SSL_INFO) <>  28} {$message error 'HTTP_SSL_INFO sizeof error.'} {$ifend}
{$ENDIF}

{$ENDIF}

end.
