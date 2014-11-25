(*****************************************************************************)
(* Illusion BBS - SysOp routines  [7/11] (menu editor)                       *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop7;

interface

uses
  crt, dos,
  common, sysop7m,   
  MsgF; { Dir }

procedure menu_edit;

implementation

var filv:text;

function readin:boolean;   (* read in the menu file curmenu *)
var s:astr;
    i:byte;
begin
  noc:=0;
  assign(filv,curmenu);
  {$I-} reset(filv); {$I+}
  if ioresult<>0 then
  begin
    print('"'+curmenu+'" does not exist.');
    readin:=FALSE;
  end else
  begin
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
    readin:=TRUE;
  end;
end;

procedure menu_edit;
var nocsave,i,i1,i2,ii:integer;
    c,c1:char;
    hadpause,abort,next:boolean;
    s,scurmenu:astr;
    s1:string[1];

  procedure makenewfile(fn:astr);                 (* make a new command list *)
  var f:text;
  begin
    assign(f,fn);
    {$I-} rewrite(f); {$I+}
    if (ioresult=0) then
    begin
      writeln(f,'New Illusion 3.0 Menu');
      writeln(f,'*OFF*');
      writeln(f,'*OFF*');
      writeln(f,'');
      writeln(f,'|wCommand|K: |W');
      writeln(f,'0');
      writeln(f,'31');
      writeln(f,'7');
      writeln(f,'');
      writeln(f,'');
      writeln(f,'MAIN');
      writeln(f,'0');
      writeln(f,'4');
      writeln(f,'K');
      writeln(f,'W');
      writeln(f,'w');
      writeln(f,'CG');
      writeln(f,'[Q] Quit to the main menu');
      writeln(f,'[Q] Quit to main');
      writeln(f,'Q');
      writeln(f,'');
      writeln(f,'-^');
      writeln(f,'main');
      writeln(f,'');
      close(f);
    end;
  end;

  procedure newcmd(n:integer);                          { new command stuff }
  begin
    with cmdr[n] do
    begin
      ldesc:='[x] New Command';
      sdesc:='[x] New Command';
      ckeys:='X';
      acs:='';
      cmdkeys:='-L';
      mstring:='';
      visible:=false;
    end;
  end;

  procedure moveinto(i1,i2:integer);
  begin
    cmdr[i1]:=cmdr[i2];
  end;

  procedure mes;
  var s:astr;
      i:byte;
  begin
    rewrite(filv);
    with menur do begin
      writeln(filv,menuname);
      writeln(filv,directive);
      writeln(filv,tutorial);
      writeln(filv,mpromptf);
      writeln(filv,menuprompt);
      writeln(filv,forceinput);
      writeln(filv,cstr(hilite));
      writeln(filv,cstr(lolite));
      writeln(filv,acs);
      writeln(filv,password);
      writeln(filv,fallback);
      writeln(filv,forcehelplevel);
      writeln(filv,gencols);
      for i:=1 to 3 do writeln(filv,gcol[i]);
      s:='';
      if (clrscrbefore in menuflags) then s:=s+'C';
      if (dontcenter in menuflags) then s:=s+'D';
      if (nomenuprompt in menuflags) then s:=s+'N';
      if (forcepause in menuflags) then s:=s+'P';
      if (clrscrafter in menuflags) then s:=s+'R';
      if (useglobal in menuflags) then s:=s+'G';
      writeln(filv,s);
    end;
    for i:=1 to noc do
    begin
      with cmdr[i] do
      begin
        writeln(filv,ldesc);
        writeln(filv,sdesc);
        writeln(filv,ckeys);
        writeln(filv,acs);
        writeln(filv,cmdkeys);
        writeln(filv,mstring);
        if (visible) then s:='V' else s:='';
        writeln(filv,s);
      end;
    end;
    close(filv);
    sysoplog('* Saved menu file: '+scurmenu);
  end;

  procedure med;
  begin
    sprompt('|wDelete menu file: |W'); input(s,8);
    s:=systat^.menupath+allcaps(s)+'.MNU';
    assign(filv,s);
    {$I-} reset(filv); {$I+}
    if (ioresult=0) then
    begin
      close(filv);
      sysoplog('* Deleted menu file: '+s);
      erase(filv);
    end;
  end;

  procedure mei;
  begin
    sprompt('|wInsert menu file: |W'); input(s,8);
    s:=systat^.menupath+allcaps(s)+'.MNU';
    assign(filv,s);
    {$I-} reset(filv); {$I+}
    if (ioresult=0) then
      close(filv)
    else
    begin
      sysoplog('* Inserted new menu file: '+s);
      makenewfile(s);
    end;
  end;

  procedure mem;
  var c:char;
      b:byte;
      bb:boolean;

    procedure memd(i:integer);                   (* delete command from list *)
    var x:word;
    begin
      if (i>=1) and (i<=noc) then
      begin
        for x:=i+1 to noc do cmdr[x-1]:=cmdr[x];
        dec(noc);
      end;
    end;

    procedure memi(i:integer);             (* insert a command into the list *)
    var x:word;
        s:astr;
    begin
      if (i>=1) and (i<=noc+1) and (noc<50) then
      begin
        inc(noc);
        if (i<>noc) then
          for x:=noc downto i do cmdr[x]:=cmdr[x-1];
        newcmd(i);
      end;
    end;

    procedure memp;
    var i,j,k:integer;
    begin
      sprompt('|wMove command |K[|C1|c-|C'+cstr(noc)+'|K] |W'); inu(i);
      if ((not badini) and (i>=1) and (i<=noc)) then
      begin
        sprompt('|wMove before |K[|C1|c-|C'+cstr(noc+1)+'|K] |W');
        inu(j);
        if ((not badini) and (j>=1) and (j<=noc+1) and (j<>i) and (j<>i+1)) then
        begin
          memi(j);
          if j>i then k:=i else k:=i+1;
          cmdr[j]:=cmdr[k];
          if j>i then memd(i) else memd(i+1);
        end;
      end;
    end;

    procedure editcommands;
    var c:char;
        ii:byte;
        i,j,k:integer;
    begin
      c:=#0;
      if hadpause then include(thisuser.ac,pause);
      repeat
        abort:=false; next:=false;
        cls;
        sprint('|w#   Description          Keys   Vis ACS        Cmd MString');
        sprint('|K|LI');
        ii:=1;
        while (ii<=noc) and (not abort) and (not hangup) do
          with cmdr[ii] do
          begin
            sprint('|W'+mn(ii,3)+' |w'+mlnnomci(sdesc,20)+' '+mln(ckeys,6)+' '+
                   mln(syn(visible),4)+''+mln(acs,10)+' '+mln(cmdkeys,3)+
                   mlnnomci(mstring,28));
            wkey(abort,next);
            inc(ii);
          end;
        sprint('|K|LI');
        sprompt('|wMenu Command Editor |K[|CD|c:elete|K/|CI|c:nsert|K/|CE|c:dit|K/|CM|c:ove|K/|CQ|c:uit|K] |W');
        onek(c,'QDIEM'^M);
        nl;
        case c of
          'D':begin
                sprompt('|wDelete command |K[|C1|c-|C'+cstr(noc)+'|K] |W');
                ini(b);
                if (not badini) and (b>=1) and (b<=noc) then memd(b);
              end;
          'I':if (noc<50) then
              begin
                sprompt('|wInsert before |K[|C1|c-|C'+cstr(noc+1)+'|K] |W');
                inu(i);
                if (not badini) and (i>=1) and (i<=noc+1) then
                begin
                  sprompt('|wNumber to insert |K[|C1|c-|C'+cstr(50-noc)+'|K] |K[|C1|K] |W');
                  inu(j);
                  if (badini) then j:=1;
                  if (j>=1) and (j<=50-noc) then for k:=1 to j do memi(i);
                end;
              end else
                sprint('|RYou already have 50 commands; delete some to make room for more.|LF|PA');
          'E':begin
                exclude(thisuser.ac,pause);
                memm(scurmenu);
                if hadpause then include(thisuser.ac,pause);
              end;
          'M':memp;
        end;
      until (c='Q') or (hangup);
      exclude(thisuser.ac,pause);
    end;

    function inputtype:astr;
    begin
      case menur.forceinput of
        0:inputtype:='None';
        1:inputtype:='Full line';
        2:inputtype:='Hot key';
      end;
    end;

    function forcehelptype:astr;
    begin
      case menur.forcehelplevel of
        0:forcehelptype:='None';
        1:forcehelptype:='Expert';
        2:forcehelptype:='Normal';
        3:forcehelptype:='Extended';
      end;
    end;

  begin
    sprompt('|wEdit menu: |W'); input(s,8);
    assign(filv,systat^.menupath+s+'.MNU');
    {$I-} reset(filv); {$I+}
    if ioresult=0 then
    begin
      close(filv);
      scurmenu:=s;
      curmenu:=systat^.menupath+scurmenu+'.MNU';
      if readin then
      begin
        c:=#0;
        exclude(thisuser.ac,pause);
        with menur do
          repeat
            if (c in [#0,^M,' ']) then
            begin
              cls;
              sprint('|WMenu Filename: '+scurmenu);
              nl;
              sprint('|K[|CA|K] |cGeneric menu title |w'+menuname);
              sprint('|K[|CB|K] |cPrompt string      |w'+menuprompt);
              sprint('|K[|CC|K] |cPrompt text file   |w'+mlnnomci(mpromptf,17)+
                    '|K[|CR|K] |cUse global menu    |w'+syn(useglobal in menuflags));
              sprint('|K[|CD|K] |cNormal help file   |w'+mlnnomci(aonoff(directive='','*Generic*',directive),17)+
                    '|K[|CS|K] |cClear before menu  |w'+syn(clrscrbefore in menuflags));
              sprint('|K[|CE|K] |cExtended help file |w'+mlnnomci(aonoff(tutorial='','*Generic*',tutorial),17)+
                    '|K[|CT|K] |cCenter titles      |w'+syn(not (dontcenter in menuflags)));
              sprint('|K[|CF|K] |cAccess required    |w'+mlnnomci(acs,17)+
                    '|K[|CU|K] |cNo menu prompt     |w'+syn(nomenuprompt in menuflags));
              sprint('|K[|CG|K] |cPassword           |w'+mlnnomci(password,17)+
                    '|K[|CV|K] |cPause before menu  |w'+syn(forcepause in menuflags));
              sprint('|K[|CH|K] |cFallback menu      |w'+mlnnomci(fallback,17)+
                    '|K[|CW|K] |cClear after input  |w'+syn(clrscrafter in menuflags));
              sprint('|K[|CI|K] |cForced help level  |w'+forcehelptype);
              sprint('|K[|CJ|K] |cForced input type  |w'+inputtype);
              sprint('|K[|CK|K] |cGeneric columns    |w'+cstr(gencols));
              sprint('|K[|CL|K] |cGen. bracket color |w'+gcol[1]);
              sprint('|K[|CM|K] |cGen. command color |w'+gcol[2]);
              sprint('|K[|CN|K] |cGen. desc. color   |w'+gcol[3]);
              sprint('|K[|CO|K] |cLightbar hi color  |w'); displaycolor(24,17,hilite); nl;
              sprint('|K[|CP|K] |cLightbar lo color  |w'); displaycolor(24,18,lolite); nl;
              nl;
              sprint('|K[|CSpace|K] |cEdit commands');
              nl;
              sprompt('|wCommand |K[|CQ|c:uit|K] |W');
            end;
            ansig(17,22);
            sprompt(#32+^H+'|W');
            onek(c,'QABCDEFGHIJKLMNOPRSTUVW '^M);
            case c of
              'A':inputxy(24,3,menuname,56);
              'B':inputxy(24,4,menuprompt,56);
              'C':inputxy(24,5,mpromptf,-12);
              'D':begin
                    inputxy(24,6,directive,-12);
                    sprompt('|w|I2406'+mlnnomci(aonoff(directive='','*Generic*',directive),17));
                  end;
              'E':begin
                    inputxy(24,7,tutorial,-12);
                    sprompt('|w|I2407'+mlnnomci(aonoff(tutorial='','*Generic*',tutorial),17));
                  end;
              'F':inputxy(24,8,acs,16);
              'G':inputxy(24,9,password,-15);
              'H':inputxy(24,10,fallback,-8);
              'I':begin
                    inc(forcehelplevel);
                    if (forcehelplevel>3) then forcehelplevel:=0;
                    sprompt('|w|I2411'+forcehelptype+'|LC');
                  end;
              'J':begin
                    inc(forceinput);
                    if (forceinput>2) then forceinput:=0;
                    sprompt('|w|I2412'+inputtype+'|LC');
                  end;
              'K':gencols:=inputnumxy(24,13,gencols,1,2,7);
              'L':inputcharxy(24,14,gcol[1]);
              'M':inputcharxy(24,15,gcol[2]);
              'N':inputcharxy(24,16,gcol[3]);
              'O':inputcolorxy(24,17,hilite);
              'P':inputcolorxy(24,18,lolite);
              'R':begin
                    bb:=useglobal in menuflags;
                    if (bb) then exclude(menur.menuflags,useglobal)
                            else include(menur.menuflags,useglobal);
                    switchyn(64,5,bb);
                  end;
              'S':begin
                    bb:=clrscrbefore in menuflags;
                    if (bb) then exclude(menur.menuflags,clrscrbefore)
                            else include(menur.menuflags,clrscrbefore);
                    switchyn(64,6,bb);
                  end;
              'T':begin
                    bb:=not (dontcenter in menuflags);
                    if (not bb) then exclude(menur.menuflags,dontcenter)
                            else include(menur.menuflags,dontcenter);
                    switchyn(64,7,bb);
                  end;
              'U':begin
                    bb:=nomenuprompt in menuflags;
                    if (bb) then exclude(menur.menuflags,nomenuprompt)
                            else include(menur.menuflags,nomenuprompt);
                    switchyn(64,8,bb);
                  end;
              'V':begin
                    bb:=forcepause in menuflags;
                    if (bb) then exclude(menur.menuflags,forcepause)
                            else include(menur.menuflags,forcepause);
                    switchyn(64,9,bb);
                  end;
              'W':begin
                    bb:=clrscrafter in menuflags;
                    if (bb) then exclude(menur.menuflags,clrscrafter)
                            else include(menur.menuflags,clrscrafter);
                    switchyn(64,10,bb);
                  end;
              ' ':editcommands;
            end;
          until ((c='Q') or (hangup));
        mes;
      end;
    end;
  end;

begin
  nocsave:=noc;
  noc:=0;
  hadpause:=pause in thisuser.ac;

  repeat
    cls;
    dir(systat^.menupath,'*.mnu',FALSE);
    nl;
    sprompt('|wMenu Editor |K[|CD|c:elete|K/|CI|c:nsert|K/|CE|c:dit|K/|CQ|c:uit|K] |W');
    onek(c,'QDIE'^M);
    nl;
    case c of
      'D':med;
      'I':mei;
      'E':mem;
    end;
  until (c='Q') or (hangup);

  if hadpause then include(thisuser.ac,pause);
  noc:=nocsave;
end;

end.
