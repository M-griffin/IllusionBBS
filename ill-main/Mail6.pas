(*****************************************************************************)
(* Illusion BBS - Mail functions [6/?]                                       *)
(*****************************************************************************)

Unit Mail6;
{$I MKB.DEF}

Interface

Uses common, mail0, mail2, mail3, execbat,
     MsgF; { CopyFile, Send1, Receive1 }
     

Procedure MakeQWK;
Procedure TossREP;

Implementation


Uses MkString, MkMsgAbs, MkOffAbs, MkOffQwk;


Function GetMaxMsgs:Word;
Begin
  GetMaxMsgs := 1000;
End;

Function GetAreaMaxMsgs:Word;
Begin
  GetAreaMaxMsgs := 500;
End;

Procedure GetOffType(Var OffType: AbsOffPtr);
Begin
  OffType := New(QwkOffPtr, Init);
End;


Procedure MakeQWK;
  Const
    MaxQwkAreas = 1000;
  Var
    WorkPath: String[128];      { Temp work directory }
    Offline: AbsOffPtr;         { Offline mailer object }
    CurrArea: Word;             { Current area processing }
    CMsg: AbsMsgPtr;            { Current message }
    NewLastRead: Array[0..MaxQwkAreas-1] of LongInt; { Last read pointers }
    NumThisArea,                { Number of msgs processed in this area }
    NumThisPkt: Word;           { Total number of messages processed. }
    Done: Boolean;
    Next: Boolean;              { goto next area? }
    ToYou,                      { Is this message to user? }
    FromYou: Boolean;           { Is this message from user? }
    MaxMsgs: Word;              { Max total msgs }
    AreaMax: Word;              { Max msgs in this area }
    Ok: Boolean;                { ok to continue? }
    NoSpace: Boolean;           { Not enough space to copy file }
    kabort: Boolean;            { For file transfer }
    RetLevel: Integer;          { Errorlevel returned from compression }
    Fil: File;                  { File to get packet info from }
    i: Word;                    { loop variable }
    s: astr;                    { temp string }
    UpdateTimer: Real;          { Time of last screen update }
    OldBoard: Word;             { Old message board }
    OldConf: Char;              { Old conference }
    OldFileBoard: Integer;      { Old file board }
    QwkStart,QwkEnd,TookTime: datetimerec;

