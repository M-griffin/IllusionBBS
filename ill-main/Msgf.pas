
(* Message, File Function, Broken off from File System *)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit MsgF;

interface

uses
  crt, dos,
  myio, execbat, common, common2;


const
   L_SIG=$04034b50;   {* ZIP local file header signature *}
   C_SIG=$02014b50;   {* ZIP central dir file header signature *}
   E_SIG=$06054b50;   {* ZIP end of central dir signature *}
   Z_TAG=$fdc4a7dc;   {* ZOO entry identifier *}
   
   EXTS=7;     {* number of default extensions *}
   
   filext:array[0..EXTS-1] of string[4] = (
    '.ZIP',   {* ZIP format archive *}
    '.ARJ',   {* ARJ format archive *}
    '.ARC',   {* ARC format archive *}
    '.PAK',   {* ARC format archive (PAK.EXE) *}
    '.ZOO',   {* ZOO format archive *}
    '.LZH',   {* LZH format archive *}
    '.RAR');  {* RAR format archive *}
    
type  
   zipfilerec=record   {* structure of ZIP archive file header *}
               version:integer;    {* version needed to extract *}
               bit_flag:integer;   {* general purpose bit flag *}
               method:integer;     {* compression method *}
               mod_time:integer;   {* last mod file time *}
               mod_date:integer;   {* last mod file date *}
               crc:longint;        {* CRC-32 *}
               c_size:longint;     {* compressed size *}
               u_size:longint;     {* uncompressed size *}
               f_length:integer;   {* filename length *}
               e_length:integer;   {* extra field length *}
             end;

   arjfilerec=record  {* structure of an ARJ archive file header *}
               FHeadSize:Byte;     {* *}
               ArcVer1:byte;       {* *}
               ArcVer2:Byte;       {* *}
               HostOS:byte;        {* *}
               ARJFlags:Byte;      {* *}
               Method:Byte;        {* compression method *}
               R1:byte;            {* *}
               R2:Byte;            {* *}
               mod_time:word;      {* modification time (DOS format) *}
               mod_date:word;      {* modification date (DOS format) *}
               C_size:LongInt;     {* compressed size *}
               U_Size:Longint;     {* uncompressed size *}
               CRC:LongInt;        {* CRC *}
               ENP:word;           {* *}
               FM:word;            {* *}
               HostData:Word;      {* *}
             end;

   arcfilerec=record   {* structure of ARC archive file header *}
               filename:array[0..12] of char; {* filename *}
               c_size:longint;     {* compressed size *}
               mod_date:integer;   {* last mod file date *}
               mod_time:integer;   {* last mod file time *}
               crc:integer;        {* CRC *}
               u_size:longint;     {* uncompressed size *}
             end;

   zoofilerec=record   {* structure of ZOO archive file header *}
               tag:longint;     {* tag -- redundancy check *}
               typ:byte;        {* type of directory entry (always 1 for now) *}
               method:byte;     {* 0 = Stored, 1 = Crunched *}
               next:longint;    {* position of next directory entry *}
               offset:longint;  {* position of this file *}
               mod_date:word;   {* modification date (DOS format) *}
               mod_time:word;   {* modification time (DOS format) *}
               crc:word;        {* CRC *}
               u_size:longint;  {* uncompressed size *}
               c_size:longint;  {* compressed size *}
               major_v:char;    {* major version number *}
               minor_v:char;    {* minor version number *}
               deleted:byte;    {* 0 = active, 1 = deleted *}
               struc:char;      {* file structure if any *}
               comment:longint; {* location of file comment (0 = none) *}
               cmt_size:word;   {* length of comment (0 = none) *}
               fname:array[0..12] of char; {* filename *}
               var_dirlen:integer; {* length of variable part of dir entry *}
               tz:char;         {* timezone where file was archived *}
               dir_crc:word;    {* CRC of directory entry *}
             end;

   lzhfilerec=record   {* structure of LZH archive file header *}
               h_length:byte;   {* length of header *}
               h_cksum:byte;    {* checksum of header bytes *}
               method:array[1..5] of char; {* compression type "-lh#-" *}
               c_size:longint;  {* compressed size *}
               u_size:longint;  {* uncompressed size *}
               mod_time:integer;{* last mod file time *}
               mod_date:integer;{* last mod file date *}
               attrib:integer;  {* file attributes *}
               f_length:byte;   {* length of filename *}
               crc:integer;     {* crc *}
             end;

   rarheaderrec=record
               b:array[1..7] of byte;
             end;
   rarfilerec=record
                packsize:longint;
                unpacksize:longint;
                hostos:byte; { 0 dos 1 os/2 }
                filecrc:longint;
                mod_time:integer;
                mod_date:integer;
                rarver:byte;
                method:byte;
                fnamesize:integer;
                attr:longint;
              end;

   outrec=record   {* output information structure *}
           filename:string[255];             {* output filename *}
           date:integer;                     {* output date *}
           time:integer;                     {* output time *}
           typ:integer;                      {* output storage type *}
           csize:longint;                    {* output compressed size *}
           usize:longint;                    {* output uncompressed size *}
         end;





