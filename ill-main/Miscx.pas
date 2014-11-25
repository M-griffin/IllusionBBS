(*****************************************************************************)
(* Illusion BBS - Miscellaneous routines                                     *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit miscx;

interface

uses
  crt, dos,
  common, common2, doors, misc1;

function  unregd:string;
procedure finduser(var s:astr; var usernum:integer);
procedure dsr(uname:astr);
procedure ssm(dest:integer; s:astr);
procedure isr(uname:astr;usernum:integer);
procedure logon1st;
procedure change_arflags(flagstring:string);
procedure change_credits(s:string);
function usersearch(name:string):boolean;

implementation

uses
  MsgF;

function unregd:string;
const loser:string[12]='¥¬¨µ³±§¦µ¨µ¶';
var n:byte; temp:string[12];
begin
  for n:=1 to 12 do temp[n]:=chr(250-(ord(loser[n])));
  temp[0]:=chr(12);
  unregd:=temp;
end;

procedure finduser(var s:astr; var usernum:integer);
var user:userrec;
    sr:smalrec;
    nn:astr;
    i,ii,t:integer;
begin
  s:=''; usernum:=0;
  input(nn,36);
  if (nn='?') then begin
    exit;
  end;
  while (copy(nn,1,1)=' ') do nn:=copy(nn,2,length(nn)-1);
  while (copy(nn,length(nn),1)=' ') do nn:=copy(nn,1,length(nn)-1);
  while (pos('  ',nn)<>0) do delete(nn,pos('  ',nn),1);
  if ((hangup) or (nn='')) then exit;
  s:=nn;
  usernum:=value(nn);
  if (usernum<>0) then begin
    if (usernum<0) then
      usernum:=-3             (* illegal negative number entry *)
    else begin
      SetFileAccess(ReadOnly,DenyNone);
      reset(uf);
      if (usernum>filesize(uf)-1) then begin
        spstr(322);
        usernum:=0;
      end else begin
        seek(uf,usernum); read(uf,user);
        if (user.deleted) then begin
          spstr(322);
          usernum:=0;
        end;
      end;
      close(uf);
    end;
  end else begin
    if (nn<>'') then begin
      SetFileAccess(ReadOnly,DenyNone);
      reset(sf);
      ii:=0; t:=1;
      while ((t<=filesize(sf)-1) and (ii=0)) do begin
        seek(sf,t); read(sf,sr);
        if (nn=sr.name) then ii:=sr.number;
        inc(t);
      end;
      if (ii<>0) then usernum:=ii;
    end;

   if (nn=getstr(323)) then
     if (systat^.shuttlelog) then usernum:=0 else usernum:=-1;

    if (usernum=0) and (nn<>getstr(323)) then spstr(322);
    close(sf);
  end;
end;

function usersearch(name:string):boolean;
var i:byte;
    found,sfo:boolean;
    sr:smalrec;
begin
  sfo:=(filerec(sf).mode<>fmclosed);
  if (not sfo) then begin
    SetFileAccess(ReadOnly,DenyNone);
    reset(sf);
  end;
  found:=false;
  name:=allcaps(name);
  for i:=1 to filesize(sf)-1 do
  begin
    seek(sf,i); read(sf,sr);
    if (sr.name=name) then found:=true;
  end;
  usersearch:=found;
  if (not sfo) then close(sf);
end;

procedure ssm(dest:integer; s:astr);
var u:userrec;
    x:smr;
begin
  SetFileAccess(ReadWrite,DenyNone);
  reset(smf);

  seek(smf,filesize(smf));
  x.msg:=s; x.destin:=dest;
  write(smf,x);
  close(smf);

  setfileaccess(readwrite,denynone);
  reset(uf);
  if ((dest>=1) and (dest<=filesize(uf))) then
  begin
    seek(uf,dest); read(uf,u);
{   if (not (smw in u.ac)) then begin }
      include(u.ac,smw);
      seek(uf,dest); write(uf,u);
{   end; }
  end;
  close(uf);
  if (dest=usernum) then include(thisuser.ac,smw);
end;

procedure dsr(uname:astr);
var t,ii:integer;
    sr:smalrec;
begin
  setfileaccess(readwrite,denynone);
  reset(sf);

  ii:=0; t:=1;
  while ((t<=filesize(sf)-1) and (ii=0)) do
  begin
    seek(sf,t); read(sf,sr);
    if (sr.name=uname) then ii:=t;
    inc(t);
  end;

  if (ii<>0) then
  begin
    if (ii<>filesize(sf)-1) then
      for t:=ii to filesize(sf)-2 do
      begin
        seek(sf,t+1); read(sf,sr);
        seek(sf,t); write(sf,sr);
      end;
    seek(sf,filesize(sf)-1);
    truncate(sf);
    readsystat;
    dec(systat^.numusers);
    savesystat;
  end else
    sl1('*** Couldn''t delete "'+uname+'"');
  close(sf);
end;

procedure isr(uname:astr; usernum:integer);
var t,i,ii:integer;
    sr:smalrec;
begin
  setfileaccess(readwrite,denynone);
  reset(sf);

  if (filesize(sf)=1) then
  begin
    seek(sf,0);
    read(sf,sr);
    if (uname<sr.name) then
    begin
      seek(sf,2);
      write(sf,sr);
      ii:=1;
    end else
      ii:=2;
  end else
  begin
    ii:=0; t:=1;
    while ((t<=filesize(sf)-1) and (ii=0)) do
    begin
      seek(sf,t);
      read(sf,sr);
      if (uname<sr.name) then ii:=t;
      inc(t);
    end;
    if (ii=0) then
      ii:=filesize(sf)
    else
      for i:=filesize(sf)-1 downto ii do
      begin
        seek(sf,i); read(sf,sr);
        seek(sf,i+1); write(sf,sr);
      end;
  end;
  with sr do
  begin
    name:=uname;
    number:=usernum;
  end;
  seek(sf,ii);
  write(sf,sr);
  readsystat;
  inc(systat^.numusers);
  savesystat;
  close(sf);
end;

procedure logon1st;
var lcf:file of lcallers;
    lc:lcallers;
    fb:file of astr;
    ul:text;
    u:userrec;
    zf:file of zlogrec;
    fil:file of astr;
    modemrf:file of modemrec;
    d1,d2:zlogrec;
    s,s1:astr;
    n,z,c1,num,rcode:integer;
    c:char;
    abort:boolean;
begin
  realsl:=thisuser.sl; realdsl:=thisuser.dsl;
  commandline('Purging files in TEMP directories ...');
  purgedir2(modemr^.temppath+'ARCHIVE\');
  purgedir2(modemr^.temppath+'UPLOAD\');
  purgedir2(modemr^.temppath+'QWK\');
  commandline('');

  if (systat^.lastdate<>date) then
  begin
    spstr(325);
    setfileaccess(readwrite,denynone);
    reset(uf);
    assign(fb,systat^.datapath+'BDAY.DAT');
    rewrite(fb);
    s1:=date;
    write(fb,s1);
    s1:=copy(s1,1,6);
    for n:=1 to filesize(uf)-1 do
    begin
      seek(uf,n); read(uf,u);
      with u do
      begin
        tltoday:=systat^.timeallow[sl];
        timebankadd:=0; ontoday:=0;
      end;
      if (not u.deleted) and (copy(u.bday,1,6)=s1) then
      begin
        s:=substone(getstr(636),'~UN',caps(u.name));
        s:=substone(s,'~U#',cstr(n));
        s:=substone(s,'~UC',u.citystate);
        write(fb,s);
      end;
      seek(uf,n); write(uf,u);
    end;
    close(uf);
    close(fb);

    assign(zf,systat^.datapath+'HISTORY.DAT');
    SetFileAccess(ReadWrite,DenyNone);
    {$I-} reset(zf); {$I+}
    if (ioresult<>0) then begin
      rewrite(zf); close(zf);
      SetFileAccess(ReadWrite,DenyNone); reset(zf);
      d1.date:='';
      for n:=1 to 2 do write(zf,d1);
    end;

    d1:=systat^.todayzlog;
    d1.date:=systat^.lastdate;

    for n:=filesize(zf)-1 downto 0 do begin
      seek(zf,n); read(zf,d2);
      seek(zf,n+1); write(zf,d2);
    end;
    seek(zf,0);
    write(zf,d1);
    close(zf);
    systat^.lastdate:=date;

    assign(lcf,systat^.datapath+'USERLOG.DAT');
    rewrite(lcf);
    close(lcf);

    systat^.todayzlog.date:=date;
    with systat^.todayzlog do begin
      active:=0; calls:=0; newusers:=0; pubpost:=0; privpost:=0;
      criterr:=0; uploads:=0; downloads:=0; uk:=0; dk:=0;
    end;
    savesystat;

    if (exist('daystart.bat')) and (systat^.sysbatexec) then
      shelldos(FALSE,process_door('daystart.bat %F %L %B %G %T %R'),rcode);

    enddayf:=TRUE;
  end;

  readsystat;
  if ((spd<>'KB') and not(didlogfirst)) then begin
    inc(systat^.callernum);
    inc(systat^.todayzlog.calls);
  end;
  savesystat;

  if (thisuser.slogseperate) then begin
    assign(sysopf1,systat^.trappath+'SLOG'+cstr(usernum)+'.'+cstr(nodenum));
    {$I-} append(sysopf1); {$I+}
    if (ioresult<>0) then begin
      rewrite(sysopf1);
      append(sysopf1);
      s:=''; s1:='';
      for n:=1 to 26+length(nam) do begin s:=s+'_'; s1:=s1+' '; end;
      writeln(sysopf1,'');
      writeln(sysopf1,'  '+s);
      writeln(sysopf1,'>>'+s1+'<<');
      writeln(sysopf1,'>> Illusion System Log for '+nam+': <<');
      writeln(sysopf1,'>>'+s+'<<');
      writeln(sysopf1,'');
    end;
    writeln(sysopf1);
    s:='Logon at '+dat+' [';
    if (realspd<>'KB') then s:=s+realspd+' BPS]' else s:=s+'Local]';
    writeln(sysopf1,s);
  end;

  s:=nam+'  (Caller #'+cstr(systat^.callernum)+') / Today '+cstr(thisuser.ontoday);
  if (trapping) then s:=s+' |W[TRAP]';
  sl1(s);

  if ((spd<>'KB') and not(didlogfirst)) then
  begin
    assign(lcf,systat^.datapath+'USERLOG.DAT');
    SetFileAccess(ReadWrite,DenyNone);
    {$I-} reset(lcf); {$I+}
    if (ioresult<>0) then rewrite(lcf);
    with lc do begin
      callernum:=systat^.callernum; name:=caps(thisuser.name);
      number:=usernum; citystate:=thisuser.citystate; node:=cstr(nodenum);
      baud:=realspd; s:=propertime; time:=copy(s,1,5)+copy(s,9,3);
      if wasnewuser then newuser:=true else newuser:=false;
    end;
    didlogfirst:=TRUE;
    seek(lcf,filesize(lcf));
    write(lcf,lc); close(lcf);
  end;
end;

procedure change_credits(s:string);
var i:integer;
begin
  i:=value(copy(s,2,length(s)-1));
  case s[1] of
    '+':inc(thisuser.credit,i);
    '-':dec(thisuser.credit,i);
  end;
  saveuf;
end;

procedure change_arflags(flagstring:string);
type change_flag=array[1..2] of char;
var i,j,k:integer;
    c:change_flag;
    d:char;
begin
  i:=1;
  while (i<(length(flagstring))) do begin
    c[1]:=flagstring[i]; c[2]:=flagstring[i+1];
    d:=upcase(c[2]);
    case c[1] of
      '!': begin
             if (d in thisuser.ar) then exclude(thisuser.ar,d)
               else include(thisuser.ar,d);
           end;
      '+': include(thisuser.ar,d);
      '-': exclude(thisuser.ar,d);
    end;
    inc(i); inc(i);
  end;
  if (useron) then topscr;
end;

end.
