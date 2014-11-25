(*****************************************************************************)
(* Illusion BBS - Common functions and procedures [2/3]                      *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit common2;

interface

uses
  crt, dos,
  myio, foscom2;

procedure showudstats;
procedure skey1(c:char);
procedure savesystat;
procedure readsystat;
procedure remove_port;
procedure openport(comport:byte; baud:longint; parity:char; databits,stopbits:byte);
procedure iport;
procedure sendcom1(c:char);
function recom1(var c:char):boolean;
procedure term_ready(ready_status:boolean);
procedure inuserwindow;
procedure commandline(s:string);
procedure sclearwindow;
procedure schangewindow(needcreate:boolean; newwind:integer);
procedure topscr;
procedure tleft;
procedure readinmacros;
procedure changeuserdatawindow;
procedure saveuf;
procedure savenode;

implementation

uses common, common1, common3;

const maxwin=5; { Number of sysop windows }

procedure cpr(c1,c2:byte; u:userrec);
var r:uflags;
begin
  for r:=rlogon to rmsg do begin
    if (r in u.ac) then textattr:=c1 else textattr:=c2;
    write(copy('LCVFA*PEKM',ord(r)+1,1));
  end;
  textattr:=c2;
  for r:=fnodlratio to fnodeletion do begin
    if (r in u.ac) then textattr:=c1 else textattr:=c2;
    write(copy('1234',ord(r)-19,1));
  end;
end;

procedure showudstats;
begin
  commandline('U/L: '+cstr(thisuser.uploads)+'/'+cstr(trunc(thisuser.uk))+'k'+
           ' ÄÄ D/L: '+cstr(thisuser.downloads)+'/'+cstr(trunc(thisuser.dk))+'k'+
           ' File Points:' +cstr(thisuser.filepoints));
end;

procedure skey1(c:char);
var s:string[50];
    cz,i:integer;
    cc:char;
    b,savwantout,sysopfo:boolean;

begin

  if (wherecurrent<>normal) then
  begin
    case wherecurrent of
      userval:
        begin
          cc:=upcase(c);
          if (cc in ['A'..'Z']) then
          begin
            autovalidate(cc,thisuser,usernum);
            commandline('User validated with profile '+cc+'.');
            dontgoaway:=false;
            wherecurrent:=normal;
          end;
        end;
    end;
    exit;
  end;

  case ord(c) of

    ALT_1..ALT_9:  { Execute GLOBALn.BAT }
      globat((ord(c)-ALT_1)+1);

    ALT_MINUS:     { Debugging info }
      commandline('Stack free: '+cstr(sptr)+' bytes ÄÄ Heap free: '+cstr(memavail)+' bytes');

    CTRL_PRTSC:    { Immediate exit BBS with error }
      exiterrorlevel;

    ALT_F:         { show help screen }
      showsysfunc;

    ALT_J:         { shell to DOS }
      if inwfcmenu then
      begin
        sysopfo:=(textrec(sysopf).mode<>fmclosed);
        if (sysopfo) then close(sysopf);
        cursoron(true);
        Sysopshell(FALSE);
        if (sysopfo) then append(sysopf);
        getdatetime(lastkeypress);
      end else
        Sysopshell(FALSE);

    ARROW_HOME:    { toggle chat buffer on/off }
      if (ch) then
        chatfile(not cfo)
      else
        buf:=buf+^[+'[H';

    ARROW_END:     { }
        buf:=buf+^[+'[K';

    ARROW_UP,      { }
    ARROW_LEFT,
    ARROW_RIGHT,
    ARROW_DOWN,
    ARROW_HOME,
    ARROW_END:
      begin
        buf:=buf+#27+'[';
        case ord(c) of
          ARROW_UP:   buf:=buf+'A';
          ARROW_LEFT: buf:=buf+'D';
          ARROW_RIGHT:buf:=buf+'C';
          ARROW_DOWN: buf:=buf+'B';
          ARROW_HOME: buf:=buf+'H';
          ARROW_END:  buf:=buf+'K';
        end;
      end;

    KEY_INSERT:
      buf:=buf+^V;

    KEY_DELETE:
      buf:=buf+#127;

  end;

  if (not inwfcmenu) then
  begin

    case ord(c) of

      ALT_L:       { cls }
        cls;

(*    ALT_T:       { top/bottom sysop window }
        if (cwindowon) then
        begin
          i:=systat.curwindow;
          sclearwindow;
          systat.istopwindow:=not systat.istopwindow;
          cwindowon:=TRUE;
          schangewindow(TRUE,i);
        end; *)

      ALT_V:       { auto-validate user }
        begin
          commandline('Use which auto-validation profile? (A-Z)');
          wherecurrent:=userval;
          dontgoaway:=true;
        end;

      F1:          { edit user }
        if (useron) then
        begin
          wait(TRUE);
          changeuserdatawindow;
          wait(FALSE);
        end;

      F2:          { change sysop window }
        if (useron) then
        begin
          i:=curwindow;
          if (windowon) then
          begin
            inc(i);
            if (i>maxwin) then i:=1;
          end else
            windowon:=TRUE;
          schangewindow(TRUE,i);
        end;

      SHIFT_F2:    { sysop window on/off }
        if (useron) then
          if (not windowon) then
          begin
            windowon:=TRUE;
            cwindowon:=TRUE;
            schangewindow(TRUE,curwindow);
          end else
          begin
            sclearwindow;
            windowon:=FALSE;
          end;

      F3:          { user keyboard on/off }
        if (not com_carrier) then
          commandline('No carrier detected!')
        else
        begin
          if (outcom) then
            if (incom) then
              incom:=FALSE
            else
            if (not localioonly) and (com_carrier) then
              incom:=TRUE;
          if (incom) then
            commandline('User keyboard ON.')
          else
            commandline('User keyboard OFF.');
          if (not localioonly) then com_flush_rx;
        end;

      SHIFT_F3:    { user screen&keyboard on/off }
        if (outcom) then
        begin
          savwantout:=wantout;
          wantout:=FALSE;
          wait(TRUE);
          wantout:=savwantout;
          commandline('User screen and keyboard OFF.');
          outcom:=FALSE;
          incom:=FALSE;
        end else
        if (not com_carrier) then
          commandline('No carrier detected!')
        else
        begin
          commandline('User screen and keyboard ON.');
          savwantout:=wantout;
          wantout:=FALSE;
          wait(FALSE);
          wantout:=savwantout;
          outcom:=TRUE;
          incom:=TRUE;
        end;

(*    ALT_F3:      { local screen on/off }
        if (wantout) then
        begin
          clrscr;
          tc(11);
          writeln('Local output OFF.');
          wantout:=FALSE;
          cursoron(FALSE);
        end else
        begin
          clrscr;
          tc(11);
          writeln('Local output ON.');
          wantout:=TRUE;
          cursoron(TRUE);
        end;
*)
      F4:          { toggle beep after end }
        begin
          beepend:=not beepend;
          b:=ch;
          ch:=TRUE;
          tleft;
          ch:=b;
        end;

      ALT_F4:      { Toggle DOS exit after logoff }
        begin
          doneafternext:=not doneafternext;
          tleft;
        end;

      F5, ALT_H:
        hangup:=TRUE;

      SHIFT_F5:
        begin
          cline(s,'Display what hangup file (HANGUPxx.*):');
          commandline('');
          if (s<>'') then
          begin
            nl;
            nl;
            incom:=FALSE;
            printf('hangup'+s);
            sysoplog('++ Displayed hangup file HANGUP'+s);
            hangup:=TRUE;
          end;
        end;

      F6:          { redraw sysop window }
        if (useron) then
        begin
          commandlinecount:=-1;
          topscr;
        end;

      F7:          { subtract time }
        begin
          b:=ch; ch:=TRUE;
          dec(thisuser.tltoday,5);
          tleft;
          ch:=b;
        end;

      F8:          { add time }
        begin
          b:=ch; ch:=TRUE;
          inc(thisuser.tltoday,5);
          if (thisuser.tltoday<0) then thisuser.tltoday:=32767;
          tleft;
          ch:=b;
        end;

      F9:          { temp sysop access }
        if (useron) then
          with thisuser do
          begin
            if (sl=255) then
              if (realsl<>255) or (realdsl<>255) then
              begin
                thisuser.sl:=realsl;
                thisuser.dsl:=realdsl;
                if (systat^.compressfilebases) or (systat^.compressmsgbases) then newcomptables;
                commandline('User access restored to previous state.');
              end else
            else
            begin
              realsl:=sl;
              realdsl:=dsl;
              thisuser.sl:=255;
              thisuser.dsl:=255;
              if (systat^.compressfilebases) or (systat^.compressmsgbases) then newcomptables;
              commandline('Temporary sysop access granted.');
            end;
          end;

      ALT_F9:      { page user }
        begin
          repeat
            outkey(^G);
            commandline('Paging user.');
            sleep(100);
            checkhangup;
          until ((not empty) or (hangup));
        end;

      F10, ALT_C:  { chat on/off }
        if (ch) then
        begin
          ch:=FALSE;
          chatr:='';
        end else
          chat(systat^.splitchat);

      SHIFT_F10:   { turn off chat page }
        begin
          chatcall:=FALSE;
          chatr:='';
          tleft;
        end;

      ALT_F10:     { show chat reason }
        commandline(chatr);
    end;

  end;
end;

procedure savesystat;
var systatf:file of systatrec;
begin
  assign(systatf,start_dir+'\ILLUSION.CFG');
  rewrite(systatf); write(systatf,systat^); close(systatf);
end;

procedure readsystat;
var systatf:file of systatrec;
begin
  assign(systatf,start_dir+'\ILLUSION.CFG');
  SetFileAccess(ReadOnly,DenyNone);
  reset(systatf); read(systatf,systat^); close(systatf);
end;

procedure setacch(c:char; b:boolean; var u:userrec);
begin
  if (b) then if (not (tacch(c) in u.ac)) then acch(c,u);
  if (not b) then if (tacch(c) in u.ac) then acch(c,u);
end;

procedure remove_port;
begin
  if (not localioonly) then com_deinstall;
end;

procedure openport(comport:byte; baud:longint; parity:char;
                   databits,stopbits:byte);
begin
  if (not localioonly) then begin
    com_set_speed(baud);
  end;
end;

procedure iport;
var anyerrors,bps:word;
begin
  if (not localioonly) then begin
    com_install(modemr^.comport);
    if modemr^.portlock then
      bps:=modemr^.lockspeed
    else
      bps:=modemr^.waitbaud;

    case bps of
      4800,
      7200:bps:=9600;    { Updates made here must also be       }
      12000,              { made to the duplicate case statement }
      14400,              { in "fixspeed" in mmodem.pas          }
      16800:bps:=19200;
      21600,
      24000,
      26400,
      28800,
      31200,
      33600:bps:=38400;
    end;

    case modemr^.handshake of
      hactsrts :com_set_flow('C');
      haxonxoff:com_set_flow('X');
    end;

    openport(modemr^.comport,bps,'N',8,1);
  end;
end;

procedure sendcom1(c:char);
begin
  if (not localioonly) then com_tx(c);
end;

function recom1(var c:char):boolean;
begin
  c:=#0;
  if (localioonly) then recom1:=TRUE else begin
    if (not com_rx_empty) then begin
      c:=com_rx;
      recom1:=TRUE;
    end else
      recom1:=FALSE;
  end;
end;

procedure term_ready(ready_status:boolean);
var mcr_value:byte;
begin
  if (not localioonly) then
    if (ready_status) then com_raise_dtr else com_lower_dtr;
end;

procedure inuserwindow;
begin
  if (cwindowon) then
    if (systat^.windowontop) then
      window(1,3,80,linemode)
    else
      window(1,1,80,linemode-2);
end;

procedure clrline(y:integer);
begin
  gotoxy(1,y); clreol;
end;

procedure commandline(s:string);
var p,yy:integer;
    sx,sy,sz:byte;
begin
  if (not useron) then exit;
  if (s='') then begin
    commandlinecount:=-1; topscr; exit;
  end;

  commandlinecount:=timer;
  sx:=wherex; sy:=wherey; sz:=textattr;

  window(1,1,80,linemode);
  if (not cwindowon) then yy:=1 else
    if (systat^.windowontop) then yy:=1 else yy:=linemode-1;

  p:=40-(length(s) div 2);
  textattr:=systat^.wind_normalc; clrline(yy);
  if cwindowon then clrline(yy+1);
  gotoxy(p,yy); write(s);

  inuserwindow;
  gotoxy(sx,sy); textattr:=sz;
end;

procedure sclearwindow;
var wind:windowrec;
    i:integer;
    x,y,z:byte;
begin
  if ((not cwindowon) or (not useron) or (not windowon)) then exit;

  x:=wherex; y:=wherey; z:=textattr; cursoron(FALSE);

  window(1,1,80,linemode); textattr:=7;
  if (not systat^.windowontop) then begin
    for i:=linemode-1 to linemode do clrline(i);
  end else begin
    savescreen(wind,1,3,80,linemode);
    for i:=1 to 2 do clrline(i);
    movewindow(wind,1,1);
    for i:=linemode-1 to linemode do clrline(i);
  end;
  cwindowon:=FALSE;

  gotoxy(x,y); textattr:=z; cursoron(TRUE);
end;

procedure schangewindow(needcreate:boolean; newwind:integer);
var wind:windowrec;
    i,z,sx,sy,sz:byte;
begin
  if (((not useron) and (not needcreate)) or (not windowon)) then exit;

  sx:=wherex; sy:=wherey; sz:=textattr;

  if (not needcreate) then needcreate:=(newwind<>curwindow);

  cursoron(FALSE);
  if (not systat^.windowontop) then begin
    if (needcreate) and (newwind in [1,2,3,4,5]) then begin
      window(1,1,80,linemode);
      gotoxy(1,linemode);
      if (sy>linemode-2) then begin
        z:=2-(linemode-sy);
        for i:=1 to z do writeln;
        dec(sy,z);
      end;
    end;
  end else begin
    if (needcreate) and (newwind in [1,2,3,4,5]) then begin
      window(1,1,80,linemode);
      if (newwind=curwindow) then
        savescreen(wind,1,1,80,linemode)
      else
        savescreen(wind,1,3,80,linemode);
      if (sy<=linemode-2) then z:=3 else z:=linemode+1-sy;
      if (z>=2) then begin
        movewindow(wind,1,z);
        sy:=sy-z+3;
      end;
      if (sy>linemode-2) then sy:=linemode-2;
      if (sy<1) then sy:=1;
    end;
  end;
  cursoron(TRUE);

  curwindow:=newwind;
  if (curwindow<>0) then cwindowon:=TRUE;
  gotoxy(sx,sy); textattr:=sz;
  topscr;
end;

function mrnn(i,l:integer):string;
begin
  mrnn:=mrn(cstr(i),l);
end;

function ctp(t,b:longint):string;
var s,s1:string[32];
    n:real;
begin
  s:=cstr((t*100) div b);
  if (length(s)=1) then s:=' '+s;
  s:=s+'.';
  if (length(s)=3) then s:=' '+s;
  n:=t/b+0.0005;
  s1:=cstr(trunc(n*1000) mod 10);
  ctp:=s+s1+'%';
end;

function xlatecolor(c:byte):string;
var f,b:byte;
begin
  f:=c and 7;
  if ((c and 8)<>0) then inc(f,8);
  if ((c and 128)<>0) then inc(f,16);
  b:=(c shr 4) and 7;
  xlatecolor:=#3+chr(f)+#2+chr(b);
end;

procedure topscr;
var i:integer;
    sx,sy,sz:byte;
    c:char;
    dfr:longint;
    normc,highc,labelc,flashc:string[4];
begin
  topscrcount:=timer;

  if ((not cwindowon) or (not useron) or (commandlinecount>0)) then exit;

  cursoron(FALSE);
  sx:=wherex; sy:=wherey; sz:=textattr;

  normc:=xlatecolor(systat^.wind_normalc);
  highc:=xlatecolor(systat^.wind_highlightc);
  labelc:=xlatecolor(systat^.wind_labelc);
  flashc:=xlatecolor(systat^.wind_flashc);

  textattr:=systat^.wind_normalc;
  if (systat^.windowontop) then window(1,1,80,2)
    else window(1,linemode-1,80,linemode);
  for i:=1 to 2 do begin gotoxy(1,i); clreol; end;

  with thisuser do
    case curwindow of
      1:begin
          cwriteat(1,1,normc+' '+mln(nam,26)+labelc+' AR: ');
            for c:='A' to 'Z' do
            begin
              if (c in ar) then
                textattr:=systat^.wind_highlightc
              else
                textattr:=systat^.wind_normalc;
              write(c);
            end;
            cwrite(labelc+' NSL: ');
            if (sl=255) and (dsl=255) and ((realsl<>255) or (realdsl<>255)) then
              cwrite(flashc+mn(sl,3))
            else
              cwrite(normc+mn(sl,3));

          cwriteat(1,2,normc+' '+mln(realname,26)+labelc+' AC: ');
            cpr(systat^.wind_highlightc,systat^.wind_normalc,thisuser);
            cwrite(labelc+' Baud: '+normc+mln(realspd,5));
            cwrite(labelc+' DSL: ');
            if (sl=255) and (dsl=255) and ((realsl<>255) or (realdsl<>255)) then
              cwrite(flashc+mn(dsl,3))
            else
              cwrite(normc+mn(dsl,3));
        end;

      2:begin
          cwriteat(1,1,normc+' '+mln(street,26));
            cwrite(labelc+' PH: '+normc+mln(ph,12)+'      ');
            cwrite(labelc+' FO: '+normc+mln(firston,8)+' '+labelc+' Term: '+normc);
            if (okrip) then cwrite('RIP')
              else if (okavatar) then cwrite('AVATAR')
              else if (okansi) then cwrite('ANSI')
              else cwrite('TTY');

          cwriteat(1,2,normc+' '+mln(citystate+' '+zipcode,26));
            cwrite(labelc+' BD: '+normc+mln(bday,8)+', '+sex+mn(ageuser(bday),6)+' ');
            cwrite(labelc+' LO: '+normc+mln(laston,8)+' '+labelc+' Edit: '+normc);
            case edtype of 0:cwrite('Choose'); 1:cwrite('Line'); 2:cwrite('FullScrn'); end;
        end;

      3:begin
          SetFileAccess(ReadOnly,DenyNone);
          cwriteat(1,1,labelc+' Snote: '+normc+mlnnomci(note,38));
            cwrite(labelc+'              Diskfree: '+normc);
            dfr:=freek(0); dfr:=dfr div 1024;
            cwrite(cstr(dfr)+'m');

          cwriteat(1,2,labelc+' Unote: '+normc+mlnnomci(usernote,25)+'             ');
            cwrite(labelc+' Calls: '+normc+mn(systat^.callernum,5));
            cwrite(labelc+' Overlays: '+normc);
            case whereisoverlay of
              0:cwrite('Disk');
              1:cwrite('EMS');
              2:cwrite('XMS');
            end;
        end;

      4:begin
          cwriteat(1,1,labelc+' TC: '+normc+mn(loggedon,5));
            cwrite(labelc+' CT: '+normc+mn(ontoday,5));
            cwrite(labelc+' PP: '+normc+mn(msgpost,5));
            cwrite('          ');
            cwrite(labelc+' DL: '+normc+mln(cstr(downloads)+'/'+cstr(dk)+'k',12));
            cwrite(labelc+' FP: '+normc+mn(filepoints,5));

          cwriteat(1,2,labelc+' TT: '+normc+mn(ttimeon,5));
            cwrite(labelc+' ES: '+normc+mn(emailsent,5));
            cwrite(labelc+' IL: '+normc+mn(illegal,5));
            cwrite('          ');
            cwrite(labelc+' UL: '+normc+mln(cstr(uploads)+'/'+cstr(uk)+'k',12));
            cwrite(labelc+' CR: '+normc+mn(credit,5));
        end;

      5:with systat^.todayzlog do begin
          cwriteat(1,1,labelc+' Today''s '+normc+'³ ');
            cwrite(labelc+' Calls: '+normc+mn(calls,5)+' ');
            cwrite(labelc+' Email: '+normc+mn(privpost,5)+' ');
            cwrite(labelc+' DL: '+normc+mln(cstr(downloads)+'/'+cstr(dk)+'k',12)+'    ');
            cwrite(labelc+' Newusers: '+normc+mn(newusers,3));

          cwriteat(1,2,labelc+' Stats   '+normc+'³ ');
            cwrite(labelc+' Posts: '+normc+mn(pubpost,5)+' ');
            cwrite('              ');
            cwrite(labelc+' UL: '+normc+mln(cstr(uploads)+'/'+cstr(uk)+'k',12)+'    ');
            cwrite(labelc+' Activity: '+normc+mln(cstr(active)+' min',8));
        end;
    end;

  textbackground(0); inuserwindow; gotoxy(sx,sy); textattr:=sz;
  tleft; cursoron(TRUE);
end;

procedure gotopx(i:integer; dy:integer);
var y:integer;
begin
  if (systat^.windowontop) then y:=2 else y:=linemode;
  gotoxy(i,y+dy);
end;

procedure tleft;
var s:string[16];
    lng:longint;
    zz:integer;
    sx,sy,sz:byte;
    normc,labelc,flashc:string[4];
begin
  if ((cwindowon) and (useron) and (commandlinecount<=0) and (curwindow in [1,4])) then
  begin

    cursoron(FALSE); sx:=wherex; sy:=wherey; sz:=textattr;
    window(1,1,80,linemode); gotopx(74,0);
    normc:=xlatecolor(systat^.wind_normalc);
    labelc:=xlatecolor(systat^.wind_labelc);
    flashc:=xlatecolor(systat^.wind_flashc);
    textattr:=systat^.wind_normalc; clreol;

    if (hangup)               then cwrite(flashc+'ÄDROPÄ') else
    if (doneafternext)        then cwrite(flashc+'ÄDONEÄ') else
    if (beepend)              then cwrite(flashc+'ÄBEEP-') else
    if (trapping)             then cwrite(flashc+'ÄTRAPÄ') else
    if (alert in thisuser.ac) then cwrite(flashc+'ÄALRTÄ') else
    if (chatr<>'')            then cwrite(flashc+'ÄCHATÄ');

    gotopx(68,-1);
    cwrite(labelc+' Time: '+normc);
    cwrite(mn(trunc(nsl/60),4));

    inuserwindow;
    gotoxy(sx,sy); textattr:=sz; cursoron(TRUE);
  end;

  if ((nsl<0) and (choptime<>0.0)) then
  begin
    sysoplog('Logged user off in preparation for system event');
    spstr(413); { shutting down for system event }
    hangup:=TRUE;
  end;

  if ((not ch) and (nsl<0) and (useron) and (choptime=0.0)) then
  begin
    spstr(630); { time expired }
    if (thisuser.timebank>0) then
    begin
      spstr(631); { you have xx minutes in time bank }
      dyny:=TRUE;
      if pynq(getstr(632)) then { withdraw? }
      begin
        spstr(633); { withdraw how many }
        inu(zz); lng:=zz;
        if (lng>0) then begin
          if lng>thisuser.timebank then lng:=thisuser.timebank;
          dec(thisuser.timebankadd,lng);
          if (thisuser.timebankadd<0) then thisuser.timebankadd:=0;
          dec(thisuser.timebank,lng);
          inc(thisuser.tltoday,lng);
          spstr(634); { time bank stats }
          sysoplog('Time expired, withdrew '+cstrl(lng)+' minutes from time bank');
        end;
      end else
        spstr(635); { hanging up }
    end;
    if (nsl<0) then hangup:=TRUE;
  end;
  checkhangup;
  sde;
end;

procedure gp(i,j:integer);
var x:integer;
begin
  case j of
    0:gotoxy(58,8);
    1:gotoxy(20,7); 2:gotoxy(20,8); 3:gotoxy(20,9);
    4:gotoxy(20,10); 5:gotoxy(20,11); 6:gotoxy(36,7); 7:gotoxy(36,8);
  end;
  if (j in [1..3]) then x:=5 else if (j in [4..5]) then x:=6 else x:=3;
  if (i=2) then inc(x);
  if (i>0) then gotoxy(wherex+x,wherey);
end;

procedure changeuserdatawindow;
var wind:windowrec;
    s:string[39];
    oo,i,oldsl,{realsl,realdsl,}savsl,savdsl:integer;
    c:char;
    sx,sy,ta:byte;
    done,done1:boolean;

  procedure shd(i:integer; b:boolean);
  var j:integer;
      c:char;
  begin
    gp(0,i);
    if (b) then tc(14) else tc(9);
    case i of
      1:write('SL  :'); 2:write('DSL :'); 3:write('FP  :');
      4:write('SNote:'); 5:write('UNote:'); 6:write('AR:'); 7:write('AC:');
    end;
    if (b) then begin tc(0); textbackground(7); end else tc(14);
    write(' ');
    with thisuser do
      case i of
        0:if (b) then write('ÄDoneÄ')
          else begin
            tc(9); write('Ä');
            tc(11); write('Done');
            tc(9); write('Ä');
          end;
        1:write(mln(cstr(sl),3));
        2:write(mln(cstr(dsl),3));
        3:write(mln(cstrl(filepoints),5));
        4:write(mln(note,38));
        5:write(mln(usernote,25));
        6:for c:='A' to 'Z' do begin
            if (c in ar) then tc(4)
              else if (b) then tc(0) else tc(7);
            write(c);
          end;
        7:cpr($70,$07,thisuser);
      end;
    write(' ');
    textbackground(0);
    cursoron(i in [1..5]);

    if (b) then begin
      gotoxy(26,13); tc(14);
      for j:=1 to 41 do write(' ');
      gotoxy(26,13);
      case i of
        0:write('Done -  exit back to BBS');
        1:write('Security Level (0..255)');
        2:write('Download Security Level (0..255)');
        3:write('File Points');
        4:write('Special SysOp note for this user');
        5:write('Special User note for this user');
        6:write('Special access flags ("!" to toggle all)');
        7:write('Restrictions & special ("!" to clear)');
      end;
    end;
  end;

  procedure ddwind;
  var i:integer;
      c:char;
  begin
    cursoron(FALSE);
    tc(9);
    box(1,18,6,68,14); window(19,7,67,13); clrscr; window(1,1,80,linemode);
    box(1,18,6,68,12); window(1,1,80,linemode);
    gotoxy(20,13); tc(9); write('Desc:');

    for i:=0 to 7 do shd(i,FALSE);

    shd(oo,TRUE);
  end;

  procedure ar_tog(c:char);
  begin
    if (c in thisuser.ar) then exclude(thisuser.ar,c)
      else include(thisuser.ar,c);
  end;

begin
  if (usernum < 1) then exit;

  saveuf;

  infield_out_fgrd:=0;
  infield_out_bkgd:=7;
  infield_inp_fgrd:=0;
  infield_inp_bkgd:=7;
  infield_arrow_exit:=TRUE;
  infield_arrow_exited:=FALSE;

  sx:=wherex; sy:=wherey; ta:=textattr;
  savescreen(wind,18,6,68,15);
  oo:=1;

  ddwind;
  done:=FALSE;
  repeat
    infield_arrow_exited:=FALSE;
    case oo of
      0:begin
          done1:=FALSE;
          shd(oo,TRUE);
          repeat
            c:=readkey;
            case upcase(c) of
              ^M:begin done:=TRUE; done1:=TRUE; end;
              #0:begin
                   c:=readkey;
                   case ord(c) of
                     ARROW_DOWN,ARROW_UP:
                       begin
                         infield_arrow_exited:=TRUE;
                         infield_last_arrow:=ord(c);
                         done1:=TRUE;
                       end;
                   end;
                 end;
            end;
          until (done1);
        end;
      1:begin
          s:=cstr(thisuser.sl); infield1(26,7,s,3);
          if (value(s)<>thisuser.sl) then begin
            realsl:=value(s);
            thisuser.sl:=value(s);
            inc(thisuser.tltoday,
                systat^.timeallow[thisuser.sl]-systat^.timeallow[realsl]);
          end;
        end;
      2:begin
          s:=cstr(thisuser.dsl); infield1(26,8,s,3);
          if (value(s)<>thisuser.dsl) then begin
            realdsl:=value(s);
            thisuser.dsl:=value(s);
          end;
        end;
      3:begin
          s:=cstr(thisuser.filepoints); infield1(26,9,s,5);
          thisuser.filepoints:=value(s);
        end;
      4:begin
          s:=thisuser.note; infield1(27,10,s,39);
          thisuser.note:=s;
        end;
      5:begin
          s:=thisuser.usernote; infield1(27,11,s,25);
          thisuser.usernote:=s;
        end;
      6:begin
          done1:=FALSE;
          repeat
            c:=upcase(readkey);
            case c of
              #13:done1:=TRUE;
              #0:begin
                   c:=readkey;
                   case ord(c) of
                     ARROW_DOWN,ARROW_UP:
                       begin
                         infield_arrow_exited:=TRUE;
                         infield_last_arrow:=ord(c);
                         done1:=TRUE;
                       end;
                   end;
                 end;
              '!':begin
                    for c:='A' to 'Z' do ar_tog(c);
                    shd(oo,TRUE);
                  end;
              'A'..'Z':begin ar_tog(c); shd(oo,TRUE); end;
            end;
          until (done1);
        end;
      7:begin
          s:='LCVFA*PEKM1234';
          done1:=FALSE;
          repeat
            c:=upcase(readkey);
            if (c=#13) then done1:=TRUE
            else
            if (c=#0) then begin
              c:=readkey;
              case ord(c) of
                ARROW_DOWN,ARROW_UP:
                  begin
                    infield_arrow_exited:=TRUE;
                    infield_last_arrow:=ord(c);
                    done1:=TRUE;
                  end;
              end;
            end
            else
            if (pos(c,s)<>0) then begin
              acch(c,thisuser);
              shd(oo,TRUE);
            end
            else begin
              if (c='!') then
                for i:=1 to length(s) do setacch(s[i],FALSE,thisuser);
              shd(oo,TRUE);
            end;
          until (done1);
        end;
    end;
    if (not infield_arrow_exited) then begin
      infield_arrow_exited:=TRUE;
      infield_last_arrow:=ARROW_DOWN;
    end;
    if (infield_arrow_exited) then
      case infield_last_arrow of
        ARROW_DOWN,ARROW_UP:begin
          shd(oo,FALSE);
          if (infield_last_arrow=ARROW_DOWN) then begin
            inc(oo);
            if (oo>7) then oo:=0;
          end else begin
            dec(oo);
            if (oo<0) then oo:=7;
          end;
          shd(oo,TRUE);
        end;
      end;
  until (done);

  removewindow(wind); topscr;
  gotoxy(sx,sy); textattr:=ta;
  cursoron(TRUE);
  if (systat^.compressfilebases) or (systat^.compressmsgbases) then newcomptables;

  saveuf;
end;

procedure readinmacros;
var macrf:file of macrorec;
    i:integer;
begin
  fillchar(macros^,sizeof(macros^),#0);
  for i:=1 to 4 do macros^.macro[i]:='';
  if (thisuser.mpointer<>-1) then begin
    assign(macrf,systat^.datapath+'MACROS.DAT');
    setfileaccess(readonly,denynone);
    reset(macrf);
    if (filesize(macrf)>thisuser.mpointer) then
    begin
      seek(macrf,thisuser.mpointer);
      read(macrf,macros^);
    end else
      thisuser.mpointer:=-1;
    close(macrf);
  end;
end;

procedure saveuf;
var savsl,savdsl:integer;
begin
  if ((realsl<>-1) and (realdsl<>-1)) then
  begin
    savsl:=thisuser.sl; savdsl:=thisuser.dsl;
    thisuser.sl:=realsl; thisuser.dsl:=realdsl;
  end;

  setfileaccess(readwrite,denynone);
  reset(uf);
  seek(uf,usernum);
  write(uf,thisuser);
  close(uf);

  if ((realsl<>-1) and (realdsl<>-1)) then
  begin
    thisuser.sl:=savsl; thisuser.dsl:=savdsl;
  end;
end;

procedure savenode;
begin
  setfileaccess(readwrite,denynone);
  reset(nodef);
  seek(nodef,nodenum-1);
  write(nodef,thisnode);
  close(nodef);
end;

end.