var
  dirinfo:searchrec; found:boolean;
  accum_usize:longint;    {* uncompressed size accumulator *}
  accum_csize:longint;    {* compressed size accumulator *}
  filetype:integer;       {* file type (1=ZIP, 2=ARJ, 3=ARC, 4=LZH, 5=ZOO) *}
  files:integer;          {* number of files *}
  level:integer;          {* output directory level *}
  out:^outrec;
  aborted:boolean;

{*------------------------------------------------------------------------*}


procedure getgifspecs(fn:astr; var sig:astr; var x,y,c:word);
function isgifext(fn:astr):boolean;
function nfvpointer:longint;

procedure arcstuff(var ok,convt:boolean;    { if ok - if converted }
                   var blks:longint;        { # blocks     }
                   var convtime:real;       { convert time }
                   itest:boolean;           { whether to test integrity }
                   fpath:astr;              { filepath     }
                   var fn:astr;             { filename     }
                   var f:ulfrec;            { filerec      }
                   var v:verbrec);          { verbose      }

procedure  recvascii(fn:astr; var dok:boolean; tpb:real);
procedure  sendascii(fn:astr);  
function   okprot(prot:protrec; ul,dl,batch,resume:boolean):boolean;
procedure  dodl(fpneed:integer);
function   rte:real;
  
{*------------------------------------------------------------------------*}

procedure  zip_proc(var fp:file; var abort,next:boolean);
procedure  arj_proc(var fp:file; var abort,next:boolean);
procedure  arc_proc(var fp:file; var abort,next:boolean);
procedure  zoo_proc(var fp:file; var abort,next:boolean);
procedure  lzh_proc(var fp:file; var abort,next:boolean);
procedure  rar_proc(var fp:file; var abort,next:boolean);

{*------------------------------------------------------------------------*}
  
procedure  final(var abort,next:boolean);
function   mnz(l:longint; w:integer):astr;
procedure  details(var abort,next:boolean);
function   stripname(i:astr):astr;
procedure  abend(var abort,next:boolean; b:word);
function   getbyte(var fp:file):char;
procedure  lfi(fn:astr; var abort,next:boolean);
procedure  nfile;
procedure  ffile(fn:astr);
function   iswildcard(s:astr):boolean;
function   align(fn:astr):astr;  
  

{*------------------------------------------------------------------------*}
  
function   arcmci(src,fn,ifn,cmt:astr):astr;
procedure  arcdecomp(var ok:boolean; atype:integer; fn,fspec,s:astr);
procedure  arccomp(var ok:boolean; atype:integer; fn,fspec,s:astr);
procedure  arccomment(var ok:boolean; atype,cnum:integer; fn,s:astr);
procedure  arcintegritytest(var ok:boolean; atype:integer; fn,s:astr);
procedure  conva(var ok:boolean; otype,ntype:integer; tdir,ofn,nfn:astr);
procedure  listarctypes;
procedure  invarc;
function   arctype(s:astr):integer;
function   bproline2(cline:astr):astr;
function   bproline1(cline:astr):astr;
procedure  bproline(var cline:astr; filespec:astr);
function   findprot(cs:astr; ul,dl,batch,resume:boolean):integer;
procedure  showprots(ul,dl,batch,resume:boolean);
procedure  mpkey(var s:astr);
procedure  unlisted_download(s:astr);

procedure  star(s:astr);
function   bslash(b:boolean; s:astr):astr;
function   align2(s:astr):astr;
function   info:astr;
procedure  dir(cd,x:astr; expanded:boolean);  
function   substall(src,old,new:astr):astr;  
function   existdir2(s:astr):boolean;
procedure  movefile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);
procedure  copyfile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);  
procedure  purgedir2(s:astr);                {* erase all non-dir files in dir *}
procedure  send1(fn:astr; var dok,kabort:boolean);
procedure  receive1(fn:astr; resumefile:boolean; var dok,kabort,addbatch:boolean);

