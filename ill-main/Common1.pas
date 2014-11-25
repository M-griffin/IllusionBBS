(*****************************************************************************)
(* Illusion BBS - Common functions and procedures [1/3]                      *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit common1;

interface

uses
  crt, dos, myio, misc3, foscom2;

function  checkpw:boolean;
procedure newcomptables;
function  realmsgidx(alias:word):integer;
procedure cline(var s:string; dd:string);
procedure pausescr;
procedure wait(b:boolean);
procedure inittrapfile;
procedure local_input1(var i:string; ml:integer; tf:boolean);
procedure sysopshell(takeuser:boolean);
procedure globat(i:integer);
procedure exiterrorlevel;
procedure showsysfunc;
procedure readinzscan;
procedure savezscanr;
procedure redrawforansi;
procedure setcondensedlines;
procedure set25lines;
function  getrumor:string;
procedure rsm(showit:boolean);

implementation

uses common, common2, common3;

var rclrs,fadeit:boolean;

function checkpw:boolean;
var s:string[20];
begin
  checkpw:=TRUE;
  sprompt('|wSysOp Password : |C');

  echo:=FALSE;
  input(s,20);
  echo:=TRUE;

  if (s<>systat^.sysoppw) then
  begin
    checkpw:=FALSE;
    if (incom) and (s<>'') then sysoplog('*** |RWrong SysOp Password = '+s+' |w***');
  end;
end;

procedure newcomptables;
var tempboard:boardrec;
    savuboard:ulrec;
    savreaduboard,i,j:integer;
    ulfo,done:boolean;
begin
  for i:=0 to 1 do for j:=0 to maxuboards do ccuboards[i][j]:=j;

  if (systat^.compressfilebases) then
  begin
    savuboard:=memuboard;
    savreaduboard:=readuboard;

    ulfo:=(filerec(ulf).mode<>fmclosed);
    if (not ulfo) then begin
      SetFileAccess(ReadOnly,DenyNone);
      reset(ulf);
    end;

    seek(ulf,0);
    i:=0; j:=0; done:=FALSE;
    while ((not done) and (i<=maxuboards)) do
    begin
      {$I-} read(ulf,memuboard); {$I+}
      done:=(ioresult<>0);

      if (not done) then
        if (i>maxulb) then
        begin
          ccuboards[0][i]:=maxuboards+1;
          ccuboards[1][i]:=maxuboards+1;
        end else
          if (aacs(memuboard.acs)) then
          begin
            ccuboards[1][i]:=j; ccuboards[0][j]:=i;
            inc(j);
          end;
      inc(i);
    end;
    if (maxulb<maxuboards) then begin
      ccuboards[1][maxulb+1]:=j;
      ccuboards[0][j]:=maxulb+1;
    end;
  end;

  { --- MESSAGE COMPRESSION TABLES --- }

  SetFileAccess(ReadOnly,DenyNone);
  reset(bf);

  i:=0; j:=0;

  SetFileAccess(ReadWrite,DenyNone);
  rewrite(compf);
  seek(bf,0);

  while not eof(bf) do
  begin
    read(bf,tempboard);
    compmsg.real:=i;
    if (aacs(tempboard.acs)) then
    begin
      compmsg.alias:=j;
      inc(j);
    end else
      compmsg.alias:=-1;
    write(compf,compmsg);
    inc(i);
  end;

  { --- end --- }

  close(bf);
  if (not ulfo) then close(ulf);
  close(compf);

  memuboard:=savuboard;
  readuboard:=savreaduboard;
end;

function realmsgidx(alias:word):integer;
begin
  if (alias>=0) and (alias<=numboards) then
  begin
    reset(compf);
    seek(compf,alias);
    while (not eof(compf)) and (compmsg.alias<>alias) do read(compf,compmsg);
    close(compf);
    if (compmsg.alias=alias) then
      realmsgidx:=compmsg.real
    else
      realmsgidx:=-1;
  end else
    realmsgidx:=-1;
end;

procedure cline(var s:string; dd:string);
var i,u:integer;
    sx,sy,sz:byte;
    b,savwindowon:boolean;
begin
  sx:=wherex; sy:=wherey; sz:=textattr;
  savwindowon:=cwindowon;

  if (not cwindowon) then begin
    cwindowon:=TRUE;
    schangewindow(TRUE,1);
  end;
  commandline(' ');
  window(1,1,80,linemode);

  if (systat^.windowontop) then
    gotoxy(2,2)
  else
    gotoxy(2,linemode-1);
  textattr:=120; write(dd+' ');
  local_input1(s,(78-wherex),TRUE);

  inuserwindow;
  gotoxy(sx,sy); textattr:=sz;
  if (not savwindowon) then sclearwindow;
end;

procedure pausescr;
var ddt,dt1,dt2:datetimerec;
    i,x:integer;
    s:string[3];
    c:char;
    bb:byte;
begin
  nosound;
  bb:=curco;
  x:=lenn(getstr(004)); sprompt(getstr(004)); lil:=0;
  if (systat^.specialfx and 1=1) then getkeyspin:=TRUE;

  getkey(c);
  getkeyspin:=FALSE;

  if ((okansi) and (not hangup)) then begin
    s:=cstr(x);
    if (outcom) then begin
      if (okavatar) then pr1(^Y^H+chr(x)+^Y+' '+chr(x)+^Y^H+chr(x))
      else begin
        pr1(#27+'['+s+'D');
        for i:=1 to x do pr1(' ');
        pr1(#27+'['+s+'D');
      end;
    end;
    if (wantout) then begin
      for i:=1 to x do write(^H);
      for i:=1 to x do write(' ');
      for i:=1 to x do write(^H);
    end;
  end else begin
    for i:=1 to x do outkey(^H);
    for i:=1 to x do outkey(' ');
    for i:=1 to x do outkey(^H);
  end;
  if (trapping) then begin
    for i:=1 to x do write(trapfile,^H);
    for i:=1 to x do write(trapfile,' ');
    for i:=1 to x do write(trapfile,^H);
  end;
  if (not hangup) then setc(bb);
end;

procedure wait(b:boolean);
const lastc:byte=0;
var c,len:integer;
begin
  if (b) then begin
    lastc:=curco;
    sprompt(getstr(001))
  end else begin
    len:=lenn(getstr(001));
    for c:=1 to len do prompt(^H);
    for c:=1 to len do prompt(' ');
    for c:=1 to len do prompt(^H);
    setc(lastc);
  end;
end;

procedure inittrapfile;
begin
  if (systat^.globaltrap) or (thisuser.trapactivity) then trapping:=TRUE
    else trapping:=FALSE;
  if (trapping) then begin
    if (thisuser.trapseperate) then
      assign(trapfile,systat^.trappath+'TRAP'+cstr(usernum)+'.'+cstr(nodenum))
    else
      assign(trapfile,systat^.trappath+'TRAP.'+cstr(nodenum));
    {$I-} append(trapfile); {$I+}
    if (ioresult<>0) then begin
      rewrite(trapfile);
      writeln(trapfile);
    end;
    writeln(trapfile,'** Illusion User Trap - '+nam+' on '+date+' at '+time+' *****');
  end;
end;

procedure local_input1(var i:string; ml:integer; tf:boolean);
var r:real;
    cp:integer;
    cc:char;
begin
  cp:=1;
  repeat
    cc:=readkey;
    if (not tf) then cc:=upcase(cc);
    if (cc in [#32..#255]) then
      if (cp<=ml) then begin
        i[cp]:=cc;
        inc(cp);
        write(cc);
      end
      else
    else
      case cc of
        ^H:if (cp>1) then begin
            cc:=^H;
            write(^H' '^H);
            dec(cp);
          end;
    ^U,^X:while (cp<>1) do begin
            dec(cp);
            write(^H' '^H);
          end;
      end;
  until (cc in [^M,^N]);
  i[0]:=chr(cp-1);
  if (wherey<=hi(windmax)-hi(windmin)) then writeln;
end;

procedure sysopshell(takeuser:boolean);
var wind:windowrec;
    opath:string;
    t:real;
    sx,sy,ret:integer;
    bb:byte;

  procedure dosc;
  var s:string;
      i:integer;
  begin
    s:=^M^J+#27+'[0m';
    for i:=1 to length(s) do dosansi(s[i]);
  end;

begin
  bb:=curco;
  getdir(0,opath);
  t:=timer;
  if (useron) and (incom) then begin
    nl; nl;
    spstr(002);
  end;
  sx:=wherex; sy:=wherey;
  setwindow(wind,1,1,80,linemode,7,0,0);
  clrscr;
  tc(11); writeln('Type EXIT to return to Illusion.');
  dosc;
  dosansion:=FALSE;
  if (not takeuser) then shelldos(FALSE,'',ret)
    else shelldos(FALSE,'remote.bat',ret);
  getdatetime(tim);
  if (useron) and (not localioonly) then com_flush_rx;
  chdir(opath);
  clrscr;
  removewindow(wind);
  gotoxy(sx,sy);
  if (useron) then begin
    freetime:=freetime+timer-t;
    topscr;
    sdc;
    if (incom) then begin
      nl;
      spstr(003);  nl;
    end;
  end;
  setc(bb);
end;

procedure globat(i:integer);
var wind:windowrec;
    s:string;
    t:real;
    xx,yy,z,ret:integer;
begin
  xx:=wherex; yy:=wherey; z:=textattr;
  getdir(0,s);
  chdir(start_dir);
  savescreen(wind,1,1,80,linemode);
  t:=timer;
  shelldos(FALSE,'globat'+chr(i+48),ret);
  getdatetime(tim);
  com_flush_rx;
  freetime:=freetime+timer-t;
  removewindow(wind);
  chdir(s);
  if (useron) then topscr;
  gotoxy(xx,yy); textattr:=z;
end;

procedure exiterrorlevel;
begin
  runerror(0);
end;

procedure showsysfunc;
{$I FUNCIMG.PAS}
var swind:windowrec;
    xx,yy,z:integer;
    c:char;
    screen:^screentype;
begin
  savescreen(swind,1,1,80,linemode);
  xx:=wherex; yy:=wherey; z:=textattr;
  checkvidseg;
  screen:=ptr(vidseg,0);
  uncrunch(funcimg,screen^[0],funcimg_length);
  cursoron(FALSE);
  c:=readkey;
  while keypressed do c:=readkey;
  removewindow(swind);
  if (useron) then topscr;
  gotoxy(xx,yy); textattr:=z;
  cursoron(TRUE);
end;

procedure readinzscan;
var zscanf:file of zscanrec;
    i,j:integer;
begin
  assign(zscanf,systat^.datapath+'NEWSCAN.DAT');
  setfileaccess(readwrite,denynone);
  reset(zscanf);
  if (usernum<filesize(zscanf)) then
  begin
    seek(zscanf,usernum);
    read(zscanf,zscanr);
    close(zscanf);
    exit;
  end;
  with zscanr do
  begin
    fzscan:=[];
    for i:=0 to maxuboards do include(fzscan,i);
  end;
  seek(zscanf,filesize(zscanf));
  repeat
    write(zscanf,zscanr)
  until (filesize(zscanf)>=usernum+1);
  close(zscanf);
end;

procedure savezscanr;
var zscanf:file of zscanrec;
begin
  assign(zscanf,systat^.datapath+'NEWSCAN.DAT');
  setfileaccess(readwrite,denynone);
  reset(zscanf);
  if (usernum<filesize(zscanf)) then
  begin
    seek(zscanf,usernum);
    write(zscanf,zscanr);
    close(zscanf);
    exit;
  end;
  close(zscanf);
end;

procedure redrawforansi;
begin
  if (dosansion) then dosansion:=FALSE;
  textattr:=7; curco:=7;
  if ((outcom) and (okansi)) then begin
    if (okavatar) then pr1(^V+^A+#7) else pr1(#27+'[0m');
  end;
end;

procedure setcondensedlines;

  function egavgasystem:boolean;
  var regs:registers;
  begin
    with regs do begin
      ax:=$1c00;
      cx:=7;
      intr($10,regs);
      if al=$1c then begin  {vga}
        egavgasystem:=true;
        exit;
      end;
      ax:=$1200;
      bl:=$32;
      intr($10,regs);
      if al=$12 then begin {mcga}
        egavgasystem:=true;
        exit;
      end;
      ah:=$12;
      bl:=$10;
      cx:=$ffff;
      intr($10,regs);
      egavgasystem:=(cx<>$ffff);  {ega}
    end;
  end;

begin
  if egavgasystem then begin
    textmode(lo(lastmode)+font8x8);
    linemode := succ(hi(windmax));
    setcommonline(linemode);
  end;
end;

procedure set25lines;
begin
  textmode(lo(lastmode));
  linemode := succ(hi(windmax));
  setcommonline(linemode);
end;

function getrumor:string;
var rumorr:rumorrec;
    rumorf:file of rumorrec;
    whichone:word;
begin
  assign(rumorf,systat^.datapath+'RUMOR.DAT');
  setfileaccess(readonly,denynone);
  reset(rumorf);
  if filesize(rumorf)=0 then
  begin
    getrumor:='No rumors';
    close(rumorf);
  end else
  begin
    whichone:=(random(filesize(rumorf)));
    seek(rumorf,whichone);
    read(rumorf,rumorr);
    getrumor:=rumorr;
    close(rumorf);
  end;
end;

procedure rsm(showit:boolean);
var x:smr;
    i:word;
begin
  setfileaccess(readwrite,denynone);
  reset(smf);
  i:=0;
  cl(ord('w'));
  while (i<filesize(smf)) and (not hangup) do
  begin
    if (i<filesize(smf)) then
    begin
      seek(smf,i);
      read(smf,x);
    end;
    while (i<filesize(smf)-1) and (x.destin<>usernum) do
    begin
      inc(i);
      seek(smf,i);
      read(smf,x);
    end;
    if (x.destin=usernum) and (i<filesize(smf)) then
    begin
      if showit then sprint(x.msg);
      seek(smf,i);
      x.destin:=-1;
      write(smf,x);
    end;
    inc(i);
  end;
  close(smf);
  cl(ord('w'));
end;

end.
