{ FILEP MENU EDITOR }
{$A+,B+,F+,I+,L+,O+,R-,S-,V-}
unit FilePEd;

interface

uses
   Crt,      Dos,      MRec,     common,   common1,  common2,
   common3,  FilePEd2, Fmenu2,   strproc, Newfile2, NewFile;

procedure menup_edit;

implementation

var menuchanged:boolean;
    filv:file;

function readin:boolean;                    (* read in the menu file curmenu *)
begin
   noc:=0;
   assign(filv,curmenu);
   {$I-} reset(filv,1); {$I+}
   if ioresult<>0 then begin
      print(curmenu+' does not exist.');
      readin:=FALSE;
   end
   else begin
      menuchanged:=FALSE;
      blockread(filv,menur2,sizeof(menur2));
      if fileSize(filv) >= sizeOf(menur2) + sizeOf(cmdr2[noc]) then begin
         repeat
            inc(noc);
            blockread(filv,cmdr2[noc],sizeof(cmdr2[noc]));
         until (eof(filv));
      end;
      close(filv);
      readin:=TRUE;
   end;
end;

procedure menup_edit;
const showcmdtype:integer=0;
      menudata:boolean=FALSE;
var nocsave,i,i1,i2,ii:integer;
    c:char;
    abort:boolean;
    s,scurmenu:astr;

   procedure makenewfile(fn:astr);                 (* make a new command list *)
   var f:file;
       m : menurec2;
       c : commandrec2;
   begin
      assign(f,fn);
      {$I-} rewrite(f,1); {$I+}
      if (ioresult=0) then begin
         with m do begin
            menuname[1] := 'New Menu';
            menuname[2] := '';
            menuname[3] := '';
            directive := '';
            tutorial := '';
            menuprompt := 'Command? ';
            acs := '';
            password := '';
            fallback := systat^.allstartmenu;
            forcehelplevel := 0;
            gencols := 4;
            gcol[1] := 9;
            gcol[2] := 0;
            gcol[3] := 1;
            menuflags := [];
         end;
         with c do begin
            ldesc := '';
            sdesc := '';
            xpoint := '';
            ypoint := '';
            ckeys := '';
            acs := '';
            cmdkeys := '';
            mstring := '';
            commandflags := [];
         end;
         blockwrite(f,m,sizeof(m));
         blockwrite(f,c,sizeof(c));
         close(f);
      end;
   end;

   procedure newcmd(n:integer);                          { new command stuff }
   begin
      with cmdr2[n] do begin
         ldesc:='[N] New Command';
         sdesc:='';
         xpoint:='0';
         ypoint:='0';
         ckeys:='N';
         acs:='';
         cmdkeys:='';
         mstring:='';
         if (pullDown in menur2.menuFlags) then commandFlags := +[pull]
         else commandflags:=[];
      end;
   end;

   procedure moveinto(i1,i2:integer);
   begin
      cmdr2[i1]:=cmdr2[i2];
   end;

   procedure mes;
   var i:integer;
   begin
      rewrite(filv,1);
      blockwrite(filv,menur2,sizeof(menur2));
      for i:=1 to noc do blockwrite(filv,cmdr2[i],sizeof(cmdr2[i]));
      close(filv);
      sysoplog('* Saved menu file: '+scurmenu);
   end;

   procedure med;
   begin
      prompt('Delete menu file: ');
      input(s,8);
      s:=systat^.menupath+allcaps(s)+'.MEN';
      assign(filv,s);
      {$I-} reset(filv,1); {$I+}
      if (ioresult=0) then begin
         close(filv);
         sprint('|NLMenu file: "'+s+'"');
         {changeablemci := 'delete the menu';}
         if pynq('Are You sure? ') then begin
            sysoplog('* Deleted menu file: "'+s+'"');
            erase(filv);
         end;
      end;
   end;

   procedure mei;
   begin
      prompt('Insert menu file: ');
      input(s,8);
      s:=systat^.menupath+allcaps(s)+'.MEN';
      assign(filv,s);
      {$I-} reset(filv,1); {$I+}
      if (ioresult=0) then close(filv)
      else begin
         sysoplog('Inserted new menu file: "'+s+'"');
         makenewfile(s);
      end;
   end;

   procedure mec;
   var str : string;
       ok,
       noSpace : boolean;
   begin
      prompt('Copy menu file from: ');
      input(s,8);
      s:=systat^.menupath+allcaps(s)+'.MEN';
      prompt('Copy menu file to: ');
      input(str,8);
      str := systat^.menupath+allcaps(str)+'.MEN';
      copyFile(ok,noSpace,false,s,str);
   end;

   procedure mem;
   var i,j,k:integer;
       c:char;
       b:byte;
       bb:boolean;

      procedure memd(i:integer);                   (* delete command from list *)
      var x:integer;
      begin
         if (i>=1) and (i<=noc) then begin
            for x:=i+1 to noc do cmdr2[x-1]:=cmdr2[x];
            dec(noc);
         end;
      end;

      procedure memi(i:integer);             (* insert a command into the list *)
      var x:integer;
         s:astr;
      begin
         if (i>=1) and (i<=noc+1) and (noc<50) then begin
            inc(noc);
            if (i<>noc) then for x:=noc downto i do cmdr2[x]:=cmdr2[x-1];
            newcmd(i);
         end;
      end;

      procedure memp;
      var i,j,k:integer;
      begin
         prompt('Move which command? (1-'+cstr(noc)+') : ');
         inu(i);
         if ((not badini) and (i>=1) and (i<=noc)) then begin
            prompt('Move before which command? (1-'+cstr(noc+1)+') : ');
            inu(j);
            if ((not badini) and (j>=1) and (j<=noc+1) and (j<>i) and (j<>i+1)) then begin
               memi(j);
               if j>i then k:=i
               else k:=i+1;
               cmdr2[j]:=cmdr2[k];
               if j>i then memd(i)
               else memd(i+1);
               menuchanged:=TRUE;
            end;
         end;
      end;

      function sfl(b:boolean; c:char):char;
      begin
         if (b) then sfl:=c
         else sfl:='-';
      end;

   begin
      prompt('Modify menu file: ');
      input(s,8);
      assign(filv,systat^.menupath+s+'.MEN');
      {$I-} reset(filv,1); {$I+}
      if ioresult=0 then begin
         close(filv);
         scurmenu:=s;
         curmenu:=systat^.menupath+scurmenu+'.MEN';
         if readin then begin
            menuchanged:=FALSE;
            repeat
               if (c<>'?') then begin
                  cls;
                  abort:=FALSE;
                  if (menudata) then begin
                     sprint('    |WM|wenu filename : |B'+scurmenu);
                     if (not abort) then begin
                        with menur2 do begin
                        sprint('|LF|W[|B1|W] M|wenu titles   : |B'+menuname[1]);
                        sprint('|W[|B2|W] H|welp files    : |B'+
                               aonoff((directive=''),'*Generic*',directive)+' / '+
                               aonoff((tutorial=''),'*Generic*',tutorial));
                        sprompt('|W[|B3|W] P|wrompt        : |B');
                        print(menuprompt);
                        print('('+menuprompt+')');
                        sprint('|W[|B4|W] A|wCS required  : |B"'+acs+'"');
                        sprint('|W[|B5|W] P|wassword      : |B'+
                               aonoff((password=''),'*None*',password));
                        sprint('|W[|B6|W] F|wallback menu : |B'+
                               aonoff((fallback=''),'*None*',fallback));
                        sprint('|W[|B7|W] F|worced ?-level: |B'+
                               aonoff((forcehelplevel=0),'None',cstr(forcehelplevel)));
                        { sprint('|U5[|U08|U5]|U1 Generic info  : '+cstr(gencols)+' cols - '+
                          cstr(gcol[1])+'/'+cstr(gcol[2])+'/'+cstr(gcol[3]));}
                        (*sprint('|W[|w9|W] F|wlags         : |B'+
                               (*
                               sfl((clrscrbefore in menuflags),'C')+
                               sfl((dontcenter in menuflags),'D')+
                               sfl((nomenuprompt in menuflags),'N')+
                               sfl((forcepause in menuflags),'F')+
                               sfl((pulldown in menuflags),'P')+
                               sfl((autotime in menuflags),'T'));
                               *)
                        sprint('|W[|BQ|W] Q|wuit');
                     end;
                  end;
                  end
                  else showcmds(showcmdtype);
               end;
               nl;
               sprompt('|15File Menu Prompt Editing |08[|07?/Help|08]:|03 ');
               onek(c,'ABQDILMPSTX12345679?'^M);
               case c of
                  'A':begin
                     prompt('Enter the Top Left X point (1-80) : ');
                     ini(b);
                     if (not badini) and (b>0) and (b<=80) then begin
                        menur2.menuname[2]:=cstr(b);
                        menuchanged:=TRUE;
                     end;
                  end;
                  'B':begin
                     prompt('Enter the Top Left Y point (1-25) : ');
                     ini(b);
                     if (not badini) and (b>0) and (b<=25) then begin
                        menur2.menuname[3]:=cstr(b);
                        menuchanged:=TRUE;
                     end;
                  end;
                  '?':begin
                     sprompt('|LF|W[|wCR|W] R|wedisplay screen|LF');
                     lcmds(20,3,'Delete command','PMove commands');
                     lcmds(20,3,'Insert command','Toggle display type');
                     lcmds(20,3,'Modify commands','XMenu data/command data');
                     lcmds(20,3,'Quit and save','');
                  end;
                  'D':begin
                     prompt('Delete which command? (1-'+cstr(noc)+') : ');
                     ini(b);
                     if (not badini) and (b>=1) and (b<=noc) then begin
                        memd(b);
                        menuchanged:=TRUE;
                     end;
                  end;
                  'I':if (noc<50) then begin
                     prompt('Insert before which command? (1-'+cstr(noc+1)+') : ');
                     inu(i);
                     if (not badini) and (i>=1) and (i<=noc+1) then begin
                        prompt('Insert how many commands? (1-'+cstr(50-noc)+') [1] : ');
                        inu(j);
                        if (badini) then j:=1;
                        if (j>=1) and (j<=50-noc) then begin
                           for k:=1 to j do memi(i);
                           menuchanged:=TRUE;
                        end;
                     end;
                  end
                  else begin
                     sprint('You already have 50 commands, delete some to make room.|NL');
                     pausescr;
                  end;
                  'M': memm(scurmenu,menuchanged);
                  'P': memp;
                  'T': begin
                     if (showCmdType = 0) then showCmdType := 1
                     else ShowCmdType := 0;
                  end;
                  'X': menudata:=not menudata;
                  '1':begin
                     sprompt('|LF|LFNew menu title: ');
                     inputwnwc(menur2.menuname[1],100,menuchanged);
                  end;
                  '2':begin
                     sprompt('|LF|LF|WNew file displayed for help: ');
                     inputwn(menur2.directive,12,menuchanged);
                     menur2.directive:=allcaps(menur2.directive);
                     sprompt('|LFNew tutorial file? [default ext=".TUT"] : ');
                     inputwn(menur2.tutorial,12,menuchanged);
                     menur2.tutorial:=allcaps(menur2.tutorial);
                     nl;
                  end;
                  '3':begin
                     nl;
                     prompt('New menu prompt: ');
                     inputwnwc(menur2.menuprompt,120,menuchanged);
                  end;
                  '4':begin
                     nl;
                     prompt('New menu ACS: ');
                     inputwn(menur2.acs,20,menuchanged);
                  end;
                  '5':begin
                     nl;
                     prompt('New password: ');
                     inputwn1(menur2.password,15,'u',menuchanged);
                  end;
                  '6':begin
                     nl;
                     prompt('New fallback menu: ');
                     inputwn1(menur2.fallback,8,'u',menuchanged);
                  end;
                  '7':begin
                     nl;
                     prompt('New forced menu help-level (1-3,0=None) ['+
                            cstr(menur2.forcehelplevel)+'] : ');
                     ini(b);
                     if ((not badini) and (b in [0..3])) then begin
                       menuchanged:=TRUE;
                       menur2.forcehelplevel:=b;
                     end;
                  end;
                  {            '8':begin
                  repeat
                    nl;
                    print('C. Generic columns  :'+cstr(menur2.gencols));
                    print('1. Bracket color    :'+cstr(menur2.gcol[1]));
                    print('2. Command color    :'+cstr(menur2.gcol[2]));
                    print('3. Description color:'+cstr(menur2.gcol[3]));
                    print('S. Show menu');
                    nl;
                    prompt('Select (CS,1-3,Q=Quit) : '); onek(c,'QCS123'^M);
                    nl;
                    if (c='S') then genericmenu(2);
                    if (c in ['C','1'..'3']) then begin
                      case c of
                        'C':prompt('New number of generic columns (2-7) ['+
                                cstr(menur2.gencols)+'] : ');
                      else
                            prompt('New generic menu color '+c+' (0-9) ['+
                                cstr(menur2.gcol[ord(c)-48])+'] : ');
                      end;
                      ini(b);
                      if (not badini) then
                        case c of
                          'C':if (b in [2..7]) then begin
                                menuchanged:=TRUE;
                                menur2.gencols:=b;
                              end;
                        else
                              if (b in [0..9]) then begin
                                menuchanged:=TRUE;
                                menur2.gcol[ord(c)-48]:=b;
                              end;
                        end;
                    end;
                  until ((not (c in ['C','S','1'..'3'])) or (hangup));
                  c:=#0;
                end;}
                  '9':begin
                     nl;
                     print('(C)lear screen before menu  -  (D)on''t center the menu titles');
                     print('(N)o menu prompt displayed  -  (F)Force pause before menu display');
                     print('(T)Auto-time display        -  (P)ulldown menu toggle');
                     nl;
                     prompt('Choose : ');
                     onek(c,'QCDFNPT'^M);
                     bb:=menuchanged;
                     menuchanged:=TRUE;
                     (*
                     with menur2 do
                        case c of
                           'C':if (clrscrbefore in menuflags) then menuflags:=menuflags-[clrscrbefore]
                              else menuflags:=menuflags+[clrscrbefore];
                           'D':if (dontcenter in menuflags) then menuflags:=menuflags-[dontcenter]
                              else menuflags:=menuflags+[dontcenter];
                           'N':if (nomenuprompt in menuflags) then menuflags:=menuflags-[nomenuprompt]
                              else menuflags:=menuflags+[nomenuprompt];
                           'F':if (forcepause in menuflags) then menuflags:=menuflags-[forcepause]
                              else menuflags:=menuflags+[forcepause];
                           'P':if (pulldown in menuflags) then menuflags:=menuflags-[pulldown]
                              else menuflags:=menuflags+[pulldown];
                           'T':if (autotime in menuflags) then menuflags:=menuflags-[autotime]
                              else menuflags:=menuflags+[autotime];
                           else menuchanged:=bb;
                        end; *)
                     c:=#0;
                  end;
               end;
            until ((c='Q') or (hangup));
            if (menuchanged) then begin
               sprint('Saving Menu.');
               mes;
            end;
         end;
      end;
   end;

begin
   nocsave:=noc;
   noc:=0;
   repeat
      abort:=FALSE;
      if (c<>'?') then begin
         cls;
         sprint('File Menu Prompt Editing');
         nl;
         dir(systat^.menupath,'*.men',FALSE);
      end;
      sprompt('|LF|WM|wenu Editor |W[|w?\Help|W]: |w');
      onek(c,'CQDIM?'^M);
      case c of
         '?':begin
            sprompt('|LF|W[|wCR|W] R|wedisplay screen|LF');
            lcmds(17,3,'Delete menu file','Insert menu file');
            lcmds(17,3,'Modify menu file','Copy menu file');
            lcmds(17,3,'Quit and save','');
          end;
          'D':med;
          'I':mei;
          'M':mem;
          'C':mec;
      end;
   until (c='Q') or (hangup);
   noc:=nocsave;
end;

end.
