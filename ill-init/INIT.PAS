(****************************************************************************)
(*>                                                                        <*)
(*> INIT.PAS - Illusion Bulletin Board System Initialization Program       <*)
(*>                                                                        <*)
(*> by Kyle Oppenheim                                                      <*)
(*>                                                                        <*)
(****************************************************************************)

Program INIT;

{$A-,B-,D-,E-,F+,I+,L-,N-,R-,S-,V-}
{$M 65000,65536,65536}

uses Crt, Dos, Objects, Drivers, Views, Menus, Dialogs,
     MsgBox, App, Initbox, InitMain, InitHelp;

{$L INITIMG}
Procedure InitImg; external;

Var exitsave:pointer;

Type
     TInitApp=Object(TApplication)
       constructor Init;
       function GetPalette:PPalette; virtual;
       procedure InitDeskTop; virtual;
       procedure InitStatusLine; virtual;
       procedure InitMenuBar; virtual;
       procedure HandleEvent(var Event:TEvent); virtual;
       procedure Idle; virtual;
     end;

Procedure errorhandle; { Error handler }
begin
  exitproc:=exitsave;
  if (erroraddr<>nil) then begin
    clrscr;
    textcolor(7); Writeln('[> INIT Runtime Error!  (#'+cstr(exitcode)+')');
    halt(1);
  end;
end;

Function CheckIbbsExist:Boolean;
Begin
  CheckIBBSExist:=exist('ILLUSION.CFG');
end;

(****************************************************************************)
(****************************************************************************)

{--- Background ---}

Type
  PAnsiBackGround = ^TAnsiBackGround;
  TAnsiBackGround = OBJECT (TBackGround)
    BckGrnd : Pointer;
    Constructor Init (Var Bounds : TRect; APattern : Char);
    Procedure Draw; virtual;
  end;

Constructor TAnsiBackGround.Init;
Begin
  TBackGround.Init (Bounds, APattern);
  BckGrnd := @InitImg;
end;

Procedure TAnsiBackGround.Draw;
Begin
  TView.Draw;
  TBackGround.Draw;

  WriteBuf (0,0, 80, 3, BckGrnd^);
end;

Type
  PAnsiDeskTop = ^TAnsiDeskTop;
  TAnsiDeskTop = OBJECT (TDeskTop)
    Procedure InitBackGround; virtual;
  end;

Procedure TAnsiDeskTop.InitBackGround;
var
  R: TRect;
  AB : PAnsiBackGround;
