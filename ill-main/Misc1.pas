(*****************************************************************************)
(* Illusion BBS - Miscellaneous [1/3]                                        *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit misc1;

interface

uses
  crt, dos,
  common, mmsound;

procedure reqchat(x:astr);
procedure timebank(s:astr);
function ctp(t,b:longint):astr;
procedure vote;
procedure lotto;

implementation

uses mail4;

procedure reqchat(x:astr);
var c,ii,i,j:integer;
    r,xcc:char;
    chatted,override:boolean;
    s,ss,why:astr;

  function playarray(nn:char):boolean;
  var i,max:integer;
      r:char;
      starttime,nexttime:real;
  begin
    playarray:=FALSE;
    i:=1;

    case nn of
      '1':max:=bach2max;
      '2':max:=toreodormax;
      '3':max:=rondomax;
      '4':max:=joplin1max;
      '5':max:=inventiomax;
      '6':max:=havamax;
      '7':max:=elisemax;
      '8':max:=bethovenmax;
    end;

    starttime:=timer;
    nexttime:=2.2;

    while (i<=max) and (timer-starttime<20.0) do
    begin

      case nn of
        '1':begin if not(shutupchatcall) then sound(bach2[i,1]);     sleep(bach2[i,2]);     end;
        '2':begin if not(shutupchatcall) then sound(toreodor[i,1]);  sleep(toreodor[i,2]);  end;
        '3':begin if not(shutupchatcall) then sound(rondo[i,1]);     sleep(rondo[i,2]);     end;
        '4':begin if not(shutupchatcall) then sound(joplin1[i,1]);   sleep(joplin1[i,2]);   end;
        '5':begin if not(shutupchatcall) then sound(inventio[i,1]);  sleep(inventio[i,2]);  end;
        '6':begin if not(shutupchatcall) then sound(hava[i,1]);      sleep(hava[i,2]);      end;
        '7':begin if not(shutupchatcall) then sound(elise[i,1]);     sleep(elise[i,2]);     end;
        '8':begin if not(shutupchatcall) then sound(bethoven[i,1]);  sleep(bethoven[i,2]);  end;
      end;

      nosound;
      inc(i);

      if (timer-starttime>nexttime) and (nexttime<20.0) then
      begin
        spstr(167);
        nexttime:=nexttime+2.2;
      end;

      if keypressed then
      begin
        r:=readkey;
        case r of
           #0:begin
                r:=readkey;
                if ord(r)<>F10 then skey1(r);
              end;
          #32:begin
                playarray:=TRUE;
                exit;
              end;
           ^M:shutupchatcall:=TRUE;
        end;
      end;

    end;
  end;

begin
  why:='';
  override:=FALSE;

  if (pos(';',x)<>0) then
    why:=copy(x,pos(';',x)+1,length(x));
  if (why='') then
    why:=getstr(161);

  if ((chatt<systat^.maxchat) or (cso)) then
  begin

    spstr(151);
    sprompt(why);
    chatted:=FALSE;
    mpl(65); inputl(s,65);

    if (s='') then
    begin

      spstr(278);
      for j:=1 to 9 do
      begin
        ss:=getstr(151+j);
        if (ss<>'') then sprint('|w'+chr(48+j)+'. '+ss);
      end;

      spstr(324);
      onek(xcc,'0123456789'^M);
      nl;

      case xcc of
        ^M,'0':s:='';
        '1'..'9':s:=stripcolor(getstr(151+ord(xcc)-48));
      end;

    end;

    if s='' then exit;

    inc(chatt);
    if ((not sysop) and (aacs(systat^.emergchat)) and (not(rchat in thisuser.ac))) then
      override:=pynq(getstr(163));

    if (((not sysop) or (rchat in thisuser.ac)) and (not(override))) then
      sysoplog('Chat attempt (not paged): '+s)
    else
    begin

      ss:='Chat attempt ';
      if (override) then
        ss:=ss+'(emergency): '
      else
        ss:=ss+'(paged): ';
      sysoplog(ss+s);
      nl;

      if (systat^.specialfx and 2=2) then
      begin

        spstr(162);
        onek(xcc,'012345678'^M);
        if ((xcc=^M) or (xcc='0')) then exit;
        spstr(166);

        if playarray(xcc) then
        begin
          commandline('');
          chatted:=TRUE; chatt:=0;
          chat(systat^.splitchat);
        end;

      end else
      begin

        spstr(166);
        commandline(s);

        ii:=0;
        c:=0;

        repeat

          inc(ii);
          spstr(167);

          if (shutupchatcall) then
            sleep(993)
          else
          begin
            for j:=70 to 400 do
            begin
              sound(j);
              sleep(1);
            end;
            for j:=400 downto 200 do
            begin
              sound(j);
              sleep(2);
            end;
            nosound;
            sleep(20);
            for j:=1 to 2 do
            begin
              sound(600);
              sleep(50);
              nosound;
              sleep(20);
            end;
            sleep(100);
          end;

          nosound;

          if (keypressed) then
          begin
            r:=readkey;
            case r of
               #0:begin
                    r:=readkey;
                    if ord(r)<>F10 then skey1(r);
                  end;
              #32:begin
                   commandline('');
                   chatted:=TRUE; chatt:=0;
                   chat(systat^.splitchat);
                 end;
              ^M:shutupchatcall:=TRUE;
            end;
          end;

        until ((chatted) or (ii=9) or (hangup));

        commandline('');

      end;
    end;

    if (not chatted) then
    begin
      chatr:=s;
      commandline(s);
      spstr(442);
      if (value(x)<>0) then
        AskSendMail(value(x),'Tried chatting on '+date+' at '+time+'.');
    end else
    begin
      chatr:='';
      tleft;
    end;

  end else
  begin  { if not chatt<systat.maxchat }
    spstr(443);
    sysoplog('Tried chatting more than '+cstr(systat^.maxchat)+' times');
  end;
end;

procedure timebank(s:astr);
var lng,maxperday,maxever:longint;
    zz:integer;
    oc:astr;
    c:char;

  function cantdeposit:boolean;
  begin
    cantdeposit:=TRUE;
    if ((thisuser.timebankadd>=maxperday) and (maxperday<>0)) then exit;
    if ((thisuser.timebank>=maxever) and (maxever<>0)) then exit;
    cantdeposit:=FALSE;
  end;

begin
  maxperday:=value(s);
  maxever:=0;

  if (pos(';',s)<>0) then
    maxever:=value(copy(s,pos(';',s)+1,length(s)));
  if ((maxever<>0) and (thisuser.timebank>maxever)) then
    thisuser.timebank:=maxever;

  spstr(170);
  if (not cantdeposit) then spstr(171);
  spstr(172);
  if (choptime=0.0) then spstr(173);
  if (choptime<>0.0) then spstr(174);
  if (cantdeposit) then
  begin
    if ((thisuser.timebankadd>=maxperday) and (maxperday<>0)) then spstr(175);
    if ((thisuser.timebank>=maxever) and (maxever<>0)) then spstr(176);
  end;

  spstr(286);
  if (thisuser.timebankadd<>0) then
  begin
    clearwaves;
    addwave('DT',cstr(thisuser.timebankadd),txt);
    spstr(287);
  end;
  clearwaves;
  if (maxever<>0) then
    addwave('MM',cstr(maxever),txt)
  else
    addwave('MM',getstr(288),txt);
  if (maxperday<>0) then
    addwave('MD',cstr(maxperday),txt)
  else
    addwave('MD',getstr(288),txt);
  spstr(289);
  spstr(177);
  oc:='Q';
  if (choptime=0.0) then oc:=oc+'W';
  if (not cantdeposit) then oc:=oc+'A'+'D';
  onek(c,oc);

  case c of
    'D':begin
          spstr(178);
          inu(zz);
          lng:=zz;
          if (not badini) then
            if (lng>0) then
              if (lng>trunc(nsl) div 60) then
                spstr(290)
              else
              if (lng+thisuser.timebankadd>maxperday) and (maxperday<>0) then
              begin
                addwave('MD',cstr(maxperday),txt);
                spstr(291);
              end else
              if (lng+thisuser.timebank>maxever) and (maxever<>0) then
              begin
                addwave('MM',cstr(maxever),txt);
                spstr(292);
              end else
              begin
                inc(thisuser.timebankadd,lng);
                inc(thisuser.timebank,lng);
                dec(thisuser.tltoday,lng);
                spstr(286);
                sysoplog('Deposited '+cstr(lng)+' minutes in time bank');
              end;
        end;
    'W':begin
          spstr(179);
          inu(zz);
          lng:=zz;
          if (not badini) then
            if (lng>thisuser.timebank) then
              spstr(293)
            else
              if (lng>0) then
              begin
                dec(thisuser.timebankadd,lng);
                if (thisuser.timebankadd<0) then
                  thisuser.timebankadd:=0;
                dec(thisuser.timebank,lng);
                inc(thisuser.tltoday,lng);
                spstr(286);
                sysoplog('Withdrew '+cstr(lng)+' minutes from time bank');
              end;
        end;
  end;
end;

function ctp(t,b:longint):astr;
var s,s1:astr;
    n:real;
begin
  if ((t=0) or (b=0)) then begin
    ctp:='  0.0%';
    exit;
  end;
  n:=(t*100)/b;
  str(n:5:1,s);
  s:=s+'%';
  ctp:=s;
end;

function vote1x(answeringall:boolean; qnum:integer; var vd:vdatar):boolean;
var
  s,st:astr;
  i,tv:integer;
  j:byte;
  c:char;
  abort,next,changed,doneyet,b:boolean;

  procedure showvotes(stats,letadd:boolean);
  var s:astr;
      i:integer;
  begin
    cls;

    clearwaves;
    addwave('Q#',cstr(qnum),txt);
    addwave('QS',vd.question,txt);

    tv:=0;
    for i:=1 to vd.numchoices do inc(tv,vd.choices[i-1].numvoted);
    addwave('PC',sqoutsp(ctp(tv,systat^.numusers)),txt);
    addwave('UN',vd.addedby,txt);

    if (stats) then spstr(444) else spstr(445);
    clearwaves;

    abort:=false;
    i:=1;

    while (i<=vd.numchoices) do
    begin

      if (not abort) then
      begin
        clearwaves;
        if (i=thisuser.vote[qnum]) then
          addwave('NF',getstr(294),txt)
        else
          addwave('NF',getstr(295),txt);
        addwave('C#',cstr(i),txt);
        addwave('CH',vd.choices[i-1].ans[1],txt);
        if (stats) then
        begin
          addwave('PC',ctp(vd.choices[i-1].numvoted,tv),txt);
          spstr(268);
        end else
          spstr(545);
        clearwaves;
        if (vd.choices[i-1].ans[2]<>'') then
        begin
          addwave('CH',vd.choices[i-1].ans[2],txt);
          if (stats) then spstr(547) else spstr(546);
          clearwaves;
        end;
      end;

      inc(i);
    end;

    if (letadd) and (not abort) and (aacs(vd.addacs)) and (vd.numchoices<maxvoteas) then
    begin
      clearwaves;
      addwave('NF',getstr(295),txt);
      addwave('C#',cstr(i),txt);
      addwave('CH',getstr(296),txt);
      if (stats) then
      begin
        addwave('PC','      ',txt);
        spstr(268);
      end else
        spstr(545);
      clearwaves;
    end;
  end;

label goback;

begin

  changed:=FALSE;

  if (vd.numchoices<>0) and (aacs(vd.voteacs)) then
  begin

    doneyet:=(thisuser.vote[qnum]<>0);

    goback:

    showvotes(doneyet,true);
    nl;

    if (not (rvoting in thisuser.ac)) and (not hangup) then
    begin

      if (answeringall) then
        b:=true
      else
        b:=pynq(getstr(297));

      if (b) then
      begin

        if (not answeringall) then nl;
        spstr(67);
        input(s,3);

        if (sqoutsp(s)<>'Q') then
        begin

          i:=value(s);
          if (s<>'') and (i>=0) and (i<=vd.numchoices) then
          begin

            if (thisuser.vote[qnum]<>0) then
              dec(vd.choices[thisuser.vote[qnum]-1].numvoted);
            thisuser.vote[qnum]:=i;
            if (i<>0) then
              inc(vd.choices[i-1].numvoted);

            changed:=TRUE;

            if (pynq(getstr(298))) then
            begin
              showvotes(true,false);
              if (answeringall) then
                pausescr;
            end;

          end else

          if (s<>'') and (aacs(vd.addacs)) and (vd.numchoices<maxvoteas) and (i=vd.numchoices+1) then
          begin

            for j:=1 to 2 do
            begin
              clearwaves;
              addwave('LN',cstr(j),txt);
              spstr(299);
              clearwaves;
              mpl(65);
              inputmain(st,65,'');
              vd.choices[vd.numchoices].ans[j]:=st;
            end;

            if (pynq(getstr(300))) then
            begin

              if (thisuser.vote[qnum]<>0) then
                dec(vd.choices[thisuser.vote[qnum]-1].numvoted);
              thisuser.vote[qnum]:=i;
              if (i<>0) then
                inc(vd.choices[i-1].numvoted);

              inc(vd.numchoices);
              changed:=TRUE;

              if (pynq(getstr(298))) then
              begin
                showvotes(true,false);
                if (answeringall) then
                  pausescr;
              end;

            end else
              goto goback;

          end;

        end;
      end;
    end;

  end else
    if (not answeringall) then spstr(301);

  vote1x:=changed;
end;

procedure vote;
var vdata:file of vdatar;
    vd:vdatar;
    i,j,int2,vna:integer;
    s,i1,ij:astr;
    abort,next,done,lq,waschanged:boolean;

  procedure getvote(qnum:integer);
  begin
    seek(vdata,qnum-1);
    read(vdata,vd);
  end;

  procedure vote1(answeringall:boolean;qnum:integer);
  begin
    getvote(qnum);
    if (vote1x(answeringall,qnum,vd)) then
    begin
      seek(vdata,qnum-1);
      write(vdata,vd);
      waschanged:=true;
    end;
  end;

begin
  s:='';
  done:=false;
  lq:=true;
  waschanged:=false;

  assign(vdata,systat^.datapath+'VOTING.DAT');
  setfileaccess(readwrite,denynone);
  {$I-} reset(vdata); {$I+}

  if (ioresult<>0) then
    spstr(302)
  else

  begin
    sysoplog('Entered voting booths');

    repeat

      done:=false;
      ij:='Q?';
      abort:=false;

      if (lq) then spstr(303);

      int2:=0;

      for i:=1 to filesize(vdata) do
      begin
        seek(vdata,i-1);
        read(vdata,vd);
        if (vd.numchoices<>0) and (aacs(vd.voteacs)) then
        begin
          inc(int2);
          if (lq) and (not abort) then
          begin
            if (thisuser.vote[i]=0) or (thisuser.vote[i]>vd.numchoices) then
              i1:=getstr(304)
            else
              i1:=getstr(305);
            i1:=i1+'|W'+mln(cstr(i),3)+' |C'+vd.question;
            printacr(i1,abort,next);
          end;
          ij:=ij+cstr(i);
        end;
      end;

      lq:=FALSE;

      if (int2=0) then
      begin
        spstr(306);
        done:=TRUE;
      end else

      begin

        spstr(68);
        input(s,2);
        i:=value(s);

        if (s='A') then
        begin

          j:=0;
          i:=1;

          while ((i<=filesize(vdata)) and (not hangup)) do
          begin
            getvote(i);
            if ((vd.numchoices<>0) and (thisuser.vote[i]=0)) and (aacs(vd.voteacs)) then
            begin
              vote1(true,i);
              inc(j);
            end;
            inc(i);
          end;

          if (j=0) then spstr(307);
        end;

        if ((s='Q') or (s='')) then
          done:=true;
        if ((s='L') or (s='?')) then
          lq:=true;
        if (i>=1) and (i<=filesize(vdata)) then
          vote1(false,i);

      end;

      if (systat^.forcevoting) and (done) then
      begin
        vna:=0;
        for i:=1 to filesize(vdata) do
        begin
          seek(vdata,i-1);
          read(vdata,vd);
          if ((vd.numchoices<>0) and (thisuser.vote[i]=0)) and (aacs(vd.voteacs)) then
            inc(vna);
        end;
        if (vna<>0) then
        begin
          spstr(69);
          done:=false;
        end;
      end;

    until (done) or (hangup);

    close(vdata);

    if (waschanged) then spstr(66);

  end;
end;

procedure lotto;
var a,b:array[1..5] of char;
    i,j,correct:integer;
    c:char; p:boolean;
label out;
begin
  if not(pynq(getstr(201))) then exit;
  spstr(202);
  onek(c,'TC');
  case c of
    'T':begin
          if thisuser.tltoday<20 then begin
            spstr(203);
            exit;
          end else begin
            spstr(205);
            thisuser.tltoday:=thisuser.tltoday-15; tleft;
          end;
        end;
    'C':begin
          if thisuser.credit<50 then begin
            spstr(204);
            exit;
          end else begin
            spstr(206);
            thisuser.credit:=thisuser.credit-50;
          end;
        end;
  end;
  spstr(207);
  onekcr:=FALSE; for i:=1 to 5 do onek(b[i],'1234567890'); onekcr:=TRUE;
  spstr(208); correct:=0;
  for i:=1 to 5 do
  begin
    spstr(269);
    a[i]:=chr(random(10)+48);
    p:=TRUE;
    clearwaves;
    addwave('NU',a[i],txt);
    for j:=1 to 5 do
      if a[i]=b[j] then
      begin
        inc(correct);
        spstr(274);
        b[j]:='$';
        p:=FALSE;
        goto out;
      end;
    out:
    if p then spstr(275);
  end;
  clearwaves;
  if correct<=0 then begin spstr(209); exit; end;
  clearwaves;
  case c of
    'T':begin
          case correct of 1:i:=5; 2:i:=15; 3:i:=30; 4:i:=60; 5:i:=120; end;
          addwave('WT',cstr(i),txt);
          spstr(210);
          thisuser.tltoday:=thisuser.tltoday+i;
          saveuf;
          tleft;
        end;
    'C':begin
          case correct of 1:i:=20; 2:i:=50; 3:i:=75; 4:i:=125; 5:i:=200; end;
          addwave('WC',cstr(i),txt);
          spstr(211);
          thisuser.credit:=thisuser.credit+i;
          saveuf;
        end;
  end;
  clearwaves;
end;

end.
