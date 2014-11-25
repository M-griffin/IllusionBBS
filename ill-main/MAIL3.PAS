(*****************************************************************************)
(* Illusion BBS - Mail functions [3/?]                                       *)
(*****************************************************************************)

Unit Mail3;

{$I MKB.DEF}

Interface

Uses Crt, Dos, Common, Mail0, MkMsgABS,
     MkGlobT, MkString, MkDos, MkFile,     
     MsgF, { PurgeDir2, Receive1 }     
     MailFSE, MailLine;

Function MoreMail(u:userrec; un,what:word):boolean;
function getorigin:string;
function stripthings(nn:string):string;
Function ForwardM(n:Word):Word;
Function Post(ToU:Word;                { If Email: To user }
              fTit:string;             { Forced/Suggested Title }
                                       {  "\" signifies forced  }
                                       {  and "cantabort"       }
              fTo:string;              { Forced "To"            }
              ReplyTo:LongInt          { Msg refer #            }
              ):LongInt;               { ---------------------- }
                                       { Return: Msg # of new msg }

Implementation

uses mail1, mail4;

Function MoreMail(u:userrec; un,what:word):boolean;
begin
  MoreMail:=TRUE;
  case what of
    1:moremail:=(not (((aacs1(u,un,systat^.csop)) and
        (MailWaitingForUser(un)>=systat^.csmaxwaiting)) or
        ((not aacs1(u,un,systat^.csop)) and (MailWaitingForUser(un)>=systat^.maxwaiting))));
    2:moremail:=(not (nomail in u.ac));
    3:moremail:=(not (u.deleted));
    4:moremail:=(not ((un=usernum) and (not cso)));
  end;
end;

function getorigin:string;
  var s:astr;
  begin
    if (memboard.origin<>'') then s:=memboard.origin
      else if (systat^.origin<>'') then s:=systat^.origin
        else s:=copy(stripcolor(systat^.bbsname),1,50);
    while (copy(s,length(s),1)=' ') do
      s:=copy(s,1,length(s)-1);
    getorigin:=s;
  end; {func getorigin }

function stripthings(nn:string):string;
  var p:integer;
      q:char;
      ls:string;
  begin
    if (mbNoColor in MemBoard.mbStat) then nn:=stripcolor(nn);
    if (mbStrip in MemBoard.mbStat) then begin
       if (copy(nn,1,3)='`#[') then nn:=centre(copy(nn,4,length(nn))) else
       if (nn[1]=#2) then nn:=centre(copy(nn,2,length(nn)));
    end;
    ls:='';
    for p:=1 to length(nn) do begin
      q:=nn[p];
      if (mbFilter in MemBoard.mbStat) then
        if (q in [#2..#9,#11..#12,#14..#31,#127..#255]) then q:='*';
      ls:=ls+q;
    end;
    stripthings:=ls;
  end; {func stripthings}

{ this routine will find the user that user n is forwarding their mail to.
  it will also check to get around "circular forwarding", such as:
  5 -> 10 -> 15 -> 5 ... }
Function ForwardM(n:Word):Word;
var chk:array[1..1250] of byte;   { 1250 * 8 = 10000 users max }
    cur:integer;
    u:userrec;
    done:boolean;

  function chkval(i:integer):boolean;
  begin
    dec(i);
    chkval:=((chk[i div 8] and (1 shl (i mod 8)))<>0);
  end;

  procedure chkset(i:integer);
  var bb,bc:byte;
  begin
    dec(i);
    bb:=chk[i div 8]; bc:=(1 shl(i mod 8));
    if ((bb and bc)=0) then chk[i div 8]:=chk[i div 8]+bc;
  end;

begin
  for cur:=1 to 1250 do
    chk[cur]:=0;
  cur:=n;
  done:=FALSE;
  while not done do
    if (chkval(cur)) then begin
      done:=TRUE;
      cur:=0;
    end else
      if (cur<filesize(uf)) and (cur>0) then begin
        seek(uf,cur); read(uf,u);
        if (u.deleted) then begin
          done:=TRUE;
          cur:=0;
        end else begin
          if (u.forusr=0) then begin
            done:=TRUE;
          end else begin
            chkset(cur);
            cur:=u.forusr;
          end;
        end;
      end else begin
        done:=TRUE;
        cur:=0;
      end;
  ForwardM:=cur;
end;

Function Post(ToU:Word;                { If Email: To user }
              fTit:string;             { Forced/Suggested Title }
                                       {  "\" signifies forced  }
                                       {  and "cantabort"       }
              fTo:string;              { Forced "To" }
              ReplyTo:LongInt          { Msg refer # }
              ):LongInt;
var ok,b:boolean;                  { User allowed to post on base? }
    t   :BaseTyp;
    Mtyp:(mtNormal,mtEcho,mtNet);
    u   :userrec;
    Fwd :Word;                     { For mail forwarding when ToU is used }
    i   :integer;
    cantabort:boolean;
    OrigAddr:AkaRec;
    CurrAddr, DestAddr:AddrType;
    s   :string;
    an  :AnonTyp;
    usefse,                        { Use FSE? }
    didupload:boolean;             { Uploaded prepared msg? }
    MsgFName:String[40];           { Message file name }
    f:file;                        { To erase old files }
    OAddr:AddrType;                { Address for origin line }

    TF:TFile;                      { Msg file after editing }
    TmpStr:String;                 { Lines from msg }

    SemaFile:file;                 { File handle to create semaphores }

    OldFileBoard:Integer;          { For msg uploads }
    addbatch,dok,kabort:boolean;   { --------------- }

  procedure Nope(s:word);
  begin
    if (ok) then spstr(s);
    ok:=FALSE;
  end;

  function MatchUser(UName:astr):word;
  var sfo: boolean;
      sr: smalrec;
      done,asked: boolean;
      gg: integer;
      c: char;
  begin

    sfo:=(filerec(sf).mode<>fmClosed);
    if (not sfo) then begin
      SetFileAccess(ReadOnly,DenyNone);
      reset(sf);
    end;

    done:=FALSE; asked:=FALSE; gg:=1;
    while ((gg<filesize(sf)-1) and (not done)) do begin
      seek(sf,gg); read(sf,sr);
      if (pos(UName,sr.name)<>0) then
        if (sr.name=UName) then
          MatchUser:=sr.number
        else begin
          asked:=TRUE;
          clearwaves;
          addwave('UN',caps(sr.name),txt);
          addwave('U#',cstr(sr.number),txt);
          spstr(725); {incomplete match prompt}
          clearwaves;
          onek(c,'QYN'^M);
          done:=TRUE;
          case c of
            'Q': MatchUser:=0;
            'Y': MatchUser:=sr.number;
          else
            done:=FALSE;
          end;
        end;
      inc(gg);
    end;
    if (not sfo) then close(sf);
  end;

  function GetHeaderInfo:boolean;
  const TitleLen=60;   { Maximum length of msg titles }
        ToLen=35;      { Maximum length of msg to field }
  var TempTitle:String[TitleLen];
      TempTo:String[ToLen];
      un,              { UserNum (for name lookups) }
      Fwd,             { UserNum for mail forwarding }
      code,i:word;
      uu:userrec;

  begin
    GetHeaderInfo:=FALSE;
    nl;
    TempTitle:=fTit;

    if (copy(TempTitle,1,1)='\') then begin
      TempTitle:=copy(TempTitle,2,length(TempTitle)-1);
      clearwaves;
      addwave('DT',TempTitle,txt);
      spstr(728); {title...}
      clearwaves;
      cantabort:=TRUE;
    end else begin
      cantabort:=FALSE;
      if aacs(MemBoard.AttachAcs) and
         pynq(getstr(726)) then {attach a file?}
          begin
            spstr(727); {filename..}
            TempTitle:='';
            input(TempTitle,TitleLen);
            If (TempTitle='') then exit;
            Msg^.SetFAttach(TRUE);
          end
        else
          begin
            if (fTit<>'') then begin
              clearwaves;
              addwave('DT',fTit,txt);
              spstr(729); {default.. title..}
              clearwaves;
            end else
              spstr(730); {title..}
            mpl(TitleLen); TempTitle:='';
            inputmain(TempTitle,TitleLen,'l');
            if (TempTitle='') then begin
              if (fTit<>'') then begin
                setc(systat^.inputfieldcolor);
                sprompt(fTit);
                TempTitle:=fTit;
              end else begin
                spstr(731); exit;  {abort if title is blank}
              end;
            end;
          end;
    end;

    spstr(732);
    Msg^.SetSubj(TempTitle);

    if not ((private in MemBoard.BaseStat) and
       (networked in MemBoard.BaseStat)) then
      begin
        if (fTo<>'') and (private in MemBoard.BaseStat) then
          begin
            TempTo:=fTo;
          end
        else
          begin
            if (fTo<>'') then
              begin
                clearwaves;
                addwave('DT',fTo,txt);
                spstr(733); {default.. to..}
                clearwaves;
              end else
                spstr(734);
            mpl(ToLen);
            inputmain(TempTo,ToLen,'lp');
            for i:=1 to length(TempTo) do
              prompt(^H' '^H);
            if TempTo='' then TempTo:=fTo;
            if TempTo='' then
              if (not (public in MemBoard.BaseStat)) then begin
                TempTo:=''; exit;  { Can't address private msg to ALL }
              end else
                TempTo:='All';

            if (copy(TempTo,1,1)='#') then TempTo:=copy(TempTo,2,length(TempTo)-1);
            val(TempTo,un,code);
            if ((un<>0) and (code=0)) then
              begin
                SetFileAccess(ReadOnly,DenyNone);
                reset(uf);
                if ((un>=1) and (un<=filesize(uf)-1)) then
                  begin

                    { If Email check for mail forwarding }

                    If (BoardReal=0) then begin
                      Fwd:=ForwardM(un);
                      if (Fwd>0) and (Fwd<>un) then begin
                        un:=Fwd; spstr(736); {mail forwarded to}
                      end;
                    end;

                    loadurec(uu,un);
                    if mbRealName in MemBoard.mbStat then
                      TempTo:=caps(uu.realname)
                    else
                      TempTo:=caps(uu.name);
                  end
                else
                  begin
                    spstr(86); {invalid user}
                    TempTo:=''; close(uf); exit;
                  end;
                close(uf);
              end
            else
              if (private in MemBoard.BaseStat) and (TempTo<>'All') and
                 (not (public in MemBoard.BaseStat)) then begin
                TempTo:=allcaps(TempTo);
                if TempTo='SYSOP' then
                  un:=1
                else
                  un:=MatchUser(TempTo);
                  if un=0 then begin
                    spstr(86); {invalid user}
                    TempTo:=''; exit;
                  end;
                  SetFileAccess(ReadOnly,DenyNone);
                  reset(uf);

                  { If Email check for mail forwarding }

                  If (BoardReal=0) then begin
                    Fwd:=ForwardM(un);
                    if (Fwd>0) and (Fwd<>Un) then begin
                      un:=Fwd; spstr(736); {mail forwarded to}
                    end;
                  end;

                  if ((un>=1) and (un<=filesize(uf)-1)) then
                    begin
                      loadurec(uu,un);
                      if mbRealName in MemBoard.mbStat then
                        TempTo:=caps(uu.realname)
                      else
                        TempTo:=caps(uu.name);
                    end
                  else
                    begin
                      spstr(86); {invalid user}
                      TempTo:=''; close(uf); exit;
                    end;
                  close(uf);
              end;
            sprint(TempTo);
          end;
      end
    else
      begin
        if (fTo<>'') then
          begin
            i:=pos('@',fTo);
            if i=0 then exit;
            TempTo:=copy(fTo,1,i-1);
            Delete(fTo,1,i);
            OrigAddr:=Systat^.Aka[Memboard.aka];
            Move(OrigAddr,CurrAddr,sizeof(CurrAddr));
            ParseAddr(fTo,CurrAddr,DestAddr);
            If IsValidAddr(DestAddr) then
              begin
                Msg^.SetOrig(CurrAddr);
                Msg^.SetDest(DestAddr);
              end
            else
              begin
                spstr(737); {invalid address}
                exit;
              end;
          end
        else
          begin
            spstr(738); {address (z:n/n)}
            mpl(20);
            input(TempTo,20);
            OrigAddr:=Systat^.Aka[Memboard.aka];
            Move(OrigAddr,CurrAddr,sizeof(CurrAddr));
            ParseAddr(TempTo,CurrAddr,DestAddr);
            if IsValidAddr(DestAddr) then
              begin
                Msg^.SetOrig(CurrAddr);
                Msg^.SetDest(DestAddr);
              end
            else
              begin
                spstr(737); {invalid address}
                exit;
              end;
            spstr(739); {recipient's name}
            mpl(ToLen); TempTo:='';
            inputl(TempTo,ToLen);
            if TempTo='' then exit;
          end;

        if (mso) then begin
          dyny:=TRUE;
          if pynq(getstr(740)) then {set k/s flag}
            Msg^.SetKillSent(TRUE);
        end else
          Msg^.SetKillSent(TRUE);

      end;
    Msg^.SetTo(TempTo);
    if mbRealName in MemBoard.mbStat then
      Msg^.SetFrom(ThisUser.RealName)
    else
      Msg^.SetFrom(caps(ThisUser.Name));
    GetHeaderInfo:=TRUE;
  end; {proc GetHeaderInfo}

Begin
  ok:=TRUE;
  Post:=0; { If anything goes wrong, return 0 for no msg posted. }

  if ToU>0 then begin
    SetFileAccess(ReadOnly,DenyNone);
    reset(uf);
    if (ToU>filesize(uf)-1) then begin close(uf); exit; end;

    { Check for mail forwarding }
    Fwd:=ForwardM(ToU);
    If Fwd>0 then ToU:=Fwd;

    close(uf);
    loadurec(u,ToU);
    if (mbRealName in MemBoard.mbStat) then
      fTo:=u.RealName
    else
      fTo:=caps(u.name);
  end;

  If LoadBoard(BoardReal) then begin

    If (not aacs(memboard.postacs)) then nope(73); {no post acs}

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

                   If (BoardReal=0) and (ToU>0) then begin
                     i:=0; b:=ok;
                     while ((i<4) and (b)) do begin
                       inc(i); b:=MoreMail(u,ToU,i);
                       if (not b) then
                         case i of
                           1:if (not cso) then Nope(92); {mailbox full}
                           2:if (not cso) then Nope(93); {mailbox closed}
                           3:Nope(98); {user deleted}
                           4:if (not cso) then Nope(94); {can't send to self}
                         end;
                     end;

                     if (Mtyp=mtNormal) and (Networked in MemBoard.BaseStat) then
                       Mtyp:=mtNet;
                   end;
                  end;
        end; {case}
    end; {for t}

    if (not ok) then exit;

    If OpenOrCreateMsgArea(Msg, MemBoard.MsgAreaId,
                           MemBoard.MaxMsgs, MemBoard.MaxDays) then
      begin

        case Mtyp of
          mtNormal: Msg^.SetMailType(mmtNormal);
          mtEcho  : Msg^.SetMailType(mmtEchoMail);
          mtNet   : Msg^.SetMailType(mmtNetMail);
        end;

        Msg^.StartNewMsg;
        cantabort:=FALSE;

        case MemBoard.MsgAreaId[1] of
          'H': i:=5;
          'E': i:=6;
          else i:=2;
        end;

        if (freek(exdrv(MemBoard.MsgAreaId[i]))<systat^.MinSpaceForPost) then
          begin
            spstr(87);
            sysoplog('|R>>|w '+MemBoard.MsgAreaId[i]+': drive full!  Insufficient space to save a message.');
          end
        else
          if GetHeaderInfo then begin


            ok:=TRUE; DidUpload:=FALSE;

            if (not cantabort) then
              if pynq(getstr(89)) then {ul msg}
                begin
                  ok:=FALSE;
                  if (cso) and pynq(getstr(70)) then {local ul}
                    begin
                      spstr(71); {filename..}
                      input(s,40);
                      s:=fexpand(s);
                      if exist(s) then begin
                        MsgFName:=s; DidUpload:=TRUE; ok:=TRUE;
                      end else
                        spstr(81); {file not found}
                    end
                  else
                  if (spd<>'KB') then
                    begin
                      purgedir2(modemr^.temppath+'UPLOAD\');
                      repeat
                        oldfileboard:=fileboard; addbatch:=FALSE; fileboard:=-1; isqwk:=TRUE;
                        MsgFName:=modemr^.temppath+'UPLOAD\IMSGUL.'+cstr(nodenum);
                        receive1(MsgFName,FALSE,dok,kabort,addbatch);
                        isqwk:=FALSE; fileboard:=oldfileboard;
                        if addbatch then spstr(82); {batch n/a}
                      until not(addbatch);
                      if (dok) and (not kabort) and (exist(MsgFName)) then
                        begin
                          DidUpload:=TRUE; ok:=TRUE;
                        end
                      else
                        if (not kabort) then
                          spstr(85); {error uploading; not saved}
                    end
                  else
                    spstr(721); {remote uls not possible when local}
                end;

            if ok then
              begin

                if (not DidUpload) then
                  begin

                    if (okansi) then begin
                      if thisuser.edtype=1 then
                        usefse:=FALSE
                      else if thisuser.edtype=2 then
                        usefse:=TRUE
                      else
                        usefse:=pynq(getstr(722)); {use fse?}
                    end else usefse:=FALSE;

                    MsgFName:='I_TEMP1.'+cstr(nodenum);

                    if exist(MsgFName) then
                      begin
                        assign(f,MsgFName);
                        erase(f);
                      end;

                    if usefse then
                      ok:=fse(MsgFName,cantabort)
                    else
                      ok:=lineedit(MsgFName,cantabort);

                    if (not ok) then
                      spstr(741); {aborted}
                  end; {not didupload}

                if ok then
                  begin
                    if Msg^.IsFAttach then
                      begin
                        sprint('File attach not implemented yet.');
                      end; {if IsFAttach}

                    Msg^.SetCost(0);
                    Msg^.SetDate(DateStr(GetDosDate));
                    Msg^.SetTime(TimeStr(GetDosDate));
                    Msg^.SetLocal(TRUE);
                    Msg^.SetRcvd(FALSE);
                    if Private in MemBoard.BaseStat then
                      if (Msg^.GetSubj<>'All') then
                        Msg^.SetPriv(TRUE)
                      else
                        Msg^.SetPriv(FALSE);
                    Msg^.SetCrash(FALSE);
                    Msg^.SetSent(FALSE);

                    if (Private in MemBoard.BaseStat) then
                      if (Msg^.GetSubj<>'All') then
                        Msg^.SetReqRct(FALSE)
                        { Msg^.SetReqRct(pynq(getstr(723))) } {req return rec'pt Not Implimented} 
                      else
                        Msg^.SetReqRct(FALSE)
                    else
                      Msg^.SetReqRct(FALSE);

                    Msg^.SetReqAud(FALSE);
                    Msg^.SetRetRct(FALSE);
                    Msg^.SetFileReq(FALSE);
                    Msg^.SetEcho(TRUE);

                    Msg^.SetRefer(ReplyTo);

                    Msg^.DoKludgeLn(#1'USERNOTE: '+ThisUser.Usernote);
                    Msg^.DoKludgeLn(#1'MCI: '+aonoff(aacs(MemBoard.mciAcs),'ON','OFF'));

                    an:=MemBoard.AnStat;
                    if networked in MemBoard.BaseStat then an:=atno;

                    if (an=atyes) then begin
                      if (private in MemBoard.BaseStat) then begin
                        if not (aacs(systat^.anonprivpost)) then an:=atno;
                      end;

                      if (news in MemBoard.BaseStat) then
                        an:=atno;

                      if (public in MemBoard.BaseStat) then begin
                        if (not (aacs(systat^.anonpubpost))) then
                          an:=atno;
                      end;

                      if (rpostan in thisuser.ac) then
                        an:=atno;
                    end;

                    if (an=atyes) then
                      if pynq(getstr(724)) then an:=atforced;

                    if (an=atforced) then
                      begin
                        Msg^.DoKludgeLn(#1'REALFROM: '+Msg^.GetFrom);
                        Msg^.SetFrom(getstr(83));
                        Msg^.SetSent(TRUE);
                      end;

                    if (an=atAnyname) then
                      begin
                        spstr(742); {post any name, enter name}
                        input(TmpStr,36);
                        if TmpStr<>'' then begin
                          Msg^.DoKludgeLn(#1'REALFROM: '+Msg^.GetFrom);
                          Msg^.SetFrom(caps(TmpStr));
                        end;
                      end;

                    TF.Init;
                    if TF.OpenTextFile(MsgFName) then
                      begin
                        TmpStr:=stripthings(TF.GetString);
                        While TF.StringFound Do
                          begin
                            Msg^.DoStringLn(TmpStr);
                            TmpStr:=stripthings(TF.GetString);
                          end;
                      end;

                    if networked in MemBoard.BaseStat then
                      begin
                        Move(Systat^.aka[Memboard.aka],OAddr,sizeof(OAddr));
                        Msg^.DoStringLn('');
                        Msg^.DoStringLn('--- Illusion v'+ver);
                        Msg^.DoStringLn(' * Origin: '+getorigin+' ('+addrstr(OAddr)+')');
                      end;

                    if (Msg^.WriteMsg=0) then begin
                      spstr(743); {msg saved}
                      sysoplog('+ "'+Msg^.GetSubj+'" posted on '+memboard.name);
                      if (Msg^.GetTo<>'') then sysoplog('  To: "'+Msg^.GetTo+'"');
                      Post:=Msg^.GetMsgNum;
                      if networked in MemBoard.BaseStat then begin
                        assign(SemaFile,start_dir+'\ISCAN.NOW');
                        rewrite(SemaFile); Close(SemaFile);
                      end;
                      if private in MemBoard.BaseStat then begin
                        inc(thisuser.emailsent);
                        inc(etoday);
                        readsystat;
                        inc(systat^.todayzlog.privpost);
                        savesystat;
                      end else
                      if public in MemBoard.BaseStat then begin
                        inc(thisuser.msgpost);
                        inc(ptoday);
                        readsystat;
                        inc(systat^.todayzlog.pubpost);
                        savesystat;
                        if not (rvalidate in thisuser.ac) then
                          inc(thisuser.filepoints,systat^.postcredits);
                      end;

                    end else
                      spstr(744); {error saving msg}

                    If Tf.CloseTextFile Then;
                    Tf.Done;

                    if exist('I_TEMP1.'+cstr(nodenum)) then
                      begin
                        assign(f,'I_TEMP1.'+cstr(nodenum));
                        erase(f);
                      end;

                  end; {if ok}
              end; {if ok}
          end; {if getheaderinfo}
        CloseMsgArea(Msg);
      end
    else
      MsgOpenError;

  end else {if not loadboard}
  begin
    sprint('|RAn error has occured accessing the message board data.');
    sprint('|RThis could result from a file sharing violation.  Try');
    sprint('|Ragain in a few minutes.');
  end;

  if (exist('MsgTmp.'+cstr(nodenum))) then
    begin
      assign(f,'MsgTmp.'+cstr(nodenum));
      erase(f);
    end;
End;


End.
