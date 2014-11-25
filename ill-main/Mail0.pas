(*****************************************************************************)
(* Illusion BBS - Mail functions [0/?]                                       *)
(*****************************************************************************)

Unit Mail0;

{$I MKB.Def}

Interface

Uses CRT, DOS, MkGlobT, MkMsgABS,
     MKMsgJAM, MKMsgHUD, MKMsgFID, MKMsgSQU, MKMsgEZY;

Type

  IllJamMsgObj=Object(JamMsgObj)
  End;

  IllHudMsgObj=Object(HudsonMsgObj)
  End;

  IllFidMsgObj=Object(FidoMsgObj)
  End;

  IllSquMsgObj=Object(SqMsgObj)
  End;

  IllEzyMsgObj=Object(EzyMsgObj)
  End;

  IllJamMsgPtr=^IllJamMsgObj;
  IllHudMsgPtr=^IllHudMsgObj;
  IllFidMsgPtr=^IllFidMsgObj;
  IllSquMsgPtr=^IllSquMsgObj;
  IllEzyMsgPtr=^IllEzyMsgObj;


Function OpenMsgArea(Var Msg: AbsMsgPtr; MsgAreaId: String): Boolean;
Function OpenOrCreateMsgArea(Var Msg: AbsMsgPtr; MsgAreaId: String; MaxMsg: Word; MaxDay: Word): Boolean;
Function CloseMsgArea(Var Msg: AbsMsgPtr): Boolean;
Function InitMsgPtr(Var Msg: AbsMsgPtr; MsgAreaId: String): Boolean;
Function DoneMsgPtr(Var Msg: AbsMsgPtr): Boolean;


Implementation

{ Area ids begin with identifier for msg base type }
{ The following characters are already reserved    }
{   B = PC-Board            }
{   E = Ezycom              }
{   F = Fido *.Msg          }
{   H = Hudson              }
{   I = ISR - msg fossil    }
{   J = JAM                 }
{   M = MK-Merlin           }
{   P = *.PKT               }
{   Q = QWK/REP             }
{   R = Renegade            }
{   S = Squish              }
{   W = Wildcat             }

Function OpenMsgArea(Var Msg: AbsMsgPtr; MsgAreaId: String): Boolean;
  Begin
  If InitMsgPtr(Msg, MsgAreaId) Then
    Begin
    OpenMsgArea := True;
    If Msg^.OpenMsgBase <> 0 Then
      Begin
      OpenMsgArea := False;
      If DoneMsgPtr(Msg) Then;
      End;
    End
  Else
    OpenMsgArea := False;
  End;


Function OpenOrCreateMsgArea(Var Msg: AbsMsgPtr; MsgAreaId: String; MaxMsg: Word; MaxDay: Word): Boolean;
  Begin
  If InitMsgPtr(Msg, MsgAreaId) Then
    Begin
    OpenOrCreateMsgArea := True;
    If Not Msg^.MsgBaseExists Then
      If Not Msg^.CreateMsgBase(MaxMsg, MaxDay) = 0 Then
        OpenOrCreateMsgArea := False;
    If Msg^.OpenMsgBase <> 0 Then
      Begin
      OpenOrCreateMsgArea := False;
      If DoneMsgPtr(Msg) Then;
      End;
    End;
  End;


Function CloseMsgArea(Var Msg: AbsMsgPtr): Boolean;
  Begin
  If Msg <> Nil Then
    Begin
    CloseMsgArea := (Msg^.CloseMsgBase = 0);
    If DoneMsgPtr(Msg) Then;
    End
  Else
    CloseMsgArea := False;
  End;


Function InitMsgPtr(Var Msg: AbsMsgPtr; MsgAreaId: String): Boolean;
  Begin
  Msg := Nil;
  InitMsgPtr := True;
  Case UpCase(MsgAreaId[1]) of
    'H': Msg := New(IllHudMsgPtr, Init);
    'S': Msg := New(IllSquMsgPtr, Init);
    'F': Msg := New(IllFidMsgPtr, Init);
    'E': Msg := New(IllEzyMsgPtr, Init);
    'J': Msg := New(IllJamMsgPtr, Init);
    Else
      InitMsgPtr := False;
    End;
  If Msg <> Nil Then
    Msg^.SetMsgPath(Copy(MsgAreaId, 2, 128));
  End;


Function DoneMsgPtr(Var Msg: AbsMsgPtr): Boolean;
  Begin
  If Msg <> Nil Then
    Dispose(Msg, Done);
  Msg := Nil;
  End;

End.

