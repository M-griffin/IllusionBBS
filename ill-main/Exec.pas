(*****************************************************************************)
(* Illusion BBS - Exec swap routines                                         *)
(*****************************************************************************)

{ $A+,B-,E-,F+,I+,N-,O-,R-,S-,V-}

{ $IFDEF DBUG}
  { $D+,L+}
{ $ELSE}
  { $D-,L-}
{ $ENDIF}

unit exec;

interface

uses dos, checkpat;

const
   RC_PREPERR   = $0100;
   RC_NOFILE    = $0200;
   RC_EXECERR   = $0300;
   RC_ENVERR    = $0400;
   RC_SWAPERR   = $0500;
   RC_REDIRERR  = $0600;

   USE_EMS      =  $01;
   USE_XMS      =  $02;
   USE_FILE     =  $04;
   EMS_FIRST    =  $00;
   XMS_FIRST    =  $10;
   HIDE_FILE    =  $40;
   NO_PREALLOC  = $100;
   CHECK_NET    = $200;

   USE_ALL      = USE_EMS or USE_XMS or USE_FILE or CHECK_NET;

{  Return value:

      $0000..00FF: The EXECed Program's return code

      $0101:       Error preparing for swap: no space for swapping
      $0102:       Error preparing for swap: program too low in memory

      $0200:       Program file not found
      $0201:       Program file: Invalid drive
      $0202:       Program file: Invalid path
      $0203:       Program file: Invalid name
      $0204:       Program file: Invalid drive letter
      $0205:       Program file: Path too long
      $0206:       Program file: Drive not ready
      $0207:       Batchfile/COMMAND: COMMAND.COM not found
      $0208:       Error allocating temporary buffer

      $03xx:       DOS-error-code xx calling EXEC

      $0400:       Error allocating environment buffer

      $0500:       Swapping requested,but prep_swap has not
                    been called or returned an error.
      $0501:       MCBs don't match expected setup
      $0502:       Error while swapping out

      $0600:       Redirection syntax error
      $06xx:       DOS error xx on redirection }

type filename=string[81];
     string128=string[128];
     pstring=^string;
     spawn_check_proc=function(cmdbat:integer; swapping:integer;
                               var execfn:string; var progpars:string):integer;
    prep_block=record
      xmm:longint;
      first_mcb:integer;
      psp_mcb:integer;
      env_mcb:integer;
      noswap_mcb:integer;
      ems_pageframe:integer;
      handle:integer;
      total_mcbs:integer;
      swapmethod:byte;
      swapfilename:array[0..80] of char;
    end;

var spawn_check:spawn_check_proc;
    swap_prep:prep_block;

procedure putenv(envvar:string);
function envcount:integer;
function envstr(index:integer):string;
function getenv(envvar:string):string;
function do_exec(xfn:string;pars:string;spawn:integer;needed:word;newenv:boolean):integer;

implementation

{$DEFINE REDIRECT}

const
   swap_filename  = '$$AAAAAA.AAA';

   CREAT_TEMP     = $0080;
   DONT_SWAP_ENV  = $4000;

   ERR_COMSPEC    = -7;
   ERR_NOMEM      = -8;

   spaces:set of #9..' '=[#9,' '];

type
   stringptr=^string;
   stringarray=array[0..10000] of stringptr;
   stringarrptr=^stringarray;
   bytearray=array[0..30000] of byte;
   bytearrayptr=^bytearray;

var
   envptr:stringarrptr;
   envcnt:integer;
   cmdpath:string;
   cmdpars:string;
   drive:string[3];
   dir:string[67];
   name:string[9];
   ext:string[5];

{$L SPAWNP}

function do_spawn(swapping:integer;var xeqfn;var cmdtail;envlen:word;
                   var env;stdin:pstring;stdout:pstring;stderr:pstring
                   ):integer;external;
function prep_swap(method:integer;var swapfn):integer;external;

function strpbrk(par,pattern:string):integer;
var i:integer;
begin
  for i:=1 to length(par) do
    if pos(par[i],pattern)>0 then begin
      strpbrk:=i;
      exit;
    end;
  strpbrk:=0;
end;

function envcount:integer;
begin
  if envptr=nil then envcount:=dos.envcount else envcount:=envcnt;
end;

