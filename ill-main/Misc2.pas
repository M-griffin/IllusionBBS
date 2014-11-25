(*****************************************************************************)
(* Illusion BBS - Miscellaneous [2/3]                                        *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit misc2;

interface

uses
  crt, dos,
  common;  

procedure ulist;
procedure addrumor;
procedure callerlog;
procedure checkbday;
procedure Oneliners;

implementation

procedure callerlog;
var lcf:file of lcallers;
    lc:^lcallers;
    i:word;
    abort,next:boolean;
begin
  sysoplog('Viewed caller log');
  assign(lcf,systat^.datapath+'USERLOG.DAT');
  SetFileAccess(ReadOnly,DenyNone);
  reset(lcf); new(lc);
  aborted:=false;
  spstr(446);
  if (filesize(lcf)<>0) and (not aborted) then
  begin
    i:=0; abort:=false; next:=false;
    while (not aborted) and (i<=filesize(lcf)-1) and (not hangup) and (not abort) do
    begin
      inc(i);
      read(lcf,lc^);
      clearwaves;
      with lc^ do
      begin
        addwave('C#',cstr(callernum),txt);
        addwave('UN',name,txt);
        addwave('U#',cstr(number),txt);
        addwave('UT',name+' #'+cstr(number),txt);
        addwave('UC',citystate,txt);
        addwave('N#',node,txt);
        addwave('BD',baud,txt);
        addwave('NU',aonoff(newuser,getstr(449),getstr(450)),txt);
        addwave('TC',time,txt);
      end;
      spstr(447);
      wkey(abort,next);
    end;
    aborted:=aborted or abort;
  end;
  clearwaves;
  if not aborted then spstr(448);
  close(lcf);
  dispose(lc);
end;

procedure ulist;
var u:^userrec;
    sr:smalrec;
    s:astr;
    i,j:integer;
    abort,next:boolean;
begin
  sysoplog('Viewed user list');
  setfileaccess(readonly,denynone);
  reset(sf);
  aborted:=FALSE;
  spstr(451);
  setfileaccess(readonly,denynone);
  reset(uf); new(u);
  i:=0; j:=0; abort:=false; next:=false;
  while (not aborted) and (i<filesize(sf)-1) and (not hangup) and (not abort) do
  begin
    inc(i);
    clearwaves;
    seek(sf,i); read(sf,sr); seek(uf,sr.number); read(uf,u^);
    addwave('UN',caps(sr.name),txt);
    addwave('U#',caps(cstr(sr.number)),txt);
    addwave('UT',caps(sr.name)+' #'+cstr(sr.number),txt);
    addwave('UC',u^.citystate,txt);
    addwave('US',u^.sex,txt);
    addwave('LC',u^.laston,txt);
    addwave('NO',u^.usernote,txt);
    addwave('SN',u^.note,txt);
    addwave('SL',cstr(u^.sl),txt);
    addwave('DS',cstr(u^.dsl),txt);
    spstr(452);
    wkey(abort,next);
    inc(j);
  end;
  aborted:=aborted or abort;
  clearwaves;
  if (not aborted) then
  begin
    addwave('TU',cstr(j),txt);
    spstr(453);
    clearwaves;
  end;
  close(uf);
  close(sf);
  dispose(u);
end;

procedure addrumor;
var rumorf:file of rumorrec;
    rumorr:^rumorrec;
begin
  if pynq(getstr(308)) then
  begin
    assign(rumorf,systat^.datapath+'RUMOR.DAT');
    setfileaccess(readwrite,denynone);
    reset(rumorf);
    seek(rumorf,(filesize(rumorf)));
    new(rumorr);
    spstr(309);
    inputwc(rumorr^,65);
    nl;
    if (rumorr^<>'') then
    begin
      clearwaves;
      addwave('RU',rumorr^,txt);
      spstr(310);
      if pynq(getstr(311)) then
      begin
        write(rumorf,rumorr^);
        spstr(312);
        sysoplog('Added rumor: '+rumorr^);
      end;
    end;
    close(rumorf);
    dispose(rumorr);
  end;
end;

procedure checkbday;
var fbday:file of astr;
    s:astr;

  function dobday:boolean;
  var i,j:integer;
  begin
    i:=85;
    repeat
      j:=daynum(copy(thisuser.bday,1,6)+tch(cstr(i)));
      if (daynum(date)>=j) and (daynum(thisuser.laston)<j) then begin
        dobday:=TRUE;
        exit;
      end;
      inc(i);
    until (i>value(copy(date,7,2)));
    dobday:=FALSE;
  end;

begin
  assign(fbday,systat^.datapath+'BDAY.DAT');
  {$I-} reset(fbday); {$I+}
  if ioresult=0 then
  begin
    read(fbday,s);
    clearwaves;
    addwave('DT',s,txt);
    spstr(469);
    if filesize(fbday)=1 then
      spstr(423)
    else
      while not eof(fbday) do
      begin
        clearwaves;
        read(fbday,s);
        addwave('UN',s,txt);
        spstr(470);
      end;
    clearwaves;
    close(fbday);
    spstr(471);
    clearwaves;
  end;
  if (dobday) then
  begin
    nofile:=TRUE;
    if (not (copy(thisuser.bday,1,5)=copy(date,1,5))) then spstr(439) else spstr(440);
  end;
end;

Procedure Oneliners;
var OneF:File of OnelinerRec;
    One:OnelinerRec;
    i:Word;
begin
  Assign(OneF,systat^.datapath+'ONELINER.DAT');
  SetFileAccess(ReadWrite,DenyNone);
  Reset(OneF);

  spstr(625);  { header }

  while (not Eof(OneF)) do
  begin
    read(OneF,One);
    ClearWaves;
    AddWave('1L',''+One+'',txt);
    spstr(626); { middle }
  end;
  Close(OneF);
  ClearWaves;

  spstr(627); { footer }

  if (pynq(getstr(628))) and (not hangup) then   { wanna add a oneliner? }
  begin
    spstr(629); { enter oneliner }
    inputwc(One,70);
    if (sqoutsp(One)<>'') then
    begin
      SetFileAccess(ReadWrite,DenyNone);
      Reset(OneF);
      seek(OneF,FileSize(OneF));
      write(OneF,One);
      Close(OneF);
    end;
  end;

  SetFileAccess(ReadWrite,DenyNone);
  Reset(OneF);
  if (FileSize(OneF)>Systat^.MaxOneliners) and (Systat^.MaxOneliners>0) then
  begin
    for i:=0 to Systat^.MaxOneliners-1 do
    begin
      seek(OneF,FileSize(OneF)-Systat^.MaxOneliners+i);
      read(OneF,One);
      seek(OneF,i);
      write(OneF,One);
    end;
    seek(OneF,Systat^.MaxOneliners);
    truncate(OneF);
  end;
  Close(OneF);

end;

end.
