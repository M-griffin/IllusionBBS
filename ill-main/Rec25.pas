(****************************************************************************)
(*>                                                                        <*)
(*>     Illusion Bulletin Board System                                     <*)
(*>     Copyright 1992-1998 by Kyle Oppenheim and Billy Ma                 <*)
(*>     All rights reserved                                                <*)
(*>                                                                        <*)
(*>     Record structures for data files                                   <*)
(*>                                                                        <*)
(****************************************************************************)

CONST

  Ver     : String[15] = '3.00';        { version string }
  VerType : Byte       = 1;             { version type -- 0:Unregistered }
                                        {                 1:Standard     }
                                        {                 2:Special      }
                                        {                 3:Beta         }
                                        {                 4:Alpha        }

  maxuBoards     = 140; { 0 - x }       { maximum file boards }
  maxProtocols   = 120; { 0 - x }       { maximum protocols }
  maxEvents      = 10;  { 0 - x }       { maximum events }
  maxArcs        = 8;   { 1 - x }       { maximum archive configs allowed }
  maxuBatchFiles = 20; { 1 - x }       { maximum batch files in UL queue }
  maxBatchFiles  = 20; { 1 - x }       { maximum batch files in DL queue }
  maxVoteQs      = 20;  { 1 - x }       { maximum voting questions }
  maxVoteAs      = 50;  { 1 - x }       { maximum answers per voting question }
  maxMenuCmds    = 50;  { 1 - x }       { maximum number of commands per menu }

  extIPLexe      = '.IPX';
  extIPLcode     = '.IPS';

TYPE

  aStr               = String[160];     { commonly used string type }
  ACString           = String[20];      { access condition string }
  AcRq               = '@'..'Z';        { AR flags }

  cPackDateTime      = Array[1..6] of Byte; { packed date/time }
  DateTimeRec=                          { internal date/time storage }
  record
    Day              : LongInt;
    Hour             : LongInt;
    Min              : LongInt;
    Sec              : LongInt;
  end;
  UnixTime           = LongInt;         { unix time storage - seconds since 01/01/70 }

  FzScanR            = set of 0..MaxuBoards;

