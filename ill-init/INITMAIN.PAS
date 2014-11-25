Unit INITMAIN;

{$A-,B-,D-,E-,F+,I+,L-,N-,R-,S-,V-}

Interface

uses dos,crt,objects,drivers,views,menus,dialogs,app,msgbox;

{$I rec25.pas}

Var Path:array[1..12] of string;
    curdir:string;     { Current directory }
    installdir:string; { Install directory }

    dirinfo:searchrec;
    found:boolean;

Function Cstr(i:longint):string;
function value(s:string):longint;
function allcaps(s:string):string;
Function SqOutSp(S:string):string;
procedure RemoveEndSlashes(var s:string);
Function Exist(fn:string):boolean;

procedure make_status_dat;
procedure make_modem_dat(n:byte);

function make_path(s:string):boolean;
function make_paths:boolean;

procedure copyfile1(srcname,destpath:string);
procedure movefile1(srcname,destpath:string);
procedure movefiles(srcname,destpath:string);
procedure copyfiles(srcname,destpath:string);

Implementation

function cstr(i:longint):string;
var c:string[16];
begin
  str(i,c);
  cstr:=c;
end;

function value(s:string):longint;
var i:longint;
    j:integer;
begin
  val(s,i,j);
  if (j<>0) then begin
    s:=copy(s,1,j-1);
    val(s,i,j)
  end;
  value:=i;
  if (s='') then value:=0;
end;

