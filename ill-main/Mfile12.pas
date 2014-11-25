(*****************************************************************************)
(* Illusion BBS - File routines  [12/15] (batch functions)                   *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit Mfile12;

interface

uses
  crt,dos,
  Mfile0, Mfile1, Mfile2, Mfile4, Mfile6, Mfile9,
  execbat,
  mmodem,
  common, common2;

procedure delubatch(n:integer);
procedure listubatchfiles;
procedure removeubatchfiles;
procedure clearubatch;
procedure batchul;
procedure batchinfo;

implementation

procedure delubatch(n:integer);
var c:integer;
begin
  if ((n>=1) and (n<=numubatchfiles)) then begin
    if (n<>numubatchfiles) then
      for c:=n to numubatchfiles-1 do ubatch[c]:=ubatch[c+1];
    dec(numubatchfiles);
  end;
end;

procedure listubatchfiles;
var s,s1:astr;
    i,j:integer;
    abort,next,vfo:boolean;
begin
  if (numubatchfiles=0) then begin
    nl; sprint('|CUpload batch queue empty.');
  end else begin
    abort:=FALSE; next:=FALSE;
    nl;
    printacr('|B##:Filename.Ext Area Description',abort,next);
    printacr('|B컴컴컴컴컴컴컴� 컴컴 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�',abort,next);

    i:=1;
    while ((not abort) and (i<=numubatchfiles) and (not hangup)) do begin
      with ubatch[i] do begin
        if (section=systat^.tosysopdir) then s1:='|RSysp'
          else s1:=mrn(cstr(section),4);
        s:='|C'+mn(i,2)+'|B:|Y'+align(fn)+' '+s1+' '+
           '|C'+mln(description,55);
        printacr(s,abort,next);
        if (vr<>0) then
          if (ubatchv[vr]^.descr[1]<>'') then begin
            vfo:=(filerec(verbf).mode<>fmclosed);
            if (not vfo) then begin
              SetFileAccess(ReadOnly,DenyNone);
              reset(verbf);
            end;
            if (ioresult=0) then
              for j:=1 to 9 do
                if ubatchv[vr]^.descr[j]='' then j:=9 else
                  printacr('                         |b:|B'+
                           ubatchv[vr]^.descr[j],abort,next);
            if (not vfo) then close(verbf);
          end;
      end;
      inc(i);
    end;

    printacr('|B컴컴컴컴컴컴컴� 컴컴 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�',abort,next);
  end;
end;

procedure removeubatchfiles;
var s:astr;
    i:integer;
begin
  if (numubatchfiles=0) then begin
    nl; sprint('|CUpload batch queue empty.');
  end else
    repeat
      nl;
      prt('File # to remove (1-'+cstr(numubatchfiles)+') (?=list) : ');
      input(s,2); i:=value(s);
      if (s='?') then listubatchfiles;
      if ((i>0) and (i<=numubatchfiles)) then begin
        print('"'+stripname(ubatch[i].fn)+'" deleted out of upload queue.');
        delubatch(i);
      end;
      if (numubatchfiles=0) then sprint('|CUpload queue now empty.');
    until (s<>'?');
end;

procedure clearubatch;
begin
  nl;
  if pynq('Clear upload queue') then begin
    numubatchfiles:=0;
    sprint('|CUpload queue now empty.');
  end;
end;

procedure batchul;
var fi:file of byte;
    dirinfo:searchrec;
    f:ulfrec;
    v:verbrec;
    xferstart,xferend,tooktime,takeawayulrefundgot1,ulrefundgot1:datetimerec;
    tconvtime1,st1:datetimerec;
    pc,fn,s:astr;
    st,tconvtime,convtime,ulrefundgot,takeawayulrefundgot:real;
    blks,totb,totfils,totb1,totfils1,cps,lng,totpts:longint;
    i,p,pl,dbn,gotpts,ubn,filsuled,oldboard,passn:integer;
    c:char;
    abort,hua,ahangup,next,done,dok,kabort,wenttosysop,ok,convt,
      beepafter,dothispass,fok,nospace,savpause:boolean;
    oldwhereuser:string[20];

  function notinubatch(fn:astr):boolean;
  var i:integer;
  begin
    notinubatch:=FALSE;
    for i:=1 to numubatchfiles do
      if (sqoutsp(fn)=sqoutsp(ubatch[i].fn)) then exit;
    notinubatch:=TRUE;
  end;

  function ubatchnum(fn:astr):integer;
  var i:integer;
  begin
    fn:=sqoutsp(fn);
    ubatchnum:=0;
    for i:=1 to numubatchfiles do
      if (fn=sqoutsp(ubatch[i].fn)) then ubatchnum:=i;
  end;

  function plural:string;
  begin
    if (totfils<>1) then plural:='s' else plural:='';
  end;

begin
  savpause:=(pause in thisuser.ac);
  if (savpause) then exclude(thisuser.ac,pause);

  oldboard:=fileboard;
  beepafter:=FALSE; done:=FALSE;
  nl;
  if (numubatchfiles=0) then printf('batchul0') else printf('batchul');
  SetFileAccess(ReadOnly,DenyNone);
  reset(xf);
  done:=FALSE;
  repeat
    spstr(117); mpkey(s);
    if (s='?') then begin
      nl;
      showprots(TRUE,FALSE,TRUE,FALSE);
    end else begin
      p:=findprot(s,TRUE,FALSE,TRUE,FALSE);
      if (p=-99) then print('Wrong!') else done:=TRUE;
    end;
  until (done) or (hangup);
  if (p<>-10) then begin
    seek(xf,p); read(xf,protocol); close(xf);
    hua:=pynq(getstr(140));
    dok:=TRUE;

    dyny:=TRUE;
    beepafter:=pynq(getstr(419));

    lil:=0;
    if (useron) then spstr(420);
    lil:=0;

    oldwhereuser:=thisnode.whereuser;
    thisnode.whereuser:=getstr(363);
    savenode;

    getdatetime(xferstart);
    if (useron) then shel(caps(thisuser.name)+' is batch uploading!')
                else shel('Receiving file(s)...');
    systat^.swapshell:=systat^.swapshell and systat^.swapxfer;
    execbatch(dok,FALSE,'ircv'+cstr(nodenum)+'.bat','',modemr.temppath+'UPLOAD\',
              bproline1(systat^.protpath+protocol.ulcmd),-1);
    readsystat;
    shel2;
    getdatetime(xferend);
    timediff(tooktime,xferstart,xferend);

    thisnode.whereuser:=oldwhereuser;
    savenode;

    ulrefundgot:=(dt2r(tooktime))*(systat^.ulrefund/100.0);
    freetime:=freetime+ulrefundgot;

    showuserfileinfo;

    {*****}

    lil:=0;
    nl;
    nl;
    star('Batch upload transfer complete.');
    nl;
    lil:=0;

    tconvtime:=0.0; takeawayulrefundgot:=0.0;
    totb:=0; totfils:=0; totb1:=0; totfils1:=0; totpts:=0;

    findfirst(modemr.temppath+'UPLOAD\*.*',anyfile-directory-volumeid,dirinfo);
    while (doserror=0) do begin
      inc(totfils1);
      inc(totb1,dirinfo.size);
      findnext(dirinfo);
    end;
    cps:=trunc(totb1/dt2r(tooktime));

    abort:=FALSE; next:=FALSE;

    if (totfils1=0) then begin
      star('No files detected!  Transfer aborted.');
      exit;
    end;

    if hua then
    begin
      lil:=0;
      nl;
      nl;
      sprint('|cSystem will automatically hang up in 30 seconds.');
      sprint('|cHit |K[|CH|K]|c to hang up now, any other key to abort.');
      st:=timer;
      while (tcheck(st,30)) and (empty) do;
      if (empty) then hangup:=TRUE;
      if (not empty) then
        if (upcase(inkey)='H') then hangup:=TRUE;
      lil:=0;
    end;

    ahangup:=FALSE;
    if (hangup) then begin
      if (spd<>'KB') then begin
        commandline('Hanging up and taking phone off hook...');
        dophonehangup(FALSE);
        dophoneoffhook(FALSE);
        spd:='KB';
      end;
      hangup:=FALSE; ahangup:=TRUE;
    end;

    r2dt(ulrefundgot,ulrefundgot1);
    if (not ahangup) then begin
      prt('Press any key for upload stats..');
      if (beepafter) then begin
        i:=1;
        repeat
          if (s<>time) then begin prompt(^G#0#0#0^G); s:=time; inc(i); end;
        until ((i=30) or (not empty) or (hangup));
      end;
      getkey(c);
      for i:=1 to 33 do prompt(^H' '^H);

      nl;
      star('# files uploaded:   '+cstr(totfils1)+' files.');
      star('File size uploaded: '+cstrl(totb1)+' bytes.');
      star('Batch upload time:  '+longtim(tooktime)+'.');
      star('Transfer rate:      '+cstr(cps)+' cps');
      star('Time refund:        '+longtim(ulrefundgot1)+'.');
      nl;
      pausescr;
      star('Adding files to bases, please wait...');
    end;

    fiscan(pl);

    {* files not in upload batch queue are ONLY done during the first pass *}
    {* files already in the upload batch queue done during the second pass *}

    for passn:=1 to 2 do begin
      findfirst(modemr.temppath+'UPLOAD\*.*',anyfile-directory-volumeid,dirinfo);
      while (doserror=0) do begin
        fn:=sqoutsp(dirinfo.name);
        nl;
        dothispass:=FALSE;
        if (notinubatch(fn)) then begin
          ubn:=0;
          dothispass:=TRUE;
          star('"'+fn+'" - File not in upload batch queue.');

          close(ulff); fiscan(pl);
          wenttosysop:=TRUE;
          f.filename:=fn;
          dodescrs(f,v,pl,wenttosysop);
          if (ahangup) then begin
            f.description:='Uploaded without description & User Hung-up';
            f.vpointer:=-1; v.descr[1]:='';
          end;
          if (not wenttosysop) then begin
            nl;
            done:=FALSE;
            if (ahangup) then
              dbn:=oldboard
            else
              repeat
                prt('File base (?=List,#=File base) ['+cstr(ccuboards[1][oldboard])+'] : ');
                input(s,3); dbn:=ccuboards[0][value(s)];
                if (s='?') then begin fbaselist; nl; end;
                if (s='') then dbn:=oldboard;
                if (not fbaseac(dbn)) then begin
                  print('Can''t put it there.');
                  dbn:=-1;
                end else
                  loaduboard(dbn);
                  if (exist(sqoutsp(memuboard.dlpath+fn))) then begin
                    print('"'+fn+'" already exists in that directory.');
                    dbn:=-1;
                  end;
                if (dbn<>-1) and (s<>'?') then done:=TRUE;
              until ((done) or (hangup));
            fileboard:=dbn;
            nl;
          end;
        end else
          if (passn<>1) then begin
            dothispass:=TRUE;
            star('"'+fn+'" - File found.');
            ubn:=ubatchnum(fn);
            f.description:=ubatch[ubn].description;
            fileboard:=ubatch[ubn].section;
            v.descr[1]:='';
            if (ubatch[ubn].vr<>0) then v:=ubatchv[ubatch[ubn].vr]^;
            f.vpointer:=-1;
            if (v.descr[1]<>'') then f.vpointer:=nfvpointer;
            wenttosysop:=(fileboard=systat^.tosysopdir);
          end;

        if (dothispass) then begin
          if (wenttosysop) then fileboard:=systat^.tosysopdir;

          close(ulff); fiscan(pl);

          convt:=TRUE;
          arcstuff(ok,convt,blks,convtime,TRUE,modemr.temppath+'UPLOAD\',
                   fn,f,v);
          tconvtime:=tconvtime+convtime; f.blocks:=blks;
          doffstuff(f,fn,gotpts);

          fok:=TRUE;
          loaduboard(fileboard);
          if (ok) then begin
            star('Moving file to '+memuboard.name);
            sprompt('|YProgress: ');
            movefile(fok,nospace,TRUE,modemr.temppath+'UPLOAD\'+fn,memuboard.dlpath+fn);
            if (fok) then begin
              nl;
              newff(f,v);
              star('"'+fn+'" successfully uploaded.');
              sysoplog('|CBatch uploaded "'+sqoutsp(fn)+'" on '+
                       memuboard.name);
              inc(totfils);
              lng:=blks; lng:=lng*128;
              inc(totb,lng);
              inc(totpts,gotpts);
            end else begin
              star('Error moving file into directory - upload voided.');
              sysoplog('|CError moving batch upload "'+sqoutsp(fn)+'" into directory');
            end;
          end else begin
            star('Upload not received.');
            if ((thisuser.sl>0 {systat.minresumelatersl} ) and
                (f.blocks div 8>systat^.minresume)) then begin
              nl;
              dyny:=TRUE;
              if pynq('Save file for a later resume') then begin
                sprompt('|BProgress: ');
                movefile(fok,nospace,TRUE,modemr.temppath+'UPLOAD\'+fn,memuboard.dlpath+fn);
                if (fok) then begin
                  nl;
                  doffstuff(f,fn,gotpts);
                  include(f.filestat,resumelater);
                  newff(f,v);
                  s:='file saved for later resume';
                end else begin
                  star('Error moving file into directory - upload voided.');
                  sysoplog('|CError moving batch upload "'+sqoutsp(fn)+'" into directory');
                end;
              end;
            end;
            if (not (resumelater in f.filestat)) then begin
              s:='file deleted';
              assign(fi,modemr.temppath+'UPLOAD\'+fn); erase(fi);
            end;
            sysoplog('|CErrors batch uploading "'+sqoutsp(fn)+'" - '+s);
          end;

          if (not ok) then begin
            st:=(rte*f.blocks);
            takeawayulrefundgot:=takeawayulrefundgot+st;
            r2dt(st,st1);
            star('Time refund of '+longtim(st1)+' will be taken away.');
          end else
            if (ubn<>0) then delubatch(ubn);
        end;

        findnext(dirinfo);
      end;
    end;

    close(ulff);
    fileboard:=oldboard;
    fiscan(pl); close(ulff);

    nl;
    star('# files uploaded:   '+cstr(totfils1)+' files.');
    if (totfils<>totfils1) then
      star('Files successful:   '+cstr(totfils)+' files.');
    star('File size uploaded: '+cstrl(totb1)+' bytes.');
    star('Batch upload time:  '+longtim(tooktime)+'.');
    r2dt(tconvtime,tconvtime1);
    if (tconvtime<>0.0) then
      star('Total convert time: '+longtim(tconvtime1)+' (not refunded)');
    star('Transfer rate:      '+cstr(cps)+' cps');
    nl;
    r2dt(ulrefundgot,ulrefundgot1);
    star('Time refund:        '+longtim(ulrefundgot1)+'.');

    readsystat;
    inc(systat^.todayzlog.uploads,totfils);
    inc(systat^.todayzlog.uk,totb1 div 1024);
    savesystat;
    if (aacs(systat^.ulvalreq)) then begin
      if (totpts<>0) then
        star('File points:        '+cstr(totpts)+' pts.');
      star('Upload credits got: '+cstr(totfils)+' files, '+cstr(totb1 div 1024)+'k.');
      nl;
      star('Thanks for the file'+plural+', '+thisuser.name+'!');
      inc(thisuser.uploads,totfils);
      inc(thisuser.filepoints,totpts);
      thisuser.uk:=thisuser.uk+(totb1 div 1024);
    end else begin
      nl;
      sprint('|YThanks for the upload'+plural+', '+thisuser.name+'!');
      sprompt('|YYou will receive file ');
      if (systat^.uldlratio) then
        sprompt('credit')
      else
        sprompt('points');
      sprint(' as soon as the SysOp validates the file'+plural+'!');
    end;
    nl;

    if (choptime<>0.0) then begin
      choptime:=choptime+ulrefundgot;
      freetime:=freetime-ulrefundgot;
      star('Sorry, no upload time refund may be given at this time.');
      star('You will get your refund after the event.');
      nl;
    end;

    if (takeawayulrefundgot<>0.0) then begin
      nl;
      r2dt(takeawayulrefundgot,takeawayulrefundgot1);
      star('Taking away time refund of '+longtim(takeawayulrefundgot1));
      freetime:=freetime-takeawayulrefundgot;
    end;

    if (ahangup) then begin
      commandline('Hanging up phone...');
      dophonehangup(FALSE);
      hangup:=TRUE;
    end;

  end;
  if (savpause) then include(thisuser.ac,pause);
end;

procedure batchinfo;
var anyyet:boolean;

  procedure sayit(s:string);
  begin
    if (not anyyet) then begin anyyet:=TRUE; nl; end;
    sprint(s);
  end;

begin
  anyyet:=FALSE;
  if (numbatchfiles<>0) then
    sayit('|B>> |CYou have |Y'+cstr(numbatchfiles)+
          '|C file'+aonoff(numbatchfiles<>1,'s','')+
            ' left in your download batch queue.');
  if (numubatchfiles<>0) then
    sayit('|V>> |CYou have |Y'+cstr(numubatchfiles)+
          '|C file'+aonoff(numubatchfiles<>1,'s','')+
            ' left in your upload batch queue.');
end;

end.

