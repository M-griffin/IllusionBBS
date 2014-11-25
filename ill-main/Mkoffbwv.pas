Unit MKOffBwv;       {BlueWave Offline mail Object}

{$I MKB.Def}

{
     MKOffBwv - Copyright 1993 by Mark May - MK Software
     You are free to use this code in your programs, however
     it may not be included in Source/TPU function libraries
     without my permission.

     Mythical Kingom Tech BBS (513)237-7737 HST/v32
     FidoNet: 1:110/290
     Rime: ->MYTHKING
     You may also reach me at maym@dmapub.dma.org
}


Interface

Uses MKGlobT, MKMsgAbs, MKOffAbs,
{$IFDEF WINDOWS}
  WinDos;
{$ELSE}
  Dos;
{$ENDIF}


Type BWFileName = Array[1..13] of Char;


Type BWWordType = Array[1..21] of Char;


Type BWMacroType = Array[1..80] of Char;


Type BWInfHdrType = Record
  Version: Byte;
  RdrFiles: Array[1..5] of BWFileName;
  RegNum: Array[1..9] of Char;
  PackType: Byte;
  Name: Array[1..43] of Char;
  Alias: Array[1..43] of Char;
  Pwd: Array[1..21] of Char;
  PwdType: Byte;
  Addr: AddrType;
  Sysop: Array[1..41] of Char;
  Rsvd1: Array[1..2] of Char;
  SystemName: Array[1..65] of Char;
  MaxFreq: Byte;
  Rsvd2: Array[1..6] of Char;
  UFlags: Word;
  Keywords: Array[1..10] of BWWordType;
  Filters: Array[1..10] of BWWordType;
  Macros: Array[1..3] of BWMacroType;
  NMFlags: Word;
  NMCredit: Word;
  NMDebit: Word;
  CanForward: Boolean;
  InfHdrLen: Word;
  InfAreaLen: Word;
  MixLen: Word;
  FTILen: Word;
  Rsvd3: Array[1..246] of Char;
  End;


Const
  UFlagHotKey =     $0001;
  UFlagExpert =     $0002;
  UFlagGraphics =   $0004;


Const
  NMFlagCrash =     $0001;
  NMFlagAttach =    $0010;
  NMFlagKill =      $0080;
  NMFlagHold =      $0200;
  NMFlagImm =       $0400;
  NMFlagFreq =      $0800;
  NMFlagDir =       $1000;


Type BWInfAreaType = Record
  AreaNum: Array[1..6] of Char;
  EchoTag: Array[1..21] of Char;
  Title: Array[1..50] of Char;
  AreaFlags: Word;
  Rsvd: Byte;
  End;


Const
  AFlagScan =       $0001;
  AFlagAlias =      $0002;
  AFlagAnon =       $0004;
  AFlagNonLoc =     $0008;
  AFlagNetMail =    $0010;
  AFlagPost =       $0020;
  AFlagNoPriv =     $0040;
  AFlagNoPubl =     $0080;


Type BWMixType = Record
  AreaNum: Array[1..6] of Char;
  TotMsgs: Word;
  NumPers: Word;
  MsgHdrPtr: LongInt;
  End;


Type BWFTIType = Record
  MsgFrom: Array[1..36] of Char;
  MsgTo: Array[1..36] of Char;
  MsgSubj: Array[1..72] of Char;
  MsgDate: Array[1..20] of Char;
  MsgNum: Word;
  Refer: Word;
  SeeAlso: Word;
  MsgPtr: LongInt;
  MsgLen: LongInt;
  MFlags: Word;
  OrigZone: Word;
  OrigNet: Word;
  OrigNode: Word;
  End;


Const MaxFTI = 50;

Type FTIArrayType = Array[1..MaxFTI] of BWFTIType;


Const
  MFlagPriv =       $0001;
  MFlagCrash =      $0002;
  MFlagRcvd =       $0004;
  MFlagSent =       $0008;
  MFlagAttach =     $0010;
  MFlagFwd =        $0020;
  MFlagOrphan =     $0040;
  MFlagKill =       $0080;
  MFlagLocal =      $0100;
  MFlagHold =       $0200;
  MFlagImm =        $0400;
  MFlagFreq =       $0800;
  MFlagDir =        $1000;
  MFlagURq =        $8000;


