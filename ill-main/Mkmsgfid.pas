Unit MKMsgFid;       {Fido *.Msg Unit}

{$I MKB.Def}

{
     MKMsgFid - Copyright 1993, 1994 by Mark May - MK Software
     You are free to use this code in your programs, however
     it may not be included in Source/TPU function libraries
     without my permission.

     Mythical Kingom Tech BBS (513)237-7737 HST/v32
     FidoNet: 1:110/290
     Rime: ->MYTHKING
     You may also reach me at maym@dmapub.dma.org
}


{
     Now handles message size only limited by disk space and
     the maximum size of a longint, while using only a small
     buffer for low memory usage with reasonable speed
}

Interface

Uses MKGlobT, MKMsgAbs, MKFFile,
{$IFDEF WINDOWS}
  Strings, WinDos;
{$ELSE}
  Dos;
{$ENDIF}


Const MaxFidMsgArray = 4000;
Const MaxFidMsgNum = (MaxFidMsgArray * 8) - 1;

Type FMsgType = Record
  MsgFile: FFileObj;
  TextCtr: LongInt;
  MsgName: String[13];
  TmpName: String[130];
  TmpOpen: Boolean;
  MsgOpen: Boolean;
  Error: Word;
  NetMailPath: String[128];
  Dest: AddrType;
  Orig: AddrType;
  MsgStart: LongInt;
  MsgEnd: LongInt;
  MsgSize: LongInt;
  DefaultZone: Word;
  QDate: String[8];
  QTime: String[5];
  MsgDone: Boolean;
  CurrMsg: LongInt;
  SeekOver: Boolean;
  {$IFDEF WINDOWS}
  SR: TSearchRec;
  {$ELSE}
  SR: SearchRec;
  {$ENDIF}
  Name: String[35];
  Handle: String[35];
  MailType: MsgMailType;
  MsgPresent: Array[0..MaxFidMsgArray] of Byte;
  End;


Type FidoMsgObj = Object (AbsMsgObj)
  FM: ^FMsgType;
  Constructor Init;                      {Initialize FidoMsgOut}
  Destructor Done; Virtual; {Done FidoMsgOut}
  Procedure RemoveTmp; {remove temporary file}
  Procedure PutLong(L: LongInt; Position: LongInt); {Put long into msg}
  Procedure PutWord(W: Word; Position: LongInt);  {Put word into msg}
  Procedure PutByte(B: Byte; Position: LongInt);  {Put byte into msg}
  Function  GetByte(Position: LongInt): Byte; {Get byte from msg}
  Procedure PutNullStr(St: String; Position: LongInt);  {Put string & null into msg}
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
  Procedure DoString(Str: String); Virtual; {Add string to message text}
  Procedure DoChar(Ch: Char); Virtual; {Add character to message text}
  Procedure DoStringLn(Str: String); Virtual; {Add string and newline to msg text}
  Function  WriteMsg: Word; Virtual;
  Procedure SetDefaultZone(DZ: Word); Virtual; {Set default zone to use}
  Procedure LineStart; Virtual; {Internal use to skip LF, ^A}
  Function  GetChar: Char; Virtual;
  Procedure CheckZone(ZoneStr: String); Virtual;
  Procedure CheckPoint(PointStr: String); Virtual;
  Procedure CheckLine(TStr: String); Virtual;
  Function  CvtDate: Boolean; Virtual;
  Function  BufferWord(i: Word):Word; Virtual;
  Function  BufferByte(i: Word):Byte; Virtual;
  Function  BufferNullString(i: Word; Max: Word): String; Virtual;
  Procedure MsgStartUp; Virtual; {set up msg for reading}
  Function  EOM: Boolean; Virtual; {No more msg text}
  Function  GetString(MaxLen: Word): String; Virtual; {Get wordwrapped string}
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
  Function  MsgBaseExists: Boolean; Virtual;
  Procedure Rescan;
  Function  MsgExists(MsgNum: LongInt): Boolean;
  End;


Type FidoMsgPtr = ^FidoMsgObj;

Function MonthStr(MoNo: Byte): String; {Return 3 char month name for month num}
Function MonthNum(St: String):Word;


Implementation

Uses MKFile, MKString, MKDos;


Const
  PosArray: Array[0..7] of Byte = (1, 2, 4, 8, 16, 32, 64, 128);


Constructor FidoMsgObj.Init;
  Begin
  New(FM);
  If FM = Nil Then
    Begin
    Fail;
    Exit;
    End;
  FM^.NetMailPath := '';
  FM^.TextCtr := 190;
  FM^.Dest.Zone := 0;
  FM^.Orig.Zone := 0;
  FM^.SeekOver := False;
  FM^.DefaultZone := 1;
  FM^.MsgFile.Init(4000);
  FM^.TmpOpen := False;
  FM^.MsgOpen := False;
  End;


Destructor FidoMsgObj.Done;
  Begin
  If FM^.MsgOpen Then
    If FM^.MsgFile.CloseFile Then;
  If FM^.TmpOpen Then
    Begin
    RemoveTmp;
    End;
  FM^.MsgFile.Done;
  Dispose(FM);
  End;


Procedure FidoMsgObj.RemoveTmp;
  Var
    TmpFile: File;

  Begin
  If FM^.MsgFile.CloseFile Then;
  Assign(TmpFile, FM^.TmpName);
  Erase(TmpFile);
  If IoResult <> 0 Then;
  FM^.TmpOpen := False;
  End;


