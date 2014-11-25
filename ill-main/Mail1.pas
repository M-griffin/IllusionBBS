(****************************************************************************)
(* Illusion BBS - Mail functions [1/?]                                      *)
(****************************************************************************)

Unit Mail1;

{$I MKB.Def}

Interface

Uses CRT, DOS, Common,
     Mail0, Mail2, Mail3, Mail7,
     MkGlobT, MkMsgAbs, MkString;

Procedure MessageSystemInit;
Procedure MsgOpenError;
Function IsAnon:boolean;
Function IsNew:boolean;
Procedure DoReply;
Function MsgExport(OutDev:Astr; ShowKludge:Boolean; ReadAllMail:Boolean):byte;
Procedure DoScan(VAR Quit:Boolean; StartMsg:LongInt;
                     ScanType:ScanTyp; ReadAllMail:Boolean);
Procedure ScanMessages(mstr:astr);
Procedure QScan(b:word; VAR Quit:Boolean);
Procedure GNScan;
Procedure NScan(mStr:string);

Implementation

Procedure MessageSystemInit;
  Begin
    BoardLoaded:=0;
    BoardReal:=0;
    Board:=0;
    FillChar(MemBoard, SizeOf(MemBoard), #0);
  End;

Procedure MsgOpenError;
  begin
    sprint('|RAn error has occured opening/creating the message base.');
    sprint('|RThis could result from another node accessing the base');
    sprint('|Rat the same time.  Try again in a few minutes.');
  end;

Function IsAnon:boolean;
  Begin
    if ( not (Networked in MemBoard.BaseStat) ) and (Msg^.IsSent) then
      IsAnon:=TRUE
    else
      IsAnon:=FALSE;
  end;

Function IsNew:boolean;
var LastRead:LongInt;
  Begin
    LastRead:=Msg^.GetLastRead(usernum);
    If LastRead<Msg^.GetMsgNum then
      IsNew:=TRUE
    else
      IsNew:=FALSE;
  end;

Function ShowAnon:boolean;
begin
  if (Public in MemBoard.BaseStat) and (Private in MemBoard.BaseStat) then
    ShowAnon:=(aacs(systat^.AnonPubRead)) and (aacs(systat^.AnonPrivRead))
  else
  if (Public in MemBoard.BaseStat) then
    ShowAnon:=aacs(systat^.AnonPubRead)
  else
  if (Private in MemBoard.BaseStat) then
    ShowAnon:=aacs(systat^.AnonPrivRead)
  else
    ShowAnon:=FALSE;
end;

Procedure DoReply;
Var t:Text;
    TmpStr:String;
    Initials:String[2];
    StLen:byte;
    QuotePos:byte;

  Function GetInitials:aStr;
  var ss,is:aStr;
  begin
    is:=Msg^.GetFrom;
    if (pos(' ',is)<>0) and (copy(is,(pos(' ',is)+1),1)<>'#') then begin
      ss:=copy(is,1,1)+copy(is,(pos(' ',is)+1),1);
      ss:=allcaps(ss);
    end else begin
      ss:=copy(is,1,2);
      ss:=caps(ss);
    end;
    ss[0]:=#2;
    GetInitials:=ss;
  end;

  Begin
    assign(t,'msgtmp.'+cstr(nodenum));
    rewrite(t);

    writeln(t,Msg^.GetFrom);
    writeln(t,Msg^.GetTo);
    writeln(t,Msg^.GetSubj);

    Initials:=GetInitials;

    StLen:=79;

    Msg^.MsgTxtStartup;

    While (not Msg^.EOM) Do
    Begin
      TmpStr:=Msg^.GetString(StLen);
      if (TmpStr[1]<>#1) then begin
        QuotePos := Pos('>',TmpStr);
        If (QuotePos = 0) or (QuotePos > 5) then
          TmpStr := Initials+'> '+stripcolor(TmpStr);
        TmpStr := StripColor(TmpStr);
        If Length(TmpStr) > 75 then TmpStr[0] := #75;

        Writeln(T,stripcolor(TmpStr));
      end;
    End;
    close(t);
  End;

Function MsgExport(OutDev:Astr; ShowKludge:Boolean; ReadAllMail:Boolean):byte;
Var
  TmpStr: String;
  TF:Text;
  AllowMCI:boolean;

  abort,next:boolean;
  StLen:byte;

  RMsg:AbsMsgPtr;  { Msg Object for Return Receipts }

Procedure OutString(s:string);
Var
  isANSI  :boolean;
  j1,j2:byte;
Begin
  if abort then exit;

  if s[1]=#1 then
  begin
    if (copy(s,1,11)=#1'REALFROM: ') then
      if (ShowAnon) then
        s:='|CREAL FROM: ' + copy(s,12,length(s)-11)
      else
        exit
    else
    if (copy(s,1,8)=#1'MCI: ON') then begin
      AllowMCI:=TRUE; exit;
    end else
    if (copy(s,1,9)=#1'MCI: OFF') then begin
      AllowMCI:=FALSE; exit;
    end else
    if (copy(s,1,11)=#1'USERNOTE: ') then
      exit
    else
      if (not ShowKludge) then
        exit
      else begin
        s[1]:='&';
        s:='|r'+s;
      end;
  end;

  if OutDev[1]='*' then
  begin
    isANSI:=(pos(^[,s)<>0);
    if not isANSI then
      begin
        j1:=pos('>',s);
        if (j1>0) and (j1<4) then
          s:='|'+memboard.quote_color+s+'|'+memboard.text_color
        else
          if (Networked in MemBoard.BaseStat) then
          begin
            j1:=pos('---',s);
            j2:=pos('* Origin',s);
            if (j1>0) and (j1<5) then
              s:='|'+memboard.tear_color+s+'|'+memboard.text_color
            else
            if (j2>0) and (j2<5) then
              s:='|'+memboard.origin_color+s+'|'+memboard.text_color
            else
              s:='|'+memboard.text_color+s;
          end else
            s:='|'+memboard.text_color+s;
      end;

    if AllowMCI then
      printacr(s,abort,next)
    else begin
      spromptt(s,FALSE,TRUE); nl; wkey(abort,next);
    end;
  end else
    writeln(TF,s);
End;

Begin
  StLen:=ThisUser.LineLen-1;
  MsgExport:=1;
  AllowMCI:=FALSE;

  If OutDev[1]<>'*' then
  begin
    Assign(TF,OutDev);
    Append(TF);
    if ioresult<>0 then
    begin
      rewrite(TF);
      if ioresult<>0 then
      begin
        MsgExport:=3;        { 3 = Unable to open output file }
        Exit;
      end;
    end;
  end;

  Msg^.MsgStartUp;

  if OutDev[1]='*' then
  begin
    ClearWaves;

    AddWave('M#',cstr(Msg^.GetMsgNum),txt);
    AddWave('H#',cstr(Msg^.GetHighMsgNum),txt);
    AddWave('MN',memboard.name,txt);

    if IsAnon and (not ShowAnon) then
      AddWave('MD',getstr(83),txt)
    else
      AddWave('MD',ReformatDate(Msg^.GetDate, 'MM/DD/YY') + ' ' + Msg^.GetTime,txt);

    TmpStr:='';
    If Msg^.IsPriv then
      TmpStr:=TmpStr+getstr(679); {priv}
    If (Msg^.IsRcvd) and (Private in MemBoard.BaseStat) then
      TmpStr:=TmpStr+getstr(680); {rcvd}
    If (Msg^.IsLocal) and (Networked in MemBoard.BaseStat) then
      TmpStr:=TmpStr+getstr(681); {local}
    If (Msg^.IsCrash) and (Networked in MemBoard.BaseStat) then
      TmpStr:=TmpStr+getstr(682); {crash}
    If (Msg^.IsKillSent) and (Networked in MemBoard.BaseStat) then
      TmpStr:=TmpStr+getstr(683); {k/s}
    If (Msg^.IsSent) and (Networked in MemBoard.BaseStat) then
      TmpStr:=TmpStr+getstr(684); {sent}

    If (Msg^.IsDeleted) then
      TmpStr:=getstr(685);

    If TmpStr='' then TmpStr:=getstr(686);

    AddWave('SF',TmpStr,txt);
    AddWave('MF',Msg^.GetFrom,txt);
    AddWave('MT',Msg^.GetTo,txt);

    if (Msg^.IsFAttach) then
      AddWave('TI','[File Attach]',txt)
    else
      AddWave('TI',Msg^.GetSubj,txt);

    TmpStr:='';

    if (Msg^.GetRefer<=0) then
      AddWave('R#','None',txt)
    else
    begin
      AddWave('R#',cstr(Msg^.GetRefer),txt);
      TmpStr:='Reply to '+cstr(Msg^.GetRefer);
    end;

    if (Msg^.GetSeeAlso<=0) then
    begin
      AddWave('SA','None',txt);
      if TmpStr='' then
        TmpStr:='No replies';
    end
    else
    begin
      AddWave('SA',cstr(Msg^.GetSeeAlso),txt);
      if TmpStr='' then
        TmpStr:='See '+cstr(Msg^.GetSeeAlso)
      else
        TmpStr:=TmpStr+'/See '+cstr(Msg^.GetSeeAlso);
    end;

    AddWave('RS',TmpStr,txt);

  end else
  begin
    writeln(TF,'-----------------------------------------------------------------------------');
    writeln(TF,'Message number: '+cstr(Msg^.GetMsgNum));
    writeln(TF,'From: '+Msg^.GetFrom);
    writeln(TF,'To  : '+Msg^.GetTo);
    writeln(TF,'Subj: '+Msg^.GetSubj);
    writeln(TF,'');
  end;

  Msg^.MsgTxtStartup;
  TmpStr:=Msg^.GetString(StLen);

  if (not isAnon) or (ShowAnon) then
  begin
    if (copy(TmpStr,1,11) = #1'USERNOTE: ') then
    begin
      AddWave('UN',copy(TmpStr,12,length(TmpStr)-11),txt);
      TmpStr:=Msg^.GetString(StLen);
    end else
      AddWave('UN',getstr(83),txt);
  end else
    AddWave('UN',getstr(83),txt);

  aborted:=FALSE; abort:=FALSE; next:=FALSE;

  If OutDev[1]='*' then
  begin
    printf( copy(OutDev,2,length(OutDev)-1) );
    ClearWaves;
    if aborted then abort:=TRUE;
  end;

  While (not Msg^.EOM) and (not abort) Do
    Begin
      OutString(TmpStr);
      TmpStr:=Msg^.GetString(StLen);
    End;
  If length(TmpStr) > 0 then OutString(TmpStr);
  if OutDev[1]<>'*' then
    begin
      Close(TF);
      if IoResult<>0 then
        begin
          MsgExport:=4; exit;
        end;
    end else
      if (dosansion) then redrawforansi;

  { Send return receipt / Set received flag }

  If (not ReadAllMail) then begin
    If (not Msg^.IsRcvd) and (Private in MemBoard.BaseStat) then begin
      If Msg^.IsReqRct then begin
        spstr(664); {return receipt req'd - not yet implemented}
        { Use RMsg variable }
      end;

      Msg^.SetRcvd(TRUE);
      Msg^.ReWriteHdr;
    end;
  end; {not ReadAllMail}

  MsgExport:=0;
End;

Procedure DoScan(VAR Quit:Boolean; StartMsg:LongInt;
                     ScanType:ScanTyp; ReadAllMail:Boolean);
Var
  CurrentMsg:LongInt;
  TempCurrent:LongInt;  { Used for going backwards through the msg base }
  FirstMsg  :LongInt;
  DoneScan  :Boolean;
  AskPost   :Boolean;   { Ask user to post after scanning? }
  abort,next:Boolean;
  inp       :aStr;      { Command input (command or message number) }
  Allowed   :aStr;      { Allowed commands }
  cmd       :Char;      { 1 character command }
  GetM      :LongInt;   { Message to get next }
  ShowKludge:Boolean;   { Show kludge lines? }
  isPublic,isPrivate,isNetworked,isNews:Boolean;
  Ok        :Boolean;
  s         :aStr;
  HelpType  :byte;
  ReferNum  :LongInt;   { Msg reference #, for replies }
  SeeAlsoNum:LongInt;   { Msg reference #, for replies }
  ReplyTitle,           { Default reply title }
  ReplyTo   :aStr;      { Default reply "to"  }
  ReplyAddr :AddrType;  { Reply address for netmail }

  Function Readable(HelpType:byte):Boolean;
  var ok:boolean;
      T:String;
  begin
    if ReadAllMail then
      begin
        Readable:=TRUE;
        exit;
      end;

    if not (HelpType in [2,3,6,7]) then
      begin
        Readable:=TRUE;
        exit;
      end;

    ok:=FALSE;
    Msg^.MsgStartUp;
    T:=allcaps(Msg^.GetTo);
    if (pos('#',T)<>0) then T:=copy(T,1,pos('#',T)-1);

    while T[length(T)]=' ' do T[0]:=chr(ord(T[0])-1);

    if (HelpType in [3,7]) then
      if (T='ALL') then
        ok:=TRUE;

    if (not ok) then
      begin
        if (T=allcaps(ThisUser.RealName)) or
           (T=ThisUser.Name)
        then ok:=TRUE;
      end;

    Readable:=ok;
  end;

  Function InBounds(VAR MsgNum:LongInt):Boolean;
  var HiMsg:Word;
  begin
    InBounds:=TRUE;
    HiMsg:=Msg^.GetHighMsgNum;
    if MsgNum<FirstMsg then
    begin
      MsgNum:=FirstMsg;
    end else
      if MsgNum>HiMsg then
      begin
        MsgNum:=HiMsg;
        InBounds:=FALSE;
      end
  end;

  procedure ScanInput(VAR S:string; Allowed:aStr);
  var os:string;
      i :integer;
      c :char;
      GotCmd:boolean;
  begin
    GotCmd:=FALSE; s:='';

    repeat
      getkey(c);
      c:=upcase(c);
      os:=s;

      if ((pos(c,Allowed)<>0) and (s='')) then begin
        GotCmd:=TRUE;
        s:=c;
      end else
        if (pos(c,'0123456789')<>0) then
        begin
          if (length(s)<5) then s:=s+c;
        end else
          if ((s<>'') and (c=^H)) then
            s:=copy(s,1,length(s)-1)
          else
            if (c=^X) then
            begin
              for i:=1 to length(s) do prompt(^H' '^H);
              s:=''; os:='';
            end else
              if (c=#13) then GotCmd:=TRUE;

      if (length(s)<length(os)) then prompt(^H' '^H);
      if (length(s)>length(os)) then prompt(copy(s,length(s),1));
    until ((GotCmd) or (hangup));
    nl;
  end; {proc ScanInput}


  function TitleList(StartMsg:LongInt; VAR EndMsg:LongInt):boolean;
  var Done,abort,next: boolean;
      NumShown: Byte;
      TmpStr: Astr;

  begin
    TitleList:=TRUE;

    Done:=FALSE; abort:=FALSE; next:=FALSE; aborted:=false;
    NumShown:=0;
        
    if not InBounds(StartMsg) then exit;
    EndMsg:=StartMsg;

    Msg^.SeekFirst(EndMsg);
    while (not readable(HelpType)) and (Msg^.SeekFound) do Msg^.SeekNext;
    if Msg^.SeekFound then
      begin
        EndMsg:=Msg^.GetMsgNum;
        spstr(807); { Title Header ANSI }
        spstr(604);
      end
    else
      begin
        done:=TRUE; aborted:=TRUE;
        spstr(665); {no msgs to you found}
        TitleList:=FALSE;
      end;

    while (not hangup) and (not abort) and (NumShown<15) and (not done) and (not aborted) do begin
      ClearWaves;
      If not InBounds(EndMsg) then Done:=TRUE;

      If (not Done) and (Msg^.SeekFound) then
      begin
        Msg^.MsgStartUp;

        AddWave('M#',cstr(Msg^.GetMsgNum),txt);

        TmpStr:='';

        if Msg^.IsDeleted then
          TmpStr:=TmpStr+getstr(607)
        else
          TmpStr:=TmpStr+getstr(608);

        if IsNew then
          TmpStr:=TmpStr+getstr(609)
        else
          TmpStr:=TmpStr+getstr(610);

        AddWave('M$',TmpStr,txt);

        if not Msg^.IsDeleted then begin
          if IsAnon and (not ShowAnon) then
            AddWave('MD',getstr(83),txt)
          else
            AddWave('MD',ReformatDate(Msg^.GetDate, 'MM/DD/YY'),txt);

          AddWave('MF',Msg^.GetFrom,txt);
          AddWave('MT',Msg^.GetTo,txt);
          AddWave('MS',Msg^.GetSubj,txt);
        end;

        spstr(605);
        wkey(abort,next);
        if abort then aborted:=true;
        inc(NumShown);
        Msg^.SeekNext;
        while (not Readable(HelpType)) and (Msg^.SeekFound) do Msg^.SeekNext;
        EndMsg:=Msg^.GetMsgNum;
      end else
        done:=TRUE;
    end;

    ClearWaves;

    if (not aborted) then spstr(606);
    nl;
  end; {proc TitleList}

Begin
  CurrentMsg:=StartMsg;
  DoneScan:=FALSE;
  AskPost :=FALSE;
  ShowKludge:=FALSE;
  isPublic   := (Public in Memboard.BaseStat);
  isPrivate  := (Private in Memboard.BaseStat);
  isNetworked:= (Networked in Memboard.BaseStat);
  isNews     := (News in Memboard.BaseStat);
  GetM:=-1;

  Allowed:='?A-BDHITQZ';
  if (so) then
    Allowed:=Allowed+'UX$';
  if (mso) then
    Allowed:=Allowed+'EM';
  if isPublic then begin
    if isPrivate then begin  {public/private}
      Allowed:=Allowed+'FPRWS';
      HelpType:=3;
    end else begin           {public}
      Allowed:=Allowed+'PRW';
      HelpType:=1;
    end;
  end else
    if isPrivate then begin  {private}
      Allowed:=Allowed+'FRWS';
      HelpType:=2;
    end else
      if isNews then begin   {news}
        Allowed:=Allowed+'P';
        HelpType:=4;
      end;

  if isNetworked then begin
    Allowed:=Allowed+'&*';
    if isPrivate then begin
      Allowed:=Allowed+'%!';
      HelpType:=HelpType+4;
    end else
      HelpType:=HelpType+8;
  end;

      Msg^.SeekFirst(1);
      Msg^.MsgStartUp;
      FirstMsg:=Msg^.GetMsgNum;
      If InBounds(CurrentMsg) then;

      While (not DoneScan) and (not hangup) do begin
        if ScanType=stTitles then begin
          if TitleList(CurrentMsg, CurrentMsg) then
            ScanType:=stReadP
          else
            DoneScan:=TRUE;
        end;
        if ScanType=stReadP then begin
          Msg^.SeekFirst(CurrentMsg);
          Msg^.MsgStartup;

          if (HelpType in [2,3,6,7]) then
            spStr(80)
          else
            spStr(78);
          ScanInput(inp,Allowed);
          GetM:=-1; Cmd:=#0;

          if (inp='') then
            GetM:=CurrentMsg+1
          else begin
            GetM:=value(inp);
            If GetM<=0 then GetM:=-1;
          end;

          if (GetM=-1) and (inp<>'') then Cmd:=inp[1];

          if (GetM=-1) and (Cmd<>#0) then
          case cmd of
            '?':begin
                  nl; nl;
                  sprint('|w(|WA|w)Reread message           |w(|W-|w)Previous message');
                  sprint('|w(|WB|w)Next board in NewScan    |w(|WD|w)elete message');
                  sprint('|w(|WH|w)Set high message pointer |w(|WI|w)gnore remaining messages');
                  sprint('|w(|WT|w)itle list                |w(|WZ|w)Toggle NewScan of this base');

                  if (HelpType=1) or (HelpType=3) then begin
                    sprint('|w(|WP|w)ost public message       |w(|WR|w)eply to message');
                  end;

                  if (HelpType=2) or (HelpType=3) then begin
                    sprint('|w(|WF|w)orward mail              |w(|WS|w)end private message');
                  end;

                  if (HelpType=2) then begin
                    sprint('|w(|WR|w)eply to message');
                  end;

                  if (HelpType=4) then begin
                    sprint('|w(|WP|w)ost announcement');
                  end;

                  nl;
                  if so then begin
                    sprint('SysOp Commands:');
                    sprint('|w(|WU|w)Edit sender''s info.      |w(|WX|w)Extract message to file');
                    sprint('|w(|W$|w)Read all messages (incl. private)');
                    nl;
                  end;
{                 if mso then begin
                    sprint('Message SubOp Commands:');
                    sprint('|w(|WE|w)dit message              |w(|WM|w)Move message');
                    nl;
                  end; }
                  sprint('|w(|WQ|w)uit');
                end;
            'A':GetM:=CurrentMsg;
            '-':begin
                  { Get the firstmsg again in case somebody deleted
                    a message (earlier or on another node) }

                  Msg^.SeekFirst(1);
                  Msg^.MsgStartup;
                  FirstMsg:=Msg^.GetMsgNum;

                  GetM:=CurrentMsg-1;
                  Msg^.SeekFirst(GetM);
                  Msg^.MsgStartUp;
                  TempCurrent:=CurrentMsg;
                  Repeat
                    While (Msg^.GetMsgNum=TempCurrent) and (GetM>FirstMsg) do begin
                      dec(GetM);
                      Msg^.SeekFirst(GetM);
                      Msg^.MsgStartUp;
                    end;
                    TempCurrent:=GetM;
                  Until Readable(HelpType) or (not (GetM>FirstMsg));
                end;
            'B':DoneScan:=TRUE;
            'D':begin
                  Ok:=FALSE;
                  if isPublic or isPrivate then
                    if (allcaps(copy(Msg^.GetFrom,1,length(ThisUser.RealName)))=allcaps(ThisUser.RealName)) or
                       (allcaps(copy(Msg^.GetFrom,1,length(ThisUser.Name)))=ThisUser.Name)
                    then ok:=TRUE;
                  if isPrivate then
                    if (allcaps(copy(Msg^.GetTo,1,length(ThisUser.RealName)))=allcaps(ThisUser.RealName)) or
                       (allcaps(copy(Msg^.GetTo,1,length(ThisUser.Name)))=ThisUser.Name)
                    then ok:=TRUE;
                  If mso then ok:=TRUE;
                  If Ok then begin
                    sysoplog('* Deleted "'+Msg^.GetSubj+'"');
                    Msg^.DeleteMsg;
                    spstr(666); {msg deleted}
                    GetM:=CurrentMsg+1;
                  end else
                    spstr(687); {you can't delete this msg}
                end;
(*          'E':begin
                  { EDIT MESSAGE }
                  { if your message, or mso }
                end; *)
            'F':begin
                  { FORWARD MAIL }
                  { if readable  }
                end;
            'H':begin
                  clearwaves;
                  addwave('M#',cstr(Msg^.GetMsgNum),txt);
                  spstr(688); {lastread pointer set to}
                  clearwaves;
                  Msg^.SetLastRead(usernum,CurrentMsg);
                end;
            'I':begin
                  spstr(689); {remaining msgs ignored}
                  Msg^.SetLastRead(usernum,Msg^.GetHighMsgNum);
                  DoneScan:=TRUE;
                end;
(*          'M':begin
                  { MOVE MESSAGE }
                  { if mso }
                end; *)
            'P':begin
                  CloseMsgArea(Msg);
                  post(0,'','',0);
                  OpenOrCreateMsgArea(Msg, MemBoard.MsgAreaID,
                    MemBoard.MaxMsgs, MemBoard.MaxDays)
                end;
            'Q':begin
                  Quit:=TRUE;
                  DoneScan:=TRUE;
                end;
    'W','R','S':if Readable(Helptype) then begin
                  DoReply;
                  ReferNum:=Msg^.GetMsgNum;
                  ReplyTitle:=Msg^.GetSubj;
                  if copy(allcaps(ReplyTitle),1,3) <> 'RE:' then
                    ReplyTitle:='Re: '+ReplyTitle;
                  ReplyTo:=Msg^.GetFrom;

                  If (HelpType=6) then begin {Netmail}
                    Msg^.GetOrig(ReplyAddr);
                    ReplyTo:=ReplyTo+'@'+AddrStr(ReplyAddr);
                  end;

                  CloseMsgArea(Msg);
                  SeeAlsoNum := Post(0,ReplyTitle,ReplyTo,ReferNum);
                  OpenOrCreateMsgArea(Msg, MemBoard.MsgAreaId,
                    MemBoard.MaxMsgs, MemBoard.MaxDays);
                  Msg^.SeekFirst(CurrentMsg);
                  Msg^.MsgStartup;

                  if (SeeAlsoNum>0) then begin

                    { Use reply threading if JAM; otherwise,
                      just update See Also }

                    if (MemBoard.MsgAreaID[1]='J') then begin

                      { -- If first reply, act normally }

                      if (Msg^.GetSeeAlso=0) then begin
                        Msg^.SetSeeAlso(SeeAlsoNum);
                        Msg^.ReWriteHdr; { Save updates to message header }
                      end else begin

                        { -- (else) First, go to the first reply }

                        Msg^.SeekFirst(Msg^.GetSeeAlso);
                        Msg^.MsgStartup;

                        { -- Then, thread until at the last reply }

                        while (Msg^.GetNextSeeAlso>0) do begin
                          Msg^.SeekFirst(Msg^.GetNextSeeAlso);
                          Msg^.MsgStartup;
                        end;

                        Msg^.SetNextSeeAlso(SeeAlsoNum);
                        Msg^.ReWriteHdr; { Save updates to message header }
                      end;
                    end else begin
                      if (Msg^.GetSeeAlso=0) then begin
                        Msg^.SetSeeAlso(SeeAlsoNum);
                        Msg^.ReWriteHdr; { Save updates to message header }
                      end;
                    end; {not JAM}

                    Msg^.SeekFirst(CurrentMsg); { Reload current msg }
                    Msg^.MsgStartup;
                  end;

                  { Delete original --- }

                  Ok:=FALSE;
                  if isPrivate then
                    if (allcaps(copy(Msg^.GetTo,1,length(ThisUser.RealName)))=allcaps(ThisUser.RealName)) or
                       (allcaps(copy(Msg^.GetTo,1,length(ThisUser.Name)))=ThisUser.Name)
                    then ok:=TRUE;

                  If Ok then begin
                    dyny:=TRUE;
                    if pynq(getstr(690)) then begin
                      Msg^.DeleteMsg;
                      GetM:=CurrentMsg+1;
                    end;
                  end;

                end;
            'T':begin inc(CurrentMsg); ScanType:=stTitles; end;
            'U':begin
                  { EDIT SENDER USERREC }
                end;
            'X':begin
                  spstr(691);  {extract to filename}
                  input(s,60);
                  if (s='') then s:='EXTRACT.TXT';
                  if pynq(getstr(692)) then begin
                    if (MsgExport(s,ShowKludge,ReadAllMail)=0) then
                      spstr(693)  {msg successfully exported}
                    else
                      spstr(694); {error exporting msg}
                  end;
                end;
            'Z': { TOGGLE ZSCAN } ;
            '$': begin
                   ReadAllMail:=not ReadAllMail;
                   if ReadAllMail then
                     spstr(695)  {all msgs will be displayed)
                   else
                     spstr(696); {priv msgs to others won't be displayed}
                 end;
            '&':begin
                  ShowKludge:=not ShowKludge;
                  if ShowKludge then
                    spstr(697)  {kludge lines displayed}
                  else
                    spstr(698); {not displayed}
                end;
            '*':begin
                  if Msg^.IsSent then begin
                    Msg^.SetSent(FALSE);
                    spstr(700); {marked as not sent}
                  end else begin
                    Msg^.SetSent(TRUE);
                    spstr(699); {marked as sent}
                  end;
                end;
            '%':begin
                  if Msg^.IsRcvd then begin
                    Msg^.SetRcvd(FALSE);
                    spstr(702); {marked as received}
                  end else begin
                    Msg^.SetRcvd(TRUE);
                    spstr(701); {marked as not rcvd}
                  end;
                end;
            '!':begin
                  If Msg^.IsCrash then begin
                    Msg^.SetCrash(FALSE);
                    spstr(704); {no longer marked crash}
                  end else begin
                    Msg^.SetCrash(TRUE);
                    spstr(703); {marked crash}
                  end;
                end;
          end; {case Cmd}

        end; {if ScanType=stRead}

        if (GetM<>-1) then CurrentMsg:=GetM;

        If (not InBounds(CurrentMsg)) then
          begin
            DoneScan:=TRUE; askpost:=TRUE;
          end;

        If (not DoneScan) then
          begin
            if (GetM<>-1) then ScanType:=stReadM;
            if ScanType=stReadM then
              begin
                Msg^.SeekFirst(CurrentMsg);
                Msg^.MsgStartUp;
                while (not Readable(HelpType)) and (Msg^.SeekFound) do Msg^.SeekNext;
                CurrentMsg:=Msg^.GetMsgNum;
                if (not InBounds(CurrentMsg)) or (not Msg^.SeekFound) then
                  DoneScan:=TRUE
                else
                  begin
                    MsgExport('*'+MemBoard.MsgHeaderFile,ShowKludge,ReadAllMail);
                    if CurrentMsg>Msg^.GetLastRead(usernum) then
                      Msg^.SetLastRead(usernum,CurrentMsg);
                    ScanType:=stReadP;
                    if isPublic then inc(Mread);
                  end;
              end;
          end;
      end; {While not DoneScan}

      if (AskPost) then
        if aacs(memboard.postacs) then
          if pynq(getstr(705)) then begin
            CloseMsgArea(Msg);
            post(0,'','',0);
            OpenOrCreateMsgArea(Msg, MemBoard.MsgAreaID,
              MemBoard.MaxMsgs, MemBoard.MaxDays);
          end;

End;

Procedure ScanMessages(mstr:astr);
Var s:string[10];
    StartMsg:LongInt;
    HighMsg:LongInt;
    Quit:Boolean;
begin
  nl;
  if (BoardReal<>BoardLoaded) then LoadBoard(BoardReal);
  If OpenOrCreateMsgArea(Msg, MemBoard.MsgAreaID,
                         MemBoard.MaxMsgs, MemBoard.MaxDays) then
    begin
      if Msg^.NumberOfMsgs>0 then
        begin
          SpStr(79); {scan prompt}
          Input(s,10);
          StartMsg:=Value(s);
          If StartMsg<1 then StartMsg:=1;
          HighMsg:=Msg^.GetHighMsgNum;
          If StartMsg>HighMsg then StartMsg:=HighMsg;
          if s<>'' then
            if s[1]<>'Q' then begin
              if mstr='T' then
                DoScan(Quit,StartMsg,StTitles,False)
              else
                DoScan(Quit,StartMsg,StReadM,False);
            end;
        end
      else
        spstr(706); {no msgs in this base}
      CloseMsgArea(Msg);
    end
  else
    MsgOpenError;
end;

Procedure QScan(b:word; VAR Quit:Boolean);

{ b = Compressed base number }

var OldBoard,OldBoardReal:word;
    StartMsg:LongInt;
    HighMsg :LongInt;
    LastRead:LongInt;
    Next    :Boolean;
begin
  OldBoard:=Board;
  OldBoardReal:=BoardReal;
  if (not Quit) then begin
    if (Board<>b) then ChangeBoard(b);
    if (Board=b) then
    begin
      lil:=0;
      SpStr(76); {start newscan}
      If OpenOrCreateMsgArea(Msg, MemBoard.MsgAreaID,
                             MemBoard.MaxMsgs, MemBoard.MaxDays) then
        begin
          Msg^.SeekFirst(1);
          LastRead:=Msg^.GetLastRead(usernum);
          Msg^.SeekFirst(LastRead+1);
          Msg^.MsgStartUp;
          StartMsg:=Msg^.GetMsgNum;
          HighMsg:=Msg^.GetHighMsgNum;

          if (StartMsg<=HighMsg) and (LastRead<StartMsg) then
            DoScan(Quit,StartMsg,stReadM,False);
          CloseMsgArea(Msg);
        end
      else
        MsgOpenError;
      if (not quit) then begin
        lil:=0;
        spstr(77); {end newscan}
      end;
    end;
    wkey(quit,next);
  end;
  Board:=OldBoard;
  BoardReal:=OldBoardReal;
end;

Procedure GNScan;
var OldBoard,OldBoardReal:Word;
    b       :word;
    Quit    :Boolean;
begin
  sysoplog('NewScan of message bases');
  OldBoard:=Board;
  OldBoardReal:=BoardReal;
  spstr(74); {start global newscan}
  b:=0; Quit:=FALSE;
  Repeat
    if (Board<>b) then ChangeBoard(b);
    if (Board=b) then begin
      LoadMsgZScan;
      If MsgZScan.MailScan then
        QScan(b,Quit);
    end;
    inc(b);
  until ((b>numboards) or (quit) or (hangup));
  spstr(75); {end newscan}
  Board:=OldBoard;
  BoardReal:=OldBoardReal;
end;

Procedure NScan(mStr:string);
var abort,next:boolean;
begin
  abort:=FALSE; next:=FALSE;
  if (mStr='C') then QScan(Board,next)
    else if (mStr='G') then GNScan
      else if (value(mStr)<>0) then QScan(Value(mStr),next)
        else begin
          if pynq(getstr(707)) then
            GNScan
          else
            QScan(Board,next);
        end;
end;

End.
