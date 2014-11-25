(*****************************************************************************)
(* Illusion BBS - File routines  [9/11]                                      *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit Mfile9;

interface

uses
  crt, dos,
  myio, Mfile0, Mfile1, Mfile2, Mfile11, misc2, common;

function info:astr;
procedure dir(cd,x:astr; expanded:boolean);
procedure dirf(expanded:boolean);
procedure deleteff(rn:integer; var pl:integer; killverbose:boolean);
procedure setdirs;
procedure pointdate;
procedure listopts;

implementation

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
    if (aacs(systat.nofilepts)) then
    sprint(mln('High security level -  No file point check!',53)+'|B ³')
    else
    sprint(mln('Active according to setting on each file.',53)+'|B ³');
    if (not systat.fileptratio) then
    sprint('|B³                      |C'+mln('Auto file point compensation inactive.',53)+'|B ³')
    else begin
    sprint('|B³                      |C'+mln('File point compensation of '+cstr(systat.fileptcomp)+' to 1.',53)+'|B ³');
    sprint('|B³                      |C'+mln('Base compensation size of '+cstr(systat.fileptcompbasesize)+'k.',53)+'|B ³');
    end;
    sprompt('|B³ |WUL/DL ratio setting|b: |C');
    if (not systat.uldlratio) then
      sprint(mln('|CInactive.',53)+'|B ³')
    else
      if ((fnodlratio in thisuser.ac) or (aacs(systat.nodlratio))) then
        sprint(mln('|C- No ratio checking -',53)+'|B ³')
      else begin
         sprint(mln('|C  1 upload for every '+cstr(systat.dlratio[thisuser.sl])+' downloads',53)+'|B ³');
         sprint('|B³                      '+mln('|C  1k upload for every '+
         cstr(systat.dlkratio[thisuser.sl])+' downloaded',53)+'|B ³');
       end;
    sprompt('|BÀ'); for j:=1 to 76 do sprompt ('Ä'); sprint ('Ù');
  end;
end;
*)

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

end.
