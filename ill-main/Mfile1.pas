(*****************************************************************************)
(* Illusion BBS - File routines  [1/15]                                      *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit Mfile1;

interface

uses
  crt, dos,
  execbat, myio, common, common2;

procedure dodl(fpneed:integer);
procedure doul(pts:integer);
procedure showuserfileinfo;
function okdl(f:ulfrec):boolean;
procedure dlx(f1:ulfrec; rn:integer; var abort:boolean);
procedure dl(fn:astr);
procedure dodescrs(var f:ulfrec; var v:verbrec; var pl:integer; var tosysop:boolean);
procedure writefv(rn:integer; f:ulfrec; v:verbrec);
procedure newff(f:ulfrec; v:verbrec);
procedure doffstuff(var f:ulfrec; fn:astr; var gotpts:integer);
procedure arcstuff(var ok,convt:boolean; var blks:longint; var convtime:real;
                   itest:boolean; fpath:astr; var fn:astr; var f:ulfrec;
                   var v:verbrec);
procedure idl;
procedure iul;

procedure fbaselist;
procedure unlisted_download(s:astr);
procedure do_unlisted_download;
function nfvpointer:longint;

implementation

uses Mfile0, Mfile4, Mfile8, Mfile14, Mfile9, MsgF;

var locbatup:boolean;

procedure dodl(fpneed:integer);
begin
  nl;
  nl;
  if (not aacs(systat^.nofilepts)) or
     (not (fnofilepts in thisuser.ac)) then begin
    if (fpneed>0) then dec(thisuser.filepoints,fpneed);
    if (thisuser.filepoints<0) then thisuser.filepoints:=0;
    if (fpneed<>0) then begin spstr(120); end;
  end;
end;

procedure doul(pts:integer);
begin
  if (not aacs(systat^.ulvalreq)) then begin
    spstr(121);
    if (systat^.uldlratio) then
      spstr(122)
    else
      spstr(123);
  end else
    if ((not systat^.uldlratio) and (not systat^.fileptratio) and (pts=0)) then begin
      spstr(121);
    end else
      inc(thisuser.filepoints,pts);
end;

procedure showuserfileinfo;
begin
  with thisuser do
    commandline('U/L: '+cstr(uploads)+'/'+cstr(trunc(uk))+'k  ³ D/L: '+cstr(downloads)+'/'+cstr(trunc(dk))+'k');
end;

function okdl(f:ulfrec):boolean;
var s:astr;
    b:boolean;

  procedure nope(s:word);
  begin
    if (b) then spstr(s);
    b:=FALSE;
  end;

begin
  b:=TRUE;
  if (isrequest in f.filestat) then begin
    spstr(124);
    if (pynq(getstr(479))) then begin
      s:=sqoutsp(f.filename);
      sysoplog('|R!!!!!|Y File Requested: '+sqoutsp(f.filename)+'|R !!!!!');
      {-M-}
{     ssz(1,'File Request: '+s+' from base #'+cstr(ccuboards[1][fileboard])); }
      spstr(326);
    end;
    b:=FALSE;
  end;
  if ((resumelater in f.filestat) and (not fso)) then nope(125);
  if ((notval in f.filestat) and (not aacs(systat^.dlunval))) then nope(126);
  if (thisuser.filepoints<f.filepoints) and (f.filepoints>0) and
     (not aacs(systat^.nofilepts)) and
     (not (fnofilepts in thisuser.ac)) and
     (not (fbnoratio in memuboard.fbstat)) then
    nope(108);
  if (nsl<rte*f.blocks) then
    nope(127);
  if (not exist(memuboard.dlpath+f.filename)) then begin
    nope(128);
    sysoplog('File missing: '+sqoutsp(memuboard.dlpath+f.filename));
  end;
  okdl:=b;
end;

procedure dlx(f1:ulfrec; rn:integer; var abort:boolean);
var u:userrec;
    tooktime,xferstart,xferend:datetimerec;
    i,ii,tt,bar,s:astr;
    rl,tooktime1:real;
    cps,lng:longint;
    inte,pl,z:integer;
    c:char;
    next,ps,ok,tl:boolean;
    oldwhereuser:string[20];
begin
  abort:=FALSE; next:=FALSE;
  nl;
  fileinfo(f1,false,abort,next);

  ps:=TRUE;
  abort:=FALSE;
  if (not okdl(f1)) then ps:=TRUE
  else begin
    ps:=FALSE;
    showuserfileinfo;

    oldwhereuser:=thisnode.whereuser;
    thisnode.whereuser:=getstr(388);
    savenode;

    getdatetime(xferstart);
    send1(memuboard.dlpath+f1.filename,ok,abort);
    getdatetime(xferend);
    timediff(tooktime,xferstart,xferend);

    thisnode.whereuser:=oldwhereuser;
    savenode;

    if (not (-lastprot in [10,11,12])) then
      if (not abort) then
        if (not ok) then begin
          spstr(129);
          sysoplog('|CUnsuccessful Download: "'+sqoutsp(f1.filename)+
                   '" from '+memuboard.name);
          ps:=TRUE;
        end else begin
          if (not (fbnoratio in memuboard.fbstat)) then begin
            inc(thisuser.downloads);
            thisuser.dk:=thisuser.dk+(f1.blocks div 8);
          end;

          readsystat;
          inc(systat^.todayzlog.downloads);
          inc(systat^.todayzlog.dk,(f1.blocks div 8));
          savesystat;

          lng:=f1.blocks; lng:=lng*128;

          clearwaves;
          addwave('TI',longtim(tooktime),txt);
          spstr(327);
          clearwaves;
          addwave('BY',cstrl(lng),txt);
          addwave('NR',aonoff(fbnoratio in memuboard.fbstat,getstr(329),''),txt);
          spstr(328);
          clearwaves;

          s:='|CDownload "'+sqoutsp(f1.filename)+'" from '+memuboard.name;

          tooktime1:=dt2r(tooktime);
          if (tooktime1>=1.0) then begin
            cps:=f1.blocks; cps:=cps*128;
            cps:=trunc(cps/tooktime1);
          end else
            cps:=0;

          s:=s+'|C ('+cstr(f1.blocks div 8)+'k, '+ctim(dt2r(tooktime))+
               ', '+cstr(cps)+' cps)';
          sysoplog(s);
          if ((not (fbnoratio in memuboard.fbstat)) and
             (f1.filepoints>0)) then dodl(f1.filepoints);
          showuserfileinfo;

          if (rn<>-1) then begin
            inc(f1.nacc);
            seek(ulff,rn); write(ulff,f1);
          end;
        end;
  end;
  if (ps) then begin
    spstr(110);
    onek(c,'Q '^M);
    abort:=(c='Q');
  end;
end;

procedure dl(fn:astr);
var pl,rn:integer;
    f:ulfrec;
    abort:boolean;
begin
  abort:=FALSE;
  recno(fn,pl,rn);
  if (baddlpath) then exit;
  if (rn=-1) then spstr(330)
  else
    while (rn<>-1) and (not abort) and (not hangup) do begin
      SetFileAccess(ReadWrite,DenyNone);
      reset(ulff);
      seek(ulff,rn); read(ulff,f);
      nl;
      dlx(f,rn,abort);
      nrecno(fn,pl,rn);
    end;
  SetFileAccess(ReadOnly,DenyNone); reset(uf); close(uf);
  close(ulff);
end;

procedure idl;
var s,xxz:astr; xxy:byte; I:integer;

  function ok_to_dl(s:astr):boolean;
  var ss:astr;
  begin
    ok_to_dl:=TRUE;
    I:=pos('.',s);
    if i=0 then ss:=copy(s,1,8) else ss:=copy(s,1,i-1);
    if (ss='CON') or (ss='AUX') or (ss='COM1') or (ss='COM2') or (ss='COM3') or
      (ss='COM4') or (ss='LPT1') or (ss='LPT2') or (ss='COM') or (ss='LPT') or
      (ss='PRN') or (ss='NUL') or (ss='LPT3') then begin
        ok_to_dl:=FALSE;
        sysoplog('|RTried to transfer a device!!');
        spstr(331);
      end;
  end;

begin
  spstr(105);
  mpl(12);
  input(s,12);
  if not(ok_to_dl(s)) then hangup:=TRUE;
  if (s<>'') then dl(s);
end;

procedure dodescrs(var f:ulfrec;              {* file record      *}
                   var v:verbrec;             {* verbose description record *}
                   var pl:integer;            {* # files in dir   *}
                   var tosysop:boolean);      {* whether to-SysOp *}
var i,maxlen:integer;
    isgif:boolean;
begin
  if ((tosysop) and (systat^.tosysopdir<>255) and
      (systat^.tosysopdir>=0) and (systat^.tosysopdir<=maxulb)) then begin
    spstr(130);
  end else
    tosysop:=FALSE;

  loaduboard(fileboard);
  isgif:=isgifext(f.filename);
  maxlen:=54;
  if ((fbusegifspecs in memuboard.fbstat) and (isgif)) then dec(maxlen,14);

  if (maxlen>50) then maxlen:=50;
  spstr(131);
  pchar;
  mpl(maxlen); inputl(f.description,maxlen);
  if (((f.description[1]='\') or (rvalidate in thisuser.ac))
     and (tosysop)) then begin
    fileboard:=systat^.tosysopdir;
    close(ulff);
    fiscan(pl);
    tosysop:=TRUE;
  end else
    tosysop:=FALSE;
  if (f.description[1]='\') then f.description:=copy(f.description,2,80);
  v.descr[1]:='';
  i:=1;
  repeat
    mpl(50);
    inputl(v.descr[i],50);
    if (v.descr[i]='') then i:=9;
    inc(i);
  until ((i=10) or (hangup));
  if (v.descr[1]<>'') then f.vpointer:=nfvpointer else f.vpointer:=-1;
end;

procedure writefv(rn:integer; f:ulfrec; v:verbrec);
begin
  seek(ulff,rn);
  write(ulff,f);

  if (v.descr[1]<>#1#1#0#1#1) and (f.vpointer<>-1) then begin
    SetFileAccess(ReadWrite,DenyNone);
    reset(verbf);
    seek(verbf,f.vpointer);
    write(verbf,v);
    close(verbf);
  end;
end;

procedure newff(f:ulfrec; v:verbrec); {* ulff needs to be open before calling *}
var i,pl:integer;
    f1:ulfrec;
begin
  pl:=filesize(ulff)-1;
  for i:=pl downto 0 do begin
    seek(ulff,i); read(ulff,f1);
    seek(ulff,i+1); write(ulff,f1);
  end;
  writefv(0,f,v);
  inc(pl);
end;

procedure doffstuff(var f:ulfrec; fn:astr; var gotpts:integer);
var rfpts:real;
begin
  f.filename:=align(fn);
  f.owner:=usernum;
  f.stowner:=allcaps(thisuser.name);
  f.date:=date;
  f.daten:=daynum(date);
  f.nacc:=0;

  if (not systat^.fileptratio) then begin
    f.filepoints:=0;
    gotpts:=0;
  end else begin
    rfpts:=(f.blocks/8)/systat^.fileptcompbasesize;
    f.filepoints:=round(rfpts);
    gotpts:=round(rfpts*systat^.fileptcomp);
    if (gotpts<1) then gotpts:=1;
  end;

  f.filestat:=[];
  if (not fso) and (not systat^.validateallfiles) then
    include(f.filestat,notval);
  f.ft:=255; {* ft; *}
end;

procedure arcstuff(var ok,convt:boolean;    { if ok - if converted }
                   var blks:longint;        { # blocks     }
                   var convtime:real;       { convert time }
                   itest:boolean;           { whether to test integrity }
                   fpath:astr;              { filepath     }
                   var fn:astr;             { filename     }
                   var f:ulfrec;            { filerec      }
                   var v:verbrec);          { verbose      }
var fi:file of byte;
    convtook,convstart,convend:datetimerec;
    oldnam,newnam,s,sig:astr;
    sttime:real;
    x,y,c:word;
    oldarc,newarc:integer;
    t:text;
begin
  {*  oldarc: current archive format, 0 if none
   *  newarc: desired archive format, 0 if none
   *  oldnam: current filename
   *  newnam: desired archive format filename
   *}

  convtime:=0.0;
  ok:=TRUE;

  assign(fi,fpath+fn);
  SetFileAccess(ReadOnly,DenyNone);
  {$I-} reset(fi); {$I+}
  if (ioresult<>0) then blks:=0
  else begin
    blks:=trunc((filesize(fi)+127.0)/128.0);
    close(fi);
  end;

  newarc:=memuboard.arctype;
  oldnam:=sqoutsp(fpath+fn);
  oldarc:=arctype(fn);

  if (not systat^.filearcinfo[oldarc].active) then oldarc:=0;
  if (not systat^.filearcinfo[newarc].active) then newarc:=0;
  if (newarc=0) then newarc:=oldarc;

  {* if both archive formats supported ... *}
  if ((oldarc<>0) and (newarc<>0)) then begin
  {* archive extension supported *}
    newnam:=fn;
    if (pos('.',newnam)<>0) then newnam:=copy(newnam,1,pos('.',newnam)-1);
    newnam:=sqoutsp(fpath+newnam+'.'+systat^.filearcinfo[newarc].ext);
    {* if integrity tests supported ... *}
    if ((itest) and (systat^.filearcinfo[oldarc].testline<>'')) then begin
      spstr(332);
      arcintegritytest(ok,oldarc,oldnam,'Testing file integrity...');
      if (not ok) then begin
        sysoplog(oldnam+' on #'+cstr(fileboard)+': Errors in integrity test');
        spstr(333);
      end else
        spstr(334);
    end;

    {* if conversion required ... *}
    if ((ok) and (oldarc<>newarc) and (newarc<>0)) then begin
      s:=systat^.filearcinfo[newarc].ext;
      if (fso) then begin
        dyny:=TRUE;
        clearwaves;
        addwave('AF',s,txt);
        convt:=pynq(getstr(335));
        clearwaves;
      end;
      if (convt) then begin
        getdatetime(convstart);
        conva(ok,oldarc,newarc,'I_temp5.'+cstr(nodenum),oldnam,newnam);
        getdatetime(convend);
        timediff(convtook,convstart,convend);
        convtime:=dt2r(convtook);

        if (ok) then begin
          assign(fi,fpath+fn);
          rewrite(fi); close(fi); erase(fi);
          assign(fi,newnam);
          SetFileAccess(readonly,denynone);
          {$I-} reset(fi); {$I+}
          if (ioresult<>0) then ok:=FALSE
          else begin
            blks:=trunc((filesize(fi)+127.0)/128.0);
            close(fi);
            if (blks=0) then ok:=FALSE;
          end;
          fn:=align(stripname(newnam));
          spstr(336);
        end else begin
          assign(fi,newnam);
          rewrite(fi); close(fi); erase(fi);
          sysoplog('|R>>>>|Y "'+oldnam+'" on #'+
                   cstr(fileboard)+': Conversion unsuccessful');
          spstr(337);
          newarc:=oldarc;
        end;
        ok:=TRUE;
      end else
        newarc:=oldarc;
    end;

    {* if comment fields supported/desired ... *}
    if (ok) and (systat^.filearcinfo[newarc].cmtline<>'') then begin
      spstr(338);
      s:=sqoutsp(fpath+fn);
      arccomment(ok,newarc,memuboard.cmttype,s,'Adding comment...');
      ok:=TRUE;
    end;

    {* get file_id.diz *}
    if (ok) and (systat^.descimport<>0) then begin
      s:=sqoutsp(fpath+fn);
      spstr(339);
      arcdecomp(ok,newarc,s,'FILE_ID.DIZ DESC.SDI','Looking for internal file description...');
      if (ok) then begin
        if exist(modemr.temppath+'ARCHIVE\FILE_ID.DIZ') then begin
          spstr(637);
          assign(t,modemr.temppath+'ARCHIVE\FILE_ID.DIZ');
        end else
        if exist(modemr.temppath+'ARCHIVE\DESC.SDI') then begin
          spstr(638);
          assign(t,modemr.temppath+'ARCHIVE\DESC.SDI');
        end else ok:=FALSE;

        if ok and (((systat^.descimport=1) and (pynq(getstr(385)))) or (systat^.descimport=2)) then begin
          reset(t);
          nl;
          x:=1;
          while (not(eof(t))) and (x<=10) do begin
            readln(t,s);
            sprint(s);
            if s='' then s:=' ';
            if x=1 then
              if (length(s)>60) then f.description:=copy(s,1,60)
                else f.description:=s
            else
              if length(s)>50 then v.descr[x-1]:=copy(s,1,50)
                else v.descr[x-1]:=s;
            inc(x);
          end;
          if x<=10 then v.descr[x-1]:='';
          close(t);
          if (f.vpointer=-1) and (v.descr[1]<>'') then f.vpointer:=nfvpointer;
        end;
        ok:=TRUE;
        purgedir2(modemr.temppath+'ARCHIVE\');
      end else ok:=TRUE;
    end;
  end;
  fn:=sqoutsp(fn);

  if ((isgifext(fn)) and (fbusegifspecs in memuboard.fbstat)) then begin
    getgifspecs(memuboard.dlpath+fn,sig,x,y,c);
    s:='('+cstrl(x)+'x'+cstrl(y)+','+cstr(c)+'c) ';
    f.description:=s+f.description;
    if (length(f.description)>60) then f.description:=copy(f.description,1,60);
  end;
end;

function searchfordups(completefn:astr):boolean;
var wildfn,nearfn,s:astr;
    i:integer;
    fcompleteacc,fcompletenoacc,fnearacc,fnearnoacc,
    hadacc,b1,b2:boolean;

  procedure searchb(b:integer; fn:astr; var hadacc,fcl,fnr:boolean);
  var f:ulfrec;
      oldboard,pl,rn:integer;
  begin
    oldboard:=fileboard;
    hadacc:=fbaseac(b); { loads in memuboard }
    fileboard:=b;

    recno(fn,pl,rn);
    if (badfpath) then exit;
    while (rn<=pl) and (rn<>-1) do begin
      seek(ulff,rn); read(ulff,f);
      if (align(f.filename)=align(completefn)) then fcl:=TRUE
      else begin
        nearfn:=align(f.filename);
        fnr:=TRUE;
      end;
      nrecno(fn,pl,rn);
    end;
    close(ulff);
    fileboard:=oldboard;
    fiscan(pl);
  end;

begin
  spstr(132);

  searchfordups:=TRUE;

  wildfn:=copy(align(completefn),1,9)+'???';
  fcompleteacc:=FALSE; fcompletenoacc:=FALSE;
  fnearacc:=FALSE; fnearnoacc:=FALSE;
  b1:=FALSE; b2:=FALSE;

  i:=0;
  while (i<=maxulb) do begin
    searchb(i,wildfn,hadacc,b1,b2); { fbaseac loads in memuboard ... }
    loaduboard(i);
    if (b1) then begin
      s:='User tried upload "'+sqoutsp(completefn)+'" to #'+cstr(fileboard)+
         '; existed in #'+cstr(i);
      if (not hadacc) then s:=s+' - no access to';
      sysoplog(s);
      spstr(134);
      clearwaves;
      addwave('FN',sqoutsp(completefn),txt);
      if (hadacc) then
      begin
        addwave('BN',memuboard.name,txt);
        addwave('B#',cstr(i),txt);
        spstr(340);
      end else
        spstr(341);
      clearwaves;
      exit;
    end;
    if (b2) then begin
      s:='User entered upload filename "'+sqoutsp(completefn)+'" in #'+
         cstr(fileboard)+'; was warned that "'+sqoutsp(nearfn)+
         '" existed in #'+cstr(i)+'.';
      if (not hadacc) then s:=s+' - no access to';
      sysoplog(s);
      addwave('FN',sqoutsp(completefn),txt);
      if (hadacc) then
      begin
        addwave('BN',memuboard.name,txt);
        addwave('B#',cstr(i),txt);
        spstr(342);
      end else
        spstr(343);
      clearwaves;
      searchfordups:=not pynq(getstr(344));
      exit;
    end;
    inc(i);
  end;

  spstr(133);
  searchfordups:=FALSE;
end;

procedure ul(var abort:boolean; fn:astr; var addbatch:boolean);
var baf:text;
    fi:file of byte;
    f,f1:ulfrec;
    wind:windowrec;
    v:verbrec;
    s:astr;
    xferstart,xferend,tooktime,ulrefundgot1,convtime1:datetimerec;
    ulrefundgot,convtime,rfpts,tooktime1:real;
    cps,lng,origblocks:longint;
    x,rn,pl,cc,oldboard,np,sx,sy,gotpts:integer;
    c:char;
    uls,ok,kabort,convt,aexists,resumefile,wenttosysop,offline:boolean;
    oldwhereuser:string[20];
begin
  oldboard:=fileboard;
  fiscan(pl);
  if (baddlpath) then exit;

  uls:=incom; ok:=TRUE; fn:=align(fn); rn:=0; ok:=TRUE;
  for x:=1 to length(fn) do
    if (pos(fn[x],'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ. !-@#$%^&()_{}''~`')=0) then ok:=FALSE;
  if (fn[1]=' ') or (fn[10]=' ') then ok:=FALSE;
  np:=0;
  for x:=1 to length(fn) do if (fn[x]='.') then inc(np);
  if (np>1) then ok:=FALSE;
  if (not ok) then begin
    spstr(134);
    exit;
  end;

  {* aexists:    if file already EXISTS in dir
     rn:         rec-num of file if already EXISTS in file listing
     resumefile: if user is going to RESUME THE UPLOAD
     uls:        whether file is to be actually UPLOADED
     offline:    if uploaded a file to be offline automatically..
  *}

  resumefile:=FALSE; uls:=TRUE; offline:=FALSE; abort:=FALSE;
  aexists:=exist(memuboard.dlpath+fn);

  recno(fn,pl,rn);
  if (baddlpath) then exit;
  nl;
  if (rn<>-1) then begin
    seek(ulff,rn); read(ulff,f);
    resumefile:=(resumelater in f.filestat);
    if (resumefile) then begin
      spstr(345);
      resumefile:=((f.owner=usernum) or (fso));
      if (resumefile) then begin
        if (not incom) then begin
          spstr(346);
          exit;
        end;
        dyny:=TRUE;
        clearwaves;
        addwave('FN',sqoutsp(fn),txt);
        resumefile:=pynq(getstr(347));
        clearwaves;
        if (not resumefile) then exit;
      end else begin
        spstr(348);
        exit;
      end;
    end;
  end;
  if ((not aexists) and (not incom)) then begin
    uls:=FALSE;
    offline:=TRUE;
    spstr(349);
    if not pynq(getstr(350)) then exit;
  end;
  if (not resumefile) then begin
    if (((aexists) or (rn<>-1)) and (not fso)) then begin
      spstr(351);
      exit;
    end;
    if (pl>=memuboard.maxfiles) then begin
      spstr(352);
      exit;
    end;
    if (not aexists) and (not offline) and
       (freek(exdrv(memuboard.dlpath))<=systat^.minspaceforupload)
    then begin
      spstr(353);
      c:=chr(exdrv(memuboard.dlpath)+64);
      if c='@' then
        sysoplog('|R>>|w Main BBS drive full!  Insufficient space to upload a file!')
      else
        sysoplog('|R>>|w '+c+': drive full!  Insufficient space to upload a file!');
      exit;
    end;
    if (aexists) then begin
      uls:=FALSE;
      clearwaves;
      addwave('FN',sqoutsp(memuboard.dlpath+fn),txt);
      spstr(354);
      clearwaves;
      if (rn<>-1) then spstr(355);
      dyny:=(rn=-1);
      if (locbatup) then begin
        spstr(356);
        onekcr:=FALSE; onekda:=FALSE;
        onek(c,'QYN'^M);
        if (rn<>-1) then ok:=(c='Y') else ok:=(c in ['Y',^M]);
        abort:=(c='Q');
        if (abort) then spstr(357) else
          if (not ok) then spstr(359) else spstr(358);
      end else
        ok:=pynq(getstr(360));
      rn:=-1;
    end;

    if ((systat^.searchdup) and (ok) and (not abort) and (incom)) then
      if (searchfordups(fn)) then exit;

    if (uls) then begin
      dyny:=TRUE;
      clearwaves;
      addwave('FN',sqoutsp(fn),txt);
      ok:=pynq(getstr(361));
      clearwaves;
    end;
    if ((ok) and (uls) and (not resumefile)) then begin
      assign(fi,memuboard.dlpath+fn);
      {$I-} rewrite(fi); {$I+}
      if ioresult<>0 then begin
        {$I-} close(fi); {$I+}
        cc:=ioresult;
        ok:=FALSE;
      end else begin
        close(fi);
        erase(fi);
        ok:=TRUE;
      end;
      if (not ok) then begin
        spstr(362);
        exit;
      end;
    end;
  end;

  if (not ok) then exit;
  wenttosysop:=TRUE;
  if (not resumefile) then begin
    f.filename:=align(fn);
    dodescrs(f,v,pl,wenttosysop);
  end;
  ok:=TRUE;
  if (uls) then begin
    showuserfileinfo;

    oldwhereuser:=thisnode.whereuser;
    thisnode.whereuser:=getstr(363);
    savenode;

    getdatetime(xferstart);
    receive1(memuboard.dlpath+fn,resumefile,ok,kabort,addbatch);

    if (addbatch) then begin
      inc(numubatchfiles);
      ubatch[numubatchfiles].fn:=sqoutsp(fn);
      with ubatch[numubatchfiles] do begin
        section:=fileboard;
        description:=f.description;
        if (v.descr[1]<>'') then begin
          inc(hiubatchv);
          new(ubatchv[hiubatchv]);    {* define dynamic memory *}
          ubatchv[hiubatchv]^:=v;
          vr:=hiubatchv;
        end else
          vr:=0;
      end;
      clearwaves;
      addwave('B#',cstr(numubatchfiles),txt);
      spstr(364);
      spstr(365);
      fileboard:=oldboard;
      thisnode.whereuser:=oldwhereuser;
      savenode;
      exit;
    end else begin
      getdatetime(xferend);
      timediff(tooktime,xferstart,xferend);
      thisnode.whereuser:=oldwhereuser;
      savenode;
    end;

    if (kabort) then begin
      fileboard:=oldboard;
      exit;
   end;

    ulrefundgot:=(dt2r(tooktime))*(systat^.ulrefund/100.0);
    freetime:=freetime+ulrefundgot;
    clearwaves;
    addwave('TR',ctim(ulrefundgot),txt);
    spstr(366);
    clearwaves;

    showuserfileinfo;

    if (not kabort) then spstr(367);
  end;
  nl;

  if (not offline) then begin
    assign(fi,memuboard.dlpath+fn);
    SetFileaccess(readonly,denynone);
    {$I-} reset(fi); {$I+}
    if (ioresult<>0) then ok:=FALSE
    else begin
      f.blocks:=trunc((filesize(fi)+127.0)/128.0);
      close(fi);
      if (f.blocks=0) then ok:=FALSE;
      origblocks:=f.blocks;
    end;
  end;

  if ((ok) and (not offline)) then begin
    convt:=TRUE;
    arcstuff(ok,convt,f.blocks,convtime,uls,memuboard.dlpath,fn,f,v);
    doffstuff(f,fn,gotpts);

    if (ok) then begin
      if ((not resumefile) or (rn=-1)) then newff(f,v) else writefv(rn,f,v);

      if (uls) then begin
        if (aacs(systat^.ulvalreq)) then begin
          inc(thisuser.uploads);
          inc(thisuser.uk,f.blocks div 8);
        end;
        readsystat;
        inc(systat^.todayzlog.uploads);
        inc(systat^.todayzlog.uk,f.blocks div 8);
        savesystat;
      end;

      s:='|CUpload "'+sqoutsp(fn)+'" on '+memuboard.name;
      if (uls) then begin
        tooktime1:=dt2r(tooktime);
        if (tooktime1>=1.0) then begin
          cps:=f.blocks; cps:=cps*128;
          cps:=trunc(cps/tooktime1);
        end else
          cps:=0;
        s:=s+'|C ('+cstr(f.blocks div 8)+'k, '+ctim(tooktime1)+
             ', '+cstr(cps)+' cps)';
      end;
      sysoplog(s);
      if ((incom) and (uls)) then begin
        if (convt) then begin
          lng:=origblocks*128;
          clearwaves;
          addwave('FS',cstrl(lng),txt);
          spstr(368);
        end;
        lng:=f.blocks; lng:=lng*128;
        clearwaves;
        addwave('FS',cstrl(lng),txt);
        if (convt) then spstr(369) else spstr(370);
        clearwaves;
        addwave('UT',longtim(tooktime),txt);
        spstr(371);
        r2dt(convtime,convtime1);
        if (convt) then
        begin
          clearwaves;
          addwave('CT',longtim(convtime1),txt);
          spstr(372);
        end;
        clearwaves;
        addwave('CS',cstr(cps),txt);
        spstr(373);
        r2dt(ulrefundgot,ulrefundgot1);
        clearwaves;
        addwave('TR',longtim(ulrefundgot1),txt);
        spstr(374);
        if (gotpts<>0) then
        begin
          clearwaves;
          addwave('FP',cstr(gotpts),txt);
          spstr(375);
        end;
        if (choptime<>0.0) then begin
          choptime:=choptime+ulrefundgot;
          freetime:=freetime-ulrefundgot;
          spstr(549);
        end;
        doul(gotpts);
      end
      else spstr(376);
      clearwaves;
    end;
  end;
  if (not ok) and (not offline) then begin
    if (exist(memuboard.dlpath+fn)) then begin
      spstr(377);
      s:='file deleted';
      if ((thisuser.sl>0 {systat.minresumelatersl} ) and
          (f.blocks div 8>systat^.minresume)) then begin
        dyny:=TRUE;
        if pynq(getstr(378)) then begin
          doffstuff(f,fn,gotpts);
          include(f.filestat,resumelater);
          if (not aexists) or (rn=-1) then newff(f,v) else writefv(rn,f,v);
          s:='file saved for later resume';
        end;
      end;
      if (not (resumelater in f.filestat)) then begin
        if (exist(memuboard.dlpath+fn)) then begin
          assign(fi,memuboard.dlpath+fn);
          {$I-} erase(fi); {$I+}
        end;
      end;
      sysoplog('|CError uploading "'+sqoutsp(fn)+'" - '+s);
    end;
    clearwaves;
    addwave('TR',ctim(ulrefundgot),txt);
    spstr(379);
    clearwaves;
    freetime:=freetime-ulrefundgot;
  end;
  if (offline) then begin
    f.blocks:=10;
    doffstuff(f,fn,gotpts);
    include(f.filestat,isrequest);
    newff(f,v);
  end;
  close(ulff);
  fileboard:=oldboard;
  fiscan(pl); close(ulff);
end;

procedure iul;
var s,xxz:astr;
    pl:integer;
    c:char;
    xxy:byte;
    abort,done,addbatch:boolean;
    I:integer;

function ok_to_ul(s:astr):boolean;
var ss:astr;
begin
ok_to_ul:=TRUE; I:=pos('.',s); if i=0 then ss:=copy(s,1,8) else ss:=copy(s,1,i-1);
if (ss='CON') or (ss='AUX') or (ss='COM1') or (ss='COM2') or (ss='COM3') or
   (ss='COM4') or (ss='LPT1') or (ss='LPT2') or (ss='COM') or (ss='LPT') or
   (ss='PRN') or (ss='NUL') or (ss='LPT3') then begin
   ok_to_ul:=FALSE;
   sysoplog('|RTried to transfer a device!!');
   spstr(331);
   end;
   end;

begin
  fiscan(pl);
  if (baddlpath) then exit;
  if (not aacs(memuboard.ulacs)) then begin
    spstr(380);
    exit;
  end;
  locbatup:=FALSE;
  repeat
    spstr(106);
    done:=TRUE; addbatch:=FALSE;
    mpl(12); input(s,12); s:=sqoutsp(s);
    if not(ok_to_ul(s)) then hangup:=TRUE;

    if ((s<>'') and (ok_to_ul(s))) then
      if (not fso) then ul(abort,s,addbatch)
      else begin
        if (not iswildcard(s)) then ul(abort,s,addbatch)
        else begin
          locbatup:=TRUE;
          ffile(memuboard.dlpath+s);
          if (not found) then spstr(111) else
            repeat
              if not ((dirinfo.attr and VolumeID=VolumeID) or
                      (dirinfo.attr and Directory=Directory)) then
                ul(abort,dirinfo.name,addbatch);
              nfile;
            until (not found) or (abort);
        end;
      end;
    done:=(not addbatch);
  until (done) or (hangup);
end;

procedure fbaselist;
var s,os:astr;
    onlin,nd,b,b2,i:integer;
    abort,next,acc,showtitles:boolean;

 procedure shortlist;
  begin
    printf('farealst');
    while (b<=maxulb) and (not abort) do begin
      acc:=fbaseac(b); { fbaseac will load memuboard }
      if ((fbunhidden in memuboard.fbstat) or (acc)) then begin
        if (acc) then begin
          s:='|W';
          b2:=ccuboards[1][b];
          if (b2<10) then s:=s+' '; s:=s+cstr(b2)+'|w: |W';
          if (b in zscanr.fzscan) then s:=s+'*' else s:=s+' ';
          if (fbusegifspecs in memuboard.fbstat) then s:=s+'g ' else s:=s+'  ';
        end else
          s:='       ';
        s:=s+'|Y'+memuboard.name;
        if (fbnoratio in memuboard.fbstat) then s:=s+'|Y <NR>';
        inc(onlin); inc(nd);
        if (onlin=1) then begin
          if (thisuser.linelen>=80) and (b<maxulb) and (lenn(s)>40) then
            s:=mln(s,40);
          sprompt(s); os:=s;
        end else begin
          i:=40-lenn(os); os:='';
          if (thisuser.linelen>=80) then begin
            while (lenn(os)<i) do os:=os+' ';
            if (lenn(s)>38) then s:=mln(s,38);
          end else
            nl;
          sprint(os+s);
          onlin:=0;
        end;
        if (not empty) then wkey(abort,next);
      end;
      inc(b);
    end;
    if (onlin=1) and (thisuser.linelen>=80) then nl;
  end;

begin
  nl;
  abort:=FALSE;
  onlin:=0; s:=''; b:=0; nd:=0;
  shortlist;
  if (nd=0) then spstr(381);
end;

procedure unlisted_download(s:astr);
var dok,kabort:boolean;
    pl,oldnumbatchfiles,oldfileboard:integer;
begin
  if (s<>'') then begin
    if (not exist(s)) then spstr(382)
    else if (iswildcard(s)) then spstr(383)
      else begin
        oldnumbatchfiles:=numbatchfiles;
        oldfileboard:=fileboard; fileboard:=-1;
        send1(s,dok,kabort);
        if (numbatchfiles=oldnumbatchfiles) and (dok) and (not kabort) then
          dodl(systat^.unlistfp);
        fileboard:=oldfileboard;
      end;
  end;
end;

procedure do_unlisted_download;
var s:astr;
begin
  spstr(384);
  mpl(78); input(s,78);
  unlisted_download(s);
end;

function nfvpointer:longint;
var i,x:integer;
    v:verbrec;
    vfo:boolean;
begin
  vfo:=(filerec(verbf).mode<>fmclosed);
  if (not vfo) then begin
    SetFileaccess(readonly,denynone);
    reset(verbf);
  end;
  x:=filesize(verbf);
  for i:=0 to filesize(verbf)-1 do begin
    seek(verbf,i); read(verbf,v);
    if (v.descr[1]='') then x:=i;
  end;
  if (not vfo) then close(verbf);
  nfvpointer:=x;
end;

end.