begin
  GetExtent(R);
  New (AB, Init(R, #177));
  BackGround := AB;
end;

{--- Color ---}
function TInitApp.GetPalette: PPalette;
const
  {*
    1:  Desktop
    2-7    (menu colors):
      2:      Normal
      3:      Disabled
      4:      Shortcut
      5:      Selected
      6:      Selected Disabled
      7:      Shortcut Selected
    8-13   (blue window)
    16-21  (window)
    24-29  (gray window)
    33-61  (blue dialog):
      33:     Frame/background
      34:     Frame icons
      35:     Scroll bar page
      36:     Scroll bar icons
      37:     Static text
      38:     Label normal
      39:     Label selected
      40:     Label shortcut
      41:     Button normal
      42:     Button default
      43:     Button selected
      44:     Button disabled
      45:     Button shortcut
      46:     Button shadow
      47:     Cluster normal
      48:     Cluster selected
      49:     Cluster shortcut
      50:     Input normal
      51:     Input selected
      52:     Input arrow
      53:     history button
      54:     History sides
      55:     History bar page
      56:     Histiry bar icons
      57:     List normal
      58:     List focused
      59:     List selected
      60:     List divider
      61:     Information pane
    65-93  (dialog):
    97-125 (graydialog)
  *}

  NewCAppColor =
        #$01#$30#$38#$3F#$17#$18#$1F#$17#$1F#$1D#$31#$31#$17#$71#$1F + {15}
    #$37#$3F#$3A#$13#$13#$3E#$21#$3F#$70#$7F#$7A#$13#$13#$70#$7F#$7E + {31}
    #$70#$3F#$3B#$13#$13#$30#$30#$3F#$3F#$17#$1B#$1F#$18#$1E#$38#$13 + {47}
    #$1B#$1F#$1F#$7F#$1B#$20#$72#$31#$31#$30#$2F#$3E#$31#$13#$38#$00 +
    #$17#$1F#$1A#$71#$71#$1E#$17#$1F#$1E#$20#$2B#$2F#$78#$2E#$10#$30 +
    #$3F#$3E#$70#$2F#$7A#$20#$12#$31#$31#$30#$2F#$3E#$31#$13#$38#$00 +
    #$37#$3F#$3A#$13#$13#$3E#$30#$3F#$3E#$20#$2B#$2F#$78#$2E#$30#$70 +
    #$7F#$7E#$1F#$2F#$1A#$20#$32#$31#$71#$70#$2F#$7E#$71#$13#$38#$00;
  CNewColor = NewCAppColor;
  CNewBlackWhite = CAppBlackWhite;
  CNewMonochrome = CAppMonochrome;
  P: array[apColor..apMonochrome] of string[Length(CNewColor)] =
    (CNewColor, CNewBlackWhite, CNewMonochrome);
begin
  GetPalette := @P[AppPalette];
end;

(****************************************************************************)
(****************************************************************************)

Var InitApp:TInitApp;

Procedure TInitApp.InitDeskTop;
VAR
  AB : PAnsiDeskTop;
  R : TRect;
Begin
  GetExtent(R);
  Inc(R.A.Y);
  Dec(R.B.Y);
  New(AB, Init(R));
  DeskTop := AB;
end;

(****************************************************************************)
(****************************************************************************)
type
  PHintStatusLine=^ThintStatusLine;
  ThintStatusLine=object(Tstatusline)
    Function hint(Ahelpctx:word):string; virtual;
  end;

function THintStatusLine.Hint(AhelpCtx:word):string;
Begin
  case AhelpCtx of
    hcInstall : hint:='New Illusion installation and initialization';
    hcInstall2: hint:='Please wait while Illusion is installed and initialized';
    hcAbout   : hint:='Information about the Illusion Initialization program';
    hcStatus  : hint:='Recreate a bad or corrupt ILLUSION.CFG';
    hcQuit    : hint:='Exit from Illusion Initialization';
    hcRegit1  : hint:='Create an Illusion key file';
    hcRegit2  : hint:='Enter your registration numbers, be careful to enter then correctly!';
    hcC       : hint:='Close this dialog box';
    hcGetPath : hint:='Enter full pathname';
    hcUpgrade : hint:='Upgrade Information from the last version';
    hcSiteapp : hint:='Application for a registration key';
  else
    Hint:='';
  end;
end;

procedure TInitApp.InitStatusLine;
Var R:Trect;
Begin
  Getextent(R);
  R.A.Y:=R.B.Y-1;
  StatusLine:=new(PHintStatusLine, Init(R,
    NewStatusDef(0,$7FFF,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      NewStatusKey('~F2~ Install New System',kbf2,  cmInstall,
      NewStatusKey('~F3~ Register Illusion',kbf3,  cmregit,
      nil))),
    NewStatusDef($8000,$FFFF,
      NewStatusKey('IBBS Init. ',0,cmAbout,
      nil),
    nil))
  ));
end;

procedure TInitApp.InitMenuBar;
Var R:Trect;
Begin
  GetExtent(R);
  R.B.Y:=R.A.Y+1;
  MenuBar:=New(PMenuBar,Init(R, NewMenu(
    NewSubMenu('~ð~',hcNoContext,NewMenu(
      NewItem('~A~bout','',0,cmAbout,hcAbout,
      nil)),
    NewSubMenu('~M~ain',hcNoContext,Newmenu(
      NewItem('~I~nstall new system','F2',kbF2,cmInstall,hcInstall,
      NewItem('~N~ode Management','',0,cmNodeMgr,hcMultiNode,
      NewItem('~A~pply for registration','',0,cmSiteApp,hcSiteApp,
      NewItem('~R~egister Illusion','F3',kbF3,cmRegit,hcRegit1,
      NewLine(
      NewItem('E~x~it','Alt-X',kbAltX,cmQuit,hcQuit,
      nil))))))),
    NewSubMenu('~R~ecreate',hcNoContext,Newmenu(
      NewItem('~!~Illusion.Cfg'   ,'',0,cmStatus  ,hcStatus,
      NewItem('~O~Node    .1  '   ,'',0,cmThisNode,hcThisnode,
      { NewItem('~S~trings  .Dat'   ,'',0,cmString  ,hcString, }
      nil))),
    nil))))
  ));
end;

Procedure TInitApp.Idle;
Begin
  TApplication.Idle;
  if (not checkibbsexist) then begin
      DisableCommands([cmThisnode,{cmString,}cmRegit]);
    end else begin
      EnableCommands([cmStatus,cmThisnode,{cmString,}cmRegit]);
    end;
end;

constructor TInitApp.Init;
var R:Trect;
    I:integer;
    Event:TEvent;
begin
    inherited Init;
    registerObjects;
    registerViews;
    registerMenus;
    registerDialogs;
    registerApp;

    if (not checkibbsexist) then begin
      DisableCommands([cmThisnode,{cmString,}cmRegit]);
    end else begin
      EnableCommands([cmStatus,cmThisnode,{cmString,}cmRegit]);
    end;

    Event.What:=evCommand;
    Event.Command:=cmAbout;
    Event.Infoptr:=nil;
    PutEvent(Event);

    { if (egavgasystem=1) then fadein; }
end;

(****************************************************************************)
(****************************************************************************)

Procedure TInitApp.HandleEvent(Var Event:TEvent);
Var i:integer;
Begin
  Tapplication.handleevent(event);
  If Event.what=evCommand then begin
    case Event.Command of
      cmAbout   : aboutbox;
      cmInstall : install;
      cmNodeMgr : NodeMgr;

      cmStatus  : recreate(1);
      cmThisnode: recreate(2);

      else exit;
    end;
    clearevent(Event);
  end;
end;

PROCEDURE SetTextPointer(PtrTyp, AND_Str, XOR_End : word);
CONST mouseint=$33;
VAR reg:registers;
BEGIN
  Reg.AX := 10;
  Reg.BX := PtrTyp;
  Reg.CX := AND_Str;
  Reg.DX := XOR_End;
  intr(MouseInt, Reg);
END;

Begin
  textcolor(7); textbackground(0);
  writeln('Illusion BBS Initialization '+ver);
  delay(1000);
  fillchar(path,sizeof(path),#0);
  getdir(0,curdir);

  delay(500);

  exitsave:=exitproc;
  exitproc:=@errorhandle;

  settextpointer(0,$08FF,$7000);

  Initapp.init;
  Initapp.run;
  Initapp.done;

  textcolor(7); textbackground(0); clrscr;
  textmode(lastmode);
  writeln('Thank you for using Illusion BBS.');
  halt(0);
end.