function allcaps(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do s[i]:=upcase(s[i]);
  allcaps:=s;
end;

function sqoutsp(s:string):string;
begin
  while (pos(' ',s)>0) do delete(s,pos(' ',s),1);
  sqoutsp:=s;
end;

procedure RemoveEndSlashes(var s:string);
begin
  while(copy(s,length(s),1)='\') do s:=copy(s,1,length(s)-1);
end;

function exist(fn:string):boolean;
var srec:searchrec;
begin
  findfirst(sqoutsp(fn),anyfile,srec);
  exist:=(doserror=0);
end;

function tch(s:astr):astr;
begin
  if (length(s)>2) then s:=copy(s,length(s)-1,2) else
    if (length(s)=1) then s:='0'+s;
  tch:=s;
end;

function date:astr;
var r:registers;
    y,m,d:string[3];
    yy,mm,dd,dow:word;
begin
  getdate(yy,mm,dd,dow);
  str(yy-1900,y); str(mm,m); str(dd,d);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
end;

(****************************************************************************)
(****************************************************************************)

procedure make_status_dat;
var systatf:file of systatrec;
    systat:systatrec;
    i,k:integer;
begin
with systat do begin

    { Set all reserved space to 0 }

    fillchar(systat,sizeof(systat),0);

    DataPath:=path[2];
    TextPath:=path[3];
    MenuPath:=path[4];
    Jampath:=path[5];
    HudsonPath:=path[6];
    SquishPath:=path[7];
    TrapPath:=path[8];
    MultPath:=path[9];
    iplxpath:=path[10];

    BBSName:='New Illusion 3.0 BBS';
    BBSLocation:='Nemesis, Earth';
    BBSPhone:='000-000-0000';
    SysopName:='System Lord';
    MaxUsers:=9999;
    NumUsers:=1;
    LowTime := 0; HiTime  := 0;

    ShuttleLog:=TRUE;

    SysopPw:='SYSTEM';
    NewuserPw:='';
    ShuttlePw:='MATRIX';

    ClosedSystem:=FALSE;
    SwapShell:=TRUE;
    SwapShelltype:=3;

    EventWarningTime:=60;
    LastMsgId:=0;
    CallerNum:=0;

    MatrixMenu_Ansi:='MATRIX';
    MatrixMenu_TTY:='MATRIX';

    EzycomPath := '';

    Sop := 's255u1';   CSop := 's250';
    MSop:= 's200';     FSop := 's210';
    SPw := 's250';     SeePw:= 's255u1';

    NormPubPost := 's20';  NormPrivPost:= 's20';  AnonPubRead:= 's250';
    AnonPrivRead:= 's250'; AnonPrivPost:= 's250'; AnonPubPost:= 's100';

    Seeunval    := 's50';  DLUnval     := 's250'; NoDLRatio  := 's250';
    NoPostRatio := 's250'; NoFilePts   := 's250'; ULValReq   := 's20';
    FastLogonAcs:= 's100'; EmergChat   := 's255';

    QwkFilename := 'ILLUSION';
    QwkDir      := '';
    QwkWelcome  := 'WELCOME';
    QwkNews     := 'NEWS';
    QwkGoodbye  := 'GOODBYE';
    QwkComp     := 'ZIP';

    MaxPrivPost:=20;   MaxOneliners:=10;
    MaxPubPost:=40;    MaxChat:=5;     MaxWaiting:=15;
    CsMaxWaiting:=50;  DescImport:=1;

    MaxLogonTries:=3;  BsDelay:=50;
    SysopColor:=3;    UserColor:=11;

    MinSpaceForPost:=128;
    MinSpaceForUpload:=1024;

    WfcBlankTime:=5;
    LineLen:=80;       PageLen:=24;
    NuvYes:=5;         NuvNo:=4;       NuvVal:='B';

    InputFieldColor:=(7 shl 4)+8;
    SpecialFx:=$01+$02+$04+$08;

    Wind_NormalC:=(1 shl 4)+7;
    Wind_HighlightC:=(1 shl 4)+15;
    Wind_LabelC:=(1 shl 4)+9;
    Wind_FlashC:=(1 shl 4)+12+128;

    ReqAnsi:=TRUE;
    CompressMsgBases:=TRUE;
    SysBatExec:=FALSE;
    AllowAlias:=TRUE;
    PhonePw:=TRUE;
    LocalSec:=FALSE;
    LocalScreenSec:=FALSE;
    GlobalTrap:=FALSE;
    AutoChatOpen:=FALSE;
    SplitChat:=TRUE;
    OffHookLocalLogon:=TRUE;
    ForceVoting:=FALSE;
    CompressFileBases:=TRUE;
    SearchDup:=TRUE;
    StripCLog:=FALSE;
    Nuv:=FALSE;
    PutOvr:=0;
    UseBios:=FALSE;
    CgaSnow:=FALSE;

    NewApp:=1;
    TimeOutBell:=3;
    TimeOut:=5;

    for i:=1 to 8 do
      with filearcinfo[i] do
        case i of
          1:begin
              active:=TRUE;
              ext:='ZIP';
              listline:='/1';
              arcline:='PKZIP -aex @F @I';
              unarcline:='PKUNZIP @F @I';
              testline:='PKUNZIP -t @F';
              cmtline:='PKZIP -z @F < @C';
              succlevel:=0;
            end;
          2:begin
              active:=FALSE;
              ext:='ARJ';
              listline:='/2';
              arcline:='ARJ a @F @I';
              unarcline:='ARJ e @F @I';
              testline:='ARJ t @F';
              cmtline:='';
              succlevel:=-1;
            end;
          2:begin
              active:=FALSE; ext:='ARC'; listline:='/3';
              arcline:='PKPAK a @F @I'; unarcline:='PKUNPAK @F @I';
              testline:='PKUNPAK -t @F'; cmtline:='PKPAK x @F'; succlevel:=0;
            end;
          3:begin
              active:=FALSE; ext:='PAK'; listline:='/3';
              arcline:='PAK a @F @I'; unarcline:='PAK e @F @I';
              testline:='PAK t @F'; cmtline:=''; succlevel:=-1;
            end;
          4:begin
              active:=FALSE; ext:='LZH'; listline:='/5';
              arcline:='LHA a @F @I'; unarcline:='LHA e @F @I';
              testline:='LHA t @F'; cmtline:=''; succlevel:=0;
            end;
          5:begin
              active:=FALSE; ext:='ZOO'; listline:='/4';
              arcline:='ZOO aP: @F @I'; unarcline:='ZOO x @F @I';
              testline:='ZOO xNd @F'; cmtline:='ZOO cA @F'; succlevel:=0;
            end;
          6:begin
              active:=FALSE; ext:='RAR'; listline:='/6';
              arcline:='RAR a @F @I'; unarcline:='RAR x @F @I';
              testline:='RAR t @F'; cmtline:='RAR c @F =@C'; succlevel:=0;
            end;
          7..8:begin
              active:=FALSE;
              ext:='';
              listline:='';
              arcline:='';
              unarcline:='';
              testline:='';
              cmtline:='';
              succlevel:=-1;
            end;
        end;

    for i:=1 to 3 do
      FileArcComment[i]:='';

    ULDLRatio:=TRUE; FilePtRatio:=TRUE;

    FilePtComp:=2;   FilePtCompBaseSize:=100;
    PostCredits:=0;  ULRefund:=100;
    ToSysopDir:=0;   ValidateAllFiles:=TRUE;

    RemDevice:='CON';

    MinResume:=100;  MaxDBatch:=20;
    MaxUBatch:=20;   UnlistFp:=0;

    ArcPath:='';     ProtPath:='';

    SwapXfer:=TRUE;

    AllStartMenu:='LOGON';

    for i:=0 to 255 do begin
      case i of 0..9:k:=1; 10..19:k:=10; 20..29:k:=20; 30..39:k:=40;
                40..49:k:=50; 50..59:k:=80; 60..69:k:=90; 70..79:k:=100;
                80..89:k:=110; 90..99:k:=120; 100..199:k:=130;
                200..239:k:=150; 240..249:k:=200; 250:k:=250;
                251..255:k:=6000; end; timeallow[i]:=k;
      case i of 200..255:k:=20; 100..199:k:=15; 50..99:k:=10;
                30..49:k:=5; 20..29:k:=3; else k:=1; end; callallow[i]:=k;
      case i of 60..255:k:=5; 20..59:k:=3; else k:=2; end; dlratio[i]:=k;
      case i of 60..255:k:=10; 20..59:k:=5; else k:=2; end; dlkratio[i]:=k;
      k:=10; postratio[i]:=k;
    end;

    Origin:='Illusion 3.0 BBS (000) 000-0000';
    Text_Color:='w';
    Quote_Color:='W';
    Tear_Color:='B';
    Origin_Color:='Y';
    Strip:=TRUE;
    AddTear:=TRUE;

    fillchar(aka,sizeof(aka),0);

    LastDate:=date;
    WindowDefOn:=TRUE; WindowOnTop:=FALSE;

    with todayzlog do begin
      Active:=0; Calls:=0; NewUsers:=0; PubPost:=0; PrivPost:=0;
      CritErr:=0; Uploads:=0; Downloads:=0; Uk:=0; Dk:=0;
    end;
    Todayzlog.Date:=date;

  end;
  assign(systatf,installdir+'Illusion.cfg');
  rewrite(systatf); write(systatf,systat); close(systatf);
end;



procedure make_modem_dat(n:byte);
var i,j:integer;
    s:string[25];
    modemr:modemrec;
    modemf:file of modemrec;
begin
with modemr do begin

    { Set all reserved space to 0 }

    fillchar(modemr,sizeof(modemr),0);

    DoorPath:=path[11];
    TempPath:=path[12];

    LastDate:=date;
    LowSpeed:=0;
    LowPW:='';

    ComPort:=1;
    WaitBaud:=14400;
    PortLock:=TRUE;
    HandShake:=HaCTSRTS;
    LockSpeed:=38400;

    ESCcode:='+++';
    init[1]:='ATZ';
    init[2]:='ATQ0V1E0M0X1S0=0S2=43S10=20S95=0&C1&D2';
    NoCallInitTime:=30;
    Answer:='ATA';
    AnswerDelay:=2;
    Hangup:='~ATH0';
    OffHook:='ATM0H1';

    CodeError:='ERROR';
    CodeNoCarrier:='NO CARRIER';
    CodeOK:='OK';
    CodeRing:='RING';

    For i:=0 to 19 do begin
      s:='CONNECT ';
      case i of
         0: ;
         1:s:=s+'1200';     2:s:=s+'2400';
         3:s:=s+'4800';     4:s:=s+'7200';
         5:s:=s+'9600';     6:s:=s+'12000';
         7:s:=s+'14400';    8:s:=s+'16800';
         9:s:=s+'19200';   10:s:=s+'21600';
        11:s:=s+'24000';   12:s:=s+'26400';
        13:s:=s+'28800';   14:s:=s+'31200';
        15:s:=s+'33600';   16:s:=s+'38400';
        17:s:=s+'57600';   18:s:=s+'64000';
        19:s:=s+'115200';
      end;
      resultcode[i]:=s;
    end;

  end;
  assign(modemf,installdir+'node.'+cstr(n));
  rewrite(modemf); write(modemf,modemr); close(modemf);
end;

(****************************************************************************)
(****************************************************************************)

function make_path(s:string):boolean;
var parent:string;
    ok:boolean;
begin
  RemoveEndSlashes(s);

  { Find this directories parent }

  parent := s;
  while((copy(parent,length(parent),1)<>'\') and (length(parent)>0)) do
    parent:=copy(parent,1,length(parent)-1);
  RemoveEndSlashes(parent);

  { Create the parent first if it doesn't already exist }

  if (parent<>'') and (parent[length(parent)]<>':') then
    if (not exist(parent)) then ok:=make_path(parent);

  make_path:=TRUE;
  {$I-} mkdir(fexpand(s)); {$I+}
  if ioresult<>0 then begin
    messagebox(^C'Error creating directory.',nil,mferror+mfokbutton);
    make_path:=FALSE;
  end;
end;

function make_paths:boolean;
var i:integer;
begin
  make_paths:=TRUE;
  for i:=2 to 12 do begin
    if (not make_path(path[i])) then begin make_paths:=FALSE; exit; end;
  end;
end;

(****************************************************************************)
(****************************************************************************)

function freek(d:integer):longint;
var lng:longint;
begin
  lng:=diskfree(d);
  freek:=lng div 1024;
end;

function exdrv(s:astr):byte;
begin
  s:=fexpand(s);
  exdrv:=ord(s[1])-64;
end;

procedure copyfile(var ok,nospace:boolean;
                   srcname,destname:astr;
                   movefile:boolean);
var buffer:array[1..16384] of byte;
    fs,dfs:longint;
    nrec,i:integer;
    src,dest:file;

  procedure dodate;
  var r:registers;
      od,ot,ha:integer;
  begin
    srcname:=srcname+#0; destname:=destname+#0;
    with r do begin
      ax:=$3d00; ds:=seg(srcname[1]); dx:=ofs(srcname[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5700; msdos(dos.registers(r));
      od:=dx; ot:=cx; bx:=ha; ax:=$3e00; msdos(dos.registers(r));
      ax:=$3d02; ds:=seg(destname[1]); dx:=ofs(destname[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5701; cx:=ot; dx:=od; msdos(dos.registers(r));
      ax:=$3e00; bx:=ha; msdos(dos.registers(r));
    end;
  end;

begin
  ok:=TRUE; nospace:=FALSE;

  if fexpand(srcname) = fexpand(destname) then exit;

  assign(src,srcname);
  {$I-} reset(src,1); {$I+}
  if (ioresult<>0) then begin
    ok:=FALSE; exit;
  end;

  dfs:=freek(exdrv(destname));        { free space on dest drive }
  fs:=trunc(filesize(src)/1024.0)+1;  { size of source file      }

  if (fs>=dfs) then begin
    close(src);
    nospace:=TRUE; ok:=FALSE;
    exit;
  end else begin
    if ((exdrv(srcname)=exdrv(destname)) and (movefile)) then begin
      close(src); rename(src,destname);
    end else begin

      assign(dest,destname);
      {$I-} rewrite(dest,1); {$I+}
      if (ioresult<>0) then begin
        ok:=FALSE; exit;
      end;

      repeat
        blockread(src,buffer,16384,nrec);
        blockwrite(dest,buffer,nrec);
      until (nrec<16384);

      close(dest); close(src);
      dodate;
      if movefile then erase(src);
    end;
  end;
end;

procedure movefile(var ok,nospace:boolean;
                   srcname,destname:astr);
begin
  copyfile(ok,nospace,srcname,destname,TRUE);
end;

procedure ffile(fn:string);
begin
  findfirst(fn,anyfile,dirinfo);
  found:=(doserror=0);
end;

procedure nfile;
begin
  findnext(dirinfo);
  found:=(doserror=0);
end;

procedure copyfile1(srcname,destpath:string);
var ps,ns,es:string;
    ok,nospace:boolean;
begin
  ok:=TRUE; nospace:=FALSE;
  fsplit(srcname,ps,ns,es);
  copyfile(ok,nospace,srcname,destpath+ns+es,FALSE);

  if (not ok) then begin
    if (nospace) then
      messagebox('Error copying files: Out of space.',nil,mferror+mfokbutton)
    else
      messagebox('Error moving/copying file ('+allcaps(srcname)+').',nil,mferror+mfokbutton);
  end;

end;

procedure movefile1(srcname,destpath:string);
var ps,ns,es:string;
    ok,nospace:boolean;
begin
  ok:=TRUE; nospace:=FALSE;
  fsplit(srcname,ps,ns,es);
  movefile(ok,nospace,srcname,destpath+ns+es);

  if (not ok) then begin
    if (nospace) then
      messagebox('Error moving files: Out of space.',nil,mferror+mfokbutton)
    else
      messagebox('Error moving file ('+allcaps(srcname)+').',nil,mferror+mfokbutton);
  end;

end;

procedure movefiles(srcname,destpath:string);
var ok,nospace:boolean;
begin
  ffile(srcname);
  while found do begin
    movefile1(dirinfo.name,destpath);
    nfile;
  end;
end;

procedure copyfiles(srcname,destpath:string);
var ok,nospace:boolean;
begin
  ffile(srcname);
  while found do begin
    copyfile1(dirinfo.name,destpath);
    nfile;
  end;
end;

end.