Begin
  Cls;
  sprint('Illusion Offline Mail System');
  nl;

  OldBoard := Board;
  OldConf := ThisUser.Conference;
  ThisUser.Conference := '@'; { Switch to global msg conference }
  GetDateTime(QwkStart);

  { Initialize new lastread pointers to -1 }
  FillChar(NewLastRead, sizeof(NewLastRead), 0);

  MaxMsgs := GetMaxMsgs;
  AreaMax := GetAreaMaxMsgs;
  Next := False;
  Ok := True;
  Offline := nil;
  GetOffType(Offline);
  If Offline = nil Then
    ok := False;

  If Ok Then Begin
    Offline^.SetBBSID(Systat^.QwkFileName);
    WorkPath := Modemr^.TempPath+'QWK\';
    Offline^.SetPath(WorkPath);
    PurgeDir2(WorkPath);
    If Offline^.StartPacket <> 0 Then
      Ok := False;
  End;

  NumThisPkt := 0;
  CurrArea := 0;

  If Ok Then Begin
    Done := False;
    While ((CurrArea <= numboards) and (not Done) and (not hangup)) do Begin
      If mbaseac(currarea) Then Begin
        LoadMsgZScan;
        If MsgZScan.QwkScan Then Begin
          NumThisArea := 0;
          If OpenMsgArea(CMsg, MemBoard.MsgAreaID) Then Begin

            sprompt(mn(MemBoard.PermIndx,3)+' '+
                   mln(MemBoard.Name,38)+' '+
                   mln(MemBoard.QWKname,12)+' '+
                   mn(CMsg^.GetLastRead(usernum),5)+' '+
                   '   0');
            UpdateTimer := Timer;

            CMsg^.SeekFirst(CMsg^.GetLastRead(usernum) + 1);
            While (CMsg^.SeekFound and (Not Done) and (NumThisArea < AreaMax)
              and (not hangup) and (not next)) Do Begin
              CMsg^.MsgStartUp;
              FromYou := (Upper(CMsg^.GetFrom) = ThisUser.Name)
                or (Upper(CMsg^.GetFrom) = Upper(ThisUser.RealName));
              ToYou := (Upper(CMsg^.GetTo) = ThisUser.Name)
                or (Upper(CMsg^.GetTo) = Upper(ThisUser.RealName));
              If (Not CMsg^.IsPriv) or ToYou or FromYou then begin
                NewLastRead[CurrArea] := CMsg^.GetMsgNum;
                If Not Offline^.AddMsg(CMsg^, MemBoard.PermIndx, False) Then begin
                  nl;
                  sprint('Error!  Unable to add message.');
                  pausescr;
                  Done := True;
                End;
                Inc(NumThisArea);
                Inc(NumThisPkt);
                If NumThisPkt > MaxMsgs then
                  Done := True;

                if (abs(Timer-UpdateTimer) >= 2.0) then begin
                  For i:=1 to 4 do prompt(^H);
                  sprompt(PadLeft(Long2Str(NumThisArea),' ', 4));
                  UpdateTimer := Timer;
                end;

                wkey(done,next);
              End; {if not priv/toyou/fromyou}
              CMsg^.SeekNext;
            End; {while seekfound}
            If CloseMsgArea(CMsg) Then;
            { Update display one last time before doing next area }
            For i:=1 to 4 do prompt(^H);
            sprompt(PadLeft(Long2Str(NumThisArea),' ', 4));
          End; {if area opened}
          lil:=0; nl; { don't let the screen pause }
        End; {if in newscan}
      End; {if access}
      inc(CurrArea);
    End; {while}
    If Offline^.ClosePacket <> 0 Then Ok := False;
  End; {if ok}

  Dispose(Offline,Done);
  SysOpLog('Made offline mail packet with '+cstr(NumThisPkt)+' messages.');
  nl;
  sprint(cstr(NumThisPkt)+' messages.');

  { // Archive Packet }

  if (NumThisPkt > 0) then begin
    if ok then begin
      ok := FALSE;
      if pynq('Archive this packet') then begin
        nl;
        for i:=1 to 3 do begin
          case i of
            1: s:=systat^.qwkwelcome;
            2: s:=systat^.qwknews;
            3: s:=systat^.qwkgoodbye;
          end; {case}

          if exist(systat^.textpath+s) then
            copyfile(ok,nospace,FALSE,systat^.textpath+s,WorkPath+s);
        end;
        shel('Compressing QWK packet...');
        pexecbatch(FALSE,'iqwktemp.bat','',WorkPath,
          arcmci(systat^.filearcinfo[arctype('BLAH.'+thisuser.qwkarc)].arcline,
            Systat^.QwkFileName+'.QWK',' *.*',''),
          retlevel);
        shel2;
        assign(fil, WorkPath+Systat^.QwkFileName+'.QWK');
        {$I-} reset(fil,1); {$I+}
        if ioresult<>0 then begin
          sprint('Error compressing QWK Packet.'); nl;
        end else begin
          sprint('Packet Size = '+cstr(filesize(fil)));
          close(fil);
          ok:=TRUE;
        end;
      end; {if user wants to continue}
    end else
      sprint('Error: cannot archive packet.');
  end else begin {no messages to archive}
    sprint('No messages to download.'); ok:=FALSE;
  end;

  { // Download }
  if ok then begin
    OldFileBoard:=FileBoard;
    FileBoard:=-1;
    isQWK:=TRUE;
    Send1(WorkPath+Systat^.QwkFileName+'.QWK',ok,kabort);
    isQWK:=FALSE;
    FileBoard:=OldFileBoard;
    if (ok and (not kabort)) then
      ok:=TRUE
    else
      ok:=FALSE;
  end; {if ok}

  { // Reset Pointers }
  if ok then begin
    dyny:=TRUE;
    if (pynq('Update newscan pointers')) then begin
      sprint('Updating newscan pointers ...');
      CurrArea := 0;
      While (CurrArea <= NumBoards) do begin
        if (NewLastRead[CurrArea] > 0) then begin
          loadboard(CurrArea);
          sprint(memboard.name+' '+cstr(NewLastRead[CurrArea]));
          if OpenMsgArea(CMsg, Memboard.MsgAreaID) then begin
            CMsg^.SetLastRead(usernum, NewLastRead[CurrArea]);
            if CloseMsgArea(CMsg) then;
          end;
        end;
        Inc(CurrArea);
      end; {while}
    end;
  end;

  { // Delete Packet }
  purgedir2(WorkPath);

  { // Update mread }
  if ok then
    inc(mread,NumThisPkt);

  { // Restore time / old boards / etc. }
  ThisUser.Conference := OldConf;
  ChangeBoard(OldBoard);
  GetDateTime(QwkEnd);
  TimeDiff(TookTime,QwkStart,QwkEnd);
  FreeTime:=FreeTime+dt2r(TookTime);
  if ChopTime<>0.0 then begin
    Choptime:=ChopTime+dt2r(TookTime);
    FreeTime:=FreeTime-dt2r(TookTime);
  end;
  sprint('Time making/downloading packet: '+cstr(TookTime.hour)+':'+cstr(TookTime.min)+':'+cstr(TookTime.sec));
End;

Procedure TossREP;
  Var
    WorkPath: String[128];      { Temp work directory }
    Offline: AbsOffPtr;         { Offline mailer object }
    Ok: Boolean;                { ok to continue? }
    OldBoard: Word;             { Old message board }
    OldFileBoard: Integer;      { Old file board }
    OldConf: Char;              { Old conference }
    RepStart,RepEnd,TookTime: datetimerec;
    dok, kabort, addbatch: Boolean; { file file xfer }
    aType: Integer;             { Archive Type }

Begin
  Cls;
  sprint('Illusion Offline Mail System');
  sprint('þ This system has not been thoroughly tested yet.');
  sprint('þ Please report any bugs to the SysOp who should contact the');
  sprint('þ BBS authors (information is available in the readme files).');
  nl;

  OldBoard := Board;
  OldConf := ThisUser.Conference;
  ThisUser.Conference := '@'; { Switch to global msg conference }
  GetDateTime(RepStart);

  { // Initialize Object }
  Offline := nil;
  GetOffType(Offline);
  If Offline = nil Then
    ok := False;

  If Ok Then Begin
    Offline^.SetBBSID(Systat^.QwkFileName);
    WorkPath := Modemr^.TempPath+'QWK\';
    PurgeDir2(WorkPath);
    Offline^.SetPath(WorkPath);
  End;

  { // Upload }
  OldFileBoard:=FileBoard;
  Sprint('REP Packet Upload'); nl;
  repeat
    addbatch:=FALSE; FileBoard:=-1; isQWK:=TRUE;
    receive1(WorkPath+Systat^.QwkFileName+'.REP',FALSE,dok,kabort,addbatch);
    isQWK:=FALSE;
    if addbatch then sprint('Batch unavailable for uploading REP packets.');
  until not(addbatch);
  FileBoard:=OldFileBoard;

  if (dok and (not kabort)) then
    ok:=TRUE
  else
    ok:=FALSE;

  { // Unpack }
  if ok then begin
    aType := arctype('BLAH.'+thisuser.qwkarc);
    Sprint('Decompressing packet ...');
    shel1;
    execbatch(ok,TRUE,'iqwktemp.bat','',WorkPath,
      arcmci(Systat^.ArcPath+Systat^.filearcinfo[atype].unarcline,
        Systat^.QwkFileName+'.REP',Systat^.QwkFileName+'.MSG',''),
      systat^.filearcinfo[atype].succlevel);
    shel2;
  end;

  { // Toss }
  If Ok Then Begin
    Sprint('Tossing...');
    Offline^.ImportPacket;
  End;

  Dispose(Offline,Done);

  ThisUser.Conference := OldConf;
  ChangeBoard(OldBoard);
  GetDateTime(RepEnd);
  TimeDiff(TookTime,RepStart,RepEnd);
  FreeTime:=FreeTime+dt2r(TookTime);
  if ChopTime<>0.0 then begin
    Choptime:=ChopTime+dt2r(TookTime);
    FreeTime:=FreeTime-dt2r(TookTime);
  end;
  SysOpLog('Uploaded offline mail packet.');
  sprint('Packet tossed.');
  sprint('Packet upload and toss took: '+cstr(TookTime.hour)+':'+cstr(TookTime.min)+':'+cstr(TookTime.sec));
End;

End.