function envstr(index:integer):string;
begin
  if envptr=nil then
    envstr:=dos.envstr(index)
  else if (index<=0) or (index>=envcnt) or (envptr^[index-1]=nil) then
    envstr:=''
  else
    envstr:=envptr^[index-1]^;
end;

function name_eq(var n1,n2:string):boolean;
var i:integer;
    eq:boolean;
begin
  i:=1;
  eq:=false;
  while (i<=length(n1)) and (i<=length(n2)) and (upcase(n1[i])=upcase(n2[i])) do inc(i);
  name_eq:=(i>length(n1)) and (i<=length(n2)) and (n2[i]='=');
end;

function searchenv(var str:string):integer;
var idx:integer;
    found:boolean;
begin
  idx:=0;
  found:=false;
  while (idx<envcnt) and not found do begin
    if envptr^[idx]<>nil then found:=name_eq(str,envptr^[idx]^);
    inc(idx);
  end;
  if not found then searchenv:=-1 else searchenv:=idx-1;
end;

function getenv(envvar:string):string;
var strp:stringptr;
    eq:integer;
begin
  if envptr=nil then
    getenv:=dos.getenv(envvar)
  else begin
    eq:=searchenv(envvar);
    if eq<0 then
      getenv:=''
    else begin
      strp:=envptr^[eq];
      eq:=pos('=',strp^);
      getenv:=copy(strp^,eq+1,length(strp^)-eq);
    end;
  end;
end;

procedure init_envptr;
var i:integer;
    str:string;
begin
  envcnt:=dos.envcount;
  getmem(envptr,envcnt*sizeof(stringptr));
  if envptr=nil then exit;
  for i:=0 to envcnt-1 do begin
    str:=dos.envstr(i+1);
    getmem(envptr^[i],length(str)+1);
    if envptr^[i]<>nil then envptr^[i]^:=str;
  end;
end;

procedure putenv(envvar:string);
var idx,eq:integer;
    help:stringarrptr;
    tmpvar:string;
begin
  if envptr=nil then begin init_envptr; exit; end;

  eq:=pos('=',envvar);
  if eq=0 then exit;
  for idx:=1 to eq do envvar[idx]:=upcase(envvar[idx]);
  tmpvar:=copy(envvar,1,eq-1);

  idx:=searchenv(tmpvar);
  if idx>=0 then begin
    freemem(envptr^[idx],length(envptr^[idx]^)+1);
    if eq>=length(envvar) then
      envptr^[idx]:=nil
    else begin
      getmem(envptr^[idx],length(envvar)+1);
      if envptr^[idx]<>nil then envptr^[idx]^:=envvar;
    end;
  end else if eq<length(envvar) then begin
    getmem(help,(envcnt+1)*sizeof(stringptr));
    if help=nil then exit;
    move(envptr^,help^,envcnt*sizeof(stringptr));
    freemem(envptr,envcnt*sizeof(stringptr));
    envptr:=help;
    getmem(envptr^[envcnt],length(envvar)+1);
    if envptr^[envcnt]<>nil then envptr^[envcnt]^:=envvar;
    envcnt:=envcnt+1;
  end;
end;

function tryext(var fn:string):integer;
var nfn:filename;
    ok:boolean;
begin
  tryext:=1;
  nfn:=fn+'.COM';
  ok:=exists(nfn);
  if not ok then begin
    nfn:=fn+'.EXE';
    ok:=exists(nfn);
  end;
  if not ok then begin
    tryext:=2;
    nfn:=fn+'.BAT';
    ok:=exists(nfn);
  end;
  if not ok then tryext:=0 else fn:=nfn;
end;

function findfile(var fn:string):integer;
var path:string;
    i,j:integer;
    hasext,found,check:integer;
