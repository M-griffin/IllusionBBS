(*****************************************************************************)
(* Illusion BBS - File routines  [2/15] (copy/move files)                    *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit Mfile2;

interface

uses
  crt, dos,
  execbat, Mfile0, common;

procedure copyfile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);
procedure movefile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);

implementation

procedure copyfile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);
var buffer:array[1..16384] of byte;
    fs,dfs:longint;
    nrec,i,pass:integer;
    src,dest:file;

  procedure dodate;
  var r:registers;
      od,ot,ha:integer;
  begin
    srcname:=srcname+#0;
    destname:=destname+#0;
    with r do begin
      ax:=$3d00; ds:=seg(srcname[1]); dx:=ofs(srcname[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5700; msdos(dos.registers(r));
      od:=dx; ot:=cx; bx:=ha; ax:=$3e00; msdos(dos.registers(r));
      ax:=$3d02; ds:=seg(destname[1]); dx:=ofs(destname[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5701; cx:=ot; dx:=od; msdos(dos.registers(r));
      ax:=$3e00; bx:=ha; msdos(dos.registers(r));
    end;
  end;

begin
  ok:=TRUE; nospace:=FALSE;
  assign(src,srcname);
  SetFileAccess(ReadWrite,DenyALL);
  {$I-} reset(src,1); {$I+}
  if (ioresult<>0) then begin ok:=FALSE; exit; end;
  dfs:=freek(exdrv(destname));
  fs:=trunc(filesize(src)/1024.0)+1;
  if (fs>=dfs) then begin
    close(src);
    nospace:=TRUE; ok:=FALSE;
    exit;
  end else begin
    assign(dest,destname);
    {$I-} rewrite(dest,1); {$I+}
    if (ioresult<>0) then begin ok:=FALSE; exit; end;
    Close(dest);
    SetFileAccess(ReadWrite,DenyALL);
    Reset(Dest,1);

    if (showprog) then
    begin
      cl(ord('w'));
      prompt('0%');
    end;
    pass:=0; i:=fs div 16; if (fs mod 16<>0) then inc(i);
    repeat
      blockread(src,buffer,16384,nrec);
      blockwrite(dest,buffer,nrec); inc(pass);
      if (showprog) then prompt(^H^H^H^H+cstr(round(pass/i*100))+'%');
    until (nrec<16384);
    prompt(^H^H^H^H+'100%');
    close(dest); close(src);
    dodate;
  end;
end;

function substall(src,old,new:astr):astr;
var p:integer;
begin
  p:=1;
  while p>0 do begin
    p:=pos(old,src);
    if p>0 then begin
      insert(new,src,p+length(old));
      delete(src,p,length(old));
    end;
  end;
  substall:=src;
end;

procedure movline(var src:astr; s1,s2:astr);
begin
  src:=substall(src,'@F',s1);
  src:=substall(src,'@I',s2);
end;

procedure movefile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);
var f:file;
    s,opath:astr;
    c1,c2:char;
begin
  ok:=TRUE; nospace:=FALSE;

  getdir(0,opath);

  s:=fexpand(srcname); c1:=s[1];
  s:=fexpand(destname); c2:=s[1];
  if c1=c2 then begin
    assign(f,srcname);
    {$I-} rename(f,destname); {$I+}
    if ioresult=0 then begin
      if showprog then prompt('100%');
      chdir(opath);
      exit;
    end;
  end;

  copyfile(ok,nospace,showprog,srcname,destname);
  if ((ok) and (not nospace)) then begin
    assign(f,srcname);
    {$I-} erase(f); {$I+}
  end;
  chdir(opath);
end;

end.
