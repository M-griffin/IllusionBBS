(* File Promt Menu 2 *)
{$A+,B+,F+,I+,L+,O+,R-,S-,V-,T+}

unit FMenu2;

interface

uses
  crt, dos, common;
  

procedure showcmds(listtype:integer);
procedure readin;
function oksecurity(i:integer; var cmdnothid:boolean):boolean;
procedure dopulls(var inp : string);


var gotcommand:boolean;



implementation

uses FMenu, Mrec;


procedure showcmds(listtype:integer);
var i,j,numrows:integer;
    s,s1:astr;
    abort,next:boolean;

  function type1(i:integer):astr;
  begin
    type1:=mn(i,3)+mlnnomci(cmdr2[i].ckeys,3)+mlnnomci(cmdr2[i].cmdkeys,4)+
           mlnnomci(cmdr2[i].mstring,15);
  end;

  function sfl(b:boolean; c:char):char;
  begin
    if (b) then sfl:=c else sfl:='-';
  end;

begin
  abort:=FALSE; next:=FALSE;
  if (noc<>0) then begin
    case listtype of
      0:begin
          printacr('|15'+'# '+'Command       '+'Fl'+
                   '  ACS      '+'Cmd'+'  MString',abort,next);
          printacr('|07'+'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',abort,next);
          i:=1;
          while (i<=noc) and (not abort) and (not hangup) do begin
            print{acr}({#3#0+}mn(i,2)+' '+{#3#3+}mlnnomci(cmdr2[i].ckeys,14)+' '+
                     sfl(hidden in cmdr2[i].commandflags,'H')+
                     sfl(unhidden in cmdr2[i].commandflags,'U')+' '+
                     {#3#9+}mlnnomci(cmdr2[i].acs,10)+' '+
                     {#3#3+}mlnnomci(cmdr2[i].cmdkeys,2)+' '+
                     cmdr2[i].mstring);{,abort,next);}
            inc(i);
          end;
        end;
      1:begin
          numrows:=(noc+2) div 3;
          i:=1;
          s:={#3#0}'|15'+'# '+'KK-Typ-MString        ';
          s1:={#3#9}'|07'+'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ';
          while (i<=numrows) and (i<3) do begin
            s:=s+'|15 # '+'KK-Typ-MString        ';
            s1:=s1+'|07ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ';
            inc(i);
          end;
          printacr(s,abort,next);
          printacr(s1,abort,next);
          i:=0;
          repeat
            inc(i);
            s:=type1(i);
            for j:=1 to 2 do
              if i+(j*numrows)<=noc then
                s:=s+' '+type1(i+(j*numrows));
            print{acr}({#3#1+}s{,abort,next});
          until ((i>=numrows) or (abort) or (hangup));
        end;
    end;
  end
  else print('- No Commands on this menu -');
end;

procedure dopulls(var inp : string);
var cc,c:char;
    newcmd,s:string;
    ckey,rep,ex,x,numberofchoices:integer;
    pp,qq,choice,tries,zz,xx,yy,i:integer;
    execnum:array [1..50] of integer;
    done:boolean;

begin

  done:=false;
  newcmd:='';
  if menur2.directive <> '' then printf(menur2.directive);
  ex:=1;
  thisuser.ac:=thisuser.ac+[ansi];
  
  
  while (not done) and (not hangup) do begin
    tries:=0;
    xx:=1;
    yy:=1;
    pp:=1;
    qq:=1;
    ex:=1;
    for i:=1 to noc do begin
      if (pull in cmdr2[i].commandflags) then
      begin
        execnum[ex]:=i;
        inc(ex);
      end;
    end; {for i:=1 to noc}
    
    numberofchoices:=ex-1;
    choice:=1;

    
    ansig(wherex,wherey);
    sprompt('[1;30m°[37mÜ[47mß[0mÛÛß[1;47mÜ [0mÜ [1;30m°');


    for rep:=1 to numberofchoices do begin
      xx := value(cmdr2[execnum[rep]].xpoint);
      if xx = 0 then xx := wherex;
      yy := value(cmdr2[execnum[rep]].ypoint);
      if yy = 0 then yy := wherey;
      ansig(xx, yy);
      sprompt('|16'+cmdr2[execnum[rep]].ldesc+'|16');
    end; {rep:=1 to numberofchoices}

    xx := value(cmdr2[execnum[1]].xpoint);
    if xx = 0 then xx := wherex;
    yy := value(cmdr2[execnum[1]].ypoint);
    if yy = 0 then yy := wherey;
    ansig(xx, yy);
    sprompt('|16'+cmdr2[execnum[1]].sdesc+'|16');

    while (not done) and (not hangup) do
    begin
      getkey(c);
      c:=upcase(c);
      if (c in [^[,'[',']',^M, ^N]) then
      begin
      if c <> ^M then
        begin
        getkey(c);
        c := upcase(c);
        end;
      if (c in ['[','A','B','C','D','P','H','K','M',^M,^N]) then
      begin
      if c = '[' then
        getkey(c);

      c := upcase(c);

      if (filemnu) and (c in ['B','A']) then
        begin
        inp := '['+c;
        c := 'Z';
        done := true;
        end;

      if ((c='K') or {(c='A') or} (c='D')) then begin   {Cursor Up}  { ESC[A is cursor up }
        inp := c;
        xx:=value(cmdr2[execnum[choice]].xpoint);
        if xx = 0 then xx := wherex;
        yy:=value(cmdr2[execnum[choice]].ypoint);
        if yy = 0 then yy := wherey;
        ansig(xx,yy);
        sprompt('|16'+cmdr2[execnum[choice]].ldesc+'|16');  { terms send for up  }
        dec(choice);
        if choice < 1 then choice := numberofchoices;
        xx:=value(cmdr2[execnum[choice]].xpoint);
        if xx = 0 then xx := wherex;
        yy:=value(cmdr2[execnum[choice]].ypoint);
        if yy = 0 then yy := wherey;
        ansig(xx,yy);
        sprompt('|16'+cmdr2[execnum[choice]].sdesc+'|16');
      end; {c='A', c='D'}

      if ((c='M') or {(c='B') or} (c='C')) then begin   {Cursor Down}
        xx:=value(cmdr2[execnum[choice]].xpoint);
        if xx = 0 then xx := wherex;
        yy:=value(cmdr2[execnum[choice]].ypoint);
        if yy = 0 then yy := wherey;
        ansig(xx,yy);
        sprompt('|16'+cmdr2[execnum[choice]].ldesc+'|16');
        inc(choice);
        if choice > numberofchoices then choice := 1;
        xx:=value(cmdr2[execnum[choice]].xpoint);
        if xx = 0 then xx := wherex;
        yy:=value(cmdr2[execnum[choice]].ypoint);
        if yy = 0 then yy := wherey;
        ansig(xx,yy);
        sprompt('|16'+cmdr2[execnum[choice]].sdesc+'|16');
      end; {c='B', c='C'}

      if c=#13 then begin
        {ansig(1,23);}
        inp := ^M;
        nl;
        gotcommand:=true;
        done:=true;
        cc:=cmdr2[execnum[choice]].ckeys[1];
        for ckey:=1 to noc do begin
          if (cmdr2[ckey].ckeys[1]=cc) then
          begin
            done:=true;
            newcmd:='';
            domenucommand(done,cmdr2[ckey].cmdkeys+cmdr2[ckey].mstring,newcmd);
          end;
        end;  {ckey:=1 to noc}
      end; {c=#13}
    end;
    end
  else {if (c in [#27,'[',']','C','D','A','B',^M,^N]) then}
  begin
    inp := ^M;
    for ckey:=1 to noc do
    begin
      if (cmdr2[ckey].ckeys[1]=c) then
      begin
        done:=true;
        setc(7);
        domenucommand(done,cmdr2[ckey].cmdkeys+cmdr2[ckey].mstring,newcmd);
      end;
    end; {ckey=1 to noc}
  end; {else begin}
 end; {while (not done) and (not hangup) and (not getout) do}
 end; {while (not done) and (not hangup) do begin}  
end; {begin}


procedure readin;
var infile        : file;
    s             ,
    lcmdlistentry : string;
    i             ,
    j             : byte;
    d             : menurec2;
    newNoc        : byte;
begin
   cmdlist:='';
   noc:=0;
   
   curmenu := systat^.menupath+'FILEP.MEN';
   
   assign(infile,curmenu);
   {$I-} reset(infile,1); {$I-}
   if (ioresult<>0) then begin
      assign(infile,curmenu);
      {$I-} reset(infile,1); {$I-}
      if (ioresult<>0) then begin
         { Menu Not found }
         sysoplog('"'+curmenu+'" is MISSING - Hung user up.');
	 sprint('FILEP.MEN menu is MISSING.  Please inform SysOp.');
         sprint('Critical error.');
         curmenu := last_menu;
         exit;        
      end;
   end;
   
   if (not hangup) then begin
      blockread(infile,menur2,sizeof(menur2));
      repeat
         inc(noc);
         blockread(infile,cmdr2[noc],sizeof(cmdr2[noc]));
      until eof(infile);
      mqarea:=FALSE;
      fqarea:=FALSE;
      lcmdlistentry:='';
      j:=0;
      for i:=1 to noc do begin
         if (cmdr2[i].ckeys<>lcmdlistentry) then begin
            if (aacs(cmdr2[i].acs)) then begin
               inc(j);
               if ((cmdr2[i].ckeys<>'FIRSTCMD') and (cmdr2[i].ckeys<>'GTITLE')) then begin
                  if (j<>1) then cmdlist:=cmdlist+',';
                  cmdlist:=cmdlist+cmdr2[i].ckeys;
               end
               else dec(j); { if not firstcmd }
            end; { if b is true }
            lcmdlistentry:=+cmdr2[i].ckeys;
         end; { if command key hasn't been used }
         if (cmdr2[i].cmdkeys='M#') then mqarea:=TRUE;
         if (cmdr2[i].cmdkeys='F#') then fqarea:=TRUE;
      end; { for i = 1 to total command }
      close(infile);
   end; { if not hangup }
   
   
   if not(pulldown in menur2.menuflags) then exit;
        
end;



function oksecurity(i:integer; var cmdnothid:boolean):boolean;
begin
   oksecurity:=FALSE;
   if (unhidden in cmdr2[i].commandflags) then cmdnothid:=TRUE;
   if (not aacs(cmdr2[i].acs)) then exit;
   oksecurity:=TRUE;
end;


end.
