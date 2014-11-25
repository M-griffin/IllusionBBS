(*> INITBOX Unit for INIT program      <*)
(*>                                    <*)
(*> Contains dialogs, help contexts    <*)
(*> and other globals.                 <*)
(*>                                    <*)
(*> by Kyle Oppenheim                  <*)

Unit INITBOX;

{$A-,B-,D-,E-,F+,I+,L-,N-,R-,S-,V-}

Interface

uses
  Crt, Dos, Objects, Drivers, Views, Menus, Dialogs, App, msgbox, memory,
  initmain, inithelp;

{$I rec25.pas}

type
  string128=string[128];

const
  finame:string[12]='FILES300';
  gotpath:array[1..12] of boolean=
    (FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE);

  dbox:pdialog=nil;

  cmInstall =202;  { Install new system }
  cmNodeMgr =203;  { Node Management    }

  cmStatus  =205;  { Recreate ILLUSION.CFG }
  cmThisnode=206;  { Recreate NODE.###     }

  cmAbout   =220;  { About Init }
  cmRegit   =222;  { Registration option }
  cmSiteApp =223;  { Registration Mailer }

var
  systat:systatrec;

Procedure aboutbox;
procedure getpath(i,node:integer; force:boolean);
Procedure recreate(op:byte);

Function EgaVgaSystem:byte;
Function Installinfo:boolean;
Procedure Install;

Function readsystat:boolean;
Procedure nodemgr;


Implementation

Procedure aboutbox;
Var R:Trect;
    Dialog:PDialog;
    Control:Word;
begin
  R.Assign(15,5,65,15);
  Dialog:=New(Pdialog,Init(R,'About INIT'));
  With Dialog^ Do Begin
    HelpCtx:=hcAbout;
    R.Assign(11,2,38,3);
    Insert(New(PStaticText,Init(R,'Illusion BBS Initialization')));
    R.Assign(10,4,39,5);
    Insert(New(PstaticText,Init(R,'For the Illusion BBS software')));
    R.Assign(18,5,33,6);
    Insert(New(PstaticText,Init(R,'Version '+ver)));
    R.assign(5,7,45,9);
    Insert(new(Pbutton,Init(r,'~O~k',cmOK,bfdefault)));
  end;
  Control:=Desktop^.Execview(Dialog);
end;

procedure getpath(i,node:integer; force:boolean);
Var Dialog:PDialog;
    R:Trect;
    Control:Word;
    A:Pview;
    d,s:string;
begin
  if ( gotpath[i] and (not force) ) then exit; { Did we already do this one? }
  if (installdir = '') then installdir := curdir+'\';

  Case i of
    1:begin
        path[1]:=curdir+'\';
        d:='Path to install Illusion to.';
      end;
    2:begin
        path[2]:=installdir+'DATA\';
        d:='Path where data files are stored.';
      end;
    3:begin
        path[3]:=installdir+'TEXT\';
        d:='Path where ANSI, *.MSG, menu help files, etc. are stored.';
      end;
    4:begin
        path[4]:=installdir+'MENUS\';
        d:='Path where the menu files are stored.';
      end;
    5:begin
        path[5]:=installdir+'MSGS\JAM';
        d:='Path where JAM format messages are stored.';
      end;
    6:begin
        path[6]:=installdir+'MSGS\HUDSON';
        d:='Path where Hudson format messages are stored.';
      end;
    7:begin
        path[7]:=installdir+'MSGS\SQUISH';
        d:='Path where SQUISH format messages are stored.';
      end;
    8:begin
        path[8]:=installdir+'TRAP\';
        d:='Path where sysop logs, chat traps, etc. are stored.';
      end;
    9:begin
        path[9]:=installdir+'MULTI\';
        d:='Path for temp. multinode files (use RAM drive if possible).';
      end;
   10:begin
        path[10]:=installdir+'IPL\';
        d:='Path for Illusion programming language (IPL) executables.';
      end;
   11:begin
        path[11]:=installdir+'DOOR'+cstr(node)+'\';
        d:='Path for node '+cstr(node)+' door dropfiles (DORINFO1.DEF, etc.).';
      end;
   12:begin
        path[12]:=installdir+'TEMP'+cstr(node)+'\';
        d:='Path for node '+cstr(node)+' temporary work (batch uploads, QWK, etc.).';
      end;

  end; {case}

  repeat
  R.assign(5,6,75,16);
  Dialog:=new(Pdialog, Init(R,'Directory Paths'));
    with Dialog^ do begin
      Helpctx:=hcgetpath;
      R.assign(2,2,65,3);
      Insert(new(PstaticText,Init(R,d)));
      R.Assign(2,5,64,6);
      A:=New(PInputLine,Init(R,60));
      Insert(A);
      R.Assign(1,4,11,5);
      Insert(new(Plabel,Init(R,'~P~athname:',A)));
      R.Assign(5,7,15,9);
      Insert(new(Pbutton,Init(R,'~O~k',cmOk,bfdefault)));
      S:=path[i];
      Setdata(S);
      Selectnext(False);
    end;
    Control:=Desktop^.Execview(Dialog);
    If control<>cmCancel then begin
      Dialog^.GetData(S);
      path[i]:=S;
      if (copy(path[i],length(path[i]),1)<>'\') then path[i]:=path[i]+'\';
      path[i]:=allcaps(path[i]);
      if (i=1) then installdir:=path[i];
      gotpath[i]:=TRUE;
      exit;
    end;
    until 1=0;
end;

procedure getnode(var i:byte);
Var Dialog:PDialog;
    R:Trect;
    Control:Word;
    A:Pview;
    s:string;
begin
  repeat
    R.assign(15,7,65,13);
    Dialog:=new(Pdialog, Init(R,'Select Node'));
    with Dialog^ do begin
      Helpctx:=hcNoContext;
      R.Assign(2,3,7,4);
      A:=New(PInputLine,Init(R,3));
      Insert(A);
      R.Assign(1,2,15,3);
      Insert(new(Plabel,Init(R,'Which ~N~ode?',A)));
      R.Assign(5,7,15,9);
      Insert(new(Pbutton,Init(R,'~O~k',cmOk,bfdefault)));
      S:='';
      Setdata(S);
      Selectnext(False);
    end;

    Control:=Desktop^.Execview(Dialog);
    If control<>cmCancel then begin
      Dialog^.GetData(S);
      i:=value(S);
      if i>0 then exit;
    end;
  until 1=0;
end;

Procedure recreate(op:byte);
Var R:Trect;
    C:word;
    i:byte;
begin
  R.Assign(10,7,70,14);
  C:=MessageBoxRect(R,'All previous information may be lost!  Continue?'
                ,nil,mfConfirmation+mfYesButton+mfNoButton);

  if c=cmYes then begin
    case op of
      1:begin
          for i:=2 to 10 do getpath(i,1,TRUE);
          make_status_dat;
        end;
      2:begin
          getnode(i);
          getpath(11,i,TRUE);
          getpath(12,i,TRUE);
          make_modem_dat(i);
        end;
    end;
    R.Assign(12,6,68,15);
    MessageBoxRect(R,'A new file has been recreated with the default'+#13+
                     'settings in the current directory  You may'+#13+
                     'need to move it to its proper directory.'
                     ,nil,mfInformation+mfokbutton);
  end;
end;

Function installinfo:boolean;
Var C:word;
    R:Trect;
begin
  Installinfo:=FALSE;

  getpath(1,1,TRUE);

  R.Assign(15,5,65,16);
  C:=Messageboxrect(R,
     ^C'INIT will now install Illusion in:'#13+
     ^C+allcaps(installdir)+#13+
     #13^C'Continue?',
     nil,mfConfirmation+mfYesButton+mfNoButton);

  if C=cmyes then installinfo:=TRUE;
end;


procedure Shell(s:string);
begin
  DoneSysError;
  DoneEvents;
  DoneVideo;
  DoneDosMem;
  SwapVectors;
  Exec(GetEnv('COMSPEC'),'/c'+s);
  SwapVectors;
  InitDosMem;
  InitVideo;
  InitEvents;
  InitSysError;
  Application^.Redraw;
end;

procedure RunPk(s:string);
begin
  Shell('Echo Y|'+finame+' -n '+s);
end;

procedure dobox(s:string);
Var R:Trect;
Begin
  R.Assign(20,6,60,15);
  Dbox:=New(PDialog,Init(R,'Installing'));
  With Dbox^ do begin
    helpctx:=hcinstall2;
    R.Assign(2,2,15,3);
    Insert(new(Pstatictext,Init(R,'Installing...')));
    R.assign(2,4,20,5);
    Insert(new(PstaticText,Init(R,'Current operation:')));
    R.Assign(4,5,35,6);
    Insert(new(PstaticText,Init(R,s)));
  end;
  Desktop^.Insert(Dbox);
end;

Procedure Killbox;
begin
  Desktop^.Delete(Dbox);
  If Dbox<>nil then begin
    Dispose(Dbox,done);
    Dbox:=nil;
  end;
end;

procedure errorbox;
Var R:Trect;
begin
  R.Assign(15,5,65,18);
  Messageboxrect(R,
    ^C'Installation Aborted!'+#13#13+
      'An error has occurred during installation.'+#13+
      'Correct the problem, and run INIT again.'+#13+
      'If you continue to have problems, contact'+#13+
      'an alpha or beta site.',
      nil,mferror+mfokbutton);
end;

Function EGAVGASystem: byte;
var  Regs : registers;
begin
    EGAVGASystem:=0;
    with Regs do
    begin
        Ax := $1C00;
        Cx := 7;
        Intr($10,Regs);
        If Al = $1C then  {VGA}
        begin
            EGAVGASystem :=1;
            exit;
        end;
        Ax := $1200;
        Bl := $32;
        Intr($10,Regs);
        If Al = $12 then {MCGA}
        begin
            EGAVGASystem :=2;
            exit;
        end;
        Ah := $12;
        Bl := $10;
        Cx := $FFFF;
        Intr($10,Regs);
        If Cx<>$FFFF then begin
          EGAVGASystem := 3;  {EGA}
          exit;
        end;
   end; {with}
end;

Procedure Install;
Var R:Trect;
    i:integer;
    C:word;
    b:boolean;
    s1,s2:string;
Begin
  if installinfo then begin

    R.Assign(12,5,68,15);
    Messageboxrect(R,
      'First you must enter the directory paths Illusion'+#13+
      'will use to store its data files.  Defaults will'+#13+
      'be suggested, but you may choose any name you want.',
      nil,mfInformation+mfOkButton);

    for i:=2 to 12 do getpath(i,1,TRUE);

    R.Assign(5,5,75,16);
    C:=Messageboxrect(R,
      'INIT will now install Illusion on your system.  Make sure the'+#13+
      finame+'.EXE is in the current directory.  If everything is'+#13+
      'ready, select "Ok", otherwise select "Cancel".',
      nil,mfconfirmation+mfOkButton+mfCancelButton);
    if C=cmCancel then exit;

    if exist(curdir+'\'+finame+'.EXE') then b:=TRUE else b:=FALSE;
    if (not b) then begin
      R.Assign(16,7,64,14);
      Messageboxrect(R,^C+finame+'.EXE not found.  Install aborted!',nil,mferror+mfokbutton);
      exit;
    end;

    s1:=fexpand(installdir);
    s2:=fexpand(curdir);
    RemoveEndSlashes(s1);
    RemoveEndSlashes(s2);

    if s1 <> s2 then
      if (not make_path(installdir)) then begin
        errorbox;
        exit;
      end;

    dobox('Copying installation files');
    copyfile1(curdir+'\'+finame+'.EXE',installdir);
    killbox;

    dobox('Creating directories');
    if (not make_paths) then begin
      killbox;
      errorbox;
      exit;
    end;
    delay(1000); killbox;

    dobox('Creating data files');
    make_status_dat;
    make_modem_dat(1);
    delay(1500); killbox;

    dobox('Copying main executables');
    copyfile1('ILLUSION.EXE',installdir);
    copyfile1('ILLUSION.OVR',installdir);
    killbox;

    dobox('Copying documentation');
    copyfiles('*.DOC',installdir);
    copyfiles('*.NEW',installdir);
    copyfiles('*.INC',installdir);
    copyfiles('README.*',installdir);
    copyfiles('NET*.ZIP',installdir);
    killbox;

    ChDir(s1);
    curdir:=s1;

    dobox('Moving data files');
    runpk('PROTOCOL.DAT AUTOMSG.TXT');
    movefile1('PROTOCOL.DAT',path[2]);
    movefile1('AUTOMSG.TXT',path[2]);
    movefile1('NODE.1',path[2]);
    delay(1500); killbox;

    dobox('Moving ansi/text files');
    runpk('*.ANS *.MSG');
    movefiles('*.ANS',path[3]);
    movefiles('*.MSG',path[3]);
    delay(1000); killbox;

    dobox('Moving menu files');
    runpk('*.MNU');
    movefiles('*.MNU',path[4]);
    delay(1500); killbox;

    dobox('Moving IPL files');
    runpk('*.IPS *.IPX');
    movefiles('*.IPS',path[10]);
    movefiles('*.IPX',path[10]);
    delay(1500); killbox;

    dobox('Extracting utilities');
    runpk('*.EXE STRINGS.TXT ACTIONS.TXT');
    delay(1500); killbox;

    R.Assign(5,5,75,16);
    C:=Messageboxrect(R,
      'Illusion''s language definitions (all the configurable strings'+#13+
      'in the BBS) must be compiled before starting Illusion for the'+#13+
      'first time.  Would you like Illusion to compile them now?',
      nil,mfConfirmation+mfYesButton+mfNoButton);
    if C=cmYes then Shell('I_LANG COMPILE STRINGS.TXT');

    R.Assign(5,5,75,16);
    C:=Messageboxrect(R,
      'The teleconference actions must also be compiled before'+#13+
      'Illusion can use them.  Would you like to have Illusion compile'+#13+
      'them now?',
      nil,mfConfirmation+mfYesButton+mfNoButton);
    if C=cmYes then Shell('I_ACTION ACTIONS.TXT');

    R.Assign(5,5,75,16);
    Messageboxrect(R,
      ^C'Installation Complete!'+#13#13+
        'Illusion has been successfully installed and initialized.'+#13+
        'You can now start Illusion by typing "ILLUSION -L" at the DOS'+#13+
        'prompt.  (The -L will start the BBS in local mode.)',
        nil,mfInformation+mfokbutton);

    R.Assign(5,5,75,16);
    Messageboxrect(R,
      'The first time you run Illusion, you will get a lot of'+#13+
      'warning messages about missing files and paths.  Illusion'+#13+
      'will create them when it starts up.  After that, your'+#13+
      'system will be completely initialized.',
      nil,mfinformation+mfokbutton);

    R.Assign(5,5,75,16);
    Messageboxrect(R,
      'Start by going through the editors and configuring all the'+#13+
      'options.  It takes time, and you will probably need some'+#13+
      'help (be sure to read the documentation).',
      nil,mfinformation+mfokbutton);

    R.Assign(5,5,75,16);
    Messageboxrect(R,
      ^C'Thank you for trying Illusion!'+#13+#13+
      'Check the README file for the latest information about this'+#13+
      'version and how to contact us.  If you have any problems,'+#13+
      'please consult the README first.',
      nil,mfInformation+mfokbutton);
    end;
end;

Function readsystat:boolean;
var systatf:file of systatrec;
    R:Trect;
begin
  readsystat:=FALSE;
  assign(systatf,'ILLUSION.CFG');
  {$I-} reset(systatf); {$I+}
  if (ioresult<>0) then begin
    R.assign(20,7,60,14);
    messageboxrect(R,^C'Error reading ILLUSION.CFG.',nil,mfError+mfokbutton);
  end else begin
    read(systatf,systat);
    close(systatf);
    readsystat:=TRUE;
  end;
end;

procedure nodemgr;
const D:pdialog=nil;
var r:trect;
    c:word;
    Dialog:PDialog;

    op1,op2:string;
    fp1,fp2:boolean;
    nf:file of noderec;
    n:noderec;
    i:byte;
    ok:boolean;
    f:file;
begin
  if readsystat then begin
    assign(nf,systat.datapath+'NODES.DAT');
    {$I-} reset(nf); {$I+}
    if ioresult<>0 then begin
      R.assign(20,7,60,14);
      messageboxrect(R,^C'Error reading NODES.DAT.',nil,mfError+mfokbutton);
    end else begin
      i:=0; ok:=TRUE;
      while (i<filesize(nf)) and (ok) do begin
        seek(nf,i); read(nf,n);
        if n.active then ok:=FALSE;
        inc(i);
      end;

      if ok then begin
        R.Assign(10,6,70,15);
        c:=MessageBoxRect(R,'Before changing your multinode setup, make sure'+#13+
                         'all current nodes are inactive.  If everything'+#13+
                         'is ready, select "Ok", otherwise, select "Cancel".'
                         ,nil,mfConfirmation+mfokbutton+mfcancelbutton);
        if c<>cmcancel then ok:=TRUE else ok:=FALSE;
      end else begin
        R.Assign(10,6,70,15);
        Messageboxrect(R,'INIT has determined node '+cstr(i)+' to be active.'+#13+
                         'Please shut down this node.  If it is already'+#13+
                         'inactive, load it and quit to reset the data files.'
                         ,nil,mfInformation+mfokbutton);
        ok:=FALSE;
      end;

      if (not ok) then begin
        close(nf);
        exit;
      end;

      R.Assign(15,7,65,16);
      Dialog:=New(Pdialog,Init(R,'Node Management'));
      With Dialog^ Do Begin
        HelpCtx:=hcMultiNode;
        R.assign(5,2,45,4);
        Insert(new(Pbutton,Init(r,'~A~dd Node',cmYes,bfNormal)));
        R.assign(5,4,45,6);
        Insert(new(Pbutton,Init(r,'~D~elete Node',cmNo,bfNormal)));
        R.assign(5,6,45,8);
        Insert(new(Pbutton,Init(r,'~C~ancel',cmCancel,bfdefault)));
      end;
      C:=Desktop^.Execview(Dialog);

      if c<>cmcancel then begin

        {create box}
        R.assign(5,18,75,21);
        D:=New(PDialog,Init(R,'Node Management'));
        With D^ do begin
          helpctx:=hcMultiNode;
          R.Assign(2,1,69,2);
          case c of
            cmYes:Insert(new(Pstatictext,Init(R,^C'Adding Node #'+cstr(filesize(nf)+1))));
            cmNo :Insert(new(Pstatictext,Init(R,^C'Delete Node')));
          end;
        end;
        Desktop^.Insert(D);

        case c of
          cmYes:begin
                  { Get paths }
                  op1:=path[6];
                  op2:=path[8];
                  fp1:=gotpath[6];
                  fp2:=gotpath[8];
                  gotpath[6]:=FALSE;
                  gotpath[8]:=FALSE;
                  getpath(6,filesize(nf)+1,TRUE);
                  getpath(8,filesize(nf)+1,TRUE);
                  ok:=FALSE;
                  if (make_path(path[6])) then
                    if (make_path(path[6]+'ARCHIVE\')) then
                      if (make_path(path[6]+'UPLOAD\')) then
                        if (make_path(path[6]+'ARCFUNC\')) then
                          if (make_path(path[6]+'QWK\')) then
                            if (make_path(path[8])) then
                              ok:=TRUE;

                  if ok then begin
                    make_modem_dat(filesize(nf)+1);
                    movefile1('NODE.'+cstr(filesize(nf)+1),systat.datapath);
                  end;

                  {restore old paths}
                  path[6]:=op1;
                  path[8]:=op2;
                  gotpath[6]:=fp1;
                  gotpath[8]:=fp2;

                  if ok then begin
                    seek(nf,filesize(nf));
                    with n do begin
                      active:=FALSE;
                      username:='';
                      unum:=0;
                      whereuser:='Node Offline';
                    end;
                    write(nf,n);

                    R.Assign(25,7,55,14);
                    Messageboxrect(R,
                      ^C'Node added.',nil,mfinformation+mfokbutton);
                  end;

                  close(nf);

               end; {if cmyes/add}
          cmNo:begin
                 if filesize(nf)>1 then begin
                   getnode(i);
                   {$I-} reset(nf); {$I+}
                   if (ioresult=0) then begin
                     if i>filesize(nf) then begin
                       R.Assign(16,7,64,14);
                       messageboxrect(R,^C'There is no such node!',nil,mferror+mfokbutton);
                       ok:=FALSE;
                     end else ok:=TRUE;

                     if ok then begin
                       seek(nf,filesize(nf)-1);
                       truncate(nf);

                       assign(f,systat.datapath+'NODE.'+cstr(i));
                       {$I-} erase(f); {$I+}
                       inc(i);
                       while exist(systat.datapath+'NODE.'+cstr(i)) do begin
                         assign(f,systat.datapath+'NODE.'+cstr(i));
                         rename(f,systat.datapath+'NODE.'+cstr(i-1));
                         inc(i);
                       end;

                       R.Assign(15,6,65,15);
                       Messageboxrect(R,
                         'NODES.DAT updated and NODE.* names shifted.'+#13+
                         'The old temp and door directories have not'+#13+
                         'been removed.  You can remove them now if'+#13+
                         'you wish.',nil,mfinformation+mfokbutton);

                     end; {if ok}
                   end;
                 end else begin
                   R.Assign(16,7,64,14);
                   messageboxrect(R,^C'There are no nodes to delete.',nil,mferror+mfokbutton);
                 end;
                 close(nf);
               end; {if cmno/del}
        end; {case c of}

        {remove box}
        Desktop^.Delete(D);
        If D<>nil then begin
          Dispose(D,done);
          D:=nil;
        end;

      end else {if not cancel}
        close(nf);
    end; {if nodes.dat ok}
  end; {if readsystat}
end; {proc nodemgr}

function tch(s:string):string;
begin
  if (length(s)>2) then
    s:=copy(s,length(s)-1,2)
  else
    if (length(s)=1) then s:='0'+s;
  tch:=s;
end;

function date:string;
var y,m,d:string[3];
    yy,mm,dd,dow:word;
begin
  getdate(yy,mm,dd,dow);
  str(yy-1900,y); str(mm,m); str(dd,d);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
end;

end.
