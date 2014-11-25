(*****************************************************************************)
(* Illusion BBS - Logon routines [2/2]                                       *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit logon2;

interface

uses
  Crt,
  Dos,
  NewFile,
  Mail4,
  Miscx,
  Doors,
  Common,
  Execbat;



procedure logon;
procedure logoff;
procedure endday;

implementation

procedure logon;

var i,j,k,rcode,vna:integer;
    c:char;
    didvote,didmail:boolean;
    conff:file of confrrec;

label skip, force;

procedure findchoptime;
var lng,lng2,lng3:longint;

  procedure onlinetime;
  var dt:datetimerec;
      secs:longint;
  begin
    secs:=trunc(nsl);
    dt.day:=secs div 86400; secs:=secs-(dt.day*86400);
    dt.hour:=secs div 3600; secs:=secs-(dt.hour*3600);
    dt.min:=secs div 60; secs:=secs-(dt.min*60);
    dt.sec:=secs;
    spstr(438);
  end;

begin
  if (exteventtime<>0) then
  begin
    lng:=exteventtime;
    if (lng<trunc(nsl/60.0)) then
    begin
      choptime:=(nsl-(lng*60.0))+120.0; onlinetime; exit;
    end;
  end;
  lng:=1; lng2:=trunc(nsl/60);
  if (lng2>180) then lng2:=180;
  while (lng<=lng2) do
  begin
    lng3:=lng*60;
    if (checkevents(lng3)<>-1) then
    begin
      choptime:=(nsl-(lng*60.0))+60.0; onlinetime; exit;
    end;
    inc(lng,2);
  end;
end;

begin
  getdatetime(timeon); mread:=0; extratime:=0.0; freetime:=0.0;
  useron:=TRUE;
  if (not localioonly) then com_flush_rx;
  logon1st; findchoptime;

  if not (thisuser.conference in ['@'..'Z']) then thisuser.conference:='@';
  assign(conff,systat^.datapath+'CONF.DAT');
  setfileaccess(readwrite,denynone);
  reset(conff);
  seek(conff,ord(thisuser.conference)-64);
  read(conff,conference);
  if (not conference.active) then
  begin
    thisuser.conference:='@';
    seek(conff,0);
    read(conff,conference);
  end;
  close(conff);

  if ((exist('logon.bat')) and (systat^.sysbatexec)) then
  begin
    shel1;
    shelldos(FALSE,process_door('logon.bat %F %L %B %G %T %R'),rcode);
    shel2;
    topscr;
  end;

  fastlogon:=(fastlogon) or (rfastlogon in thisuser.ac);
  if (aacs(systat^.fastlogonacs) and (not fastlogon)) then begin
    spstr(808);
    if pynq(getstr(422)) then fastlogon:=TRUE;
  end;
  nl;

  { Log Users IP }
  sysoplog(userip);  

  with thisuser do
  begin
    didmail:=TRUE;
    if (smw in ac) then begin rsm(TRUE); nl; end;
    exclude(ac,smw);
    NewCompTables;  { Not done normally until Main BBS Loop }
    (*sprompt('Scanning for personal email ...');*)
    spstr(809);
    if (MailWaiting) then begin
      nl;
      if pynq(getstr(35)) then ScanForYourMail;
      nl;
    end else
      (*sprint('None found');*)
      spstr(810);
  end;

  thisnode.whereuser:=getstr(468);
  savenode;

  if ((alert in thisuser.ac) and (sysop)) then chatcall:=TRUE;
  savesystat; saveuf; topscr;
end;

procedure logoff;
var ddt,dt:datetimerec;
    i,tt,rcode:integer;
begin
  if ((useron) and (usernum>0)) then
    if (exist('logoff.bat') and (systat^.sysbatexec)) then begin
      shel1;
      shelldos(FALSE,process_door('logoff.bat %F %L %B %G %T %R'),rcode);
      shel2;
    end;

  term_ready(FALSE);

  if ((useron) and (usernum>0)) then begin
    purgedir(modemr^.temppath+'ARCHIVE\');
    purgedir(modemr^.temppath+'UPLOAD\');
    purgedir(modemr^.temppath+'QWK\');

    if (trapping) then begin
      if (hungup) then begin
        writeln(trapfile);
        writeln(trapfile,'NO CARRIER');
      end;
      close(trapfile); trapping:=FALSE;
    end;

    getdatetime(dt); timediff(ddt,timeon,dt); tt:=trunc((dt2r(ddt)+30)/60);

    thisuser.laston:=systat^.lastdate; inc(thisuser.loggedon);

    (* if not logged in, but logged on *)
    if (realsl<>-1) then thisuser.sl:=realsl;
    if (realdsl<>-1) then thisuser.dsl:=realdsl;

    thisuser.illegal:=0; thisuser.ttimeon:=thisuser.ttimeon+tt;
    if (choptime<>0.0) then inc(thisuser.tltoday,trunc(choptime/60.0));
    thisuser.tltoday:=trunc(nsl/60.0);
    thisuser.lastmsg:=board; thisuser.lastfil:=fileboard;

    with thisnode do begin
      username:='';
      unum:=0;
      whereuser:=getstr(472);
    end;
    savenode;

    SetFileAccess(ReadWrite,DenyNone);
    reset(uf);
    if ((usernum>=1) and (usernum<=filesize(uf)-1)) then
      begin seek(uf,usernum); write(uf,thisuser); end;
    close(uf);

    readsystat;
    if (spd<>'KB') then inc(systat^.todayzlog.active,tt);
    inc(systat^.todayzlog.privpost,etoday);
    savesystat;

    for i:=1 to hiubatchv do release(ubatchv[i]); {* release dynamic memory *}
    window(1,1,80,linemode); tb(0); clrscr;
    if (hungup) then begin sysoplog('Hung up'); sysoplog(userip); end;
    sl1('Logoff -- Msgs read: '+cstr(mread)+'  Time on: '+cstr(tt));
  end;
end;

procedure endday;
var d:integer;
begin
  useron:=FALSE;
  d:=daynum(date);
  if (d<>ldate) then
    if (d-ldate)=1 then
      inc(ldate)
    else begin
      writeln('Date corrupted.');
      thisnode.active:=FALSE;
      thisnode.username:='';
      thisnode.unum:=0;
      thisnode.whereuser:=getstr(473);
      savenode;
      halt(1);
    end;
end;

end.
