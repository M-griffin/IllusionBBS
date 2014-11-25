(*****************************************************************************)
(* Illusion BBS - File routines  [0/15]                                      *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit Mfile0;

interface

uses
  crt, dos,
  myio, common;

const ulffopen1:boolean=TRUE;   { whether ulff has been opened before }

var dirinfo:searchrec; found:boolean;

function align(fn:astr):astr;
function baddlpath:boolean;
function bslash(b:boolean; s:astr):astr;
function existdir(s:astr):boolean;
procedure ffile(fn:astr);
procedure fileinfo(f:ulfrec; editinfo:boolean; var abort,next:boolean);
procedure fiscan(var pl:integer);
function fit(f1,f2:astr):boolean;
procedure gfn(var fn:astr);
function isgifdesc(d:astr):boolean;
function isgifext(fn:astr):boolean;
function isul(s:astr):boolean;
function iswildcard(s:astr):boolean;
procedure nfile;
procedure nrecno(fn:astr; var pl,rn:integer);
procedure recno(fn:astr; var pl,rn:integer);
function rte:real;
procedure star(s:astr);
function stripname(i:astr):astr;
function tcheck(s:real; i:integer):boolean;
function tchk(s:real; i:real):boolean;

implementation

function align(fn:astr):astr;
var f,e,t:astr; c,c1:integer;
begin
  c:=pos('.',fn);
  if (c=0) then begin
    f:=fn; e:='   ';
  end else begin
    f:=copy(fn,1,c-1); e:=copy(fn,c+1,3);
  end;
  f:=mln(f,8);
  e:=mln(e,3);
  c:=pos('*',f); if (c<>0) then for c1:=c to 8 do f[c1]:='?';
  c:=pos('*',e); if (c<>0) then for c1:=c to 3 do e[c1]:='?';
  c:=pos(' ',f); if (c<>0) then for c1:=c to 8 do f[c1]:=' ';
  c:=pos(' ',e); if (c<>0) then for c1:=c to 3 do e[c1]:=' ';
  align:=f+'.'+e;
end;

function baddlpath:boolean;
var s:string;
begin
  if (badfpath) then begin
    nl;
    sprint('|RFile base #'+cstr(fileboard)+': Unable to perform command.');
    sprint('|YBad DL file path:');
    if (fso) then sprint('"'+memuboard.dlpath+'".');
    sysoplog('|RInvalid DL path (file base #'+cstr(fileboard)+'): "'+
             memuboard.dlpath+'"');
  end;
  baddlpath:=badfpath;
end;

function bslash(b:boolean; s:astr):astr;
begin
  if (b) then begin
    while (copy(s,length(s)-1,2)='\\') do s:=copy(s,1,length(s)-2);
    if (copy(s,length(s),1)<>'\') then s:=s+'\';
  end else
    while (copy(s,length(s),1)='\') do s:=copy(s,1,length(s)-1);
  bslash:=s;
end;

function existdir(s:astr):boolean;
var savedir:astr;
    okd:boolean;
begin
  okd:=TRUE;
  s:=bslash(FALSE,fexpand(s));

  if ((length(s)=2) and (copy(s,2,1)=':')) then begin
    getdir(0,savedir);
    {$I-} chdir(s); {$I+}
    if (ioresult<>0) then okd:=FALSE;
    chdir(savedir);
    exit;
  end;

  okd:=(exist(s));

  if (okd) then begin
    findfirst(s,anyfile,dirinfo);
    if (dirinfo.attr and directory<>directory) or
       (doserror<>0) then okd:=FALSE;
  end;

  existdir:=okd;
end;

procedure fiscan(var pl:integer); { loads in memuboard ... }
var dirinfo:searchrec;
    s:astr;
begin
  s:=memuboard.dlpath; s:=copy(s,1,length(s)-1);
  if ((length(s)=2) and (s[2]=':')) then badfpath:=FALSE
  else begin
    findfirst(s,dos.directory,dirinfo);
    badfpath:=(doserror<>0);
  end;

  if (not ulffopen1) then
  begin
    if (filerec(ulff).mode<>fmclosed) then close(ulff);
  end else
    ulffopen1:=FALSE;
  loaduboard(fileboard);
  if (fbdirdlpath in memuboard.fbstat) then
    assign(ulff,memuboard.dlpath+memuboard.filename+'.DIR')
  else
    assign(ulff,systat^.datapath+memuboard.filename+'.DIR');
  SetFileAccess(ReadWrite,DenyNone);
  {$I-} reset(ulff); {$I+}
  if (ioresult<>0) then
  begin
    rewrite(ulff);
    Close(ulff);
    SetFileAccess(ReadWrite,DenyNone);
    reset(ulff);
  end;
  pl:=filesize(ulff)-1;
  bnp:=FALSE;
end;

procedure ffile(fn:astr);
begin
  findfirst(fn,anyfile,dirinfo);
  found:=(doserror=0);
end;

procedure fileinfo(f:ulfrec; editinfo:boolean; var abort,next:boolean);
var dt:datetimerec;
    s:str2;
    r:real;
    v:verbrec;
    i,j:byte;
    vfo:boolean;
    li:longint;
begin
  with f do begin
    clearwaves;
    addwave('FN',filename,txt);
    addwave('01',description,txt);
    li:=blocks; li:=li*128;
    addwave('FS',cstr(li),txt);
    r:=rte*blocks; r2dt(r,dt);
    addwave('TN',ctim(r),txt);
    addwave('TE',longtim(dt),txt);
    addwave('UN',aonoff(aacs(memuboard.nameacs),caps(stowner),'Unknown'),txt);
    addwave('DU',date,txt);
    addwave('TD',cstr(nacc),txt);
    addwave('FP',cstr(filepoints),txt);
  end;
  v.descr[1]:='';
  if f.vpointer<>-1 then begin
    SetFileAccess(ReadOnly,DenyNone);
    {$I-} reset(verbf); {$I+}
    if ioresult=0 then
    begin
      {$I-} seek(verbf,f.vpointer);
      read(verbf,v); {$I+}
      if ioresult=0 then
        with v do
          for i:=1 to 9 do
            if descr[i]='' then
            begin
              for j:=i to 9 do
                addwave(aonoff(j<9,'0','1')+chr(j+49),'',txt);
              i:=9;
            end else
              addwave(aonoff(i<9,'0','1')+chr(i+49),descr[i],txt);
    end else
      for i:=1 to 9 do
        addwave(aonoff(i<9,'0','1')+chr(i+49),'',txt);
  end else
    for i:=1 to 9 do
      addwave(aonoff(i<9,'0','1')+chr(i+49),'',txt);
  if (editinfo) then spstr(624) else spstr(548);
  clearwaves;
end;

function fit(f1,f2:astr):boolean;
var tf:boolean; c:integer;
begin
  tf:=TRUE;
  for c:=1 to 12 do
    if (f1[c]<>f2[c]) and (f1[c]<>'?') then tf:=FALSE;
  fit:=tf;
end;

procedure gfn(var fn:astr);
begin
  spstr(113);
  spstr(114); input(fn,12);
  if (pos('.',fn)=0) then fn:=fn+'*.*';
  fn:=align(fn);
end;

function isgifdesc(d:astr):boolean;
begin
  isgifdesc:=((copy(d,1,1)='(') and (pos('x',d) in [1..7]) and
              (pos('c)',d)<>0));
end;

function isgifext(fn:astr):boolean;
begin
  fn:=align(stripname(sqoutsp(fn)));
  fn:=allcaps(copy(fn,length(fn)-2,3));
  isgifext:=((fn='GIF') or (fn='GYF'));
end;

function isul(s:astr):boolean;
begin
  isul:=((pos('\',s)<>0) or (pos(':',s)<>0) or (pos('|',s)<>0));
end;

function iswildcard(s:astr):boolean;
begin
  iswildcard:=((pos('*',s)<>0) or (pos('?',s)<>0));
end;

procedure nfile;
begin
  findnext(dirinfo);
  found:=(doserror=0);
end;

procedure nrecno(fn:astr; var pl,rn:integer);
var c:integer;
    f:ulfrec;
begin
  rn:=-1;
  if (lrn<pl) and (lrn>=0) then begin
    c:=lrn+1;
    while (c<=pl) and (rn=-1) do begin
      seek(ulff,c); read(ulff,f);
      if pos('.',f.filename)<>9 then
      begin
        f.filename:=align(f.filename);
        seek(ulff,c); write(ulff,f);
      end;
      if fit(lfn,f.filename) then rn:=c;
      inc(c);
    end;
    lrn:=rn;
  end;
end;

procedure recno(fn:astr; var pl,rn:integer);
var f:ulfrec;
    c:integer;
begin
  fn:=align(fn);
  fiscan(pl);
  rn:=-1; c:=0;
  while (c<=pl) and (rn=-1) do
  begin
    seek(ulff,c); read(ulff,f);
    if pos('.',f.filename)<>9 then
    begin
      f.filename:=align(f.filename);
      seek(ulff,c); write(ulff,f);
    end;
    if fit(fn,f.filename) then rn:=c;
    inc(c);
  end;
  lrn:=rn;
  lfn:=fn;
end;

function rte:real;
var i:word;
begin
  i:=value(realspd); if (i=0) then i:=modemr.waitbaud;
  rte:=1241.6/i;
end;

procedure star(s:astr);
begin
  sprint('|Bþ |C'+s);
end;

function stripname(i:astr):astr;
var i1:astr;
    n:integer;

  function nextn:integer;
  var n:integer;
  begin
    n:=pos(':',i1);
    if (n=0) then n:=pos('\',i1);
    if (n=0) then n:=pos('/',i1);
    nextn:=n;
  end;

begin
  i1:=i;
  while (nextn<>0) do i1:=copy(i1,nextn+1,80);
  stripname:=i1;
end;

function tcheck(s:real; i:integer):boolean;
var r:real;
begin
  r:=timer-s;
  if r<0.0 then r:=r+86400.0;
  if (r<0.0) or (r>32760.0) then r:=32766.0;
  if trunc(r)>i then tcheck:=FALSE else tcheck:=TRUE;
end;

function tchk(s:real; i:real):boolean;
var r:real;
begin
  r:=timer;
  if r<s then r:=r+86400.0;
  if (r-s)>i then tchk:=FALSE else tchk:=TRUE;
end;

end.
