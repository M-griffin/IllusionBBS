(*****************************************************************************)
(* Illusion Main File System BBS                                             *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit NewFile;

interface

uses
  crt,
  dos,
  myio,
  common,
  misc2,
  execbat,
  common2,
  sysop4,
  mmodem,
  miscx,
  Fmenu,  { FileP Menu System }  
  Fmenu2; { Filep Menu System }




(* Archive 1 Functions ---------------------------------------- *)

procedure purgedir(s:astr);                {* erase all non-dir files in dir *}
function  arcmci(src,fn,ifn,cmt:astr):astr;
procedure arcdecomp(var ok:boolean; atype:integer; fn,fspec,s:astr);
procedure arccomp(var ok:boolean; atype:integer; fn,fspec,s:astr);
procedure arccomment(var ok:boolean; atype,cnum:integer; fn,s:astr);
procedure arcintegritytest(var ok:boolean; atype:integer; fn,s:astr);
procedure conva(var ok:boolean; otype,ntype:integer; tdir,ofn,nfn:astr);
function  arctype(s:astr):integer;
procedure listarctypes;
procedure invarc;

const
  maxdoschrline=127;



(* File 15 Functions ------------------------------------------ *)

procedure quickfile;

(* File 14 Functions ------------------------------------------ *)

procedure getgifspecs(fn:astr; var sig:astr; var x,y,c:word);
procedure dogifspecs(fn:astr; var abort,next:boolean);
procedure addgifspecs;

(* File 13 Functions ------------------------------------------ *)

procedure sort;

(* File 12 Functions ------------------------------------------ *)

procedure delubatch(n:integer);
procedure listubatchfiles;
procedure removeubatchfiles;
procedure clearubatch;
procedure batchul;
procedure batchinfo;
  
  
(* File 11 Functions ------------------------------------------ *)  
  
TYPE                               { Queue to store the contents of the  }
  FListPtr = ^FlistRec;            { current screen so it can be redrawn }
  FListRec = Record                { from the file prompt.               }
    Line:Astr;                     {                 |                   }
    Next:FListPtr;                 {                 |                   }
  End;                             {                 |                   }
                                   {                 |                   }
CONST                              {                 |                   }
  Front : FListPtr = nil;          {                 |                   }
  Rear  : FListPtr = nil;          {                 |                   }
  Temp  : FListPtr = nil;          {                 V                   }

  flistlines:byte=0;
  
  var exitnow:boolean;

Procedure KillQueue;

function cansee(f:ulfrec):boolean;
procedure pbn(var abort,next:boolean);
procedure pfn(fnum:integer; f:ulfrec; var abort,next:boolean);
procedure searchb(b:integer; fn:astr; filestats:boolean; var abort,next:boolean; newf:boolean);
{procedure searchb(b:integer; fn:astr; filestats:boolean; var abort,next:boolean);}
procedure search;
procedure listfiles;
procedure searchbd(b:integer; ts:astr; var abort,next,found:boolean);
procedure searchd;
{procedure newfiles(b:integer; var abort,next:boolean);}
procedure gnfiles;
procedure nf(mstr:astr);
procedure fbasechange(var done:boolean; mstr:astr);
procedure createtempdir;


(* File 10 Functions ------------------------------------------ *)

procedure resetverbose(curfile:longint);
procedure editfiles(curfile:longint);
procedure validatefiles;

(* File 9 Functions ------------------------------------------- *)

function info:astr;
procedure dir(cd,x:astr; expanded:boolean);
procedure dirf(expanded:boolean);
procedure deleteff(rn:integer; var pl:integer; killverbose:boolean);
procedure setdirs;
procedure pointdate;
procedure listopts;

(* File 8 Functions ------------------------------------------- *)

function checkfileratio:integer;
procedure ymbadd(fname:astr);
procedure tagfile(fname:astr);
procedure send1(fn:astr; var dok,kabort:boolean);
procedure receive1(fn:astr; resumefile:boolean; var dok,kabort,addbatch:boolean);


(* File 7 Functions ------------------------------------------- *)

procedure recvascii(fn:astr; var dok:boolean; tpb:real);
procedure sendascii(fn:astr);


(* File 6 Functions ------------------------------------------- *)

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

uses
  Newfile2, FilePEd;


(* Archive 1 Functions ---------------------------------------- *)



procedure purgedir(s:astr);                {* erase all non-dir files in dir *}
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

function arcmci(src,fn,ifn,cmt:astr):astr;
begin
  src:=substall(src,'@F',fn);
  src:=substall(src,'@I',ifn);
  src:=substall(src,'@C',cmt);
  arcmci:=src;
end;

{* ok: result
 * atype: archive method
 * fn   : archive filename
 *}

procedure arcdecomp(var ok:boolean; atype:integer; fn,fspec,s:astr);
begin
  purgedir(modemr^.temppath+'ARCHIVE\');
  shel(s);
  execbatch(ok,TRUE,'i_arc'+cstr(nodenum)+'.bat','',modemr^.temppath+'ARCHIVE\',
            arcmci(systat^.arcpath+systat^.filearcinfo[atype].unarcline,fn,fspec,''),
            systat^.filearcinfo[atype].succlevel);
  shel2;
  if (not ok) then sysoplog('Archive "'+fn+'": Errors during de-compression');
end;

procedure arccomp(var ok:boolean; atype:integer; fn,fspec,s:astr);
begin
  shel(s);
  execbatch(ok,TRUE,'i_arc'+cstr(nodenum)+'.bat','',modemr^.temppath+'ARCHIVE\',
            arcmci(systat^.arcpath+systat^.filearcinfo[atype].arcline,fn,fspec,''),
            systat^.filearcinfo[atype].succlevel);
  shel2;
  if (not ok) then sysoplog('Archive "'+fn+'": Errors during compression');
  purgedir(modemr^.temppath+'ARCHIVE\');
end;

procedure arccomment(var ok:boolean; atype,cnum:integer; fn,s:astr);
begin
  if (cnum<>0) and (systat^.filearccomment[cnum]<>'') then
  begin
    shel(s);
    execbatch(ok,FALSE,'i_arc'+cstr(nodenum)+'.bat','',modemr^.temppath+'ARCHIVE\',
              arcmci(systat^.arcpath+systat^.filearcinfo[atype].cmtline,fn,'',systat^.filearccomment[cnum]),
              systat^.filearcinfo[atype].succlevel);
    shel2;
  end;
end;

procedure arcintegritytest(var ok:boolean; atype:integer; fn,s:astr);
begin
  if (systat^.filearcinfo[atype].testline<>'') then
  begin
    shel(s);
    execbatch(ok,TRUE,'i_arc'+cstr(nodenum)+'.bat','',modemr^.temppath+'ARCHIVE\',
              arcmci(systat^.arcpath+systat^.filearcinfo[atype].testline,fn,'',''),
              systat^.filearcinfo[atype].succlevel);
    shel2;
  end;
end;

procedure conva(var ok:boolean; otype,ntype:integer; tdir,ofn,nfn:astr);
var f:file;
    nofn,ps,ns,es:astr;
    eq:boolean;
begin
  star('Converting archive - stage one.');
  eq:=(otype=ntype);
  if (eq) then begin
    fsplit(ofn,ps,ns,es);
    nofn:=ps+ns+'.#$%';
  end;
  arcdecomp(ok,otype,ofn,'*.*','Converting archive - stage one...');
  if (not ok) then star('Errors in decompression!')
  else begin
    star('Converting archive - stage two.');
    if (eq) then begin assign(f,ofn); rename(f,nofn); end;
    arccomp(ok,ntype,nfn,'*.*','Converting archive - stage two...');
    if (not ok) then begin
      star('Errors in compression!');
      if (eq) then begin assign(f,nofn); rename(f,ofn); end;
    end;
    if (not exist(sqoutsp(nfn))) then ok:=FALSE;
  end;
end;

function arctype(s:astr):integer;
var atype:integer;
begin
  s:=align(stripname(s)); s:=copy(s,length(s)-2,3);
  atype:=1;
  while (systat^.filearcinfo[atype].ext<>'') and
        (systat^.filearcinfo[atype].ext<>s) and
        (atype<maxarcs+1) do
    inc(atype);
  if (atype=maxarcs+1) or (systat^.filearcinfo[atype].ext='') or
     (not systat^.filearcinfo[atype].active) then atype:=0;
  arctype:=atype;
end;

procedure listarctypes;
var i,j:integer;
begin
  i:=1; j:=0;
  while (systat^.filearcinfo[i].ext<>'') and (i<maxarcs) do begin
    if (systat^.filearcinfo[i].active) then begin
      inc(j);
      if (j=1) then prompt('Available archive formats: ') else prompt(',');
      prompt(systat^.filearcinfo[i].ext);
    end;
    inc(i);
  end;
  if (j=0) then prompt('No archive formats available.');
  nl;
end;

procedure invarc;
begin
  print('Unsupported archive format.');
  nl;
  listarctypes;
  nl;
end;

(* File 15 Functions ------------------------------------------ *)

procedure quickfile;
var c:char;
    b:boolean;
begin
  b:=FALSE;
  newdate:=thisuser.laston;
  repeat
    cls;
    sprint('|WQuickFile Menu');
    nl;
    sprint('Current Base: |C%FN |C#%F#');
    nl;
    lcmds(16,3,'[Previous Base',']Next Base');
    lcmds(16,3,'Area Change','List Files');
    lcmds(16,3,'File Manager','GAdd GifSpecs');
    lcmds(16,3,'Newscan Files','Pointer Date');
    lcmds(16,3,'Sort Files','Upload Files');
    lcmds(16,3,'Validate Files','MFilep Editor');
    nl;
    prt('Command (Q:uit): ');
    onek(c,'[]ALVGNPSUFQM');
    nl;
    case c of
      'N':nf('!');
      'A':fbasechange(b,'');
      '[':fbasechange(b,'-');
      ']':fbasechange(b,'+');
      'L':listfiles;
      'U':uploadall;
      'S':sort;
      'V':validatefiles;
      'F':editfiles(-1);
      'G':addgifspecs;
      'P':pointdate;
      'M':menup_edit; { filep menu editor }
    end;
    if pos(c,'NSVGP!')<>0 then pausescr;
  until (c='Q') or (hangup);
end;

(* File 14 Functions ------------------------------------------ *)

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

(* File 13 Functions ------------------------------------------ *)

var totfils,totbases:longint;
    bubblesortend:integer;

procedure switch(a,b:integer);
var f1,f2:ulfrec;
begin
  seek(ulff,a); read(ulff,f1);
  seek(ulff,b); read(ulff,f2); seek(ulff,b); write(ulff,f1);
  seek(ulff,a); write(ulff,f2);
end;

function greater(islesser,isequ:boolean; r1,r2:integer):boolean;
var f1,f2:ulfrec;
    b,c:boolean;

  procedure figure1;
  begin
    if (isequ) then
      b:=(f1.filename<=f2.filename)
    else
      b:=(f1.filename<f2.filename);
  end;

  procedure figure2;
  begin
    if (isequ) then
      b:=(f1.filename>=f2.filename)
    else
      b:=(f1.filename>f2.filename);
  end;

begin
  if (r1<r2) then begin
    seek(ulff,r1); read(ulff,f1);
    seek(ulff,r2); read(ulff,f2);
  end else begin
    seek(ulff,r2); read(ulff,f2);
    seek(ulff,r1); read(ulff,f1);
  end;

  islesser:=not islesser;
  if (islesser) then figure1 else figure2;
  greater:=b;
end;

procedure mainsort(pl:integer);
label 10,20,30,40,50,60,70,80;
const maxsortrec=2000;   (* maximum size of directory which can be processed *)
var hold,pass:array[0..maxsortrec] of integer;
    a,b,c,d,e,f,x:integer;
begin
  a:=pl; b:=0; c:=0; d:=1; e:=0; f:=0;
10:
  if (a-e<9) then goto 70;
  b:=e; c:=a;
20:
  if (greater(TRUE,FALSE,b,c)) then begin
    switch(c,b);
    goto 60;
  end;
30:
  dec(c);
  if (c>b) then goto 20;
  inc(c);
40:
  inc(d);
  if (b-e<a-c) then begin
    hold[d]:=c; pass[d]:=a;
    a:=b;
    goto 10;
  end;
  hold[d]:=e; pass[d]:=b;
  e:=c;
  goto 10;
50:
  if (greater(FALSE,FALSE,c,b)) then begin
    switch(c,b);
    goto 30;
  end;
60:
  inc(b);
  if (c>b) then goto 50;
  inc(c);
  goto 40;
70:
  if (a-e+1=1) then goto 80;
  for b:=e+1 to a do
    for c:=e to (b-1) do begin
      f:=b-c+e-1;
      if (greater(TRUE,FALSE,f,f+1)) then begin
        x:=f+1;
        switch(f,x);
      end;
    end;
80:
  e:=hold[d]; a:=pass[d];
  dec(d);
  if (d=0) then exit;
  goto 10;
end;

procedure flipit(pl:integer);
var i:integer;
begin
  for i:=0 to pl div 2 do switch(i,pl-i);
end;

procedure bubblesort(pl:integer);
var f1,f2:ulfrec;
    i,j,numdone:integer;
    foundit:boolean;
begin
  if (bubblesortend>pl) then bubblesortend:=pl;  { should never happen, but...}
  numdone:=0;
  repeat
    i:=(bubblesortend+1)-numdone;
    foundit:=FALSE;
    while ((i<=pl) and (not foundit)) do
      if (greater(FALSE,TRUE,0,i)) then foundit:=TRUE else inc(i);

{    while ((i<=pl) and (not greater(FALSE,TRUE,0,i))) do inc(i);}
    seek(ulff,0); read(ulff,f1);

{                   (i-1) __(i)               }
{                     |  /                    }
      { x O + + + + + + + x x x x x x x ..... }
      { x + + + + + + +   x x x x x x x ..... }
    for j:=0 to i-2 do begin
      seek(ulff,j+1); read(ulff,f2);
      seek(ulff,j); write(ulff,f2);
    end;

      { x + + + + + + + O x x x x x x x ..... }
    seek(ulff,i-1); write(ulff,f1);
    inc(numdone);
  until ((numdone>=bubblesortend));

end;

function analysis(pl:integer):integer;
var i,j:integer;
    c1,c2:boolean;
begin
  analysis:=1;
  c1:=TRUE; c2:=TRUE;
  for i:=0 to pl-1 do begin
    if (not greater(TRUE,TRUE,i,i+1)) then c1:=FALSE;    { a }
    if (not greater(FALSE,TRUE,i,i+1)) then c2:=FALSE;   { d }
  end;
  if (c1) then analysis:=2;     { list is backwards, so flip it }
  if (c2) then analysis:=0;     { list is already sorted }
  if ((not c1) and (not c2)) then begin
    c1:=FALSE; j:=0;
    i:=pl-1;
    while ((i>=0) and (not c1)) do begin
      if (not greater(FALSE,TRUE,i,i+1)) then begin c1:=TRUE; j:=i; end;
      dec(i);
    end;
    if ((c1) and (j/pl<0.15)) then begin
      analysis:=3;
      bubblesortend:=j;
    end;
  end;
end;

procedure sortfiles(b:integer; var abort,next:boolean);
var s:string;
    oldboard,pl,sortt:integer;
begin
  oldboard:=fileboard;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    fiscan(pl);
    seek(ulff,pl+1); truncate(ulff);
    clearwaves;
    addwave('FI',cstr(pl),txt);
    spstr(478);
    abort:=FALSE; next:=FALSE;
    sortt:=analysis(pl);
    case sortt of
      0:;
      1:mainsort(pl);
      2:flipit(pl);
      3:bubblesort(pl);
    end;
    wkey(abort,next);
    close(ulff);
    inc(totbases); inc(totfils,pl);
  end;
  fileboard:=oldboard;
  clearwaves;
end;

procedure sort;
var f:ulfrec;
    sortstart,sortend,tooktime:datetimerec;
    i:integer;
    c:char;
    global,abort,next,savepause:boolean;
begin
  savepause:=pause in thisuser.ac; exclude(thisuser.ac,pause);

  if (not filesortonly) then begin
    dyny:=true;
    global:=pynq(getstr(477));
  end else global:=true;
  if global then begin
    sysoplog('Sorted all file bases');
    spstr(476);
  end;

  totfils:=0; totbases:=0;

  getdatetime(sortstart);
  abort:=FALSE; next:=FALSE;
  if (not global) then
    sortfiles(fileboard,abort,next)
  else begin
    i:=0;
    while ((not abort) and (i<=maxulb) and (not hangup)) do begin
      if (fbaseac(i)) then sortfiles(i,abort,next);
      inc(i);
      wkey(abort,next);
      if (next) then abort:=FALSE;
    end;
  end;
  getdatetime(sortend);
  timediff(tooktime,sortstart,sortend);

  nl;
  print('Sorted '+cstrl(totfils)+' file'+aonoff(totfils<>1,'s','')+
        ' in '+cstrl(totbases)+' base'+aonoff(totbases<>1,'s','')+
        ' - Took '+longtim(tooktime));

  if savepause then include(thisuser.ac,pause);
end;

(* File 12 Functions ------------------------------------------ *)

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
    printacr('|BÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ÄÄÄÄ ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',abort,next);

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

    printacr('|BÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ÄÄÄÄ ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',abort,next);
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
    execbatch(dok,FALSE,'ircv'+cstr(nodenum)+'.bat','',modemr^.temppath+'UPLOAD\',
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

    findfirst(modemr^.temppath+'UPLOAD\*.*',anyfile-directory-volumeid,dirinfo);
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
      findfirst(modemr^.temppath+'UPLOAD\*.*',anyfile-directory-volumeid,dirinfo);
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
          arcstuff(ok,convt,blks,convtime,TRUE,modemr^.temppath+'UPLOAD\',
                   fn,f,v);
          tconvtime:=tconvtime+convtime; f.blocks:=blks;
          doffstuff(f,fn,gotpts);

          fok:=TRUE;
          loaduboard(fileboard);
          if (ok) then begin
            star('Moving file to '+memuboard.name);
            sprompt('|YProgress: ');
            movefile(fok,nospace,TRUE,modemr^.temppath+'UPLOAD\'+fn,memuboard.dlpath+fn);
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
            if ((thisuser.sl>0 {systat^.minresumelatersl} ) and
                (f.blocks div 8>systat^.minresume)) then begin
              nl;
              dyny:=TRUE;
              if pynq('Save file for a later resume') then begin
                sprompt('|BProgress: ');
                movefile(fok,nospace,TRUE,modemr^.temppath+'UPLOAD\'+fn,memuboard.dlpath+fn);
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
              assign(fi,modemr^.temppath+'UPLOAD\'+fn); erase(fi);
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

(* File 11 Functions ------------------------------------------ *)


{----------------------------------------------------------------------------}

Procedure EnQueue(Var Front,Rear:FListPtr; Temp:FListPtr);
{ Add to rear of queue }
Begin
  if front=nil
    then front:=temp
  else rear^.next:=temp;

  Rear:=temp;
end;

Procedure printacrQ(s:string; var abort,next:boolean);
Begin
  New(Temp);
  Temp^.Next:=nil;
  Temp^.Line:=s;
  EnQueue(Front,Rear,Temp);
  Printacr(s,abort,next);
End;

Procedure DeQueue(Var Front,Rear,Temp:FListPtr);
Begin
  Temp:=Front;
  If not (Front=nil)
    then begin
      if Front^.next = nil
        then rear:=nil;
      Front:=Front^.next;
    end;
end;

Function emptyqueue:boolean;
{ returns true if the queue is empty }
begin
  emptyqueue:=(front=nil);
end;

Procedure KillQueue;
Begin
  while (not emptyqueue) do begin
    dequeue(front,rear,temp);
    dispose(temp);
  end;
End;

Procedure PrintQueue;
var abort,next:boolean;
Begin
  abort:=false; next:=false;

  Temp:=Front;
  While (not abort) and (temp<>rear) do begin
    lil:=0;
    Printacr(Temp^.Line,abort,next);
    Temp:=Temp^.next;
  end;
  printacr(Temp^.Line,abort,next);
end;

{----------------------------------------------------------------------------}

function cansee(f:ulfrec):boolean;
begin
  cansee:=((not (notval in f.filestat)) or (aacs(systat^.seeunval)));
end;

function isulr:boolean;
begin
  isulr:=((systat^.uldlratio) and (not systat^.fileptratio));
end;





procedure fileprompt(var abort:boolean);
var c:char;
    ufo1,ufo2:boolean;
    oldlrn:integer;
    oldlfn:string;
    oldbnp:boolean;
    s:string[10];

begin

  ufo1:=(filerec(ulff).mode=fmclosed);
  oldlrn:=lrn;
  oldlfn:=lfn;
  oldbnp:=bnp;

  repeat
    spstr(612);

    s:=^M^L'QDVT';
    onek(c,s);

    case c of
      'Q': Abort:=TRUE;
      ^M : nl;
      'D': idl;
      'V': lfii;
      'T': tagfile('');
      ^L : ;
    end;

    if c in ['D','V',^L,'T'] then begin
      if (c<>^L) then pausescr;
      cls;
      printqueue;
    end;

    ufo2:=(filerec(ulff).mode=fmclosed);
    if (ufo2) and (not ufo1) then begin
      SetFileAccess(ReadWrite,DenyNone);
      reset(ulff);
    end else
      if (not ufo2) and (ufo1) then close(ulff);

    lrn:=oldlrn;
    lfn:=oldlfn;
    bnp:=false;

  until (c=^M) or (c='Q') or (hangup);

  KillQueue;
  flistlines:=0;
end;



procedure pbn(var abort,next:boolean);
var s:astr;
    ii:byte;
begin
  aborted:=FALSE;
  if (not bnp) then
  begin
    loaduboard(fileboard);
    killqueue;
    { Displays File List Header Here }
    printacrQ('',abort,next);
    spstr(613);

  end;
  bnp:=TRUE;
end;


{ New }
procedure pfndd(fnum:integer; ts:astr; f:ulfrec; var abort,next:boolean);
var rr,s,s1,dd,dd2:astr;
    v:verbrec;
    u:userrec;
    li:longint;
    i:integer;
    vfo:boolean;
    lst,iii,ldescp:integer;

begin

  lst:=0;
  li:=f.blocks; li:=li*128;
  
  { File Number }
  s:=+'|08'+mln(cstr(fnum),4)+' ';
  iii:=1;
  
  { File Name }
  s:=s+'|09'+mln(f.filename,12);
  
  { New File }
 
  if (f.daten >= daynum(newdate)) then s:=s+' |11* '
  else s:=s+'   ';  
  
  { File Size }
  if (f.blocks div 8>=20000) then
    s:=s+'|15'+mln(cstr((f.blocks div 8) div 1024)+'|07m',6)+' '
  else
    if (f.blocks div 8<9) then
      s:=s+'|15'+mln(cstr(f.blocks*128)+'|07b',6)+' '
  else
    s:=s+'|15'+mln(cstr(f.blocks div 8)+'|07k',6)+' ';
  s:=s+' ';
  
  { File downloads }
  s:=s+'|03'+mln(cstr(f.nacc),3);
  s:=s+' ';
  
  (* Get rid of ay File Points
  if Thisuser.flistc[3][1] > 0 then s:=s+'|C'+mln(cstr(f.filepoints),3);
  s:=s+' ';
  *)
  
  
  { File Description }
  iii:=length(s);
  s:=s+'|w'+mln(f.description,45);
  s:=s+' ';
  
  printacrQ(s,abort,next);
  flistlines:=flistlines+1;

  
  (*
  
  if Thisuser.flistc[8][1] > 0 then begin
    (*if (f.vpointer<>-1) then begin

      vfo:=(filerec(verbf).mode<>fmclosed);

      if (not vfo) then begin
        SetFileAccess(ReadOnly,DenyNone);
        {$I-} reset(verbf); {$I+}
      end;

      if (ioresult=0) then begin
        {$I-} seek(verbf,f.vpointer); read(verbf,v); {$I+}

        if (ioresult=0) then lst:=9;

        s := '';
        s:=s+(mln(' ',iii-10));


        for i:=1 to 9 do
          if (v.descr[i]='') then i:=9;

            if ((length(v.descr[i])<>0) and (v.descr[i]<>'')) then
            begin            
              dd:='|w'+v.descr[i];
              printacrQ(s+mln(dd,45),abort,next);
            end;
          end;
          if (vfo) then close(verbf);
      end;
      *)
     (*
    end;

  end; { End This User }

  s := '';
  for ldescp:=1 to iii-8 do s:=s+' ';

  if Thisuser.flistc[6][1] > 0 then begin
    printacrQ(s+'|CU|cploaded by: |C'+caps(f.stowner),abort,next);
    flistlines:=flistlines+1;
  end;

  if Thisuser.flistc[7][1] > 0 then begin
    printacrQ(s+'|CU|cploaded on: |C'+f.date,abort,next);
    flistlines:=flistlines+1;
  end;

  if Thisuser.flistc[4][1] > 0 then begin
    printacrQ(s+'|CN|cumber of D/L''s |W[|C'+cstr(f.nacc)+'|W]',abort,next);
    flistlines:=flistlines+1;
  end;

  *)

end;



procedure pfn(fnum:integer; f:ulfrec; var abort,next:boolean);
begin
  pfndd(fnum,'',f,abort,next);
end;



{ New }
procedure searchb(b:integer; fn:astr; filestats:boolean; var abort,next:boolean; newf:boolean);
var f:ulfrec;
    v:verbrec;
    pp,li,totfils,lastfile,totsize:longint;
    oldboard,pl,rn:integer;
    filenum:array[1..20] of integer;
    fpos:array[1..20] of integer;
    fnum:array[1..20] of integer;
    s:astr;
    bk,temp,yy,tmp,tmppos,tmp2,tmp3,i,a1,a2,
           bx,by,numadd,savflistopt:integer;
    r,c:char;
    oldpage:byte;
    filep : string;
    jump,showp,vfo,botlist,eol,bb,abort1,done,done1,showlist:boolean;
    
begin

  exitnow:=false;

  bb:=false;
  eol:=false;
  botlist:=false;
  last_menu := curmenu;
  curmenu := systat^.menupath+'FILEP.MNU';
  filemnu := true;   
  readin;
  showp := false;
  fillchar(fileNum,20,0);
  fillChar(fPos,20,0);
  fillChar(fNum,20,0);
  tmppos:=0;
  oldboard:=fileboard;
  
  
  if (fileboard<>b) then changefileboard(b);   
  if (fileboard=b) then begin
    totfils:=0;
    totsize:=0;
    lastfile:=0;
              
    recno(fn,pl,rn);    
    if (baddlpath) then 
    begin
      curmenu := last_menu;
      filemnu := false;
      exit;
    end; 
 
    if (rn=-1) then
    begin
      spstr(111);
    end;
  
    
    while ((rn<=pl) and (not abort) and (not hangup) and (rn<>-1)) do begin

      yy:=0;
      showp := false;
      seek(ulff,rn); read(ulff,f);



      if (not newf) then begin      
        if (cansee(f)) then begin     


        KillQueue;

        pbn(abort,next);

        lil := 0;
        yy:=wherey;
        temp:=yy;
        inc(tmppos);
        if (tmppos>=20) then tmppos:=0;
        fpos[tmppos]:=wherey;

        pfn(rn,f,abort,next); { Runs through first loop for file info }

        fnum[tmppos]:=rn;
        tmp2:=wherey;


        if (tmppos=1) then begin
          ansig(1,fpos[tmppos]);
          sprompt('|15|19'+mln(cstr(rn),4)+'|K')
        end;


        ansig(1,tmp2);
        inc(lastfile);
        if (filestats) then begin
          inc(totfils);
          li:=f.blocks; li:=li*128; inc(totsize,li);
        end;

        showp:=false;

        {test code}
        if (rn<pl) then begin

          if (rn<>lastfile) then
          begin

            seek(ulff,rn); read(ulff,f);

          end else if (yy >= 24) then showp := true;

        end; { End rc<pl }
      end; { End Cansee(f) }

        { This is new for displaying New Files Only! }
     end else if (cansee(f)) and (f.daten >= daynum(newdate)) then begin
     
       KillQueue;
             
       pbn(abort,next);
                
       lil := 0;
       yy:=wherey;
       temp:=yy;
       inc(tmppos);
       if (tmppos>=20) then tmppos:=0;
       fpos[tmppos]:=wherey;
                        
       pfn(rn,f,abort,next); { Runs through first loop for file info }        
                
       fnum[tmppos]:=rn;
       tmp2:=wherey;
        
        
       if (tmppos=1) then begin
         ansig(1,fpos[tmppos]);
         sprompt('|15|19'+mln(cstr(rn),4)+'|K')
       end;
                
        
       ansig(1,tmp2);
       inc(lastfile);
       if (filestats) then begin
         inc(totfils);
         li:=f.blocks; li:=li*128; inc(totsize,li);
       end;
                
       showp:=false;
        
       {test code}
       if (rn<pl) then begin
       
         if (rn<>lastfile) then
         begin
                                                                
           seek(ulff,rn); read(ulff,f);
        
         end else if (yy >= 24) then showp := true;
       
       end; { End rc<pl }
     end; { End Cansee(f) }
     



      nrecno(fn,pl,rn);

      if ((rn>pl) or (rn=-1)) then abort:=true;
      
      
      
      if (yy >= 24) then
      begin
        showp:=true;
      end;

      if ((lil >= 20) or
          (showp) or 
          (rn   = -1))
               
          
      then begin           
      

        bx:=wherex; by:=wherey;
        done:=false;
        oldboard:=fileboard;
        tmp2:=tmppos;
        tmp3:=1;
        tmppos:=0;
        abort:=false;
        
        if (totfils = 0) then exit;

        repeat
        
          ansig(bx,by);
          filepmnu := #0;
          filep := '';
          mainmenuhandle(filep);
          c := filepmnu;
          s:='';
        
          (*
          case c of

            ' ':begin
              i:=fnum[tmp3];
              if (i>=1) and (i<=pl) then begin
                filenum[1]:=i;
                numadd:=1;
                if (checkfileratio=0) then begin
                  a2:=0;
                  seek(ulff,filenum[1]); read(ulff,f);
                  a1:=numbatchfiles;
                  if (okdl(f)) then ymbadd(memuboard.dlpath+f.filename);
                  sprint(getstr(376));
                  if (numbatchfiles<>a1) then inc(a2);
                end else
                  sprint(getstr(109));
                end;
              end; 
            end; 

            *)
       
            ansig(1,21);
            if length(filep) > 1 then
            case filep[2] of            
            
            'A':begin { UP }
            
              if fnum[2]<>0 then begin
                dec(tmp3);
                
                if tmp3<=0 then tmp3:=1;
                if tmp3>0 then begin
                
                  ansig(1,fpos[tmp3]);
                  sprompt('|15|19'+mln(cstr(fnum[tmp3]),4)+'|16');
                  ansig(1,fpos[tmp3+1]);
                  sprompt('|08'+mln(cstr(fnum[tmp3+1]),4)+'|16');

                end;
              end;
              
              filep := '';
            end;

            'B':begin { DOWN }
            
              if fnum[2]<>0 then begin
                inc(tmp3);
                
                if tmp3>tmp2 then tmp3:=tmp2;
                if tmp3<=tmp2 then begin
                
                  ansig(1,fpos[tmp3]);
                  sprompt('|15|19'+mln(cstr(fnum[tmp3]),4)+'|16');
                  ansig(1,fpos[tmp3-1]);
                  sprompt('|08'+mln(cstr(fnum[tmp3-1]),4)+'|16');

                end;
              end;
              
              filep := '';
            end;
          end; { End of Case filep[2] }

          {ansig(bx,by);}
          i:=fnum[tmp3];
          filepmnu := #0;
          filep := '';
        until (c in ['L','F','+','?','J','V','Q','T','I','R','S','N']);


        repeat
          ansig(bx,by);
          i:=fnum[tmp3];
          if (c in ['F','+','?','R','S','V','T','I']) then
          begin
            rn:=fnum[1];
            lrn := rn;
            jump:=true;
            bk:=rn;
            showlist:=TRUE;
          end;

          if (not (c in ['L','F','+','?','J','R','S','V','Q','T','I','N'])) then
          begin
            showlist:=true;
            done:=true;
          end else
            case c of
              'I':begin
                sprompt('|LF |01+ |WI|wnfo on which file |w[|WENTER='+cstr(i)+'|w, |WQ=Quit|w]?|W ');
                s:='';
                input(s,4);
                if (s<>'') then i:=value(s);

                if (allcaps(s)<>'Q') then begin
                  if (i>=0) and (i<=pl) then begin
                    seek(ulff,i); read(ulff,f);
                    fileinfo(f,FALSE,abort1,next);
                    pausescr;
                  end;
                end;
                done:=true;
              end;

              'J':begin
                sprompt('|LF |01+ |WJ|wump to which file |w[|WENTER='+cstr(i)
                  +'|w] |w(|W0|w-|W'+cstr(pl)+'|w)? ');
                s:='';
                input(s,4);
                if (allcaps(s)<>'Q') then begin
                  if (s<>'') then i:=value(s);
                  if (i>=0) and (i<=pl) then begin
                    rn:=i;
                    lrn := i;
                    jump:=true;
                    bk:=rn;
                    {seek(ulff,i); read(ulff,f);}
                    showlist:=TRUE;
                  end;
                end;
                done:=true;
              end;

              '?':begin
                nl;
                lcmds(9,3,'Download','Upload');
                lcmds(9,3,'Jump to file','Toggle file list');
                lcmds(9,3,'Upload','Flag or + to tag files');
                lcmds(9,3,'Quit Listing','View interior');
                pausescr;
                done:=true;
              end;

              'T':begin { Toggle File Listing }

                if (thisuser.flistc[6][1]=0) then
                  thisuser.flistc[6][1]:=1
                else
                  thisuser.flistc[6][1]:=0;


                if (thisuser.flistc[7][1]=0) then
                  thisuser.flistc[7][1]:=1
                else
                  thisuser.flistc[7][1]:=0;


                if (thisuser.flistc[4][1]=0) then
                  thisuser.flistc[4][1]:=1
                else
                  thisuser.flistc[4][1]:=0;

                sprompt('|LF |01+ |WF|wile listing Toggled!|LF');
                pausescr;
                done:=true;
              end;

              'L','N':begin
                for tmp2:=1 to 20 do fpos[tmp2]:=0;
                for tmp2:=1 to 20 do fnum[tmp2]:=0;
                showlist:=true;
                done:=true;
              end;  {* do nothing *}

              '+','F':begin
                sprompt('|LF |01+ |WF|wlag Which File |w[|WENTER='+cstr(i)+'|w, |WQ=Quit|w]?|W ');
                s:='';
                input(s,4);
                if (s<>'') then i:=value(s);
                if (i>=0) and (i<=pl) then begin
                  filenum[1]:=i;
                  numadd:=1;                  
                  if (allcaps(s)<>'Q') then begin                  
                    if (checkfileratio=0) then begin
                      a2:=0;
                      seek(ulff,filenum[1]); read(ulff,f);
                      a1:=numbatchfiles;
                      if (okdl(f)) then ymbadd(memuboard.dlpath+f.filename);
                      clearwaves;                  
                      addwave('FN',f.filename,txt);                                 
                      {spstr(115);}                 
                      clearwaves;
                      {sprint(getstr(376));}
                      if (numbatchfiles<>a1) then inc(a2);
                    end else
                      sprint(getstr(109));
                      pausescr;                    
                    end;
                  end; { end <> 'Q' }
                  done:=true;                  
              end;

              'R':begin
                sprompt('|LF |01+ |WD|wownload Which File |w[|WENTER='+cstr(i)+'|w, |WQ=Quit|w]?|W ');
                s:='';
                input(s,4);
                if (allcaps(s)<>'Q') then begin
                  if (s<>'') then i:=value(s);
                  if ((i>=0) and (i<=pl)) then begin
                    seek(ulff,i); read(ulff,f);
                    abort1:=FALSE;
                    dlx(f,i,abort1);
                  end;
                end;  
                done:=true;
              end;

              'S':begin
                batchul;
                fiscan(pl);
                done:=true;
              end;

              'V':begin
                sprompt('|LF |01+ |WV|wiew Which File |w[|WENTER='+cstr(i)+'|w, |WQ=Quit|w]?|W ');
                s:='';
                input(s,4);
                if (allcaps(s)<>'Q') then begin
                  if (s<>'') then i:=value(s);
                  if (i>=0) and (i<=pl) then begin
                    abort1:=FALSE; next:=FALSE;
                    lfin(i,abort1,next);
                  end;
                  fiscan(pl);
                  pausescr;
                end;
                done:=true;
              end;

              'Q':begin
                done:=true; bb:=true; abort:=true; exitnow :=true;
              end;

            end;  { End of Case (c) }

          if (rn = -1) then abort := true;
          if (not bb) and (not abort) then begin spstr(613); end;
        until (done) or (hangup) or (abort);
      end; { End Begin }
    end; { End While }

    nl;
    close(ulff);

  end; { End if (fileboard=b) }

  fileboard := oldboard;
  curmenu := last_menu;
  filemnu := false;
  next := true;

end;


(*
procedure searchb(b:integer; fn:astr; filestats:boolean; var abort,next:boolean);
var f:ulfrec;
    li,totfils,totsize:longint;
    oldboard,pl,rn:integer;
begin
  oldboard:=fileboard;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    totfils:=0; totsize:=0;
    recno(fn,pl,rn);
    if (baddlpath) then exit;
    while ((rn<=pl) and (not abort) and (not hangup) and (rn<>-1)) do begin
      seek(ulff,rn); read(ulff,f);
      if (cansee(f)) then begin
        pbn(abort,next);
        pfn(rn,f,abort,next);
        inc(totfils);
        if (filestats) then begin
          li:=f.blocks; li:=li*128; inc(totsize,li);
        end;
      end;
      nrecno(fn,pl,rn);
    end;
    if ((not abort) and (totfils>0)) then begin
      if flistlines>0 then fileprompt(abort);
    end else if ((totfils=0) and (filestats)) then begin
      spstr(111);
    end;
    close(ulff);
  end;
  fileboard:=oldboard;
  KillQueue;
end;
*)



procedure search;
var fn:astr;
    bn:integer;
    abort,next:boolean;
    oldconf:char;
begin
  spstr(102);
  spstr(112);
  gfn(fn); oldconf:=thisuser.conference;
  if pynq(getstr(622)) then thisuser.conference:='@';
  bn:=0; abort:=FALSE; next:=FALSE;
  while (not abort) and (bn<=maxulb) and (not hangup) do begin
    if (fbaseac(bn)) then searchb(bn,fn,FALSE,abort,next,false);
    inc(bn);
    wkey(abort,next);
    if (next) then begin abort:=FALSE; next:=FALSE; end;
  end;
  thisuser.conference:=oldconf;
end;



{ New }
procedure listfiles;
var fn:astr;
    blah:integer;
    r,abort,next:boolean;

begin
   spstr(100);
   gfn(fn);
   abort:=FALSE;
   r:=false;
   blah:=thisuser.pagelen;
   {thisuser.pagelen := 24 - 3;}

   if (thisuser.ac=thisuser.ac+[pause]) then begin
      r:=true;
      thisuser.ac:=thisuser.ac-[pause];
   end;

   searchb(fileboard,fn,TRUE,abort,next, false);

   if (r) then thisuser.ac:=thisuser.ac+[pause];
   thisuser.pagelen:=blah;
end;


(*
procedure listfiles;
var fn:astr;
    abort,next:boolean;
begin
  spstr(100);
  gfn(fn); abort:=FALSE;
  searchb(fileboard,fn,TRUE,abort,next);
end;
*)




procedure searchbd(b:integer; ts:astr; var abort,next,found:boolean);
var oldboard,pl,rn,i,tot:integer;
    f:ulfrec;
    ok,vfo:boolean;
    v:verbrec;
begin
  oldboard:=fileboard; tot:=0;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    vfo:=(filerec(verbf).mode<>fmclosed);
    if not vfo then begin
      SetFileAccess(ReadOnly,DenyNone);
      {$I-} reset(verbf); {$I+}
    end;
    fiscan(pl);
    if (baddlpath) then exit;
    rn:=0;
    while (rn<=pl) and (not abort) and (not hangup) do begin
      seek(ulff,rn); read(ulff,f);
      if (cansee(f)) then begin
        ok:=((pos(ts,allcaps(f.description))<>0) or
             (pos(ts,allcaps(f.filename))<>0));
        if (not ok) then
          if (f.vpointer<>-1) then begin
            {$I-} seek(verbf,f.vpointer); read(verbf,v); {$I+}
            if (ioresult=0) then begin
              i:=1;
              while (v.descr[i]<>'') and (i<=9) and (not ok) do begin
                if pos(ts,allcaps(v.descr[i]))<>0 then ok:=TRUE;
                inc(i);
              end;
            end;
          end;
      end;
      if (ok) then begin
        found:=TRUE;
        pbn(abort,next);
        pfndd(rn,ts,f,abort,next); inc(tot);
      end;
      inc(rn);
    end;
    if flistlines>0 then fileprompt(abort);
    close(ulff);
    SetFileAccess(ReadOnly,DenyNone); reset(verbf); close(verbf);
  end;
  fileboard:=oldboard; if tot>0 then pausescr;
  KillQueue;
end;

procedure searchd;
var s:astr;
    bn:integer;
    abort,next,found:boolean;
    oldconf:char;
begin
  found:=FALSE; oldconf:=thisuser.conference;
  spstr(103);
  spstr(104);
  mpl(20); input(s,20);
  if pynq(getstr(622)) then thisuser.conference:='@';
  if (s<>'') then
  begin
    clearwaves;
    addwave('SS',s,txt);
    spstr(621);
    clearwaves;
    if pynq(getstr(618)) then begin
      bn:=0; abort:=FALSE; next:=FALSE;
      while (not abort) and (bn<=maxulb) and (not hangup) do begin
        if (fbaseac(bn)) then searchbd(bn,s,abort,next,found);
        inc(bn);
        wkey(abort,next);
        if (next) then begin abort:=FALSE; next:=FALSE; end;
      end;
    end else begin
      abort:=FALSE; next:=FALSE;
      searchbd(fileboard,s,abort,next,found);
    end;
  end;
  if not(found) then spstr(623);
  thisuser.conference:=oldconf;
end;



(*
procedure newfiles(b:integer; var abort,next:boolean);
var f:ulfrec;
    oldboard,pl,rn,tot:integer;
begin
  oldboard:=fileboard; tot:=0;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    fiscan(pl);
    if (baddlpath) then exit;
    rn:=0;
    while (rn<=pl) and (not abort) and (not hangup) do begin
      seek(ulff,rn); read(ulff,f);
      
      { Check for Newscan file date }      
      if ((cansee(f)) and (f.daten>=daynum(newdate))) or
         ((notval in f.filestat) and (cansee(f))) then begin
         
        pbn(abort,next);
        pfn(rn,f,abort,next); inc(tot);
                
        if flistlines>15 then    
        begin     
          fileprompt(abort);       
        end;
        
      end;
      inc(rn);
    end;
    
    if flistlines>0 then    
    begin     
      fileprompt(abort);       
    end;
    
    close(ulff);
  end;
  fileboard:=oldboard;
  KillQueue;
end;


procedure gnfiles;
var i:integer;
    abort,next:boolean;
begin
  sysoplog('NewScan of file bases');
  i:=0;
  abort:=FALSE; next:=FALSE;
  while (not abort) and (i<=maxulb) and (not hangup) do begin
    if ((fbaseac(i)) and (i in zscanr.fzscan)) then begin
      if (fileboard<>i) then changefileboard(i);
      spstr(619);
      newfiles(i,abort,next);
      spstr(620);
    end;
    inc(i);
    wkey(abort,next);
    if (next) then begin abort:=FALSE; next:=FALSE; end;
  end;
end;

procedure nf(mstr:astr);
var bn:integer;
    abort,next:boolean;
begin
  abort:=FALSE; next:=FALSE;

  if (mstr='C') then
    newfiles(fileboard,abort,next)
  else if (mstr='G') then
    gnfiles
  else if (value(mstr)<>0) then
    newfiles(value(mstr),abort,next)
  else begin
    spstr(101);
    spstr(112);
    abort:=FALSE; next:=FALSE;
    if pynq(getstr(618)) then gnfiles else newfiles(fileboard,abort,next);
  end;
end;
*)


procedure gnfiles;
var i:integer;
    abort,next:boolean;
begin
  sysoplog('NewScan of file bases');
  i:=0;
  abort:=FALSE; next:=FALSE; exitnow:=FALSE;
  
  while (i<=maxulb) and (not hangup) do begin
    if (fileboard<>i) then changefileboard(i);
    if ((fbaseac(i)) and (i in zscanr.fzscan)) then begin      

      if (exitnow) then begin
        changefileboard(1);
        exit;
      end;       
            
      spstr(619);
      searchb(i,'*.*',true,abort,next,true);
      spstr(620);
      
    end;
      
    inc(i);
    wkey(abort,next);
    if (next) then begin abort:=FALSE; next:=FALSE; end;
  end;
  changefileboard(1);
end;

procedure nf(mstr:astr);
var bn:integer;
    abort,next:boolean;
begin
  if (mstr='C') then searchb(fileboard,'*.*',true,abort,next,true)
  else if (mstr='G') then gnfiles
  else if (value(mstr)<>0) then searchb(value(mstr),'*.*',true,abort,next,true)
  else begin
    nl;
    {spstr(101);}
    spstr(112);
    nl;
    abort:=FALSE; next:=FALSE;

    if pynq(getstr(618)) then gnfiles
      else searchb(fileboard,'*.*',true,abort,next,true);
  end;
end;




procedure fbasechange(var done:boolean; mstr:astr);
var s:astr;
    i:integer;
begin
  if (mstr<>'') then
    case mstr[1] of
      '+':begin
            i:=fileboard;
            if (fileboard>=maxulb) then i:=0 else
              repeat
                inc(i);
                if (fbaseac(i)) then changefileboard(i);
              until ((fileboard=i) or (i>maxulb));
            if (fileboard<>i) then spstr(616) else lastcommandovr:=TRUE;
          end;
      '-':begin
            i:=fileboard;
            if (fileboard<=0) then i:=maxulb else
              repeat
                dec(i);
                if fbaseac(i) then changefileboard(i);
              until ((fileboard=i) or (i<=0));
            if (fileboard<>i) then spstr(617) else lastcommandovr:=TRUE;
          end;
      'L':fbaselist;
    else
          begin
            changefileboard(value(mstr));
            if (pos(';',mstr)>0) then begin
              s:=copy(mstr,pos(';',mstr)+1,length(mstr));
              curmenu:=systat^.menupath+s+'.mnu';
              newmenutoload:=TRUE;
              done:=TRUE;
            end;
            lastcommandovr:=TRUE;
          end;
    end
  else begin
    if (novice in thisuser.ac) then fbaselist;
    nl;
    s:='?';
    repeat
      spstr(141); input(s,3);
      i:=ccuboards[0][value(s)];
      if (s='?') then begin fbaselist; nl; end else
        if (((i>=1) and (i<=maxulb)) or
           ((i=0) and (copy(s,1,1)='0'))) and
           (i<>fileboard) then
          changefileboard(i);
    until (s<>'?') or (hangup);
    lastcommandovr:=TRUE;
  end;
end;

procedure createtempdir;
var s:astr;
    i:integer;
begin
  nl;
  if (maxulb=maxuboards) then print('Too many file bases already.')
  else begin
    print('Enter file path for temporary directory');
    pchar; mpl(40); input(s,40);
    if (s<>'') then begin
      s:=fexpand(bslash(TRUE,s));
      fileboard:=maxulb+1;
      sysoplog('Created temporary directory #'+cstr(fileboard)+
               ' in "'+s+'"');
      fillchar(tempuboard,sizeof(tempuboard),#0);
      with tempuboard do
      begin
        name:='Temporary';
        filename:='TEMPFILE';
        dlpath:=s;
        maxfiles:=2000;
        arctype:=0;
        cmttype:=1;
        fbstat:=[];
        acs:='s'+cstr(thisuser.sl)+'d'+cstr(thisuser.dsl);
        ulacs:='s'+cstr(thisuser.sl)+'d'+cstr(thisuser.dsl);
        nameacs:='s'+cstr(thisuser.sl)+'d'+cstr(thisuser.dsl);
      end;
      memuboard:=tempuboard;
    end;
  end;
end;

(* File 10 Functions ------------------------------------------ *)

procedure creditfile(var u:userrec; un:integer; var f:ulfrec; credit:boolean);
var rfpts:real;
    gotpts:longint;
begin
  if (not systat^.fileptratio) then
    gotpts:=0
  else begin
    rfpts:=(f.blocks/8)/systat^.fileptcompbasesize;
    gotpts:=round(rfpts*systat^.fileptcomp);
    if (gotpts<1) then gotpts:=1;
  end;
  if (credit) then
    sprompt('|YAwarding upload credits: ')
  else
    sprompt('|YTaking away upload credits: ');
  prompt('1 file, '+cstrl(f.blocks div 8)+'k');
  if (credit) then begin
    inc(u.uploads);
    inc(u.uk,f.blocks div 8);
  end else begin
    dec(u.uploads);
    dec(u.uk,f.blocks div 8);
  end;
  if (systat^.fileptratio) then begin
    prompt(', '+cstrl(gotpts)+' file points');
    if (credit) then
      inc(u.filepoints,gotpts)
    else
      dec(u.filepoints,gotpts);
  end;
  print('.');
  saveurec(u,un);
  if (un=usernum) then showudstats;
end;


procedure resetverbose(curfile:longint);  {-1 if none}
var u:userrec;        f:ulfrec;           v:verbrec;
    c:char;           li:longint;         ff:file;
    r:real;           dt:datetimerec;     convtime:real;
    s,fl,s1,s2:astr;
    x,oldfileboard,dbn,pl:integer;
    ok,convt,done,espace,nospace:boolean;
    t:text;
begin
  fiscan(pl);
  if (filesize(ulff)=0) then
  begin
    print('No files exist.');
    close(ulff);
    exit;
  end;
  if (curfile=-1) then curfile:=0;
  cls;
  c:=#0;
  
  
  repeat
  
    seek(ulff,curfile);
    read(ulff,f);
    
     
      
    with f do
    begin
      if (c in [#0,^M,'[',']','D','M','E']) then
      begin
        ansig(1,1);
        sprint('|WFile Manager ['+cstr(curfile)+'/'+cstr(filesize(ulff)-1)+']|LC');
        nl;
        sprint('|K[|C1|K] |cFilename          |w'+mlnnomci(filename,18)+' '+mlnnomci(description,38)+'|LC');
        li:=blocks; li:=li*128;
        sprint('|K[|C2|K] |cFilesize          |w'+mn(li,18));
        r:=rte*blocks; r2dt(r,dt);
        sprint('|K[|C3|K] |cUploader          |w'+mlnnomci(caps(stowner),18));
        sprint('|K[|C4|K] |cUploader user #   |w'+mn(owner,18));
        sprint('|K[|C5|K] |cDate uploaded     |w'+mln(date,18));        
        sprint('|K[|C6|K] |cTimes downloaded  |w'+mn(nacc,18));
        sprint('|K[|C7|K] |cFile points       |w'+mn(filepoints,18));
        sprint('|K[|C8|K] |cValidated file    |w'+mln(syn(not (notval in filestat)),18));
        sprint('|K[|C9|K] |cResume flag       |w'+mln(syn(resumelater in filestat),18));
        sprint('|K[|C0|K] |cOffline file      |w'+mln(syn(isrequest in filestat),18));
        nl;
        sprint('|K[|CD|K] |cDelete file|LC');
        sprint('|K[|CE|K] |cEdit description');
        sprint('|K[|CI|K] |cImport file description and update comment');
        sprint('|K[|CM|K] |cMove file');
        sprint('|K[|CW|K] |cWithdraw credit');
        sprint('|K[|CZ|K] |cRemove Verbose');
        sprint('|K[|C!|K] |cdate num          |w'+mn(daten,18));
        nl;
        sprompt('|wCommand |K[|C[|K/|C]|K/|CQ|c:uit|K] |W');
      end;
          
      ansig(22,2);
      sprompt(#32+^H+'|W');      
      onek(c,'Q1234567890IDEMWZ[]'^M);
      case c of
        '[':
           begin
             f.daten := 1;
             f.date := '01/01/04';
             f.vpointer:=-1;
             seek(ulff,curfile);
             write(ulff,f);
             if (curfile<=0) then curfile:=pl else dec(curfile);             
           end;
        ']':begin
             f.daten := 1;
             f.date := '01/01/04';
             f.vpointer:=-1;
             seek(ulff,curfile);
             write(ulff,f);           
             if (curfile>=pl) then curfile:=0 else inc(curfile);           
           end;
  
      end;
    end;
    
    if not (c in ['[',']','D','M']) then
    begin
      seek(ulff,curfile);
      write(ulff,f);
    end;
    
    
    if (filesize(ulff)=0) then c:='Q';
  until (c='Q') or (hangup);
  close(ulff);
end;

procedure editfiles(curfile:longint);  {-1 if none}
var u:userrec;        f:ulfrec;           v:verbrec;
    c:char;           li:longint;         ff:file;
    r:real;           dt:datetimerec;     convtime:real;
    s,fl,s1,s2:astr;
    x,oldfileboard,dbn,pl:integer;
    ok,convt,done,espace,nospace:boolean;
    t:text;
begin
  fiscan(pl);
  if (filesize(ulff)=0) then
  begin
    print('No files exist.');
    close(ulff);
    exit;
  end;
  if (curfile=-1) then curfile:=0;
  cls;
  c:=#0;
  assign(verbf,systat^.datapath+'VERBOSE.DAT');
  repeat
  
    seek(ulff,curfile);
    read(ulff,f);
    
    if (f.vpointer<>-1) then
    begin
      setfileaccess(readwrite,denynone);
      reset(verbf);
      seek(verbf,f.vpointer);
      read(verbf,v);
      x:=1;
      while (x<=9) and (v.descr[x]<>'') do inc(x);
      if (x<10) then for li:=x to 9 do v.descr[li]:='';
      seek(verbf,f.vpointer);
      write(verbf,v);
      close(verbf);
    end else
      fillchar(v,sizeof(v),#0);
      
      
    with f do
    begin
      if (c in [#0,^M,'[',']','D','M','E']) then
      begin
        ansig(1,1);
        sprint('|WFile Manager ['+cstr(curfile)+'/'+cstr(filesize(ulff)-1)+']|LC');
        nl;
        sprint('|K[|C1|K] |cFilename          |w'+mlnnomci(filename,18)+' '+mlnnomci(description,38)+'|LC');
        li:=blocks; li:=li*128;
        sprint('|K[|C2|K] |cFilesize          |w'+mn(li,18)+' '+mlnnomci(v.descr[1],38)+'|LC');
        r:=rte*blocks; r2dt(r,dt);
        sprint('|K[|C3|K] |cUploader          |w'+mlnnomci(caps(stowner),18)+' '+mlnnomci(v.descr[2],38)+'|LC');
        sprint('|K[|C4|K] |cUploader user #   |w'+mn(owner,18)+' '+mlnnomci(v.descr[3],38)+'|LC');
        sprint('|K[|C5|K] |cDate uploaded     |w'+mln(date,18)+' '+mlnnomci(v.descr[4],38)+'|LC');        
        sprint('|K[|C6|K] |cTimes downloaded  |w'+mn(nacc,18)+' '+mlnnomci(v.descr[5],38)+'|LC');
        sprint('|K[|C7|K] |cFile points       |w'+mn(filepoints,18)+' '+mlnnomci(v.descr[6],38)+'|LC');
        sprint('|K[|C8|K] |cValidated file    |w'+mln(syn(not (notval in filestat)),18)+' '+
                                                  mlnnomci(v.descr[7],38)+'|LC');
        sprint('|K[|C9|K] |cResume flag       |w'+mln(syn(resumelater in filestat),18)+' '+
                                                  mlnnomci(v.descr[8],38)+'|LC');
        sprint('|K[|C0|K] |cOffline file      |w'+mln(syn(isrequest in filestat),18)+' '+
                                                  mlnnomci(v.descr[9],38)+'|LC');
        nl;
        sprint('|K[|CD|K] |cDelete file|LC');
        sprint('|K[|CE|K] |cEdit description');
        sprint('|K[|CI|K] |cImport file description and update comment');
        sprint('|K[|CM|K] |cMove file');
        sprint('|K[|CW|K] |cWithdraw credit');
        sprint('|K[|CZ|K] |cRemove Verbose');        
        sprint('|K[|C!|K] |cdate num          |w'+mn(daten,18));
        nl;
        sprompt('|wCommand |K[|C[|K/|C]|K/|CQ|c:uit|K] |W');
      end;
          
      ansig(22,2);
      sprompt(#32+^H+'|W');      
      onek(c,'Q1234567890IDEMWZ[]'^M);
      case c of
        '1':begin
              s:=filename;
              inputxy(23,3,s,-12);
              if (s<>'') and (align(s)<>filename) then
              begin
                if ((exist(memuboard.dlpath+s)) and (exist(memuboard.dlpath+sqoutsp(filename)))) then
                  sprompt('|I3603|wFilename already used. Press a key..|PK|I3603|LC')
                else
                begin
                  assign(ff,memuboard.dlpath+filename);
                  {$I-} rename(ff,memuboard.dlpath+s); {$I+}
                  x:=ioresult;
                  filename:=align(s);
                end;
              end;
              sprompt('|w|I2303'+mlnnomci(filename,18));
            end;
        '2':begin
              li:=blocks; li:=li*128;
              li:=inputnumxy(23,4,li,9,0,999999999);
              blocks:=li div 128;
            end;
        '3':begin
              stowner:=caps(stowner);
              inputxy(23,5,stowner,18);
              stowner:=allcaps(stowner);
              sprompt('|w|I2305'+mlnnomci(caps(stowner),18));
            end;
        '4':inputnumxy(23,6,owner,5,0,32767);
        '5':begin
              s:=date;
              inputxy(23,7,s,8);
              if (s<>'') and (s[3]='/') and (s[6]='/') then
              begin
                date:=s;
                daten:=daynum(s);
              end;
              sprompt('|I2307'+mln(date,18));
            end;
        '!':daten:=inputnumxy(23,8,daten,5,0,32767);
        '6':nacc:=inputnumxy(23,8,nacc,5,0,32767);
        '7':filepoints:=inputnumxy(23,9,filepoints,5,0,32767);
        '8':begin
              ok:=not (notval in filestat);
              if (notval in filestat) then exclude(filestat,notval)
                                      else include(filestat,notval);
              switchyn(23,10,ok);
            end;
        '9':begin
              ok:=resumelater in filestat;
              if (resumelater in filestat) then exclude(filestat,resumelater)
                                           else include(filestat,resumelater);
              switchyn(23,11,ok);
            end;
        '0':begin
              ok:=isrequest in filestat;
              if (isrequest in filestat) then exclude(filestat,isrequest)
                                         else include(filestat,isrequest);
              switchyn(23,12,ok);
            end;
        'I':begin
              cls;
              convt:=TRUE; ok:=TRUE;
              s:=sqoutsp(f.filename);
              arcstuff(ok,convt,f.blocks,convtime,FALSE,memuboard.dlpath,s,f,v);
              writefv(curfile,f,v);
              pausescr;
              cls;
              c:=#0;
            end;
        'W':if (owner>0) then
            begin
              loadurec(u,owner);
              creditfile(u,owner,f,FALSE);
            end;
        'D':begin
              deleteff(curfile,pl,TRUE);
              s:='Removed "'+sqoutsp(f.filename)+'" from Dir#'+cstr(fileboard);
              if (exist(memuboard.dlpath+f.filename)) then
              if pynq('|I2314Erase file too') then
              begin
                assign(ff,memuboard.dlpath+f.filename);
                {$I-} erase(ff); {$I+}
                if (ioresult=0) then
                  s:=s+' [FILE DELETED]'
                else
                  s:='Tried deleting "'+sqoutsp(f.filename)+'" from Dir#'+cstr(fileboard);
              end;
              sysoplog(s);
              if (curfile>pl) then dec(curfile);
            end;
        'M':begin
              done:=FALSE;
              cls;
              fbaselist;
              nl;
              repeat
                sprompt('|wMove file |K[|C#|c=destination|K/|CQ|c:uit|K] |W');
                input(s,3);
                dbn:=ccuboards[0][value(s)];
                if (s='Q') or ((dbn=0) and (s<>'0')) then
                  done:=TRUE
                else
                if (dbn<0) or (dbn>maxulb) then
                  sprint('|RInvalid file base number.')
                else
                begin
                  oldfileboard:=fileboard;
                  changefileboard(dbn);
                  if (fileboard=oldfileboard) then
                    sprint('|RCan''t move to the same directory!')
                  else
                  begin
                    fileboard:=oldfileboard;
                    done:=TRUE;
                    nl;
                    loaduboard(fileboard);
                    fl:=memuboard.dlpath+f.filename;
                    s1:=fexpand(bslash(FALSE,memuboard.dlpath));
                    loaduboard(dbn);
                    sprint('Moving file to '+memuboard.name+' ...');
                    s2:=fexpand(bslash(FALSE,memuboard.dlpath));
                    ok:=TRUE;
                    sprint('Orig-path: "'+s1+'" ('+cstrl(freek(exdrv(s1)))+'k free)');
                    sprint('Dest-path: "'+s2+'" ('+cstrl(freek(exdrv(s2)))+'k free)');
                    if (s1=s2) then
                    begin
                      sprint('|RUnable to move. Directory paths are the same.');
                      espace:=TRUE;
                      ok:=TRUE;
                    end else
                      if (exist(fl)) then
                      begin
                        espace:=TRUE;
                        assign(ff,fl);
                        {$I-}
                        SetFileAccess(ReadOnly,DenyNone);
                        reset(ff,1);
                        close(ff);
                        {$I+}
                        sprompt('Progress: ');
                        movefile(ok,nospace,TRUE,fl,memuboard.dlpath+f.filename);
                        if (ok) then nl;
                        if (not ok) then begin
                          sprompt('|RMove failed');
                          if (not nospace) then nl else
                            sprompt(' - Insuffient space on drive '+chr(x+64)+':');
                          sprint('!');
                        end;
                      end else
                        sprint('File does not actually exist.');
                    if ((espace) and (ok)) or (not exist(fl)) then
                    begin
                      sprompt('|CMoving file record ...');
                      deleteff(curfile,pl,FALSE);
                      oldfileboard:=fileboard;
                      fileboard:=dbn;
                      close(ulff);
                      fiscan(pl);
                      if (baddlpath) then exit;
                      v.descr[1]:=#1#1#0#1#1;
                      newff(f,v);
                      close(ulff);
                      fileboard:=oldfileboard;
                      fiscan(pl);
                      if (baddlpath) then exit;
                      sysoplog('Moved "'+sqoutsp(f.filename)+'" from Dir#'+
                               cstr(fileboard)+' to Dir#'+cstr(dbn));
                    end;
                  end;
                end;
              until ((done) or (hangup));
              if (curfile>pl) then dec(curfile);
              sprompt('|LF|PA|SC');
            end;
            {Remove Verbose}
        'Z':begin
              if (f.vpointer<>-1) then f.vpointer:=-1;
            end;
        '[':if (curfile<=0) then curfile:=pl else dec(curfile);
        ']':if (curfile>=pl) then curfile:=0 else inc(curfile);
        'E':begin
              assign(verbf,systat^.datapath+'VERBOSE.DAT');
              assign(t,'I_EDDESC.'+cstr(nodenum));
              rewrite(t);
              writeln(t,description);
              if (vpointer<>-1) then
              begin
                setfileaccess(readwrite,denynone);
                reset(verbf);
                seek(verbf,vpointer);
                read(verbf,v);
                close(verbf);
              
                for x:=1 to 9 do
                  if ((v.descr[x]<>'') and (v.descr[x]<>' ')) then writeln(t,v.descr[x]) else x:=9;
                end;                
              
              close(t);
              cls;
              tedit('I_EDDESC.'+cstr(nodenum));
              setfileaccess(readwrite,denynone);
              reset(t);
              if (not eof(t)) then
              begin
                readln(t,s);
                if (s='') then s:=' ';
                if (length(s)>50) then s:=copy(s,1,50);
                description:=s;
              end;
              if (not eof(t)) then
              begin
                fillchar(v,sizeof(v),#0);
                x:=1;
                while (x<=9) and (not eof(t)) do
                begin
                  readln(t,s);                  
                  if (length(s)>50) then s:=copy(s,1,50);
                  if (s<>'') then 
                  begin 
                    v.descr[x]:=s;
                    inc(x);
                  end;
                end;
                if (vpointer=-1) then vpointer:=nfvpointer;
                setfileaccess(readwrite,denynone);
                reset(verbf);
                seek(verbf,f.vpointer);
                write(verbf,v);
                close(verbf);
              end else
                if (vpointer<>-1) then
                begin
                  v.descr[1]:='';
                  setfileaccess(readwrite,denynone);
                  reset(verbf);
                  seek(verbf,f.vpointer);
                  write(verbf,v);
                  close(verbf);
                  vpointer:=-1;
                end;
              close(t);
              erase(t);
            end;
      end;
    end;
    
    if not (c in ['[',']','D','M']) then
    begin
      seek(ulff,curfile);
      write(ulff,f);
    end;
    
    
    if (filesize(ulff)=0) then c:='Q';
  until (c='Q') or (hangup);
  close(ulff);
end;

procedure validatefiles;
var i:integer;
    c:char;
    abort,next,isglobal,ispoints,isprompt:boolean;
    oldconf:char;

  procedure valfiles(b:integer; var abort,next:boolean);
  var u:userrec;
      f:ulfrec;
      s:astr;
      lng:longint;
      oldboard,pl,rn:integer;
      shownalready:boolean;
  begin
    oldboard:=fileboard;
    if (fileboard<>b) then changefileboard(b);
    if (fileboard=b) then begin
      recno('*.*',pl,rn);
      shownalready:=FALSE; abort:=FALSE; next:=FALSE;
      while (rn<>-1) and (not abort) and (not hangup) do begin
        seek(ulff,rn); read(ulff,f);
        if (notval in f.filestat) and
           (not (resumelater in f.filestat)) then begin
          if (not shownalready) then begin
            nl;
            sprint('Validating '+memuboard.name+'|w #'+
                   cstr(fileboard));
            nl;
            shownalready:=TRUE;
          end;

          lng:=f.blocks; lng:=lng*128;
          sprint('Filename   : |C'+'"'+f.filename+'"');
          sprint('Description: |C'+f.description);
          sprint('Size/points: |C'+cstrl(lng)+' bytes / '+
                 cstr(f.filepoints)+' pts');
          sprint('UL''d by    : |C'+caps(f.stowner)+' #'+cstr(f.owner));
          nl;
          loadurec(u,f.owner);
          if (isprompt) then begin
            if (ispoints) then begin
              prt('Points for file (<CR>=Skip,Q=Quit) : '); input(s,5);
              if (s='Q') then abort:=TRUE;
              if ((s<>'') and (s<>'Q')) then begin
                f.filepoints:=value(s);
                exclude(f.filestat,notval);
                seek(ulff,rn); write(ulff,f);
                if (not aacs1(u,f.owner,systat^.ulvalreq)) then
                  creditfile(u,f.owner,f,TRUE);
                prt('Points for |Y'+caps(f.stowner)+' #'+
                    cstr(f.owner)+'|B (-999..999) : ');
                input(s,5);
                if (s<>'') then
                  if (f.owner=usernum) then
                    inc(thisuser.filepoints,value(s))
                  else begin
                    inc(u.filepoints,value(s));
                    saveurec(u,f.owner);
                  end;
              end;
              nl;
            end else begin
              repeat
                prt('Validate (Y/N,V=View,Q=Quit) ? '); onek(c,'QNVY');
                case c of
                  'Q':abort:=TRUE;
                  'V':begin
                        abort:=FALSE; next:=FALSE;
                        lfi(sqoutsp(memuboard.dlpath+f.filename),abort,next);
                        abort:=FALSE; next:=FALSE;
                      end;
                  'Y':begin
                        exclude(f.filestat,notval);
                        seek(ulff,rn); write(ulff,f);
                        if (not aacs1(u,f.owner,systat^.ulvalreq)) then
                          creditfile(u,f.owner,f,TRUE);
                      end;
                end;
              until ((c<>'V') or (hangup));
              nl;
            end;
          end else begin
            exclude(f.filestat,notval);
            seek(ulff,rn); write(ulff,f);
            if (not aacs1(u,f.owner,systat^.ulvalreq)) then
              creditfile(u,f.owner,f,TRUE);
          end;
        end;

        nrecno('*.*',pl,rn);
        wkey(abort,next);
      end;
      close(ulff);
    end;
    fileboard:=oldboard;
  end;

begin
  nl;
  print('Validate files -');
  nl;
  prt('Prompt for validation (Y)es, (N)o, (P)oints validation ? ');
  onek(c,'QNPY');
  if (c='Q') then exit;

  ispoints:=(c='P');
  isprompt:=(c<>'N');
  oldconf:=thisuser.conference;
  isglobal:=pynq('Search all directories');
  if isglobal then if pynq('Ignore conferences') then thisuser.conference:='@';
  nl;

  abort:=FALSE; next:=FALSE;
  if (isglobal) then begin
    i:=0;
    while (i<=maxulb) and (not abort) and (not hangup) do begin
      if (fbaseac(i)) then valfiles(i,abort,next);
      inc(i);
      wkey(abort,next);
      if (next) then abort:=FALSE;
    end;
  end else
    valfiles(fileboard,abort,next);
  thisuser.conference:=oldconf;
end;



(* File 9 Functions ------------------------------------------- *)

var J:integer;
function align2(s:astr):astr;
begin
  if pos('.',s)=0 then s:=mln(s,12)
    else s:=mln(copy(s,1,pos('.',s)-1),8)+' '+mln(copy(s,pos('.',s)+1,3),3);
  align2:=s;
end;

function info:astr;
var pm:char;
    i:integer;
    s:astr;
    dt:datetime;

  function ti(i:integer):astr;
  var s:astr;
  begin
    ti:=tch(cstr(i));
  end;

begin
  s:=dirinfo.name;
  if (dirinfo.attr and directory)=directory then s:=mln(s,13)+'<DIR>   '
    else s:=align2(s)+'  '+mrn(cstrl(dirinfo.size),7);
  unpacktime(dirinfo.time,dt);
  with dt do begin
    if hour<13 then pm:='a' else begin pm:='p'; hour:=hour-12; end;
    s:=s+'  '+mrn(cstr(month),2)+'-'+ti(day)+'-'+ti(year-1900)+
             '  '+mrn(cstr(hour),2)+':'+ti(min)+pm;
  end;
  info:=s;
end;

procedure dir(cd,x:astr; expanded:boolean);
var abort,next,nofiles:boolean;
    s:astr;
    onlin:integer;
    dfs:longint;
    numfiles:integer;
begin
  if (copy(cd,length(cd),1)<>'\') then cd:=cd+'\';
  abort:=FALSE;
  cd:=cd+x;
  if (fso) then begin
    printacr('|c Directory of |C'+copy(cd,1,length(cd)),abort,next);
    nl;
  end;
  s:=''; onlin:=0; numfiles:=0; nofiles:=TRUE;
  ffile(cd);
  while (found) and (not abort) do begin
    if (not (dirinfo.attr and directory=directory)) or (fso) then
      if (not (dirinfo.attr and volumeid=volumeid)) then
        if ((not (dirinfo.attr and dos.hidden=dos.hidden)) or (usernum=1)) then
          if ((dirinfo.attr and dos.hidden=dos.hidden) and
             (not (dirinfo.attr and directory=directory))) or
             (not (dirinfo.attr and dos.hidden=dos.hidden)) then begin
            nofiles:=FALSE;
            if (expanded) then printacr(info,abort,next)
            else begin
              inc(onlin);
              s:=s+align2(dirinfo.name);
              if onlin<>5 then s:=s+'    ' else begin
                printacr(s,abort,next);
                s:=''; onlin:=0;
              end;
            end;
            inc(numfiles);
          end;
    nfile;
  end;
  if (not found) and (onlin in [1..5]) then printacr(s,abort,next);
  dfs:=freek(exdrv(cd));
  if (nofiles) then s:='|CFile not found'
    else s:='|C'+mrn(cstr(numfiles)+'|c File(s)',17);
  printacr(s+'|C'+mrn(cstrl(dfs*1024),10)+'|c bytes free',abort,next);
end;

procedure dirf(expanded:boolean);
var fspec:astr;
    abort,next,all:boolean;
begin
  nl;
  print('Raw directory.');
  gfn(fspec); abort:=FALSE; next:=FALSE;
  nl;
  loaduboard(fileboard);
  dir(memuboard.dlpath,fspec,expanded);
end;

procedure deleteff(rn:integer; var pl:integer; killverbose:boolean);
var i:integer;
    f:ulfrec;
    v:verbrec;
begin
  if (rn<=pl) and (rn>-1) then begin
    dec(pl);
    seek(ulff,rn); read(ulff,f);
    if (f.vpointer<>-1) and (killverbose) then begin
      assign(verbf,systat^.datapath+'VERBOSE.DAT');
      SetFileAccess(ReadWrite,DenyNone);
      reset(verbf);
      seek(verbf,f.vpointer); read(verbf,v);
      if (ioresult=0) then begin
        v.descr[1]:='';
        seek(verbf,f.vpointer); write(verbf,v);
      end;
      close(verbf);
    end;
    for i:=rn to pl do begin
      seek(ulff,i+1); read(ulff,f);
      seek(ulff,i); write(ulff,f);
    end;
    seek(ulff,filesize(ulff)-1); truncate(ulff);
  end;
end;

procedure setdirs;
var s:astr;
    i:integer;
    done:boolean;
begin
  nl;
  fbaselist; nl;
  done:=FALSE;
  repeat
    spstr(119); input(s,3);
    if (s='Q') then done:=TRUE;
    if (s='?') then begin fbaselist; nl; end;
    i:=ccuboards[0][value(s)];
    if (fbaseac(i)) then { loads memuboard }
      if (i>=0) and (i<=maxulb) and
         (length(s)>0) and (s[1] in ['0'..'9']) then begin
        nl;
        sprompt(memuboard.name+'|C');
        if (i in zscanr.fzscan) then begin
          sprint(' will NOT be scanned.');
          exclude(zscanr.fzscan,i);
        end else begin
          sprint(' WILL be scanned.');
          include(zscanr.fzscan,i);
        end;
        nl;
      end;
  until (done) or (hangup);
  lastcommandovr:=TRUE;
  savezscanr;
end;

procedure pointdate;
var s:astr;
begin
  clearwaves;
  addwave('DA',newdate,txt);
  spstr(416);
  clearwaves;
  inputdate(s);
  if (s<>'') then if (daynum(s)=0) then spstr(417) else newdate:=s;
  clearwaves;
  addwave('DA',newdate,txt);
  spstr(418);
  clearwaves;
end;

(*
procedure yourfileinfo;
var abort,next:boolean;
begin
  nl; abort:=FALSE; next:=FALSE;
  with thisuser do begin
    cl(ord('B'));
    sprompt('Ú'); for j:=1 to 76 do sprompt ('Ä'); sprint ('¿');
    sprint ('|B³ |WUser Name|B..........|b: |C'+mln(name,53)+'|B ³');
    sprint ('|B³ |WSecurity Lvl|B.......|b: |C'+mln(cstr(sl),53)+'|B ³');
    sprint ('|B³ |WDownload Sec|B.......|b: |C'+mln(cstr(dsl),53)+'|B ³');
    sprint ('|B³ |WFile points|B........|b: |C'+mln(cstr(filepoints),53)+'|B ³');
    sprint ('|B³ |WDL Totals in K|B.....|b: |C'+mln(cstrl(dk),53)+'|B ³');
    sprint ('|B³ |WUL Totals in K|B.....|b: |C'+mln(cstrl(uk),53)+'|B ³');
   sprompt ('|B³ |WFile point status|B..|b: |C');
    if (fnofilepts in thisuser.ac) then
    sprint(mln('Special flag -  No file point check!',53)+'|B ³')
    else
    if (aacs(systat^.nofilepts)) then
    sprint(mln('High security level -  No file point check!',53)+'|B ³')
    else
    sprint(mln('Active according to setting on each file.',53)+'|B ³');
    if (not systat^.fileptratio) then
    sprint('|B³                      |C'+mln('Auto file point compensation inactive.',53)+'|B ³')
    else begin
    sprint('|B³                      |C'+mln('File point compensation of '+cstr(systat^.fileptcomp)+' to 1.',53)+'|B ³');
    sprint('|B³                      |C'+mln('Base compensation size of '+cstr(systat^.fileptcompbasesize)+'k.',53)+'|B ³');
    end;
    sprompt('|B³ |WUL/DL ratio setting|b: |C');
    if (not systat^.uldlratio) then
      sprint(mln('|CInactive.',53)+'|B ³')
    else
      if ((fnodlratio in thisuser.ac) or (aacs(systat^.nodlratio))) then
        sprint(mln('|C- No ratio checking -',53)+'|B ³')
      else begin
         sprint(mln('|C  1 upload for every '+cstr(systat^.dlratio[thisuser.sl])+' downloads',53)+'|B ³');
         sprint('|B³                      '+mln('|C  1k upload for every '+
         cstr(systat^.dlkratio[thisuser.sl])+' downloaded',53)+'|B ³');
       end;
    sprompt('|BÀ'); for j:=1 to 76 do sprompt ('Ä'); sprint ('Ù');
  end;
end;
*)




{ new }
procedure listopts;
var f:ulfrec;
    abort,next:boolean;
    c,cc:char; i,k:integer;
    
    li:longint; 
    lst,iii,ldescp:integer;
    rr,s,s1,dd,dd2:astr;

  function siz(n:byte):byte;
  var l:byte;
  begin
    case n of 1:l:=13; 2:l:=6; 3:l:=5; end;
    siz:=l;
  end;

begin

  with f do begin
    filename:='ILLUSION.EXE';
    description:='Illusion BBS System 3.0';
    filepoints:=50;
    nacc:=666;
    ft:=0;
    blocks:=650;
    owner:=0;
    stowner:='Mercyful Fate';
    date:='08/01/03';
    daten:=0;
    vpointer:=-2;
    filestat:=[];
  end;


  with thisuser do
  repeat
    cls;
    abort:=FALSE; next:=FALSE;
    i:=0; bnp:=TRUE;

    printf('filehead.ans'); { Display File Header }   
    
    
    li:=f.blocks; li:=li*128;
    
    s:=+'|09|17'+mln(cstr(1),4)+'|w ';

    iii:=1;
    if Thisuser.flistc[1][1] > 0 then s:=s+'|B'+mln(f.filename,12);
    s:=s+' ';  
    if Thisuser.flistc[2][1] > 0 then
    begin
      if (f.blocks div 8>=20000) then
        s:=s+'|W'+mln(cstr((f.blocks div 8) div 1024)+'m',6)+' '
      else
        if (f.blocks div 8<9) then
          s:=s+'|W'+mln(cstr(f.blocks*128)+'b',6)+' '
      else
        s:=s+'|W'+mln(cstr(f.blocks div 8)+'k',6)+' ';
    end;  

    s:=s+' ';
    if Thisuser.flistc[3][1] > 0 then s:=s+'|C'+mln(cstr(f.filepoints),3);
    s:=s+' ';
    iii:=length(s);
    if Thisuser.flistc[5][1] > 0 then begin s:=s+'|w'+mln(f.description,25);
      s:=s+' '; 
      if Thisuser.flistc[8][1] > 0 then
      s:=s+'|C'+mln('+v',3);
    end;
    printacr(s,abort,next);    
       
    
    if Thisuser.flistc[6][1] > 0 then begin  
      for ldescp:=1 to iii-13 do sprompt(' ');     
      printacr('|CU|cploaded by: |C'+caps(f.stowner),abort,next);
    end;

    if Thisuser.flistc[7][1] > 0 then begin
      for ldescp:=1 to iii-13 do sprompt(' '); 
      printacr('|CU|cploaded on: |C'+f.date,abort,next);
    end;
      
    if Thisuser.flistc[4][1] > 0 then begin
      for ldescp:=1 to iii-13 do sprompt(' '); 
      printacr('|CN|cumber of D/L''s |W[|C'+cstr(f.nacc)+'|W]',abort,next);
    end;


    
    nl;
    nl;
    sprint('|C1,2,3,4,5,6,7,8|w: Toggle option');
    {sprint('|C!,@,#,$,%,^,&,*|w: Set color of option');}
    sprint('|wÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
    lcmds(14,3,'1Filename'  , '2File size');
    lcmds(14,3,'3File points',  '4Popularity');
    lcmds(14,3,'5Description' , '6Uploader');
    lcmds(14,3,'7Date'     ,  '8Verbose');
    
    nl;
    prt('Toggle (1-8,!-*,?=help,Q:uit): ');
    onek(c,'12345678!@#$%^&*?Q'^M);
    
    case c of
      '1'..'8':begin
                 k:=ord(c)-48;
                 if flistc[k][1]<=0 then
                   inc(flistc[k][1])
                 else
                   flistc[k][1]:=0;
               end;
      '!','@','#','$',
      '%','^','&','*'
               :begin
                 case c of '!':k:=1; '@':k:=2; '#':k:=3; '$':k:=4;
                           '%':k:=5; '^':k:=6; '&':k:=7; '*':k:=8; end;
                 repeat
                   prt('Enter color (?=list): ');
                   repeat getkey(cc) until pos(cc,'kbgcrmywKBGCRMYW?'^M)>0;
                   sprint(cc);
                   case cc of
                     ^M :;
                     '?':sprint('|BColors: |kk|bb|gg|cc|rr|mm|yy|ww|KK|BB|GG|CC|RR|MM|YY|WW');
                     else flistc[k][2]:=ord(cc);
                   end;
                 until cc<>'?';
               end;
           '?':begin
                 nl;
                 sprint('|C1,2,3,4,5,6,7,8|w: Toggle option');
                 sprint('|C!,@,#,$,%,^,&,*|w: Set color of option');
                 sprint('|wÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
                 lcmds(14,3,'1Filename'  , '2File size');
                 lcmds(14,3,'3File points',  '4Popularity');
                 lcmds(14,3,'5Description' , '6Uploader');
                 lcmds(14,3,'7Date'     ,  '8Verbose');
               end;
    end;
    nl;
  until c='Q';
  saveuf;
  lastcommandovr:=TRUE;
end;



(*
procedure listopts;
var f:ulfrec;
    abort,next:boolean;
    c,cc:char; i,k:integer;

  function siz(n:byte):byte;
  var l:byte;
  begin
    case n of 1:l:=13; 2:l:=6; 3:l:=5; end;
    siz:=l;
  end;

begin
  with f do begin
    filename:='ILLUSION.EXE';
    description:='Illusion BBS System';
    filepoints:=0;
    nacc:=99;
    ft:=0;
    blocks:=650;
    owner:=0;
    stowner:='Illusion Development';
    date:='01/01/96';
    daten:=0;
    vpointer:=-2;
    filestat:=[];
  end;

  cls; nl;

  with thisuser do
  repeat
    abort:=FALSE; next:=FALSE;
    i:=1; flistlines:=0; bnp:=TRUE;
    pfn(i,f,abort,next);
    flistlines:=0;
    KillQueue;
    if flistc[8][1]>0 then begin
      i:=1; for k:=1 to 3 do if flistc[k][1]>0 then inc(i,siz(k));
    end;

    nl;
    prt('Toggle (1-8,!-*,?=help,Q:uit): ');
    onek(c,'12345678!@#$%^&*?Q'^M);
    case c of
      '1'..'8':begin
                 k:=ord(c)-48;
                 if flistc[k][1]<=0 then
                   inc(flistc[k][1])
                 else
                   flistc[k][1]:=0;
               end;
      '!','@','#','$',
      '%','^','&','*'
               :begin
                 case c of '!':k:=1; '@':k:=2; '#':k:=3; '$':k:=4;
                           '%':k:=5; '^':k:=6; '&':k:=7; '*':k:=8; end;
                 repeat
                   prt('Enter color (?=list): ');
                   repeat getkey(cc) until pos(cc,'kbgcrmywKBGCRMYW?'^M)>0;
                   sprint(cc);
                   case cc of
                     ^M :;
                     '?':sprint('|BColors: |kk|bb|gg|cc|rr|mm|yy|ww|KK|BB|GG|CC|RR|MM|YY|WW');
                     else flistc[k][2]:=ord(cc);
                   end;
                 until cc<>'?';
               end;
           '?':begin
                 nl;
                 sprint('|C1,2,3,4,5,6,7,8|w: Toggle option');
                 sprint('|C!,@,#,$,%,^,&,*|w: Set color of option');
                 sprint('|wÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
                 lcmds(14,3,'1Filename'  , '2File size');
                 lcmds(14,3,'3File points',  '4Popularity');
                 lcmds(14,3,'5Description' , '6Uploader');
                 lcmds(14,3,'7Date'     ,  '8Verbose');
               end;
    end;
    nl;
  until c='Q';
  saveuf;
  lastcommandovr:=TRUE;
end;
*)




(* File 8 Functions ------------------------------------------- *)

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
    (* if (t2>nsl) then spstr(142)  - Remove Time Needed Check for Download
    else *)
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

        (* Removed, File point Bug
        
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
        *)

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


(* File 7 Functions ------------------------------------------- *)

procedure recvascii(fn:astr; var dok:boolean; tpb:real);
var f:file;
    r1:array[0..1023] of byte;
    byte_count,start_time:longint;
    bytes_this_line,kbyte_count,line_count:integer;
    b:byte;
    start,abort,error,done,timeo,kba,prompti,badf:boolean;
    c:char;

    procedure checkkb;
    var c:char;
    begin
      if (keypressed) then begin
        c:=readkey;
        if (c=#27) then begin
          abort:=TRUE; done:=TRUE; kba:=TRUE;
          spstr(403);
        end;
      end;
    end;

begin
  abort:=FALSE; done:=FALSE; timeo:=FALSE; kba:=FALSE; badf:=FALSE;
  line_count:=0; start:=FALSE;
  start_time:=trunc(timer); byte_count:=0;
  assign(f,fn);
  {$I-} rewrite(f,1); {$I+}
  if (ioresult<>0) then begin
    if (useron) then spstr(404);
    done:=TRUE; abort:=TRUE; badf:=TRUE;
  end;
  prompti:=pynq(getstr(405));
  if (useron) then spstr(406);
  while (not done) and (not hangup) do begin
    error:=TRUE;
    checkkb;
    if (kba) then begin
      done:=TRUE;
      abort:=TRUE;
    end;
    if (not kba) then
      if (prompti) then begin
        com_flush_rx;
        sendcom1('>');
      end;
    if (not done) and (not abort) and (not hangup) then begin
      start:=FALSE;
      error:=FALSE;
      checkkb;
      if (not done) then begin
        bytes_this_line:=0;
        repeat
          getkey(c); b:=ord(c);
          if (b=26) then begin
            start:=TRUE; done:=TRUE;
            nl;
            if (useron) then spstr(407);
          end else begin
            if (b<>10) then begin         (* ignore LF *)
              r1[bytes_this_line]:=b;
              bytes_this_line:=bytes_this_line+1;
            end;
          end;
        until (bytes_this_line>250) or (b=13) or (timeo) or (done);
        if (b<>13) then begin
          r1[bytes_this_line]:=13;
          bytes_this_line:=bytes_this_line+1;
        end;
        r1[bytes_this_line]:=10;
        bytes_this_line:=bytes_this_line+1;
        seek(f,byte_count);
        {$I-} blockwrite(f,r1,bytes_this_line); {$I+}
        if (ioresult<>0) then begin
          if (useron) then spstr(408);
          done:=TRUE; abort:=TRUE;
        end;
        inc(line_count);
        byte_count:=byte_count+bytes_this_line;
      end;
    end;
  end;
  if not badf then close(f);
  kbyte_count:=0;
  while (byte_count>1024) do begin
    inc(kbyte_count);
    byte_count:=byte_count-1024;
  end;
  if (byte_count>512) then inc(kbyte_count,1);
  if (hangup) then abort:=TRUE;
  if (abort) then erase(f)
  else begin
    clearwaves;
    addwave('LN',cstr(line_count),txt);
    addwave('KB',cstr(kbyte_count),txt);
    spstr(409);
    clearwaves;
    if (timer<start_time) then start_time:=start_time-24*60*60;
  end;
  dok:=not abort;
end;

procedure sendascii(fn:astr);
var f:file of char;
    i:integer;
    c,c1:char;
    abort:boolean;

  procedure ckey;
  begin
    checkhangup;
    while (not empty) and (not abort) and (not hangup) do begin
      if (hangup) then abort:=TRUE;
      c1:=inkey;
      if (c1=^X) or (c1=#27) or (c1=' ') then abort:=TRUE;
      if (c1=^S) then getkey(c1);
    end;
  end;

begin
  assign(f,fn);
  SetFileAccess(ReadOnly,DenyNone);
  {$I-} reset(f); {$I+}
  if (ioresult<>0) then spstr(382) else begin
    abort:=FALSE;
    spstr(410);
    repeat getkey(c) until (c=^M) or (hangup);
    while (not hangup) and (not abort) and (not eof(f)) do begin
      read(f,c); if (outcom) then sendcom1(c);
      if (c<>^G) then write(c);
      ckey;
    end;
    close(f);
    prompt(^Z);
    spstr(411);
  end;
end;

(* File 6 Functions ------------------------------------------- *)

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
  if ((not incom) and (not outcom)) then s1:=cstrl(modemr^.waitbaud) else s1:=spd;
  if ((not incom) and (not outcom)) then s2:=cstrl(modemr^.waitbaud) else s2:=realspd;
  s:=substall(cline,'%B',s1);
  s:=substall(s,'%E',s2);
  s:=substall(s,'%L',bproline2(protocol.dlflist));
  s:=substall(s,'%P',cstr(modemr^.comport));
  s:=substall(s,'%T',bproline2(protocol.templog));
  s:=substall(s,'%I',userip);
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

    (* Removed Not enough time Left
    if (tott>nsl) then begin
      spstr(137);
      spstr(139);
      exit;
    end;  
    *)
    
    (* Removed file point Bug
    
    end else if (thisuser.filepoints<tptsneed) and (tptsneed>0) and
     (not aacs(systat^.nofilepts)) and
     (not (fnofilepts in thisuser.ac)) and
     (not (fbnoratio in memuboard.fbstat)) then
    begin
      spstr(138);
      spstr(139);
      exit;
    end;
    *)

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

      
      
      { Remove After Transfer Stats }
      
      for n:=1 to numbatchfiles do begin
        delbatch(1);
      end;     
      
      
      
      (* figuresucc; *)
      
      (*
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
      {dec(thisuser.filepoints,tpts1);}

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
      *)
    

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
    printacr('|BÄÄ:ÄÄÄÄÄÄÄÄÄÄÄÄ ÄÄÄÄ ÄÄÄÄÄ ÄÄÄÄÄÄÄ ÄÄÄÄÄÄÄÄ',abort,next);

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

    printacr('|BÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ÄÄÄÄ ÄÄÄÄÄ ÄÄÄÄÄÄÄ ÄÄÄÄÄÄÄÄ',abort,next);
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