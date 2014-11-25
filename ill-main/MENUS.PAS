(*****************************************************************************)
(* Illusion BBS - Menu routines [1/3]                                        *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O-,R-,S-,V-}



{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

Unit Menus;

Interface

Uses
  Crt,Dos,
  InitP,Common,Common2,

  Sysop2,Sysop3,Sysop4,Sysop6,
  Sysop7,Sysop8,Sysop9,Sysop10,Sysop11,

  Mail0,Mail1,Mail2,Mail3,Mail4,
  Mail6,

  Newfile,
  Newfile2,

  Misc1,
  Misc2,
  Misc3,
  infoform,
  MiscX,
  CUser,
  Doors,
  Menus2,
  Menus3,
  MyIO,
  Telec,
  BBSlist,
  AutoMsg,
  IplX,
  
  FilePEd;



var J:integer;

Procedure readin2;
Procedure mainmenuhandle(var cmd:string);
Procedure fcmd(cmd:string; var i:integer; noc:integer;
               var cmdexists,cmdnothid:boolean);
Procedure domenuexec(cmd:string; var newmenucmd:string);
Procedure domenucommand(var done:boolean; cmd:string; var newmenucmd:string);

Implementation

function peopleon:boolean;
var n:noderec;
    d:boolean;
begin
  setfileaccess(readonly,denynone);
  reset(nodef);
  d:=false;
  while not (eof(nodef)) do
  begin
    read(nodef,n);
    if (n.unum>0) and
       (n.unum<>usernum) and
       (filepos(nodef)+1<>nodenum)
    then
      d:=true;
  end;
  close(nodef);
  peopleon:=d;
end;

procedure readin2;
var s:string;
    nacc:boolean;
begin
  readin;
  nacc:=FALSE;
  with menur do begin
    if ((not aacs(acs)) or (password<>'')) then
    begin
      nacc:=TRUE;
      if (password<>'') then
      begin
        nl; prt('Password: '); input(s,15);
        if (s=password) then nacc:=FALSE;
      end;
      if (nacc) then
      begin
        nl; print('Access denied.'); pausescr;
        print('Dropping back to fallback menu...');
        curmenu:=systat^.menupath+fallback+'.mnu';
        readin;
      end;
    end;
    if (not nacc) then
      if (forcehelplevel<>0) then
        chelplevel:=forcehelplevel
      else
        if (novice in thisuser.ac) then chelplevel:=2 else chelplevel:=1;
  end;
end;

procedure checkforcelevel;
begin
  if (chelplevel<menur.forcehelplevel) then chelplevel:=menur.forcehelplevel;
end;

procedure getcmd(var s:string);
var s1,ss,oss,shas0,shas1:string;
    i,newarea:integer;
    c,cc:char;
    oldco:byte;
    achange,bb,gotcmd,has0,has1,has2,hasenter:boolean;
begin
  s:='';
  if (buf<>'') then
    if (copy(buf,1,1)='`') then
    begin
      buf:=copy(buf,2,length(buf)-1);
      i:=pos('`',buf);
      if (i<>0) then
      begin
        s:=allcaps(copy(buf,1,i-1)); buf:=copy(buf,i+1,length(buf)-i);
        nl; exit;
      end;
    end;

  shas0:='?|'; shas1:='';
  has0:=FALSE; has1:=FALSE; has2:=FALSE; hasenter:=FALSE;

  { find out what kind of 0:"x", 1:"/x", and 2:"//xxxxxxxx..." commands
    are in this menu. }

  for i:=1 to noc do
    if (aacs(cmdr[i].acs)) then
      if (cmdr[i].ckeys[0]=#1) then
      begin
        has0:=TRUE; shas0:=shas0+cmdr[i].ckeys;
      end else
        if ((cmdr[i].ckeys[1]='/') and (cmdr[i].ckeys[0]=#2)) then
        begin
          has1:=TRUE; shas1:=shas1+cmdr[i].ckeys[2];
         end else if (cmdr[i].ckeys='ENTER') then hasenter:=TRUE
          else
           has2:=TRUE;

  oldco:=curco;

  gotcmd:=FALSE; ss:='';
  if ((not (onekey in thisuser.ac)) or (menur.forceinput=1)) and (menur.forceinput<>2) then
  begin
    inputl(s,60);
    s:=allcaps(s);
  end else
  begin
    repeat
      getkey(c); c:=upcase(c);
      oss:=ss;
      if (ss='') then begin

        if (c=#13) then
          if (hasenter) then
             begin
              ss:='ENTER'; gotcmd:=TRUE;
             end
          else
            gotcmd:=TRUE;

        if ((c='/') and ((has1) or (has2) or (thisuser.sl=255))) then ss:='/';
        if (((fqarea) or (mqarea)) and (c in ['0'..'9'])) then
          ss:=c
        else
          if (pos(c,shas0)<>0) then begin gotcmd:=TRUE; ss:=c; end;
      end else
        if (ss='/') then begin
          if (c=^H) then ss:='';
          if ((c='/') and ((has2) or (thisuser.sl=255))) then ss:=ss+'/';
          if ((pos(c,shas1)<>0) and (has1)) then
            begin gotcmd:=TRUE; ss:=ss+c; end;
        end else
          if (copy(ss,1,2)='//') then begin
            if (c=#13) then
              gotcmd:=TRUE
            else
              if (c=^H) then
                ss:=copy(ss,1,length(ss)-1)
              else
                if (c=^X) then begin
                  for i:=1 to length(ss)-2 do
                    prompt(^H' '^H);
                  ss:='//';
                  oss:=ss;
                end else
                  if ((length(ss)<62) and (c>=#32) and (c<=#127)) then
                    ss:=ss+c;
          end else
            if ((length(ss)>=1) and (ss[1] in ['0'..'9']) and
                ((fqarea) or (mqarea))) then begin
              if (c=^H) then ss:=copy(ss,1,length(ss)-1);
              if (c=#13) then gotcmd:=TRUE;
              if (c in ['0'..'9']) then begin
                ss:=ss+c;
                if (length(ss)=3) then gotcmd:=TRUE;
              end;
            end;

      if ((length(ss)=1) and (length(oss)=2)) then setc(oldco);
      if (oss<>ss) then begin
        if (length(ss)>length(oss)) then
          if (not ((ss='ENTER') and (hasenter))) then prompt(copy(ss,length(ss),1));
        if (length(ss)<length(oss)) then prompt(^H' '^H);
      end;
      if ((not (ss[1] in ['0'..'9'])) and
        ((length(ss)=2) and (length(oss)=1))) then setc(systat^.inputfieldcolor);

    until ((gotcmd) or (hangup));

    if (copy(ss,1,2)='//') then ss:=copy(ss,3,length(ss)-2);

    s:=ss;
  end;

  nl;

  if (pos(';',s)<>0) then                 {* "command macros" *}
    if (copy(s,1,2)<>'\\') then begin
      if ((onekey in thisuser.ac) or (menur.forceinput=1)) and (menur.forceinput<>2) then begin
        s1:=copy(s,2,length(s)-1);
         if (copy(s1,1,1)='/') then s:=copy(s1,1,2) else s:=copy(s1,1,1);
         s1:=copy(s1,length(s)+1,length(s1)-length(s));
      end else begin
        s1:=copy(s,pos(';',s)+1,length(s)-pos(';',s));
        s:=copy(s,1,pos(';',s)-1);
      end;
      while (pos(';',s1)<>0) do s1[pos(';',s1)]:=^M;
      dm(' '+s1,c);
    end;
end;


function zero(s:string):string;
begin
  if (length(s)=1) then zero:='0'+s else zero:=s;
end;


procedure litbargetcmd(var s:string);
var shas0:string;
    i,j,current:integer;
    c,cc:char;
    x,y,a,oldco:byte;
    gotcmd:boolean;
begin
  s:='';
  litbar:=true;

  shas0:='|';

  for i:=1 to noc do
    if (aacs(cmdr[i].acs)) and (cmdr[i].ckeys[0]=#1) and
       (pos(cmdr[i].ckeys[1],shas0)=0) and (not (cmdr[i].ckeys[1] in ['[',']']))
       then
    begin
      shas0:=shas0+cmdr[i].ckeys;
      current:=findwave(zero(cstr(i)));
      ansig(waves[current]^.x,waves[current]^.y);
      setc(menur.lolite);
      sprompt(cmdr[i].sdesc);
    end;

  oldco:=curco;
  i:=findwave('HP');
  x:=waves[i]^.x;
  y:=waves[i]^.y;
  a:=waves[i]^.a;

  i:=1;
  while (i<=noc) and (not (aacs(cmdr[i].acs))) do inc(i);
  if (i>noc) then current:=1 else current:=i;
  i:=findwave(zero(cstr(current)));
  ansig(waves[i]^.x,waves[i]^.y);
  setc(menur.hilite);
  sprompt(cmdr[current].sdesc);
  if (x<>0) then
  begin
    ansig(x,y);
    setc(a);
    sprompt(cmdr[current].ldesc);
  end;

  gotcmd:=FALSE;
  repeat
    getkey(c);
    c:=upcase(c);

    case c of
      #27:begin
           getkey(cc);
           if (cc='[') then
           begin
             getkey(cc);
             if (cc in ['A'..'D']) then
             begin
               case cc of
                 'A',
                 'D':begin
                       i:=current;
                       repeat
                         if (i=1) then i:=noc else dec(i);
                       until ((aacs(cmdr[i].acs)) and
                              (cmdr[i].ckeys[0]=#1) and
                              (cmdr[i].sdesc<>'')) or
                             (i=current);
                     end;
                 'B',
                 'C':begin
                       i:=current;
                       repeat
                         if (i=noc) then i:=1 else inc(i);
                       until ((aacs(cmdr[i].acs)) and
                              (cmdr[i].ckeys[0]=#1) and
                              (cmdr[i].sdesc<>'')) or
                             (i=current);
                     end;
               end;
               j:=findwave(zero(cstr(current)));
               ansig(waves[j]^.x,waves[j]^.y);
               setc(menur.lolite);
               sprompt(cmdr[current].sdesc);
               if (x<>0) then
               begin
                 ansig(x,y);
                 setc(a);
                 if (lenn(cmdr[current].ldesc)>lenn(cmdr[i].ldesc)) then
                   sprompt(mln(cmdr[i].ldesc,lenn(cmdr[current].ldesc)))
                 else
                   sprompt(cmdr[i].ldesc);
               end;
               current:=i;
               j:=findwave(zero(cstr(current)));
               ansig(waves[j]^.x,waves[j]^.y);
               setc(menur.hilite);
               sprompt(cmdr[current].sdesc);
             end;
           end;
         end;

      #13:begin gotcmd:=TRUE; s:=cmdr[current].ckeys; end;

      else if (pos(c,shas0)<>0) then begin gotcmd:=TRUE; s:=c; end;

    end;
  until ((gotcmd) or (hangup));

  litbar:=false;
  setc(7);
end;



procedure mainmenuhandle(var cmd:string);
var newarea,i,nocsave:integer;
    wantshow,cmdexists,cmdnothid,done:boolean;
    newmenucmd:string;
label cutcode;
begin
  tleft;
  macok:=TRUE;

  if (menur.menuprompt='LIGHTBAR') then
  begin
    chelplevel:=2;
    clearwaves;
    for i:=1 to noc do addwave(zero(cstr(i)),'',xya);
    addwave('HP','',xya);
    i:=findwave('HP');
    waves[i]^.x:=0;
  end else
  begin
    checkforcelevel;
    if ((forcepause in menur.menuflags) and (chelplevel>1) and (lastcommandgood))
      then pausescr;
    lastcommandgood:=FALSE;
  end;
  showthismenu;

  if haseverytime then begin
    newmenucmd:=''; i:=0; done:=FALSE; nocsave:=noc;
    repeat
      fcmd('EVERYTIME',i,nocsave,cmdexists,cmdnothid);
      if (i<>0) then
        domenucommand(done,cmdr[i].cmdkeys+cmdr[i].mstring,newmenucmd);
    until ((i=0) or (done));
  end;

  if (not (menur.menuprompt='LIGHTBAR')) then
  begin

    if (not (nomenuprompt in menur.menuflags)) then
    begin
      if (menur.mpromptf<>'*OFF*') then
        printf(menur.mpromptf)
      else
        nofile:=true;
      if nofile then sprompt('|LF'+menur.menuprompt);
    end;

    getcmd(cmd);

    if (cmd='?') then
    begin
      cmd:='';
      inc(chelplevel);
      if (chelplevel>3) then chelplevel:=3;
      if ((menur.tutorial='*OFF*') and (chelplevel>=3)) then chelplevel:=2;
    end else
      if (menur.forcehelplevel<>0) then chelplevel:=menur.forcehelplevel
      else
        if (novice in thisuser.ac) then chelplevel:=2 else chelplevel:=1;

    checkforcelevel;

    if (fqarea) or (mqarea) then
    begin
      newarea:=value(cmd);

      if ((newarea<>0) or (copy(cmd,1,1)='0')) then begin
        if (fqarea) then begin
          if (newarea>=0) and (newarea<=maxuboards) then
            changefileboard(ccuboards[0][newarea]);
        end else
        if (mqarea) then
          if (newarea>=0) {and (newarea<=maxboards)} then
            changeboard(newarea);
        cmd:='';
      end;
    end;

  end else {lightbar}
    litbargetcmd(cmd);

  if (cmd<>'?') and (cmd<>'') and (clrscrafter in menur.menuflags) then cls;

end;

procedure fcmd(cmd:string; var i:integer; noc:integer;
               var cmdexists,cmdnothid:boolean);
var done:boolean;
begin
  done:=FALSE;
  repeat
    inc(i);
    if (cmd=cmdr[i].ckeys) then begin
      cmdexists:=TRUE;
      if (oksecurity(i,cmdnothid)) then done:=TRUE;
    end;
  until ((i>noc) or (done));
  if (i>noc) then i:=0;
end;

procedure domenuexec(cmd:string; var newmenucmd:string);
var cmdacs,cmdnothid,cmdexists,done:boolean;
    nocsave,i:integer;
begin
  if (newmenucmd<>'') then begin cmd:=newmenucmd; newmenucmd:=''; end;
  if (cmd<>'') then begin
    cmdacs:=FALSE; cmdexists:=FALSE; cmdnothid:=FALSE; done:=FALSE;
    nocsave:=noc; i:=0;
    repeat
      fcmd(cmd,i,nocsave,cmdexists,cmdnothid);
      if (i<>0) then begin
        cmdacs:=TRUE;
        domenucommand(done,cmdr[i].cmdkeys+cmdr[i].mstring,newmenucmd);
      end;
    until ((i=0) or (done));
    if (not done) then
      if ((not cmdacs) and (cmd<>'')) then begin
        nl;
        if ((cmdnothid) and (cmdexists)) then
          print('You don''t have enough access for this command.')
        else
          print('Invalid command.');
      end;
  end;
end;

procedure domenucommand(var done:boolean; cmd:string; var newmenucmd:string);
var filvar:text;
    {mheader:mheaderrec;}  {-M-}
    cms,s,s1,s2,ksc:string;
    i:integer;
    c1,c2,c:char;
    abort,next,b,nocmd,x:boolean;

  function semicmd(x:integer):string;
  var s:string;
      i,p:integer;
  begin
    s:=cms; i:=1;
    while (i<x) and (s<>'') do begin
      p:=pos(';',s);
      if (p<>0) then s:=copy(s,p+1,length(s)-p) else s:='';
      inc(i);
    end;
    while (pos(';',s)<>0) do s:=copy(s,1,pos(';',s)-1);
    semicmd:=s;
  end;

begin
  newmenutoload:=FALSE;
  newmenucmd:='';
  c1:=cmd[1]; c2:=cmd[2];
  cms:=copy(cmd,3,length(cmd)-2);
  nocmd:=FALSE;
  lastcommandovr:=FALSE;
  case c1 of
    '-':case c2 of
          'C':cls;
          'F':printf(cms);
          'L':begin nl; sprint(cms); end;
          'P':pausescr;
          'Q':readq(systat^.textpath+cms,0);
          'R':readasw1(cms);
          'S':sysoplog(cms);
          'W':commandline(cms);
          'Y':begin
                if (semicmd(3)<>'') and (semicmd(2)<>'') then begin
                  if (allcaps(copy(semicmd(1),1,1))='Y') then dyny:=TRUE;
                  if (semicmd(2)='Y') then x:=TRUE else x:=False;
                  nl; if (pynq(semicmd(3))<>x) then done:=TRUE; nl;
                end;
              end;
          ';':begin
                s:=cms;
                while (pos(';',s)<>0) do s[pos(';',s)]:=^M;
                dm(' '+s,c);
              end;
          '$':if (semicmd(1)<>'') then begin
                if (semicmd(2)='') then prt(':') else prt(semicmd(2));
                input(s,20);
                if (s<>semicmd(1)) then begin
                  done:=TRUE;
                  if (semicmd(3)<>'') then sprint(semicmd(3));
                end;
              end;
          '^','/','\':dochangemenu(done,newmenucmd,c2,cms);
        else  nocmd:=TRUE;
        end;
    'A':case c2 of
          'R':readamsg;
          'W':writeamsg;
        else  nocmd:=TRUE;
        end;

    'B':case c2 of
          '?':batchinfo;
          'C':if (cms='U') then clearubatch else clearbatch;
          'D':batchdl;
          'L':if (cms='U') then listubatchfiles else listbatchfiles;
          'R':if (cms='U') then removeubatchfiles else removebatchfiles;
          'U':batchul;
        else  nocmd:=TRUE;
        end;

    'D':case c2 of
          'C','D','G','S','W','-','R','Z':dodoorfunc(c2,cms);
        else  nocmd:=TRUE;
        end;


    'F':case c2 of { file.mnu }
          'A':fbasechange(done,cms);

          'D':if (numbatchfiles<>0) then batchdl else idl;

          'F':begin
                last_menu2 := curmenu;
                searchd; { Search for Files }
                curmenu := last_menu2;
                newmenutoload := true;
              end;

          'I':listopts;

          'L':begin
                last_menu2 := curmenu;
                listfiles;
                curmenu := last_menu2;
                newmenutoload := true;
              end;

 	  'N':begin
 	        last_menu2 := curmenu;
 	        nf(cms);
 	        curmenu := last_menu2;
                newmenutoload := true;
              end;

          'P':pointdate;
          'S':begin
                last_menu2 := curmenu;
                search; {searches for file matching the *.* or whatever}
                curmenu := last_menu2;
                newmenutoload := true;
              end;                               
                
          'U':batchul;  {upload}
          'V':lfii;     {file view}
          'Y':printf('filestat');
          'Z':setdirs;

          '@':createtempdir;
          '#':begin
	        nl;
	        print('Type The File Area Number at the Menu Prompt to Change to it!');
              end;

        else  nocmd:=TRUE;
        end;

    'H':case c2 of
          'C':if pynq('|LF|LF'+cms) then begin
                cls;
                printf('logoff');
                hangup:=TRUE;
                hungup:=FALSE;
              end;
          'I':hangup:=TRUE;
          'M':begin
                nl; sprint(cms);
                hangup:=TRUE;
              end;
        else  nocmd:=TRUE;
        end;
    'I':case c2 of
          'X':begin
                while (cms[1]=' ') do delete(cms,1,1);
                if (pos(' ',cms)=0) then
                  iplmodule(cms,'')
                else
                  iplmodule(copy(cms,1,pos(' ',cms)-1),
                            copy(cms,pos(' ',cms)+1,length(cms)-pos(' ',cms)));
              end;
        else  nocmd:=TRUE;
        end;
    'L':case c2 of
          '1'..'3':tshuttlelogon:=ord(c2)-48;
          'B':checkbday;
          'L':lotto;
          'O':Oneliners
        else  nocmd:=TRUE;
        end;
    'M':case c2 of
          'A':mbasechange(done,cms);
          'E':SendMailMenuCmd(cms);
          {'K':purgepriv;}
          'L':MassMail(cms);
          'M':ScanForYourMail;
          'N':nscan(cms);
          {'O':somail;}
          'P':begin
                post(0,'','',0);
              end;
          'S':scanmessages(cms);
          'Q':MakeQWK;
          'R':TossREP;
          'Z':ConfigZScan;
          '#':begin
                nl;
                print('Enter the number of the message base to change to it.');
              end;
        else  nocmd:=TRUE;
        end;
    'N':case c2 of
          'L':if cms<>'' then begin
                thisnode.whereuser:=mln(cms,20);
                savenode;
              end;
          'T':telec_run;
          'W':whoonline;
        else  nocmd:=TRUE;
        end;
    'O':case c2 of
          'B':abbs(cms);
          'C':reqchat(cms);
          'D':wantlist;
          'F':change_arflags(cms);
          'G':callerlog;
          'I':fullscr_verline;
          'J':confchange(cms);
          'M':mmacro;
          'N':nuvvote;
          'O':sysopstatus;
          'P':begin cstuff(value(cms),2,thisuser); saveuf; end;
          'R':Addrumor;
          'U':Ulist;
          'V':vote;
          'X':showpcrstat;
          '$':TimeBank(cms);
          '0':listrumors;
          '%':change_credits(cms);
{         '#':newcolorset(cms); }
        else  nocmd:=TRUE;
        end;
    '*':case c2 of
          'B':if (checkpw) then begin
                sysoplog('[Sysop] Message base editor');
                boardedit;
              end;
          'C':if (checkpw) then chuser;


          'D':if (checkpw) then begin
                sysoplog('[Sysop] Entered Mini-DOS');
                minidos;
              end;

          'E':if (checkpw) then begin
                sysoplog('[Sysop] Event editor');
                eventedit;
              end;
          'F':if (checkpw) then begin
                sysoplog('[Sysop] File base editor');
                dlboardedit;
              end;
          'V':if (checkpw) then begin
                sysoplog('[Sysop] Voting booth editor');
                initvotes;
              end;
          'L':if (checkpw) then showlogs;
          'N':if (checkpw) then tedit1;
          'P':if (checkpw) then begin
                sysoplog('[Sysop] System configuration');
                if (peopleon) then
                begin
                  nl;
                  print('Note: It is not recommended that any system information be modified');
                  print('while other nodes are active.  While it is true that ILLUSION.CFG is');
                  print('reread occasionally for multinode support, it is not reread often');
                  print('enough to ensure proper updates.  Having nodes using different settings');
                  print('may cause adverse effects.');
                  nl;
                  pausescr;
                end;
                changestuff;
              end;
          'U':if (checkpw) then begin
                sysoplog('[Sysop] User editor');
                if (peopleon) then
                begin
                  nl;
                  print('Note: It may not be wise to change the information and/or statistics');
                  print('of users that are presently on the BBS.  Modifications may not be');
                  print('reloaded by other nodes and may be overwritten with old information');
                  print('when the user logs off.');
                  nl;
                  pausescr;
                end;
                uedit1;
              end;
          'Z':begin
                sysoplog('[Sysop] Viewed history log');
                zlog;
              end;

	  'G':begin
	        sysoplog('[Sysop] Verbose Editor');  resetverbose(-1);
	      end;
          '1':begin
                sysoplog('[Sysop] File Manager'); editfiles(-1);
              end;
          '2':sort;
          '4':if (cms='') then do_unlisted_download
                else unlisted_download(cms);
          '3':begin          
                last_menu2 := curmenu;
                menup_edit; { filep menu editor }
	        curmenu := last_menu2;
                newmenutoload := true;
              end;              
          '6':if (checkpw) then uploadall;
          '7':validatefiles;
          '8':addgifspecs;


          {'9':packmessagebases;} {-M-}
          '#':if (checkpw) then begin
                sysoplog('[Sysop] Menu editor');
                last_menu:=curmenu;
                menu_edit;
                first_time:=TRUE;
                curmenu:=last_menu;
                readin2;
              end;
          '$':dirf(TRUE);
          '%':dirf(FALSE);
        else  nocmd:=TRUE;

        end;
  else
        nocmd:=TRUE;
  end;
  if nocmd=TRUE then lastcommandgood:=FALSE else lastcommandgood:=TRUE;
  if (lastcommandovr) then lastcommandgood:=FALSE;
  if (nocmd) then
    if (cso) then
    begin
      sysoplog('***Normal Menu System*** ');
      sysoplog('Invalid command   : Cmdkeys "'+cmd+'"');
      nl; print('Invalid command: Cmdkeys "'+cmd+'"');
    end;
  if (newmenutoload) then
  begin
    readin2;
    lastcommandgood:=FALSE;
    if (newmenucmd='') then begin
      i:=1;
      while ((i<=noc) and (newmenucmd='')) do begin
        if (cmdr[i].ckeys='FIRSTCMD') then
          if (aacs(cmdr[i].acs)) then newmenucmd:='FIRSTCMD';
        inc(i);
      end;
    end;
  end;
end;

end.
