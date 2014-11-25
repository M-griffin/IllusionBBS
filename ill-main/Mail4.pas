(****************************************************************************)
(* Illusion BBS - Mail functions [4/?]                                      *)
(****************************************************************************)

Unit Mail4;

{$I MKB.Def}

Interface

uses CRT, Dos, common,
     Mail0, Mail1, Mail3,
     MkGlobT, MkMsgABS,
     MKMsgJAM, MKMsgHUD, MKMsgFID, MKMsgSQU, MKMsgEZY;

Procedure ScanForYourMail;
Procedure SendMail(ToUser:Word; fTit:String);
Procedure AskSendMail(ToUser:Word; fTit:String);  { Ask user before sending mail }
Procedure MassMail(Cmd:String);
Procedure SendMailMenuCmd(mstr:astr);  { Parses a mstr before calling SendMail }
Function MailWaitingForUser(n:Word):Word; { Pieces of mail waiting for user n }
Function MailWaiting:Boolean;          { Mail waiting for this user? }

Implementation

Procedure ScanForYourMail;
var OldBoard,OldBoardReal:Word;
    b     :word;
    Quit  :Boolean;
Begin
  sysoplog('Scan for mail');
  OldBoard:=Board;
  OldBoardReal:=BoardReal;
  b:=0; Quit:=FALSE;
  Repeat
    if (b=0) then begin
      Board:=0; BoardReal:=0; LoadBoard(0);
    end else
      if (Board<>b) then ChangeBoard(b);

    if (Board=b) and (MemBoard.EmailScan) then
      begin
        lil:=0;
        spstr(745); {scanning for mail}

        If OpenOrCreateMsgArea(Msg, MemBoard.MsgAreaID,
                               MemBoard.MaxMsgs, MemBoard.MaxDays) then
          begin
            DoScan(Quit, 1, stTitles, FALSE);
            CloseMsgArea(Msg);
          end
        else
          MsgOpenError;

        if (not quit) then
          begin
            lil:=0;
            spstr(746); {done}
          end;

      end;

    inc(b);
  until ((b>numboards) or (quit) or (hangup));

  Board:=OldBoard;
  BoardReal:=OldBoardReal;
End;

Procedure SendMail(ToUser:Word; fTit:String);
Var OldBoard: word;
begin
  OldBoard:=Board;

  ChangeBoard(0);
  Post(ToUser,fTit,'',0);

  ChangeBoard(OldBoard);
end;

Procedure AskSendMail(ToUser:Word; fTit:String);
var Fwd,
    un:Word;
    uu:userrec;
begin
  SetFileAccess(ReadOnly,DenyNone);
  reset(uf);
  Fwd:=ForwardM(ToUser);
  close(uf);

  If (Fwd>0) and (Fwd<>ToUser) then begin
    LoadURec(uu,Fwd);
    clearwaves;
    addwave('UN',caps(uu.name),txt);
    spstr(747); {user forw'ding mail to..}
    ToUser:=Fwd;
  end;

  LoadURec(uu,ToUser);
  clearwaves;
  addwave('UN',caps(uu.name),txt);
  addwave('LO',uu.laston,txt);
  spstr(748); {user last called on..}

  dyny:=TRUE;
  clearwaves;
  addwave('UN',caps(uu.name),txt);
  addwave('U#',cstr(touser),txt);
  if pynq(getstr(749)) then {send mail to?}
  begin
    clearwaves;
    SendMail(ToUser,fTit);
  end;
  clearwaves;
end;

Procedure MassMail(Cmd:String);
begin
end;

Procedure SendMailMenuCmd(mstr:astr);
begin
  if (mstr='') then
    SendMail(0,'')
  else begin
    if (pos(';',mstr)>0) then
      AskSendMail(value(copy(mstr,1,pos(';',mstr)-1)),
               copy(mstr,pos(';',mstr)+1,length(mstr)-pos(';',mstr)))
    else
      AskSendMail(value(mstr),'');
  end;
end;

Function MailWaitingForUser(n:Word):Word;
var brd: boardrec;
    T: String;
    count: Word;
    M: AbsMsgPtr;
    uu: userrec;
begin
  MailWaitingForUser:=0;
  SetFileAccess(ReadOnly,DenyNone);
  Reset(bf);
  Seek(bf,0);
  Read(bf,brd);
  close(bf);

  LoadURec(uu,n);

  If OpenOrCreateMsgArea(M, Brd.MsgAreaID,
                         Brd.MaxMsgs, Brd.MaxDays) then
    begin
      M^.SeekFirst(1); Count:=0;
      While(M^.SeekFound) do begin
        M^.MsgStartUp;

        T:=allcaps(M^.GetTo);
        if (pos('#',T)<>0) then T:=copy(T,1,pos('#',T)-1);
        while T[length(T)]=' ' do T[0]:=chr(ord(T[0])-1);

        if (T=allcaps(uu.RealName)) or
           (T=uu.Name) then inc(Count);

        M^.SeekNext;
      end;
      CloseMsgArea(M);
    end;

  MailWaitingForUser:=count;
end;

Function MailWaiting:Boolean;
var brd: boardrec;
    T: String;
    done: Boolean;
    M: AbsMsgPtr;
begin
  MailWaiting:=FALSE;

  SetFileAccess(ReadOnly,DenyNone);
  Reset(bf);
  Seek(bf,0);
  Read(bf,brd);
  close(bf);

  If OpenOrCreateMsgArea(M, Brd.MsgAreaID,
                         Brd.MaxMsgs, Brd.MaxDays) then
    begin

      M^.SeekFirst(1); done:=FALSE;

      While (M^.SeekFound) and (not done) do begin
        M^.MsgStartUp;

        T:=allcaps(M^.GetTo);
        if (pos('#',T)<>0) then T:=copy(T,1,pos('#',T)-1);
        while T[length(T)]=' ' do T[0]:=chr(ord(T[0])-1);

        if (T=allcaps(ThisUser.RealName)) or
           (T=ThisUser.Name) then
          begin
            MailWaiting:=TRUE; done:=TRUE;
          end;

        M^.SeekNext;
      end;
      CloseMsgArea(M);
    end;
end;

End.