Type BlueWaveInfoType = Record
  MsgPath: String;
  MFile: File;
  MixFile: File Of BWMixType;
  MsgsPerArea: Word;
  PersPerArea: Word;
  CurrArea: Word;
  StartPos: LongInt;
  FTI: FTIArrayType;
  FTIFile: File;
  CurrFTI: Word;
  BBSid: String[8];
  End;


Type BwvOffObj = Object(AbsOffObj)
  BI: ^BlueWaveInfoType;
  Constructor Init; {Initialize}
  Destructor Done; Virtual; {Done}
  Procedure SetPath(MP: String); Virtual; {Set msg path/other info}
  Procedure SetBBSID(ID: String); Virtual;
  Function  StartPacket: Word; Virtual; {Do Packet startup tasks}
  Function  ClosePacket: Word; Virtual; {Do Packet finish tasks}
  Function  AddMsg(Var Msg: AbsMsgObj; Area: Word; ToYou: Boolean): Boolean; Virtual;
  Function  GetArchiveName(Packer: Word): String; Virtual;
  Procedure DoMix;
  Procedure DoInf;
  Procedure WriteFTI;
  End;


Type BwvOffPtr = ^BwvOffObj;


Implementation


Uses MKString, MKFile, MKCfgAbs;


Constructor BwvOffObj.Init;
  Begin
  New(BI);
  BI^.CurrArea := $ffff;
  BI^.StartPos := 0;
  End;


Destructor BwvOffObj.Done;
  Begin
  Dispose(BI);
  End;


Procedure BwvOffObj.SetPath(MP: String);
  Begin
  BI^.MsgPath := WithBackSlash(MP);
  End;


Function BwvOffObj.StartPacket: Word;
  Begin
  Assign(BI^.MixFile, BI^.MsgPath + BI^.BBSID + '.MIX');
  ReWrite(BI^.MixFile);
  Assign(BI^.MFile, BI^.MsgPath + BI^.BBSID + '.DAT');
  ReWrite(BI^.MFile, 1);
  BI^.MsgsPerArea := 0;
  BI^.PersPerArea := 0;
  BI^.CurrArea := $ffff;
  Assign(BI^.FTIFile, BI^.MsgPath + BI^.BBSID + '.FTI');
  ReWrite(BI^.FTIFile, SizeOf(BWFTIType));
  BI^.CurrFTI := 0;
  StartPacket := IoResult;
  End;


Procedure BwvOffObj.WriteFTI;
  Begin
  If BI^.CurrFTI > 0 Then
    Begin
    BlockWrite(BI^.FTIFile, BI^.FTI, BI^.CurrFTI);
    BI^.CurrFTI := 0;
    End;
  End;



Function BwvOffObj.ClosePacket: Word;
  Begin
  DoMix;
  DoInf;
  WriteFTI;
  Close(BI^.MFile);
  If IoResult <> 0 Then;
  Close(BI^.MixFile);
  If IoResult <> 0 Then;
  Close(BI^.FTIFile);
  ClosePacket := IoResult;
  End;


