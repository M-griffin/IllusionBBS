(*****************************************************************************)
(* Illusion BBS - Waiting for caller menu                                    *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit wfcmenu;

INTERFACE

uses crt,
     dos,
     initp,   { System / Data Init }


     sysop2,  { P - ChangeStuff }
     sysop3,  { U - UserEdit }
     sysop4,  { N - Tedit1 }
     sysop6,  { E - EventEdit }
     sysop7,  { # - MenuEdit }
     sysop8,  { B - BoardEdit }
     sysop9,  { F - dlboardedit }
     sysop10, { V - InitVotes }
     sysop11, { L - ShowLogs, zlog }

     mail1,   { MessageSystemInit}
     mail4,   { MailWaitingFor }
     mail5,   { QuickMail }

     NewFile, { File System }
     NewFile2,

     misc2,
     mmodem,
     myio,
     common,
     mtask,
     pdmenu;

procedure wfcinit;
procedure hangupphone;
procedure wfcmenus(wanthangup:boolean);
procedure wfcmsg(s:string);

IMPLEMENTATION

VAR
  saveractive:boolean;       { screen saver active? }
  lastrc:string;             { last result code received }
  screen:^screentype;        { used to save screen }
  wfclock:boolean;

CONST
  cnt:word=1;       { current pos in scroller }
  filet1:real=0.0;  { timer for file check }
  logot1:real=0.0;  { timer for scroller }

procedure wfcinit;
begin
  inwfcmenu:=TRUE; outcom:=FALSE;
  if answerbaud>2 then
  begin
    realspd:=cstrl(answerbaud);
    spd:=cstrl(answerbaud);
  end else
  begin
    spd:='KB';
    realspd:='KB';
  end;
  incom:=spd<>'KB';

  hangup:=FALSE;   hungup:=FALSE;
  useron:=FALSE;   usernum:=1;              cwindowon:=FALSE;

  etoday:=0;       ll:='';                  enddayf:=FALSE;
  ptoday:=0;       buf:='';
  telluserevent:=0;                         fastlogon:=FALSE;
  cfo:=FALSE;      outputbuff^:='';         loggedin:=false;

  fileboard:=1;    badfpath:=FALSE;         readuboard:=-1;

  MessageSystemInit;

  chatt:=0;        chatr:='';
  chatcall:=FALSE; shutupchatcall:=FALSE;

  checkit:=FALSE;

  textbackground(0); clrscr;

  setfileaccess(readonly,denynone);
  reset(uf);
  if (filesize(uf)>1) then
  begin
    seek(uf,1); read(uf,thisuser);
    close(uf);
    newcomptables;
    usernum:=1;
    readinmacros; readinzscan;
  end else
  begin
    close(uf);
    with thisuser do
    begin
      linelen:=80; pagelen:=25;
      ac:=[onekey,pause,novice,ansi];
      ac:=ac-[avatar];
    end;
  end;
end;

procedure savescreen;
begin
  move(ptr(vidseg,0)^,screen^,4000);
end;

procedure restorescreen;
begin
  move(screen^,ptr(vidseg,0)^,4000);
end;

function wfctime:string;
var s:string[11];
begin
  s:=propertime;
  delete(s,6,4);
  if (s[1]='0') then s[1]:=' ';
  wfctime:=s;
end;

function wfcdate:string;
var s:string[8];
begin
  s:=date;
  if (s[1]='0') then s[1]:=' ';
  wfcdate:=date;
end;

procedure wfcmsg(s:string);
begin
  if saveractive then exit;
  window(6,4,47,14);
  textattr:=7;
  gotoxy(41,11);
  writeln;
  write(wfctime+'  '+s);
  window(1,1,80,linemode);
  savescreen;
end;

procedure hangupphone;
begin
  restorescreen;
  dophonehangup(true);
end;

procedure checkresultcode(var chkcom:boolean);
var rc:resulttype;
    c:char;
    j:byte;
begin
  if (localioonly) then exit;

  doresultcode(rc,5.0,true);
  lastrc:=rc;

  if (pos(modemr^.codering,rc)<>0) then
  begin
    wfcmsg('Sending answer string');
    sleep(modemr^.answerdelay*100);
    com_flush_rx;
    outmodemstring(modemr^.answer);
    chkcom:=true;
  end else
  if (pos(modemr^.codeok,rc)<>0) then
  begin
    com_flush_rx;
  end else

  begin
    for j:=19 downto 0 do
      if (modemr^.resultcode[j]<>'') and (pos(modemr^.resultcode[j],rc)<>0) and (spd='KB') then
      begin
        case j of
          0:spd:='300';    1:spd:='1200';   2:spd:='2400';
          3:spd:='4800';   4:spd:='7200';   5:spd:='9600';
          6:spd:='12000';  7:spd:='14400';  8:spd:='16800';
          9:spd:='19200'; 10:spd:='21600'; 11:spd:='24000';
         12:spd:='26400'; 13:spd:='28800'; 14:spd:='31200';
         15:spd:='33600'; 16:spd:='38400'; 17:spd:='57600';
         18:spd:='64000'; 19:spd:='115200';
        end;
      end;
    if (spd<>'KB') then
    begin
      realspd:=spd;
      sleep(2000);
      spd:=cstr(fixspeed(value(spd)));
      textattr:=7;
    end;
  end;

  if (spd<>'KB') then incom:=TRUE;
  textattr:=7;
  savescreen;
end;

(*                 {-M-}
{ // Remove old shortmsgs // }
PROCEDURE optimize_mail;
var x:smr;
    s,d:integer;
begin
  SetFileAccess(ReadWrite,DenyALL);
  {$I-} reset(smf); {$I+}
  if (ioresult=0) then begin
    if (filesize(smf)>1) then begin
      s:=0; d:=0;
      while (s<filesize(smf)) do begin
        seek(smf,s); read(smf,x);
        if (x.destin<>-1) then
          if (s=d) then inc(d) else begin
            seek(smf,d); write(smf,x);
            inc(d);
          end;
        inc(s);
      end;
      seek(smf,d);
      truncate(smf);
    end;
    close(smf);
  end;
end; {proc optimize_mail}
*)

procedure loadwfcmenu;
{$I wfcimg.pas}
var screen:^screentype;
    i:byte;
begin
  if (saveractive) then exit;
  window(1,1,80,linemode); cursoron(FALSE); clrscr;
  checkvidseg;
  screen:=ptr(vidseg,0);
  uncrunch(wfcimg,screen^[0],wfcimg_length);
  gotoxy(59,22); textattr:=(1 shl 4)+9;
  for i:=1 to length(ver)-1 do write(ver[i]+' ');
  write(ver[length(ver)]);
end;

procedure wfcmenus(wanthangup:boolean);
var speed,i:byte;
    c:char;                       { menu choice }
    phoneoffhook,                 { phone off hook? }
    chkcom,                       { check for caller? }
    oldphoneoffhook:boolean;      { store phoneoffhook for local }
    ok:array[1..2] of boolean;
    sysopfo:boolean;              { Sysop log open? }
    major,minor:byte;             { Pull down menu choices }
    pull:^pull_array;             { Pull down menu definitions }
    lastinit:real;
    hadansi,nogoodcmd:boolean;
    ltime:string[15];
    dt,ddt:datetimerec;
    rcode:integer;
    rl2:real;
    SysOpMailWaiting:Word;        { Pieces of email for SysOp }
    s:astr;

  procedure initmodem;
  var try:integer;
      done:boolean;
      i:byte;
  begin
    if (localioonly) or ((modemr^.init[1]='') and (modemr^.init[2]='')) or (answerbaud>0) then exit;

    if modemr^.portlock then
      speed:=modemr^.lockspeed
    else
      speed:=modemr^.waitbaud;
    speed:=fixspeed(speed);
    com_set_speed(speed);

    try:=1; done:=false;

    repeat
      ok[1]:=false; ok[2]:=false;
      wfcmsg('Initializing modem');
      for i:=1 to 2 do
        if (modemr^.init[i]<>'') and (not done) and (not chkcom) then
        begin
          sleep(200);
          com_flush_rx;
          outmodemstring(modemr^.init[i]);
          checkresultcode(chkcom);
          if (not incom) then
          begin
            ok[i]:=pos(modemr^.codeok,lastrc)<>0;
            sleep(300);
          end;
        end else
          ok[i]:=true;
      done:=(ok[1] and ok[2]);
      inc(try);
    until (done) or (try>3) or (chkcom);
    sleep(500);
    phoneoffhook:=FALSE;
    lastinit:=timer;
    chkcom:=false;
    com_flush_rx;
    wfcmsg('Waiting for call or event');
  end;

  procedure checkdiskspace;
  var dfm:real;     { disk space in megs  }
      dfr:longint;  { disk space in bytes }
  begin
    dfr:=freek(0);
    dfm:=dfr/1024;
    if (dfr<systat^.minspaceforupload) or (dfr<systat^.minspaceforpost) then
      wfcmsg('Running low on disk space');
  end;

  const SCROLLER_X1     = 8;
        SCROLLER_X2     = 75;
        SCROLLER_Y      = 17;
        SCROLLER_LENGTH = SCROLLER_X2 - SCROLLER_X1 + 1;

  function spacer:string;
  var s:string[SCROLLER_LENGTH];
  begin
    fillchar(s,sizeof(s),#32);
    s[0]:=chr(SCROLLER_LENGTH);
    spacer:=s;
  end;

  procedure swrite(s:string);
  begin
    cwriteat(SCROLLER_X1,SCROLLER_Y,
             #2#1#3#8+s[1]+#3#9+s[2]+#3#7+s[3]+
             #3#15+copy(s,4,SCROLLER_LENGTH-6)+
             #3#7+s[SCROLLER_LENGTH-2]+#3#9+s[SCROLLER_LENGTH-1]+#3#8+s[SCROLLER_LENGTH]);
{   clreol; }
  end;

  procedure update_info;
  var msg1,msg2:string;
  begin

    if wfclock then
    begin
      textattr:=31;
      cwriteat(9,1,'system locked - press a key to unlock');
    end else
    begin
      textattr:=25;
      cwriteat(9,1,'press esc for menu                   ');
    end;

    msg1:='... The Illusion Bulletin Board System  Version '+ver+' ÄÄ '+
          'Programmed by Mercyful Fate ÄÄ ';
    msg2:='Nemesis Programming Team  '+
          '(tm) 2003 ... ';

    if (systat^.specialfx and 4=4) and (timer-logot1>=0.25) then
    begin
      logot1:=timer;
      if (cnt<=SCROLLER_LENGTH) then
        swrite(copy(spacer+msg1,cnt,SCROLLER_LENGTH))
      else
      if (cnt>=length(msg1)+SCROLLER_LENGTH) then
        swrite(copy(msg2+spacer,cnt-length(msg1)-SCROLLER_LENGTH,SCROLLER_LENGTH))
      else
        swrite(copy(msg1+msg2,cnt-SCROLLER_LENGTH,SCROLLER_LENGTH));
      inc(cnt);
      if cnt>=length(msg1)+length(msg2)+SCROLLER_LENGTH then cnt:=1;
    end;

    textattr:=31;
    cwriteat(54,25,wfcdate);
    cwriteat(63,25,wfctime);
    textattr:=15;
    cwriteat(19,23,aonoff(sysop,'Available','Not here '));

    if (abs(timer-filet1)>=15.0) then
    begin
      readsystat;
      textattr:=15;

      cwriteat(19,21,cstr(nodenum));
      gotoxy(19,22);
      case systype of
        1:write('DESQview');
        2:write('Windows 3.x');
        3:write('OS/2');
        4:write('Windows 95');
        else write('DOS');
      end;
      gotoxy(19,24);
      if (nomail in thisuser.ac) then
        write('Box closed ')
      else
      if (SysOpMailWaiting=0) then
        write('None       ')
      else
        write(cstr(SysOpMailWaiting)+' letter'+aonoff(SysOpMailWaiting>1,'s',''));
      cwriteat(38,21,cstr(systat^.todayzlog.calls));
      cwriteat(38,22,cstr(systat^.todayzlog.pubpost));
      cwriteat(38,23,cstr(systat^.todayzlog.uploads)+'/'+cstr(systat^.todayzlog.uk)+'k');
      cwriteat(38,24,cstr(systat^.todayzlog.downloads)+'/'+cstr(systat^.todayzlog.dk)+'k');

      filet1:=timer;
    end;
    savescreen;
  END;

  procedure takeoffhook;
  begin
    if (not localioonly) then
    begin
      dophoneoffhook(TRUE);
      phoneoffhook:=TRUE;
    end;
  end;

  procedure beephim;
  var rl,rl1:real; ch:char;
  begin
    takeoffhook;
    beepend:=FALSE;
    rl:=timer;
    repeat
      sound(1500); sleep(20);
      sound(1000); sleep(20);
      sound(800); sleep(20);
      nosound;
      rl1:=timer;
      while (abs(rl1-timer)<0.9) and (not keypressed) do;
      update_info;
    until (abs(rl-timer)>30.0) or (keypressed);
    if keypressed then ch:=readkey;
    initmodem;
  end;

  procedure definemenu;
  begin
    fillchar(pull^,sizeof(pull^),#0);
    PdMenu.PTTT.Gap:=2;
    pull^[1 ]:='\Main';
    pull^[2 ]:=' Local Logon   SPC ';
    pull^[3 ]:=' QuickMsg Menu   M ';
    pull^[4 ]:=' QuickFile Menu  $ ';
    pull^[5 ]:=' Mini-DOS        ! ';
    pull^[6 ]:=' DOS Shell       D ';
    pull^[7 ]:=' Quit to DOS     Q ';

    pull^[8 ]:='\Modem';
    pull^[9 ]:=' Initialize Modem    + ';
    pull^[10]:=' Answer Phone        A ';
    pull^[11]:=' Take Phone Offhook  O ';
    pull^[12]:=' Hangup Phone        H ';

    pull^[13]:='\Config';
    pull^[14]:=' Msg Base Editor       B ';
    pull^[15]:=' Events Editor         E ';
    pull^[16]:=' File Base Editor      F ';
    pull^[17]:=' Text Editor           N ';
    pull^[18]:=' System Configuration  P ';
    pull^[19]:=' User Editor           U ';
    pull^[20]:=' Voting Booth Editor   V ';
    pull^[21]:=' Menu Editor           # ';

    pull^[22]:='\Information';
    pull^[23]:=' Caller Log      C ';
    pull^[24]:=' Sysop Logs      L ';
    pull^[25]:=' History Log     Z ';

    pull^[26]:='\\';
  end;

  function menureturn(var major,minor:byte):char;
  var c:char;
  begin
    c:=#0;
    case major of
      1:case minor of
          1:c:=' '; 2:c:='M'; 3:c:='$';
          4:c:='!'; 5:c:='D'; 6:c:='Q';
        end;
      2:case minor of
          1:c:='+'; 2:c:='A'; 3:c:='O'; 4:c:='H';
        end;
      3:case minor of
          1:c:='B'; 2:c:='E'; 3:c:='F'; 4:c:='N'; 5:c:='P';
          6:c:='U'; 7:c:='V'; 8:c:='#';
        end;
      4:case minor of
          1:c:='C'; 2:c:='L'; 3:c:='Z';
        end;
    end;
    menureturn:=c;
  end;

  procedure chkevents;
  var i,rcode:integer;
  begin
    if (checkevents(0)<>-1) then
      for i:=0 to numevents do
      begin
        if (checkpreeventtime(i,0)) then
          if (not phoneoffhook) then
          begin
            wfcmsg('Preparing for event at '+copy(ctim(events[i]^.exectime),4,5)+':00');
            takeoffhook;
          end;
        if (checkeventtime(i,0)) then
          with events[i]^ do
          begin
            initmodem;
            if (busyduring) then takeoffhook;
            wfcmsg('Executing event '+description);
            sl1('* Ran event "'+description+'"');
            case etype of
              'D':begin
                    sysopfo:=(textrec(sysopf).mode<>fmclosed);
                    if (sysopfo) then close(sysopf);
                    cursoron(TRUE);
                    shelldos(FALSE,execdata,rcode);
                    cursoron(FALSE);
                    if (sysopfo) then append(sysopf);
                    sl1('* Returned from "'+description+'"');
                    clrscr;
                    if (not localioonly) then outmodemstring(modemr^.hangup);
                    sleep(300);
                    init;
                  end;
              'E':begin
                    cursoron(TRUE);
                    doneday:=TRUE;
                    elevel:=value(execdata);
                  end;
            end;
          end;
      end;
  end;

BEGIN
  getdatetime(lastkeypress);
  saveractive:=FALSE;
{ wantout:=not systat.localscreensec; }
  wfclock:=systat^.localsec;
  new(pull);
  chkcom:=false;

  nogoodcmd:=FALSE;

  wfcinit;
  loadwfcmenu;
  cnt:=1; filet1:=0.0;
  SysOpMailWaiting:=MailWaitingForUser(1);
  update_info;
  checkdiskspace;

  if (wanthangup) then
  begin
    hangupphone;
    wanthangup:=FALSE;
  end;

  iport;
  term_ready(TRUE);
  sleep(500);
  initmodem;

  DefineMenu;

  if (localioonly) then
  begin
    chkcom:=false;
    answerbaud:=0;
  end;

  if (answerbaud=0) then
  begin
    writeln(sysopf);
    sl1('Waiting for caller');
  end;

  if (beepend) then
    wfcmsg('Paging sysop')
  else
  if (doneafternext) then
    wfcmsg('Not answering any more calls')
  else
  if (answerbaud<>0) then
    wfcmsg('Answering modem at '+cstrl(answerbaud));
  answerbaud:=0;

  REPEAT

    if (systype>0) and (not saveractive) then timeslice;

    if (daynum(date)<>ldate) then
      if (daynum(date)-ldate)=1 then
        inc(ldate)
      else
      begin
        clrscr;
        star('Date corrupted.');
        halt(1);
      end;

    randomize; hangup:=FALSE; hungup:=FALSE; macok:=TRUE;
    c:=#0; chkcom:=FALSE;
    freetime:=0.0; extratime:=0.0; choptime:=0.0;
    sdc; lil:=0; cursoron(FALSE);

    if (not saveractive) then update_info;

    if ((not saveractive) and (systat^.wfcblanktime>0)) then
    begin
      getdatetime(dt);
      timediff(ddt,lastkeypress,dt);
      if (ddt.min>=systat^.wfcblanktime) then
      begin
        saveractive:=TRUE;
        savescreen;
        if (systat^.specialfx and 8=8) then
        begin
          asm
            mov ax,00h
            mov al,13h
            int 10h
          end;
          init;
        end else
        begin
          textattr:=7;
          clrscr;
        end;
      end;
    end;

    if (ltime<>time) then
    begin
      ltime:=time;
      if (timer-lastinit>modemr^.nocallinittime*60) then begin
        lastinit:=timer;
        if (not phoneoffhook) then initmodem;
      end;
    end;

    if (numevents>=0) then chkevents;

    if (beepend) then beephim;
    if (doneafternext) then
    begin
      takeoffhook;
      elevel:=exitnormal;
      hangup:=TRUE;
      doneday:=TRUE;
      clrscr;
    end;

    c:=inkey;
    if (c<>#0) then
    begin
      if (saveractive) then
      begin
        saveractive:=FALSE;
        if (systat^.specialfx and 8=8) then
          asm
            mov ax,3
            int 10h
          end;
        restorescreen;
        getdatetime(lastkeypress);
        c:=#0;
      end;
      if (c<>#0) and (wfclock) then
      begin
        swrite(spacer);
        textattr:=31;
        cwriteat(SCROLLER_X1+20,SCROLLER_Y,'SysOp Password: ');
        cursoron(TRUE);
        infield_out_fgrd:=1;
        infield_out_bkgd:=1;
        infield_inp_fgrd:=1;
        infield_inp_bkgd:=1;
        infielde(s,20);
        if (allcaps(s)=systat^.sysoppw) then wfclock:=false;
        update_info;
        c:=#0;
      end;
      if (c=#27) then
      begin
        major:=1; minor:=1;
        pulldown(pull^,major,minor);
        c:=menureturn(major,minor);
      end;
      c:=upcase(c);
      cursoron(TRUE);
      textattr:=7;
      curco:=7;
      hadansi:=ansi in thisuser.ac;
      include(thisuser.ac,ansi);
      wantout:=TRUE;
      case c of
        '`':begin
              saveractive:=TRUE;
              savescreen;
              if (systat^.specialfx and 8=8) then
              begin
                asm
                  mov ax,00h
                  mov al,13h
                  int 10h
                end;
                init;
              end else
              begin
                textattr:=7;
                clrscr;
              end;
              nogoodcmd:=true;
            end;
        'H','+':
            begin
              initmodem;
              nogoodcmd:=TRUE;
            end;
         ^C:begin
              wfclock:=true;
              update_info;
            end;
        '!':begin
              clrscr;
              minidos;
            end;
        'A':if (not localioonly) then
            begin
              wfcmsg('Sending answer string');
              sleep(modemr^.answerdelay*100);
              com_flush_rx;
              outmodemstring(modemr^.answer);
            end else
              nogoodcmd:=TRUE;
        'B':boardedit;
        'C':begin
              clrscr;
              callerlog;
              pausescr;
            end;
        'D':begin
              wfcmsg('Invoking DOS shell');
              sysopshell(FALSE);
              chdir(start_dir);
              wfcmsg('Returned from DOS shell');
            end;
        'E':eventedit;
        'F':dlboardedit;
        'V':initvotes;
        'L':begin
              clrscr;
              showlogs;
              writeln; pausescr;
            end;
        'M':quickmail;
        'N':begin
              clrscr;
              tedit1;
            end;
        '$':quickfile;
        'O':begin
              if (not phoneoffhook) then takeoffhook else initmodem;
              nogoodcmd:=TRUE;
            end;
        'P':changestuff;
        'Q':begin elevel:=exitnormal; hangup:=TRUE; doneday:=TRUE; end;
        'T':begin
              chdir(start_dir);
              if (exist('term.bat')) then
              begin
                clrscr; tc(15); write('Running TERM.BAT ...');
                writeln;
                sl1('* Executed TERM.BAT');
                shelldos(FALSE,'term.bat',rcode);
                clrscr;
                restorescreen;
                initmodem;
                nogoodcmd:=true;
              end;
              chdir(start_dir);
            end;
        'U':uedit1;
        'Z':begin clrscr; zlog; pausescr; end;
        '#':menu_edit;
        ' ':begin
              cursoron(false);
              oldphoneoffhook:=phoneoffhook;
              if (systat^.offhooklocallogon) and (not phoneoffhook) then takeoffhook;
              swrite(spacer);
              swrite(copy(spacer,1,(SCROLLER_LENGTH-24) div 2)+'Logon? [Y]es [N]o [F]ast');
              rl2:=timer;
              while (not keypressed) and (abs(timer-rl2)<30.0) do;
              if (keypressed) then c:=readkey else c:='N';
              c:=upcase(c);
              textattr:=7;
              case c of
                'F':begin
                      fastlogon:=TRUE;
                      c:=' ';
                    end;
                'Y':c:=' ';
              else
                    c:='@';
              end;
              if (c='@') then
              begin
                if ((systat^.offhooklocallogon) and (not oldphoneoffhook)) then initmodem;
                update_info;
                nogoodcmd:=TRUE;
              end;
              cursoron(true);
            end;
        else
          nogoodcmd:=TRUE;
      end;
      if (not hadansi) then exclude(thisuser.ac,ansi);
      if (not nogoodcmd) then
      begin
        getdatetime(lastkeypress);
        if (c<>'A') then
        begin
          if (not localioonly) then com_flush_rx;
          curco:=7; sdc;
          window(1,1,80,linemode);
          restorescreen;
        end;
        SysOpMailWaiting:=MailWaitingForUser(1);
        update_info;
      end else
        nogoodcmd:=FALSE;
      filet1:=0.0;
    end;

    if (c<>' ') then c:=#0;

    if (not localioonly) and (not com_rx_empty) then
    begin
      if ((not phoneoffhook) and (not localioonly)) then
      begin
        if (saveractive) then
        begin
          saveractive:=FALSE;
          if (systat^.specialfx and 8=8) then
            asm
              mov ax,3
              int 10h
            end;
          restorescreen;
          getdatetime(lastkeypress);
        end;
        checkresultcode(chkcom);
        if (not incom) and (spd='KB') and (c<>' ') then
        begin
          if (pos(modemr^.codenocarrier,lastrc)<>0) then initmodem;
          if (quitafterdone) then
          begin
            elevel:=exitnormal; hangup:=TRUE;
            doneday:=TRUE;
          end;
        end;
      end;
    end;

  UNTIL ((incom) or (c=' ') or (doneday));

  etoday:=0; ptoday:=0; chatt:=0; shutupchatcall:=FALSE;
  badfpath:=FALSE; dispose(pull);

  if (not doneday) then
  begin
    savescreen;
    window(1,1,80,linemode);
    textattr:=7;
    clrscr;
    writeln('Baud = '+spd);
  end;
  curco:=7; sdc;

  if (incom) then begin
    com_flush_rx; term_ready(TRUE);
    outcom:=TRUE;
  end else begin
    if (not phoneoffhook) then term_ready(FALSE);
    incom:=FALSE; outcom:=FALSE;
  end;

  getdatetime(timeon);
  if (not localioonly) then com_flush_rx;
  outputbuff^:='';
  lil:=0;
  curco:=$07;
  checkit:=TRUE; beepend:=FALSE;
  inwfcmenu:=FALSE;

  if (systat^.localscreensec) then wantout:=FALSE;
  if (spd='KB') and (not wantout) then wantout:=TRUE;
  if (wantout) then cursoron(TRUE);

  savesystat;
  for i:=1 to 4 do macros^.macro[i]:='';
END;

begin
  new(screen);
end.
