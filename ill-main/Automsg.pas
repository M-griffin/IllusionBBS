(*****************************************************************************)
(* Illusion BBS - Auto Message                                               *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit automsg;

interface

uses
  crt, dos,
  common, mailfse, mailline;

procedure readamsg;
procedure writeamsg;

implementation

procedure readamsg;
var f:text;
    s,ss:^astr;
begin
  new(s); new(ss);
  assign(f,systat^.datapath+'AUTOMSG.TXT');
  setfileaccess(readwrite,denynone);
  {$I-} reset(f); {$I+}
  nofile:=(ioresult<>0);
  if (nofile) then
    spstr(671)
  else
  begin
    readln(f,ss^);
    if (ss^[1]='@') then
      if (aacs(systat^.anonpubread)) then
        ss^:=substone(getstr(672),'~AU',copy(ss^,2,length(ss^)))
      else
        ss^:=getstr(673);
    clearwaves;
    addwave('AU',ss^,txt);
    spstr(668);
    if aborted then exit;
    while not (eof(f)) do
    begin
      readln(f,s^);
      clearwaves;
      addwave('LI',s^,txt);
      spstr(669);
    end;
    close(f);
    clearwaves;
    addwave('AU',ss^,txt);
    spstr(670);
    clearwaves;
  end;
  dispose(s); dispose(ss);
end;

procedure writeamsg;
var usefse,ok:boolean;
    fname,s:astr;
    f,f1:text;
begin
  if (ramsg in thisuser.ac) then
    spstr(674)  { no acs }
  else
  begin
    if (okansi) then
    begin
      if thisuser.edtype=1 then
        usefse:=FALSE
      else if thisuser.edtype=2 then
        usefse:=TRUE
      else
        usefse:=pynq(getstr(675));  { use fse? }
    end else
      usefse:=FALSE;

    fname:=modemr^.temppath+'AMSG.'+cstr(nodenum);
    if exist(fname) then
    begin
      assign(f,fname);
      setfileaccess(readwrite,denynone);
      erase(f);
    end;

    if usefse then
      ok:=fse(fname,FALSE)
    else
      ok:=lineedit(fname,FALSE);

    if (not ok) then
      spstr(676)  { aborted }
    else
    begin

      s:=nam;
      if (aacs(systat^.anonpubpost)) and (pynq(getstr(677))) then s:='@'+s;

      assign(f,systat^.datapath+'AUTOMSG.TXT');
      setfileaccess(readwrite,denynone);
      rewrite(f);
      assign(f1,fname);
      setfileaccess(readwrite,denynone);
      reset(f1);
      writeln(f,s);
      while not (eof(f1)) do
      begin
        readln(f1,s);
        writeln(f,s);
      end;
      close(f);
      close(f1);

      spstr(678); { amsg saved }
      sysoplog('Changed auto message.');
    end;
  end;
end;

end.
