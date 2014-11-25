Unit MKMsgEZY;       {EZYCom Msg Unit}

{$I MKB.Def}
Interface

{
     MKMsgEzy - Copyright 1993 by Mark May - MK Software
     You are free to use this code in your programs, however
     it may not be included in Source/TPU function libraries
     without my permission.

     Mythical Kingom Tech BBS (513)237-7737 HST/v32
     FidoNet: 1:110/290
     Rime: ->MYTHKING
     You may also reach me at maym@dmapub.dma.org
}


Uses MKGlobT, MKMsgAbs,
{$IFDEF WINDOWS}
  Strings, WinDos;
{$ELSE}
  Dos;
{$ENDIF}

Const
  MaxEzMsgAreas = 1024;

Type EZMsgHdrType = Record
  ReplyTo: Word; {Message is reply to this number}
  SeeAlso: Word; {Message has replies}
  TxtStart: LongInt; {Text start position}
  TxtLen: LongInt; {Length of msg text incl nul term}
  DestAddr: AddrType; {Destination address}
  OrigAddr: AddrType; {Origination address}
  Cost: Word; {Message cost}
  MsgAttr: Byte; {Message attribute - see constants}
  NetAttr: Byte; {Netmail attribute - see constants}
  ExtraAttr: Byte; {Future use}
  Date: LongInt; {Date message was written}
  RcvdDate: LongInt; {Date msg received bye MsgTo}
  MsgTo: String[35]; {Message is intended for}
  MsgFrom: String[35]; {Message was written by}
  Subj: String[72]; {Message subject}
  End;


Const                                  {MsgHdr.MsgAttr}
  ezDeleted =       1;                 {Message is deleted}
  ezUnmovedNet =    2;                 {Unexported Netmail message}
  ezRsvAttr =       4;
  ezPriv =          8;                 {Message is private}
  ezRcvd =         16;                 {Message is received}
  ezUnmovedEcho =  32;                 {Unexported Echomail message}
  ezLocal =        64;                 {"Locally" entered message}
  ezNoKill =      128;


Const                                  {MsgHdr.NetAttr}
  ezKillSent =      1;                 {Delete after exporting}
  ezSent =          2;                 {Msg has been sent}
  ezFAttach =       4;                 {Msg has file attached}
  ezCrash =         8;                 {Msg is crash}
  ezFileReq =      16;                 {Msg is a file request}
  ezReqRcpt =      32;                 {Msg is return receipt request}
  ezRetAudit =     64;                 {Msg is a audit request}
  ezRetRcpt =     128;                 {Msg is a return receipt}


Const
  EzMsgLen = 16000;

Type EZMsgType = Record
  MsgHdrFile: File; { MsgH???.BBS }
  MsgTxtFile: File; { MsgT???.BBS }
  MsgTxtWFile: File;
  MsgHdr: EzMsgHdrType;
  TextCtr: LongInt;
  MsgPath: String[128];
  MsgAreaPath: String[128];
  MsgArea: Word;
  Error: Word;
  MsgChars: Array[0..EZMsgLen] of Char;
  MsgDone: Boolean;
  CurrMsg: LongInt;
  SeekOver: Boolean;
  Name: String[35];
  Handle: String[35];
  MailType: MsgMailType;
  Found: Boolean;
  StrDate: String[8];
  StrTime: String[5];
  CRLast: Boolean;
  End;


