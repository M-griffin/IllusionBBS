Unit MKOffAbs;       {Abstract Offline mail Object}

{$I MKB.Def}

{
     MKOffAbs - Copyright 1993 by Mark May - MK Software
     You are free to use this code in your programs, however
     it may not be included in Source/TPU function libraries
     without my permission.

     Mythical Kingom Tech BBS (513)237-7737 HST/v32
     FidoNet: 1:110/290
     Rime: ->MYTHKING
     You may also reach me at maym@dmapub.dma.org
}


Interface

Uses Common,
     MKGlobT, MKMsgAbs,
{$IFDEF WINDOWS}
  WinDos;
{$ELSE}
  Dos;
{$ENDIF}


Type AbsOffObj = Object
  Constructor Init; {Initialize}
  Destructor Done; Virtual; {Done}
  Procedure SetPath(MP: String); Virtual; {Set msg path/other info}
  Procedure SetBBSID(ID: String); Virtual; {Set BBS id/filename}
  Function  StartPacket: Word; Virtual; {Do Packet startup tasks}
  Function  ClosePacket: Word; Virtual; {Do Packet finish tasks}
  Function  AddMsg(Var Msg: AbsMsgObj; Area: Word; ToYou: Boolean): Boolean; Virtual;
  Function  GetArchiveName(Packer: Word): String; Virtual;
  Function  GetReplyName: String; Virtual;
  Function  GetExtractSpec: String; Virtual;
  Function CheckPostAccess: Word;
  Procedure ImportPacket; Virtual;
  End;


Type AbsOffPtr = ^AbsOffObj;


Implementation


Constructor AbsOffObj.Init;
  Begin
  End;


Destructor AbsOffObj.Done;
  Begin
  End;


Procedure AbsOffObj.SetPath(MP: String);
  Begin
  End;


Function AbsOffObj.StartPacket: Word;
  Begin
  End;


Function AbsOffObj.ClosePacket: Word;
  Begin
  End;


Function AbsOffObj.AddMsg(Var Msg: AbsMsgObj; Area: Word; ToYou: Boolean): Boolean;
  Begin
  End;


Function AbsOffObj.GetArchiveName(Packer: Word): String;
  Begin
  End;


Function AbsOffObj.GetReplyName: String;
  Begin
  GetReplyName := '';
  End;


Function AbsOffObj.GetExtractSpec: String;
  Begin
  GetExtractSpec := '';
  End;


Function AbsOffObj.CheckPostAccess: Word;
Var
  t: BaseTyp;
  i: word;
  Mtyp:(mtNormal,mtEcho,mtNet);

  Result: Byte;
  Procedure Nope(Code: Word); Begin If (Result = 0) Then Result := Code; End;

Begin
  CheckPostAccess := 73;
  Result := 0;

  If (not aacs(memboard.postacs)) then exit;

  Mtyp:=mtNormal;

  for t:=Public to News do begin
    if t in MemBoard.BaseStat then
      case t of
        Public:begin
                 if ((rPost in ThisUser.ac) or
                     (not aacs(Systat^.NormPubPost))) then
                   Nope(41); {can't post public}

                 if ((ptoday>=Systat^.MaxPubPost) and (not mso)) then
                   Nope(491); {too many msgs today}

                 if (Mtyp=mtNormal) and (Networked in MemBoard.BaseStat) then
                   Mtyp:=mtEcho;
               end;
        Private:begin
                 if ((rEmail in ThisUser.ac) or
                     (not aacs(Systat^.NormPrivPost))) and
                    (not mso) then
                   Nope(95); {you can't send mail}

                 if (etoday>=systat^.MaxPrivPost) and (not mso) then
                   Nope(96); {you send too much email}

                   if (Mtyp=mtNormal) and (Networked in MemBoard.BaseStat) then
                     Mtyp:=mtNet;
                 end;
      end; {case}
  end; {for t}
  CheckPostAccess := Result;
End;

Procedure AbsOffObj.ImportPacket;
  Begin
  End;


Procedure AbsOffObj.SetBBSId(ID: String);
  Begin
  End;


End.
