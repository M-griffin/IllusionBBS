(****************************************************************************)
(* Illusion BBS - Mail functions [7/?]                                      *)
(****************************************************************************)

Unit Mail7;

{$I MKB.Def}

Interface

Uses Common,
     Mail0,
     MkGlobT, MkMsgAbs, MkString;

Procedure CopyMsg(OrigMsg: AbsMsgPtr; Var DestMsg: AbsMsgPtr; DestLoc: String);

Implementation

{ Copies OrigMsg to DestMsg. }
{ OrigMsg MUST be initialized and the message base opened. }
{ DestMsg MUST NOT be initialized }
Procedure CopyMsg(OrigMsg: AbsMsgPtr; Var DestMsg: AbsMsgPtr; DestLoc: String);
Const
  StLen = 78;  { wrap lines at 78 chars }
Var
  TmpStr: String;
  TmpAddr: AddrType;
Begin
  If OpenMsgArea(DestMsg, DestLoc) Then Begin
    DestMsg^.SetMailType(mmtNormal);
    OrigMsg^.MsgStartUp;                   {Initialize input msg}
    DestMsg^.StartNewMsg;                 {Initialize output msg}
    OrigMsg^.MsgTxtStartUp;                {Initialize input msg text}
    OrigMsg^.GetDest(TmpAddr);             {Set header fields}
    DestMsg^.SetDest(TmpAddr);
    OrigMsg^.GetOrig(TmpAddr);
    DestMsg^.SetOrig(TmpAddr);
    DestMsg^.SetFrom(OrigMsg^.GetFrom);
    DestMsg^.SetTo(OrigMsg^.GetTo);
    DestMsg^.SetSubj(OrigMsg^.GetSubj);
    DestMsg^.SetCost(OrigMsg^.GetCost);
    DestMsg^.SetRefer(OrigMsg^.GetRefer);
    DestMsg^.SetSeeAlso(OrigMsg^.GetSeeAlso);
    DestMsg^.SetDate(OrigMsg^.GetDate);
    DestMsg^.SetTime(OrigMsg^.GetTime);
    DestMsg^.SetLocal(OrigMsg^.IsLocal);
    DestMsg^.SetRcvd(OrigMsg^.IsRcvd);
    DestMsg^.SetPriv(OrigMsg^.IsPriv);
    DestMsg^.SetCrash(OrigMsg^.IsCrash);
    DestMsg^.SetKillSent(OrigMsg^.IsKillSent);
    DestMsg^.SetSent(OrigMsg^.IsSent);
    DestMsg^.SetFAttach(OrigMsg^.IsFAttach);
    DestMsg^.SetReqRct(OrigMsg^.IsReqRct);
    DestMsg^.SetRetRct(OrigMsg^.IsRetRct);
    DestMsg^.SetFileReq(OrigMsg^.IsFileReq);
    DestMsg^.SetEcho(False);
    TmpStr := OrigMsg^.GetString(StLen);   {Get line of message text}
    While (Not OrigMsg^.EOM) or (Length(TmpStr) > 0) Do Begin
      If ((TmpStr[1] = #1) and (Not OrigMsg^.WasWrap)) Then
        DestMsg^.DoKludgeLn(TmpStr)       {Save as ^A Kludge line}
      Else
        Begin
        If OrigMsg^.WasWrap Then
          DestMsg^.DoString(TmpStr)       {Save as normal text}
        Else
          DestMsg^.DoStringLn(TmpStr);    {Save as normal text with CR}
        End;
      TmpStr := OrigMsg^.GetString(StLen); {Get next line of message text}
    End;
    If DestMsg^.WriteMsg <> 0 Then;       {Save the message}
    If Not CloseMsgArea(DestMsg) Then;
  End {if OpenMsgArea}
  Else
    spstr(750); {unable to open destination msg base}
End; {proc CopyMsg}

End.
