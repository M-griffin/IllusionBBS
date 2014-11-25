(*****************************************************************************)
(* Illusion BBS - File routines  [8/15]                                      *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit Mfile8;

interface

uses
  crt, dos,
  myio, execbat, common, common2, 
  Mfile0, Mfile1, Mfile6, Mfile7;

procedure purgedir2(s:astr);                {* erase all non-dir files in dir *}
procedure ymbadd(fname:astr);
procedure tagfile(fname:astr);
procedure send1(fn:astr; var dok,kabort:boolean);
procedure receive1(fn:astr; resumefile:boolean; var dok,kabort,addbatch:boolean);
function checkfileratio:integer;

implementation


procedure purgedir2(s:astr);                {* erase all non-dir files in dir *}
var odir,odir2:astr;
    dirinfo:searchrec;
    f:file;
    att:word;
begin
  s:=fexpand(s);
  while copy(s,length(s),1)='\' do s:=copy(s,1,length(s)-1);
  getdir(0,odir); getdir(exdrv(s),odir2);
  chdir(s);
  findfirst('*.*',AnyFile-Directory-VolumeID,dirinfo);
  while (doserror=0) do begin
    assign(f,fexpand(dirinfo.name));
    setfattr(f,$00);           {* remove possible read-only, etc, attributes *}
    {$I-} erase(f); {$I+}      {* erase the $*@( file !!     *}
    findnext(dirinfo);         {* move on to the next one... *}
  end;
  chdir(odir2); chdir(odir);
end;

procedure abeep;
var a,b,c,i,j:integer;
begin
  for j:=1 to 3 do begin
    for i:=1 to 3 do begin
      a:=i*500;
      b:=a;
      while (b>a-300) do begin
{       sound(b); }
        dec(b,50);
        c:=a+1000;
        while (c>a+700) do begin
        { sound(c);}dec(c,50);
          delay(2);
        end;
      end;
    end;
    delay(50);
    nosound;
  end;
end;

function checkfileratio:integer;
var i,r,t:real;
    j:integer;
    badratio:boolean;
begin
  t:=thisuser.dk;
  if (numbatchfiles<>0) then
    for j:=1 to numbatchfiles do begin
      loaduboard(batch[j].section);
      if (not (fbnoratio in memuboard.fbstat)) then
        t:=t+(batch[j].blks div 8);
    end;
  badratio:=FALSE;
  r:=(t+0.001)/(thisuser.uk+0.001);
  if (r>systat^.dlkratio[thisuser.sl]) then badratio:=TRUE;
  i:=(thisuser.downloads+numbatchfiles+0.001)/(thisuser.uploads+0.001);
  if (i>systat^.dlratio[thisuser.sl]) then badratio:=TRUE;
  if ((aacs(systat^.nodlratio)) or (fnodlratio in thisuser.ac)) then
    badratio:=FALSE;
  if (not systat^.uldlratio) then badratio:=FALSE;
  checkfileratio:=0;
  if (badratio) then
    if (numbatchfiles=0) then checkfileratio:=1 else checkfileratio:=2;
  loaduboard(fileboard);
  if (fbnoratio in memuboard.fbstat) then checkfileratio:=0;
end;

procedure ymbadd(fname:astr);
var t1,t2:real;
    f:file of byte;
    ff:ulfrec;
    sof:longint;
    ior:word;
    slrn,rn,pl:integer;
    fblks:longint;
    slfn:astr;
    ffo:boolean;
begin
  ffo:=(filerec(ulff).mode<>fmclosed);
  fname:=sqoutsp(fname);
  if (exist(fname)) then begin
    assign(f,fname); SetFileAccess(ReadOnly,DenyNone); reset(f);
    sof:=filesize(f);
    fblks:=trunc((sof+127.0)/128.0);
    t1:=rte*fblks;
    close(f);
    t2:=batchtime+t1;
    if (t2>nsl) then spstr(142)
    else
    if (numbatchfiles=maxbatchfiles) then spstr(143)
    else begin
      inc(numbatchfiles);
      with batch[numbatchfiles] do begin
        if (fileboard<>-1) then begin
          slrn:=lrn; slfn:=lfn;
          if ffo then close(ulff);
          recno(stripname(fname),pl,rn);
          seek(ulff,rn); read(ulff,ff);
          close(ulff);
          if ffo then fiscan(pl);
          lrn:=slrn; lfn:=slfn;
          pts:=ff.filepoints;
          blks:=ff.blocks;
        end else begin
          pts:=systat^.unlistfp;
          blks:=fblks;
        end;

        if (thisuser.filepoints<pts) and (pts>0) and
        (not aacs(systat^.nofilepts)) and
        (not (fnofilepts in thisuser.ac)) and
        (not (fbnoratio in memuboard.fbstat)) then
        begin
          spstr(118);
          sysoplog('Tried to add '+stripname(fn)+' to batch d/l.  Not enough file pts.');
          delbatch(numbatchfiles);
          exit;
        end;

        fn:=sqoutsp(fname);
        tt:=t1;
        section:=fileboard;
        batchtime:=t2;

        sysoplog('Added '+stripname(fn)+' to batch queue.');
        clearwaves;
        addwave('FN',stripname(fn),txt);
        spstr(115);
        clearwaves;
      end;
    end;
  end else
    spstr(412);
end;

procedure tagfile(fname:astr);
var fn:astr;
    pl,rn:integer;
    f:ulfrec;
begin
  if (fname='') then
  begin
    spstr(611);
    mpl(12); input(fn,12);
  end else
    fn:=fname;
  recno(fn,pl,rn);
  if (baddlpath) then exit;
  if (rn=-1) then
    spstr(330)
  else
    while (rn<>-1) do
    begin
      setfileaccess(readwrite,denynone);
      reset(ulff);
      seek(ulff,rn); read(ulff,f);
      if (okdl(f)) then ymbadd(memuboard.dlpath+f.filename);
      nrecno(fn,pl,rn);
    end;
  setfileaccess(readonly,denynone); reset(uf); close(uf);
  close(ulff);
end;

procedure addtologupdown;
var s:astr;
begin
  s:='  ULs: '+cstr(trunc(thisuser.uk))+'k in '+cstr(thisuser.uploads)+' file';
  if thisuser.uploads<>1 then s:=s+'s';
  s:=s+'  -  DLs: '+cstr(trunc(thisuser.dk))+'k in '+cstr(thisuser.downloads)+' file';
  if thisuser.downloads<>1 then s:=s+'s';
  sysoplog(s);
end;

procedure send1(fn:astr; var dok,kabort:boolean);
var f:text;
    ff:file;
    f1:ulfrec;
    nfn,cp,slfn,s:astr;
    st:real;
    filsize:longint;
    dcode:word; { dos exit code }
    p,i,sx,sy,t,pl,rn,slrn,errlevel:integer;
    g,c:char;
    b,done1,foundit:boolean;
begin
  done1:=FALSE;
  SetFileAccess(ReadOnly,DenyNone);
  reset(xf);
    repeat
      spstr(116); mpkey(s);
      if (s='?') then begin
        nl;
        showprots(FALSE,TRUE,FALSE,FALSE);
      end else begin
        p:=findprot(s,FALSE,TRUE,FALSE,FALSE);
        if (p=-99) then print('Invalid entry.') else
          if ((p=-12) and (isqwk)) then sprint('Batch unavailable for downloading QWK packets.')
            else done1:=TRUE;
      end;
    until (done1) or (hangup);

  dok:=TRUE; kabort:=FALSE;
  if (-p in [1,2,3,4,12]) or (p in [1..200]) and (not isqwk) then
    case checkfileratio of
      1:begin
          spstr(109);
          sysoplog('LEECH - D/L ratio bad');
          addtologupdown;
          p:=-11;
        end;
      2:begin
          spstr(109);
          sysoplog('Tried to add to batch queue while ratio out of balance:');
          addtologupdown;
          p:=-11;
        end;
    end;
  if (p>=0) then begin seek(xf,p); read(xf,protocol); end;
  close(xf);
  lastprot:=p;
  case p of
   -12:ymbadd(fn);
   -11:;
   -10:begin dok:=FALSE; kabort:=TRUE; end;
(*   -4:if (incom) then send(TRUE,TRUE,fn,dok,kabort,FALSE,rte);
   -3:if (incom) then send(FALSE,TRUE,fn,dok,kabort,FALSE,rte);
   -2:if (incom) then send(FALSE,FALSE,fn,dok,kabort,FALSE,rte);*)
   -1:sendascii(fn);
(*   -2:if (not trm) then begin
        assign(f,fn);
        SetFileAccess(ReadOnly,DenyNone);
        {$I-} reset(f); {$I+}
        if (ioresult<>0) then spstr(330)
        else begin
          kabort:=FALSE;
          clrscr;
          sx:=wherex; sy:=wherey;
          window(1,25,80,25);
          tc(11); textbackground(1);
          gotoxy(1,1);
          for t:=1 to 80 do write(' ');
          gotoxy(1,1);
          write('Sending ASCII File '+fn+' -- Please Wait');
          tc(7); textbackground(0);
          window(1,1,80,24);
          gotoxy(sx,sy);
          repeat
            read(f,g);
            o(g); write(g);
          until (eof(f)) or (kabort);
          close(f);
        end;
      end;*)
  else
      if (incom) then begin
        cp:=bproline1(systat^.protpath+protocol.dlcmd);
        bproline(cp,sqoutsp(fn));

        if (useron) then spstr(414);
        if (useron) then shel(caps(thisuser.name)+' is downloading!') else
                       shel('Sending file(s)...');
        systat^.swapshell:=systat^.swapshell and systat^.swapxfer;
        pexecbatch(FALSE,'isnd'+cstr(nodenum)+'.bat','',start_dir,cp,errlevel);
        readsystat;
        shel2;

        foundit:=FALSE; i:=0;
        while ((i<6) and (not foundit)) do begin
          inc(i);
          if (value(protocol.dlcode[i])=errlevel) then foundit:=TRUE;
        end;

        dok:=TRUE;
        if ((foundit) and (not (xbxferokcode in protocol.xbstat))) then dok:=FALSE;
        if ((not foundit) and (xbxferokcode in protocol.xbstat)) then dok:=FALSE;
      end;
  end;
  if (not useron) and (not kabort) then begin
    cursoron(FALSE);
    setwindow(wind,25,8,55,12,4,0,1);
    gotoxy(5,2); tc(14);
    if dok then write('Transfer successful.') else
                write('Transfer unsuccessful.');
    st:=timer;
    while (not keypressed) and (tcheck(st,3)) do abeep;
    if keypressed then c:=readkey;
    removewindow(wind);
    cursoron(TRUE);
    incom:=FALSE; outcom:=FALSE;
  end;
end;

procedure receive1(fn:astr; resumefile:boolean; var dok,kabort,addbatch:boolean);
var cp,nfn,s:astr;
    st:real;
    filsize:longint;
    p,i,t,fno,sx,sy,nof,errlevel:integer;
    c:char;
    b,done1,foundit:boolean;
begin
  done1:=FALSE;
  SetFileAccess(ReadOnly,DenyNone);
  reset(xf);
  repeat
    spstr(116); mpkey(s);
    if (s='?') then begin
      nl;
      showprots(TRUE,FALSE,FALSE,resumefile);
    end else begin
      p:=findprot(s,TRUE,FALSE,FALSE,resumefile);
      if (p=-99) then print('Invalid entry.') else done1:=TRUE;
    end;
  until (done1) or (hangup);

  if (not useron) then begin incom:=TRUE; outcom:=TRUE; end;
  dok:=TRUE; kabort:=FALSE;
  if (p>=0) then begin seek(xf,p); read(xf,protocol); end;
  close(xf);
  case p of
   -12:addbatch:=TRUE;
   -11,-10:begin dok:=FALSE; kabort:=TRUE; end;
   -1:recvascii(fn,dok,rte);
  else
      if (incom) then begin
        cp:=bproline1(systat^.protpath+protocol.ulcmd);
        bproline(cp,sqoutsp(fn));

        if (useron) then spstr(415);
        if (useron) then shel(caps(thisuser.name)+' is uploading!') else
                       shel('Receiving file(s)...');
        systat^.swapshell:=systat^.swapshell and systat^.swapxfer;
        pexecbatch(FALSE,'isnd'+cstr(nodenum)+'.bat','',start_dir,cp,errlevel);
        readsystat;
        shel2;

        foundit:=FALSE; i:=0;
        while ((i<6) and (not foundit)) do begin
          inc(i);
          if (value(protocol.ulcode[i])=errlevel) then foundit:=TRUE;
        end;

        dok:=TRUE;
        if ((foundit) and (not (xbxferokcode in protocol.xbstat))) then dok:=FALSE;
        if ((not foundit) and (xbxferokcode in protocol.xbstat)) then dok:=FALSE;
      end;
  end;
  if (not useron) and (not kabort) then begin
    cursoron(FALSE);
    setwindow(wind,25,8,55,12,4,0,1);
    gotoxy(5,2); textcolor(14);
    if (dok) then write('Transfer successful.') else
      write('Transfer unsuccessful.');
    st:=timer;
    while (not keypressed) and (tcheck(st,3)) do abeep;
    if (keypressed) then c:=readkey;
    removewindow(wind);
    cursoron(TRUE);
    incom:=FALSE; outcom:=FALSE;
  end;
end;

end.