Type EzyMsgObj = Object (AbsMsgObj)
  EZM: ^EZMsgType;
  Constructor Init; {Initialize}
  Destructor Done; Virtual; {Done}
  Procedure SetMsgPath(St: String); Virtual; {Set netmail path}
  Function  GetHighMsgNum: LongInt; Virtual; {Get highest netmail msg number in area}
  Procedure SetDest(Var Addr: AddrType); Virtual; {Set Zone/Net/Node/Point for Dest}
  Procedure SetOrig(Var Addr: AddrType); Virtual; {Set Zone/Net/Node/Point for Orig}
  Procedure SetFrom(Name: String); Virtual; {Set message from}
  Procedure SetTo(Name: String); Virtual; {Set message to}
  Procedure SetSubj(Str: String); Virtual; {Set message subject}
  Procedure SetCost(SCost: Word); Virtual; {Set message cost}
  Procedure SetRefer(SRefer: LongInt); Virtual; {Set message reference}
  Procedure SetSeeAlso(SAlso: LongInt); Virtual; {Set message see also}
  Procedure SetDate(SDate: String); Virtual; {Set message date}
  Procedure SetTime(STime: String); Virtual; {Set message time}
  Procedure SetLocal(LS: Boolean); Virtual; {Set local status}
  Procedure SetRcvd(RS: Boolean); Virtual; {Set received status}
  Procedure SetPriv(PS: Boolean); Virtual; {Set priveledge vs public status}
  Procedure SetCrash(SS: Boolean); Virtual; {Set crash netmail status}
  Procedure SetKillSent(SS: Boolean); Virtual; {Set kill/sent netmail status}
  Procedure SetSent(SS: Boolean); Virtual; {Set sent netmail status}
  Procedure SetFAttach(SS: Boolean); Virtual; {Set file attach status}
  Procedure SetReqRct(SS: Boolean); Virtual; {Set request receipt status}
  Procedure SetReqAud(SS: Boolean); Virtual; {Set request audit status}
  Procedure SetRetRct(SS: Boolean); Virtual; {Set return receipt status}
  Procedure SetFileReq(SS: Boolean); Virtual; {Set file request status}
  Procedure SetEcho(ES: Boolean); Virtual; {Set echo status}
  Procedure DoString(Str: String); Virtual; {Add string to message text}
  Procedure DoChar(Ch: Char); Virtual; {Add character to message text}
  Procedure DoStringLn(Str: String); Virtual; {Add string and newline to msg text}
  Function  WriteMsg: Word; Virtual;
  Function  GetChar: Char; Virtual;
  Procedure MsgStartUp; Virtual; {set up msg for reading}
  Function  EOM: Boolean; Virtual; {No more msg text}
  Function  WasWrap: Boolean; Virtual; {Last line was soft wrapped no CR}
  Procedure SeekFirst(MsgNum: LongInt); Virtual; {Seek msg number}
  Procedure SeekNext; Virtual; {Find next matching msg}
  Procedure SeekPrior; Virtual; {Seek prior matching msg}
  Function  GetFrom: String; Virtual; {Get from name on current msg}
  Function  GetTo: String; Virtual; {Get to name on current msg}
  Function  GetSubj: String; Virtual; {Get subject on current msg}
  Function  GetCost: Word; Virtual; {Get cost of current msg}
  Function  GetDate: String; Virtual; {Get date of current msg}
  Function  GetTime: String; Virtual; {Get time of current msg}
  Function  GetRefer: LongInt; Virtual; {Get reply to of current msg}
  Function  GetSeeAlso: LongInt; Virtual; {Get see also of current msg}
  Function  GetMsgNum: LongInt; Virtual; {Get message number}
  Procedure GetOrig(Var Addr: AddrType); Virtual; {Get origin address}
  Procedure GetDest(Var Addr: AddrType); Virtual; {Get destination address}
  Function  IsLocal: Boolean; Virtual; {Is current msg local}
  Function  IsCrash: Boolean; Virtual; {Is current msg crash}
  Function  IsKillSent: Boolean; Virtual; {Is current msg kill sent}
  Function  IsSent: Boolean; Virtual; {Is current msg sent}
  Function  IsFAttach: Boolean; Virtual; {Is current msg file attach}
  Function  IsReqRct: Boolean; Virtual; {Is current msg request receipt}
  Function  IsReqAud: Boolean; Virtual; {Is current msg request audit}
  Function  IsRetRct: Boolean; Virtual; {Is current msg a return receipt}
  Function  IsFileReq: Boolean; Virtual; {Is current msg a file request}
  Function  IsRcvd: Boolean; Virtual; {Is current msg received}
  Function  IsPriv: Boolean; Virtual; {Is current msg priviledged/private}
  Function  IsDeleted: Boolean; Virtual; {Is current msg deleted}
  Function  IsEchoed: Boolean; Virtual; {Msg should be echoed}
  Function  GetMsgLoc: LongInt; Virtual; {Msg location}
  Procedure SetMsgLoc(ML: LongInt); Virtual; {Msg location}
  Procedure YoursFirst(Name: String; Handle: String); Virtual; {Seek your mail}
  Procedure YoursNext; Virtual; {Seek next your mail}
  Function  YoursFound: Boolean; Virtual; {Message found}
  Procedure StartNewMsg; Virtual;
  Function  OpenMsgBase: Word; Virtual;
  Function  CloseMsgBase: Word; Virtual;
  Function  CreateMsgBase(MaxMsg: Word; MaxDays: Word): Word; Virtual;
  Function  SeekFound: Boolean; Virtual;
  Procedure SetMailType(MT: MsgMailType); Virtual; {Set message base type}
  Function  GetSubArea: Word; Virtual; {Get sub area number}
  Procedure ReWriteHdr; Virtual; {Rewrite msg header after changes}
  Procedure DeleteMsg; Virtual; {Delete current message}
  Function  NumberOfMsgs: LongInt; Virtual; {Number of messages}
  Function  GetLastRead(UNum: LongInt): LongInt; Virtual; {Get last read for user num}
  Procedure SetLastRead(UNum: LongInt; LR: LongInt); Virtual; {Set last read}
  Procedure MsgTxtStartUp; Virtual; {Do message text start up tasks}
  Function  GetTxtPos: LongInt; Virtual; {Get indicator of msg text position}
  Procedure SetTxtPos(TP: LongInt); Virtual; {Set text position}
  Procedure SetMsgAttr(Mask: Word; St: Boolean); {Set msgattr}
  Procedure SetNetAttr(Mask: Word; St: Boolean); {Set netattr}
  Function  MsgBaseExists: Boolean; Virtual;
  End;


Type EzyMsgPtr = ^EzyMsgObj;

Var
  EzLastPath: String[128];
  EzLastRecSize: Word;


Implementation


Uses MKFile, MKString, MKDos, Crc32;


