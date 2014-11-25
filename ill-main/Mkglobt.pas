Unit MKGlobT;

{$I MKB.Def}

Interface

{
     MKGlobT - Copyright 1993 by Mark May - MK Software
     You are free to use this code in your programs, however
     it may not be included in Source/TPU function libraries
     without my permission.

     Mythical Kingom Tech BBS (513)237-7737 HST/v32
     FidoNet: 1:110/290
     Rime: ->MYTHKING
     You may also reach me at maym@dmapub.dma.org
}


Uses
  {$IFDEF WINDOWS}
  WinDos;
  {$ELSE}
  Dos {$IFDEF OS2} ,use32 {$ENDIF} ;
  {$ENDIF}

Type AddrType = Record                 {Used for Fido style addresses}
  Zone: Word;
  Net: Word;
  Node: Word;
  Point: Word;
  End;

Type MKDateType = Record
  Year: Word;
  Month: Word;
  Day: Word;
  End;

Type MKDateTime = Record
  Year: Word;
  Month: Word;
  Day: Word;
  Hour: Word;
  Min: Word;
  Sec: Word;
  End;

Function  AddrStr(Addr: AddrType): String;
Function  PointlessAddrStr(Var Addr: AddrType): String;
Function  ParseAddr(AStr: String; CurrAddr: AddrType; Var DestAddr: AddrType): Boolean;
Function  IsValidAddr(Addr: AddrType): Boolean;
Function  ValidMKDate(DT: MKDateTime): Boolean;
{$IFDEF WINDOWS}
Procedure DT2MKDT(Var DT: TDateTime; Var DT2: MKDateTime);
Procedure MKDT2DT(Var DT: MKDateTime; Var DT2: TDateTime);
{$ELSE}
Procedure DT2MKDT(Var DT: DateTime; Var DT2: MKDateTime);
Procedure MKDT2DT(Var DT: MKDateTime; Var DT2: DateTime);
{$ENDIF}
Procedure Str2MKD(St: String; Var MKD: MKDateType);
Function MKD2Str(MKD: MKDateType): String;
Function AddrEqual(Addr1: AddrType; Addr2: AddrType):Boolean;

Implementation

Uses MKString, Crc32, MKMisc;

Function AddrStr(Addr: AddrType): String;
  Begin
  If Addr.Point = 0 Then
    AddrStr := Long2Str(Addr.Zone) + ':' + Long2Str(Addr.Net) + '/' +
      Long2Str(Addr.Node)
  Else
    AddrStr := Long2Str(Addr.Zone) + ':' + Long2Str(Addr.Net) + '/' +
      Long2Str(Addr.Node) + '.' + Long2Str(Addr.Point);
  End;


Function PointlessAddrStr(Var Addr: AddrType): String;
  Begin
  PointlessAddrStr := Long2Str(Addr.Zone) + ':' + Long2Str(Addr.Net) + '/' +
      Long2Str(Addr.Node);
  End;