Procedure FidoMsgObj.PutLong(L: LongInt; Position: LongInt);
  Var
    i: Integer;

  Begin
  If FM^.MsgFile.SeekFile(Position) Then
    If FM^.MsgFile.BlkWrite(L, SizeOf(LongInt)) Then;
  End;


Procedure FidoMsgObj.PutWord(W: Word; Position: LongInt);
  Begin
  If FM^.MsgFile.SeekFile(Position) Then
    If FM^.MsgFile.BlkWrite(W, SizeOf(Word)) Then;
  End;


Procedure FidoMsgObj.PutByte(B: Byte; Position: LongInt);
  Begin
  If FM^.MsgFile.SeekFile(Position) Then
    If FM^.MsgFile.BlkWrite(B, SizeOf(Byte)) Then;
  End;


Function FidoMsgObj.GetByte(Position: LongInt): Byte;
  Var
    B: Byte;
    NumRead: Word;

  Begin
  If FM^.MsgFile.SeekFile(Position) Then
    If FM^.MsgFile.BlkRead(B, SizeOf(Byte), NumRead) Then;
  GetByte := b;
  End;


Procedure FidoMsgObj.PutNullStr(St: String; Position: LongInt);
  Var
    i: Byte;

  Begin
  i := 0;
  If FM^.MsgFile.SeekFile(Position) Then
    Begin
    If FM^.MsgFile.BlkWrite(St[1], Length(St)) Then;
    If FM^.MsgFile.BlkWrite(i, 1) Then;
    End;
  End;


Procedure FidoMsgObj.SetMsgPath(St: String);
  Begin
  FM^.NetMailPath := Copy(St, 1, 110);
  AddBackSlash(FM^.NetMailPath);
  End;


Function FidoMsgObj.GetHighMsgNum: LongInt;
  Var
  Highest: LongInt;
  Cnt: LongInt;

  Begin
  Cnt := MaxFidMsgArray;
  While (Cnt > 0) and (FM^.MsgPresent[Cnt] = 0) Do
    Dec(Cnt);
  If Cnt < 0 Then
    Highest := 0
  Else
    Begin
    Highest := Cnt * 8;
    If (FM^.MsgPresent[Cnt] and $80) <> 0 Then
      Inc(Highest, 7)
    Else If (FM^.MsgPresent[Cnt] and $40) <> 0 Then
      Inc(Highest, 6)
    Else If (FM^.MsgPresent[Cnt] and $20) <> 0 Then
      Inc(Highest, 5)
    Else If (FM^.MsgPresent[Cnt] and $10) <> 0 Then
      Inc(Highest, 4)
    Else If (FM^.MsgPresent[Cnt] and $08) <> 0 Then
      Inc(Highest, 3)
    Else If (FM^.MsgPresent[Cnt] and $04) <> 0 Then
      Inc(Highest, 2)
    Else If (FM^.MsgPresent[Cnt] and $02) <> 0 Then
      Inc(Highest, 1)
    End;
  GetHighMsgNum := Highest;
  End;


Function MonthStr(MoNo: Byte): String;
  Begin
  Case MoNo of
    01: MonthStr := 'Jan';
    02: MonthStr := 'Feb';
    03: MonthStr := 'Mar';
    04: MonthStr := 'Apr';
    05: MonthStr := 'May';
    06: MonthStr := 'Jun';
    07: MonthStr := 'Jul';
    08: MonthStr := 'Aug';
    09: MonthStr := 'Sep';
    10: MonthStr := 'Oct';
    11: MonthStr := 'Nov';
    12: MonthStr := 'Dec';
    Else
      MonthStr := '???';
    End;
  End;


