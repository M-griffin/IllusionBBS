(*****************************************************************************)
(* Illusion BBS - File routines  [11/15]                                     *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit Mfile11;

interface

uses
  crt,dos,
  myio, Mfile0, Mfile1, common;

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

Procedure KillQueue;

function cansee(f:ulfrec):boolean;
procedure pbn(var abort,next:boolean);
procedure pfn(fnum:integer; f:ulfrec; var abort,next:boolean);
procedure searchb(b:integer; fn:astr; filestats:boolean; var abort,next:boolean);
procedure search;
procedure listfiles;
procedure searchbd(b:integer; ts:astr; var abort,next,found:boolean);
procedure searchd;
procedure newfiles(b:integer; var abort,next:boolean);
procedure gnfiles;
procedure nf(mstr:astr);
procedure fbasechange(var done:boolean; mstr:astr);
procedure createtempdir;

implementation

uses Mfile4, Mfile10, Mfile8;

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
    {printacrQ('',abort,next);}
    spstr(613);

  end;
  bnp:=TRUE;
end;

{ File Listing Procedure }

procedure pfndd(fnum:integer; ts:astr; f:ulfrec; var abort,next:boolean);
var s,s1,dd,dd2:astr;
    v:verbrec;
    u:userrec;
    i,k,vv,vv2:integer;
    vfo:boolean;

  function sizef:astr;
  begin
    if (isrequest in f.filestat) then sizef:='Req''st ' else
    if (resumelater in f.filestat) then sizef:='Resume ' else
    if (notval in f.filestat) then sizef:='N/V    ' else
    if (f.blocks div 8>=20000) then
      sizef:=mln(cstr((f.blocks div 8) div 1024)+'m',6)+' '
    else
    if (f.blocks div 8<9) then
      sizef:=mln(cstr(f.blocks*128)+'b',6)+' '
    else
      sizef:=mln(cstr(f.blocks div 8)+'k',6)+' ';
  end;

  function ptsf:astr;
  begin
    if ((isrequest in f.filestat) or (resumelater in f.filestat) or (notval in f.filestat)) then
      ptsf:='N/A  '
    else if f.filepoints=0 then
      ptsf:='Free '
    else
      ptsf:=mn(f.filepoints,4)+' ';
  end;

begin
  lil:=0;

  loaduboard(fileboard); vv:=1;

  with thisuser do begin
  
    { Crappy Hard Coding till Rewrite.. Manually Set Bits }          
    if (f.daten>=daynum(newdate)) then s:='|R*' else s:=' ';
    for k:=1 to 5 do
      if flistc[k][1]>0 then begin
        case k of
          1:begin dd:=f.filename+' '; inc(vv,13); end;
          2:begin dd:=sizef; inc(vv,7); end;
          3:begin dd:=ptsf; inc(vv,5); end;
          4:begin dd:=mn(f.nacc,2)+' '; inc(vv,3); end;
          5:begin
              vv2:=79-vv;
              if (vv2>60) then vv2:=60;
              dd:=f.description;
              if (not (flistc[8][1]>0)) and (f.vpointer<>-1) then begin
                if (lenn(dd)>vv2-3) then dd:=copy(dd,1,vv2-4)+'|C+(v)'
                  else dd:=dd+'|C+(v)';
              end else
                if (lenn(dd)>vv2) then dd:=copy(dd,1,vv2-1)+'|C+';
            end;
        end;        
        s:=s+'|'+chr(flistc[k][2])+dd;
        if (ts<>'') then s:=substone(s,ts,'|W'+allcaps(ts)+'|'+chr(flistc[k][2]));
      end;
      if length(s)>79 then s:=mln(s,79);
    end;

  if ((f.vpointer<>-1) and (thisuser.flistc[8][1]>0)) then begin
    if (f.vpointer=-2) then begin
      printacrQ(s,abort,next);
      printacrQ(mln(' ',vv)+'|'+chr(thisuser.flistc[8][2])+'Verbose description',abort,next);
      inc(flistlines);
    end 
    else begin
      vfo:=(filerec(verbf).mode=fmclosed);
      if (vfo) then begin
        SetFileAccess(ReadOnly,DenyNone);
        {$I-} reset(verbf); {$I+}
      end;
      if (ioresult=0) then begin
        seek(verbf,f.vpointer); read(verbf,v);
        if (thisuser.flistc[6][1]>0) or (thisuser.flistc[7][1]>0) then k:=2 else k:=1;
        for i:=1 to 9 do if (v.descr[i]<>'') then inc(k) else i:=9;

        if flistlines+k>=thisuser.pagelen-11 then fileprompt(abort);
        if abort then exit;
        pbn(abort,next);

        printacrQ(s,abort,next);
        for i:=1 to 9 do
          if (v.descr[i]='') then i:=9
          else begin
            dd:=substone(v.descr[i],ts,'|W'+allcaps(ts)+'|'+chr(thisuser.flistc[8][2]));
            printacrQ(mln(' ',vv)+'|'+chr(thisuser.flistc[8][2])+dd,abort,next);
            inc(flistlines);
          end;
        if (vfo) then close(verbf);
      end else begin
        if (thisuser.flistc[6][1]>0) or (thisuser.flistc[7][1]>0) then k:=2 else k:=1;
        if flistlines+k>=thisuser.pagelen-11 then fileprompt(abort);
        if abort then exit;
        pbn(abort,next);
        printacrQ(s,abort,next);
      end;
    end;
  end else begin
    if (thisuser.flistc[6][1]>0) or (thisuser.flistc[7][1]>0) then k:=2 else k:=1;
    if flistlines+k>=thisuser.pagelen-11 then fileprompt(abort);
    if abort then exit;
    pbn(abort,next);
    printacrQ(s,abort,next);
  end;

  inc(flistlines);

  if (thisuser.flistc[6][1]>0) or (thisuser.flistc[7][1]>0) then begin
    if (thisuser.flistc[6][1]>0) then
      dd:='|'+chr(thisuser.flistc[6][2])
    else
      dd:='|'+chr(thisuser.flistc[7][2]);
    dd:=dd+'Uploaded ';
    if (thisuser.flistc[6][1]>0) then
      if (aacs(memuboard.nameacs)) then
        dd:=dd+'by '+caps(f.stowner)+' '
      else
        dd:=dd+'by Unknown ';
    if (thisuser.flistc[7][1]>0) then
      dd:=dd+'on '+f.date;
    if length(dd)>79-vv then dd:=mln(dd,79-vv);
    printacrQ(mln(' ',vv)+dd,abort,next);
    inc(flistlines);
  end;

  if ((resumelater in f.filestat) and (f.owner=usernum)) then
    sprint('|RYou MUST RESUME this file to receive credit for it');

  { File Prompt? }

  if flistlines>=thisuser.pagelen-11 then fileprompt(abort);
  pbn(abort,next);

end;

procedure pfn(fnum:integer; f:ulfrec; var abort,next:boolean);
begin
  pfndd(fnum,'',f,abort,next);
end;

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
    if (fbaseac(bn)) then searchb(bn,fn,FALSE,abort,next);
    inc(bn);
    wkey(abort,next);
    if (next) then begin abort:=FALSE; next:=FALSE; end;
  end;
  thisuser.conference:=oldconf;
end;

procedure listfiles;
var fn:astr;
    abort,next:boolean;
begin
  spstr(100);
  gfn(fn); abort:=FALSE;
  searchb(fileboard,fn,TRUE,abort,next);
end;

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
      end;
      inc(rn);
    end;
    if flistlines>0 then fileprompt(abort);
    close(ulff);
  end;
  fileboard:=oldboard; if tot>0 then pausescr;
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

end.