Procedure BwvOffObj.DoMix;
  Var
    MixRec: BWMixType;
    TmpStr: String;
    i: Word;

  Begin
  If BI^.CurrArea <> $ffff Then
    Begin
    FillChar(MixRec, SizeOf(MixRec), #0);
    TmpStr := Long2Str(BI^.CurrArea);
    For i := 1 to Length(TmpStr) Do
      MixRec.AreaNum[i] := TmpStr[i];
    MixRec.TotMsgs := BI^.MsgsPerArea;
    MixRec.NumPers := BI^.PersPerArea;
    MixRec.MsgHdrPtr := BI^.StartPos;
    Write(BI^.MixFile, MixRec);
    If IoResult <> 0 Then;
    End;
  End;


Procedure BwvOffObj.DoInf;
  Type BWInfAreaArray = Array[1..500] of BwInfAreaType;

  Var
    Inf: ^BwInfHdrType;
    Area: ^BWInfAreaArray;
    NumAreas: Word;
    CurrArea: Word;
    i: Word;
    TmpStr: String;
    IFile: File;
    Sec: SecType;
    RSec: SecType;
    WriteSize: LongInt;

  Begin
  New(Inf);
  FillChar(Inf^, SizeOf(Inf^), #0);
  Inf^.Version := 2;
  TmpStr := User^.GetUserName + #0;
  Move(TmpStr[1], Inf^.Name, Length(TmpStr));
  TmpStr := User^.GetUserHandle + #0;
  Move(TmpStr[1], Inf^.Alias, Length(TmpStr));
  Config^.GetAddr(1, Inf^.Addr);
  TmpStr := Config^.GetSysopName + #0;
  Move(TmpStr[1], Inf^.Sysop, Length(TmpStr));
  TmpStr := Copy(Config^.GetBBSName,1,64);
  Move(TmpStr[1], Inf^.SystemName, Length(TmpStr));
  Inf^.MaxFreq := 10;
  Inf^.NMCredit := User^.GetUserCredit;
  Inf^.NMDebit := User^.GetUserPending;
  Inf^.CanForward := False;
  Inf^.InfHdrLen := SizeOf(BWInfHdrType);
  Inf^.InfAreaLen := SizeOf(BWInfAreaType);
  Inf^.MixLen := SizeOf(BWMixType);
  Inf^.FTILen := SizeOf(BWFTIType);
  User^.GetUserSec(@Sec);
  Config^.GetCrashNMSec(RSec);
  If Access(Sec, RSec) Then
    Inc(Inf^.NMFlags, NMFlagCrash);
  Assign(IFile, BI^.MsgPath + BI^.BBSId + '.INF');
  Rewrite(IFile, 1);
  BlockWrite(IFile, Inf^, SizeOf(Inf^));
  Dispose(Inf);
  New(Area);
  NumAreas := 0;
  FillChar(Area^, SizeOf(Area^), #0);
  For CurrArea := 1 to 500 Do
    Begin
    If Config^.MsgReadAccess(CurrArea, Sec) Then
      Begin
      Inc(NumAreas);
      TmpStr := Long2Str(CurrArea);
      For i := 1 to Length(TmpStr) Do
        Area^[NumAreas].AreaNum[i] := TmpStr[i];
      TmpStr := Config^.GetMsgName(CurrArea);
      For i := 1 to Length(TmpStr) Do
        Area^[NumAreas].Title[i] := TmpStr[i];
      TmpStr := Config^.GetEchoAreaTag(CurrArea);
      For i := 1 to Length(TmpStr) Do
        Area^[NumAreas].EchoTag[i] := TmpStr[i];
{ **
      If User^.GetUserOffline(CurrArea) Then
        Inc(Area^[NumAreas].AreaFlags, AFlagScan);
}
      If Config^.MsgAllowHdl(CurrArea) Then
        Inc(Area^[NumAreas].AreaFlags, AFlagAlias);
      If Config^.MsgAllowAnon(CurrArea) Then
        Inc(Area^[NumAreas].AreaFlags, AFlagAnon);
      If Config^.GetMsgType(CurrArea) <> Normal Then
        Inc(Area^[NumAreas].AreaFlags, AFlagNonLoc);
      If Config^.GetMsgType(CurrArea) = NetMail Then
        Inc(Area^[NumAreas].AreaFlags, AFlagNetMail);
      If Config^.MsgWriteAccess(CurrArea, Sec) Then
        Inc(Area^[NumAreas].AreaFlags, AFlagPost);
      If Not Config^.MsgAllowPriv(CurrArea) Then
        Inc(Area^[NumAreas].AreaFlags, AFlagNoPriv);
      If Not Config^.MsgAllowPubl(CurrArea) Then
        Inc(Area^[NumAreas].AreaFlags, AFlagNoPubl);
      End;
    End;
  WriteSize := NumAreas;
  WriteSize := NumAreas * SizeOf(BWInfAreaType);
  BlockWrite(IFile, Area^, WriteSize);
  Dispose(Area);
  Close(IFile);
  If IoResult <> 0 Then;
  End;


Function BwvOffObj.AddMsg(Var Msg: AbsMsgObj; Area: Word; ToYou: Boolean): Boolean;
  Const MaxTxt = 5000;
  Type MsgTxtArrayType = Array[1..MaxTxt] of Char;

  Var
    TmpStr: String;
    i: Word;
    Addr: AddrType;
    Txt: ^MsgTxtArrayType;
    CurrTxt: Word;
    TotTxt: LongInt;
    Ch: Char;


  Begin
  If (Area <> BI^.CurrArea) Then
    Begin
    DoMix;
    BI^.CurrArea := Area;
    BI^.StartPos := FilePos(BI^.FTIFile) + BI^.CurrFTI;
    BI^.StartPos := BI^.StartPos * SizeOf(BWFTIType);
    BI^.MsgsPerArea := 0;
    BI^.PersPerArea := 0;
    End;
  Inc(BI^.MsgsPerArea);
  If ToYou Then
    Inc(BI^.PersPerArea);
  If BI^.CurrFTI = MaxFTI Then
    WriteFTI;
  Inc(BI^.CurrFTI);
  FillChar(BI^.FTI[BI^.CurrFTI], SizeOf(BWFTIType), #0);
  TmpStr := Msg.GetFrom;
  For i := 1 to Length(TmpStr) Do
  BI^.FTI[BI^.CurrFTI].MsgFrom[i] := TmpStr[i];
  TmpStr := Msg.GetTo;
  For i := 1 to Length(TmpStr) Do
  BI^.FTI[BI^.CurrFTI].MsgTo[i] := TmpStr[i];
  TmpStr := Msg.GetSubj;
  For i := 1 to Length(TmpStr) Do
  BI^.FTI[BI^.CurrFTI].MsgSubj[i] := TmpStr[i];
  TmpStr := ReformatDate(Msg.GetDate, 'YY NNN DD  ') + Copy(Msg.GetTime,1,5) + ':00';
  For i := 1 to Length(TmpStr) Do
  BI^.FTI[BI^.CurrFTI].MsgDate[i] := TmpStr[i];
  BI^.FTI[BI^.CurrFTI].MsgPtr := FilePos(BI^.MFile);
  BI^.FTI[BI^.CurrFTI].MsgNum := Msg.GetMsgNum;
  BI^.FTI[BI^.CurrFTI].Refer := Msg.GetRefer;
  BI^.FTI[BI^.CurrFTI].SeeAlso := Msg.GetSeeAlso;
  Msg.GetOrig(Addr);
  BI^.FTI[BI^.CurrFTI].OrigZone := Addr.Zone;
  BI^.FTI[BI^.CurrFTI].OrigNet := Addr.Net;
  BI^.FTI[BI^.CurrFTI].OrigNode := Addr.Node;
  If Msg.IsPriv Then
    Inc(BI^.FTI[BI^.CurrFTI].MFlags, MFlagPriv);
  If Msg.IsCrash Then
    Inc(BI^.FTI[BI^.CurrFTI].MFlags, MFlagCrash);
  If Msg.IsRcvd Then
    Inc(BI^.FTI[BI^.CurrFTI].MFlags, MFlagRcvd);
  If Msg.IsSent Then
    Inc(BI^.FTI[BI^.CurrFTI].MFlags, MFlagSent);
  If Msg.IsFAttach Then
    Inc(BI^.FTI[BI^.CurrFTI].MFlags, MFlagAttach);
  If Msg.IsKillSent Then
    Inc(BI^.FTI[BI^.CurrFTI].MFlags, MFlagKill);
  If Msg.IsLocal Then
    Inc(BI^.FTI[BI^.CurrFTI].MFlags, MFlagLocal);
  If Msg.IsFileReq Then
    Inc(BI^.FTI[BI^.CurrFTI].MFlags, MFlagFreq);
  New(Txt);
  CurrTxt := 0;
  TotTxt := 0;
  Msg.MsgTxtStartUp;
  Ch := Msg.GetChar;
  While Not Msg.EOM Do
    Begin
    If CurrTxt = MaxTxt Then
      Begin
      BlockWrite(BI^.MFile, Txt^, CurrTxt);
      CurrTxt := 0;
      End;
    Case Ch Of
      #$8d: Ch := #0;
      #$0a: Ch := #0;
      End;
    If Ch <> #0 Then
      Begin
      Inc(CurrTxt);
      Inc(TotTxt);
      Txt^[CurrTxt] := Ch;
      End;
    Ch := Msg.GetChar;
    End;
  If CurrTxt > 0 Then
    Begin
    BlockWrite(BI^.MFile, Txt^, CurrTxt);
    CurrTxt := 0;
    End;
  Dispose(Txt);
  BI^.FTI[BI^.CurrFTI].MsgLen := TotTxt;
  AddMsg := IoResult = 0;
  End;


Function BwvOffObj.GetArchiveName(Packer: Word): String;
  Begin
  GetArchiveName := BI^.BBSID + '.MO1';
  End;


Procedure BWVOffObj.SetBBSid(Id: String);
  Begin
  BI^.BBSId := Id;
  End;


End.
