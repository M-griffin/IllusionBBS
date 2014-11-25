(*****************************************************************************)
(* Illusion BBS - Initialization routines                                    *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit initp;

interface

uses
  crt, dos,
  myio, mtask, common;

procedure readp;
procedure initp1;
procedure init;

implementation

var do50:boolean;

procedure readp;
var filv:text;
    d:astr;
    a,count:integer;
    showhelp:boolean;

  function sc(s:astr; i:integer):char;
  begin
    s:=allcaps(s); sc:=s[i];
  end;

  procedure wpar(s:astr);
  begin
    writeln('  þ '+s);
  end;

  function atoi(s:astr):word;
  var i,code:integer;
  begin
    val(s,i,code);
    if code<>0 then i:=0;
    atoi:=i;
  end;

begin
  cursoron(FALSE); writeln;

  exteventtime:=0; answerbaud:=0; quitafterdone:=FALSE;
  localioonly:=FALSE; showhelp:=FALSE; do50:=FALSE;
  filesortonly:=FALSE;

  a:=0;
  nodenum:=1;
  while (a<paramcount) do
  begin
    inc(a);
    if (sc(paramstr(a),1)='-') or (sc(paramstr(a),1)='/') then
      case sc(paramstr(a),2) of
        'B':begin
              answerbaud:=atoi(copy(paramstr(a),3,length(paramstr(a))-2));
              case answerbaud div 100 of
                  3:;  12:;  24:;  48:;  72:;  96:; 120:; 144:;
                168:; 192:; 216:; 240:; 264:; 288:; 312:; 336:;
                384:; 576:; 640:;
                else answerbaud:=0;
              end;
            end;
        'E':if (length(paramstr(a))>=4) then
            begin
              d:=allcaps(paramstr(a));
              case d[3] of
                'E':exiterrors:=value(copy(d,4,length(d)-3));
                'N':exitnormal:=value(copy(d,4,length(d)-3));
              end;
            end;
        'H':door32:=atoi(copy(paramstr(a),3,length(paramstr(a))-2));
        'I':userip:=copy(paramstr(a),3,length(paramstr(a))-2);
        'L':localioonly:=TRUE;
        'N':begin
              nodenum:=atoi(copy(paramstr(a),3,length(paramstr(a))-2));
              if not (nodenum in [1..255]) then nodenum:=0;
            end;
        'P':packbasesonly:=TRUE;
        'S':filesortonly:=TRUE;
        'Q':quitafterdone:=TRUE;
        'X':exteventtime:=atoi(copy(paramstr(a),3,length(paramstr(a))-2));
        '5':do50:=TRUE;
        '?':showhelp:=TRUE;
      end;
  end;

  tc(7);
  if showhelp then
  begin
    writeln('Syntax: ILLUSION [parameters]');
    writeln;
    writeln('/H[#]           - Pass the Socket Handle for Door32 from Telnet Server!');
    writeln('/B[spd]         - Answer phone at [spd]');
    writeln('/E[E|N][elevel] - Set errorlevel (E=error, N=Normal)');
    writeln('/L              - Local I/O only');
    writeln('/N[node]        - Load up node [node]');
    writeln('/P              - Pack message bases only');
    writeln('/Q              - Quit to DOS after user logs off');
    writeln('/S              - Sort file bases only');
    writeln('/X[min]         - Only allow users [min] minutes');
    writeln('/5              - 43/50 line mode');
    writeln('/?              - Show help');
    writeln;
    writeln('(For frontends, use both the -B and -Q parameters.)');
    writeln('Parameters may be proceeded with either a "/" or a "-".');
    cursoron(TRUE);
    halt(exiterrors);
  end;

  writeln('Parsing command line parameters ...');
  if (nodenum=0) then
  begin
    writeln('  þ Illegal Node Number - Defaulting to Node 1');
    nodenum:=1;
  end;
  if (nodenum<>0) then wpar('Loading Node '+cstr(nodenum));
  if (exitnormal<>255) then wpar('Normal exit Errorlevel = '+cstr(exitnormal));
  if (exiterrors<>254) then wpar('Critical Error exit Errorlevel = '+cstr(exiterrors));
  if (localioonly) then wpar('Local I/O only');
  if (answerbaud>0) then wpar('Answer at '+cstr(answerbaud)+' baud');
  if (exteventtime>0) then wpar('External event in '+cstr(exteventtime)+' minute(s)');
  if (quitafterdone) then wpar('Quit after user logoff');
  if (packbasesonly) then wpar('Pack message bases only');
  if (filesortonly) then wpar('Sort file bases only');
  if (do50) then wpar('43/50 line mode');
  allowabort:=TRUE;
end;

procedure initp1;
var filv:text;
    evf:file of eventrec;
    modemrf:file of modemrec;
    valf:file of valrec;
    valr:valrec;
    fp:file;
    v:verbrec;
    One:OnelinerRec;
    OneF:File of OnelinerRec;
    conff:file of confrrec;
    numread,i,j,k:integer;
    errs,npatch:boolean;
    s:astr;
    unames:array[1..1000] of ^smalrec;
    u:userrec;
    c:char; r1:real;

  procedure inmsgs(sh:astr; var s:astr; len:integer);
  begin
    write(sh);
    textattr:=31;
    infielde(s,len);
    textattr:=7;
    writeln;
  end;

  function existdir(fn:astr):boolean;
  var srec:searchrec;
  begin
    while (fn[length(fn)]='\') do fn:=copy(fn,1,length(fn)-1);
    findfirst(fexpand(sqoutsp(fn)),anyfile,srec);
    existdir:=(doserror=0) and (srec.attr and directory=directory);
  end;

  procedure abend(s:astr);
  begin
    writeln('  þ '+s);
    cursoron(TRUE);
    halt(exiterrors);
  end;

  function date2:string;
  var y,m,d:string[3];
      yy,mm,dd,dow:word;
  begin
    getdate(yy,mm,dd,dow);
    str(yy-1900,y); str(mm,m); str(dd,d);
    date2:=tch(m)+'-'+tch(d)+'-'+tch(y);
  end;

  procedure findbadpaths;
  var s,s1,s2:astr;
      i:integer;
  begin
    infield_out_fgrd:=7;
    infield_out_bkgd:=0;
    infield_inp_fgrd:=15;
    infield_inp_bkgd:=1;
     
    with systat^ do
      for i:=1 to 8 do
      begin
        case i of 1:s1:='DATA';   2:s1:='MENU';
                  3:s1:='TEXT';   4:s1:='TRAP/LOG';
                  5:s1:='MULT';   6:s1:='JAM';
                  7:s1:='Hudson'; 8:s1:='Squish';
        end;
        case i of
          1:s:=datapath;
          2:s:=menupath;
          3:s:=textpath;
          4:s:=trappath;
          5:s:=multpath;
          6:s:=jampath;
          7:s:=hudsonpath;
          8:s:=squishpath;
        end;
        if (not existdir(s)) then
        begin
          cursoron(TRUE);
          s2:=s;
          inmsgs('  þ New '+s1+' path: ',s2,50);
          s2:=fexpand(allcaps(sqoutsp(s2)));
          if (s=s2) or (s2='') then
            abend('Illegal pathname')
          else
          begin
            if (s2<>'') then
              if (copy(s2,length(s2),1)<>'\') then s2:=s2+'\';
            if (existdir(s2)) then
            begin
              case i of
                1:datapath:=s2;
                2:menupath:=s2;
                3:textpath:=s2;
                4:trappath:=s2;
                5:multpath:=s2;
                6:jampath:=s2;
                7:hudsonpath:=s2;
                8:squishpath:=s2;
              end;
              savesystat;
            end else
              abend('Path not found');
          end;
          cursoron(FALSE);
        end;
      end;
  end;

  procedure writef(s:string);
  begin
    write('  þ Verifying '+allcaps(s)+' ');
  end;

  procedure writes(b:byte);
  begin
    case b of
      0:writeln(' -- Okay');
      1:writeln(' -- Created');
    end;
  end;

  procedure switch(var a,b:smalrec);
  var c:smalrec;
  begin
    c:=a; a:=b; b:=c;
  end;

begin
  writeln;
  writeln('Initializing ...');

  wantout:=TRUE;
  ldate:=daynum(date);
  ch:=FALSE; lil:=0; thisuser.pagelen:=20; buf:=''; chatcall:=FALSE;
  spd:=''; realspd:=''; ll:=''; chatr:=''; npatch:=FALSE;

  cursoron(FALSE);

  if (exist(start_dir+'\CRITICAL.ERR')) then
  begin
    assign(filv,start_dir+'\CRITICAL.ERR');
    erase(filv);
    writeln('  þ Updating ILLUSION.CFG with critical error report');
    inc(systat^.todayzlog.criterr);
    savesystat;
  end;

  find_systype;
  case systype of
    1:writeln('  þ DESQview multitasking enviroment detected');
    2:writeln('  þ Windows enhanced mode detected');
    3:writeln('  þ OS/2 multitasking operating system detected');
    4:writeln('  þ Windows 95 multitasking operating system detected');
  end;
{ if systype>0 then begin_critical; }

  writeln;
  writeln('Checking path names ...');

  findbadpaths;

  writeln;
  writeln('Checking data files ...');

  new(modemr);

  assign(modemrf,systat^.datapath+'NODE.'+cstr(nodenum));
  writef('NODE.'+cstr(nodenum));
  if (exist(systat^.datapath+'NODE.'+cstr(nodenum))) then
  begin      
    setfileaccess(readonly,denynone);
    reset(modemrf);    
    
    read(modemrf,modemr^);
    close(modemrf);
    writes(0);
  end else
  begin
    fillchar(modemr,sizeof(modemr),#0);
    with modemr^ do
    begin
      temppath:=start_dir+'\TEMP'+cstr(nodenum)+'\';
      doorpath:=start_dir+'\DOOR'+cstr(nodenum)+'\';
      lastdate:=date;
      comport:=1; waitbaud:=14400; handshake:=hactsrts;
      portlock:=true; lockspeed:=38400;
      esccode:='+++'; offhook:='ATM0H1'; hangup:='~ATH0';
      answer:='ATA'; answerdelay:=2;
      init[1]:='ATZ';
      init[2]:='ATE0M0Q0V1W2X4&C1&D2S0=0S95=1';
      nocallinittime:=30;
      codeerror:='ERROR'; codenocarrier:='NO CARRIER';
      codeok:='OK'; codering:='RING';
      for i:=0 to 19 do
      begin
        s:='CONNECT ';
        case i of
           0:s:=s+'300';     1:s:=s+'1200';   2:s:=s+'2400';   3:s:=s+'4800';
           4:s:=s+'7200';    5:s:=s+'9600';   6:s:=s+'12000';  7:s:=s+'14400';
           8:s:=s+'16800';   9:s:=s+'19200'; 10:s:=s+'21600'; 11:s:=s+'24000';
           12:s:=s+'26400'; 13:s:=s+'28800'; 14:s:=s+'31200'; 15:s:=s+'33600';
           16:s:=s+'38400'; 17:s:=s+'57600'; 18:s:=s+'64000'; 19:s:=s+'115200';
        end;
        resultcode[i]:=s;
      end;
    end;
    setfileaccess(readwrite,denyall);
    rewrite(modemrf);
    write(modemrf,modemr^);
    close(modemrf);
    writes(1);
  end;

  assign(nodef,systat^.datapath+'NODES.DAT');
  writef('NODES.DAT');
  fillchar(thisnode,sizeof(thisnode),#0);
  thisnode.whereuser:='New Node (unused)';
  if (exist(systat^.datapath+'NODES.DAT')) then
  begin
    setfileaccess(readwrite,denynone);
    reset(nodef);
    if (filesize(nodef)<nodenum) then
      while (filesize(nodef)<nodenum) do
      begin
        seek(nodef,filesize(nodef));
        write(nodef,thisnode);
      end;
    seek(nodef,nodenum-1);
    read(nodef,thisnode);
    close(nodef);
    if (thisnode.active) then writeln(' -- Resetting node') else writes(0);
  end else
  begin
    setfileaccess(readwrite,denynone);
    rewrite(nodef);
    while (filesize(nodef)<nodenum) do
    begin
      seek(nodef,filesize(nodef));
      write(nodef,thisnode);
    end;
    close(nodef);
    writes(1);
  end;

  assign(fp,'MSGTMP.'+cstr(nodenum));
  SetFileAccess(ReadOnly,DenyAll);
  {$I-} reset(fp); {$I+}
  if (ioresult=0) then begin close(fp); erase(fp); end;

  assign(sysopf,systat^.trappath+date2+'.'+cstr(nodenum));
  writef(date+'.'+cstr(nodenum));
  if (exist(systat^.trappath+date2+'.'+cstr(nodenum))) then
  begin
    append(sysopf);
    writes(0);
  end else
  begin
    rewrite(sysopf);
    writeln(sysopf,'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
    writeln(sysopf,'³  SysOp Log for '+date+'         .  ³');
    writeln(sysopf,'³  Node '+mn(nodenum,3)+'                          ³');
    writeln(sysopf,'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
    writeln(sysopf);
    writes(1);
  end;

  assign(sysopf1,systat^.trappath+'SLOGxxxx.'+cstr(nodenum));

  first_time:=TRUE;

  assign(fstringf,systat^.datapath+'STRINGS.DAT');
  writef('STRINGS.DAT');
  if (exist(systat^.datapath+'STRINGS.DAT')) then
  begin
    setfileaccess(readonly,denynone);
    reset(fstringf,256);
    new(strglobal); new(strbuff);
    blockread(fstringf,strglobal^,10);
    blockread(fstringf,strbuff^,20);
    firstbuff:=10;
    writes(0);
  end else
  begin
    writeln(' -- Not found; recompile language file');
    cursoron(true);
    halt(exiterrors);
  end;

  assign(uf,systat^.datapath+'USERS.DAT');
  writef('USERS.DAT');
  if (exist(systat^.datapath+'USERS.DAT')) then
  begin
    setfileaccess(readonly,denynone);
    reset(uf);
    if (filesize(uf)>1) then
    begin
      seek(uf,1);
      read(uf,thisuser);
    end else
      thisuser.slogseperate:=FALSE;
    writes(0);
  end else
  begin
    fillchar(thisuser,sizeof(thisuser),#0);
    with thisuser do
    begin
      name:='SYSOP'; realname:='System Operator'; pw:='SYSOP';
      ph:='000-000-0000'; bday:='00/00/00'; sex:='M';
      firston:=date; laston:=date;
      street:='1 Illusion Blvd.'; citystate:='Somewhere, Earth';
      zipcode:='00000-0000'; computer:='IBM Compatible';
      occupation:='Sysop'; wherebbs:='A little birdie told me';
      note:='>> Change these stats to your own <<'; usernote:='Sysop!';
      ac:=[onekey,pause,novice,ansi,smw,fnodlratio,fnopostratio,fnofilepts,fnodeletion];
      ar:=[]; for c:='A' to 'Z' do ar:=ar+[c]; conference:='@';
      tltoday:=600; filepoints:=50; linelen:=80; pagelen:=25;
      sl:=255; dsl:=255; lastmsg:=1; lastfil:=0;
      credit:=10000; timebank:=60; mpointer:=-1;
      for i:=1 to 10 do
      begin
        if (i in [1..8]) then flistc[i][1]:=1 else flistc[i][1]:=0;
        case i of
          1:flistc[i][2]:=ord('W');
          2:flistc[i][2]:=ord('B');
          3:flistc[i][2]:=ord('b');
          4:flistc[i][2]:=ord('K');
          5:flistc[i][2]:=ord('w');
          6,
          7:flistc[i][2]:=ord('K');
          8:flistc[i][2]:=ord('w');
          9,
         10:flistc[i][2]:=ord('w');
        end;
      end;
      
      { Initalize to Default Settings 1 ON / 0 OFF}
      
      flistc[1][1] :=  1; { FileName }
      flistc[2][1] :=  1; { FileSize }
      flistc[3][1] :=  0; { FilePoints }
      flistc[4][1] :=  1; { Popularity }
      flistc[5][1] :=  1; { Descriptions }
      flistc[6][1] :=  1; { Uploader }
      flistc[7][1] :=  1; { Date }
      flistc[8][1] :=  1; { Verbose }
      
      qwkarc:='ZIP';
    end;
    setfileaccess(readwrite,denynone);
    rewrite(uf);
    write(uf,thisuser);  { dummy record }
    write(uf,thisuser);  { user #1 }
    writes(1);
  end;

  assign(sf,systat^.datapath+'USERS.IDX');
  writef('USERS.IDX');
  if (exist(systat^.datapath+'USERS.IDX')) then
  begin
    setfileaccess(readonly,denynone);
    reset(sf);
    writes(0);
  end else
  begin
    for i:=1 to (sizeof(unames) div sizeof(smalrec)) do new(unames[i]);
    j:=1;
    for i:=1 to filesize(uf)-1 do
    begin
      seek(uf,i); read(uf,u);
      if (not u.deleted) then
      begin
        unames[j]^.name:=u.name;
        unames[j]^.number:=i;
        inc(j);
      end;
    end;
    dec(j);
    for i:=2 to j do
      for k:=j downto i do
        if unames[k-1]^.name>unames[k]^.name then switch(unames[k]^,unames[k-1]^);
    setfileaccess(readwrite,denyall);
    rewrite(sf);
    for i:=0 to j do write(sf,unames[i]^);
    fillchar(unames[1]^,sizeof(unames[1]^),#0);
    seek(sf,0); write(sf,unames[1]^);
    close(sf);
    setfileaccess(readonly,denynone);
    reset(sf);
    for i:=1 to (sizeof(unames) div sizeof(smalrec)) do dispose(unames[i]);
    writes(1);
  end;

  if (systat^.numusers<>filesize(sf)) then systat^.numusers:=filesize(sf);
  close(sf);
  close(uf);

  assign(verbf,systat^.datapath+'VERBOSE.DAT');
  writef('VERBOSE.DAT');
  if (exist(systat^.datapath+'VERBOSE.DAT')) then
  begin
    setfileaccess(readonly,denynone);
    reset(verbf);
    close(verbf);
    writes(0);
  end else
  begin
    fillchar(v,sizeof(v),#0);
    setfileaccess(readwrite,denynone);
    rewrite(verbf);
    write(verbf,v);
    close(verbf);
    writes(1);
  end;

  assign(xf,systat^.datapath+'PROTOCOL.DAT');
  writef('PROTOCOL.DAT');
  if (exist(systat^.datapath+'PROTOCOL.DAT')) then
  begin
    setfileaccess(readonly,denynone);
    reset(xf);
    close(xf);
    writes(0);
  end else
  begin
    writeln(' -- Not found');
    cursoron(true);
    halt(exiterrors);
  end;

  assign(valf,systat^.datapath+'AUTOVAL.DAT');
  writef('AUTOVAL.DAT');
  if (exist(systat^.datapath+'AUTOVAL.DAT')) then
  begin
    setfileaccess(readonly,denynone);
    reset(valf);
    close(valf);
    writes(0);
  end else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(valf);
    for i:=1 to 26 do
    begin
      fillchar(valr,sizeof(valr),#0);
      case i of
        1:with valr do
          begin
            name:='New User';
            sl:=20; dsl:=20;
            ac:=[rpostan,rvoting];
            fp:=25; credit:=500; unote:='New User';
            actype:=TRUE; artype:=TRUE;
          end;
        2:with valr do
          begin
            name:='Validated User';
            sl:=50; dsl:=50;
            fp:=-1; credit:=-1; unote:='Validated User';
          end;
      end;
      write(valf,valr);
    end;
    close(valf);
    writes(1);
  end;

  assign(evf,systat^.datapath+'EVENTS.DAT');
  writef('EVENTS.DAT');
  if (exist(systat^.datapath+'EVENTS.DAT')) then
  begin
    setfileaccess(readonly,denynone);
    reset(evf);
    numevents:=filesize(evf)-1;
    repeat
      new(events[numevents]);
      read(evf,events[numevents]^);
    until (eof(evf));
    close(evf);
    writes(0);
  end else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(evf);
    new(events[0]);
    fillchar(events[0]^,sizeof(events[0]^),#0);
    with events[0]^ do
    begin
      active:=true; description:='Pack message bases';
      etype:='P'; exectime:=120; busyduring:=TRUE;
      duration:=1; execdays:=127;
    end;
    write(evf,events[0]^);
    new(events[1]);
    fillchar(events[1]^,sizeof(events[1]^),#0);
    with events[1]^ do
    begin
      description:='Nightly events'; busyduring:=TRUE;
      etype:='D'; execdata:='night.bat'; busytime:=1; exectime:=121;
      duration:=1; execdays:=127;
    end;
    write(evf,events[1]^);
    close(evf);
    numevents:=1;
    writes(1);
  end;

  assign(bf,systat^.datapath+'MBOARDS.DAT');
  writef('MBOARDS.DAT');
  if (exist(systat^.datapath+'MBOARDS.DAT')) then
  begin
    setfileaccess(readonly,denynone);
    reset(bf);
    numboards:=filesize(bf)-1;
    seek(bf,numboards-1);
    read(bf,memboard);
    close(bf);
    writes(0);
  end else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(bf);
    fillchar(memboard,sizeof(memboard),#0);
    with memboard do
    begin
      name:='Electronic Mail'; qwkname:='E-Mail';
      msgareaid:='J'+systat^.jampath+'EMAIL'; permindx:=1;
      emailscan:=true; mciacs:='%'; attachacs:='s50';
      maxmsgs:=200; maxdays:=30; anstat:=atno; basestat:=[private];
      text_color:='w'; quote_color:='W'; tear_color:='b'; origin_color:='B';
      scantype:=2; MsgHeaderFile:='MSGHEAD';
    end;
    write(bf,memboard);
    fillchar(memboard,sizeof(memboard),#0);
    with memboard do
    begin
      name:='General Chat'; qwkname:='General Chat';
      msgareaid:='J'+systat^.jampath+'GENERAL'; permindx:=2;
      subopacs:='s200'; mciacs:='%'; attachacs:='s50';
      maxmsgs:=100; maxdays:=30; anstat:=atno; basestat:=[public];
      text_color:='w'; quote_color:='W'; tear_color:='b'; origin_color:='B';
      MsgHeaderFile:='MSGHEAD';
    end;
    write(bf,memboard);
    close(bf);
    numboards:=1;
    writes(1);
  end;

  assign(ulf,systat^.datapath+'FBOARDS.DAT');
  writef('FBOARDS.DAT');
  if (exist(systat^.datapath+'FBOARDS.DAT')) then
  begin
    setfileaccess(readonly,denynone);
    reset(ulf);
    maxulb:=filesize(ulf)-1;
    seek(ulf,maxulb-1);
    read(ulf,memuboard);
    close(ulf);
    writes(0);
  end else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(ulf);
    fillchar(memuboard,sizeof(memuboard),#0);
    with memuboard do
    begin
      name:='Sysop Directory'; filename:='SYSOP';
      dlpath:=start_dir+'\FILES\SYSOP\'; maxfiles:=2000;
      arctype:=1; cmttype:=1;
      acs:='s255'; ulacs:='^'; permindx:=1;
    end;
    write(ulf,memuboard);
    if not (existdir(start_dir+'\FILES')) then mkdir(start_dir+'\FILES');
    if not (existdir(start_dir+'\FILES\SYSOP')) then mkdir(start_dir+'\FILES\SYSOP');
    fillchar(memuboard,sizeof(memuboard),#0);
    with memuboard do
    begin
      name:='Miscellaneous'; filename:='MISC';
      dlpath:=start_dir+'\FILES\MISC\'; maxfiles:=2000;
      arctype:=1; cmttype:=1;
      acs:='s20'; ulacs:=''; permindx:=2;
    end;
    write(ulf,memuboard);
    if not (existdir(start_dir+'\FILES\MISC')) then mkdir(start_dir+'\FILES\MISC');
    maxulb:=1;
    close(ulf);
    writes(1);
  end;

  assign(smf,systat^.datapath+'SHORTMSG.DAT');
  writef('SHORTMSG.DAT');
  if (exist(systat^.datapath+'SHORTMSG.DAT')) then
    writes(0)
  else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(smf);
    close(smf);
    writes(1);
  end;

  assign(fp,systat^.datapath+'VOTING.DAT');
  writef('VOTING.DAT');
  if (exist(systat^.datapath+'VOTING.DAT')) then
    writes(0)
  else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(fp);
    close(fp);
    writes(1);
  end;

  assign(fp,systat^.datapath+'RUMOR.DAT');
  writef('RUMOR.DAT');
  if (exist(systat^.datapath+'RUMOR.DAT')) then
    writes(0)
  else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(fp);
    close(fp);
    writes(1);
  end;

  assign(fp,systat^.datapath+'NUV.DAT');
  writef('NUV.DAT');
  if (exist(systat^.datapath+'NUV.DAT')) then
    writes(0)
  else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(fp);
    close(fp);
    writes(1);
  end;

  assign(fp,systat^.datapath+'MACROS.DAT');
  writef('MACROS.DAT');
  if (exist(systat^.datapath+'MACROS.DAT')) then
    writes(0)
  else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(fp);
    close(fp);
    writes(1);
  end;

  assign(fp,systat^.datapath+'USERLOG.DAT');
  writef('USERLOG.DAT');
  if (exist(systat^.datapath+'USERLOG.DAT')) then
    writes(0)
  else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(fp);
    close(fp);
    writes(1);
  end;

  assign(fp,systat^.datapath+'NEWSCAN.DAT');
  writef('NEWSCAN.DAT');
  if (exist(systat^.datapath+'NEWSCAN.DAT')) then
    writes(0)
  else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(fp);
    close(fp);
    writes(1);
  end;

  assign(fp,systat^.datapath+'WANTLIST.DAT');
  writef('WANTLIST.DAT');
  if (exist(systat^.datapath+'WANTLIST.DAT')) then
    writes(0)
  else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(fp);
    close(fp);
    writes(1);
  end;

  assign(OneF,systat^.datapath+'ONELINER.DAT');
  writef('ONELINER.DAT');
  if (exist(systat^.datapath+'ONELINER.DAT')) then
    writes(0)
  else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(OneF);
    One:='This BBS is running Illusion '+ver;
    Write(OneF,One);
    Close(OneF);
    writes(1);
  end;

  assign(conff,systat^.datapath+'CONF.DAT');
  writef('CONF.DAT');
  if (exist(systat^.datapath+'CONF.DAT')) then
    writes(0)
  else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(conff);
    conference.active:=true;
    conference.name:='Global conference';
    conference.acs:='^';
    write(conff,conference);
    fillchar(conference,sizeof(conference),#0);
    for i:=1 to 26 do write(conff,conference);
    setfileaccess(readwrite,denynone);
    reset(uf);
    for i:=1 to filesize(uf)-1 do
    begin
      seek(uf,i);
      read(uf,thisuser);
      thisuser.conference:='@';
      seek(uf,i);
      write(uf,thisuser);
    end;
    close(uf);
    writes(1);
  end;

  assign(fp,systat^.datapath+'HISTORY.DAT');
  writef('HISTORY.DAT');
  if (exist(systat^.datapath+'HISTORY.DAT')) then
    writes(0)
  else
  begin
    setfileaccess(readwrite,denyall);
    rewrite(fp);
    close(fp);
    writes(1);
  end;

  writeln;
  writeln('Creating temporary directories ...');
  modemr^.temppath:=start_dir+'\TEMP'+cstr(nodenum)+'\';
  if not (existdir(modemr^.temppath)) then mkdir(copy(modemr^.temppath,1,length(modemr^.temppath)-1));
  if not (existdir(modemr^.temppath+'ARCHIVE\')) then mkdir(modemr^.temppath+'ARCHIVE');
  if not (existdir(modemr^.temppath+'UPLOAD\')) then mkdir(modemr^.temppath+'UPLOAD');
  if not (existdir(modemr^.temppath+'QWK\')) then mkdir(modemr^.temppath+'QWK');
  assign(cf,systat^.trappath+'CHAT.'+cstr(nodenum));
  assign(compf,modemr^.temppath+'MSG.IDX');

  numwaves:=0;
  new(macros);
  new(outputbuff);

  thisnode.active:=TRUE;
  thisnode.whereuser:=getstr(472);
  savenode;

  cfo:=false;
  textbackground(0);
  tc(7);
{ if systype>0 then end_critical; }
end;

procedure init;
var rcode:integer;
begin
  
  
  hangup:=FALSE; incom:=FALSE; outcom:=FALSE;
  echo:=TRUE; doneday:=FALSE;
  checkbreak:=FALSE;
  trapping:=FALSE;
  sysopon:=FALSE; inmsgfileopen:=FALSE;
  beepend:=FALSE;
  checksnow:=systat^.cgasnow;
  directvideo:=not systat^.usebios;
{ writeln(4); }

  writeln('readp');

  readp;
  
  writeln('initp1');  
  
  initp1;
  tc(7); if do50 then SetCondensedLines;

  iport;

  {clrscr;}

  if ((exist('BBSSTART.BAT')) and (systat^.sysbatexec)) then shelldos(FALSE,'BBSSTART.BAT',rcode);
end;

end.