Procedure FidoMsgObj.SetDest(Var Addr: AddrType);
  Var
    TmpChr: Char;

  Begin
  FM^.Dest := Addr;
  PutWord(Addr.Net, 174);
  PutWord(Addr.Node, 166);
  If ((Addr.Point <> 0) and (FM^.MailType = mmtNetmail)) Then
    Begin
    If ((FM^.TextCtr <> 190) And
    (GetByte(FM^.TextCtr - 1) <> 13)) Then
      DoChar(#13);
    DoStringLn(#1 + 'TOPT ' + Long2Str(Addr.Point));
    End;
  If ((FM^.Orig.Zone <> 0) and (FM^.MailTYpe = mmtNetMail)) Then
    Begin
    If ((FM^.TextCtr <> 190) And
    (GetByte(FM^.TextCtr - 1) <> 13)) Then
      DoChar(#13);
    DoStringLn(#1 + 'INTL ' + PointlessAddrStr(FM^.Dest) + ' ' +
      PointlessAddrStr(FM^.Orig));
    End;
  End;


Procedure FidoMsgObj.SetOrig(Var Addr: AddrType);
  Begin
  FM^.Orig := Addr;
  PutWord(Addr.Net, 172);
  PutWord(Addr.Node, 168);
  If ((Addr.Point <> 0) and (FM^.MailType = mmtNetmail)) Then
    Begin
    If ((FM^.TextCtr <> 190) And
    (GetByte(FM^.TextCtr - 1) <> 13)) Then
      DoChar(#13);
    DoStringLn(#1 + 'FMPT ' + Long2Str(Addr.Point));
    End;
  If ((FM^.Dest.Zone <> 0) and (FM^.MailType = mmtNetmail)) Then
    Begin
    If ((FM^.TextCtr <> 190) And
    (GetByte(FM^.TextCtr - 1) <> 13)) Then
      DoChar(#13);
    DoStringLn(#1 + 'INTL ' + PointlessAddrStr(FM^.Dest) + ' ' +
      PointlessAddrStr(FM^.Orig));
    End;
  End;


Procedure FidoMsgObj.SetFrom(Name: String);
  Begin
  PutNullStr(Copy(Name, 1, 35),0);
  End;


Procedure FidoMsgObj.SetTo(Name: String);
  Begin
  PutNullStr(Copy(Name, 1, 35), 36);
  End;


Procedure FidoMsgObj.SetSubj(Str: String);
  Begin
  PutNullStr(Copy(Str, 1, 71), 72);
  End;


Procedure FidoMsgObj.SetCost(SCost: Word);
  Begin
  PutWord(SCost, 170);
  End;


Procedure FidoMsgObj.SetRefer(SRefer: LongInt);
  Begin
  PutWord(SRefer, 184);
  End;


Procedure FidoMsgObj.SetSeeAlso(SAlso: LongInt);
  Begin
  PutWord(SAlso, 188);
  End;


Procedure FidoMsgObj.SetDate(SDate: String);
  Var
    TempNum: Word;
    Code: Word;
    TmpStr: String[20];

  Begin
  FM^.QDate := Copy(SDate,1,8);
  Val(Copy(SDate,1,2),TempNum, Code);
  TmpStr := Copy(SDate,4,2) + ' ' + MonthStr(TempNum) + ' ' +
    Copy(SDate,7,2) + '  ';
  For TempNum := 1 to 11 Do
    PutByte(Ord(TmpStr[TempNum]), TempNum + 143);
  End;


Procedure FidoMsgObj.SetTime(STime: String);
  Begin
  FM^.QTime := Copy(STime,1,5);
  PutNullStr(Copy(STime + ':00', 1, 8), 155);
  End;


Procedure FidoMsgObj.SetLocal(LS: Boolean);
  Begin
  If LS Then
    PutByte(GetByte(187) or 1, 187)
  Else
    PutByte(GetByte(187) and (Not 1), 187);
  End;


Procedure FidoMsgObj.SetRcvd(RS: Boolean);
  Begin
  If RS Then
    PutByte(GetByte(186) or 4, 186)
  Else
    PutByte(GetByte(186) and (not 4), 186);
  End;


Procedure FidoMsgObj.SetPriv(PS: Boolean);
  Begin
  If PS Then
    PutByte(GetByte(186) or 1, 186)
  Else
    PutByte(GetByte(186) and (not 1), 186);
  End;


Procedure FidoMsgObj.SetCrash(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(186) or 2, 186)
  Else
    PutByte(GetByte(186) and (not 2), 186);
  End;


Procedure FidoMsgObj.SetKillSent(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(186) or 128, 186)
  Else
    PutByte(GetByte(186) and (Not 128), 186);
  End;


Procedure FidoMsgObj.SetSent(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(186) or 8, 186)
  Else
    PutByte(GetByte(186) and (not 8), 186);
  End;


Procedure FidoMsgObj.SetFAttach(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(186) or 16, 186)
  Else
    PutByte(GetByte(186) and (not 16), 186);
  End;


Procedure FidoMsgObj.SetReqRct(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(187) or 16, 187)
  Else
    PutByte(GetByte(187) and (not 16), 187);
  End;


Procedure FidoMsgObj.SetReqAud(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(187) or 64, 187)
  Else
    PutByte(GetByte(187) and (not 64), 187);
  End;


Procedure FidoMsgObj.SetRetRct(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(187) or 32, 187)
  Else
    PutByte(GetByte(187) and (not 32), 187);
  End;


Procedure FidoMsgObj.SetFileReq(SS: Boolean);
  Begin
  If SS Then
    PutByte(GetByte(187) or 8, 187)
  Else
    PutByte(GetByte(187) and (not 8), 187);
  End;


Procedure FidoMsgObj.DoString(Str: String);
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


Procedure FidoMsgObj.DoChar(Ch: Char);
  Begin
  PutByte(Ord(Ch), FM^.TextCtr);
  Inc(FM^.TextCtr);
  End;


Procedure FidoMsgObj.DoStringLn(Str: String);
  Begin
  DoString(Str);
  DoChar(#13);
  End;


Function  FidoMsgObj.WriteMsg: Word;
  Var
    NetNum: Word;
    TmpDate: LongInt;
    {$IFDEF WINDOWS}
    TmpDT: TDateTime;
    {$ELSE}
    TmpDT: DateTime;
    {$ENDIF}
    TmpFile: File;
    Code: LongInt;

  Begin
  DoChar(#0);
  PutLong(GetDosDate, 180);
  TmpDT.Year := Str2Long(Copy(FM^.QDate,7,2));
  If TmpDT.Year > 79 Then
    Inc(TmpDT.Year, 1900)
  Else
    Inc(TmpDT.Year, 2000);
  TmpDT.Month := Str2Long(Copy(FM^.QDate,1,2));
  TmpDT.Day := Str2Long(Copy(FM^.QDate,4,2));
  TmpDt.Hour := Str2Long(Copy(FM^.QTime,1,2));
  TmpDt.Min := Str2Long(Copy(FM^.QTime, 4,2));
  TmpDt.Sec := 0;
  PackTime(TmpDT, TmpDate);
  PutLong(TmpDate, 176);
  NetNum := GetHighMsgNum + 1;
  If FileExist(FM^.NetMailPath + Long2Str(NetNum) + '.Msg') Then
    Begin
    Rescan;
    NetNum := GetHighMsgNum + 1;
    End;
  Code := NetNum shr 3; {div by 8 to get byte position}
  FM^.MsgPresent[Code] := FM^.MsgPresent[Code] or PosArray[NetNum and 7];
  If FM^.TmpOpen Then
    Begin
    If FM^.MsgFile.CloseFile Then
      Begin
      Assign(TmpFile, FM^.TmpName);
      Rename(TmpFile, FM^.NetMailPath + Long2Str(NetNum) + '.Msg')
      End;
    End;
  WriteMsg := IoResult;
  FM^.CurrMsg := NetNum;
  End;


Procedure FidoMsgObj.SetDefaultZone(DZ: Word); {Set default zone to use}
  Begin
  FM^.DefaultZone := DZ;
  End;


Procedure FidoMsgObj.LineStart;
  Begin
  If GetByte(FM^.TextCtr) = 10 Then
    Inc(FM^.TextCtr);
  If GetByte(FM^.TextCtr) = 1 Then
    Inc(FM^.TextCtr);
  End;


Function FidoMsgObj.GetChar: Char;
  Begin
  If ((FM^.TextCtr >= FM^.MsgSize) Or (GetByte(FM^.TextCtr) = 0)) Then
    Begin
    GetChar := #0;
    FM^.MsgDone := True;
    End
  Else
    Begin
    GetChar := Chr(GetByte(FM^.TextCtr));
    Inc(FM^.TextCtr);
    End;
  End;


Procedure FidoMsgObj.CheckZone(ZoneStr: String);
  Var
    DestZoneStr: String;
    Code: Word;

  Begin
  If (Upper(Copy(ZoneStr,1,4)) = 'INTL') Then
    Begin
    DestZoneStr := ExtractWord(ZoneStr, 2);
    DestZoneStr := StripBoth(DestZoneStr, ' ');
    DestZoneStr := Copy(DestZoneStr, 1, Pos(':', DestZoneStr) - 1);
    Val(DestZoneStr, FM^.Dest.Zone, Code);
    DestZoneStr := ExtractWord(ZoneStr,3);
    DestZoneStr := StripBoth(DestZoneStr, ' ');
    DestZoneStr := Copy(DestZoneStr, 1, Pos(':', DestZoneStr) - 1);
    Val(DestZoneStr, FM^.Orig.Zone, Code);
    End;
  End;


Procedure FidoMsgObj.CheckPoint(PointStr: String);
  Var
    DestPointStr: String;
    Code: Word;
    Temp: Word;

  Begin
  If (Upper(Copy(PointStr,1,4)) = 'TOPT') Then
    Begin
    DestPointStr := ExtractWord(PointStr, 2);
    DestPointStr := StripBoth(DestPointStr, ' ');
    Val(DestPointStr, Temp, Code);
    If Code = 0 Then
      FM^.Dest.Point := Temp;
    End;
  If (Upper(Copy(PointStr,1,4)) = 'FMPT') Then
    Begin
    DestPointStr := ExtractWord(PointStr, 2);
    DestPointStr := StripBoth(DestPointStr, ' ');
    Val(DestPointStr, Temp, Code);
    If Code = 0 Then
      FM^.Orig.Point := Temp;
    End;
  End;


Function MonthNum(St: String):Word;
  Begin
  ST := Upper(St);
  MonthNum := 0;
  If St = 'JAN' Then MonthNum := 01;
  If St = 'FEB' Then MonthNum := 02;
  If St = 'MAR' Then MonthNum := 03;
  If St = 'APR' Then MonthNum := 04;
  If St = 'MAY' Then MonthNum := 05;
  If St = 'JUN' Then MonthNum := 06;
  If St = 'JUL' Then MonthNum := 07;
  If St = 'AUG' Then MonthNum := 08;
  If St = 'SEP' Then MonthNum := 09;
  If St = 'OCT' Then MonthNum := 10;
  If St = 'NOV' Then MonthNum := 11;
  If St = 'DEC' Then MonthNum := 12;
  End;


Function FidoMsgObj.CvtDate: Boolean;
  Var
    MoNo: Word;
    TmpStr: String;
    i: Word;
    MsgDt: String[25];

  Begin
  MsgDt := BufferNullString(144, 20);
  MsgDt := PadRight(MsgDt,' ', 20);
  CvtDate := True;
  If MsgDt[3] = ' ' Then
    Begin {Fido or Opus}
    If MsgDt[11] = ' ' Then
      Begin {Fido DD MON YY  HH:MM:SSZ}
      FM^.QTime := Copy (MsgDT,12,5);
      TmpStr := Long2Str(MonthNum(Copy(MsgDt,4,3)));
      If Length(TmpStr) = 1 Then
        TmpStr := '0' + TmpStr;
      FM^.QDate := TmpStr + '-' + Copy(MsgDT,1,2) + '-' + Copy (MsgDt,8,2);
      End
    Else
      Begin {Opus DD MON YY HH:MM:SS}
      FM^.QTime := Copy(MsgDT,11,5);
      TmpStr := Long2Str(MonthNum(Copy(MsgDt,4,3)));
      If Length(TmpStr) = 1 Then
        TmpStr := '0' + TmpStr;
      FM^.QDate := TmpStr + '-' + Copy(MsgDT,1,2) + '-' + Copy (MsgDt,8,2);
      End;
    End
  Else
    Begin
    If MsgDT[4] = ' ' Then
      Begin {SeaDog format DOW DD MON YY HH:MM}
      FM^.QTime := Copy(MsgDT,15,5);
      TmpStr := Long2Str(MonthNum(Copy(MsgDT,8,3)));
      If Length(TmpStr) = 1 Then
        TmpStr := '0' + TmpStr;
      FM^.QDate := TmpStr + '-' + Copy(MsgDT,5,2) + '-' + Copy (MsgDt,12,2);
      End
    Else
      Begin
      If MsgDT[3] = '-' Then
        Begin {Wierd format DD-MM-YYYY HH:MM:SS}
        FM^.QTime := Copy(MsgDt,12,5);
        FM^.QDate := Copy(MsgDt,4,3) + Copy (MsgDt,1,3) + Copy (MsgDt,9,2);
        End
      Else
        Begin  {Bad Date}
        CvtDate := False;
        End;
      End;
    End;
  For i := 1 to 5 Do
    If FM^.QTime[i] = ' ' Then
      FM^.QTime[i] := '0';
  For i := 1 to 8 Do
    If FM^.QDate[i] = ' ' Then
      FM^.QDate[i] := '0';
  If Length(FM^.QDate) <> 8 Then
    CvtDate := False;
  If Length(FM^.QTime) <> 5 Then
    CvtDate := False;
  End;


Function FidoMsgObj.BufferWord(i: Word):Word;
  Begin
  BufferWord := BufferByte(i) + (BufferByte(i + 1) shl 8);
  End;


Function FidoMsgObj.BufferByte(i: Word):Byte;
  Begin
  BufferByte := GetByte(i);
  End;


Function FidoMsgObj.BufferNullString(i: Word; Max: Word): String;
  Var
    Ctr: Word;
    CurrPos: Word;

  Begin
  BufferNullString := '';
  Ctr := i;
  CurrPos := 0;
  While ((CurrPos < Max) and (GetByte(Ctr) <> 0)) Do
    Begin
    Inc(CurrPos);
    BufferNullString[CurrPos] := Chr(GetByte(Ctr));
    Inc(Ctr);
    End;
  BufferNullString[0] := Chr(CurrPos);
  End;


Procedure FidoMsgObj.CheckLine(TStr: String);
  Begin
  If TStr[1] = #10 Then
    TStr := Copy(TStr,2,255);
  If TStr[1] = #01 Then
    TStr := Copy(TStr,2,255);
  CheckZone(TStr);
  CheckPoint(TStr);
  End;


Procedure FidoMsgObj.MsgStartUp;
  Var
    TStr: String;
    TmpChr: Char;
    NumRead: Word;

  Begin
  If FM^.MsgOpen Then
    If FM^.MsgFile.CloseFile Then
      FM^.MsgOpen := False;
  If FM^.TmpOpen Then
    RemoveTmp;
  LastSoft := False;
  If FileExist (FM^.NetMailPath + Long2Str(FM^.CurrMsg) + '.MSG') Then
    FM^.Error := 0
  Else
    FM^.Error := 200;
  If FM^.Error = 0 Then
    Begin
    If Not FM^.MsgFile.OpenFile(FM^.NetMailPath + Long2Str(FM^.CurrMsg) +
    '.Msg',  fmReadWrite + fmDenyNone) Then FM^.Error := 1000;
    End;
  If FM^.Error = 0 Then
    FM^.MsgOpen := True;
  FM^.MsgDone := False;
  FM^.MsgSize := FM^.MsgFile.RawSize;
  FM^.MsgEnd := 0;
  FM^.MsgStart := 190;
  FM^.Dest.Zone := FM^.DefaultZone;
  FM^.Dest.Point := 0;
  FM^.Orig.Zone := FM^.DefaultZone;
  FM^.Orig.Point := 0;
  FM^.Orig.Net := BufferWord(172);
  FM^.Orig.Node := BufferWord(168);
  FM^.Dest.Net := BufferWord(174);
  FM^.Dest.Node := BufferWord(166);
  FM^.TextCtr := FM^.MsgStart;
  If FM^.Error = 0 Then
    Begin
    If Not CvtDate Then
      Begin
      FM^.QDate := '09-06-89';
      FM^.QTime := '19:76';
      End;
    TStr := GetString(128);
    CheckLine(TStr);
    If FM^.MsgFile.SeekFile(FM^.TextCtr) Then
      If FM^.MsgFile.BlkRead(TmpChr, 1, NumRead) Then;
    While ((FM^.MsgEnd = 0) and (FM^.TextCtr <= FM^.MsgSize)) Do
      Begin
      Case TmpChr Of
        #0: FM^.MsgEnd := FM^.TextCtr;
        #13: Begin
          Inc(FM^.TextCtr);
          TStr := GetString(128);
          CheckLine(TStr);
          If Length(TStr) > 0 Then
            Dec(FM^.TextCtr);
          End;
        Else
          Begin
          Inc(FM^.TextCtr);
          If FM^.MsgFile.BlkRead(TmpChr, 1, NumRead) Then;
          End;
        End;
      End;
    If FM^.MsgEnd = 0 Then
      FM^.MsgEnd := FM^.MsgSize;
    FM^.MsgSize := FM^.MsgEnd;
    FM^.MsgStart := 190;
    FM^.TextCtr := FM^.MsgStart;
    FM^.MsgDone := False;
    LastSoft := False;
    End;
  End;


Procedure FidoMsgObj.MsgTxtStartUp;
  Begin
  FM^.MsgStart := 190;
  FM^.TextCtr := FM^.MsgStart;
  FM^.MsgDone := False;
  LastSoft := False;
  End;


Function FidoMsgObj.GetString(MaxLen: Word): String;
  Var
    WPos: LongInt;
    WLen: Byte;
    StrDone: Boolean;
    TxtOver: Boolean;
    StartSoft: Boolean;
    CurrLen: LongInt;
    PPos: LongInt;
    TmpCh: Char;
    TmpStr: String;
    NumRead: Word;
    StrCtr: LongInt;

  Begin
  If MaxLen > 254 Then
    MaxLen := 254;
  StrDone := False;
  CurrLen := 0;
  PPos := FM^.TextCtr;
  WPos := 0;
  WLen := 0;
  StartSoft := LastSoft;
  LastSoft := True;
  If (FM^.TextCtr >= FM^.MsgSize) Then
    Begin
    TmpStr := #0;
    TmpCh := #0;
    FM^.MsgDone := True;
    End
  Else
    Begin
    If FM^.MsgFile.SeekFile(FM^.TextCtr) Then
      If FM^.MsgFile.BlkRead(TmpStr[1], 255, NumRead) Then;
    TmpStr[0] := Chr(NumRead);
    TmpCh := TmpStr[1];
    End;
  StrCtr := 1;
  { **1 TmpCh := GetChar; }
  While ((Not StrDone) And (CurrLen < MaxLen) And (Not FM^.MsgDone)) Do
    Begin
    Case TmpCh of
      #$00:;
      #$0d: Begin
            StrDone := True;
            LastSoft := False;
            End;
      #$8d:;
      #$0a:;
      #$20: Begin
            If ((CurrLen <> 0) or (Not StartSoft)) Then
              Begin
              Inc(CurrLen);
              WLen := CurrLen;
              GetString[CurrLen] := TmpCh;
              WPos := FM^.TextCtr + StrCtr;
              End
            Else
              StartSoft := False;
            End;
      Else
        Begin
        Inc(CurrLen);
        GetString[CurrLen] := TmpCh;
        End;
      End;
    If Not StrDone Then
      Begin
      Inc(StrCtr);
      TmpCh := TmpStr[StrCtr];
      If StrCtr > Length(TmpStr) Then
        Begin
        TmpCh := #0;
        StrDone := True;
        End
      {** 1 TmpCh := GetChar;}
      End;
    End;
  FM^.TextCtr := FM^.TextCtr + StrCtr;
  If StrDone Then
    Begin
    GetString[0] := Chr(CurrLen);
    End
  Else
    If FM^.MsgDone Then
      Begin
      GetString[0] := Chr(CurrLen);
      End
    Else
      Begin
      If WLen = 0 Then
        Begin
        GetString[0] := Chr(CurrLen);
        Dec(FM^.TextCtr);
        End
      Else
        Begin
        GetString[0] := Chr(WLen);
        FM^.TextCtr := WPos;
        End;
      End;
  End;


Function FidoMsgObj.EOM: Boolean;
  Begin
  EOM := FM^.MsgDone;
  End;


Function FidoMsgObj.WasWrap: Boolean;
  Begin
  WasWrap := LastSoft;
  End;


Function FidoMsgObj.GetFrom: String; {Get from name on current msg}
  Begin
  GetFrom := BufferNullString(0, 35);
  End;


Function FidoMsgObj.GetTo: String; {Get to name on current msg}
  Begin
  GetTo := BufferNullString(36,35);
  End;


Function FidoMsgObj.GetSubj: String; {Get subject on current msg}
  Begin
  GetSubj := BufferNullString(72,71);
  End;


Function FidoMsgObj.GetCost: Word; {Get cost of current msg}
  Begin
  GetCost := BufferWord(170);
  End;


Function FidoMsgObj.GetDate: String; {Get date of current msg}
  Begin
  GetDate := FM^.QDate;
  End;


Function FidoMsgObj.GetTime: String; {Get time of current msg}
  Begin
  GetTime := FM^.QTime;
  End;


Function FidoMsgObj.GetRefer: LongInt; {Get reply to of current msg}
  Begin
  GetRefer := BufferWord(184);
  End;


Function FidoMsgObj.GetSeeAlso: LongInt; {Get see also of current msg}
  Begin
  GetSeeAlso := BufferWord(188);
  End;


Function FidoMsgObj.GetMsgNum: LongInt; {Get message number}
  Begin
  GetMsgNum := FM^.CurrMsg;
  End;


Procedure FidoMsgObj.GetOrig(Var Addr: AddrType); {Get origin address}
  Begin
  Addr := FM^.Orig;
  End;


Procedure FidoMsgObj.GetDest(Var Addr: AddrType); {Get destination address}
  Begin
  Addr := FM^.Dest;
  End;


Function FidoMsgObj.IsLocal: Boolean; {Is current msg local}
  Begin
  IsLocal := ((GetByte(187) and 001) <> 0);
  End;


Function FidoMsgObj.IsCrash: Boolean; {Is current msg crash}
  Begin
  IsCrash := ((GetByte(186) and 002) <> 0);
  End;


Function FidoMsgObj.IsKillSent: Boolean; {Is current msg kill sent}
  Begin
  IsKillSent := ((GetByte(186) and 128) <> 0);
  End;


Function FidoMsgObj.IsSent: Boolean; {Is current msg sent}
  Begin
  IsSent := ((GetByte(186) and 008) <> 0);
  End;


Function FidoMsgObj.IsFAttach: Boolean; {Is current msg file attach}
  Begin
  IsFAttach := ((GetByte(186) and 016) <> 0);
  End;


Function FidoMsgObj.IsReqRct: Boolean; {Is current msg request receipt}
  Begin
  IsReqRct := ((GetByte(187) and 016) <> 0);
  End;


Function FidoMsgObj.IsReqAud: Boolean; {Is current msg request audit}
  Begin
  IsReqAud := ((GetByte(187) and 064) <> 0);
  End;


Function FidoMsgObj.IsRetRct: Boolean; {Is current msg a return receipt}
  Begin
  IsRetRct := ((GetByte(187) and 032) <> 0);
  End;


Function FidoMsgObj.IsFileReq: Boolean; {Is current msg a file request}
  Begin
  IsFileReq := ((GetByte(187) and 008) <> 0);
  End;


Function FidoMsgObj.IsRcvd: Boolean; {Is current msg received}
  Begin
  IsRcvd := ((GetByte(186) and 004) <> 0);
  End;


Function FidoMsgObj.IsPriv: Boolean; {Is current msg priviledged/private}
  Begin
  IsPriv := ((GetByte(186) and 001) <> 0);
  End;


Function FidoMsgObj.IsDeleted: Boolean; {Is current msg deleted}
  Begin
  IsDeleted := Not FileExist (FM^.NetMailPath + Long2Str(FM^.CurrMsg) + '.MSG');
  End;


Function FidoMsgObj.IsEchoed: Boolean; {Is current msg echoed}
  Begin
  IsEchoed := True;
  End;


Procedure FidoMsgObj.SeekFirst(MsgNum: LongInt); {Start msg seek}
  Begin
  FM^.CurrMsg := MsgNum - 1;
  SeekNext;
  End;


Procedure FidoMsgObj.SeekNext; {Find next matching msg}
  Begin
  Inc(FM^.CurrMsg);
  While ((Not MsgExists(FM^.CurrMsg)) and (FM^.CurrMsg <= MaxFidMsgNum)) Do
    Inc(FM^.CurrMsg);
  If Not MsgExists(FM^.CurrMsg) Then
    FM^.CurrMsg := 0;
  End;


Procedure FidoMsgObj.SeekPrior;
  Begin
  Dec(FM^.CurrMsg);
  While ((Not MsgExists(FM^.CurrMsg)) and (FM^.CurrMsg > 0)) Do
    Dec(FM^.CurrMsg);
  End;


Function FidoMsgObj.SeekFound: Boolean;
  Begin
  SeekFound := FM^.CurrMsg <> 0;
  End;


Function FidoMsgObj.GetMsgLoc: LongInt; {Msg location}
  Begin
  GetMsgLoc := GetMsgNum;
  End;


Procedure FidoMsgObj.SetMsgLoc(ML: LongInt); {Msg location}
  Begin
  FM^.CurrMsg := ML;
  End;


Procedure FidoMsgObj.YoursFirst(Name: String; Handle: String);
  Begin
  FM^.Name := Upper(Name);
  FM^.Handle := Upper(Handle);
  FM^.CurrMsg := 0;
  YoursNext;
  End;


Procedure FidoMsgObj.YoursNext;
  Var
    FoundDone: Boolean;

  Begin
  FoundDone := False;
  SeekFirst(FM^.CurrMsg + 1);
  While ((FM^.CurrMsg <> 0) And (Not FoundDone)) Do
    Begin
    MsgStartUp;
    If ((Upper(GetTo) = FM^.Name) Or (Upper(GetTo) = FM^.Handle)) Then
      FoundDone := True;
    If IsRcvd Then FoundDone := False;
    If Not FoundDone Then
      SeekNext;
    If Not SeekFound Then
      FoundDone := True;
    End;
  End;


Function FidoMsgObj.YoursFound: Boolean;
  Begin
  YoursFound := SeekFound;
  End;


Procedure FidoMsgObj.StartNewMsg;
  Var
    Tmp: Array[0..189] of Char;

  Begin
  FM^.Error := 0;
  FM^.TextCtr := 190;
  FM^.Dest.Zone := 0;
  FM^.Orig.Zone := 0;
  FM^.Dest.Point := 0;
  FM^.Orig.Point := 0;
  If FM^.TmpOpen Then
    RemoveTmp
  Else
    Begin
    If FM^.MsgOpen Then
      Begin
      If FM^.MsgFile.CloseFile Then
        FM^.MsgOpen := False;
      End;
    End;
  FM^.TmpName := GetTempName(FM^.NetMailPath);
  If Length(FM^.TmpName) > 0 Then
    Begin
    If FM^.MsgFile.OpenFile(FM^.TmpName, fmReadWrite + fmDenyNone) Then
      Begin
      FM^.TmpOpen := True;
      End
    Else
      FM^.Error := 1002;
    End
  Else
    FM^.Error := 1001;
  FillChar(Tmp, SizeOf(Tmp), #0);
  If FM^.MsgFile.SeekFile(0) Then;
  If FM^.MsgFile.BlkWrite(Tmp, SizeOf(Tmp)) Then;
  End;


Function FidoMsgObj.OpenMsgBase: Word;
  Begin
  Rescan;
  If MsgBaseExists Then
    OpenMsgBase := 0
  Else
    OpenMsgBase := 500;
  End;


Function FidoMsgObj.CloseMsgBase: Word;
  Begin
  CloseMsgBase := 0;
  End;


Function FidoMsgObj.CreateMsgBase(MaxMsg: Word; MaxDays: Word): Word;
  Begin
  If MakePath(FM^.NetMailPath) Then
    CreateMsgBase := 0
  Else
    CreateMsgBase := 1;
  End;


Procedure FidoMsgObj.SetMailType(MT: MsgMailType);
  Begin
  FM^.MailType := Mt;
  End;


Function FidoMsgObj.GetSubArea: Word;
  Begin
  GetSubArea := 0;
  End;


Procedure FidoMsgObj.ReWriteHdr;
  Begin
  { Not needed, rewrite is automatic when updates are done }
  End;


Procedure FidoMsgObj.DeleteMsg;
  Var
    TmpFile: File;
    Code: LongInt;

  Begin
  If FM^.MsgOpen Then
    If FM^.MsgFile.CloseFile Then
      FM^.MsgOpen := False;
  Assign(TmpFile, FM^.NetMailPath + Long2Str(FM^.CurrMsg) + '.MSG');
  Erase(TmpFile);
  Code := FM^.CurrMsg shr 3; {div by 8 to get byte position}
  FM^.MsgPresent[Code] := FM^.MsgPresent[Code] and
    Not (PosArray[FM^.CurrMsg and 7]);
  If IoResult <> 0 Then;
  End;


Function FidoMsgObj.NumberOfMsgs: LongInt;
  Var
  Cnt: Word;
  Active: LongInt;

  Begin
  Active := 0;
  For Cnt := 0 To MaxFidMsgArray Do
    Begin
    If FM^.MsgPresent[Cnt] <> 0 Then
      Begin
      If (FM^.MsgPresent[Cnt] and $80) <> 0 Then
        Inc(Active);
      If (FM^.MsgPresent[Cnt] and $40) <> 0 Then
        Inc(Active);
      If (FM^.MsgPresent[Cnt] and $20) <> 0 Then
        Inc(Active);
      If (FM^.MsgPresent[Cnt] and $10) <> 0 Then
        Inc(Active);
      If (FM^.MsgPresent[Cnt] and $08) <> 0 Then
        Inc(Active);
      If (FM^.MsgPresent[Cnt] and $04) <> 0 Then
        Inc(Active);
      If (FM^.MsgPresent[Cnt] and $02) <> 0 Then
        Inc(Active);
      If (FM^.MsgPresent[Cnt] and $01) <> 0 Then
        Inc(Active);
      End;
    End;
  NumberOfMsgs := Active;
  End;


Function FidoMsgObj.GetLastRead(UNum: LongInt): LongInt;
  Var
    LRec: Word;

  Begin
  If ((UNum + 1) * SizeOf(LRec)) >
  SizeFile(FM^.NetMailPath + 'LastRead') Then
    GetLastRead := 0
  Else
    Begin
    If LoadFilePos(FM^.NetMailPath + 'LastRead', LRec, SizeOf(LRec),
    UNum * SizeOf(LRec)) = 0 Then
      GetLastRead := LRec
    Else
      GetLastRead := 0;
    End;
  End;


Procedure FidoMsgObj.SetLastRead(UNum: LongInt; LR: LongInt);
  Var
    LRec: Word;
    Status: Word;

  Begin
  If ((UNum + 1) * SizeOf(LRec)) >
  SizeFile(FM^.NetMailPath + 'LastRead') Then
    Begin
    Status := ExtendFile(FM^.NetMailPath + 'LastRead',
    (UNum + 1) * SizeOf(LRec));
    End;
  If LoadFilePos(FM^.NetMailPath + 'LastRead', LRec, SizeOf(LRec),
  UNum * SizeOf(LRec)) = 0 Then
    Begin
    LRec := LR;
    Status := SaveFilePos(FM^.NetMailPath + 'LastRead', LRec, SizeOf(LRec),
    UNum * SizeOf(LRec));
    End;
  End;


Function FidoMsgObj.GetTxtPos: LongInt;
  Begin
  GetTxtPos := FM^.TextCtr;
  End;


Procedure FidoMsgObj.SetTxtPos(TP: LongInt);
  Begin
  FM^.TextCtr := TP;
  End;


Function FidoMsgObj.MsgBaseExists: Boolean;
  Begin
  MsgBaseExists := FileExist(FM^.NetMailPath + 'Nul');
  End;


Procedure FidoMsgObj.Rescan;
  Var
  {$IFDEF WINDOWS}
    SR: TSearchRec;
    TStr: Array[0..128] of Char;
  {$ELSE}
    SR: SearchRec;
  {$ENDIF}
  TmpName: String[13];
  TmpNum: Word;
  Code: Word;


  Begin
  FillChar(FM^.MsgPresent, SizeOf(FM^.MsgPresent), 0);
  {$IFDEF WINDOWS}
  StrPCopy(TStr, FM^.NetMailPath + '*.MSG');
  FindFirst(TStr, faReadOnly + faArchive, SR);
  {$ELSE}
  FindFirst(FM^.NetMailPath + '*.MSG', ReadOnly + Archive, SR);
  {$ENDIF}
  While DosError = 0 Do
    Begin
    {$IFDEF WINDOWS}
    TmpName :=  StrPas(SR.Name);
    {$ELSE}
    TmpName := SR.Name;
    {$ENDIF}
    Val(Copy(TmpName, 1,  Pos('.', TmpName) - 1), TmpNum, Code);
    If ((Code = 0) And (TmpNum > 0)) Then
      Begin
      If TmpNum <= MaxFidMsgNum Then
        Begin
        Code := TmpNum shr 3; {div by 8 to get byte position}
        FM^.MsgPresent[Code] := FM^.MsgPresent[Code] or PosArray[TmpNum and 7];
        End;
      End;
    FindNext(SR);
    End;
  End;


Function FidoMsgObj.MsgExists(MsgNum: LongInt): Boolean;
  Var
    Code: LongInt;

  Begin
  If ((MsgNum > 0) and (MsgNum <= MaxFidMsgNum)) Then
    Begin
    Code := MsgNum shr 3;
    MsgExists := (FM^.MsgPresent[Code] and PosArray[MsgNum and 7]) <> 0;
    End
  Else
    MsgExists := False;
  End;


End.
