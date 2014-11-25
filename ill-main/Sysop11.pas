(*****************************************************************************)
(* Illusion BBS - SysOp routines  [11/11] (zlog, change user, logs)          *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop11;

interface

uses
  crt, dos,
  misc1, miscx, menus2, common;

procedure chuser;
procedure zlog;
procedure showlogs;

implementation

procedure chuser;
var macrf:file of macrorec;
    s:astr;
    i:integer;
begin
  sprompt('|wUser to change to: |W');
  finduser(s,i);
  if (i>=1) then begin
    thisuser.sl:=realsl; thisuser.dsl:=realdsl;

    SetFileAccess(ReadWrite,DenyNone);
    reset(uf);
    seek(uf,usernum); write(uf,thisuser);
    seek(uf,i); read(uf,thisuser);
    close(uf);

    realsl:=thisuser.sl; realdsl:=thisuser.dsl;
    usernum:=i;
    choptime:=0.0; extratime:=0.0; freetime:=0.0;

    readinmacros; readinzscan;

    if (spd<>'KB') then sysoplog('* |RChanged to '+nam);
    topscr;
    newcomptables;
  end;
end;

procedure zlog;
var zf:file of zlogrec;
    d1:zlogrec;
    dd:astr;
    i:integer;
    abort,next:boolean;

  function mrnn(i,l:integer):astr;
  begin
    mrnn:=mrn(cstr(i),l);
  end;

begin
  cls;
  assign(zf,systat^.datapath+'HISTORY.DAT');
  SetFileAccess(ReadOnly,DenyNone);
  reset(zf);
  if (filesize(zf)=0) then
    sprint('History log is empty.|LF|PA')
  else
  begin
    abort:=FALSE;
    read(zf,d1);

    printacr('|w                       New        Email',abort,next);
    printacr('|wDate     Calls Active Users Posts Sent   Uploads     Downloads',abort,next);
    printacr('|K|LI',abort,next);
    i:=-1;
    seek(zf,0);
    while ((i<=filesize(zf)-1) and (not abort) and (d1.date<>'')) do begin
      if (i>=0) then begin
        read(zf,d1);
        dd:=d1.date;
      end else begin
        d1:=systat^.todayzlog;
        dd:='|WToday''s ';
      end;
      printacr(dd+' '+mrnn(d1.calls,5)+' '+
               ctp(d1.active,1440)+' '+mrnn(d1.newusers,5)+' '+
               mrnn(d1.pubpost,5)+' '+mrnn(d1.privpost,5)+'  '+
               mln(cstr(d1.uploads)+'-'+cstr(d1.uk)+'k',10)+'  '+
               mln(cstr(d1.downloads)+'-'+cstr(d1.dk)+'k',10),abort,next);
      inc(i);
    end;
    close(zf);
  end;
end;

procedure showlogs;
var s:astr;
    nodes,day,noden:integer;
begin
  nl;
  SetFileAccess(ReadOnly,DenyNone);
  reset(nodef);
  nodes:=filesize(nodef);
  close(nodef);
  if (nodes>1) then
  begin
    sprompt('|wDisplay log for node |K[|C1|c-|C'+cstr(nodes)+'|K] [|C'+cstr(nodenum)+'|K] |W');
    input(s,8);
    if (length(s)>0) then
      noden:=value(s)
    else
      noden:=nodenum;
  end else
    noden:=nodenum;
  cls;
  close(sysopf);
  printf(systat^.trappath+date2+'.'+cstr(noden));
  if (nofile) then begin nl; sprint('|RSystem log not found!'); end;
  append(sysopf);
  if (useron) then begin
    s:='* Viewed today''s sysop log';
    if (nodes>1) then s:=s+' for node '+cstr(noden);
    sysoplog(s);
  end;
end;

end.