implementation

{*------------------------------------------------------------------------*}



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

function isgifext(fn:astr):boolean;
begin
  fn:=align(stripname(sqoutsp(fn)));
  fn:=allcaps(copy(fn,length(fn)-2,3));
  isgifext:=((fn='GIF') or (fn='GYF'));
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
        if exist(modemr^.temppath+'ARCHIVE\FILE_ID.DIZ') then begin
          spstr(637);
          assign(t,modemr^.temppath+'ARCHIVE\FILE_ID.DIZ');
        end else
        if exist(modemr^.temppath+'ARCHIVE\DESC.SDI') then begin
          spstr(638);
          assign(t,modemr^.temppath+'ARCHIVE\DESC.SDI');
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
        purgedir2(modemr^.temppath+'ARCHIVE\');
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


function rte:real;
var i:word;
begin
  i:=value(realspd); if (i=0) then i:=modemr^.waitbaud;
  rte:=1241.6/i;
end;



{*------------------------------------------------------------------------*}

procedure zip_proc(var fp:file; var abort,next:boolean);
var zip:zipfilerec;
    buf:array[0..25] of byte;
    signature:longint;
    numread:word;
    i,stat:integer;
    c:char;
begin
  {* zip_proc - Process entry in ZIP archive.
  *}

  while (not aborted) do begin {* set up infinite loop (exit is within loop) *}
    blockread(fp,signature,4,numread); if numread<>4 then abend(abort,next,578);
    if abort then exit;
    if (signature=C_SIG) or (signature=E_SIG) or (aborted) then
      exit;
    if signature<>L_SIG then
      abend(abort,next,579);
    if abort then exit;
    blockread(fp,zip,26,numread); if numread<>26 then abend(abort,next,578);
    if abort then exit;
    out^.filename:='';
    for i:=1 to zip.f_length do    {* get filename *}
      out^.filename[i]:=getbyte(fp);
    out^.filename[0]:=chr(zip.f_length);
    if (zip.e_length>0) then         {* skip comment if present *}
      for i:=1 to zip.e_length do
        c:=getbyte(fp);
    out^.date:=zip.mod_date;
    out^.time:=zip.mod_time;
    out^.csize:=zip.c_size;
    out^.usize:=zip.u_size;
    case zip.method of
      0:out^.typ:=2;    {* Stored *}
      1:out^.typ:=9;    {* Shrunk *}
      2,3,4,5:
        out^.typ:=zip.method+8;  {* Reduced *}
      6:out^.typ:=15;   {* Imploded *}
      7,8:out^.typ:=16;   {* Deflated *}
    else
      out^.typ:=1;    {* Unknown! *}
    end;
    details(abort,next); if abort then exit;
    {$I-} seek(fp,filepos(fp)+zip.c_size); {$I+}  {* seek to next entry *}
    if (ioresult<>0) then abend(abort,next,580);
    if (abort) then exit;
  end;
end;

{*------------------------------------------------------------------------*}

procedure arj_proc(var fp:file; var abort,next:boolean);
Var arj:arjfilerec;
    ARJId:word;
    Hsize:word;
    numread:word;
    c:char;
    i:integer;
    firstone:boolean;
    nextone:longint;

begin
  {* arj_proc - Process entry in ARJ archive.
  *}

  firstone:=TRUE; nextone:=0;
  while (not aborted) do begin
    blockread(fp,ARJId,2,numread); if numread<>2 then abend(abort,next,578);
    if (abort) then exit;
    blockread(fp,Hsize,2,numread); if numread<>2 then abend(abort,next,578);
    if (abort) then exit;
    nextone:=filepos(fp);
    if (hsize<=0) or (aborted) then exit;
    blockread(fp,arj,30,numread); if (numread<>30) then abend(abort,next,578);
    if abort then exit;

    out^.filename:='';
    i:=0;
    repeat
      inc(i);
      c:=getbyte(fp);
      out^.filename[i]:=c;
    until c<=#0;
    out^.filename[0]:=chr(i-1);

    if (firstone) then nextone:=nextone+hsize+6
     else nextone:=nextone+hsize+arj.c_size+6; {* Where do we seek next? *}

    out^.date:=arj.mod_date;
    out^.time:=arj.mod_time;
    out^.csize:=arj.c_size;
    out^.usize:=arj.u_size;
    if arj.method=0 then
      out^.typ:=2
    else
      out^.typ:=arj.method+16;

    if (not firstone) then details(abort,next);
    firstone:=FALSE;
    if abort then exit;
    {$I-} seek(fp,nextone); {$I+} {* seek to next entry *}
    if (ioresult<>0) then abend(abort,next,580);
    if (abort) then exit;
  end;
end;

{*------------------------------------------------------------------------*}

procedure arc_proc(var fp:file; var abort,next:boolean);
var arc:arcfilerec;
    numread:word;
    i,typ,stat:integer;
    c:char;
begin
  {*  arc_proc - Process entry in ARC archive.
  *}

  repeat
    c:=getbyte(fp);
    typ:=ord(getbyte(fp));   {* get storage method *}
    case typ of
      0:exit;                {* end of archive file *}
      1,2:out^.typ:=2;        {* Stored *}
      3,4:out^.typ:=typ;      {* Packed & Squeezed *}
      5,6,7:out^.typ:=typ;    {* crunched *}
      8,9,10:out^.typ:=typ-2; {* Crunched, Squashed & Crushed *}
      30:out^.typ:=0;         {* Directory *}
      31:dec(level);         {* end of dir (not displayed) *}
    else
         out^.typ:=1;         {* Unknown! *}
    end;
    if typ<>31 then begin    {* get data from header *}
      blockread(fp,arc,23,numread); if numread<>23 then abend(abort,next,578);
      if abort then exit;
      if typ=1 then          {* type 1 didn't have c_size field *}
        arc.u_size:=arc.c_size
      else begin
        blockread(fp,arc.u_size,4,numread);
        if numread<>4 then abend(abort,next,578);
        if abort then exit;
      end;
      i:=0;
      repeat
        inc(i);
        out^.filename[i]:=arc.filename[i-1];
      until (arc.filename[i]=#0) or (i=13);
      out^.filename[0]:=chr(i);
      out^.date:=arc.mod_date;
      out^.time:=arc.mod_time;
      if typ=30 then begin
        arc.c_size:=0;            {* set file size entries *}
        arc.u_size:=0;            {* to 0 for directories *}
      end;
      out^.csize:=arc.c_size;   {* set file size entries *}
      out^.usize:=arc.u_size;   {* for normal files *}
      details(abort,next); if abort then exit;
      if typ<>30 then begin
        {$I-} seek(fp,filepos(fp)+arc.c_size); {$I+} {* seek to next entry *}
        if ioresult<>0 then abend(abort,next,580);
        if abort then exit;
      end;
    end;
  until (c<>#$1a) or (aborted);
  if not aborted then abend(abort,next,579);
end;

{*------------------------------------------------------------------------*}

procedure zoo_proc(var fp:file; var abort,next:boolean);
var zoo:zoofilerec;
    zoo_longname,zoo_dirname:string[255];
    numread:word;
    i,method:integer;
    namlen,dirlen:byte;
begin
  {*  zoo_proc - Process entry in ZOO archive.
   *}

  while (not aborted) do begin {* set up infinite loop (exit is within loop) *}
    blockread(fp,zoo,56,numread); if numread<>56 then abend(abort,next,578);
    if abort then exit;
    if zoo.tag<>Z_TAG then abend(abort,next,579);   {* abort if invalid tag *}
    if (abort) or (zoo.next=0) then exit;

    namlen:=ord(getbyte(fp)); dirlen:=ord(getbyte(fp));
    zoo_longname:=''; zoo_dirname:='';
    if namlen>0 then
      for i:=1 to namlen do   {* get long filename *}
        zoo_longname:=zoo_longname+getbyte(fp);
    if dirlen>0 then begin
      for i:=1 to dirlen do   {* get directory name *}
        zoo_dirname:=zoo_dirname+getbyte(fp);
      if copy(zoo_dirname,length(zoo_dirname),1)<>'/' then
        zoo_dirname:=zoo_dirname+'/';
    end;
    if zoo_longname<>'' then out^.filename:=zoo_longname
    else begin
      i:=0;
      repeat
        inc(i);
        out^.filename[i]:=zoo.fname[i-1];
      until (zoo.fname[i]=#0) or (i=13);
      out^.filename[0]:=chr(i);
      out^.filename:=zoo_dirname+out^.filename;
    end;
    out^.date:=zoo.mod_date;  {* set up fields *}
    out^.time:=zoo.mod_time;
    out^.csize:=zoo.c_size;
    out^.usize:=zoo.u_size;
    method:=zoo.method;
    case method of
      0:out^.typ:=2;      {* Stored *}
      1:out^.typ:=6;      {* Crunched *}
    else
        out^.typ:=1;      {* Unknown! *}
    end;
    if not (zoo.deleted=1) then details(abort,next);
    if abort then exit;

    {$I-} seek(fp,zoo.next); {$I+}  {* seek to next entry *}
    if ioresult<>0 then abend(abort,next,580);
    if abort then exit;
  end;
end;

{*------------------------------------------------------------------------*}

procedure lzh_proc(var fp:file; var abort,next:boolean);
var lzh:lzhfilerec;
    numread:word;
    i:integer;
    c:char;
begin
  {*  lzh_proc - Process entry in LZH archive.
   *}

  while (not aborted) do begin {* set up infinite loop (exit is within loop) *}
    c:=getbyte(fp);
    if (c=#0) then exit else lzh.h_length:=ord(c);
    c:=getbyte(fp);
    lzh.h_cksum:=ord(c);
    blockread(fp,lzh.method,5,numread); if (numread<>5) then abend(abort,next,578);
    if (abort) then exit;
    if ((lzh.method[1]<>'-') or
        (lzh.method[2]<>'l') or
        (lzh.method[3]<>'h')) then abend(abort,next,579);
    if (abort) then exit;
    blockread(fp,lzh.c_size,15,numread); if (numread<>15) then abend(abort,next,578);
    if (abort) then exit;
    for i:=1 to lzh.f_length do out^.filename[i]:=getbyte(fp);
    out^.filename[0]:=chr(lzh.f_length);
    if (lzh.h_length-lzh.f_length=22) then begin
      blockread(fp,lzh.crc,2,numread); if (numread<>2) then abend(abort,next,578);
      if (abort) then exit;
    end;
    out^.date:=lzh.mod_date;  {* set up fields *}
    out^.time:=lzh.mod_time;
    out^.csize:=lzh.c_size;
    out^.usize:=lzh.u_size;
    c:=lzh.method[4];
    case c of
      '0':out^.typ:=2;       {* Stored *}
      '1'..'5':out^.typ:=14; {* Frozen *}
    else
      out^.typ:=1;           {* Unknown! *}
    end;
    details(abort,next);

    {$I-} seek(fp,filepos(fp)+lzh.c_size); {$I+}  {* seek to next entry *}
    if (ioresult<>0) then abend(abort,next,580);
    if (abort) then exit;
  end;
end;

{*------------------------------------------------------------------------*}

procedure rar_proc(var fp:file; var abort,next:boolean);
var rar:rarfilerec;
    rh:rarheaderrec;
    h:integer;
    numread:word;
    i:integer;
begin
  {*  rar_proc - Process entry in RAR archive.
   *}

  while (not aborted) do {* set up infinite loop (exit is within loop) *}
  begin
    if (eof(fp)) then exit;

    blockread(fp,rh.b[1],5,numread);
    if numread<>5 then abend(abort,next,578);
    if (abort) then exit;
    if not(rh.b[3]=$74) then exit;
    blockread(fp,h,2,numread);
    if numread<>2 then abend(abort,next,578);
    if (abort) then exit;
    blockread(fp,rar,sizeof(rar),numread);
    if numread<>sizeof(rar) then abend(abort,next,578);
    if (abort) then exit;

    out^.filename:='';
    for i:=1 to rar.fnamesize do    {* get filename *}
      out^.filename[i]:=getbyte(fp);
    out^.filename[0]:=chr(rar.fnamesize);
    out^.date:=rar.mod_date;
    out^.time:=rar.mod_time;
    out^.csize:=rar.packsize;
    out^.usize:=rar.unpacksize;

    case rar.method of
      $30:out^.typ:=2;   {* Stored *}
      $31..$35:out^.typ:=ord(rar.method)-$30+20;
      else out^.typ:=1;    {* Unknown! *}
    end;

    details(abort,next);

    {$I-} seek(fp,filepos(fp)+(h-(sizeof(rar)+7+length(out^.filename)))); {$I+}
    if (ioresult<>0) then abend(abort,next,580);
    if (abort) then exit;
    {$I-} seek(fp,filepos(fp)+(rar.packsize)); {$I+}
    if (ioresult<>0) then abend(abort,next,580);
    if (abort) then exit;
  end;
end;

{*------------------------------------------------------------------------*}



procedure final(var abort,next:boolean);
var ratio:longint;
begin
  {*  final - Display final totals and information.
   *}

  if accum_usize=0 then ratio:=0    {* ratio is 0% if null total length *}
  else
    ratio:=100-((accum_csize*100) div accum_usize);
  if ratio>99 then ratio:=99;

  clearwaves;
  addwave('US',cstrl(accum_usize),txt);
  addwave('CS',cstrl(accum_csize),txt);
  addwave('CR',cstrl(ratio),txt);
  addwave('TF',cstr(files),txt);
  addwave('FS',aonoff(files<>1,'s',''),txt);
  spstr(584);
  clearwaves;
end;

function mnz(l:longint; w:integer):astr;
var s:astr;
begin
  s:=cstrl(l);
  while length(s)<w do s:='0'+s;
  mnz:=s;
end;

procedure details(var abort,next:boolean);
var i,month,day,year,hour,minute,typ:integer;
    ampm:string[2];
    ratio:longint;
begin
  {*  details - Calculate and display details line.
   *}

  typ:=out^.typ;
  for i:=1 to length(out^.filename) do
    out^.filename[i]:=upcase(out^.filename[i]);
  day:=out^.date and $1f;                {* day = bits 4-0 *}
  month:=(out^.date shr 5) and $0f;      {* month = bits 8-5 *}
  year:=((out^.date shr 9) and $7f)+80;  {* year = bits 15-9 *}
  minute:=(out^.time shr 5) and $3f;     {* minute = bits 10-5 *}
  hour:=(out^.time shr 11) and $1f;      {* hour = bits 15-11 *}

  if (month>12) then dec(month,12);     {* adjust for month > 12 *}
  if (year>99) then dec(year,100);      {* adjust for year > 1999 *}
  if (hour>23) then dec(hour,24);       {* adjust for hour > 23 *}
  if (minute>59) then dec(minute,60);   {* adjust for minute > 59 *}

  if (hour<12) then ampm:='am' else ampm:='pm'; {* determine AM/PM *}
  if (hour=0) then hour:=12;                    {* convert 24-hour to 12-hour *}
  if (hour>12) then dec(hour,12);

  if (out^.usize=0) then ratio:=0 else   {* ratio is 0% for null-length file *}
    ratio:=100-((out^.csize*100) div out^.usize);
  if ratio>99 then ratio:=99;

  clearwaves;
  addwave('MT',getstr(typ+550),txt);
  addwave('DM',mnz(month,2),txt);
  addwave('DD',mnz(day,2),txt);
  addwave('DY',mnz(year,2),txt);
  addwave('TH',mnz(hour,2),txt);
  addwave('TM',mnz(minute,2),txt);
  addwave('AP',ampm,txt);
  addwave('US',cstrl(out^.usize),txt);
  addwave('CS',cstrl(out^.csize),txt);
  addwave('CR',cstrl(ratio),txt);
  addwave('FN',out^.filename,txt);
  spstr(583);
  wkey(abort,next);
  clearwaves;

  inc(accum_csize,out^.csize);  {* adjust accumulators and counter *}
  inc(accum_usize,out^.usize);
  inc(files);
end;


function stripname(i:astr):astr;
var i1:astr;
    n:integer;

  function nextn:integer;
  var n:integer;
  begin
    n:=pos(':',i1);
    if (n=0) then n:=pos('\',i1);
    if (n=0) then n:=pos('/',i1);
    nextn:=n;
  end;

begin
  i1:=i;
  while (nextn<>0) do i1:=copy(i1,nextn+1,80);
  stripname:=i1;
end;

procedure abend(var abort,next:boolean; b:word);
begin
  spstr(b);
  aborted:=TRUE;
  abort:=TRUE;
  next:=TRUE;
end;

function getbyte(var fp:file):char;
var buf:array[0..0] of char;
    numread:word;
    c:char;
    abort,next:boolean;
begin
  {*  getbyte - Obtains character from file pointed to by fp.
   *            Aborts to DOS on error.
   *}

  if (not aborted) then begin
    blockread(fp,c,1,numread);
    if numread=0 then begin
      close(fp);
      abend(abort,next,577);
    end;
    getbyte:=c;
  end;
end;

procedure lfi(fn:astr; var abort,next:boolean);
var fp:file;
    dirinfo1:searchrec;
    lzh:lzhfilerec;
    i1,i2,temp,infile,filename:astr;
    zoo_temp,zoo_tag:longint;
    h,numread:word;
    i,p,arctype,rcode:integer;
    c:char;
    rha:array[1..15] of byte;
begin
  fn:=sqoutsp(fn);
  if (pos('*',fn)<>0) or (pos('?',fn)<>0) then begin
    findfirst(fn,anyfile-directory-volumeid,dirinfo1);
    if (doserror=0) then fn:=dirinfo1.name;
  end;
  if ((exist(fn)) and (not abort)) then begin
    arctype:=1;
    while (systat^.filearcinfo[arctype].ext<>'') and
          (systat^.filearcinfo[arctype].ext<>copy(fn,length(fn)-2,3)) and
          (arctype<9) do
      inc(arctype);
    if not ((systat^.filearcinfo[arctype].ext='') or (arctype=9)) then begin
      temp:=systat^.filearcinfo[arctype].listline;
      if (temp[1]='/') and (temp[2] in ['1'..'6']) and (length(temp)=2) then begin
        aborted:=FALSE;
        if (not abort) then begin
          infile:=fn;
          assign(fp,infile);
          SetFileAccess(ReadOnly,DenyNone);
          reset(fp,1);

          c:=getbyte(fp);  {* determine type of archive *}
          case c of
            'P':begin
                  if getbyte(fp)<>'K' then abend(abort,next,581);
                  filetype:=1;
                  SetFileAccess(ReadOnly,DenyNone);
                  reset(fp,1);                      {* back to start of file *}
                end;
            #96:begin
                  if getbyte(fp)<>#234 then abend(abort,next,581);
                  filetype:=2;
                  SetFileAccess(ReadOnly,DenyNone);
                  reset(fp,1);                      {* back to start of file *}
                end;
            #$1a:begin
                  filetype:=3;
                  SetFileAccess(ReadOnly,DenyNone);
                  reset(fp,1);                      {* back to start of file *}
                end;
            'Z':begin
                  for i:=0 to 1 do
                    if getbyte(fp)<>'O' then abend(abort,next,581);
                  SetFileAccess(ReadOnly,DenyNone);
                  reset(fp,1);                      {* back to start of file *}
                  filetype:=4;
                end;
            #$52:begin
                  if (ord(getbyte(fp))<>$61) then abend(abort,next,581);
                  if (ord(getbyte(fp))<>$72) then abend(abort,next,581);
                  if (ord(getbyte(fp))<>$21) then abend(abort,next,581);
                  if (ord(getbyte(fp))<>$1a) then abend(abort,next,581);
                  c:=getbyte(fp); c:=getbyte(fp);
                  blockread(fp,rha[1],5,numread);
                  if numread<>5 then abend(abort,next,578);
                  if rha[3]<>$73 then abend(abort,next,578);
                  blockread(fp,h,2,numread);
                  if numread<>2 then abend(abort,next,578);
                  blockread(fp,rha[1],6,numread);
                  if numread<>6 then abend(abort,next,578);
                  {$I-} seek(fp,filepos(fp)+(h-13)); {$I+}
                  if (ioresult<>0) then abend(abort,next,580);
                  filetype:=6;
                end;
              else
                begin       {* assume LZH format *}
                  lzh.h_length:=ord(c);
                  c:=getbyte(fp);
                  for i:=1 to 5 do lzh.method[i]:=getbyte(fp);
                  if ((lzh.method[1]='-') and
                      (lzh.method[2]='l') and
                      (lzh.method[3]='h')) then
                    filetype:=5
                  else
                    abend(abort,next,581);
                  SetFileAccess(ReadOnly,DenyNone);
                  reset(fp,1);                      {* back to start of file *}
                end;
          end;

          p:=0;                             {* drop drive and pathname *}
          for i:=1 to length(infile) do
            if infile[i] in [':','\'] then p:=i;
          filename:=copy(infile,p+1,length(infile)-p);

          if filetype=4 then begin    {* process initial ZOO file header *}
            for i:=0 to 19 do      {* skip header text *}
              c:=getbyte(fp);
             {* get tag value *}
            blockread(fp,zoo_tag,4,numread);
            if numread<>4 then abend(abort,next,578);
            if zoo_tag<>Z_TAG then abend(abort,next,581);
             {* get data start *}
            blockread(fp,zoo_temp,4,numread); if numread<>4 then abend(abort,next,578);
            {$I-} seek(fp,zoo_temp); {$I+}
            if ioresult<>0 then abend(abort,next,580);
          end;

          accum_csize:=0; accum_usize:=0;   {* set accumulators to 0 *}
          level:=0; files:=0;               {* ditto with counters *}

          clearwaves;
          addwave('FN',stripname(fn),txt);
          spstr(582);
          clearwaves;;
          new(out);
          case filetype of
            1:zip_proc(fp,abort,next);  {* process ZIP entry *}
            2:arj_proc(fp,abort,next);  {* process ARJ entry *}
            3:arc_proc(fp,abort,next);  {* process ARC entry *}
            4:zoo_proc(fp,abort,next);  {* process ZOO entry *}
            5:lzh_proc(fp,abort,next);  {* process LZH entry *}
            6:rar_proc(fp,abort,next);  {* process RAR entry *}
          end;
          final(abort,next);      {* clean things up *}
          close(fp);              {* close file *}
          dispose(out);
        end;
      end else
      begin
        spstr(585);
        temp:=substall(systat^.arcpath+systat^.filearcinfo[arctype].listline,'@F',fn);
        shelldos(FALSE,temp+' >SHELL.'+cstr(nodenum),rcode);
        for i:=1 to 15 do prompt(^H' '^H);
        nl;
        pfl('shell.'+cstr(nodenum),abort,next,TRUE);
        assign(fp,'SHELL.'+cstr(nodenum));
        {$I-} erase(fp); {$I+}
        if (ioresult<>0) then spstr(586);
      end;
    end;
  end;
end;


procedure nfile;
begin
  findnext(dirinfo);
  found:=(doserror=0);
end;

procedure ffile(fn:astr);
begin
  findfirst(fn,anyfile,dirinfo);
  found:=(doserror=0);
end;

function iswildcard(s:astr):boolean;
begin
  iswildcard:=((pos('*',s)<>0) or (pos('?',s)<>0));
end;

function align(fn:astr):astr;
var f,e,t:astr; c,c1:integer;
begin
  c:=pos('.',fn);
  if (c=0) then begin
    f:=fn; e:='   ';
  end else begin
    f:=copy(fn,1,c-1); e:=copy(fn,c+1,3);
  end;
  f:=mln(f,8);
  e:=mln(e,3);
  c:=pos('*',f); if (c<>0) then for c1:=c to 8 do f[c1]:='?';
  c:=pos('*',e); if (c<>0) then for c1:=c to 3 do e[c1]:='?';
  c:=pos(' ',f); if (c<>0) then for c1:=c to 8 do f[c1]:=' ';
  c:=pos(' ',e); if (c<>0) then for c1:=c to 3 do e[c1]:=' ';
  align:=f+'.'+e;
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
  purgedir2(modemr^.temppath+'ARCHIVE\');
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
  purgedir2(modemr^.temppath+'ARCHIVE\');
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

procedure mpkey(var s:astr);
var sfqarea,smqarea:boolean;
begin
  sfqarea:=fqarea; smqarea:=mqarea;
  fqarea:=FALSE; mqarea:=FALSE;

  mmkey(s);

  fqarea:=sfqarea; mqarea:=smqarea;
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

procedure star(s:astr);
begin
  sprint('|Bþ |C'+s);
end;

function bslash(b:boolean; s:astr):astr;
begin
  if (b) then begin
    while (copy(s,length(s)-1,2)='\\') do s:=copy(s,1,length(s)-2);
    if (copy(s,length(s),1)<>'\') then s:=s+'\';
  end else
    while (copy(s,length(s),1)='\') do s:=copy(s,1,length(s)-1);
  bslash:=s;
end;

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

function existdir2(s:astr):boolean;
var savedir:astr;
    okd:boolean;
begin
  okd:=TRUE;
  s:=bslash(FALSE,fexpand(s));

  if ((length(s)=2) and (copy(s,2,1)=':')) then begin
    getdir(0,savedir);
    {$I-} chdir(s); {$I+}
    if (ioresult<>0) then okd:=FALSE;
    chdir(savedir);
    exit;
  end;

  okd:=(exist(s));

  if (okd) then begin
    findfirst(s,anyfile,dirinfo);
    if (dirinfo.attr and directory<>directory) or
       (doserror<>0) then okd:=FALSE;
  end;

  existdir2:=okd;
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
  (*
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
  *)
  if (p>=0) then begin seek(xf,p); read(xf,protocol); end;
  close(xf);
  lastprot:=p;
  case p of
{   -12:ymbadd(fn); }
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
    {while (not keypressed) and (tcheck(st,3)) do abeep;}
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
    {while (not keypressed) and (tcheck(st,3)) do abeep;}
    if (keypressed) then c:=readkey;
    removewindow(wind);
    cursoron(TRUE);
    incom:=FALSE; outcom:=FALSE;
  end;
end;

end.