begin
  if fn='' then begin
    if cmdpath='' then findfile:=ERR_COMSPEC else findfile:=3;
    exit;
  end;

  check:=checkpath(fn,INF_NODIR,drive,dir,name,ext,fn);
  if check<0 then begin
    findfile:=check;
    exit;
  end;

  if ((check and HAS_WILD)<>0) or ((check and HAS_FNAME)=0) then begin
    findfile:=ERR_FNAME;
    exit;
  end;

  if (check and HAS_EXT)<>0 then begin
    for i:=1 to length(ext) do ext[i]:=upcase(ext[i]);
    if ext='.BAT' then hasext:=2 else hasext:=1;
  end else hasext:=0;

  if hasext<>0 then begin
    if (check and FILE_EXISTS)<>0 then found:=hasext else found:=0;
  end else found:=tryext(fn);

  if (found<>0) or ((check and (HAS_PATH or HAS_DRIVE))<>0) then begin
    findfile:=found;
    exit;
  end;

  path:=getenv('PATH');
  i:=1;
  while (found=0) and (i<=length(path)) do begin
    j:=0;
    while (path[i]<>';') and (i<=length(path)) do begin
      inc(j);
      fn[j]:=path[i];
      inc(i);
    end;
    inc(i);
    if (j>0) then begin
      if not (fn[j] in ['\','/']) then begin
        inc(j);
        fn[j]:='\';
      end;
      fn[0]:=chr(j);
      fn:=fn+name+ext;
      check:=checkpath(fn,INF_NODIR,drive,dir,name,ext,fn);
      if hasext<>0 then begin
        if (check and FILE_EXISTS)<>0 then found:=hasext else found:=0;
      end else found:=tryext(fn);
    end;
  end;
  findfile:=found;
end;

procedure getcmdpath;
var i,found:integer;
begin
  if length(cmdpath)>0 then exit;
  cmdpath:=getenv('COMSPEC');
  cmdpars:='';
  found:=0;

  if cmdpath<>'' then begin
    i:=1;
    while (i<=length(cmdpath)) and (cmdpath[i] in spaces) do inc(i);
    if i>1 then begin
      cmdpath:=copy(cmdpath,i,255);
      i:=1;
    end;

    i:=strpbrk(cmdpath,';,=+/"[]|<>'#9);
    if i<>0 then begin
      cmdpars:=copy(cmdpath,i,128);
      cmdpath[0]:=chr(i-1);
      i:=1;
      while (i<=length(cmdpars)) and (cmdpars[i] in spaces) do inc(i);
      if i>1 then cmdpars:=copy(cmdpars,i,128);
      if cmdpars<>'' then cmdpars:=cmdpars+' ';
    end;
    found:=findfile(cmdpath);
  end;

  if found=0 then begin
    cmdpath:='COMMAND.COM';
    cmdpars:='';
    found:=findfile(cmdpath);
    if found=0 then cmdpath:='';
  end;
end;

function tempdir(var outfn:filename):boolean;
var stmp:array[0..3] of filename;
    i,res:integer;
begin
  stmp[0]:=getenv('TMP');
  stmp[1]:=getenv('TEMP');
  stmp[2]:='.\';
  stmp[3]:='\';

  for i:=0 to 3 do
    if length(stmp[i])<>0 then begin
      outfn:=stmp[i];
      res:=checkpath(outfn,0,drive,dir,name,ext,outfn);
      if (res>0) and ((res and IS_DIR)<>0) and ((res and IS_READ_ONLY)=0) then begin
        tempdir:=true;
        exit;
      end;
    end;
  tempdir:=false;
end;

function parse_redirect(var par:string;idx:integer;var stdin,stdout,stderr:pstring):boolean;
var ch:char;
    fnp:pstring;
    fn:string;
    app,i,beg,fne:integer;
begin
  i:=idx;
  par[length(par)+1]:=#0;

  repeat
    app:=0;
    ch:=par[i];
    beg:=i;
    inc(i);
    if ch<>'<' then begin
      if par[i]='&' then begin
        ch:='&';
        inc(i);
      end;
      if par[i]='>' then begin
        app:=1;
        inc(i);
      end;
    end;

    while (i<=length(par)) and (par[i] in spaces) do inc(i);
    fn:=copy(par,i,255);
    fne:=strpbrk(fn,';,=+/"[]|<>'#9);
    if fne=0 then fne:=length(fn)+1;
    par:=copy(par,1,beg-1)+copy(fn,fne,255);
    i:=beg;
    fn[0]:=chr(fne-1);
    if (fne=0) or (length(fn)=0) then begin
      parse_redirect:=false;
      exit;
    end;

    getmem(fnp,length(fn)+app+2);
    if fnp=NIL then begin
      parse_redirect:=false;
      exit;
    end;
    if app<>0 then fnp^:='>'+fn else fnp^:=fn;
    fnp^[length(fnp^)+1]:=#0;

    case ch of
      '<':if stdin<>NIL then begin
            parse_redirect:=false;
            exit;
          end else stdin:=fnp;
      '>':if stdout<>NIL then begin
            parse_redirect:=false;
            exit;
          end else stdout:=fnp;
      '&':if stderr<>NIL then begin
            parse_redirect:=false;
            exit;
          end else stderr:=fnp;
    end;

    i:=strpbrk(fn,'<>');
  until (i <= 0);

  par[length(par)+1]:=#0;
  parse_redirect:=true;
end;

function do_exec(xfn,pars:string;spawn:integer;needed:word;newenv:boolean):integer;
label exit;
var cmdbat:integer;
    swapfn:filename;
    regs:registers;
    avail,envlen,einx:word;
    swapping,idx,len,rc:integer;
    envp:bytearrayptr;
    stdin,stdout,stderr:pstring;
begin
  stdin:=NIL; stdout:=NIL; stderr:=NIL;

  getcmdpath;
  envlen:=0;

  cmdbat:=findfile(xfn);
  if cmdbat<=0 then begin
    do_exec:=RC_NOFILE or -cmdbat;
    goto exit;
  end;

  if cmdbat>1 then begin
    if length(cmdpath)=0 then begin
      do_exec:=RC_NOFILE or -ERR_COMSPEC;
      goto exit;
    end;
    if cmdbat=2 then pars:=cmdpars+'/c '+xfn+' '+pars else pars:=cmdpars+pars;
    xfn:=cmdpath;
  end;

  idx:=strpbrk(pars,'<>');
  if idx>0 then
    if not parse_redirect(pars,idx,stdin,stdout,stderr) then begin
      do_exec:=RC_REDIRERR;
      goto exit;
    end;

  if newenv and (envptr<>nil) then begin
    for idx:=0 to envcnt-1 do envlen:=envlen+length(envptr^[idx]^)+1;
    if envlen>0 then begin
      inc(envlen);
      getmem(envp,envlen);
      if envp=nil then begin
        do_exec:=RC_ENVERR;
        goto exit;
      end;
      einx:=0;
      for idx:=0 to envcnt-1 do begin
        len:=length(envptr^[idx]^);
        move(envptr^[idx]^[1],envp^[einx],len);
        envp^[einx+len]:=0;
        einx:=einx+len+1;
      end;
      envp^[einx]:=0;
    end;
  end;

  if spawn=0 then swapping:=-1 else begin

    with regs do begin
      ax:=$4800;
      bx:=$ffff;
      msdos(regs);
      avail:=regs.bx;
    end;

    if needed<avail then swapping:=0 else begin
      swapping:=spawn;
      if (spawn and USE_FILE)<>0 then begin
        if not tempdir(swapfn) then begin
          spawn:=spawn xor USE_FILE;
          swapping:=spawn;
        end else begin
          if (dosversion and $ff)>=3 then
            swapping:=swapping or CREAT_TEMP
          else begin
            swapfn:=swapfn+swap_filename;
            len:=length(swapfn);
            while exists(swapfn) do begin
              if (swapfn[len]>='Z') or (swapfn[len]='.') then dec(len);
              swapfn[len]:=succ(swapfn[len]);
            end;
          end;
          swapfn[length(swapfn)+1]:=#0;
        end;
      end;
    end;
  end;

  if swapping>0 then begin
    if envlen=0 then swapping:=swapping or DONT_SWAP_ENV;

    rc:=prep_swap(swapping,swapfn);
    if rc<0 then begin
      do_exec:=RC_PREPERR or -rc;
      goto exit;
    end;
  end;

  xfn[length(xfn)+1]:=#0;
  pars[length(pars)+1]:=#0;

  if @spawn_check<>NIL then begin
    rc:=spawn_check(cmdbat,swapping,xfn,pars);
    if rc<>0 then begin
      do_exec:=rc;
      goto exit;
    end;
  end;

  swapvectors;
  do_exec:=do_spawn(swapping,xfn,pars,envlen,envp^,stdin,stdout,stderr);
  swapvectors;

exit:

  if envlen>0 then freemem(envp,envlen);
  if stdin<>NIL then freemem(stdin,length(stdin^)+2);
  if stdout<>NIL then freemem(stdout,length(stdout^)+2);
  if stderr<>NIL then freemem(stderr,length(stderr^)+2);
end;

begin
  envptr:=nil;
  envcnt:=0;
  cmdpath:='';
  @spawn_check:=nil;
end.