Function ParseAddr(AStr: String; CurrAddr: AddrType; Var DestAddr: AddrType): Boolean;
  Var
    SPos: Word;
    EPos: Word;
    TempStr: String;
    Code: Word;
    BadAddr: Boolean;

  Begin
  BadAddr := False;
  AStr := StripBoth(Upper(AStr), ' ');
  EPos := Length(AStr);
  {thanks for the fix domain problem to Ryan Murray @ 1:153/942}
  Code := Pos('@', AStr);
  If Code > 0 then
    Delete(Astr, Code, Length(Astr) + 1 - Code);
  SPos := Pos(':',AStr) + 1;
  If SPos > 1 Then
    Begin
    TempStr := StripBoth(Copy(AStr,1,Spos - 2), ' ');
    Val(TempStr,DestAddr.Zone,Code);
    If Code <> 0 Then
      BadAddr := True;
    AStr := Copy(AStr,Spos,Length(AStr));
    End
  Else
    DestAddr.Zone := CurrAddr.Zone;
  SPos := Pos('/',AStr) + 1;
  If SPos > 1 Then
    Begin
    TempStr := StripBoth(Copy(AStr,1,Spos - 2), ' ');
    Val(TempStr,DestAddr.Net,Code);
    If Code <> 0 Then
      BadAddr := True;
    AStr := Copy(AStr,Spos,Length(AStr));
    End
  Else
    DestAddr.Net := CurrAddr.Net;
  EPos := Pos('.', AStr) + 1;
  If EPos > 1 Then
    Begin
    TempStr := StripBoth(Copy(AStr,EPos,Length(AStr)), ' ');
    Val(TempStr,DestAddr.Point,Code);
    If Code <> 0 Then
      DestAddr.Point := 0;
    AStr := Copy(AStr,1,EPos -2);
    End
  Else
    DestAddr.Point := 0;
  TempStr := StripBoth(AStr,' ');
  If Length(TempStr) > 0 Then
    Begin
    Val(TempStr,DestAddr.Node,Code);
    If Code <> 0 Then
      BadAddr := True;
    End
  Else
    DestAddr.Node := CurrAddr.Node;
  ParseAddr := Not BadAddr;
  End;


{$IFDEF WINDOWS}
Procedure DT2MKDT(Var DT: TDateTime; Var DT2: MKDateTime);
{$ELSE}
Procedure DT2MKDT(Var DT: DateTime; Var DT2: MKDateTime);
{$ENDIF}

  Begin
  DT2.Year := DT.Year;
  DT2.Month := DT.Month;
  DT2.Day := DT.Day;
  DT2.Hour := DT.Hour;
  DT2.Min := DT.Min;
  DT2.Sec := DT.Sec;
  End;


{$IFDEF WINDOWS}
Procedure MKDT2DT(Var DT: MKDateTime; Var DT2: TDateTime);
{$ELSE}
Procedure MKDT2DT(Var DT: MKDateTime; Var DT2: DateTime);
{$ENDIF}

  Begin
  DT2.Year := DT.Year;
  DT2.Month := DT.Month;
  DT2.Day := DT.Day;
  DT2.Hour := DT.Hour;
  DT2.Min := DT.Min;
  DT2.Sec := DT.Sec;
  End;


Function  ValidMKDate(DT: MKDateTime): Boolean;
  Var
    {$IFDEF WINDOWS}
    DT2: TDateTime;
    {$ELSE}
    DT2: DateTime;
    {$ENDIF}

  Begin
  MKDT2DT(DT, DT2);
  ValidMKDate := ValidDate(DT2);
  End;


Procedure Str2MKD(St: String; Var MKD: MKDateType);
  Begin
  FillChar(MKD, SizeOf(MKD), #0);
  MKD.Year := Str2Long(Copy(St, 7, 2));
  MKD.Month := Str2Long(Copy(St, 1, 2));
  MKD.Day := Str2Long(Copy(St, 4, 2));
  If MKD.Year < 80 Then
    Inc(MKD.Year, 2000)
  Else
    Inc(MKD.Year, 1900);
  End;


Function MKD2Str(MKD: MKDateType): String;
  Begin
  MKD2Str := PadLeft(Long2Str(MKD.Month),'0',2) + '-' +
             PadLeft(Long2Str(MKD.Day), '0',2) + '-' +
             PadLeft(Long2Str(MKD.Year Mod 100), '0', 2);
  End;


Function AddrEqual(Addr1: AddrType; Addr2: AddrType):Boolean;
  Begin
  AddrEqual := ((Addr1.Zone = Addr2.Zone) and (Addr1.Net = Addr2.Net)
    and (Addr1.Node = Addr2.Node) and (Addr1.Point = Addr2.Point));
  End;



Function  IsValidAddr(Addr: AddrType): Boolean;
  Begin
  IsValidAddr := not (Addr.Zone = 0);
  End;


End.
