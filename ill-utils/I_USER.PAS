{$A+,B-,D-,E-,F+,G+,I+,L-,N-,O-,R-,S-,V-,X+}

program user_utils;

uses crt,dos;

{$I ..\main\rec25.pas}

var systat:systatrec;
    systatf:file of systatrec;
    userf:file of userrec;
    user:userrec;
    s:string[20];

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

function tch(s:string):string;
begin
  if (length(s)>2) then
    s:=copy(s,length(s)-1,2)
  else
    if (length(s)=1) then s:='0'+s;
  tch:=s;
end;

function date:string;
var y,m,d:string[3];
    yy,mm,dd,dow:word;
begin
  getdate(yy,mm,dd,dow);
  str(yy-1900,y); str(mm,m); str(dd,d);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
end;

procedure reindex;
type un=array[1..1250] of smalrec;
var sf:file of smalrec;
    i,j,k:integer;
    unames:^un;

  procedure switch(var a,b:smalrec);
  var c:smalrec;
  begin
    c:=a; a:=b; b:=c;
  end;

begin
  writeln('Rebuild user database index...');
  writeln;

  assign(sf,systat.datapath+'USERS.IDX');

  j:=0;
  new(unames);

  for i:=1 to filesize(userf)-1 do
  begin
    seek(userf,i);
    read(userf,user);
    gotoxy(1,wherey);
    write('Reading users...');
    if (not user.deleted) then
    begin
      inc(j);
      unames^[j].name:=user.name;
      unames^[j].number:=i;
    end;
  end;

  writeln;
  writeln('Sorting users...');
  for i:=2 to j do
    for k:=j downto i do
      if unames^[k-1].name>unames^[k].name then switch(unames^[k],unames^[k-1]);

  writeln('Writing users...');
  rewrite(sf);
  for i:=0 to j do write(sf,unames^[i]);
  close(sf);
  dispose(unames);

  writeln;
  writeln('Index rebuilt with '+cstr(j)+' entries.');
end;

procedure onetime;
var i,j:integer;
    b:boolean;

  function leapyear(yr:integer):boolean;
  begin
    leapyear:=(yr mod 4=0) and ((yr mod 100<>0) or (yr mod 400=0));
  end;

  function days(mo,yr:integer):integer;
  var d:integer;
  begin
    d:=value(copy('312831303130313130313031',1+(mo-1)*2,2));
    if ((mo=2) and (leapyear(yr))) then inc(d);
    days:=d;
  end;

  function daycount(mo,yr:integer):integer;
  var m,t:integer;
  begin
    t:=0;
    for m:=1 to (mo-1) do t:=t+days(m,yr);
    daycount:=t;
  end;

  function daynum(dt:string):integer;
  var d,m,y,t,c:integer;
  begin
    t:=0;
    m:=value(copy(dt,1,2));
    d:=value(copy(dt,4,2));
    y:=value(copy(dt,7,2))+1900;
    for c:=1985 to y-1 do
      if (leapyear(c)) then inc(t,366) else inc(t,365);
    t:=t+daycount(m,y)+(d-1);
    daynum:=t;
    if y<1985 then daynum:=0;
  end;

begin
  writeln('Delete users who have only called once...');
  writeln;

  j:=0;
  for i:=2 to ((filesize(userf)-1)) do
  begin
    b:=false;
    seek(userf,i);
    read(userf,user);
    gotoxy(1,wherey);
    write('Reading user #'+cstr(i)+'...');

    if ((user.firston=user.laston) and
        (daynum(date)>daynum(user.firston)+7) and
        (not user.deleted)) then
    begin
      user.deleted:=TRUE;
      inc(j);
      seek(userf,i); write(userf,user);
      gotoxy(1,wherey);
      write('Deleted '+user.name+' #'+cstr(i)+'.');
      clreol;
      writeln;
      b:=true;
    end;
  end;

  if (not b) then writeln;
  writeln;
  writeln(cstr(j)+' user(s) deleted.');
end;

procedure zerouser;
var i,j,k:integer;
    b:boolean;
begin
  writeln('Purge deleted user records...');
  writeln;

  j:=0;
  for i:=1 to ((filesize(userf)-1)) do
  begin
    b:=false;
    seek(userf,i);
    read(userf,user);
    gotoxy(1,wherey);
    write('Reading user #'+cstr(i)+'...');
    if (user.deleted) then
    begin
      gotoxy(1,wherey);
      write('Purging record #'+cstr(i)+'...');
      clreol;
      writeln;
      fillchar(user,sizeof(user),#0);
      inc(j);
      with user do
      begin
        name:='PURGED USER';
        note:='Deleted with I_USER purger'; deleted:=TRUE;
        lockedfile:='LOCKOUT';
        sex:='M';
        linelen:=25; pagelen:=80; lastmsg:=1; lastfil:=1;
        mpointer:=-1; qwkarc:='ZIP';
      end;
      seek(userf,i);
      write(userf,user);
      b:=true;
    end;
  end;

  if (not b) then writeln;
  writeln;
  writeln(cstr(j)+' record(s) purged.');
end;

procedure nofile(s:string);
begin
  writeln('Cannot find '+s);
  halt;
end;

function allcaps(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do s[i]:=upcase(s[i]);
  allcaps:=s;
end;

function line:string;
var ss:string[79];
begin
  fillchar(ss[1],79,'Ä');
  ss[0]:=chr(79);
  line:=ss;
end;

procedure disphelp;
begin
  writeln('Syntax:  I_USER <function>');
  writeln;
  writeln('Functions:');
  writeln;
  writeln('   Reindex    Rebuild user database index');
  writeln('   Onetime    Delete users who have only called once');
  writeln('   Purge      Purge deleted user records');
  halt;
end;

begin

  textmode(co80);
  textattr:=15; write('I_USER');
  textattr:=8;  write(' - ');
  textattr:=15; writeln('Illusion User Database Utilities version '+ver);
  textattr:=7;  writeln('Copyright 1992-1998, Illusion Development.  All rights reserved.');
  textattr:=8;  writeln(line);
  textattr:=7;  writeln;
  window(1,5,80,24);

  if (paramcount<>1) then disphelp;

  assign(systatf,'ILLUSION.CFG');
  {$I-} reset(systatf); {$I+}
  if (ioresult<>0) then nofile('ILLUSION.CFG');
  read(systatf,systat);
  close(systatf);

  assign(userf,systat.datapath+'USERS.DAT');
  {$I-} reset(userf); {$I+}
  if (ioresult<>0) then nofile('USERS.DAT');

  s:=allcaps(paramstr(1));
  if (s='REINDEX') then reindex else
  if (s='ONETIME') then onetime else
  if (s='PURGE') then zerouser else disphelp;

  close(userf);

end.
