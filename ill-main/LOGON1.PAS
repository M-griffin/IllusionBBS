(*****************************************************************************)
(* Illusion BBS - Logon routines  [1/2]                                      *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit logon1;

interface

uses
  crt, dos,
  newusers, mail4, miscx, menus, menus2,
  common, crc32, mtask;

function getuser:boolean;

implementation

uses tpansii;

procedure getpws(var ok:boolean; var tries:integer);
var phone,pw,s:astr; olduser:boolean;
begin
  ok:=TRUE;

  if NOT (fastlogon) then begin

    echo:=FALSE; olduser:=useron; useron:=TRUE;
    if not systat^.localsec then
      commandline('Password - "'+thisuser.pw+'"   Phone # - "'+(copy(thisuser.ph,length(thisuser.ph)-3,4))+'"')
    else
      commandline('- Local Security ON -');
    dontgoaway:=true;
    useron:=olduser;

    spstr(11); input(pw,20);
    if (systat^.phonepw) then begin
      if (pos('-',thisuser.ph)<>0) and (length(thisuser.ph)=12) then
      begin
        spstr(12);
        sprompt('('+copy(thisuser.ph,1,3)+') '+
          copy(thisuser.ph,5,3)+'-')
      end else
      begin
        spstr(12);
        sprompt(copy(thisuser.ph,1,length(thisuser.ph)-4));
      end;
      input(phone,4);
    end else
      phone:=(copy(thisuser.ph,length(thisuser.ph)-3,4));

    echo:=TRUE;
    if ((thisuser.pw<>pw) or (copy(thisuser.ph,length(thisuser.ph)-3,4)<>phone)) then begin
      spstr(19);
      if (not hangup) and (usernum<>0) then begin
        s:='>> Illegal logon attempt! Tried: '+caps(thisuser.name)+' #'+cstr(usernum);
        s:=s+' PW="'+pw+'"'; if (systat^.phonepw) then s:=s+', PH#="'+phone+'"';
{       ssz(1,s); } {-M-}
        sysoplog(s);
        sysoplog(userip);
      end;
      inc(thisuser.illegal);
      saveuf;
      inc(tries);
      if (tries>=systat^.maxlogontries) then hangup:=TRUE;
      ok:=FALSE;
    end;

    if ((aacs(systat^.spw)) and (ok) and (incom) and (not hangup)) then begin
      echo:=FALSE; spstr(13); input(pw,20);
      if (pw<>systat^.sysoppw) then begin
        spstr(19);
        s:='>> Illegal system pw! Tried: '+caps(thisuser.name)+' #'+cstr(usernum)+' PW='+pw;
 {      ssz(1,s); } {-M-}
        sysoplog(s);
        sysoplog(userip);
        inc(tries);
        if (tries>=systat^.maxlogontries) then hangup:=TRUE;
        ok:=FALSE;
      end;
      echo:=TRUE;
    end;

    if ((ok) and (systat^.shuttlelog) and (thisuser.lockedout)) then begin
      printf(thisuser.lockedfile);
      sysoplog('>> '+thisuser.name+' attempted to access system when locked out');
      sysoplog(userip);
      hangup:=TRUE;
    end;

    dontgoaway:=false;

  end;
end;

procedure s7;
var a,d:integer;
begin
  for a:=1 to 10 do begin
    d:=18;
    while d<2500 do begin
      sound(d); delay(a); nosound; d:=d+100;
    end;
  end;
end;

procedure termdetect;
const ansiseq:string[4]=#27+'[6n';
      avtseq :string[2]=^V^F;
      ripseq :string[3]=#27+'[!';

      TheWord:String[8]='DEMO';
      TheCRC:LongInt=522767851;

      numusers:real=50.783;

var r:real; c:char; i,x:integer; s:string[20];
    crc:longint;

   procedure getrest;
   var r1:real; c:char;
   begin
     r1:=timer; s:='';
     repeat
       c:=inkey; if (not (c in [#0,#27,'R','['])) then s:=s+c;
     until (timer-r1>=1.0) or (upcase(c)='R') or (hangup);
   end;

   procedure getrip;
   var r1:real; c:char;
   begin
     r1:=timer; s:='';
     repeat
       c:=inkey; if (ord(c)>=32) then s:=s+c;
     until (timer-r1>=0.75) or (length(s)>=14);
   end;

  

begin
  if (spd<>'KB') then with thisuser do
  begin
    sleep(500);
    com_flush_rx; c:=#0; i:=1; x:=0; exclude(ac,rip);

    spstr(424);

    repeat
      case i of
        1,2:pr1(ansiseq);
        3:if (systat^.allowavatar) then pr1(avtseq);
        4:if (systat^.allowrip) then pr1(ripseq);
      end;
      r:=timer;
      if (i<=2) then repeat c:=inkey; until (timer-r>=1.5) or (c<>#0) or (hangup);

      if (i<=2) and (c=#27) then
      begin
        i:=3;
        include(ac,ansi);
        exclude(ac,avatar);
        getrest;
        getnumber(s);
        x:=getnumber(s);
      end else
      if (i=2) then
      begin
        exclude(ac,ansi);
        exclude(ac,avatar);
        i:=3;
        if (systat^.reqansi) and (not pynq(getstr(492))) then hangup:=TRUE
                                                        else include(ac,ansi);
      end else
      if (i=3) and (systat^.allowavatar) then
      begin
        pr1(ansiseq);
        getrest;
        getnumber(s);
        if x+1=getnumber(s) then
        begin
          include(ac,ansi);
          include(ac,avatar);
        end else
          prompt(^H^H'  '^H^H);
        i:=4;
      end else
      if (i=4) and (systat^.allowrip) then
      begin
        getrip;
        if (copy(s,1,8)='RIPSCRIP') then
        begin
          include(ac,rip);
          exclude(ac,ansi);
          exclude(ac,avatar);
          sleep(500);
        end;
        i:=5;
      end else
        inc(i);

    until (i>4) or (hangup);

    nl;
    if okansi then
    begin
      if okrip then
      begin
        spstr(602);
        for i:=1 to 3 do begin pr1(#27'[1!'); sleep(60); end;
      end else
      if okavatar then
        spstr(601)
      else
      if okansi then
        spstr(600);
    end;
  end else
    include(thisuser.ac,ansi);

  Crc:=$FFFFFFFF;
  For i:=1 to length(TheWord) do
    Crc:=UpdC32(ord(TheWord[i]),crc);

  If CRC<>TheCRC then
    begin
      Sprint('|RInvalid copy of Illusion.');
      halt;
    end;

  spstr(425);
end;

procedure nulrecord;
var valf:file of valrec;
    val:valrec;
    kansi,kavatar,krip:boolean;
begin
  assign(valf,systat^.datapath+'AUTOVAL.DAT');
  SetFileAccess(ReadOnly,DenyNone);
  reset(valf); read(valf,val); close(valf);

  if (ansi in thisuser.ac) then kansi:=true else kansi:=false;
  if (avatar in thisuser.ac) then kavatar:=true else kavatar:=false;
  if (rip in thisuser.ac) then krip:=true else krip:=false;
  with thisuser do begin
    fillchar(thisuser,sizeof(thisuser),#0);
    usernum:=-1;
    name:='New User'; realname:='New User';
    sl:=0; dsl:=0; ar:=[];
    ac:=[onekey,pause,novice]; ac:=ac+val.ac;
    if (kansi) then ac:=ac+[ansi];
    if (kavatar) then ac:=ac+[avatar];
    if (krip) then ac:=ac+[rip];
    linelen:=80; pagelen:=25;
    tltoday:=30;  { > give user 30 min to logon < }
  end;
  topscr;
end;

procedure doshuttle;
var s,cmd,pw,newmenucmd:astr;
    xx:char;
    xz:byte absolute xx;
    tries,i,nocsave:integer;
    loggedoz,gotname,noneedname,ok,cmdnothid,cmdexists:boolean;
    val,val2:valrec; valf:file of valrec;
begin
  assign(valf,systat^.datapath+'AUTOVAL.DAT');
  SetFileAccess(ReadOnly,DenyNone);
  reset(valf); read(valf,val); read(valf,val2); close(valf);

  nl; termdetect;
  if (okansi) then
    last_menu:=systat^.matrixmenu_ansi
  else
    last_menu:=systat^.matrixmenu_tty;
  curmenu:=systat^.menupath+last_menu+'.MNU'; readin;
  loggedoz:=FALSE;
  gotname:=FALSE;
  tries:=0;

  chelplevel:=2;
  repeat
    tshuttlelogon:=0;
    mainmenuhandle(cmd);

    if ((not gotname) and (cmd<>'')) then begin
      noneedname:=TRUE; i:=0;
      repeat
        loggedoz:=False;
        fcmd(cmd,i,noc,cmdexists,cmdnothid);
        if (i<>0) then
          if (cmdr[i].cmdkeys<>'LP') and (cmdr[i].cmdkeys<>'L1') and
             (cmdr[i].cmdkeys<>'L2') and (cmdr[i].cmdkeys[1]<>'H') and
             (cmdr[i].cmdkeys<>'-F') and (cmdr[i].cmdkeys<>'-L') and
             (cmdr[i].cmdkeys<>'-S') and (cmdr[i].cmdkeys<>'-W') and
             (cmdr[i].cmdkeys<>'-;') and (cmdr[i].cmdkeys<>'-$') and
             (cmdr[i].cmdkeys<>'-Y') and (cmdr[i].cmdkeys<>'-P') and
             (cmdr[i].cmdkeys<>'OI') and (cmdr[i].cmdkeys<>'-C') and
             (cmdr[i].cmdkeys<>'-\') and (cmdr[i].cmdkeys<>'-/') and
             (cmdr[i].cmdkeys<>'OO') and (cmdr[i].cmdkeys<>'-^') then
            noneedname:=FALSE;
      until (i=0);
      if (not noneedname) then begin
        spstr(10); finduser(s,usernum);
        if (usernum>=1) then begin
          SetFileAccess(ReadWrite,DenyNone);
          reset(uf); seek(uf,usernum); read(uf,thisuser);
          getpws(ok,tries); gotname:=ok; nl;
          if (gotname) then begin
            readinmacros; readinzscan; useron:=TRUE;
            schangewindow(TRUE,curwindow); commandline('');
            sysoplog('Matrix logon: '+caps(thisuser.name)+' #'+
                     cstr(usernum));
            sysoplog(userip);
            if (MailWaiting) then begin
              nl; if pynq(getstr(35)) then ScanForYourMail; nl;
            end;
          end else nulrecord;
        end else begin
          spstr(18);
          loggedoz:=False; nulrecord;
        end;
      end;
    end;

    if ((gotname) or (noneedname)) then begin
      newmenucmd:='';
      repeat domenuexec(cmd,newmenucmd) until (newmenucmd='');
      case tshuttlelogon of

        1:if (systat^.shuttlepw='') then loggedoz:=TRUE else begin
            echo:=FALSE;
            spstr(15); input(pw,20);
            nl; echo:=TRUE;
            if (pw=systat^.shuttlepw) then
              loggedoz:=TRUE
            else begin
              sysoplog('>> Illegal matrix password: "'+pw+'"');
              sysoplog(userip);
              spstr(19); inc(tries); loggedoz:=FALSE;
            end;
          end;

        2:if (gotname) then begin
            spstr(97);
          end else begin
            if pynq(getstr(36)) then begin
              newuserinit; newuser;
              if (usernum>0) and (not hangup) then begin
                gotname:=TRUE; useron:=TRUE; logon1st;
              end;
              
              printf('afterapp');
              hangup:=true;
              
            end else loggedoz:=False;
          end;

        3:if ((thisuser.sl>val.sl) or (thisuser.dsl>val.dsl) or
             ((val.sl=val2.sl) and
             (val.dsl=val2.sl))) then begin
            sysoplog('Found out the matrix password.');
            sysoplog(userip);            
            spstr(29);
            clearwaves;
            addwave('MP',systat^.shuttlepw,txt);
            spstr(30);
            clearwaves;
            loggedoz:=pynq(getstr(31));
          end else begin
            spstr(32);
            if systat^.nuv then spstr(33);
            spstr(441);
            sysoplog('Tried to find out matrix password, was not validated.');
            sysoplog(userip);
            loggedoz:=False;
          end;

      end; {case}
    end;
    if (tries=systat^.maxlogontries) then hangup:=TRUE;
  until (loggedoz) or (hangup);
end;


procedure getacsuser(eventnum:integer; acsreq:astr);
var user:userrec; sr:smalrec;
    r:real;
    s,pw:astr;
    cp,un,i:integer;
    c:char;

  procedure dobackspace;
  begin
    dec(cp);
    outkey(^H); outkey(' '); outkey(^H);
  end;

begin
  spstr(427);
  checkhangup;
  if (hangup) then exit;
  r:=timer; s:=''; cp:=1; echo:=TRUE;
  repeat
    checkhangup;
    c:=inkey;
    if (c<>#0) then
      case c of
        ^H:if (cp>1) then dobackspace;
        ^X:while (cp<>1) do dobackspace;
        #32..#255:
           if (cp<=36) then begin
             c:=upcase(c);
             outkey(c);
             s[cp]:=c; inc(cp);
           end;
      end;
    if (timer-r>30.0) then begin
        spstr(426);
        hangup:=TRUE;
    end;
  until ((c=^M) or (hangup));
  s[0]:=chr(cp-1);
  if (not hangup) then begin
    un:=value(s);
    if (un<>0) then begin
      SetFileAccess(ReadOnly,DenyNone);
      reset(uf);
      if (un>filesize(uf)-1) then un:=0
      else begin
        seek(uf,un);
        read(uf,user);
      end;
      close(uf);
    end else begin
      SetFileAccess(ReadOnly,DenyNone);
      reset(sf);
      un:=0; i:=1;
      while ((i<=filesize(sf)-1) and (un=0)) do begin
        seek(sf,i); read(sf,sr);
        if (s=sr.name) then un:=sr.number;
        inc(i);
      end;
      if (un>filesize(sf)-1) then un:=0;
      close(sf);
      if (un<>0) then begin
        SetFileAccess(ReadOnly,DenyNone);
        reset(uf);
        seek(uf,un); read(uf,user);
        close(uf);
      end;
    end;
    if (un<>0) then usernum:=un;
    if ((user.deleted) or (not aacs1(user,usernum,acsreq))) then un:=0;
    if (un=0) then begin
      spstr(428);
      hangup:=TRUE;
    end else begin
      spstr(429);
      echo:=FALSE;
    spstr(430);
    input(pw,20);
    if (pw<>user.pw) then begin
      spstr(431);
      hangup:=TRUE;
    end else
      spstr(432);
    echo:=TRUE;
    end;
  end;
end;

function getuser:boolean;
var pw,s,phone,newusername,acsreq:astr;
    lng:longint;
    tries,i,ttimes,z,zz,eventnum:integer;
    done,nu,ok,toomuch,wantnewuser,acsuser:boolean;
    tempnode:noderec;
begin
  wasnewuser:=FALSE; onekcr:=TRUE; didlogfirst:=FALSE;
  extratime:=0.0; freetime:=0.0; choptime:=0.0;
  nulrecord;
  getdatetime(timeon);
  mread:=0; extratime:=0.0; freetime:=0.0;
  realsl:=-1; realdsl:=-1;
  newusername:='';
  useron:=TRUE;
  clearwaves;
  curwindow:=1; windowon:=systat^.windowdefon;
  schangewindow(not cwindowon,curwindow);

  s:='Login ';
  if (realspd<>'KB') then s:=s+'at '+realspd+'BPS' else s:=s+'locally';
  writeln(sysopf);
  sl1(s);

  wantnewuser:=FALSE;
  macok:=FALSE; nu:=FALSE;
  echo:=TRUE; nl;
  pw:='';

  with thisnode do begin
    username:=getstr(433);
    unum:=0;
    whereuser:='';
  end;
  savenode;

  if ((value(realspd)<=modemr^.lowspeed) and (outcom) and (modemr^.lowspeed>0)) then begin
    if (modemr^.lowpw<>'') then begin
      spstr(14);
      echo:=FALSE;
      input(s,20);
      echo:=TRUE;
    end;

    if ((s<>modemr^.lowpw) or (modemr^.lowpw='')) then begin
      spstr(434);
      hangup:=TRUE;
    end;
  end;

  acsuser:=FALSE;
  (*
  for i:=0 to numevents do
    with events[i]^ do
      if ((etype='A') and (active) and (checkeventtime(i,0))) then begin
        acsuser:=TRUE;
        acsreq:=events[i]^.execdata;
        eventnum:=i;
      end;
  if (acsuser) then getacsuser(eventnum,acsreq); 
  *) {Disable Events MF}

  if ((systat^.shuttlelog) and (not fastlogon) and (not hangup)) then doshuttle;
  nl;

  if not (systat^.shuttlelog) then begin termdetect; end;
  if (not wantnewuser) and (not fastlogon) then begin
    printf('welcome');
    z:=0;
    repeat
      inc(z);
      printf('welcome'+cstr(z));
    until (z=9) or (nofile) or (hangup);
  end;

  ttimes:=0; tries:=0; s:='';

  repeat

    nulrecord;

    repeat
      if (not wantnewuser) then begin
        if (getstr(639)<>'') then spstr(639);
        if (getstr(640)<>'') then spstr(640);
        if (getstr(10)<>'') then spstr(10);
      end;
      if (systat^.shuttlelog) and (wantnewuser) then begin
        s:=''; usernum:=-1;
      end else
        finduser(s,usernum);

      if (not hangup) then begin
        newusername:='';

        if (usernum=0) then begin
          if (s<>'') and (allcaps(s)<>getstr(323)) then begin
            spstr(17); {name not found}     {^NEW}
            if (not systat^.shuttlelog) then
            begin
              clearwaves;
              addwave('UN',s,txt);
              if pynq(getstr(435)) then usernum:=-1;
              clearwaves;   {^create account?}
            end else
              spstr(22); {cannot logon as new here}
            if (usernum<>-1) then
              sysoplog('"'+s+'" not found in user list');
              sysoplog(userip);
            inc(ttimes);
            if (ttimes>=systat^.maxlogontries) then hangup:=TRUE;
          end else
          if ((allcaps(s)=getstr(323)) and (systat^.shuttlelog)) then
            spstr(22)           {^NEW}
          else   {^cannot logon as new here}
          begin
            inc(ttimes);
            if (ttimes>=systat^.maxlogontries) then hangup:=TRUE;
          end;
          nl;
        end;

      end;
    until ((usernum<>0) or (hangup));

    ok:=TRUE; done:=FALSE;
    if (not hangup) then
      case usernum of
       -1:begin
            newuserinit;
            nu:=TRUE;
            done:=TRUE; ok:=FALSE;
          end;
       -3:begin
            spstr(20);
            sysoplog('User tried to crash system with negative number entry at logon');
            sysoplog(userip);
            hangup:=TRUE;
          end;
      else begin
          SetFileAccess(ReadWrite,DenyNone);
          reset(uf); seek(uf,usernum); read(uf,thisuser);
          realsl:=thisuser.sl; realdsl:=thisuser.dsl;
          if (not systat^.localsec) then begin
            if (not useron) then begin
              useron:=TRUE;
              schangewindow(TRUE,curwindow);
            end else
              schangewindow(FALSE,curwindow);
            {useron:=FALSE;}
          end;
          getpws(ok,tries);
          if (ok) then begin
            done:=TRUE;
            readinmacros; readinzscan;
          end else
          begin
            realsl:=-1; realdsl:=-1;
          end;
      end;
      end; {case}
  until ((done) or (hangup));

  { VALID USER LOGGED ON or USER HUNGUP }

  if (not hangup) then begin
    i:=0; ok:=TRUE; SetFileAccess(ReadOnly,DenyNone); reset(nodef);
    if (not nu) then
      while (ok) and (i<=filesize(nodef)-1) do begin
        seek(nodef,i); read(nodef,tempnode);
        if ((tempnode.username=caps(thisuser.name)) or
            (tempnode.unum=usernum))
           then ok:=FALSE;
        inc(i);
      end;
    close(nodef);

    if (not ok) then begin
      spstr(21);
      hangup:=TRUE;
    end else
    with thisnode do
    begin
      username:=caps(thisuser.name);
      if (usernum=-1) then unum:=0 else unum:=usernum;
      whereuser:=getstr(436);
      savenode;
    end;
  end;

  if ((thisuser.lockedout) and (not hangup)) then begin
    printf(thisuser.lockedfile);
    sysoplog('>> '+thisuser.name+' attempted to access system when locked out');
    sysoplog(userip);
    hangup:=TRUE;
  end;

  if ((not nu) and (not hangup)) then begin
    toomuch:=FALSE;
    if (thisuser.laston<>date) then begin
      thisuser.ontoday:=0;
      thisuser.tltoday:=systat^.timeallow[thisuser.sl];
    end;

    if (((rlogon in thisuser.ac) or (systat^.callallow[thisuser.sl]=1)) and
       (thisuser.ontoday>=1) and (thisuser.laston=date)) then begin
      spstr(23);
      toomuch:=TRUE;
    end else

    if ((thisuser.ontoday>=systat^.callallow[thisuser.sl]) and
        (thisuser.laston=date)) then begin
      clearwaves;
      addwave('CC',cstr(systat^.callallow[thisuser.sl]),txt);
      spstr(24);
      clearwaves;
      toomuch:=TRUE;
    end else

    if ((thisuser.tltoday<=0) and (thisuser.laston=date)) then begin
      clearwaves;
      addwave('TA',cstr(systat^.timeallow[thisuser.sl]),txt);
      spstr(25);
      clearwaves;
      toomuch:=TRUE;

      if (thisuser.timebank>0) then begin
        spstr(26);
        dyny:=TRUE;
        if pynq(getstr(27)) then begin
          spstr(179); inu(zz); lng:=zz;
          if (lng>0) then begin
            if (lng>thisuser.timebank) then lng:=thisuser.timebank;
            dec(thisuser.timebankadd,lng);
            if (thisuser.timebankadd<0) then thisuser.timebankadd:=0;
            spstr(437);
            sysoplog('No time left at logon, withdrew '+cstrl(lng)+' minutes');
            sysoplog(userip);
          end;
        end;
        if (nsl>=0) then toomuch:=FALSE else spstr(28);
      end;
    end;

    if (toomuch) then begin
      sysoplog('>> '+thisuser.name+' #'+cstr(usernum)+' tried logging on more than allowed');
      sysoplog(userip);
      hangup:=TRUE;
    end;
    if (tries=systat^.maxlogontries) then hangup:=TRUE;
    if (not hangup) then inc(thisuser.ontoday);
  end;

  { USER ALLOWED ON (time left ok, etc.) }

  checkit:=FALSE;
  if ((usernum>0) and (not hangup)) then begin
    getuser:=nu; loggedin:=true;
    schangewindow(not cwindowon,curwindow);
    commandline('Successful logon...');
    inittrapfile;
    spstr(34);
  end;
  if (hangup) then getuser:=FALSE;
end;

end.