(*****************************************************************************)
{ User Listings }

  SmalRec=              { 1 - x }       { USERS.IDX : sorted names listing }
  record
    Name             : String[36];      { user name }
    Number           : Integer;         { user number }
  end;

  uFlags =                              { user AC Flags - stored in UserRec }
   (rLogon,                             { L - restricted to one call a day }
    rChat,                              { C - can't page the sysop }
    rValidate,                          { V - posts marked unvalidated }
    rFastLogon,                         { F - force fast logon }
    rAMsg,                              { A - can't change the automessage }
    rPostAn,                            { * - can't post anonymously }
    rPost,                              { P - can't post at all }
    rEmail,                             { E - can't send any e-mail }
    rVoting,                            { K - can't vote }
    rMsg,                               { M - force e-mail deletion }

    Rip,                                { user has rip }
    OneKey,                             { hotkey input mode }
    Avatar,                             { user has avatar }
    Pause,                              { pause is active }
    Novice,                             { expert mode is off (novice on) }
    Ansi,                               { user has ansi }

    res1,                               { reserved }

    Alert,                              { alert sysop when user logs on }
    Smw,                                { telegram waiting for user }
    NoMail,                             { user mailbox is closed }

    fNoDLRatio,                         { 1 - no UL/DL ratio }
    fNoPostRatio,                       { 2 - no post/call ratio }
    fNoFilePts,                         { 3 - no file points checking }
    fNoDeletion);                       { 4 - protection from deletion }

  UserRec=              { 1 - x }       { USERS.DAT : user account records }
  record
    Name             : String[36];      { user name/alias }
    RealName         : String[36];      { real name }
    PW               : String[20];      { user password }
    Ph               : String[12];      { user phone number }
    Bday             : String[8];       { user birthdate }
    FirstOn          : String[8];       { date first applied }
    LastOn           : String[8];       { date last logged on }
    Street           : String[30];      { mailing address }
    CityState        : String[30];      { city, state, country }
    ZipCode          : String[10];      { zip/postal code }
    Computer         : String[30];      { type of computer }
    Occupation       : String[40];      { occupation }
    WhereBBS         : String[40];      { BBS reference }
    Note             : String[39];      { sysop note }
    UserNote         : String[25];      { user note }

    res1:Array[1..164] of Byte;         { reserved }

    LockedOut        : Boolean;         { locked out? }
    Deleted          : Boolean;         { deleted? }
    LockedFile       : String[8];       { lockout file to display (in TEXT) }

    AC               : set of uFlags;   { user flags (see above) }
    AR               : set of AcRq;     { AR flags }

    Vote             : Array[1..20] of Byte; { voting data }
    Sex              : Char;            { user gender }

    tTimeOn          : LongInt;         { total minutes spent online }
    Uk               : LongInt;         { total kbytes uploaded }
    Dk               : LongInt;         { total kbytes downloaded }
    Uploads          : Word;            { number of files uploaded }
    Downloads        : Word;            { number files downloaded }
    LoggedOn         : Word;            { number of times logged on }
    tlToday          : Word;            { minutes left today }
    MsgPost          : Word;            { number of public posts }
    EmailSent        : Word;            { number of email sent }

    res2:Array[1..2] of Byte;           { reserved }

    ForUsr           : Word;            { forward mail to user # }
    FilePoints       : LongInt;         { number of file points }

    res3:Array[1..19] of Byte;          { reserved }

    LineLen          : Byte;            { line length (# cols) }
    PageLen          : Byte;            { page length (# rows) }
    OnToday          : Byte;            { number of times on today }
    Illegal          : Byte;            { number of illegal logon attempts }
    SL               : Byte;            { security level (SL) }
    DSL              : Byte;            { download security level (DSL) }
    LastMsg          : Byte;            { msg area when last logged off }
    LastFil          : Byte;            { file area when last logged off }

    res4:Array[1..10] of Byte;          { reserved }

    Credit           : Integer;         { credits }
    TimeBankAdd      : Integer;         { time added to time bank today }
    TimeBank         : Integer;         { number of minutes in time bank }

    res5:Array[1..10] of Byte;          { reserved }

    SLogSeperate     : Boolean;         { seperate sysop log for each user? }
    ChatAuto         : Boolean;         { automatically trap chat sessions? }
    ChatSeperate     : Boolean;         { trap chat to separate files for each user? }
    TrapActivity     : Boolean;         { trap all users' activity? }
    TrapSeperate     : Boolean;         { trap to separate files for each user? }

    res6:Array[1..5] of Byte;           { reserved }

    mPointer         : LongInt;         { pointer to entry in MACROS.DAT }
    UserStartMenu    : String[8];       { menu to start all users out on }

    res7:Array[1..2] of Byte;           { reserved }

    Conference       : Char;            { current conference }

    fListC           : Array[1..10,1..2] of Byte; { file listing configuation }
                                        { 1..10: file listing elements        }
                                        { 1..2:  1: 0:off 1:on                }
                                        {        2: color                     }

    QwkArc           : String[3];       { QWK archive type }
    QwkFiles         : Boolean;         { list new files in packet? (not used) }

    EdType           : Byte;            { editor type          }
                                        { 0:select at time     }
                                        { 1:line editor        }
                                        { 2:full screen editor }

    res8:Array[1..99] of Byte;          { reserved }
  end;

(*****************************************************************************)
{ Logs }

  zLogRec=                              { HISTORY.DAT : system log }
  record
    Date             : String[8];       { entry date }

    res1:Array[0..9] of Byte;           { reserved }

    Active           : Integer;         { number of minutes active }
    Calls            : Integer;         { number of calls }
    NewUsers         : Integer;         { number of new users }
    PubPost          : Integer;         { number of public posts }
    PrivPost         : Integer;         { number of private posts }

    res2:Array[1..2] of Byte;           { reserved }

    CritErr          : Integer;         { number of runtime errors occured }
    Uploads          : Integer;         { number of files uploaded }
    Downloads        : Integer;         { number of files downloaded }
    Uk               : LongInt;         { number of kbytes uploaded }
    Dk               : LongInt;         { number of kbytes downloaded }
  end;

(****************************************************************************)
{ Multinode files }

  HaTypes=                              { handshake types - stored in ModemRec }
    (HaCtsRts,                          { cts/rts }
     HaXonXoff,                         { xon/xoff }
     HaRes1,                            { reserved }
     HaRes2);                           { reserved }

  ModemRec=                             { NODE.### : modem/node info }
  record
    DoorPath         : String[79];      { door drop file path (for this node) }
    TempPath         : String[79];      { temp path (for this node) }

    res1:Array[1..160] of Byte;         { reserved }

    LastDate         : String[8];       { last system date (for this node) }

    LowSpeed         : Word;            { speed for low speed lockout }
    LowPw            : String[20];      { low speed override password }

    res2:Array[1..40] of Byte;          { reserved }

    ComPort          : Byte;            { COM port }
    WaitBaud         : Word;            { maximum speed }
    PortLock         : Boolean;         { port locked? }

    res3:Array[1..2] of Byte;           { reserved }

    Handshake        : HaTypes;         { handshaking type }
    LockSpeed        : LongInt;         { speed port is locked at }

    res4:Array[1..16] of Byte;          { reserved }

    EscCode          : String[20];      { "+++" }
    Init             : Array[1..2] of String[80]; { initialization strings }
    NoCallInitTime   : Integer;         { reinit modem after x mins of inactivity }
    Answer           : String[40];      { answer string }
    AnswerDelay      : Byte;            { delay in 1/10 seconds before answering }
    Hangup           : String[40];      { hangup string }
    Offhook          : String[40];      { phone off-hook string }

    res5:Array[1..160] of Byte;         { reserved }

    CodeError        : String[25];      { result code for ERROR }
    CodeNoCarrier    : String[25];      { result code for NO CARRIER }
    CodeOk           : String[25];      { result code for OK }
    CodeRing         : String[25];      { result code for RING }

    res6:Array[1..78] of Byte;          { reserved }

    ResultCode       : Array[0..19] of String[25]; { connection result codes    }
                                        {  0:300    1:1200    2:2400    3:4800  }
                                        {  4:7200   5:9600    6:12000   7:14400 }
                                        {  8:16800  9:19200  10:21600  11:24000 }
                                        { 12:26400 13:28800  14:31200  15:33600 }
                                        { 16:38400 17:57600  18:64000  19:115200}
                                        {                    ^^ not used        }

    res7:Array[1..104] of Byte;         { reserved }
  end;

  NodeRec=                              { NODES.DAT : node listings }
  record
    UserName         : String[36];      { name of user on node }
    uNum             : Integer;         { user number of user on node }
    WhereUser        : String[20];      { where on the system is the user? }
    Available        : Boolean;         { available for chat? }

    res1:Array[1..21] of Byte;          { reserved }

    Active           : Boolean;         { is this node active/running? }
  end;

(*****************************************************************************)
{ Main config }

  SecRange           = Array[0..255] of Integer; { security tables }

  FileArcInfoRec=                       { archives - stored in SystatRec }
  record
    Active           : Boolean;         { active? }
    Ext              : String[3];       { 3 character file extension }
    ListLine         : String[25];      { /x for internal  }
    ArcLine          : String[25];      { compression commandline }
    UnarcLine        : String[25];      { decompression commandline }
    TestLine         : String[25];      { integrity test commandline (null if none) }
    CmtLine          : String[25];      { add comment commandline (null if none) }
    SuccLevel        : Integer;         { success errorlevel (-1=ignore results) }
  end;

  AkaRec=                               { separate AKAs - stored in SystatRec }
  record
    Zone             : Word;            { Zone:Net/Node.Point }
    Net              : Word;
    Node             : Word;
    Point            : Word;
  end;

  SystatRec=                            { ILLUSION.CFG : main configuration }
  record
    DataPath         : String[79];      { DATA path }
    TextPath         : String[79];      { default TEXT path (text files path) }
    MenuPath         : String[79];      { MENU path }
    HudsonPath       : String[79];      { Hudson messages path }
    JamPath          : String[79];      { JAM messages path }
    TrapPath         : String[79];      { TRAP path }
    MultPath         : String[79];      { MULT path }
    SquishPath       : String[79];      { Squish messages path }

    BBSName          : String[40];      { BBS name }
    BBSLocation      : String[39];      { BBS location }
    BBSPhone         : String[12];      { BBS phone number }
    SysopName        : String[30];      { sysop's full name or alias }
    MaxUsers         : Integer;         { max number of users system can have }
    NumUsers         : Integer;         { number of users }
    LowTime          : Integer;         { sysop chat begin.. (in minutes) }
    HiTime           : Integer;         { ..and end }

    res1:Array[1..4] of Byte;           { reserved }

    ShuttleLog       : Boolean;         { matrix logon active? }

    SysopPw          : String[20];      { sysop password }
    NewUserPw        : String[20];      { new user password (null if none) }
    ShuttlePw        : String[20];      { matrix password (if matrix active) }

    ClosedSystem     : Boolean;         { don't allow new users? }
    SwapShell        : Boolean;         { swap shell function enabled? }
    SwapShellType    : Byte;            {   0:disk  1:EMS  2:XMS  3:all }

    EventWarningTime : Integer;         { time before event warning }
    LastMsgId        : LongInt;         { last-used message id (sequential) }
    CallerNum        : LongInt;         { total number of callers }

    EzycomPath       : String[79];      { Ezycom messages path }
    IPLxPath         : String[79];      { IPL executables path }

    MatrixMenu_Ansi  : String[8];       { matrix menu filename if ansi/avt on }
    MatrixMenu_TTY   : String[8];       { matrix menu filename w/o ansi }

    res2:Array[1..22] of Byte;          { reserved }

    Sop              : ACString;        { sysop acs }
    CSop             : ACString;        { cosysop acs }
    MSop             : ACString;        { message sysop acs }
    FSop             : ACString;        { file sysop acs }
    SPw              : ACString;        { sysop pw at logon }
    SeePw            : ACString;        { see passwords remotely }
    NormPubPost      : ACString;        { make normal public posts }
    NormPrivPost     : ACString;        { send normal email }
    AnonPubRead      : ACString;        { see who posted public anonymously }
    AnonPrivRead     : ACString;        { see who sent anonymous email }
    AnonPubPost      : ACString;        { make anonymous posts }
    AnonPrivPost     : ACString;        { send anonymous email }
    SeeUnval         : ACString;        { see unvalidated files }
    DLUnval          : ACString;        { download unvalidated files }
    NoDLRatio        : ACString;        { no UL/DL ratio }
    NoPostRatio      : ACString;        { no post/call ratio }
    NoFilePts        : ACString;        { no file points checking }
    ULValReq         : ACString;        { uploads require validation by sysop }
    FastLogonAcs     : ACString;        { can fast logon }
    EmergChat        : ACString;        { override sysop status for chat }

    res3:Array[1..96] of Byte;          { reserved }

    QwkFilename      : String[8];       { filename for QWK/REP packets }
    QwkDir           : String[79];      { local QWK directory }
    QwkWelcome       : String[8];       { filename of QWK welcome message }
    QwkNews          : String[8];       { filename of QWK news message }
    QwkGoodbye       : String[8];       { filename of QWK goodbye message }
    QwkComp          : String[3];       { default archive extension }

    res4:Array[1..744] of Byte;         { reserved }

    MaxPrivPost      : Byte;            { maximum email can send per call }
    MaxOneliners     : Byte;            { maximum oneliners allowed }
    MaxPubPost       : Byte;            { maximum posts per call }
    MaxChat          : Byte;            { maximum chat-pages per call }
    MaxWaiting       : Byte;            { maximum mail in mailbox }
    CsMaxWaiting     : Byte;            { maximum mail in mailbox for cosysop+ }
    DescImport       : Byte;            { import description in file       }
                                        { 0:never  1:optional  2:mandatory }

    res5:Byte;                          { reserved }

    MaxLogonTries    : Byte;            { tries allowed to logon }
    BsDelay          : Byte;            { backspacing delay }
    SysopColor       : Byte;            { sysop color in chat mode }
    UserColor        : Byte;            { user color in chat mode }

    MinSpaceForPost  : Integer;         { minimum k drive space left to post }
    MinSpaceForUpload : Integer;        { minimum k drive space left to upload }

    res6:Byte;                          { reserved }

    WfcBlankTime     : Byte;            { minutes after which to blank wfcmenu }
    LineLen          : Byte;            { default video line length }
    PageLen          : Byte;            { default video page length }
    NuvYes           : Byte;            { yes votes needed to be validated }
    NuvNo            : Byte;            { no votes needed to be deleted }
    NuvVal           : Char;            { validation profile to use }

    res7:Array[1..23] of Byte;          { reserved }

    InputFieldColor  : Byte;            { color used for input fields }

    SpecialFx        : Word;            { system special effects - bitmapped }
                                        { $01:animated pause cursor }
                                        { $02:enhanced chat page }
                                        { $04:wfc scroller }
                                        { $08:fireworks screen saver }

    res8:Array[1..114] of Byte;         { reserved }

    Wind_NormalC     : Byte;            { sysop window normal text color }
    Wind_HighlightC  : Byte;            { sysop window highlighted text color }
    Wind_LabelC      : Byte;            { sysop window label color }
    Wind_FlashC      : Byte;            { sysop window important text color }

    ReqAnsi          : Boolean;         { require ansi to logon? }
    CompressMsgBases : Boolean;         { compress message base numbers? }
    SysBatExec       : Boolean;         { execute system batch files? }
    AllowAlias       : Boolean;         { allow aliases? (handles) }
    PhonePw          : Boolean;         { use phone number password in logon? }
    LocalSec         : Boolean;         { is local security on? }
    LocalScreenSec   : Boolean;         { is local screen-security on? }
    GlobalTrap       : Boolean;         { trap all users' activity? }
    AutoChatOpen     : Boolean;         { does chat buffer auto-open? }
    SplitChat        : Boolean;         { use split-screen chat? }
    OffHookLocalLogon : Boolean;        { take phone offhook for local logons? }
    ForceVoting      : Boolean;         { is mandatory logon voting active? }
    CompressFileBases : Boolean;        { compress file base numbers? }
    SearchDup        : Boolean;         { search for duplicate filenames for UL? }
    StripCLog        : Boolean;         { strip colors from sysop log output? }
    Nuv              : Boolean;         { new user voting active? }
    PutOvr           : Byte;            { where to load overlay }
                                        { 0:disk  1:EMS  2:XMS  }
    UseBios          : Boolean;         { use ROM BIOS for local video output? }
    CgaSnow          : Boolean;         { suppress snow on CGA systems? }
    AllowAvatar      : Boolean;         { allow the use of AVATAR emulation? }
    AllowRip         : Boolean;         { allow the use of RIP emulation? }

    res9:Array[1..18] of Byte;          { reserved }

    NewApp           : Integer;         { user to send new user application to }
    TimeOutBell      : Integer;         { minutes before timeout bell }
    TimeOut          : Integer;         { minutes before timeout (logoff) }

    FileArcInfo      : Array[1..MaxArcs] of FileArcInfoRec; { archives }
    FileArcComment   : Array[1..3] of String[80]; { BBS comments }

    ULDLRatio        : Boolean;         { use UL/DL ratios? }
    FilePtRatio      : Boolean;         { use file points? }

    res10:Array[1..3] of Byte;          { reserved }

    FilePtComp       : Word;            { file point compensation ratio x/1 }
    FilePtCompBaseSize : Word;          { file point "base compensation size" }
    PostCredits      : Word;            { file point compensation for posts }
    ULRefund         : Byte;            { percent time refund for ULs }
    ToSysopDir       : Byte;            { "to sysop" file base }
    ValidateAllFiles : Boolean;         { validate all files automatically? }

    RemDevice        : String[10];      { remote output device (GATEx,COMx,etc) }

    res11:Array[1..2] of Byte;          { reserved }

    MinResume        : Integer;         { min k to allow resume-later }
    MaxDBatch        : Byte;            { max files in DL batch queue }
    MaxUBatch        : Byte;            { max files in UL batch queue }
    UnlistFp         : Byte;            { file pts required for unlisted DL }

    ArcPath          : String[79];      { path to archive utils }
    ProtPath         : String[79];      { path to protocol drivers }

    SwapXfer         : Boolean;         { swap overlay for file transfer? }

    res12:Array[1..82] of Byte;         { reserved }

    AllStartMenu     : String[8];       { logon menu to start ALL users on }

    TimeAllow        : SecRange;        { time allowance }
    CallAllow        : SecRange;        { call allowance }
    DLRatio          : SecRange;        { # ULs/# DLs ratios }
    DLKRatio         : SecRange;        { DLk/ULk ratios }
    PostRatio        : SecRange;        { post/call ratios }

    Origin           : String[50];      { default origin line }
    Text_Color       : Char;            { color of standard text }
    Quote_Color      : Char;            { color of quoted text }
    Tear_Color       : Char;            { color of tear line }
    Origin_Color     : Char;            { color of origin line }
    Strip            : Boolean;         { strip centering codes? }
    AddTear          : Boolean;         { add tear/origin lines? }
    Aka              : Array[1..20] of AkaRec; { network AKAs }

    res13:Array[1..295] of Byte;        { reserved }

    LastDate         : String[8];       { last system date }

    res14:Byte;

    WindowDefOn      : Boolean;         { is the sysop window defaultly on? }
    WindowOnTop      : Boolean;         { is sysop window on top of screen? }

    TodayZLog        : ZLogRec;         { today's history log record }

    res15:Array[1..001] of Byte;        { reserved }
  end;

(*****************************************************************************)
{ Voting booth }

  VDataR=                               { VOTING.DAT : voting booth }
  record
    Question         : String[75];      { voting question }
    VoteAcs          : ACString;        { acs required to vote }
    NumVoted         : Word;            { number of users who have answered }
    AddedBy          : String[35];      { who added this question }
    NumChoices       : Byte;            { number of choices }
    AddAcs           : ACString;        { acs required to add a choice }

    Choices          : Array[0..maxVoteas] of { choices available }
    record
      Ans            : Array[1..2] of String[65]; { answer description }
      NumVoted       : Integer;         { number of votes for this answer }
    end;
  end;

(*****************************************************************************)
{ Caller log }

  LCallers=                             { USERLOG.DAT : today's callers }
  record
    CallerNum        : Integer;         { system caller number }
    Name             : String[36];      { user name of caller }
    Number           : Integer;         { user number of caller }
    CityState        : String[30];      { city/state of caller }
    Node             : String[3];       { node of caller }
    Baud             : String[5];       { baud of caller }
    NewUser          : Boolean;         { new user? }
    Time             : String[8];       { time of call }

    res1:Array[1..41] of Byte;          { reserved }
  end;

(*****************************************************************************)
{ Events }

  EventRec=                             { EVENTS.DAT : events }
  record
    Active           : Boolean;         { active? }
    Description      : String[30];      { event description (for logs) }
    EType            : Char;            { A:CS, C:hat, D:OS call, E:xternal }
    ExecData         : String[20];      { errorlevel if E, commandline if D }
    BusyTime         : Integer;         { mins offhook before event (0=none) }
    ExecTime         : Integer;         { time of execution (mins after midnight) }
    BusyDuring       : Boolean;         { phone offhook during event? }
    Duration         : Integer;         { length of time event }
    ExecDays         : Byte;            { bitwise execution day(s) }
    Monthly          : Boolean;         { monthly event? }
  end;

(*****************************************************************************)
{ New user voting }

  NuvRec=                               { NUV.DAT : new user voting }
  record
    NewUserNum       : Integer;         { user # of new user being voted on }
    Votes            : Array[1..20] of  { votes }
    record
      Name           : String[36];      { user name who voted }
      Number         : Integer;         { user number of above }
      Vote           : Byte;            { user's vote            }
                                        { 1:yes  2:no  3:abstain }
      Comment        : String[65];      { comment on user }
    end;
  end;

(*****************************************************************************)
{ BBS list }

  BBSListRec=                           { BBSLIST.DAT : BBS list }
  record
    Ph               : String[20];      { phone number }
    Name             : String[30];      { BBS name }
    BPS              : String[6];       { maximum BPS rate }
    Software         : String[10];      { BBS software }
    Info             : String[50];      { extended info }
    BBSDate          : String[8];       { date added/modified last }

    res1:Array[1..50] of Byte;          { reserved }
  end;

(*****************************************************************************)
{ Miscellaneous }

  RumorRec           = String[65];      { RUMOR.DAT : rumors }

  WlRec              = String[99];      { WANTLIST.DAT : wantlist }

  OnelinerRec        = String[70];      { ONELINER.DAT : oneliners }

  BdayRec=                              { BDAY.DAT : birthdays }
  record
    Name             : aStr;            { user's name }
    From             : aStr;            { where the user is from }
    Age              : Byte;            { what the user's age is }
  end;

  MacroRec=                             { MACROS.DAT : user macros }
  record
    Macro            : Array[1..4] of String[240]; { macros       }
                                        { 1:^D  2:^E  3:^F  4:^R }
  end;

  Smr=                                  { SHORTMSG.DAT : one-line messages }
  record
    Msg              : aStr;            { message }
    Destin           : Integer;         { destination (-1 to delete) }
  end;

(*****************************************************************************)
{ Area list compression tables }

  AreaIdxRec=                           { MSG.IDX/FILE.IDX : compression table }
  record
    Alias            : Integer;         { alias base number (appears to user) }
    Real             : Integer;         { real file base number in FBOARDS.DAT }
  end;

(*****************************************************************************)
{ Message boards }

  MbFlags=                              { msg area flags - stored in BoardRec }
   (MbVisible,                          { visible to users without access? }
    MbRealName,                         { real names are forced? }
    MbFilter,                           { filter ANSI and 8-bit ASCII? }
    MbStrip,                            { strip box/centering codes? }
    MbAddTear,                          { add tear/origin lines? }
    MbNoColor,                          { strip color codes? }
    MbNoTwit);                          { immune to I_ECHO twit? }

  AnonTyp=                              { anonymous types - stored in BoardRec }
   (atNo,                               { no anonymous posts allowed }
    atYes,                              { anonymous posts are allowed }
    atForced,                           { all posts are forced anonymous }
    atAnyName);                         { users can post as any name they want }

  BaseTyp=                              { base types - stored in BoardRec }
   (Public,                             { public base }
    Private,                            { private base }
    Networked,                          { base networked? }
    News);                              { news/announcements }

  { The following are the combinations of BaseTyp --                     }
  {                                                                      }
  { Public                   : Local, public base.  Anybody can read.    }
  { Private                  : Local, private base.  Only intended       }
  {                            recipient may read.                       }
  { Public/Private           : Local base which only intended recipient  }
  {                            may read; however, messages may be        }
  {                            addressed to 'all.'                       }
  { Public Networked         : Echomail                                  }
  { Private Networked        : Netmail                                   }
  { Public/Private Networked : Networked base that is private, yet msgs  }
  {                            addressed to all may be read by anyone.   }

  BoardRec=                             { MBOARDS.DAT : Message base records }
  record
    PermIndx         : Word;            { permanent index # (used for QWK) }
    Name             : String[40];      { message base description }
    QWKname          : String[12];      { short description for QWK }
    MsgAreaID        : String[128];     { message area ID }
    EmailScan        : Boolean;         { include in email scan? }

    Acs              : ACString;        { access requirement }
    PostAcs          : ACString;        { post access requirement }
    SubOpAcs         : ACString;        { subop access requirement }
    MciAcs           : ACString;        { MCI usage requirement }
    AttachAcs        : ACString;        { file attach access requirement }

    MaxMsgs          : Word;            { maximum message count }
    MaxDays          : Word;            { maximum days to keep mesages }
    AnStat           : AnonTyp;         { anonymous type }
    MbStat           : set of MbFlags;  { message base status }
    BaseStat         : set of BaseTyp;  { base type (see above) }

    Origin           : String[50];      { origin line }
    Text_Color       : Char;            { color of standard text }
    Quote_Color      : Char;            { color of quoted text }
    Tear_Color       : Char;            { color of tear line }
    Origin_Color     : Char;            { color of origin line }
    Aka              : Byte;            { network AKA }
    ScanType         : Byte;            { scan type - 0:Default ON  }
                                        {             1:Default OFF }
                                        {             2:Mandatory  }
    MsgHeaderFile    : String[8];       { message header textfile }

    res1:Array[1..491] of Byte;         { reserved }
  end;

(*****************************************************************************)
{ File bases }

  fbFlags=                              { file area flags - stored in ULRec }
   (fbNoRatio,                          { no ratio? }
    fbUnhidden,                         { visible to all users? }
    fbDirDLPath,                        { if *.DIR file stored in DLPath }
    reserved,                           { reserved }
    fbUseGifSpecs,                      { insert GIFspecs? }
    fbNetlink);                         { networked? }

  ULRec=                                { FBOARDS.DAT : file base records }
  record
    Name             : String[40];      { area description }
    Filename         : String[12];      { filename + ".DIR" }
    DLPath           : String[40];      { path to files }

    res1:Array[1..41] of Byte;          { reserved }

    MaxFiles         : Integer;         { maximum number of files allowed }

    res2:Array[1..21] of Byte;          { reserved }

    ArcType          : Byte;            { wanted archive type (1..Max,0=inactive) }
    CmtType          : Byte;            { wanted comment type (1..3,0=inactive) }

    res3:Array[1..2] of Byte;           { reserved }

    fbStat           : set of fbFlags;  { file base status }
    Acs              : ACString;        { access requirements }
    ULAcs            : ACString;        { upload acs }
    NameAcs          : ACString;        { see uploaders' names acs }
    PermIndx         : LongInt;         { permanent index # }

    res4:Array[1..6] of Byte;           { reserved }
  end;

  FilStat=                              { file flags - stored in ULFRec }
   (NotVal,                             { if file is NOT validated }
    IsRequest,                          { if file is REQUEST }
    ResumeLater);                       { if file is RESUME-LATER }

  ULFRec=                               { *.DIR : file records }
  record
    Filename         : String[12];      { filename }
    Description      : String[60];      { file description }
    FilePoints       : Integer;         { file points }
    NAcc             : Integer;         { number of downloads }
    Ft               : Byte;            { file type (useless?) }
    Blocks           : LongInt;         { number of 128 byte blocks }
    Owner            : Integer;         { uploader of file }
    StOwner          : String[36];      { uploader's name }
    Date             : String[8];       { date uploaded }
    DateN            : Integer;         { numeric date uploaded }
    VPointer         : LongInt;         { pointer to verbose descr (-1 if none) }
    FileStat         : set of FilStat;  { file status }

    res1:Array[1..10] of Byte;          { reserved }
  end;

  VerbRec=                              { VERBOSE.DAT : verbose descriptions }
  record
    Descr            : Array[1..9] of String[50]; { description }
  end;

(*****************************************************************************)
{ Newscan }

  ZScanRec=                             { NEWSCAN.DAT : file newscan records }
  record
    fZScan           : fZScanR;         { newscan file bases }
  end;

  MsgScanRec=                           { *.MSI : message newscan records }
  record
    MailScan         : Boolean;         { base in newscan }
    QWKscan          : Boolean;         { base in QWK scan }
  end;

(*****************************************************************************)
{ Menus -- used internally }

  MnuFlags=                             { menu flags - stored in MenuRec }
   (ClrScrBefore,                       { C: clear screen before menu display }
    DontCenter,                         { D: don't center the menu titles }
    NoMenuPrompt,                       { N: no menu prompt whatsoever? }
    ForcePause,                         { P: force a pause before menu display? }
    ClrScrAfter,                        { R: clear screen after command received }
    UseGlobal);                         { G: use global menu commands? }

  MenuRec=                              { *.MNU : menu records (mainly used internally) }
  record
    MenuName         : String[56];      { menu name }
    Directive        : String[12];      { normal menu text file }
    Tutorial         : String[12];      { extended help text file }
    mPromptF         : String[12];      { prompt text file }
    MenuPrompt       : String[56];      { menu prompt }
    ForceInput       : Byte;            { forced input type  0:normal }
                                        { 0:normal  1:line  2:hotkey }
    HiLite           : Byte;            { lightbar highlight color }
    LoLite           : Byte;            { lightbar normal color }
    Acs              : ACString;        { access requirements }
    Password         : String[15];      { password required }
    Fallback         : String[8];       { fallback menu }
    ForceHelpLevel   : Byte;            { forced help level for menu             }
                                        { 0:none  1:expert  2:normal  3:extended }
    GenCols          : Byte;            { generic menus: # of columns }
    GCol             : Array[1..3] of Char; { generic menus: colors }
    MenuFlags        : set of MnuFlags; { menu status variables }
  end;

  CommandRec=                           { *.MNU : command records (mainly used internally) }
  record
    LDesc            : String[70];      { command description }
    SDesc            : String[35];      { command string }
    CKeys            : String[14];      { command execution keys }
    Acs              : ACString;        { access requirements }
    CmdKeys          : String[2];       { command keys }
    MString          : String[50];      { command data }
    Visible          : Boolean;         { visible to all users? }
  end;

(*****************************************************************************)
{ Protocols }

  XbFlags=                              { protocol flags - stored in ProtRec }
   (XbActive,                           { protocol active? }
    XbIsBatch,                          { batch protocol? }
    XbIsResume,                         { resume protocol? }
    XbXferOkCode);                      { read error codes? }

  ProtRec=                              { PROTOCOL.DAT - protocols }
  record
    XbStat           : set of XbFlags;  { protocol flags }
    CKeys            : String[14];      { command keys }
    Descr            : String[40];      { description }
    Acs              : ACString;        { access string }
    TempLog          : String[25];      { temporary log file }

    res0:Array[1..52] of Byte;          { reserved }

    ULCmd            : String[78];      { upload commandline }
    DLCmd            : String[78];      { download commandline }
    ULCode           : Array[1..6] of String[6]; { UL result codes }
    DLCode           : Array[1..6] of String[6]; { DL result codes }
    Envcmd           : String[60];      { environment setup command }
    DLFList          : String[25];      { batch download file list }

    res1:Array[1..2] of Byte;           { reserved }

    LogPf            : Integer;         { position in log file for filename }
    LogPs            : Integer;         { position in log file for status }
    PermIndx         : LongInt;         { permanent index # }

    res2:Array[1..11] of Byte;          { reserved }
  end;

(*****************************************************************************)
{ Teleconference }

  NameStr            = String[36];

  EachNodeRec=                          { TELECONF.USR : users in teleconference }
  record
    Name             : NameStr;         { name of user }
    Channel          : NameStr;         { channel name }
    CbChannel        : Word;            { current C.B. channel }
    Invisible        : Boolean;         { invisible? }
    ShowAll          : Boolean;         { ??? }
  end;

  EachLine=                             { TELEDATA.### : messages to node }
  record
    Data             : String[160];     { message }
    DataFor:                            { message destination }
      (Channel,                         { message for main channel }
       CbChannel,                       { message for C.B. channel }
       Sent);                           { a message sent message }
  end;

  ActionRec=                            { ACTION.DAT : teleconference actions }
  record
    Act              : String[25];      { action name, ie: "spit" }
    ObjectMsg        : String[80];      { message sent to object of action }
    GlobalMsg        : String[80];      { message sent to everyone else }
    YourMsg          : String[80];      { message sent to sender of action }
    NoObject         : String[80];      { message sent to everyone if no obj. }
  end;

(*****************************************************************************)
{ Conferences }

  ConfrRec=                             { CONF.DAT : conferences            }
  record                                  { 0 .. 26 }
    Active           : Boolean;         { is this conference used? }
    Name             : String[40];      { conference name }
    Acs              : ACString;        { conference ACS requirement }
  end;

(*****************************************************************************)
{ Validation }

  ValRec=                               { AUTOVAL.DAT : autovalidation profiles }
  record                                  { 1 - 26 }
    Name             : String[30];      { validation profile name }
    Sl               : Byte;            { security level }
    Dsl              : Byte;            { download security level }
    Ar               : set of AcRq;     { AR flags }
    Ac               : set of uFlags;   { AC flags }
    Fp               : Integer;         { file points }
    Credit           : LongInt;         { credit }
    uNote            : String[20];      { user note }
    AcType           : Boolean;         { AC flags are hard/soft }
    ArType           : Boolean;         { AR flags are hard/soft }
  end;

(*****************************************************************************)
{ Hudson message type }

  MsgInfoType=                          { MSGINFO.BBS }
  record
    LowMsg           : Word;            { low message number }
    HighMsg          : Word;            { high message number }
    Active           : Word;            { number of active messages }
    AreaActive       : Array[1..200] of Word; { number active in each area }
  end;

  MsgIdxType=                           { MSGIDX.BBS }
  record
    MsgNum           : Word;            { message number }
    Area             : Byte;            { message area }
  end;

  MsgHdrType=                           { MSGHDR.BBS }
  record
    MsgNum           : Word;            { message number }
    ReplyTo          : Word;            { message is reply to this number }
    SeeAlso          : Word;            { message has replies }
    Extra            : Word;            { reserved }
    StartRec         : Word;            { starting seek offset in MSGTXT.BBS }
    NumRecs          : Word;            { number of MSGTXT.BBS records }
    DestNet          : Integer;         { netmail destination net }
    DestNode         : Integer;         { netmail destination node }
    OrigNet          : Integer;         { netmail originating net }
    OrigNode         : Integer;         { netmail originating node }
    DestZone         : Byte;            { netmail destination zone }
    OrigZone         : Byte;            { netmail originating zone }
    Cost             : Word;            { netmail cost }
    MsgAttr          : Byte;            { message attribute - bitmapped }
                                        { $01:deleted message }
                                        { $02:unexported netmail message }
                                        { $04:netmail message }
                                        { $08:private message }
                                        { $10:message is received }
                                        { $20:unexported echomail message }
                                        { $40:"locally" entered message }
    NetAttr          : Byte;            { netmail attribute - bitmapped }
                                        { $01:delete after exporting }
                                        { $02:message has been sent }
                                        { $04:message has file attach }
                                        { $08:crash message }
                                        { $10:message requests receipt }
                                        { $20:message requests audit }
                                        { $40:message is return receipt }
                                        { $80:message is file request }
    Area             : Byte;            { message area }
    Time             : String[5];       { message time in hh:mm }
    Date             : String[8];       { message date in mm-dd-yy }
    MsgTo            : String[35];      { message is intended for }
    MsgFrom          : String[35];      { message was written by }
    Subj             : String[72];      { message subject }
  end;

  LastReadType = Array[1..200] Of Word; { LASTREAD.BBS }

(*****************************************************************************)
{ Fidonet *.MSG message type }

  FidoAttrib=                            { message attributes - stored in FidoMsgRec }
   (fPrivate,                            { private }
    fCrash,                              { crash mail }
    fReceived,                           { received }
    fSent,                               { sent }
    fFAttach,                            { file attached }
    fInTransit,                          { in-transit }
    fOrphan,                             { orphaned }
    fKill,                               { kill after sending }
    fLocal,                              { local message }
    fHold,                               { hold for pickup }
    funused,                             { reserved }
    fFReq,                               { file request }
    fRReq,                               { return receipt request }
    fReceipt,                            { return receipt message }
    fAReq,                               { audit request }
    fFUReq);                             { file update request }

  FidoMsgRec=                            { *.MSG files }
  record
    MsgFrom          : Array[1..36] of Char; { from information }
    MsgTo            : Array[1..36] of Char; { to information }
    Subject          : Array[1..72] of Char; { subject }
    Date_Time        : Array[1..20] of Char; { date/time of message }
    TimesRead        : Word;             { times read }
    DestNode         : Word;             { destination node # }
    OrigNode         : Word;             { origin node #}
    Cost             : Word;             { cost of message }
    OrigNet          : Word;             { origin network # }
    DestNet          : Word;             { destination network # }
    DestZone         : Word;             { destination zone # }
    OrigZone         : Word;             { origin zone # }
    DestPoint        : Word;             { destination point # }
    OrigPoint        : Word;             { origin point # }
    ReplyTo          : Word;             { reply to message # }
    Attribute        : set of FidoAttrib; { attributes }
    NextReply        : Word;             { next reply }
  end;

  FidoReadRec=                           { LASTREAD. }
  record
    LastRead         : Word;             { last message # read }
  end;

(*****************************************************************************)
{ JAM message type }

  JamInfoRec=                            { *.JHR : JAM message base header }
  record                                 { first record }
    Signature       : Array[1..4] of Char; { message signature - "JAM" plus nul }
    DateCreated     : LongInt;           { creation date }
    ModifyCount     : LongInt;           { modification counter }
    ActiveMsgs      : LongInt;           { active messages }
    PasswordCRC     : LongInt;           { CRC of password, -1 = none }
    BaseMsgNum      : LongInt;           { lowest number in index }

    res:Array[1..1000] of Byte;          { reserved }
  end;

  JamMsgAttr=                            { message attributes - stored in JamHdrRec }
   (jLocal,                              { local }
    jInTransit,                          { in-transit }
    jPrivate,                            { private }
    jRead,                               { read by receiver }
    jSent,                               { sent }
    jKillSent,                           { kill msg/sent }
    jArchiveSent,                        { archive msg/sent }
    jHold,                               { hold }
    jCrash,                              { crash }
    jImmediate,                          { immediate }
    jDirect,                             { direct }
    jGate,                               { gate }
    jFileReq,                            { file requests }
    jFileAttach,                         { files attached }
    jTruncFiles,                         { truncate sent files }
    jKillFiles,                          { kill sent files }
    jReceiptReq,                         { receipt requested }
    jConfirmReq,                         { confirmation of receipt }
    jOrphan,                             { orphaned message }
    jEncrypt,                            { encrypted message }
    jCompress,                           { compressed message }
    jEscaped,                            { escaped message }
    jForcePickup,                        { force pickup }
    jTypeLocal,                          { local only }
    jTypeEcho,                           { for echo distribution }
    jTypeNet,                            { for netmail distribution }
    jNoMsgDisplay,                       { no message display }
    jLocked,                             { locked message }
    jDeleted);                           { deleted message }

  JamHdrRec=                             { *.JHR : JAM message headers }
  record
    Signature       : Array[1..4] of Char; { message signature - "JAM" plus nul }
    Revision        : Word;              { JAM revision level }

    res1:Array[1..2] of Byte;            { reserved }

    SubFieldLen     : LongInt;           { length of subfields }
    TimesRead       : LongInt;           { # times message read }
    MsgIdCRC        : LongInt;           { CRC-32 of MSGID line }
    ReplyCRC        : LongInt;           { CRC-32 of REPLY line }
    ReplyTo         : LongInt;           { reply to # }
    Reply1st        : LongInt;           { 1st reply number }
    ReplyNext       : LongInt;           { reply next }
    Date            : UnixTime;          { date written }
    DateRcvd        : UnixTime;          { date received }
    DateProc        : UnixTime;          { date processed (tosser/scanner) }
    MsgNum          : LongInt;           { message number }
    Attribute       : set of JamMsgAttr; { attributes }

    res2:Array[1..4] of Byte;            { reserved }

    TextOffset      : LongInt;           { offset of text in *.JDT file }
    TextLen         : LongInt;           { length of text }
    PasswordCRC     : LongInt;           { CRC-32 of password }
    Cost            : LongInt;           { cost of message }
  end;

  JamSubFieldRec=                        { *.JHR : subfield records }
  record
     fieldid        : Word;              { subfield ID }
     res1:Array[1..4] of Byte;           { reserved }
     datalen        : LongInt;           { length of buffer }
  end;

  { The *.JHR file contains most of the information that is required for
    messages.  The first record contains information about the base that
    is being looked at.  The records afterword are variable in length
    because of the numerous subfields that may or may not exist for each
    message:

    jaminforec
    jamhdrrec[1]
       subfield[1]
       subfield character buffer
          :
       subfield[n]
       subfield character buffer
    jamhdrrec[2]
       :
    jamhdrrec[n]
  }

  JamIndexRec=                          { *.JDX : JAM quick index }
  record
     UserCRC         : LongInt;         { CRC-32 of receipient's name }
     HdrOffset       : LongInt;         { offset to JamHdrRec }
  end;

  JamReadRec=                           { *.JLR : JAM last read storage }
  record
     UserCRC         : LongInt;         { CRC-32 of receipients name (lower) }
     UserID          : LongInt;         { unique user-ID }
     LastRead        : LongInt;         { last read pointer }
     HighRead        : LongInt;         { high read pointer }
  end;

(*****************************************************************************)
{ Squish message type }

  SqInfoRec=                            { *.SQD : Squish message base header }
  record                                { first record }
    Length           : Word;            { length of this structure }

    res1:Array[1..2] of Byte;           { reserved }

    NumMsgs          : LongInt;         { number of messages }
    HighMsg          : LongInt;         { highest message (=num_msg) }
    KeepMsgs         : LongInt;         { # of messages to keep }
    HwMsgId          : LongInt;         { high water message msg-ID # }
    LastMsgId        : LongInt;         { last message msg-ID # }
    BaseName         : String[79];      { basename for SquishFile }
    FirstMsgPtr      : LongInt;         { offset to first message header }
    LastMsgPtr       : LongInt;         { offset to last message header }
    FirstFreePtr     : LongInt;         { offset to first free header }
    LastFreePtr      : LongInt;         { offset to last free header }
    LastPtr          : LongInt;         { offset of end of file }
    MaxMsgs          : LongInt;         { maximum number of messages }
    KeepDays         : Word;            { days to keep messages }
    SqHdrSize        : Word;            { size of header record }

    res2:Array[1..124] of Byte;         { reserved }
  end;

  SqFHdrRec=                            { *.SQD : Message header }
  record
    SqId             : LongInt;         { squish ID - $AFAE4453 }
    NextMsg          : LongInt;         { offset to last message }
    PrevMsg          : LongInt;         { offset to previous message }
    TotalLength      : LongInt;         { length of header & message }
    MsgLength        : LongInt;         { length of message }
    ControlLen       : LongInt;         { length of control information }
    HeaderType       : Word;            { header type: 0:message }
                                        {              1:free    }

    res1:Array[1..2] of Byte;           { reserved }
  end;

  SqshMsgAttr=                          { message attributes - stored in SqMHdrRec }
   (sPrivate,                           { private }
    sCrash,                             { crash }
    sRead,                              { read by receiver }
    sSent,                              { sent }
    sFileAttach,                        { files attached }
    sInTransit,                         { in-transit }
    sOrphan,                            { orphaned message }
    sKillSent,                          { kill msg/sent }
    sLocal,                             { local }
    sHold,                              { hold }
    sFileReq,                           { file requests }
    sReceiptReq,                        { receipt requested }
    sConfirmReq,                        { confirmation of receipt }
    sAudit,                             { audit trail requested }
    sUpdate,                            { update request }
    sScanned,                           { echomail scanned }
    sMsgId,                             { valid msgid? }

    sres1,  sres2,  sres3,  sres4,      { reserved }
    sres5,  sres6,  sres7,  sres8,
    sres9,  sres10, sres11, sres12,
    sres13, sres14, sres15);

  SqMHdrRec=                            { *.SQD: Message Info Header }
  record
    Attribute        : set of SqshMsgAttr; { message attributes }
    MsgFrom          : Array[1..36] of Char; { message from - nul terminated }
    MsgTo            : Array[1..36] of Char; { message to - nul terminated }
    Subject          : Array[1..72] of Char; { message subject - nul terminated }
    OrigAddr         : AkaRec;          { origin address }
    DestAddr         : AkaRec;          { destination address }
    OrigDate         : LongInt;         { original date (utc) }
    MsgDate          : LongInt;         { arrival (system) date (utc) }
    UTCoffSet        : Word;            { minutes offset of utc }
    ReplyTo          : LongInt;         { reply-to msg-ID # }
    Replies          : Array[1..9] of LongInt; { replies msg-ID # }
    MsgId            : LongInt;         { message id }
    RawDate          : Array[1..20] of Char; { ascii date - nul terminated }
  end;

  SqIndexRec =                          { *.SQI : Squish message index }
  record
    MsgPtr           : LongInt;         { offset of SqFHdr record }
    MsgId            : LongInt;         { msg-ID # }
    Hash             : LongInt;         { hash of 'To' name }
  end;

  SqReadRec=                            { *.SQL : Squish last read Index }
  record
    MsgId            : LongInt;         { msg-ID # }
  end;

(*******************************[ END OF FILE ]*******************************)
