(*****************************************************************************)
(* Illusion BBS - File routines  [4/15] (archive viewer)                     *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit Mfile4;

interface

uses
  crt, dos,
  Mfile0, Mfile14,
  common;

function substall(src,old,new:astr):astr;
function getbyte(var fp:file):char;
procedure abend(var abort,next:boolean; b:word);
procedure details(var abort,next:boolean);
procedure lfi(fn:astr; var abort,next:boolean);
procedure lfin(rn:integer; var abort,next:boolean);
procedure lfii;

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
  accum_csize:longint;    {* compressed size accumulator *}
  accum_usize:longint;    {* uncompressed size accumulator *}
  files:integer;          {* number of files *}
  level:integer;          {* output directory level *}
  filetype:integer;       {* file type (1=ZIP, 2=ARJ, 3=ARC, 4=LZH, 5=ZOO) *}
  out:^outrec;
  aborted:boolean;

implementation

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

procedure lbrl(fn:astr; var abort,next:boolean);
var f:file;
    c,n,n1:integer;
    x:record
        st:byte;
        name:array[1..8] of char;
        ext:array[1..3] of char;
        index,len:integer;
        fil:array[1..16] of byte;
      end;
    i:astr;
begin
  nl;
  assign(f,fn);
  SetFileAccess(ReadOnly,DenyNone);
  reset(f,32);
  blockread(f,x,1);
  c:=x.len*4-1;
  for n:=1 to c do begin
    blockread(f,x,1); i:='';
    if (x.st=0) and not abort then begin
      for n1:=1 to 8 do i:=i+x.name[n1];
      i:=i+'.';
      for n1:=1 to 3 do i:=i+x.ext[n1];
      i:=align(i)+' '+mrn(cstrr(x.len*128.0,10),7);
      printacr(i,abort,next);
    end;
  end;
  close(f);
end;

function mnz(l:longint; w:integer):astr;
var s:astr;
begin
  s:=cstrl(l);
  while length(s)<w do s:='0'+s;
  mnz:=s;
end;

function mnr(l:longint; w:integer):astr;
begin
  mnr:=mrn(cstrl(l),w);
end;

{*------------------------------------------------------------------------*}

procedure abend(var abort,next:boolean; b:word);
begin
  spstr(b);
  aborted:=TRUE;
  abort:=TRUE;
  next:=TRUE;
end;

{*------------------------------------------------------------------------*}

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

{*------------------------------------------------------------------------*}

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

procedure lfin(rn:integer; var abort,next:boolean);
var f:ulfrec;
begin
  seek(ulff,rn); read(ulff,f);
  lfi(memuboard.dlpath+f.filename,abort,next);
end;

procedure lfii;
const sepr2:string[5]='|B:|C';
var f:ulfrec;
    fn:astr;
    pl,rn:integer;
    abort,next,lastarc,lastgif,isgif:boolean;
begin
  spstr(107);
  gfn(fn); abort:=FALSE; next:=FALSE;
  nl;
  recno(fn,pl,rn);
  if (baddlpath) then exit;
  abort:=FALSE; next:=FALSE; lastarc:=fALSE; lastgif:=FALSE;
  while ((rn<>-1) and (not abort)) do begin
    seek(ulff,rn); read(ulff,f);
    isgif:=isgifext(f.filename);
    if (isgif) then begin
      lastarc:=FALSE;
      if (not lastgif) then begin
        lastgif:=TRUE;
        nl; nl;
        printacr('|CFilename.Ext '+sepr2+' Resolution '+sepr2+
                 ' Num Colors '+sepr2+' Signat.',abort,next);
        printacr('|B컴컴컴컴컴컴�:컴컴컴컴컴컴:컴컴컴컴컴컴:컴컴컴컴�',abort,next);
      end;
      dogifspecs(sqoutsp(memuboard.dlpath+f.filename),abort,next);
    end else begin
      lastgif:=FALSE;
      if (not lastarc) then begin
        lastarc:=TRUE;
        nl;
      end;
      lfin(rn,abort,next);
    end;
    nrecno(fn,pl,rn);
    if (next) then abort:=FALSE;
    next:=FALSE;
  end;
  close(ulff);
end;

end.
