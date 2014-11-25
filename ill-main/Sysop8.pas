(*****************************************************************************)
(* Illusion BBS - SysOp routines [8/11] (message base editor)                *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

Unit Sysop8;

Interface

USES
  crt, dos,
  common, mail0,
  MsgF, { Bslash, PurgeDir2 }
  sysop2o,
  MKMsgAbs, MKDos, MKString, MKFile, MKGlobT;

procedure boardedit;

Implementation

PROCEDURE BOARDEDIT;

const ltype:integer=1;
var s:string;
    ii:integer;
    c:char;
    abort,next,upause:boolean;

{><><><><><><><><><><><><><><><><><><><}

procedure reindex;
var brd:boardrec;
    i:integer;
    f:file;
begin
  nl;
  sprint('REP packets that haven''t been tossed yet may be');
  sprint('tossed in the wrong bases after reindexing.');
  nl; sprompt('Reindexing...');
  setfileaccess(readwrite,denyall);
  reset(bf);
  for i:=1 to filesize(bf) do
  begin
    seek(bf,i-1); read(bf,brd);
    brd.permindx:=i;
    if(exist(systat^.datapath+cstr(brd.permindx)+'.MSI')) then begin
      assign(f,systat^.datapath+cstr(brd.permindx)+'.MSI');
      rename(f,systat^.datapath+cstr(brd.permindx)+'.MSN');
    end;
    seek(bf,i-1); write(bf,brd);
  end;
  seek(bf,0);
  while not (eof(bf)) do
  begin
    read(bf,brd);
    if (exist(systat^.datapath+cstr(brd.permindx)+'.MSN')) then begin
      assign(f,systat^.datapath+cstr(brd.permindx)+'.MSN');
      rename(f,systat^.datapath+cstr(brd.permindx)+'.MSI');
    end;
  end;
  close(bf);
  print('done.'); nl;
  pausescr;
end; {reindex}

function newindexno(x:byte):byte;
var brd:boardrec;
    i,j:integer;
begin
  setfileaccess(readwrite,denynone);
  reset(bf);
  j:=-1;
  for i:=0 to filesize(bf)-1 do
  begin
    read(bf,brd);
    if (brd.permindx>j) then j:=brd.permindx;
  end;
  close(bf);
  inc(j);
  if j>998 then
  begin
    sprint('|WMessage bases must be reindexed.');
    reindex;
    newindexno:=x;
  end else
    newindexno:=j;
end; {newindexno}

function getbrdtype(c:char):string;
begin
  case c of
    'J':getbrdtype:='JAM';
{   'E':getbrdtype:='Ezycom'; }
    'F':getbrdtype:='Fidonet *.MSG';
    'H':getbrdtype:='Hudson';
    'S':getbrdtype:='Squish';
  end;
end;

function getareaidnum(s:string):string;
begin
  case s[1] of
    'H':getareaidnum:=copy(s,2,3);
{   'E':getareaidnum:=copy(s,2,4); }
  end;
end;

function hdup(i:byte):astr;
var s:astr;
begin
  fillchar(s[1],i,^H);
  s[0]:=chr(i);
  hdup:=s;
end;

FUNCTION msgcnvt(inm,outm:string):boolean;
Var
  MsgIn: AbsMsgPtr;                    {pointer to input message object}
  MsgOut: AbsMsgPtr;                   {pointer to output message object}
  TmpStr: String;                      {temporary storage}
  TmpAddr: AddrType;                   {temporary address storage}
  PriorWrap: Boolean;                  {prior text line was wrapped}
  msg,lin:word;
Const
  StLen = 78;                          {wrap strings at 78 characters}
begin
  If Not OpenMsgArea(MsgIn, Inm) Then
  begin
    sprint('Unable to open input message base.');
    msgcnvt:=false;
    exit;
  end;
  if openmsgarea(msgout, outm) then
  begin
    sprint('Output message base already exists.');
    msgcnvt:=false;
    exit;
  end;
  If Not OpenOrCreateMsgArea(MsgOut, Outm,memboard.maxmsgs,memboard.maxdays) Then
  begin
    sprint('Unable to open/create output message base.');
    msgcnvt:=false;
    exit;
  end;
  MsgOut^.SetMailType(mmtNormal);
  If MsgOut^.LockMsgBase Then;
  MsgIn^.SeekFirst(1);                   {Start at begining of msg base}
  msg:=1;
  While MsgIn^.SeekFound Do
    Begin
    sprompt('Msg '+cstr(msg)+', Header  ');
    prompt(Hdup(8));
    lin:=1; inc(msg);
    MsgIn^.MsgStartUp;                   {Initialize input msg}
    MsgOut^.StartNewMsg;                 {Initialize output msg}
    MsgIn^.MsgTxtStartUp;                {Initialize input msg text}
    MsgIn^.GetDest(TmpAddr);             {Set header fields}
    MsgOut^.SetDest(TmpAddr);
    MsgIn^.GetOrig(TmpAddr);
    MsgOut^.SetOrig(TmpAddr);
    MsgOut^.SetFrom(MsgIn^.GetFrom);
    MsgOut^.SetTo(MsgIn^.GetTo);
    MsgOut^.SetSubj(MsgIn^.GetSubj);
    MsgOut^.SetCost(MsgIn^.GetCost);
    MsgOut^.SetRefer(MsgIn^.GetRefer);
    MsgOut^.SetSeeAlso(MsgIn^.GetSeeAlso);
    MsgOut^.SetDate(MsgIn^.GetDate);
    MsgOut^.SetTime(MsgIn^.GetTime);
    MsgOut^.SetLocal(MsgIn^.IsLocal);
    MsgOut^.SetRcvd(MsgIn^.IsRcvd);
    MsgOut^.SetPriv(MsgIn^.IsPriv);
    MsgOut^.SetCrash(MsgIn^.IsCrash);
    MsgOut^.SetKillSent(MsgIn^.IsKillSent);
    MsgOut^.SetSent(MsgIn^.IsSent);
    MsgOut^.SetFAttach(MsgIn^.IsFAttach);
    MsgOut^.SetReqRct(MsgIn^.IsReqRct);
    MsgOut^.SetRetRct(MsgIn^.IsRetRct);
    MsgOut^.SetFileReq(MsgIn^.IsFileReq);
    MsgOut^.SetEcho(False);
    PriorWrap := MsgIn^.WasWrap;
    TmpStr := MsgIn^.GetString(StLen);   {Get line of message text}
    While (Not MsgIn^.EOM) or (Length(TmpStr) > 0) Do
      Begin
      sprompt('Line '+cstr(lin));
      prompt(Hdup(5+length(cstr(lin))));
      inc(lin);
      If ((TmpStr[1] = #1) and (Not PriorWrap)) Then
        MsgOut^.DoKludgeLn(TmpStr)       {Save as ^A Kludge line}
      Else
        Begin
        If MsgIn^.WasWrap Then
          MsgOut^.DoString(TmpStr)       {Save as normal text}
        Else
          MsgOut^.DoStringLn(TmpStr);    {Save as normal text with CR}
        End;
      TmpStr := MsgIn^.GetString(StLen); {Get next line of message text}
      End;
    prompt(Hdup(6+length(cstr(msg))));
    If MsgOut^.WriteMsg <> 0 Then;       {Save the message}
    MsgIn^.SeekNext;                     {Seek next message}
    End;
  If MsgOut^.UnLockMsgBase Then;
  If Not CloseMsgArea(MsgIn) Then;
  If Not CloseMsgArea(MsgOut) Then;
  msgcnvt:=true;
end;

procedure bem1;
var s1:string;
    c:char;
    convert:boolean;
    i:integer;
begin
  with memboard do
  begin
    s1:=msgareaid;
    cls;
    sprint('|WMessage Base ['+cstr(ii)+'/'+cstr(numboards)+']|LC');
    nl;
    sprint('|cBase format     |w'+getbrdtype(msgareaid[1])+'|LC');
    case msgareaid[1] of
      'J',
      'S':sprint('|cFilename        |w'+copy(msgareaid,2,length(msgareaid)-1)+'|LC');
{     'E', }
      'H':sprint('|cBoard number    |w'+getareaidnum(msgareaid)+'|LC');
     else sprint('|cBoard path      |w'+copy(msgareaid,2,length(msgareaid)-1)+'|LC');
    end;
    nl;
{   sprint('|K[|CE|K] |cEzycom'); }
    sprint('|K[|CF|K] |cFidonet *.MSG');
    sprint('|K[|CH|K] |cHudson');
    sprint('|K[|CJ|K] |cJAM');
    sprint('|K[|CS|K] |cSquish');
    nl;
    sprompt('|wBase Format |K[|CQ|c:uit|K] |W');
{   onek(c,'EFHJSQ'); }
    onek(c,'FHJSQ');
    nl;
{   if (pos(c,'EFHJS')<>0) then }
    if (pos(c,'FHJS')<>0) then
    begin
      s1:=c;
      convert:=true;
      s:='';
      case s1[1] of
        'F':begin
              sprompt('Enter new message path: ');
              inputed(s,40,'OSUB');
              s:=sqoutsp(s);
              if (s<>'') then
              begin
                while (copy(s,length(s)-1,2)='\\') do s:=copy(s,1,length(s)-1);
                if (copy(s,length(s),1)<>'\') then s:=s+'\';
                if (not existdir2(s)) then
                begin
                  nl;
                  print('"'+s+'" does not exist.');
                  if (pynq('Create message directory now')) then
                  begin
                    {$I-} mkdir(bslash(FALSE,s)); {$I+}
                    if (ioresult<>0) then
                    begin
                      print('Errors creating directory.');
                      convert:=false;
                    end;
                  end;
                end else
                begin
                  nl;
                  print('"'+s+'" ALREADY EXISTS!');
                  nl;
                end;
              end else
                convert:=false;
              s1:=s1+s;
            end; {F}
        'J',
        'S':begin
              sprompt('Enter new filename (no ext): ');
              inputed(s,8,'OSU');
              s:=sqoutsp(s);
              if (pos('.',s)>0) then s:=copy(s,1,pos('.',s)-1);
              if (s='') then convert:=false;
              if (s1[1]='J') then s1:=s1+systat^.jampath+s
                             else s1:=s1+systat^.squishpath+s;
            end;
{       'E', }
        'H':begin
              sprompt('Enter new board number ');
              case s1[1] of
                'H':prompt('(1-200): ');
{               'E':prompt('(1-1024): '); }
              end;
              mpl(5);
              inu(i);
              if (not badini) then
              begin
                case s1[1] of
                  'H':if (i in [1..200]) then
                        s1:=s1+padleft(cstr(i),'0',3)+systat^.hudsonpath
                      else
                        convert:=false;
{                 'E':if (i>0) and (i<1025) then
                        s1:=s1+padleft(cstr(i),'0',4)+systat.ezycompath
                      else
                        convert:=false; }
                end;
              end else
                convert:=false;
            end;
      end; {case}

      if (convert) then
      begin
        nl;
        if (pynq('Convert message base to new format')) then
        begin
          if (memboard.msgareaid<>s1) then
          begin
            sprompt('Converting... ');
            if (msgcnvt(memboard.msgareaid,s1)) then
            begin
              sprint('Conversion successful.');
              memboard.msgareaid:=s1;
            end else
            begin
              sprint('Conversion unsuccessful.');
              if (pynq('Save base information anyway')) then
                memboard.msgareaid:=s1;
            end;
            pausescr;
          end;
        end else
        begin
          sprint('Base not converted.  You may have old message files that');
          sprint('are no longer used and can be deleted.');
          memboard.msgareaid:=s1;
          pausescr;
        end;
      end;
    end;
  end;
end;

procedure bem;
var s:string;
    i,xloaded:integer;
    c:char;
    b:byte;

  function anstattype:string;
  begin
    case memboard.anstat of
      atyes:    anstattype:='Optional   ';
      atno:     anstattype:='Not allowed';
      atforced: anstattype:='Forced     ';
      atanyname:anstattype:='Any name   ';
    end;
  end;

  function msgscantype:string;
  begin
    case memboard.scantype of
      0:msgscantype:='Default on ';
      1:msgscantype:='Default off';
      2:msgscantype:='Mandatory  ';
    end;
  end;

begin
  sprompt('|wEdit message base |K[|C0|c-|C'+cstr(numboards)+'|K] |W');
  inu(ii);
  c:=#0;
  xloaded:=-1;
  if (ii>=0) and (ii<=numboards) then
  begin
    exclude(thisuser.ac,pause);
    while (c<>'Q') and (not hangup) do
    begin
      if (xloaded<>ii) then
      begin
        setfileaccess(readwrite,denynone);
        reset(bf);
        seek(bf,ii);
        read(bf,memboard);
        close(bf);
        xloaded:=ii;
      end;
      with memboard do
        repeat
          if (c in [#0,^M,'[',']','J','P']) then
          begin
            if (c in [#0,^M,'P']) then cls else ansig(1,1);
            sprint('|WMessage Base ['+cstr(ii)+'/'+cstr(numboards)+']');
            nl;
            sprint('|K[|CA|K] |cBase name       |w'+name+'|LC');
            sprint('|K[|CB|K] |cQWK name        |w'+mln(qwkname,20)+
                 ' |K[|CR|K] |cMessage header        |w'+msgheaderfile+'|LC');
            sprint('|K[|CC|K] |cRequired access |w'+mln(aonoff(ii=0,'not used',acs),20)+
                 ' |K[|CS|K] |cPublic                |w'+syn(public in basestat));
            sprint('|K[|CD|K] |cSubOp access    |w'+mln(aonoff(ii=0,'not used',subopacs),20)+
                 ' |K[|CT|K] |cPrivate               |w'+syn(private in basestat));
            sprint('|K[|CE|K] |cAccess to post  |w'+mln(aonoff(ii=0,'not used',postacs),20)+
                 ' |K[|CU|K] |cNetwork               |w'+syn(networked in basestat));
            sprint('|K[|CF|K] |cUse MCI access  |w'+mln(mciacs,20)+
                 ' |K[|CV|K] |cNews                  |w'+syn(news in basestat));
            sprint('|K[|CG|K] |cFile attach acs |w'+mln(attachacs,20)+
                 ' |K[|CW|K] |cAnonymous             |w'+anstattype);
            sprint('|K[|CH|K] |cMaximum msgs    |w'+mn(maxmsgs,20)+
                  ' |K[|CX|K] |cUse real names        |w'+syn(mbrealname in mbstat));
            sprint('|K[|CI|K] |cMaximum days    |w'+mn(maxdays,20)+
                  ' |K[|CY|K] |cVisible to all        |w'+syn(mbvisible in mbstat));
            sprint('|K[|CJ|K] |cNetwork address |w'+mln(aonoff(networked in basestat,
                                          getaddr(systat^.aka[aka])+' ('+cstr(aka)+')','not used'),20)+
                  ' |K[|CZ|K] |cFilter high ascii     |w'+syn(mbfilter in mbstat));
            sprint('|K[|CK|K] |cText color      |w'+mln(text_color,20)+
                  ' |K[|C1|K] |cStrip special codes   |w'+syn(mbstrip in mbstat));
            sprint('|K[|CL|K] |cQuoting color   |w'+mln(quote_color,20)+
                  ' |K[|C2|K] |cAdd tear/origin lines |w'+syn(mbaddtear in mbstat));
            sprint('|K[|CM|K] |cTear line color |w'+mln(tear_color,20)+
                  ' |K[|C3|K] |cStrip color codes     |w'+syn(mbnocolor in mbstat));
            sprint('|K[|CN|K] |cOrigin line clr |w'+mln(origin_color,20)+
                  ' |K[|C4|K] |cScan type             |w'+msgscantype);
            sprint('    |cPermanent index |w'+mn(permindx,20)+
                  ' |K[|C5|K] |cIn email scan         |w'+syn(emailscan));
            sprint('|K[|CO|K] |cOrigin line     |w'+aonoff(networked in basestat,origin,'not used')+'|LC');
            nl;
            sprint('|K[|CP|K] |cBase format     |w'+getbrdtype(msgareaid[1])+'|LC');
            case msgareaid[1] of
              'J',
              'S':sprint('    |cFilename        |w'+copy(msgareaid,2,length(msgareaid)-1)+'|LC');
{             'E', }
              'H':sprint('    |cBoard number    |w'+getareaidnum(msgareaid)+'|LC');
             else sprint('    |cBoard path      |w'+copy(msgareaid,2,length(msgareaid)-1)+'|LC');
            end;
            nl;
            sprompt('|wCommand |K[|C[|K/|C]|K/|CQ|c:uit|K] |W');
          end;
          ansig(21,23);
          sprompt(#32+^H+'|W');

          onekcr:=FALSE;
          if (ii=0) then                  onek(c,'QABFGHIKLMNPRWXYZ1234[]'^M) else
          if (networked in basestat) then onek(c,'QABCDEFGHIJKLMNOPRSTUVXYZ12345[]'^M) else
          if (news in basestat)      then onek(c,'QABCDEFGHIKLMNPRSTUVXYZ12345[]'^M)
                                     else onek(c,'QABCDEFGHIKLMNPRSTUVWXYZ12345[]'^M);
          onekcr:=TRUE; cl(ord('w'));

          case c of
            'A':begin
                  ansig(21,3);
                  inputed(name,40,'O');
                end;
            'B':inputxy(21,4,qwkname,12);
            'C':inputxy(21,5,acs,20);
            'D':inputxy(21,6,subopacs,20);
            'E':inputxy(21,7,postacs,20);
            'F':inputxy(21,8,mciacs,20);
            'G':inputxy(21,9,attachacs,20);
            'H':maxmsgs:=inputnumxy(21,10,maxmsgs,5,10,65535);
            'I':maxdays:=inputnumxy(21,11,maxdays,5,10,65535);
            'J':begin
                  cls;
                  sprint('|WMessage Base ['+cstr(ii)+'/'+cstr(numboards)+']');
                  nl;
                  for i:=1 to 10 do
                    sprint('|K[|C'+chr(i+64)+'|K] |c'+mln(getaddr(systat^.aka[i]),30)+
                           '|K[|C'+chr(i+74)+'|K] |c'+getaddr(systat^.aka[i+10]));
                  nl;
                  sprompt('|wNetwork address |K[|CA|c-|CT|K] |W');
                  onek(c,'ABCDEFGHIJKLMNOPQRST'^M);
                  if (c in ['A'..'T']) then aka:=ord(c)-64;
                  c:=#0;
                end;
            'K':inputcharxy(21,13,text_color);
            'L':inputcharxy(21,14,quote_color);
            'M':inputcharxy(21,15,tear_color);
            'N':inputcharxy(21,16,origin_color);
            'O':inputxy(21,18,origin,50);
            'P':bem1;
            'R':inputxy(68,4,msgheaderfile,-8);
            'S':begin
                  if (public in basestat) then
                  begin
                    exclude(basestat,public); include(basestat,private);
                  end else
                    include(basestat,public);
                  ansig(68,5); sprompt(syn(public in basestat));
                  ansig(68,6); sprompt(syn(private in basestat));
                end;
            'T':begin
                  if (private in basestat) then
                  begin
                    exclude(basestat,private); include(basestat,public);
                    emailscan:=FALSE;
                  end else
                    include(basestat,private);
                  ansig(68,5);  sprompt(syn(public in basestat));
                  ansig(68,6);  sprompt(syn(private in basestat));
                  ansig(68,17); sprompt(syn(emailscan));
                end;
            'U':begin
                  if (networked in basestat) then
                  begin
                    exclude(basestat,networked);
                    exclude(mbstat,mbstrip);
                    exclude(mbstat,mbaddtear);
                  end else
                  begin
                    include(basestat,networked);
                    if (systat^.strip) then include(mbstat,mbstrip)
                                      else exclude(mbstat,mbstrip);
                    if (systat^.addtear) then include(mbstat,mbaddtear)
                                        else exclude(mbstat,mbaddtear);
                  end;
                  ansig(68,7);  sprompt(syn(networked in basestat));
                  ansig(68,13); sprompt(syn(mbstrip in mbstat));
                  ansig(68,14); sprompt(syn(mbaddtear in mbstat));
                  ansig(21,12); sprompt(mln(aonoff(networked in basestat,'|w'+
                    getaddr(systat^.aka[aka])+' ('+cstr(aka)+')','not used'),20));
                  ansig(21,18); sprompt('|w'+aonoff(networked in basestat,origin,
                    'not used')+'|LC');
                end;
            'V':begin
                  if (news in basestat) then basestat:=[public]
                                        else basestat:=[news];
                  ansig(68,5); sprompt(syn(public in basestat));
                  ansig(68,6); sprompt(syn(private in basestat));
                  ansig(68,7); sprompt(syn(networked in basestat));
                  ansig(68,8); sprompt(syn(news in basestat));
                end;
            'W':begin
                  if (anstat=atyes) then anstat:=atno else
                  if (anstat=atno) then anstat:=atforced else
                  if (anstat=atforced) then anstat:=atanyname else
                  if (anstat=atanyname) then anstat:=atyes;
                  ansig(68,9); sprompt(anstattype);
                end;
            'X':begin
                  if (mbrealname in mbstat) then exclude(mbstat,mbrealname)
                                            else include(mbstat,mbrealname);
                  ansig(68,10); sprompt(syn(mbrealname in mbstat));
                end;
            'Y':begin
                  if (mbvisible in mbstat) then exclude(mbstat,mbvisible)
                                           else include(mbstat,mbvisible);
                  ansig(68,11); sprompt(syn(mbvisible in mbstat));
                end;
            'Z':begin
                  if (mbfilter in mbstat) then exclude(mbstat,mbfilter)
                                          else include(mbstat,mbfilter);
                  ansig(68,12); sprompt(syn(mbfilter in mbstat));
                end;
            '1':begin
                  if (mbstrip in mbstat) then exclude(mbstat,mbstrip)
                                         else include(mbstat,mbstrip);
                  ansig(68,13); sprompt(syn(mbstrip in mbstat));
                end;
            '2':begin
                  if (mbaddtear in mbstat) then exclude(mbstat,mbaddtear)
                                           else include(mbstat,mbaddtear);
                  ansig(68,14); sprompt(syn(mbaddtear in mbstat));
                end;
            '3':begin
                  if (mbnocolor in mbstat) then exclude(mbstat,mbnocolor)
                                           else include(mbstat,mbnocolor);
                  ansig(68,15); sprompt(syn(mbnocolor in mbstat));
                end;
            '4':begin
                  if (scantype<2) then inc(scantype) else scantype:=0;
                  ansig(68,16); sprompt(msgscantype);
                end;
            '5':switchyn(68,17,emailscan);
            '[':if (ii>0) then dec(ii) else ii:=numboards;
            ']':if (ii<numboards) then inc(ii) else ii:=0;
          end;
        until (pos(c,'Q[]')<>0) or (hangup);
      setfileaccess(readwrite,denynone);
      reset(bf);
      seek(bf,xloaded);
      write(bf,memboard);
      close(bf);
    end;
    if (upause) then include(thisuser.ac,pause);
  end;
end;

procedure bed(x:integer);
var j:integer;
begin
  if ((x>0) and (x<=numboards)) then
  begin
    assign(msgzscanf,systat^.datapath+cstr(memboard.permindx)+'.MSI');
    {$I-} erase(msgzscanf); {$I+}
    setfileaccess(readwrite,denyall);
    reset(bf);
    if (x>0) and (x<=filesize(bf)-2) then
      for j:=x to filesize(bf)-2 do
      begin
        seek(bf,j+1);
        read(bf,memboard);
        seek(bf,j);
        write(bf,memboard);
      end;
    seek(bf,filesize(bf)-1);
    truncate(bf);
    close(bf);
    dec(numboards);
  end;
end;

procedure erasefn(fn:astr);
var f:file;
begin
  assign(f,fn);
  erase(f);
end;

procedure bedmsg(areaid:string);
var s:astr;
begin
  case areaid[1] of
    'J':begin
          s:=copy(areaid,2,length(areaid)-1);
          if (exist(s+'.JDT')) then erasefn(s+'.JDT');
          if (exist(s+'.JDX')) then erasefn(s+'.JDX');
          if (exist(s+'.JHR')) then erasefn(s+'.JHR');
          if (exist(s+'.JLR')) then erasefn(s+'.JLR');
        end;
    'S':begin
          s:=copy(areaid,2,length(areaid)-1);
          if (exist(s+'.SQD')) then erasefn(s+'.SQD');
          if (exist(s+'.SQI')) then erasefn(s+'.SQI');
          if (exist(s+'.SQL')) then erasefn(s+'.SQL');
        end;
{   'E':begin
          sprint('I don''t know how to do that yet.');
        end; }
    'H':begin
          sprint('This hasn''t been programmed yet.');
        end;
    'F':begin
          s:=copy(areaid,2,length(areaid)-1);
          purgedir2(s);
          while (s[length(s)]='\') do s:=copy(s,1,length(s)-1);
          rmdir(s);
        end;
  end;
end;

procedure bei(x:integer);
var j:integer;
    msg:absmsgptr;
begin
  setfileaccess(readwrite,denyall);
  reset(bf);
  if (x>0) and (x<=filesize(bf)) then
  begin
    for j:=filesize(bf)-1 downto x do
    begin
      seek(bf,j);
      read(bf,memboard);
      write(bf,memboard); { ...to next record }
    end;

    with memboard do
    begin
      permindx:=newindexno(x);
      name:='[ New Message Base ]';
      qwkname:='Newboard';
      msgareaid:='J'+systat^.jampath+'NEWBOARD';
      emailscan:=false;
      msgheaderfile:='MSGHEAD';

      acs:='s50';
      subopacs:=systat^.msop;
      postacs:='s50';
      mciacs:='%';

      maxmsgs:=100;
      maxdays:=10;
      anstat:=atno;
      mbstat:=[];
      basestat:=[public];

      if (systat^.origin<>'') then
        origin:=systat^.origin
      else
        origin:=copy(stripcolor(systat^.bbsname),1,50);
      text_color:=systat^.text_color;
      quote_color:=systat^.quote_color;
      tear_color:=systat^.tear_color;
      origin_color:=systat^.origin_color;
      aka:=1;
      scantype:=0;

      fillchar(res1,sizeof(res1),#0);

    end;

    reset(bf);
    seek(bf,x);
    write(bf,memboard);

    if (openorcreatemsgarea(msg,memboard.msgareaid,memboard.maxmsgs,memboard.maxdays)) then;
    if (closemsgarea(msg)) then;
    inc(numboards);

  end;

  close(bf);

  assign(msgzscanf,systat^.datapath+cstr(memboard.permindx)+'.MSI');
  SetFileAccess(ReadWrite,DenyAll);
  rewrite(msgzscanf);
  msgzscan.mailscan:=true;
  msgzscan.qwkscan:=true;
  SetFileAccess(ReadOnly,DenyNone);
  reset(uf);
  for j:=1 to filesize(uf) do write(msgzscanf,msgzscan);
  close(uf);
  close(msgzscanf);
end;

procedure bep(x,y:integer);
var tempboard:boardrec;
    i,j:integer;
begin
  if (y>x) then dec(y);
  setfileaccess(readwrite,denyall);
  reset(bf);
  seek(bf,x);
  read(bf,tempboard);
  i:=x;
  if (x>y) then j:=-1 else j:=1;
  while (i<>y) do
  begin
    if (i+j<filesize(bf)) then
    begin
      seek(bf,i+j);
      read(bf,memboard);
      seek(bf,i);
      write(bf,memboard);
    end;
    inc(i,j);
  end;
  seek(bf,y);
  write(bf,tempboard);
  close(bf);
end; {bep}

procedure bepi;
var i,j:integer;
begin
  sprompt('|wMove message base |K[|C1|c-|C'+cstr(numboards)+'|K] |W');
  inu(i);
  if ((not badini) and (i>=1) and (i<=numboards)) then
  begin
    sprompt('|wMove before |K[|C1|c-|C'+cstr(numboards+1)+'|K] |W');
    inu(j);
    if ((not badini) and (j>=1) and (j<=numboards+1) and (j<>i) and (j<>i+1)) then
    begin
      nl;
      bep(i,j);
    end;
  end;
end;

function anont(a:anontyp):string;
begin
  case a of
    atyes    :anont:='Y';
    atno     :anont:='N';
    atforced :anont:='F';
    atanyname:anont:='AN';
  end;
end;

function flagstate(mb:boardrec):string;
var s:string[7];
begin
  s:='';
  with mb do
  begin
    if (mbrealname in mbstat) then s:=s+'R' else s:=s+'-';
    if (mbvisible in mbstat) then s:=s+'V' else s:=s+'-';
    if (mbfilter in mbstat) then s:=s+'F' else s:=s+'-';
    if (mbstrip in mbstat) then s:=s+'S' else s:=s+'-';
    if (mbaddtear in mbstat) then s:=s+'T' else s:=s+'-';
    if (mbnocolor in mbstat) then s:=s+'C' else s:=s+'-';
    if (mbnotwit in mbstat) then s:=s+'I' else s:=s+'-';
  end;
  flagstate:=s;
end;

begin
  c:=#0;
  upause:=pause in thisuser.ac;
  repeat
    abort:=FALSE; next:=FALSE;
    cls;
    case ltype of
      1:sprint('#   Message base name             Flags     ACS        SubOp ACS  Post ACS');
      2:sprint('#   Message base name             QWK Name     MaxM MaxD Idx An');
      3:sprint('#   Message base name             Colors  Base format data');
      4:sprint('#   Message base name             Address     Origin line');
    end;
    sprint('|K|LI');
    ii:=0;
    setfileaccess(readwrite,denynone);
    reset(bf);
    while (ii<=numboards) and (not abort) and (not hangup) do
    begin
      seek(bf,ii); read(bf,memboard);
      with memboard do
        case ltype of
          1:sprint('|W'+mn(ii,3)+' |w'+mln(memboard.name,29)+' |w'+msgareaid[1]+','+
                   flagstate(memboard)+' '+mln(aonoff(ii>0,acs,'N/A'),10)+' '+
                   mln(aonoff(ii>0,subopacs,'N/A'),10)+' '+mln(aonoff(ii>0,postacs,'N/A'),10));
          2:sprint('|W'+mn(ii,3)+' |w'+mln(memboard.name,29)+' |w'+mln(qwkname,12)+' '+
                   mn(maxmsgs,4)+' '+mn(maxdays,4)+' '+mn(permindx,3)+' '+anont(anstat));
          3:sprint('|W'+mn(ii,3)+' |w'+mln(memboard.name,29)+' |w'+
                   text_color+','+quote_color+','+tear_color+','+origin_color+
                   ' '+mln(copy(msgareaid,2,length(msgareaid)-1),37));
          4:sprint('|W'+mn(ii,3)+' |w'+mln(memboard.name,29)+' |w'+
                   aonoff(networked in basestat,mln(getaddr(systat^.aka[aka]),11)+' '+mln(origin,33),'N/A'));
        end;
      wkey(abort,next);
      inc(ii);
    end;
    boardloaded:=1;
    if loadboard(1) then;
    sprint('|K|LI');
    sprompt('|wMessage Base Editor |K[|CD|c:elete|K/|CI|c:nsert|K/|CE|c:dit|K/|CM|c:ove|K/|CT|c:oggle|K/'+
            '|CR|c:enumber|K/|CQ|c:uit|K] |W');
    onek(c,'QDIEMTR'^M);
    case c of
      'D':begin
            sprompt('|wDelete message base |K[|C1|c-|C'+cstr(numboards)+'|K] |W');
            inu(ii);
            if ((not badini) and (ii>=1) and (ii<=numboards) and (numboards>1)) then
            begin
              boardloaded:=0;
              if loadboard(ii) then;
              s:=memboard.msgareaid;
              sysoplog('* Deleted message base: '+memboard.name);
              bed(ii);
              if (pynq('Delete message files')) then bedmsg(s);
            end;
          end;
      'I':begin
            sprompt('|wInsert before |K[|C1|c-|C'+cstr(numboards+1)+'|K] |W');
            inu(ii);
            if ((not badini) and (ii>0) and (ii<=numboards+1)) then
            begin
              sysoplog('* Inserted new message base');
              bei(ii);
            end;
          end;
      'E':bem;
      'M':bepi;
      'T':ltype:=ltype mod 4+1;  { toggle between 1, 2, 3 & 4 }
      'R':reindex;
    end;
  until ((c='Q') or (hangup));
  if (systat^.compressmsgbases) then newcomptables;
  if (upause) then include(thisuser.ac,pause);
  if (board>numboards) then board:=1;
  boardloaded:=0;
  if loadboard(board) then;
end;

end.