Constructor EzyMsgObj.Init;
  Begin
  New(Ezm);
  If Ezm = Nil Then
    Begin
    Fail;
    Exit;
    End;
  EZM^.MsgPath := '';
  Ezm^.MsgAreaPath := '';
  EZM^.MsgArea := 0;
  EZM^.TextCtr := 0;
  EZM^.SeekOver := False;
  Ezm^.Error := 0;
  End;


Destructor EzyMsgObj.Done;
  Begin
  Dispose(Ezm);
  End;


Procedure EzyMsgObj.SetMsgPath(St: String);
  Var
    ANum: Word;

  Begin
  EZM^.MsgPath := Copy(St, 5, 110);
  AddBackSlash(EZM^.MsgPath);
  EZM^.MsgArea := Str2Long(Copy(St,1,4));
  ANum := ((EZM^.MsgArea - 1) Div 100) + 1;
  Ezm^.MsgAreaPath := Ezm^.Msgpath + 'AREA' + Long2Str(ANum) +'\';
  End;


Function EzyMsgObj.GetHighMsgNum: LongInt;
  Var
    ANum: Word;

  Begin
  GetHighMsgNum := SizeFile(Ezm^.MsgAreaPath + 'MsgH' +
    PadLeft(Long2Str(Ezm^.MsgArea),'0',3) + '.BBS') Div SizeOf(EzMsgHdrType);
  End;


Procedure EzyMsgObj.SetDest(Var Addr: AddrType);
  Begin
  EZM^.MsgHdr.DestAddr := Addr;
  End;


Procedure EzyMsgObj.SetOrig(Var Addr: AddrType);
  Begin
  EZM^.MsgHdr.OrigAddr := Addr;
  End;


Procedure EzyMsgObj.SetFrom(Name: String);
  Begin
  EZM^.MsgHdr.MsgFrom := Name;
  End;


Procedure EzyMsgObj.SetTo(Name: String);
  Begin
  Ezm^.MsgHdr.MsgTo := Name;
  End;


Procedure EzyMsgObj.SetSubj(Str: String);
  Begin
  Ezm^.MsgHdr.Subj := Str;
  End;


Procedure EzyMsgObj.SetCost(SCost: Word);
  Begin
  Ezm^.MsgHdr.Cost := SCost;
  End;


Procedure EzyMsgObj.SetRefer(SRefer: LongInt);
  Begin
  Ezm^.MsgHdr.ReplyTo := SRefer and $ffff;
  End;


Procedure EzyMsgObj.SetSeeAlso(SAlso: LongInt);
  Begin
  Ezm^.MsgHdr.SeeAlso := SAlso and $ffff;
  End;


Procedure EzyMsgObj.SetDate(SDate: String);
  Begin
  Ezm^.StrDate := SDate;
  End;


Procedure EzyMsgObj.SetTime(STime: String);
  Begin
  Ezm^.StrTime := STime;
  End;


Procedure EzyMsgObj.SetMsgAttr(Mask: Word; St: Boolean); {Set msgattr}
  Begin
  If St Then
    Ezm^.MsgHdr.MsgAttr := Ezm^.MsgHdr.MsgAttr or Mask
  Else
    Ezm^.MsgHdr.MsgAttr := Ezm^.MsgHdr.MsgAttr and (Not Mask);
  End;


Procedure EzyMsgObj.SetNetAttr(Mask: Word; St: Boolean); {Set netattr}
  Begin
  If St Then
    Ezm^.MsgHdr.NetAttr := Ezm^.MsgHdr.NetAttr or Mask
  Else
    Ezm^.MsgHdr.NetAttr := Ezm^.MsgHdr.NetAttr and (not Mask);
  End;


Procedure EzyMsgObj.SetLocal(LS: Boolean);
  Begin
  SetMsgAttr(ezLocal, LS);
  End;


Procedure EzyMsgObj.SetRcvd(RS: Boolean);
  Begin
  SetMsgAttr(ezRcvd, RS);
  End;


Procedure EzyMsgObj.SetPriv(PS: Boolean);
  Begin
  SetMsgAttr(ezPriv, PS);
  End;


Procedure EzyMsgObj.SetCrash(SS: Boolean);
  Begin
  SetNetAttr(ezCrash, SS);
  End;


Procedure EzyMsgObj.SetKillSent(SS: Boolean);
  Begin
  SetNetAttr(ezKillSent, SS);
  End;


Procedure EzyMsgObj.SetSent(SS: Boolean);
  Begin
  SetNetAttr(ezSent, SS);
  End;


Procedure EzyMsgObj.SetFAttach(SS: Boolean);
  Begin
  SetNetAttr(ezFAttach, SS);
  End;


Procedure EzyMsgObj.SetReqRct(SS: Boolean);
  Begin
  SetNetAttr(ezReqRcpt, SS);
  End;


Procedure EzyMsgObj.SetReqAud(SS: Boolean);
  Begin
  End;


Procedure EzyMsgObj.SetRetRct(SS: Boolean);
  Begin
  SetNetAttr(ezRetRcpt, SS);
  End;


Procedure EzyMsgObj.SetFileReq(SS: Boolean);
  Begin
  SetNetAttr(ezFileReq, SS);
  End;


