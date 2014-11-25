(*****************************************************************************)
(* Illusion BBS - File routines  [14/15] (gifspecs)                          *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit Mfile14;

interface

uses
  crt, dos,
  myio,
  Mfile0, Mfile11,
  common;

procedure getgifspecs(fn:astr; var sig:astr; var x,y,c:word);
procedure dogifspecs(fn:astr; var abort,next:boolean);
procedure addgifspecs;

implementation

procedure getgifspecs(fn:astr; var sig:astr; var x,y,c:word);
var f:file;
    rec:array[1..11] of byte;
    c1,i,numread:word;
begin
  assign(f,fn);
  SetFileAccess(ReadOnly,DenyNone);
  {$I-} reset(f,1); {$I+}
  if (ioresult<>0) then begin
    sig:='NOTFOUND';
    exit;
  end;

  blockread(f,rec,11,numread);
  close(f);

  if (numread<>11) then begin
    sig:='BADGIF';
    exit;
  end;

  sig:='';
  for i:=1 to 6 do sig:=sig+chr(rec[i]);

  x:=rec[7]+rec[8]*256;
  y:=rec[9]+rec[10]*256;
  c1:=(rec[11] and 7)+1;
  c:=1;
  for i:=1 to c1 do c:=c*2;
end;

procedure dogifspecs(fn:astr; var abort,next:boolean);
var s,sig:astr;
    x,y,c:word;
begin
  getgifspecs(fn,sig,x,y,c);
  s:='|C'+align(stripname(fn));
  if (sig='NOTFOUND') then
    s:=s+'   |RNOT FOUND'
  else
    s:=s+'   |Y'+mln(cstrl(x)+'x'+cstrl(y),10)+'   '+
         mln(cstr(c)+' colors',10)+'   |R'+sig;
  printacr(s,abort,next);
end;

procedure addgifspecs;
var f:ulfrec;
    gifstart,gifend,tooktime:datetimerec;
    s,sig:astr;
    totfils:longint;
    x,y,c:word;
    pl,rn:integer;
    abort,next:boolean;
begin
  spstr(474);
  recno('*.*',pl,rn);
  if (baddlpath) then exit;

  totfils:=0; abort:=FALSE; next:=FALSE;
  getdatetime(gifstart);

  while (rn<>-1) and (pl<>0) and (rn<=pl) and
        (not abort) and (not hangup) do begin
    seek(ulff,rn); read(ulff,f);
    if ((isgifext(f.filename)) and (not isgifdesc(f.description))) then begin
      getgifspecs(memuboard.dlpath+sqoutsp(f.filename),sig,x,y,c);
      if (sig<>'NOTFOUND') then begin
        s:=mln('('+cstrl(x)+'x'+cstrl(y)+','+cstr(c)+'c)',15);
        f.description:=s+f.description;
        if (length(f.description)>54) then
          f.description:=copy(f.description,1,54);
        seek(ulff,rn); write(ulff,f);
        pfn(rn,f,abort,next);
        inc(totfils);
      end;
    end;
    nrecno('*.*',pl,rn);
    wkey(abort,next);
  end;
  getdatetime(gifend);
  timediff(tooktime,gifstart,gifend);

  clearwaves;
  addwave('FI',cstrl(totfils),txt);
  addwave('FS',aonoff(totfils<>1,'s',''),txt);
  addwave('TT',longtim(tooktime),txt);
  spstr(475);
  clearwaves;

  close(ulff);
end;

end.
