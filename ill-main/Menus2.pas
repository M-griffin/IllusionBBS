(*****************************************************************************)
(* Illusion BBS - Menu routines  [2/3] (generic, list, etc)                  *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit menus2;

interface

uses
  crt, dos,
  MsgF, { SubStAll }
  common;

procedure readin;
function oksecurity(i:integer; var cmdnothid:boolean):boolean;
procedure genericmenu(t:integer);
procedure showthismenu;

implementation

procedure readin;
var filv:text;
    s,lcmdlistentry:astr;
    i,j:integer;
    b:boolean;
begin
  cmdlist:='';
  noc:=0;
  assign(filv,curmenu);
  {$I-} reset(filv); {$I-}
  if (ioresult<>0) then begin
    sysoplog('"'+curmenu+'" is MISSING.');
    print('"'+curmenu+'" is MISSING.  Please inform SysOp.');
    print('Dropping back to fallback menu...');
    curmenu:=systat^.menupath+menur.fallback+'.MNU';
    assign(filv,curmenu);
    {$I-} reset(filv); {$I-}
    if (ioresult<>0) then begin
      sysoplog('"'+curmenu+'" is MISSING - Hung user up.');
      print('Fallback menu is *also* MISSING.  Please inform SysOp.');
      nl;
      print('Critical error; hanging up.');
      hangup:=TRUE;
    end;
  end;

  if (not hangup) then begin
    with menur do begin
      readln(filv,menuname);
      readln(filv,directive);
      readln(filv,tutorial);
      readln(filv,mpromptf);
      readln(filv,menuprompt);
      readln(filv,forceinput);
      if (forceinput>2) then forceinput:=0;
      readln(filv,hilite);
      readln(filv,lolite);
      readln(filv,acs);
      readln(filv,password);
      readln(filv,fallback);
      readln(filv,forcehelplevel);
      readln(filv,gencols);
      for i:=1 to 3 do readln(filv,gcol[i]);
      readln(filv,s);
      s:=allcaps(s); menuflags:=[];
      if (pos('C',s)<>0) then include(menuflags,clrscrbefore);
      if (pos('D',s)<>0) then include(menuflags,dontcenter);
      if (pos('N',s)<>0) then include(menuflags,nomenuprompt);
      if (pos('P',s)<>0) then include(menuflags,forcepause);
      if (pos('R',s)<>0) then include(menuflags,clrscrafter);
      if (pos('G',s)<>0) then include(menuflags,useglobal);
    end;
    while (not eof(filv)) do
    begin
      inc(noc);
      with cmdr[noc] do begin
        readln(filv,ldesc);
        readln(filv,sdesc);
        readln(filv,ckeys);
        readln(filv,acs);
        readln(filv,cmdkeys);
        readln(filv,mstring);
        readln(filv,s);
        if (pos('V',allcaps(s))<>0) then visible:=TRUE;
      end;
    end;
    close(filv);
    if (useglobal in menur.menuflags) then
    begin
      assign(filv,systat^.menupath+'GLOBAL.MNU');
      {$I-} reset(filv); {$I+}
      if (ioresult=0) then
      begin
        for i:=1 to 17 do readln(filv,s);
        while (not eof(filv)) do
        begin
          inc(noc);
          with cmdr[noc] do
          begin
            readln(filv,ldesc);
            readln(filv,sdesc);
            readln(filv,ckeys);
            readln(filv,acs);
            readln(filv,cmdkeys);
            readln(filv,mstring);
            readln(filv,s);
            if (pos('V',allcaps(s))<>0) then visible:=TRUE;
          end;
        end;
        close(filv);
      end;
    end;

    mqarea:=FALSE; fqarea:=FALSE; haseverytime:=FALSE;
    lcmdlistentry:=''; j:=0;
    for i:=1 to noc do begin
      if (cmdr[i].ckeys<>lcmdlistentry) then begin
        b:=(aacs(cmdr[i].acs));
        if (b) then inc(j);
(*
        if (b) and (j<>1) then cmdlist:=cmdlist+',';
        if (b) then cmdlist:=cmdlist+cmdr[i].ckeys;
*)
        if (b) then begin
          if ((cmdr[i].ckeys<>'FIRSTCMD') and (cmdr[i].ckeys<>'GTITLE') and (cmdr[i].ckeys<>'EVERYTIME')) then begin
            if (j<>1) then cmdlist:=cmdlist+',';
            cmdlist:=cmdlist+cmdr[i].ckeys;
          end else dec(j);
        end;
        lcmdlistentry:=cmdr[i].ckeys;
      end;
      if (cmdr[i].cmdkeys='M#') then mqarea:=TRUE;
      if (cmdr[i].cmdkeys='F#') then fqarea:=TRUE;
      if (cmdr[i].ckeys='EVERYTIME') then haseverytime:=TRUE;
    end;
  end;
end;

function oksecurity(i:integer; var cmdnothid:boolean):boolean;
begin
  oksecurity:=FALSE;
  if (cmdr[i].visible) then cmdnothid:=TRUE;
  if (not aacs(cmdr[i].acs)) then exit;
  oksecurity:=TRUE;
end;

procedure genericmenu(t:integer);
var glin:array [1..maxmenucmds] of astr;
    s,s1:astr;
    gcolors:array [1..3] of char;
    onlin,i,j,colsiz,numcols,numglin,maxright:integer;
    abort,next,b,cmdnothid:boolean;

  function gencolored(keys,desc:astr; acc:boolean):astr;
  begin
    s:=desc;
    j:=pos(allcaps(keys),allcaps(desc));
    if (j<>0) and (pos('|',desc)=0) then begin
      insert('|'+gcolors[3],desc,j+length(keys)+1);
      insert('|'+gcolors[1],desc,j+length(keys));
      if (acc) then insert('|'+gcolors[2],desc,j);
      if (j<>1) then
        insert('|'+gcolors[1],desc,j-1);
    end;
    gencolored:='|'+gcolors[3]+desc;
  end;

  function semicmd(s:string; x:integer):string;
  var i,p:integer;
  begin
    i:=1;
    while (i<x) and (s<>'') do begin
      p:=pos(';',s);
      if (p<>0) then s:=copy(s,p+1,length(s)-p) else s:='';
      inc(i);
    end;
    while (pos(';',s)<>0) do s:=copy(s,1,pos(';',s)-1);
    semicmd:=s;
  end;

  procedure newgcolors(s:string);
  var s1:string;
  begin
    s1:=semicmd(s,1); if (s1<>'') then gcolors[1]:=s1[1];
    s1:=semicmd(s,2); if (s1<>'') then gcolors[2]:=s1[1];
    s1:=semicmd(s,3); if (s1<>'') then gcolors[3]:=s1[1];
  end;

  procedure gen_tuto;
  var i,j:integer;
      b:boolean;
  begin
    numglin:=0; maxright:=0; glin[1]:='';
    for i:=1 to noc do
    begin
      b:=oksecurity(i,cmdnothid);
      if (b) or (cmdr[i].visible) then
        if (cmdr[i].ckeys='GTITLE') then begin
          inc(numglin); glin[numglin]:=cmdr[i].ldesc;
          j:=lenn(glin[numglin]); if (j>maxright) then maxright:=j;
          if (cmdr[i].mstring<>'') then newgcolors(cmdr[i].mstring);
        end else
          if (cmdr[i].ldesc<>'') then begin
            inc(numglin);
            glin[numglin]:=gencolored(cmdr[i].ckeys,cmdr[i].ldesc,b);
            j:=lenn(glin[numglin]); if (j>maxright) then maxright:=j;
          end;
    end;
  end;

  procedure stripc(var s1:astr);
  begin
    s1:=stripcolor(s1);
  end;

  procedure fixit(var s:astr; len:integer);
  var s1:astr;
  begin
    s1:=s;
    stripc(s1);
    if (length(s1)<len) then
      s:=s+copy('                                        ',1,len-length(s1))
    else
      if (length(s1)>len) then s:=s1;
  end;

  procedure gen_norm;
  var s1:astr;
      i,j:integer;
      b:boolean;
  begin
    s1:=''; onlin:=0; numglin:=1; maxright:=0; glin[1]:='';
    for i:=1 to noc do begin
      b:=oksecurity(i,cmdnothid);
      if (b) or (cmdr[i].visible) then
      begin
        if (cmdr[i].ckeys='GTITLE') then begin
          if (onlin<>0) then inc(numglin);
          glin[numglin]:=#2+cmdr[i].ldesc;
          inc(numglin); glin[numglin]:='';
          onlin:=0;
          if (cmdr[i].mstring<>'') then newgcolors(cmdr[i].mstring);
        end else begin
          if (cmdr[i].sdesc<>'') then begin
            inc(onlin); s1:=gencolored(cmdr[i].ckeys,cmdr[i].sdesc,b);
            if (onlin<>numcols) then fixit(s1,colsiz);
            glin[numglin]:=glin[numglin]+s1;
          end;
          if (onlin=numcols) then begin
            j:=lenn(glin[numglin]); if (j>maxright) then maxright:=j;
            inc(numglin); glin[numglin]:=''; onlin:=0;
          end;
        end;
      end;
    end;
    if (onlin=0) then dec(numglin);
  end;

  function tcentered(c:integer; s:astr):astr;
  const spacestr='                                               ';
  begin
    c:=(c div 2)-(lenn(s) div 2);
    if (c<1) then c:=0;
    tcentered:=copy(spacestr,1,c)+s;
  end;

  procedure dotitles;
  var i:integer;
      b:boolean;
  begin
    b:=FALSE;
    if (clrscrbefore in menur.menuflags) then begin
      cls;
      nl; nl;
    end;
    if (menur.menuname<>'') then
    begin
      if (not b) then begin nl; b:=TRUE; end;
      if (dontcenter in menur.menuflags) then
        printacr(menur.menuname,abort,next)
      else
        printacr(tcentered(maxright,menur.menuname),abort,next);
    end;
    nl;
  end;

begin
  for i:=1 to 3 do gcolors[i]:=menur.gcol[i];
  numcols:=menur.gencols;
  case numcols of
    2:colsiz:=39; 3:colsiz:=25; 4:colsiz:=19;
    5:colsiz:=16; 6:colsiz:=12; 7:colsiz:=11;
  end;
  if (numcols*colsiz>=thisuser.linelen) then
    numcols:=thisuser.linelen div colsiz;
  abort:=FALSE; next:=FALSE;
  if (t=2) then gen_norm else gen_tuto;
  dotitles;
  for i:=1 to numglin do
    if (glin[i]<>'') then
      if (glin[i][1]<>#2) then
        printacr(glin[i],abort,next)
      else
        printacr(tcentered(maxright,copy(glin[i],2,length(glin[i])-1)),
                 abort,next);
end;

procedure showthismenu;
var s:astr;
begin
  case chelplevel of
    2:begin
        nofile:=TRUE; s:=menur.directive;
        if (s<>'') then begin
          if (pos('@S',s)<>0) then
            printf(substall(s,'@S',cstr(thisuser.sl)));
          if (nofile) then printf(substall(s,'@S',''));
        end;
      end;
    3:begin
        nofile:=TRUE; s:=menur.tutorial;
        if (s<>'') then begin
          if (pos('.',s)=0) then s:=s+'.tut';
          if (pos('@S',s)<>0) then
            printf(substall(s,'@S',cstr(thisuser.sl)));
          if (nofile) then printf(substall(s,'@S',''));
        end;
      end;
  end;
  if ((nofile) and (chelplevel in [2,3])) then genericmenu(chelplevel);
end;

end.