Procedure EzyMsgObj.DoString(Str: String);
  Var
    i: Word;

  Begin
  i := 1;
  While i <= Length(Str) Do
    Begin
    DoChar(Str[i]);
    Inc(i);
    End;
  End;


Procedure EzyMsgObj.DoChar(Ch: Char);
  Begin
  If EZM^.TextCtr < SizeOf(EZM^.MsgChars) Then
    Begin
    Case(Ch) of
      #13: Ezm^.CRLast := True;
      #10:;
      Else
        Ezm^.CRLast := False;
      End;
    EZM^.MsgChars[EZM^.TextCtr] := Ch;
    Inc(EZM^.TextCtr);
    End;
  End;


Procedure EzyMsgObj.DoStringLn(Str: String);
  Begin
  DoString(Str);
  DoChar(#13);
  End;


Function  EzyMsgObj.WriteMsg: Word;

  Type MsgFastAccessType = Record
    CrcTo: LongInt;
    Area: Word;
    MsgNum: Word;
    End;

  Var
    {$IFDEF WINDOWS}
    TmpDT: TDateTime;
    {$ELSE}
    TmpDT: DateTime;
    {$ENDIF}
    MsgFast: MsgFastAccessType; {MsgPath\MsgFast.Bbs}
    MsgFastFile: File;
    MsgExport: Boolean;
    MsgExportFile: File;
    MsgCount: Word;
    MsgCountFile: File;
    i: Word;
    NumRead: Word;

  Begin
  If Not Ezm^.CRLast Then
    DoChar(#13);
  DoChar(#0);
  TmpDT.Year := Str2Long(Copy(Ezm^.StrDate,7,2));
  If TmpDT.Year > 79 Then
    Inc(TmpDT.Year, 1900)
  Else
    Inc(TmpDT.Year, 2000);
  TmpDT.Month := Str2Long(Copy(Ezm^.StrDate,1,2));
  TmpDT.Day := Str2Long(Copy(Ezm^.StrDate,4,2));
  TmpDt.Hour := Str2Long(Copy(Ezm^.StrTime,1,2));
  TmpDt.Min := Str2Long(Copy(Ezm^.StrTime, 4,2));
  TmpDt.Sec := 0;
  PackTime(TmpDT, Ezm^.MsgHdr.Date);
  Ezm^.MsgHdr.RcvdDate := Ezm^.MsgHdr.Date;
  FileMode := fmReadWrite + fmDenyWrite;
  If shReset(Ezm^.MsgTxtWFile, 1) Then
    Begin
    Ezm^.MsgHdr.TxtStart := FileSize(Ezm^.MsgTxtWFile);
    Seek(Ezm^.MsgTxtWFile, Ezm^.MsgHdr.TxtStart);
    Ezm^.Error := IoResult;
    Ezm^.MsgHdr.TxtLen := Ezm^.TextCtr;
    If Ezm^.Error = 0 Then
      Begin
      BlockWrite(Ezm^.MsgTxtWFile, Ezm^.MsgChars, Ezm^.TextCtr);
      Ezm^.Error := IoResult;
      End;
    If Ezm^.Error = 0 Then
      Begin
      Seek(Ezm^.MsgHdrFile, FileSize(Ezm^.MsgHdrFile));
      Ezm^.Error := IoResult;
      End;
    If Ezm^.Error = 0 Then
      Begin
      BlockWrite(Ezm^.MsgHdrFile, Ezm^.MsgHdr, 1);
      Ezm^.Error := IoResult;
      Ezm^.CurrMsg := FileSize(Ezm^.MsgHdrFile);
      End;
    If ((Ezm^.Error = 0) and (Not IsRcvd)) Then
      Begin
      MsgFast.CrcTo := $ffffffff;
      For i := 1 to Length(Ezm^.MsgHdr.MsgTo) Do
        MsgFast.CrcTo := UpDC32(Ord(UpCase(Ezm^.MsgHdr.MsgTo[i])), MsgFast.CrcTo);
      MsgFast.Area := Ezm^.MsgArea;
      MsgFast.MsgNum := Ezm^.CurrMsg;
      Assign(MsgFastFile, Ezm^.MsgPath + 'MsgFast.Bbs');
      FileMode := fmReadWrite + fmDenyNone;
      If shReset(MsgFastFile, SizeOf(MsgFastAccessType)) Then
        Begin
        Seek(MsgFastFile, FileSize(MsgFastFile));
        If IoResult <> 0 Then;
        BlockWrite(MsgFastFile, MsgFast, 1);
        If IoResult <> 0 Then;
        Close(MsgFastFile);
        If IoResult <> 0 Then;
        End;
      End;
    If ((Ezm^.Error = 0) and (IsEchoed)) Then
      Begin
      Assign(MsgExportFile, Ezm^.MsgPath + 'MsgExprt.Bbs');
      FileMode := fmReadWrite + fmDenyNone;
      If shReset(MsgExportFile, SizeOf(MsgExport)) Then
        Begin
        MsgExport := True;
        Seek(MsgExportFile, Ezm^.MsgArea - 1);
        If IoResult <> 0 Then;
        BlockWrite(MsgExportFile, MsgExport, 1);
        If IoResult <> 0 Then;
        Close(MsgExportFile);
        If IoResult <> 0 Then;
        End;
      End;
    If Ezm^.Error = 0 Then
      Begin
      Assign(MsgCountFile, Ezm^.MsgPath + 'MsgCount.Bbs');
      MsgCount := 0;
      If shReset(MsgCountFile, SizeOf(MsgCount)) Then
        Begin
        Seek(MsgCountFile, Ezm^.MsgArea - 1);
        If IoResult <> 0 Then;
        BlockRead(MsgCountFile, MsgCount, 1, NumRead);
        If IoResult <> 0 Then;
        Inc(MsgCount);
        Seek(MsgCountFile, Ezm^.MsgArea - 1);
        If IoResult <> 0 Then;
        BlockWrite(MsgCountFile, MsgCount, 1);
        If IoResult <> 0 Then;
        End;
      End;
    If Ezm^.Error = 0 Then
      Begin
      Close(Ezm^.MsgTxtWFile);
      Ezm^.Error := IoResult;
      End;
    End
  Else
    Ezm^.Error := 5;
  WriteMsg := Ezm^.Error;
  End;


Function EzyMsgObj.GetChar: Char;
  Begin
  If ((EZM^.TextCtr >= EZM^.MsgHdr.TxtLen) Or (EZM^.MsgChars[EZM^.TextCtr] = #0)
  Or(Ezm^.TextCtr >= EzMsgLen)) Then
    Begin
    GetChar := #0;
    EZM^.MsgDone := True;
    End
  Else
    Begin
    GetChar := EZM^.MsgChars[EZM^.TextCtr];
    Inc(EZM^.TextCtr);
    End;
  End;


Procedure EzyMsgObj.MsgStartUp;
  Var
    NumRead: Word;

  Begin
  If (Ezm^.CurrMsg > 0) and (Ezm^.CurrMsg <= FileSize(Ezm^.MsgHdrFile)) Then
    Begin
    LastSoft := False;
    Ezm^.MsgDone := False;
    Seek(Ezm^.MsgHdrFile, Ezm^.CurrMsg - 1);
    Ezm^.Error := IoResult;
    If Ezm^.Error = 0 Then
      Begin
      BlockRead(Ezm^.MsgHdrFile, Ezm^.MsgHdr, 1, NumRead);
      Ezm^.Error := IoResult;
      End;
    End;
  End;


Procedure EzyMsgObj.MsgTxtStartUp;
  Var
    NumRead: Word;

  Begin
  If ((Ezm^.MsgHdr.TxtStart >= 0) and (Ezm^.MsgHdr.TxtStart <=
  FileSize(Ezm^.MsgTxtFile))) Then
    Begin
    Ezm^.Error := 0;
    EZM^.TextCtr := 0;
    EZM^.MsgDone := False;
    FillChar(Ezm^.MsgChars, SizeOf(Ezm^.MsgChars), #0);
    Seek(Ezm^.MsgTxtFile, Ezm^.Msghdr.TxtStart);
    Ezm^.Error := IoResult;
    If Ezm^.Error = 0 Then
      Begin
       If Ezm^.MsgHdr.TxtLen > EzMsgLen Then
        BlockRead(Ezm^.MsgTxtFile, Ezm^.MsgChars, Ezm^.MsgHdr.TxtLen, NumRead)
      Else
        BlockRead(Ezm^.MsgTxtFile, Ezm^.MsgChars, EzMsgLen, NumRead);
      Ezm^.Error := IoResult;
      End;
    LastSoft := False;
    End
  Else
    Begin
    Ezm^.Error := 400;
    End;
  End;


Function EzyMsgObj.EOM: Boolean;
  Begin
  EOM := EZM^.MsgDone;
  End;


Function EzyMsgObj.WasWrap: Boolean;
  Begin
  WasWrap := LastSoft;
  End;


Function EzyMsgObj.GetFrom: String; {Get from name on current msg}
  Begin
  GetFrom := Ezm^.MsgHdr.MsgFrom;
  End;


Function EzyMsgObj.GetTo: String; {Get to name on current msg}
  Begin
  GetTo := Ezm^.MsgHdr.MsgTo;
  End;


Function EzyMsgObj.GetSubj: String; {Get subject on current msg}
  Begin
  GetSubj := Ezm^.MsgHdr.Subj;
  End;


Function EzyMsgObj.GetCost: Word; {Get cost of current msg}
  Begin
  GetCost := Ezm^.MsgHdr.Cost;
  End;


Function EzyMsgObj.GetDate: String; {Get date of current msg}
  Begin
  GetDate := DateStr(Ezm^.MsgHdr.Date);
  End;


Function EzyMsgObj.GetTime: String; {Get time of current msg}
  Begin
  GetTime := Copy(TimeStr(Ezm^.MsgHdr.Date),1, 5);
  End;


Function EzyMsgObj.GetRefer: LongInt; {Get reply to of current msg}
  Begin
  GetRefer := Ezm^.MsgHdr.ReplyTo;
  End;


Function EzyMsgObj.GetSeeAlso: LongInt; {Get see also of current msg}
  Begin
  GetSeeAlso := Ezm^.MsgHdr.SeeAlso;
  End;


Function EzyMsgObj.GetMsgNum: LongInt; {Get message number}
  Begin
  GetMsgNum := EZM^.CurrMsg;
  End;


Procedure EzyMsgObj.GetOrig(Var Addr: AddrType); {Get origin address}
  Begin
  Addr := EZM^.MsgHdr.OrigAddr;
  End;


Procedure EzyMsgObj.GetDest(Var Addr: AddrType); {Get destination address}
  Begin
  Addr := EZM^.MsgHdr.DestAddr;
  End;


Function EzyMsgObj.IsLocal: Boolean; {Is current msg local}
  Begin
  IsLocal := (Ezm^.MsgHdr.MsgAttr and ezLocal) <> 0;
  End;


Function EzyMsgObj.IsCrash: Boolean; {Is current msg crash}
  Begin
  IsCrash := (Ezm^.MsgHdr.NetAttr and ezCrash) <> 0;
  End;


Function EzyMsgObj.IsKillSent: Boolean; {Is current msg kill sent}
  Begin
  IsKillSent := (Ezm^.MsgHdr.NetAttr and ezKillSent) <> 0;
  End;


Function EzyMsgObj.IsSent: Boolean; {Is current msg sent}
  Begin
  IsSent := (Ezm^.MsgHdr.NetAttr and ezSent) <> 0;
  End;


Function EzyMsgObj.IsFAttach: Boolean; {Is current msg file attach}
  Begin
  IsFAttach := (Ezm^.MsgHdr.NetAttr and ezFAttach) <> 0;
  End;


Function EzyMsgObj.IsReqRct: Boolean; {Is current msg request receipt}
  Begin
  IsReqRct := (Ezm^.MsgHdr.NetAttr and ezReqRcpt) <> 0;
  End;


Function EzyMsgObj.IsReqAud: Boolean; {Is current msg request audit}
  Begin
  IsReqAud := False;
  End;


Function EzyMsgObj.IsRetRct: Boolean; {Is current msg a return receipt}
  Begin
  IsRetRct := (Ezm^.MsgHdr.NetAttr and ezRetRcpt) <> 0;
  End;


Function EzyMsgObj.IsFileReq: Boolean; {Is current msg a file request}
  Begin
  IsFileReq := (Ezm^.MsgHdr.NetAttr and ezFileReq) <> 0;
  End;


Function EzyMsgObj.IsRcvd: Boolean; {Is current msg received}
  Begin
  IsRcvd := (Ezm^.MsgHdr.MsgAttr and ezRcvd) <> 0;
  End;


Function EzyMsgObj.IsPriv: Boolean; {Is current msg priviledged/private}
  Begin
  IsPriv := (Ezm^.MsgHdr.MsgAttr and ezPriv) <> 0;
  End;


Function EzyMsgObj.IsDeleted: Boolean; {Is current msg deleted}
  Begin
  IsDeleted := (Ezm^.MsgHdr.MsgAttr and ezDeleted) <> 0;
  End;


Function EzyMsgObj.IsEchoed: Boolean; {Is current msg echoed}
  Begin
  Case EZM^.MailType of
    mmtNormal: IsEchoed := False;
    mmtNetMail: IsEchoed := (EZM^.MsgHdr.MsgAttr and ezUnMovedNet) <> 0;
    mmtEchoMail: IsEchoed := (EZM^.MsgHdr.MsgAttr and ezUnMovedEcho) <> 0;
    Else
      IsEchoed := False;
    End;
  End;


Procedure EzyMsgObj.SetEcho(ES: Boolean);
  Begin
  Case Ezm^.MailType of
    mmtNetMail:
      Begin
      If ES Then
        Ezm^.MsgHdr.MsgAttr := Ezm^.MsgHdr.MsgAttr or ezUnMovedNet
      Else
        Ezm^.MsgHdr.MsgAttr := Ezm^.MsgHdr.MsgAttr and (Not ezUnMovedNet);
      End;
    mmtEchoMail:
      Begin
      If ES Then
        Ezm^.MsgHdr.MsgAttr := Ezm^.MsgHdr.MsgAttr or ezUnMovedEcho
      Else
        Ezm^.MsgHdr.MsgAttr := Ezm^.MsgHdr.MsgAttr and (Not ezUnMovedEcho);
      End;
    End;
  End;


Procedure EzyMsgObj.SeekFirst(MsgNum: LongInt); {Start msg seek}
  Begin
  EZM^.CurrMsg := MsgNum - 1;
  SeekNext;
  End;


Procedure EzyMsgObj.SeekNext; {Find next matching msg}
  Begin
  Ezm^.Found := True;
  If Ezm^.CurrMsg < FileSize(Ezm^.MsgHdrFile) Then
    Inc(Ezm^.CurrMsg)
  Else
    Ezm^.Found := False;
  End;


Procedure EzyMsgObj.SeekPrior;
  Begin
  If Ezm^.CurrMsg > 0 Then
    Begin
    Dec(Ezm^.CurrMsg);
    End;
  If Ezm^.CurrMsg <= 0 Then
    Ezm^.Found := False;
  End;


Function EzyMsgObj.SeekFound: Boolean;
  Begin
  SeekFound := EZM^.Found;
  End;


Function EzyMsgObj.GetMsgLoc: LongInt; {Msg location}
  Begin
  GetMsgLoc := GetMsgNum;
  End;


Procedure EzyMsgObj.SetMsgLoc(ML: LongInt); {Msg location}
  Begin
  EZM^.CurrMsg := ML;
  End;


Procedure EzyMsgObj.YoursFirst(Name: String; Handle: String);
  Begin
  EZM^.Name := Upper(Name);
  EZM^.Handle := Upper(Handle);
  EZM^.CurrMsg := 0;
  YoursNext;
  End;


Procedure EzyMsgObj.YoursNext;
  Var
    FoundDone: Boolean;
    MaxSize: LongInt;

  Begin
  FoundDone := False;
  MaxSize := GetHighMsgNum;
  Inc(EZM^.CurrMsg);
  SeekFirst(EZM^.CurrMsg);
  While ((Ezm^.CurrMsg <= MaxSize) And (Not FoundDone)) Do
    Begin
    MsgStartUp;
    If ((Upper(GetTo) = Ezm^.Name) Or (Upper(GetTo) = Ezm^.Handle)) Then
      FoundDone := True;
    If IsRcvd Then FoundDone := False;
    If Not FoundDone Then
      SeekNext;
    If Not SeekFound Then
      FoundDone := True;
    End;
  End;


Function EzyMsgObj.YoursFound: Boolean;
  Begin
  YoursFound := SeekFound;
  End;


Procedure EzyMsgObj.StartNewMsg;
  Begin
  FillChar(EZM^.MsgChars, SizeOf(EZM^.MsgChars), #0);
  FillChar(Ezm^.MsgHdr, SizeOf(Ezm^.MsgHdr), 0);
  EZM^.TextCtr := 0;
  End;


Function EzyMsgObj.OpenMsgBase: Word;
  Begin
  Ezm^.Error := 0;
  If Not FileExist(Ezm^.MsgAreaPath + 'MsgH' +
  PadLeft(Long2Str(Ezm^.MsgArea),'0',3) + '.BBS') Then
    If CreateMsgBase(0,0) = 0 Then;
  Assign(Ezm^.MsgHdrFile, Ezm^.MsgAreaPath + 'MsgH' +
    PadLeft(Long2Str(Ezm^.MsgArea),'0',3) + '.BBS');
  Assign(Ezm^.MsgTxtFile, Ezm^.MsgAreaPath + 'MsgT' +
    PadLeft(Long2Str(Ezm^.MsgArea),'0',3) + '.BBS');
  Assign(Ezm^.MsgTxtWFile, Ezm^.MsgAreaPath + 'MsgT' +
    PadLeft(Long2Str(Ezm^.MsgArea),'0',3) + '.BBS');
  FileMode := fmReadWrite + fmDenyNone;
  Reset(Ezm^.MsgHdrFile, SizeOf(Ezm^.MsgHdr));
  Ezm^.Error := IoResult;
  If Ezm^.Error = 0 Then
    Begin
    FileMode := fmReadOnly + fmDenyNone;
    Reset(Ezm^.MsgTxtFile, 1);
    Ezm^.Error := IoResult;
    End;
  If Ezm^.Error <> 0 Then
    Begin
    Close(Ezm^.MsgTxtFile);
    If IoResult <> 0 Then;
    Close(Ezm^.MsgHdrFile);
    If IoResult <> 0 Then;
    End;
  OpenMsgBase := Ezm^.Error;
  End;


Function EzyMsgObj.CloseMsgBase: Word;
  Begin
  If IoResult <> 0 Then;
  Close(Ezm^.MsgHdrFile);
  If IoResult <> 0 Then;
  Close(Ezm^.MsgTxtFile);
  If IoResult <> 0 Then;
  Close(Ezm^.MsgTxtWFile);
  If IoResult <> 0 Then;
  End;


Function EzyMsgObj.CreateMsgBase(MaxMsg: Word; MaxDays: Word): Word;
  Type MsgExportType = Array[1..MaxEzMsgAreas] of Boolean;
  Type MsgCountType = Array[1..MaxEzMsgAreas] of Word;

  Var
    HdrFile: File;
    TxtFile: File;
    TempFile: File;
    MsgExport: MsgExportType;
    MsgCount: MsgCountType;

  Begin
  Assign(HdrFile, Ezm^.MsgAreaPath + 'MsgH' +
    PadLeft(Long2Str(Ezm^.MsgArea),'0',3) + '.BBS');
  Assign(TxtFile, Ezm^.MsgAreaPath + 'MsgT' +
    PadLeft(Long2Str(Ezm^.MsgArea),'0',3) + '.BBS');
  ReWrite(HdrFile);
  Ezm^.Error := IoResult;
  If Ezm^.Error = 0 Then
    Begin
    ReWrite(TxtFile);
    Ezm^.Error := IoResult;
    End;
  Close(HdrFile);
  If IoResult <> 0 Then;
  Close(TxtFile);
  If IoResult <> 0 Then;
  If Not FileExist(Ezm^.MsgPath + 'MsgFast.Bbs') Then
    Begin
    Assign(TempFile, Ezm^.MsgPath + 'Msgfast.Bbs');
    ReWrite(TempFile);
    If IoResult <> 0 Then;
    Close(TempFile);
    If IoResult <> 0 Then;
    End;
  If Not FileExist(Ezm^.MsgPath + 'MsgExprt.Bbs') Then
    Begin
    FillChar(MsgExport, SizeOf(MsgExport), #0);
    Assign(TempFile, Ezm^.Msgpath + 'MsgExprt.Bbs');
    ReWrite(TempFile, SizeOf(MsgExport));
    If IoResult <> 0 Then;
    BlockWrite(TempFile, MsgExport, 1);
    If IoResult <> 0 Then;
    Close(TempFile);
    If IoResult <> 0 Then;
    End;
  If Not FileExist(Ezm^.MsgPath + 'MsgCount.Bbs') Then
    Begin
    FillChar(MsgCount, SizeOf(MsgCount), #0);
    Assign(TempFile, Ezm^.MsgPath + 'MsgCount.Bbs');
    ReWrite(TempFile, SizeOf(MsgCount));
    If IoResult <> 0 Then;
    BlockWrite(TempFile, MsgCount, 1);
    If IoResult <> 0 Then;
    Close(TempFile);
    If IoResult <> 0 Then;
    End;
  CreateMsgBase := Ezm^.Error;
  End;


Procedure EzyMsgObj.SetMailType(MT: MsgMailType);
  Begin
  Ezm^.MailType := MT;
  End;


Function EzyMsgObj.GetSubArea: Word;
  Begin
  GetSubArea := Ezm^.MsgArea;
  End;


Procedure EzyMsgObj.ReWriteHdr;
  Begin
  If ((Ezm^.CurrMsg > 0) and (Ezm^.CurrMsg <= FileSize(Ezm^.MsgHdrFile))) Then
    Begin
    Seek(Ezm^.MsgHdrFile, Ezm^.CurrMsg - 1);
    Ezm^.Error := IoResult;
    If Ezm^.Error = 0 Then
      Begin
      BlockWrite(Ezm^.MsgHdrFile, Ezm^.MsgHdr, 1);
      Ezm^.Error := IoResult;
      End;
    End;
  End;


Procedure EzyMsgObj.DeleteMsg;
  Begin
  SetMsgAttr(ezDeleted, True);
  ReWriteHdr;
  End;


Function EzyMsgObj.NumberOfMsgs: LongInt;
  Begin
  NumberOfMsgs := FileSize(Ezm^.MsgHdrFile);
  End;



Function EzyMsgObj.GetLastRead(UNum: LongInt): LongInt;
  Var
    Count: LongInt;
    LFile: File;
    LR: Word;
    Position: LongInt;

  Begin
  LR := 0;
  Count := ((Ezm^.MsgArea - 1) Div 16) + 1; {number of combined info to skip}
  Inc(Count, (Ezm^.MsgArea - 1));  { point to current area}
  AddBackSlash(EzLastPath);
  Assign(LFile, EzLastPath + 'LastComb.Bbs');
  FileMode := fmReadOnly + fmDenyNone;
  Reset(LFile, 1);
  If IoResult <> 0 Then;
  Position := (UNum * EzLastRecSize) + (Count * 2);
  Seek(LFile, Position);
  If IoResult <> 0 Then;
  BlockRead(LFile, LR, 2);
  If IoResult <> 0 Then;
  Close(LFile);
  If IoResult <> 0 Then;
  GetLastRead := LR - 1;
  End;


Procedure EzyMsgObj.SetLastRead(UNum: LongInt; LR: LongInt);
  Var
    Count: LongInt;
    LFile: File;
    Position: LongInt;
    Tmp: Word;

  Begin
  Count := ((Ezm^.MsgArea - 1) Div 16) + 1; {number of combined info to skip}
  Inc(Count, (Ezm^.MsgArea - 1));  { point to current area}
  AddBackSlash(EzLastPath);
  Assign(LFile, EzLastPath + 'LastComb.Bbs');
  FileMode := fmReadWrite + fmDenyNone;
  Reset(LFile, 1);
  If IoResult <> 0 Then;
  Position := (UNum * EzLastRecSize) + (Count * 2);
  Seek(LFile, Position);
  If IoResult <> 0 Then;
  Tmp := LR + 1;
  BlockWrite(LFile, Tmp, 2);
  If IoResult <> 0 Then;
  Close(LFile);
  If IoResult <> 0 Then;
  End;


Function EzyMsgObj.GetTxtPos: LongInt;
  Begin
  GetTxtPos := EZM^.TextCtr;
  End;


Procedure EzyMsgObj.SetTxtPos(TP: LongInt);
  Begin
  EZM^.TextCtr := TP;
  End;


Function EzyMsgObj.MsgBaseExists: Boolean;
  Begin
  MsgBaseExists := FileExist(Ezm^.MsgAreaPath + 'MsgH' +
    PadLeft(Long2Str(Ezm^.MsgArea),'0',3) + '.BBS');
  End;

End.
