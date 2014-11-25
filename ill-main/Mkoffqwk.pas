Unit MKOffQWK;       {QWK Offline mail Object}

{$I MKB.Def}

{
     MKOffQwk - Copyright 1993 by Mark May - MK Software
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
     Mail0, Mail3,
     MKGlobT, MKMsgAbs, MKOffAbs,
{$IFDEF WINDOWS}
  WinDos;
{$ELSE}
  Dos;
{$ENDIF}


Const QIdxSize = 3000;
Const QwkBufSize = 150;
Const MaxQwkPers = 300;
Const QwkConfs = 2000;

Type QwkIdxType = Record
  QwkPtr: LongInt;
  MsgConf: Byte;
  End;


Type QwkImportRec = Record
  SeekPos: LongInt;
  Area: Word;
  End;


Type QwkRecType = Array[1..128] of Char;
Type QwkBufType = Array[0..QwkBufSize] of QwkRecType;
Type PersArray = Array[1..MaxQwkPers] of QwkIdxType;
Type QwkIdxArray = Array[1..QIdxSize] of QwkIdxType;
Type QwkAreaType = Array[1..QIdxSize] of Word;
Type QwkImportIdx = Array[1..QIdxSize] of QwkImportRec;


Type QwkInfo = Record
  MsgPath: String;
  NumMsgs: Word;
  QwkWorkNum: LongInt;
  PersExported: Word;
  ConfExported: Array[1..QwkConfs] of Word;
  ConfImported: Array[1..QwkConfs] of Boolean;
  NumExported: Word;
  BufStart: LongInt;     {Record number of first record in buffer}
  QwkNumRead: Integer;   {Number of read records in the buffer}
  NeedWritten: Array[0..QwkBufSize] of Boolean; {buffer needs written}
  QwkFile: File;         {QWK/REP file}
  QwkError: Word;        {Status from QWK file activity}
  QwkCurrPos: Word;      {Current char within QwkRec}
  ReplyMsgs: Word;       {number of msgs in reply packet}
  BBSId: String[8];
  End;


Type QwkOffObj = Object(AbsOffObj)
  QwkBuf: ^QwkBufType;   {Qwk record buffer}
  CQwkRec: ^QwkRecType;  {Active Qwk record pointer}
  QI: ^QwkInfo;
  Pers: ^PersArray;
  MsgExport: ^QwkIdxArray;
  QwkArea: ^QwkAreaType;
  QwkIn: ^QwkImportIdx;
  Constructor Init; {Initialize}
  Destructor Done; Virtual; {Done}
  Procedure SetPath(MP: String); Virtual; {Set msg path/other info}
  Procedure SetBBSID(ID: String); Virtual; {Set bbs id/filename}
  Function  StartPacket: Word; Virtual; {Do Packet startup tasks}
  Function  ClosePacket: Word; Virtual; {Do Packet finish tasks}
  Function  AddMsg(Var Msg: AbsMsgObj; Area: Word; ToYou: Boolean): Boolean; Virtual;
  Function  GetArchiveName(Packer: Word): String; Virtual;
  Function  GetReplyName: String; Virtual;
  Function  GetExtractSpec: String; Virtual;
  Procedure PutHdrStr(St: String; Loc: Word);
  Procedure PutStr(Var St: String);
  Function  GetHdrStr(Start:Integer; NumChar:Integer):String;
  Procedure PersIdx;
  Procedure DoIdx;
  Procedure DoControl;
  Procedure WriteDoorId;
  Procedure SetNeedWritten(QN: LongInt);
  Procedure FlushQwkBuf;
  Procedure SetCQwkRec(QN: LongInt);
  Procedure BuildIndex; {build index of areas/msgs from rep packet}
  Procedure ImportPacket; Virtual;
  End;


Type QwkOffPtr = ^QwkOffObj;


Implementation


Uses MKString, MKFile, MKDos;


Function Bas2Lng(InValue: LongInt): LongInt;
  Var
    Temp: LongInt;
    Negative: Boolean;
    Expon: Integer;

  Begin
    If InValue And $00800000 <> 0 Then
      Negative := True
    Else
      Negative := False;
    Expon := InValue shr 24;
    Expon := Expon and $ff;
    Temp := InValue and $007FFFFF;
    Temp := Temp or $00800000;
    Expon := Expon - 152;
    If Expon < 0 Then Temp := Temp shr Abs(Expon)
      Else Temp := Temp shl Expon;
    If Negative Then
      Bas2Lng := -Temp
    Else
      Bas2Lng := Temp;
    If Expon = 0 Then
      Bas2Lng := 0;
  End;


Function Lng2Bas(InValue: LongInt): LongInt;
  Var
    Negative: Boolean;
    Expon: LongInt;

  Begin
  If InValue = 0 Then
    Lng2Bas := 0
  Else
    Begin
    If InValue < 0 Then
      Begin
      Negative := True;
      InValue := Abs(InValue);
      End
    Else
      Negative := False;
    Expon := 152;
    If InValue < $007FFFFF Then
      While ((InValue and $00800000) = 0) Do
        Begin
        InValue := InValue shl 1;
        Dec(Expon);
        End
    Else
      While ((InValue And $FF000000) <> 0) Do
        Begin
        InValue := InValue shr 1;
        Inc(Expon);
        End;
    InValue := InValue And $007FFFFF;
    If Negative Then
      InValue := InValue Or $00800000;
    Lng2Bas := InValue + (Expon shl 24);
    End;
  End;


Constructor QwkOffObj.Init;
  Begin
  New(QI);
  End;


Destructor QwkOffObj.Done;
  Begin
  Dispose(QI);
  End;


Procedure QwkOffObj.SetPath(MP: String);
  Begin
  QI^.MsgPath := WithBackSlash(MP);
  End;


Procedure QwkOffObj.SetNeedWritten(QN: LongInt);
  Var
    BC: LongInt;

  Begin
  BC := Qn - QI^.BufStart;
  If ((BC >= 0) and (BC <= QwkBufSize)) Then
    QI^.NeedWritten[BC] := True;
  End;


Procedure QwkOffObj.FlushQwkBuf;
  Var
    i: Integer;

  Begin
  i := QwkBufSize;
  While ((Not QI^.NeedWritten[i]) and (i >= 0)) Do
    Dec(i);
  Inc(i);
  If i > 0 Then
    Begin
    Seek(QI^.QwkFile, QI^.BufStart);
    QI^.QwkError := IoResult;
    If QI^.QwkError = 0 Then
      Begin
      BlockWrite(QI^.QwkFile, QwkBuf^, i);
      QI^.QwkError := IoResult;
      End;
    QI^.BufStart := -3000;
    For i := 0 to QwkBufSize Do
      QI^.NeedWritten[i] := False;
    End;
  End;


Procedure QwkOffObj.SetCQwkRec(QN: LongInt);
  Var
    i: Word;

  Begin
  QI^.QwkError := 0;
  If ((QN >= QI^.BufStart) and (Qn < (QI^.BufStart + QwkBufSize))) Then
    CQwkRec := @QwkBuf^[QN - QI^.BufStart]
  Else
    Begin
    FlushQwkBuf;
    QI^.BufStart := Qn;
    Seek(QI^.QwkFile, QI^.BufStart);
    QI^.QwkError := IoResult;
    If QI^.QwkError = 0 Then
      Begin
      BlockRead(QI^.QwkFile, QwkBuf^, QwkBufSize, QI^.QwkNumRead);
      QI^.QwkError := IoResult;
      End;
    For i := 0 to QwkBufSize Do
      QI^.NeedWritten[i] := False;
    CQwkRec := @QwkBuf^[0];
    End;
  End;


Procedure QwkOffObj.PutHdrStr(St: String; Loc: Word);
  Var
    i: Word;

  Begin
  For i := 1 to Length(St) Do
    CQwkRec^[Loc + i - 1] := St[i];
  End;


Function QwkOffObj.GetHdrStr(Start:Integer; NumChar:Integer):String;
  Var
    TempStr: String;
    I: Integer;
    Count: Integer;

  Begin
  If ((Start + NumChar) > 129) Then
    NumChar := 129 - Start;
  TempStr := '';
  Count := 0;
  I := Start;
  While Count < NumChar Do
    Begin
    TempStr[Count + 1] := CQwkRec^[Start + Count];
    Inc(Count);
    End;
  TempStr[0] := Chr(NumChar);
  GetHdrStr := TempStr;
  End;



Procedure QwkOffObj.PutStr(Var St: String);
  Var
    i: Word;

  Begin
  For i := 1 to Length(St) Do
    Begin
    Inc(QI^.QwkCurrPos);
    If QI^.QwkCurrPos > 128 Then
      Begin
      Inc(QI^.QwkWorkNum);
      QI^.QwkCurrPos := 1;
      SetCQwkRec(QI^.QwkWorkNum);
      SetNeedWritten(QI^.QwkWorkNum);
      End;
    CQwkRec^[QI^.QwkCurrPos] := St[i];
    End;
  End;



Function QwkOffObj.AddMsg(Var Msg: AbsMsgObj; Area: Word; ToYou: Boolean): Boolean;
  Const
    StrLen = 72;

  Var
    TmpStr: String;
    i: Word;
    MsgStartQwk: LongInt;
    Crc: LongInt;
    TAddr: AddrType;

  Begin
  If QI^.NumExported < QIdxSize Then
    Begin
    Inc(QI^.QwkWorkNum);
    SetCQwkRec(QI^.QwkWorkNum);
    MsgStartQwk := QI^.QwkWorkNum;
    If ((ToYou) and (QI^.PersExported < MaxQwkPers)) Then
      Begin
      Inc(QI^.PersExported);
      Pers^[QI^.PersExported].MsgConf := Area and $ff;
      Pers^[QI^.PersExported].QwkPtr := MsgStartQwk;
      End;
    Inc(QI^.NumExported);
    Inc(QI^.ConfExported[Area]);
    MsgExport^[QI^.NumExported].QwkPtr := MsgStartQwk;
    MsgExport^[QI^.NumExported].MsgConf := Area and $ff;
    QwkArea^[QI^.NumExported] := Area;
    SetNeedWritten(QI^.QwkWorkNum);
    QI^.QwkCurrPos := 129;
    FillChar(CQwkRec^, SizeOf(QwkRecType), ' ');
    If Msg.IsRcvd Then
      Begin
      If Msg.IsPriv Then
        CQwkRec^[1] := '*'
      Else
        CQwkRec^[1] := '-'
      End
    Else
      Begin
      If Msg.IsPriv Then
        CQwkRec^[1] := '+'
      Else
        CQwkRec^[1] := ' '
      End;
    TmpStr := PadRight(Copy(Long2Str(Msg.GetMsgNum),1,7),' ',7); {msg num}
    PutHdrStr(TmpStr, 2);
    PutHdrStr(Msg.GetDate, 9);
    PutHdrStr(Copy(Msg.GetTime, 1, 5), 17);
    PutHdrStr(Upper(Copy(Msg.GetTo, 1, 25)), 22);
    PutHdrStr(Upper(Copy(Msg.GetFrom, 1, 25)), 47);
    If (private in MemBoard.BaseStat) and
       (networked in MemBoard.BaseStat) Then
      Begin
      Msg.GetOrig(TAddr);
      PutHdrStr('@' + AddrStr(TAddr),72);
      End
    Else
      PutHdrStr(Copy(Msg.GetSubj, 1, 25), 72);
    PutHdrStr(PadRight(Copy(Long2Str(Msg.GetRefer),1,8),' ',8), 109);
    CQwkRec^[123] := #225;
    CQwkRec^[124] := Chr(Lo(Area));
    CQwkRec^[125] := Chr(Area shr 8);
    CQwkRec^[128] := ' ';
    Msg.MsgTxtStartUp;
    If (private in MemBoard.BaseStat) and
       (networked in MemBoard.BaseStat) Then
      Begin
      TmpStr := 'Subj: ' + Msg.GetSubj;
      PutStr(TmpStr);
      End;
    TmpStr := Msg.GetString(StrLen);
    TmpStr[0] := Chr(Length(TmpStr) + 1);
    TmpStr[Length(TmpStr)] := #227;
    While (Not Msg.EOM) or (Length(TmpStr) > 1) Do
      Begin
      If (TmpStr[1] <> #1) Then
        PutStr(TmpStr);
      TmpStr := Msg.GetString(StrLen);
      TmpStr[0] := Chr(Length(TmpStr) + 1);
      TmpStr[Length(TmpStr)] := #227;
      End;
    If QI^.QwkCurrPos < 128 Then
      Begin
      For i := QI^.QwkCurrPos + 1 to 128 Do
      CQwkRec^[i] := ' ';
      End;
    SetCQwkRec(MsgStartQwk);
    PutHdrStr(PadRight(Long2Str(QI^.QwkWorkNum + 1 - MsgStartQwk),' ',6),117);
    SetNeedWritten(MsgStartQwk);
    SetCQwkRec(QI^.QwkWorkNum);
    AddMsg := True;
    End
  Else
    AddMsg := False;
  End;


Function QwkOffObj.GetArchiveName(Packer: Word): String;
  Begin
  GetArchiveName := QI^.BBSID + '.QWK';
  End;


Procedure QwkOffObj.PersIdx;
  Var
    i: Word;
    PersFile: File;

  Begin
  If QI^.PersExported > 0 Then
    Begin
    For i := 1 to QI^.PersExported Do
      Pers^[i].QwkPtr := Lng2Bas(Pers^[i].QwkPtr + 1);
    Assign(PersFile, QI^.MsgPath + 'PERSONAL.NDX');
    ReWrite(PersFile, 5);
    BlockWrite(PersFile, Pers^, QI^.PersExported);
    Close(PersFile);
    If IoResult <> 0 Then;
    End;
  End;



Procedure QwkOffObj.WriteDoorId;
  Var
    CFile: Text;
    i: Word;
    Ext: String[4];
    TempStr: String;

  Begin
  If IoResult <> 0 Then;
  Assign (CFile, QI^.MsgPath + 'DOOR.ID');
  ReWrite(CFile);
  WriteLn(CFile, 'DOOR = Illusion/MKQwk');
  WriteLn(CFile, 'VERSION = 1.1');
  WriteLn(CFile, 'SYSTEM = Illusion '+ver);
  WriteLn(CFile, 'CONTROLNAME = IQWK');
  WriteLn(CFile, 'CONTROLTYPE = ADD');
  WriteLn(CFile, 'CONTROLTYPE = DROP');
  WriteLn(CFile, 'CONTROLTYPE = RESET');
  Writeln(CFile, 'RECEIPT');
  Close(CFile);
  If IoResult <> 0 Then;
  End;


Procedure QwkOffObj.DoControl;
  Var
    CF: Text;
    NumAvail: Word;
    i: Word;
    Temp: String;

  Begin
  If IoResult <> 0 Then;
  FileMode := fmReadWrite + fmDenyNone;
  Assign(CF, QI^.MsgPath + 'Control.Dat');
  ReWrite(CF);
  If IoResult <> 0 Then;
  WriteLn(CF, Systat^.BBSName);
  WriteLn(CF, Systat^.BBSLocation);
  WriteLn(CF, Systat^.BBSPhone);
  WriteLn(CF, Upper(Systat^.SysopName) + ',Sysop');
  WriteLn(CF, '0 ,' + Systat^.QwkFileName);
  WriteLn(CF, FormattedDosDate(GetDosDate,'MM-DD-YYYY,') + TimeStr(GetDosDate));
  WriteLn(CF, Upper(ThisUser.Name));
  WriteLn(CF);
  WriteLn(CF,'0');
  WriteLn(CF,'0');
  NumAvail := 0;
  For i := 0 to numboards Do
    Begin
    If mbaseac(i) or (mbVisible in MemBoard.mbStat) then
      Inc(NumAvail);
    End;
  WriteLn(CF,NumAvail);
  WriteLn(CF, '0');
  WriteLn(CF, '0');
  For i := 0 to numboards Do
    Begin
    If mbaseac(i) or (mbVisible in MemBoard.mbStat) Then
      Begin
      WriteLn(CF, memboard.permindx);
      WriteLn(CF, MemBoard.QwkName);
      End;
    End;
  WriteLn(CF, Systat^.QwkWelcome);
  WriteLn(CF, Systat^.QwkNews);
  WriteLn(CF, Systat^.QwkGoodbye);
  {** Extended information **}
  Writeln(CF, '0');
  Writeln(CF, ThisUser.PageLen);
  Writeln(CF, Upper(ThisUser.Name));
  Writeln(CF, Caps(copy(ThisUser.RealName,1,pos(' ',ThisUser.RealName)-1)));
  Writeln(CF, Upper(ThisUser.CityState));
  Temp := ThisUser.Ph;
  Temp[4] := ' ';
  Writeln(CF, Temp);
  Writeln(CF, Temp);
  Writeln(CF, ThisUser.SL);
  Writeln(CF, '00-00-00');
  Temp := ThisUser.Laston;
  Temp[3] := '-';
  Temp[6] := '-';
  Writeln(CF, Temp);
  Temp := Time;
  Temp[0] := #5;
  Writeln(CF, Temp);
  Writeln(CF, ThisUser.LoggedOn);
  Writeln(CF, ThisUser.LastMsg);
  Writeln(CF, ThisUser.Dk);
  Writeln(CF, ThisUser.Downloads);
  Writeln(CF, ThisUser.Uk);
  Writeln(CF, ThisUser.Uploads);
  Writeln(CF, Systat^.TimeAllow[ThisUser.SL]);
  Writeln(CF, Trunc(nsl / 60)); { minutes remaining }
  Writeln(CF, Systat^.TimeAllow[ThisUser.SL] - (Trunc(nsl / 60))); { minutes used this call }
  Writeln(CF, '32767');
  Writeln(CF, '32767');
  Writeln(CF, '0');
  Writeln(CF, Temp); { Temp still has the current time }
  Temp := Date;
  Temp[3] := '-';
  Temp[6] := '-';
  Writeln(CF, Temp);
  Writeln(CF, Systat^.BBSName);
  Writeln(CF, '0');
  If IoResult <> 0 Then;
  Close(CF);
  If IoResult <> 0 Then;
  End;


Procedure QwkOffObj.DoIdx;
  Var
    i: Word;
    IdxPointer: Word;
    OrgPointer: Word;
    IdxFile: File;
    FileStr: String;
    QwkIdx: ^QwkIdxArray;

  Begin
  If QI^.PersExported > 0 Then
    PersIdx;
  New(QwkIdx);
  If QwkIdx <> Nil Then
    Begin
    For i := 1 to QwkConfs do
      Begin
      If QI^.ConfExported[i] > 0 Then
        Begin
        IdxPointer := 0;
        FileStr := ConCat(QI^.MsgPath, PadLeft(Long2Str(i),'0',3),'.NDX');
        Assign(IdxFile, FileStr);
        ReWrite(IdxFile,SizeOf(QwkIdxType));
        For OrgPointer := 1 to QI^.NumExported Do
          Begin
          If QwkArea^[OrgPointer] = i Then
            Begin
            Inc(IdxPointer);
            QwkIdx^[IdxPointer].MsgConf := i and $ff;
            QwkIdx^[IdxPointer].QwkPtr := Lng2Bas(MsgExport^[OrgPointer].QwkPtr + 1);
            End;
          End;
        BlockWrite(IdxFile, QwkIdx^, IdxPointer);
        Close(IdxFile);
        If Ioresult <> 0 Then;
        End;
      End;
    Dispose(QwkIdx);
    End;
  End;



Function QwkOffObj.StartPacket: Word;
  Var
    i: Word;
    QError: Word;

  Begin
  New(QwkBuf);
  New(Pers);
  New(MsgExport);
  New(QwkArea);
  If (QwkBuf=Nil) or (QI=Nil) or (Pers=Nil) or (MsgExport=Nil) or (QwkArea=Nil) Then
    QError := 1000
  Else
    QError := 0;
  IF QError = 0 Then
    Begin
    QI^.PersExported := 0;
    Assign(QI^.QwkFile, QI^.MsgPath + 'Messages.Dat');
    ReWrite(QI^.QwkFile, 128);
    If IoResult <> 0 Then
      QError := 1001;
    End;
  If QError = 0 Then
    Begin
    QI^.BufStart := -1000;
    QI^.QwkNumRead := 0;
    For i := 0 to QwkBufSize Do
    QI^.NeedWritten[i] := False;
    QI^.QwkWorkNum := 0;
    SetCQwkRec(QI^.QwkWorkNum);
    FillChar(CQwkRec^, SizeOf(QwkRecType), ' ');
    PutHdrStr('Produced by Illusion BBS System (Copyright by Kyle Oppenheim and Billy Ma) '+
              'and Mythical Kingdom Software (Copyright Mark May)', 1);
    SetNeedWritten(0);
    For i := 1 to QwkConfs Do
      QI^.ConfExported[i] := 0;
    QI^.NumExported := 0;
    End;
  StartPacket :=  QError;
  End;


Function QwkOffObj.ClosePacket: Word;
  Begin
  FlushQwkBuf;
  Close(QI^.QwkFile);
  ClosePacket := IoResult;
  DoIdx;
  DoControl;
  WriteDoorId;
  Dispose(Pers);
  Dispose(QwkArea);
  Dispose(MsgExport);
  Dispose(QwkBuf);
  End;


Function QwkOffObj.GetReplyName: String;
  Begin
  GetReplyName := QI^.BBSID + '.REP';
  End;


Function QwkOffObj.GetExtractSpec: String;
  Begin
  GetExtractSpec := QI^.BBSID + '.MSG';
  End;


Procedure QwkOffObj.BuildIndex;
  Type CharSet = Set of Char;
  Var
    i,j: Word;
    MaxNum: LongInt;
    NumBlocks: LongInt;
    LastMsgEnd: LongInt;
    QwkWorkNum: LongInt;
    Smallest: Word;
    Temp: QwkImportRec;

  Const
    DateSep = ['-','/', #196];

  Begin
  LastMsgEnd := 0;
  QI^.ReplyMsgs := 0;
  For i := 0 To QwkConfs Do
    QI^.ConfImported[i] := False;
  MaxNum := FileSize(QI^.QwkFile);
  QwkWorkNum := 1;
  While (QwkWorkNum < MaxNum) Do
    Begin
    SetCQwkRec(QwkWorkNum);
    If ((CQwkRec^[11] in DateSep) and (CQwkRec^[14] in DateSep) and
    (CQwkRec^[19] = ':') and (CQwkRec^[123] = #225)) Then
      Begin
      Inc(QI^.ReplyMsgs);
      QwkIn^[QI^.ReplyMsgs].Area := Ord(CQwkRec^[124]);
      If CQwkRec^[125] <> ' ' Then
      Inc(QwkIn^[QI^.ReplyMsgs].Area, (Word(Ord(CQwkRec^[125])) * 256));
      Dec(QwkIn^[QI^.ReplyMsgs].Area);
      QI^.ConfImported[QwkIn^[QI^.ReplyMsgs].Area] := True;
      QwkIn^[QI^.ReplyMsgs].SeekPos := QwkWorkNum;
      NumBlocks := Str2Long(StripBoth(GetHdrStr(117, 6),' '));
      If NumBlocks < 1 Then
        NumBlocks := 1;
      Inc(QwkWorkNum, NumBlocks);
      LastMsgEnd := QwkWorkNum - 1;
      End
    Else
      Begin
      NumBlocks := 1;
      Inc(QwkWorkNum, NumBlocks);
      End;
    End;

  {** Sort index **}
  For i := 1 To (QI^.ReplyMsgs-1) Do
    Begin
      Smallest := i;
      For j := (i+1) To QI^.ReplyMsgs Do
      Begin
        If QwkIn^[j].Area < QwkIn^[Smallest].Area Then
          Smallest := j
        Else
          If (QwkIn^[j].Area = QwkIn^[Smallest].Area) and
             (QwkIn^[j].SeekPos < QwkIn^[Smallest].SeekPos) Then
            Smallest := j;
      End;
      If Smallest <> i Then
        Begin
          Temp := QwkIn^[i];
          QwkIn^[i] := QwkIn^[Smallest];
          QwkIn^[Smallest] := Temp;
        End;
    End;
  End;

Function RealBase(var bb:word):boolean;
var i:integer;
    brd:boardrec;
begin
  SetFileAccess(ReadWrite,DenyNone);
  reset(bf);
  for i:=1 to filesize(bf) do begin
    seek(bf,i-1); read(bf,brd);
    if brd.permindx=bb then begin
      bb:=i;
      close(bf);
      RealBase:=TRUE;
      exit;
    end;
  end;
  realbase:=FALSE;
  close(bf);
end;

Function LoadBoardByPermIdx(b:word):Boolean;
begin
  if RealBase(b) then
    LoadBoardByPermIdx:=LoadBoard(b)
  else
    LoadBoardByPermIdx:=FALSE;
end;

{  Bugs:
     o Mail forwarding not taken into account
     o Mailbox settings (closed, full, etc.) not taken
       into account
}

Procedure QwkOffObj.ImportPacket;
  Var
    QError: Word;
    CurrArea: Word;             { Current area processing }
    CMsg: AbsMsgPtr;            { Current message }
    IPos: Word;                 { Current position in index }
    NumBlocks: LongInt;         { Number of blocks in this message }
    BlocksRead: LongInt;        { Blocks read so far }
    NumThisArea,                { Number of msgs processed in this area }
    NumThisPkt: Word;           { Total number of messages processed. }
    i: Word;                    { Temp. loop variable }
    TStr: String;               { Temp. String }
    TCurrPos: Byte;             { Current position in string, during msg read }
    OrigAddr:AddrType;
    SemaFile: File;

  Begin
  New(QwkIn);
  New(QwkBuf);
  { // Initialize Buffer since we aren't using StartPacket }
  QI^.BufStart := -1000;

  If (QwkIn=Nil) Then
    QError := 1000
  Else
    QError := 0;
  If QError = 0 Then
    Begin
    Assign(QI^.QwkFile, QI^.MsgPath + GetExtractSpec);
    Reset(QI^.QwkFile, 128);
    If IoResult <> 0 Then
      QError := 1001;
    End;
  If QError = 0 Then
    Begin

    SetCQwkRec(0);
    If (StripBoth(GetHdrStr(1,8),' ') <> QI^.BBSId) Then
      Begin
      Sprint('This packet has a BBS identification that does not');
      Sprint('match the identication of this BBS.  You may have');
      Sprint('uploaded the wrong packet.');
      If pynq('Toss this packet anyway') Then
        QError := 0
      Else
        QError := 1002;
      End;
     End;

  If QError = 0 Then
    Begin
    Sprint('Generating and sorting index...');
    BuildIndex;
    Sprint(cstr(QI^.ReplyMsgs)+' messages indexed.  Tossing...');

    {** toss mail **}
    NumThisPkt := 0;
    CurrArea := 0;
    IPos := 1;
    readsystat; { Get current vars }

    While (CurrArea <= numboards) Do
      Begin
      NumThisArea := 0;
      While (IPos <= QI^.ReplyMsgs) and (QwkIn^[IPos].Area <= CurrArea) Do
        Begin
        If (QwkIn^[IPos].Area = CurrArea) Then
          If LoadBoardByPermIdx(CurrArea) Then
            If (CheckPostAccess = 0) Then
              If OpenOrCreateMsgArea(CMsg, MemBoard.MsgAreaID,
                           MemBoard.MaxMsgs, MemBoard.MaxDays) Then
                Begin

                sprompt(mn(MemBoard.PermIndx,3)+' '+
                   mln(MemBoard.Name,38)+' '+
                   mln(MemBoard.QWKname,12)+' '+
                   '   0');

                { // Loop through the rest of messages in this area }
                { // This eliminates the need to constantly check }
                { // for access an open the message area. }

                While (QwkIn^[IPos].Area = CurrArea) Do Begin

                  SetCQwkRec(QwkIn^[IPos].SeekPos);

                  { check allowed to post priv here (MoreMail, etc.) }

                  CMsg^.StartNewMsg;
                  CMsg^.SetCost(0);
                  CMsg^.SetDate(ReformatDate(GetHdrStr(9,8),'MM-DD-YY'));
                  CMsg^.SetTime(GetHdrStr(17,5)+':00');
                  CMsg^.SetLocal(TRUE);
                  CMsg^.SetRcvd(FALSE);
                  CMsg^.SetTo(StripBoth(GetHdrStr(22,25),' '));
                  CMsg^.SetFrom(StripBoth(GetHdrStr(47,25),' '));
                  TStr := StripTrail(GetHdrStr(72,25),' ');
                  If Upper(Copy(TStr,1,3))='RRR' Then
                    Begin
                    Delete(TStr,1,3);
                    If (Private in MemBoard.BaseStat) Then
                      If (TStr<>'All') then
                        CMsg^.SetReqRct(TRUE)
                      Else
                        CMsg^.SetReqRct(FALSE)
                    Else
                      CMsg^.SetReqRct(FALSE);
                    End;
                  CMsg^.SetSubj(TStr);
                  If Private in MemBoard.BaseStat Then
                    Begin
                    If (CMsg^.GetSubj<>'All') Then
                      CMsg^.SetPriv(TRUE)
                    Else
                      CMsg^.SetPriv(FALSE);
                    If Networked in MemBoard.BaseStat Then
                      CMsg^.SetKillSent(TRUE)
                    Else
                      CMsg^.SetKillSent(FALSE);
                    End;
                  CMsg^.SetCrash(FALSE);
                  CMsg^.SetSent(FALSE);
                  CMsg^.SetReqAud(FALSE);
                  CMsg^.SetRetRct(FALSE);
                  CMsg^.SetFileReq(FALSE);
                  CMsg^.SetEcho(TRUE);
                  CMsg^.SetRefer(Value(StripBoth(GetHdrStr(109,8),' ')));
                  CMsg^.DoKludgeLn(#1'USERNOTE: '+ThisUser.Usernote);
                  CMsg^.DoKludgeLn(#1'MCI: '+aonoff(aacs(MemBoard.mciAcs),'ON','OFF'));
                  NumBlocks := Str2Long(StripBoth(GetHdrStr(117, 6),' '));
                  BlocksRead := 1;

                  TCurrPos := 0;
                  While BlocksRead < NumBlocks Do
                    Begin
                    SetCQwkRec(QwkIn^[IPos].SeekPos + BlocksRead);
                    QI^.QwkCurrPos := 1;
                    While QI^.QwkCurrPos <= 128 Do
                      Begin
                      If CQwkRec^[QI^.QwkCurrPos] <> #227 Then
                        Begin
                        Inc(TCurrPos);
                        TStr[TCurrPos] := CQwkRec^[QI^.QwkCurrPos];
                        End
                      Else
                        Begin
                        TStr[0] := Chr(TCurrPos);
                        CMsg^.DoStringLn(StripThings(TStr));
                        TCurrPos := 0;
                        End;
                      Inc(QI^.QwkCurrPos);
                    End;
                    Inc(BlocksRead);
                  End;

                  If networked in MemBoard.BaseStat Then
                    Begin
                    Move(Systat^.aka[Memboard.aka],OrigAddr,sizeof(OrigAddr));
                    CMsg^.DoStringLn('');
                    CMsg^.DoStringLn('--- Illusion v'+ver);
                    CMsg^.DoStringLn(' * Origin: '+getorigin+' ('+addrstr(OrigAddr)+')');
                    End;

                  If (CMsg^.WriteMsg=0) then begin
                    sysoplog('+ "'+CMsg^.GetSubj+'" posted on '+memboard.name);
                    If (CMsg^.GetTo<>'') Then sysoplog('  To: "'+CMsg^.GetTo+'"');
                    If networked in MemBoard.BaseStat Then
                      Begin
                      assign(SemaFile,start_dir+'\ISCAN.NOW');
                      rewrite(SemaFile); Close(SemaFile);
                      End;

                    If private in MemBoard.BaseStat Then
                      Begin
                      inc(thisuser.emailsent);
                      inc(etoday);
                      inc(systat^.todayzlog.privpost);
                      End
                    Else
                      If public in MemBoard.BaseStat Then Begin
                        inc(thisuser.msgpost);
                        inc(ptoday);
                        readsystat;
                        inc(systat^.todayzlog.pubpost);
                        savesystat;
                        if not (rvalidate in thisuser.ac) then
                        inc(thisuser.filepoints,systat^.postcredits);
                      End;
                    Inc(NumThisArea);
                    Inc(NumThisPkt);
                  End; {if writemsg}
                  Inc(IPos);
                End; {While Area=CurrArea, single message}

              CloseMsgArea(CMsg);
              { // IPos incremented once too many times in above loop }
              { // to satisfy exit condition.  Need to decrement it   }
              Dec(IPos);
              End; {If OpenMsgArea / Area=CurrArea, single area}
        Inc(IPos);
        For i:=1 to 4 do prompt(^H);
        sprompt(PadLeft(Long2Str(NumThisArea),' ', 4));
        lil:=0; nl; { don't let the screen pause }
        End; {while Area <= CurrArea, all msgs in this area}
      inc(CurrArea);
      End; {while}

    {** End toss mail **}
    sprint('Tossed '+cstr(NumThisPkt)+' messages.');
    End; {Error Check}

    (* File may not be open... so turn off IO checking *)
    (* Could use better error checking, but no need.   *)
    {$I-} Close(QI^.QwkFile); {$I+}
    If IoResult <> 0 Then;

    Dispose(QwkIn);
    Dispose(QwkBuf);
    SaveSystat;
  End;


Procedure QwkOffObj.SetBBSId(ID: String);
  Begin
  QI^.BBSId := Id;
  End;


End.
