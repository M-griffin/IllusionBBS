(*****************************************************************************)
(* Illusion BBS - File routines  [6/15] (protocols, batch)                   *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit Mfile6;

interface

uses
  crt, dos,
  Mfile0, Mfile1, Mfile2, Mfile4, Mfile9, execbat, common, common2;

procedure delbatch(n:integer);
procedure mpkey(var s:astr);
function  bproline1(cline:astr):astr;
procedure bproline(var cline:astr; filespec:astr);
function  okprot(prot:protrec; ul,dl,batch,resume:boolean):boolean;
procedure showprots(ul,dl,batch,resume:boolean);
function  findprot(cs:astr; ul,dl,batch,resume:boolean):integer;
procedure batchdl;
procedure listbatchfiles;
procedure removebatchfiles;
procedure clearbatch;

implementation

procedure delbatch(n:integer);
var c:integer;
begin
  if ((n>=1) and (n<=numbatchfiles)) then begin
    batchtime:=batchtime-batch[n].tt;
    if (n<>numbatchfiles) then
      for c:=n to numbatchfiles-1 do batch[c]:=batch[c+1];
    dec(numbatchfiles);
  end;
end;

procedure mpkey(var s:astr);
var sfqarea,smqarea:boolean;
begin
  sfqarea:=fqarea; smqarea:=mqarea;
  fqarea:=FALSE; mqarea:=FALSE;

  mmkey(s);

  fqarea:=sfqarea; mqarea:=smqarea;
end;

function bproline2(cline:astr):astr;
var s:astr;
begin
  s:=substall(cline,'%C',start_dir);
  s:=substall(s,'%G',copy(systat^.datapath,1,length(systat^.datapath)-1));
  bproline2:=s;
end;

function bproline1(cline:astr):astr;
var s,s1,s2:astr;
begin
  if ((not incom) and (not outcom)) then s1:=cstrl(modemr.waitbaud) else s1:=spd;
  if ((not incom) and (not outcom)) then s2:=cstrl(modemr.waitbaud) else s2:=realspd;
  s:=substall(cline,'%B',s1);
  s:=substall(s,'%E',s2);
  s:=substall(s,'%L',bproline2(protocol.dlflist));
  s:=substall(s,'%P',cstr(modemr.comport));
  s:=substall(s,'%T',bproline2(protocol.templog));
  bproline1:=bproline2(s);
end;

procedure bproline(var cline:astr; filespec:astr);
const lastpos:integer=-1;
begin
  if (pos('%F',cline)<>0) then begin
    lastpos:=pos('%F',cline)+length(filespec);
    cline:=substall(cline,'%F',filespec);
  end;
end;

function okprot(prot:protrec; ul,dl,batch,resume:boolean):boolean;
var s:astr;
begin
  okprot:=FALSE;
  with prot do begin
    if (ul) then s:=ulcmd else if (dl) then s:=dlcmd else s:='';
    if (s='NEXT') and ((ul) or (batch) or (resume)) then exit;
    if (s='BATCH') and ((batch) or (resume)) then exit;
    if (batch<>(xbisbatch in xbstat)) then exit;
    if (resume<>(xbisresume in xbstat)) then exit;
    if (not (xbactive in xbstat)) then exit;
    if (not aacs(acs)) then exit;
    if (s='') then exit;
  end;
  okprot:=TRUE;
end;

procedure showprots(ul,dl,batch,resume:boolean);
var s:astr;
    i:integer;
    abort,next:boolean;
begin
  nofile:=TRUE;
  if (resume) then printf('protres')
  else begin
    if (batch) and (ul) then printf('protbul');
    if (batch) and (dl) then printf('protbdl');
    if (not batch) and (ul) then printf('protsul');
    if (not batch) and (dl) then printf('protsdl');
  end;
  if (nofile) then begin
    seek(xf,0);
    abort:=FALSE; next:=FALSE; i:=0;
    while ((i<=filesize(xf)-1) and (not abort)) do begin
      read(xf,protocol);
      if (okprot(protocol,ul,dl,batch,resume)) then sprint(protocol.descr);
      if (not empty) then wkey(abort,next);
      inc(i);
    end;
  end;
end;

(* XF should be OPEN  --
   returns:
     (-1):Ascii   (xx):Xmodem   (xx):Xmodem-CRC   (xx):Ymodem
     (-10):Quit   (-11):Next    (-12):Batch       (-99):Invalid (or no access)
   else, the protocol #
*)
function findprot(cs:astr; ul,dl,batch,resume:boolean):integer;
var s:astr;
    i:integer;
    done:boolean;
begin
  findprot:=-99;
  if (cs='') then exit;
  seek(xf,0);
  done:=FALSE; i:=0;
  while ((i<=filesize(xf)-1) and (not done)) do begin
    read(xf,protocol);
    with protocol do
      if (cs=ckeys) then
        if (okprot(protocol,ul,dl,batch,resume)) then begin
          if (ul) then s:=ulcmd else if (dl) then s:=dlcmd else s:='';
          if (s='ASCII') then begin done:=TRUE; findprot:=-1; end
          else if (s='QUIT') then begin done:=TRUE; findprot:=-10; end
          else if (s='NEXT') then begin done:=TRUE; findprot:=-11; end
          else if (s='BATCH') then begin done:=TRUE; findprot:=-12; end
          else if (s<>'') then begin done:=TRUE; findprot:=i; end;
        end;
    inc(i);
  end;
end;

procedure batchdl;
var batfile,tfil:text;  {@4 file list file}
    xferstart,xferend,tooktime,batchtime1:datetimerec;
    nfn,snfn,s,s1,s2,i,logfile:astr;
    st,tott,tooktime1,r:real;
    tblks,tblks1,cps,lng:longint;
    tpts,tpts1,tptsneed,tnfils,tnfils1:integer;
    sx,sy,n,p,toxfer,rcode:integer;
    c:char;
    hua,swap,done1,dok,kabort,nomore,readlog:boolean;
    oldwhereuser:string[20];

  function tempfile(i:integer):astr;
  begin
    tempfile:='temp'+cstr(i)+'.'+cstr(nodenum);
  end;

  procedure sprtcl(c:char; s:astr);
  var wnl:boolean;
  begin
    if copy(s,length(s),1)<>#0 then wnl:=TRUE else wnl:=FALSE;
    if not wnl then s:=copy(s,1,length(s)-1);
    sprompt('|C'+c+'|w) |B'+s);
    if wnl then nl;
  end;

  procedure addnacc(i:integer; s:astr);
  var f:ulfrec;
      oldboard,pl,rn:integer;
  begin
    if (i<>-1) then begin
      oldboard:=fileboard; fileboard:=i;
      s:=sqoutsp(stripname(s));
      recno(s,pl,rn); {* opens ulff *}
      if rn<>-1 then begin
        seek(ulff,rn); read(ulff,f);
        inc(f.nacc);
        seek(ulff,rn); write(ulff,f);
      end;
      fileboard:=oldboard;
      close(ulff);
    end;
  end;

  procedure chopoffspace(var s:astr);
  begin
    while (pos(' ',s)=1) do delete(s,1,1);
    if (pos(' ',s)<>0) then s:=copy(s,1,pos(' ',s)-1);
  end;

  procedure figuresucc;
  var filestr,statstr:astr;
      foundit:boolean;

    function wasok:boolean;
    var i:integer;
        foundcode:boolean;
    begin
      foundcode:=FALSE;
      for i:=1 to 6 do
        if (protocol.dlcode[i]<>'') and
           (protocol.dlcode[i]=copy(statstr,1,length(protocol.dlcode[i]))) then
          foundcode:=TRUE;
      wasok:=FALSE;
      if ((foundcode) and (not (xbxferokcode in protocol.xbstat))) then exit;
      if ((not foundcode) and (xbxferokcode in protocol.xbstat)) then exit;
      wasok:=TRUE;
    end;

  begin
    readlog:=FALSE;
    if (protocol.templog<>'') then begin
      assign(batfile,bproline1(protocol.templog));
      {$I-} reset(batfile); {$I+}
      if (ioresult=0) then begin
        readlog:=TRUE;
        while (not eof(batfile)) do begin
          readln(batfile,s);
          filestr:=copy(s,protocol.logpf,length(s)-(protocol.logpf-1));
          statstr:=copy(s,protocol.logps,length(s)-(protocol.logps-1));
          chopoffspace(filestr);
          foundit:=FALSE; n:=0;
          while ((n<numbatchfiles) and (not foundit)) do begin
            inc(n);
            if (allcaps(batch[n].fn)=allcaps(filestr)) then foundit:=TRUE;
          end;
          if (foundit) then begin
            if (wasok) then begin
              sysoplog('|YBatch downloaded "'+stripname(batch[n].fn)+'"');
              inc(tnfils);
              inc(tblks,batch[n].blks);
              inc(tpts,batch[n].pts);
              loaduboard(batch[n].section);
              if (not (fbnoratio in memuboard.fbstat)) then begin
                inc(tnfils1);
                inc(tblks1,batch[n].blks);
                inc(tpts1,batch[n].pts);
              end;
              addnacc(batch[n].section,batch[n].fn);
              delbatch(n);
            end else
              sysoplog('|RTried batch download "'+stripname(batch[n].fn)+'"');
          end else
            sysoplog('|RDownloaded File Not In Queue "'+filestr+'"');
        end;
        close(batfile);
        {$I-} erase(batfile); {$I+}
      end;
    end;
    if (not readlog) then begin
      while (toxfer>0) do begin
        sysoplog('|YBatch download "'+stripname(batch[1].fn)+'"');
        inc(tnfils);
        inc(tblks,batch[1].blks);
        inc(tpts,batch[1].pts);
        loaduboard(batch[1].section);
        if (not (fbnoratio in memuboard.fbstat)) then begin
          inc(tnfils1);
          inc(tblks,batch[1].blks);
          inc(tpts1,batch[1].pts);
        end;
        addnacc(batch[1].section,batch[1].fn);
        delbatch(1); dec(toxfer);
      end;
    end;
  end;

begin
  if (numbatchfiles=0) then
    spstr(135)
  else begin

    tott:=0.0; tptsneed:=0;
    for n:=1 to numbatchfiles do begin
      tott:=tott+batch[n].tt;
      loaduboard(batch[n].section);
      if not(fbnoratio in memuboard.fbstat) then inc(tptsneed,batch[n].pts);
    end;
    if (aacs(systat^.nofilepts)) or (fnofilepts in thisuser.ac) then tptsneed:=0;

    clearwaves;
    addwave('BF',cstr(numbatchfiles),txt);
    addwave('TD',ctim(round(tott)),txt);
    addwave('TL',ctim(round(nsl)),txt);
    addwave('FP',cstr(tptsneed),txt);
    spstr(136);
    clearwaves;

    if (tott>nsl) then begin
      spstr(137);
      spstr(139);
      exit;
    end else if (thisuser.filepoints<tptsneed) and (tptsneed>0) and
     (not aacs(systat^.nofilepts)) and
     (not (fnofilepts in thisuser.ac)) and
     (not (fbnoratio in memuboard.fbstat)) then
    begin
      spstr(138);
      spstr(139);
      exit;
    end;

    SetFileAccess(ReadOnly,DenyNone);
    reset(xf);
    done1:=FALSE;
    repeat
      spstr(117); mpkey(i);
      if (i='?') then begin
        nl;
        showprots(FALSE,TRUE,TRUE,FALSE);
      end else begin
        p:=findprot(i,FALSE,TRUE,TRUE,FALSE);
        if (p=-99) then spstr(386) else done1:=TRUE;
      end;
    until (done1) or (hangup);
    if (p<>-10) then begin
      seek(xf,p); read(xf,protocol); close(xf);
      hua:=pynq(getstr(140));
      dok:=TRUE;
      tblks:=0; tpts:=0; tnfils:=0;
      tblks1:=0; tpts1:=0; tnfils1:=0;
      nl; nl;

      nfn:=bproline1(systat^.protpath+protocol.dlcmd);
      toxfer:=0; tott:=0.0;
      if (pos('%F',protocol.dlcmd)<>0) then begin
        done1:=FALSE;
        while ((not done1) and (toxfer<numbatchfiles)) do begin
          inc(toxfer); snfn:=nfn;
          bproline(nfn,batch[toxfer].fn);
          tott:=tott+batch[toxfer].tt;
        end;
      end;

      if (protocol.dlflist<>'') then begin
        tott:=0.0;
        assign(batfile,bproline1(protocol.dlflist));
        rewrite(batfile);
        for n:=1 to numbatchfiles do begin
          writeln(batfile,batch[n].fn);
          inc(toxfer); tott:=tott+batch[n].tt;
        end;
        close(batfile);
      end;

      (* output x-fer batch file *)
      assign(batfile,'I_BDL'+cstr(nodenum)+'.BAT');
      rewrite(batfile);
      writeln(batfile,'@echo off');
      if (protocol.envcmd<>'') then
        writeln(batfile,bproline1(protocol.envcmd));
      writeln(batfile,nfn);
      writeln(batfile,'exit');
      close(batfile);

      if (exist(bproline1(protocol.templog))) then
      begin
        assign(batfile,bproline1(protocol.templog));
        {$I-} erase(batfile); {$I+}
      end;

      r2dt(batchtime,batchtime1);
      if (useron) then
      begin
        clearwaves;
        addwave('ET',longtim(batchtime1),txt);
        spstr(387);
        clearwaves;
      end;

      if (useron) then shel(caps(thisuser.name)+' is batch downloading!')
                  else shel('Sending file(s)...');

      oldwhereuser:=thisnode.whereuser;
      thisnode.whereuser:=getstr(388);
      savenode;

      getdatetime(xferstart);
      systat^.swapshell:=systat^.swapshell and systat^.swapxfer;
      shelldos(FALSE,'I_BDL'+cstr(nodenum)+'.BAT',rcode);
      readsystat;
      shel2;
      getdatetime(xferend);
      timediff(tooktime,xferstart,xferend);

      thisnode.whereuser:=oldwhereuser;
      savenode;

      assign(batfile,'I_BDL'+cstr(nodenum)+'.BAT');
      {$I-} erase(batfile); {$I+}
      if (exist(protocol.dlflist)) then
      begin
        assign(batfile,protocol.dlflist);
        {$I-} erase(batfile); {$I+}
      end;

      figuresucc;

      tooktime1:=dt2r(tooktime);
      if (tooktime1>=1.0) then begin
        cps:=tblks; cps:=cps*128;
        cps:=trunc(cps/tooktime1);
      end else
        cps:=0;

      showuserfileinfo;
      commandline('');
      nl; nl;

      if tnfils=0 then
        spstr(390)
      else begin
        clearwaves;
        addwave('FI',cstr(tnfils),txt);
        addwave('FS',aonoff(tnfils<>1,'s',' '),txt);
        lng:=tblks; lng:=lng*128;
        addwave('BY',cstrl(lng),txt);
        if (tpts<>0) then begin
          addwave('FP',cstr(tpts),txt);
          addwave('PS',aonoff(tpts<>1,'s',' '),txt);
        end;
        if (tpts<>0) then spstr(389) else spstr(391);
        clearwaves;
      end;

      if (tnfils1<>tnfils) then begin
        if (tnfils<tnfils1) then tnfils1:=tnfils;

        clearwaves;
        addwave('FI',cstr(tnfils1),txt);
        addwave('FS',aonoff(tnfils1<>1,'s',' '),txt);
        lng:=tblks1; lng:=lng*128;
        addwave('BY',cstrl(lng),txt);
        if (tpts1<>0) then begin
          addwave('FP',cstr(tpts1),txt);
          addwave('PS',aonoff(tpts1<>1,'s',' '),txt);
        end;
        if (tpts1<>0) then spstr(393) else spstr(394);
      end;

      clearwaves;
      addwave('DT',longtim(tooktime),txt);
      spstr(395);
      clearwaves;
      addwave('TR',cstr(cps),txt);
      spstr(396);
      clearwaves;

      thisuser.dk:=thisuser.dk+(tblks div 8);
      inc(thisuser.downloads,tnfils1);
      dec(thisuser.filepoints,tpts1);

      readsystat;
      inc(systat^.todayzlog.downloads,tnfils);
      inc(systat^.todayzlog.dk,tblks div 8);
      savesystat;

      if (numbatchfiles<>0) then begin
        tblks:=0; tpts:=0;
        for n:=1 to numbatchfiles do begin
          inc(tblks,batch[n].blks);
          inc(tpts,batch[n].pts);
        end;
        lng:=tblks; lng:=lng*128;
        clearwaves;
        addwave('FI',cstr(numbatchfiles),txt);
        addwave('FS',aonoff(numbatchfiles<>1,'s',' '),txt);
        addwave('BY',cstrl(lng),txt);
        if (tpts<>0) then begin
          addwave('FP',cstr(tpts),txt);
          addwave('PS',aonoff(tpts<>1,'s',' '),txt);
        end;
        if (tpts<>0) then spstr(397) else spstr(398);
        clearwaves;
      end;

      if (hua) and (not hangup) then
      begin
        spstr(399);
        st:=timer; r:=timer-st; c:='5'; prompt(c);
        while (trunc(r)<5) and (empty) do
        begin
          r:=timer-st;
          if (c<>chr(trunc(5-r)+48)) then
          begin
            c:=chr(trunc(5-r)+48);
            prompt(^H+c);
          end;
        end;
        if (empty) then hangup:=TRUE;
        if (not empty) then
          if upcase(inkey)=^M then
            hangup:=TRUE;
      end;
    end;
  end;
end;

procedure listbatchfiles;
var tot:record
          pts:integer;
          blks:longint;
          tt:real;
        end;
    s:astr;
    i:integer;
    abort,next:boolean;
begin
  if (numbatchfiles=0) then begin
    nl; print('Batch queue empty.');
  end else begin
    abort:=FALSE; next:=FALSE;
    with tot do begin
      pts:=0; blks:=0; tt:=0.0;
    end;

    nl;
    printacr('|B##:Filename.Ext Area Pts   Bytes   hh:mm:ss',abort,next);
    printacr('|B컴:컴컴컴컴컴컴 컴컴 컴컴� 컴컴컴� 컴컴컴컴',abort,next);

    i:=1;
    while (not abort) and (not hangup) and (i<=numbatchfiles) do begin
      with batch[i] do begin
        if section=-1 then s:='|RUnli' else s:='|Y'+mrn(cstr(section),4);
        s:='|C'+mn(i,2)+'|B:|Y'+align(stripname(fn))+' '+
           s+' |B'+mrn(cstr(pts),5)+' |B'+
           mrn(cstrl(blks*128),7)+' |R'+ctim(tt);
        if (section<>-1) then begin
          loaduboard(section);
          if (fbnoratio in memuboard.fbstat) then s:=s+' <No-Ratio>';
        end;
        printacr(s,abort,next);
        tot.pts:=tot.pts+pts;
        tot.blks:=tot.blks+blks;
        tot.tt:=tot.tt+tt;
      end;
      inc(i);
    end;

    printacr('|B컴컴컴컴컴컴컴� 컴컴 컴컴� 컴컴컴� 컴컴컴컴',abort,next);
    with tot do
      s:='|C'+mln('Totals:',20)+' |B'+mrn(cstr(pts),5)+' |B'+
         mrn(cstrl(blks*128),7)+' |R'+ctim(tt);
    printacr(s,abort,next);
  end;
end;

procedure removebatchfiles;
var s:astr;
    i:integer;
begin
  if numbatchfiles=0 then begin
    spstr(135);
  end else
    repeat
      spstr(400);
      input(s,2); i:=value(s);
      if (s='?') then listbatchfiles;
      if (i>0) and (i<=numbatchfiles) then begin
        clearwaves;
        addwave('FN',stripname(batch[i].fn),txt);
        spstr(401);
        clearwaves;
        delbatch(i);
      end;
      if (numbatchfiles=0) then begin spstr(135); end;
    until (s<>'?');
end;

procedure clearbatch;
begin
  if pynq(getstr(402)) then begin
    numbatchfiles:=0;
    batchtime:=0.0;
    spstr(135);
  end;
end;

end.
