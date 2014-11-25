(*****************************************************************************)
(* Illusion BBS - Personal data editors                                      *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit cuser;

interface

uses
  crt, dos,
  common, MsgF;

procedure cstuff(which,how:byte; var user:userrec);

implementation

var callfromarea:byte;

procedure cstuff(which,how:byte; var user:userrec);
var done,done1:boolean;
    try,i:integer; fi:text; s:astr;

  function okstr(s:astr):boolean;
  var b:boolean;
  begin
    b:=pos('|',s)=0;
    if (not b) then
    begin
      nl;
      spstr(231);
    end;
    okstr:=(s<>'') and (b);
  end;

  procedure findarea;
  var c:char;
  begin
    spstr(232);
    onek(c,'123');
    if (hangup) then exit;
    callfromarea:=ord(c)-48;
    done1:=TRUE;
  end;

  procedure doaddress;
  begin
    if (how=3) then
      spstr(233)
    else begin
      spstr(044);
    end;
    mpl(30);
    if (how=3) then
      inputl(s,30)
    else
      inputcaps(s,30);
    if (okstr(s)) then
    begin
      user.street:=s;
      done1:=TRUE;
    end;
  end;

  procedure doage;
  var b:byte;
      s:astr;
      zxx:char;
  begin
    if (how=3) then
      spstr(234)
    else begin
      spstr(049);
    end;
    inputdate(s);
    nl;
    if (ageuser(s)=0) then
      spstr(279)
    else
    if (ageuser(s)<6) then
    begin
      addwave('YO',cstr(ageuser(s)),txt);
      spstr(235);
      clearwaves;
    end else
    if (ageuser(s)>100) then
    begin
      addwave('YO',cstr(ageuser(s)),txt);
      spstr(236);
      clearwaves;
    end else
    if (length(s)=8) then
    begin
      user.bday:=s;
      done1:=TRUE;
    end;
  end;

  procedure docitystate;
  var s,s1,s2:astr;
  begin
    case how of
      2:begin findarea; nl; end;
      3:callfromarea:=1;
    end;
    if (how=3) then
    begin
      spstr(237);
      mpl(30); inputl(s,30);
      if (okstr(s)) then
      begin
        user.citystate:=s;
        done1:=TRUE;
      end;
      exit;
    end;

    if (callfromarea<>3) then
    begin
      spstr(45);
      mpl(26); inputcaps(s1,26);
      while (copy(s1,1,1)=' ') do s1:=copy(s1,2,length(s1)-1);
      while (copy(s1,length(s1),1)=' ') do s1:=copy(s1,1,length(s1)-1);
      nl;
      spstr(46);
      mpl(2); input(s2,2);
      if (length(s2)<2) then exit;
      if (okstr(s1)) then
      begin
        user.citystate:=s1+', '+s2;
        done1:=TRUE;
      end;
    end else begin
      spstr(45);
      mpl(26); inputcaps(s1,26);
      nl;
      spstr(47);
      mpl(26); inputcaps(s2,26);
      s:=s1+', '+s2;
      if (length(s)>30) then begin
        spstr(48);
        exit;
      end;
      if (okstr(s)) then
      begin
        user.citystate:=s;
        done1:=TRUE;
      end;
    end;
  end;

  procedure docomputer;
  var s:astr;
  begin
    if (how=3) then spstr(238) else spstr(51);
    mpl(30);
    inputl(s,30);
    if (okstr(s)) then begin
      user.computer:=s;
      done1:=TRUE;
    end;
  end;

  procedure dojob;
  begin
    if (how=3) then spstr(239) else spstr(52);
    mpl(40);
    inputl(s,40);
    if (okstr(s)) then begin
      user.occupation:=s;
      done1:=TRUE;
    end;
  end;

  procedure doname;
  var i:integer;
      s1,s2:astr;
      sfo:boolean;
      sr:smalrec;
      found:byte;
  begin
    if (systat^.allowalias) then begin
      spstr(37);
    end else begin
      spstr(284);
    end;
    mpl(36); input(s,36);
    if (okstr(s)) then done1:=TRUE;
    nl;
    if ((not (s[1] in ['A'..'Z','?'])) or (s='')) then done1:=FALSE;

    sfo:=(filerec(sf).mode<>fmclosed);
    if (not sfo) then begin
      SetFileAccess(ReadOnly,DenyNone);
      reset(sf);
    end;
    spstr(38);
    found:=0;
    for i:=1 to filesize(sf)-1 do begin
      seek(sf,i); read(sf,sr);
      if (sr.name=s) then begin
        done1:=FALSE;
        found:=1;
        spstr(39);
        spstr(240);
        spstr(241);
      end;
    end;
    if found=0 then spstr(40);
    if (not sfo) then close(sf);

    assign(fi,systat^.textpath+'blacklst.txt');
    {$I-} reset(fi); {$I+}
    if (ioresult=0) then begin
      s2:=' '+s+' ';
      while not eof(fi) do begin
        readln(fi,s1);
        if s1[length(s1)]=#1 then s1[length(s1)]:=' ' else s1:=s1+' ';
        s1:=' '+s1;
        for i:=1 to length(s1) do s1[i]:=upcase(s1[i]);
        if pos(s1,s2)<>0 then begin
          addwave('BN',copy(s1,pos(s1,s2),length(s1)),txt);
          spstr(242);
          clearwaves;
          sl1('|RNewuser attempted to logon as "'+copy(s1,pos(s1,s2),length(s1))+'" and was logged off.');
          hangup:=TRUE;
          done1:=FALSE;
        end;
      end;
      close(fi);
    end;

    if (not done1) and (not hangup) then begin
      if not (found=1) then spstr(243);
      inc(try);
      sl1('Bad Name: '+s);
    end;

    if (try>=3) then hangup:=TRUE;
    if (done1) then user.name:=s;
    if ((done) and (how=1) and (not systat^.allowalias)) then
      user.realname:=caps(s);
  end;

  procedure dophone;
  begin
    case how of
      2:begin findarea; nl; end;
      3:callfromarea:=1;
    end;
    if (how=3) then spstr(244) else spstr(50);
    if (callfromarea=3) or (how=3) then begin
      mpl(12); input(s,12);
      if (length(s)>5) and (okstr(s)) then begin
        user.ph:=s;
        done1:=true;
      end;
    end else begin
      inputphone(s);
      nl;
      if (length(s)=12) and (okstr(s)) then begin
        user.ph:=s;
        done1:=TRUE;
      end;
    end;
  end;

  procedure dopw;
  var s:astr;
  begin
    case how of
      1:begin
          spstr(59);
          mpl(20); input(s,20);
          if (length(s)<4) then
            spstr(245)
          else
          if (okstr(s)) then
          begin
            nl;
            clearwaves;
            addwave('PW',s,txt);
            spstr(60);
            clearwaves;
            done1:=pynq(getstr(246));
            if (done1) then user.pw:=s;
          end;
        end;
      2:begin
          spstr(247); input(s,20);
          if (s<>user.pw) then spstr(248)
          else begin
            repeat
              spstr(249); mpl(20); input(s,20); nl;
            until (((length(s)>=4) and (length(s)<=20)) or (s='') or (hangup));

            if (okstr(s)) then begin
              addwave('PW',s,txt);
              spstr(250);
              clearwaves;
              if pynq(getstr(251)) then begin
                if (not hangup) then user.pw:=s;
                sysoplog('Changed password.');
                done1:=TRUE;
              end else
                nl;
            end else
              nl;
          end;
          nl;
        end;
      3:begin
          spstr(252); mpl(20); input(s,20);
          if (okstr(s)) then begin
            done1:=TRUE;
            user.pw:=s;
          end;
        end;
    end;
  end;

  procedure dorealname;
  var i:integer;
  begin
    if ((how=1) and (not systat^.allowalias)) then begin
      user.realname:=caps(user.name);
      done1:=TRUE;
      exit;
    end;
    if (how=3) then spstr(253) else spstr(42);
    mpl(36);
    if (how=3) then inputl(s,36) else inputcaps(s,36);
    while copy(s,1,1)=' ' do s:=copy(s,2,length(s)-1);
    while copy(s,length(s),1)=' ' do s:=copy(s,1,length(s)-1);
    if (pos(' ',s)=0) and (how<>3) then begin
      spstr(43);
      s:='';
    end;
    if (okstr(s)) then begin
      user.realname:=s;
      done1:=TRUE;
    end;
  end;

  procedure doscreen;
  var v:string;
      bb:byte;
  begin
    if (how=1) then begin
      user.linelen:=systat^.linelen;
      user.pagelen:=systat^.pagelen;
    end;
    clearwaves;
    addwave('LL',cstr(thisuser.linelen),txt);
    addwave('PL',cstr(thisuser.pagelen),txt);
    spstr(58);
    ini(bb); if (not badini) then user.linelen:=bb;
    spstr(57);
    ini(bb); if (not badini) then user.pagelen:=bb;
    if (user.pagelen>50) then user.pagelen:=50;
    if (user.pagelen<4) then user.pagelen:=4;
    if (user.linelen>132) then user.linelen:=132;
    if (user.linelen<32) then user.linelen:=32;
    clearwaves;
    done1:=TRUE;
  end;

  procedure dosex;
  var c:char;
  begin
    if (how=3) then begin
      spstr(254); mpl(1);
      onek(c,'MF '^M);
      if (c in ['M','F']) then user.sex:=c;
    end else begin
      user.sex:=#0;
      repeat
        spstr(53); mpl(1);
        onek(user.sex,'MF'^M);
        if (user.sex=^M) then spstr(255);
      until ((user.sex in ['M','F']) or (hangup));
    end;
    done1:=TRUE;
  end;

  procedure dowherebbs;
  begin
    if (how=3) then spstr(256) else spstr(54);
    mpl(40); inputl(s,40);
    if (okstr(s)) then begin user.wherebbs:=s; done1:=TRUE; end;
  end;

  procedure dozipcode;
  begin
    case how of
      2:begin findarea; nl; end;
      3:callfromarea:=3;
    end;
    if (how=3) then spstr(257) else spstr(55);
    mpl(10);input(s,10);
    if (((callfromarea=3) and (length(s)>2)) or
        ((callfromarea=2) and (length(s)=6)) or
        ((callfromarea=1) and (length(s) in [5,10]))) and
        (okstr(s)) then
    begin
      user.zipcode:=s;
      done1:=TRUE;
    end;
  end;

  procedure forwardmail;
  var u:userrec;
      s:astr;
      i:integer;
      b,ufo:boolean;
  begin
    spstr(258);
    input(s,4);
    i:=value(s);
    nl;
    if (i=0) then begin
      user.forusr:=0;
      spstr(259);
    end else begin
      ufo:=(filerec(uf).mode<>fmclosed);
      if (not ufo) then begin
        SetFileAccess(ReadOnly,DenyNone);
        reset(uf);
      end;
      b:=TRUE;
      if (i>=filesize(uf)) then b:=FALSE
      else begin
        seek(uf,i); read(uf,u);
        if (u.deleted) or (nomail in u.ac) then b:=FALSE;
      end;
      if (i=usernum) then b:=FALSE;
      if (b) then begin
        user.forusr:=i;
        addwave('UN',caps(u.name),txt);
        addwave('U#',cstr(i),txt);
        spstr(260);
        clearwaves;
        sysoplog('Started forwarding mail to '+caps(u.name)+' #'+cstr(i));
      end else
        spstr(261);
      if (not ufo) then close(uf);
    end;
  end;

  procedure mailbox;
  begin
    if (nomail in user.ac) then begin
      exclude(user.ac,nomail);
      spstr(262);
      sysoplog('Opened mailbox.');
    end else
      if (user.forusr<>0) then begin
        user.forusr:=0;
        spstr(263);
        sysoplog('Stopped forwarding mail.');
      end else begin
        if pynq(getstr(264)) then begin
          include(user.ac,nomail);
          spstr(265);
          sysoplog('Closed mailbox.');
        end else
          if pynq(getstr(266)) then forwardmail;
      end;
    done1:=TRUE;
  end;

  procedure tog_ansi;
  var c:char;
  begin
    if (not systat^.reqansi) then
    begin
      if (pynq(getstr(267))) then include(user.ac,ansi)
                             else exclude(user.ac,ansi);
    end;
    if okansi then
    begin
      if (systat^.allowavatar) then
        if (pynq(getstr(512))) then include(user.ac,avatar)
                               else exclude(user.ac,avatar);
      if (systat^.allowrip) then
        if (pynq(getstr(513))) then include(user.ac,rip)
                               else exclude(user.ac,rip);
    end;
    done1:=TRUE;
  end;

  procedure tog_pause;
  begin
    if (pause in user.ac) then begin
      exclude(user.ac,pause);
      spstr(270);
    end else begin
      include(user.ac,pause);
      spstr(271);
    end;
    done1:=TRUE;
  end;

  procedure tog_input;
  begin
    if (onekey in user.ac) then begin
      exclude(user.ac,onekey);
      spstr(272);
    end else begin
      include(user.ac,onekey);
      spstr(273);
    end;
    done1:=TRUE;
  end;

  procedure tog_expert;
  begin
    if (novice in user.ac) then begin
      exclude(user.ac,novice);
      chelplevel:=1;
      spstr(276);
    end else begin
      include(user.ac,novice);
      chelplevel:=2;
      spstr(277);
    end;
    done1:=TRUE;
  end;

  procedure qwk_opt;
  begin
    done1:=TRUE;
    if how=3 then
      spstr(280)
    else
    begin
      listarctypes;
      clearwaves;
      addwave('UQ',user.qwkarc,txt);
      spstr(281);
      clearwaves;
    end;
    mpl(3);
    input(s,3); nl;
    if (okstr(s)) and (arctype('BLAH.'+s)>0) then
    begin
      user.qwkarc:=s;
      addwave('UQ',s,txt);
      spstr(282);
    end else begin
      addwave('UQ',user.qwkarc,txt);
      spstr(282);
    end;
    clearwaves;
    nl;
    dyny:=user.qwkfiles;
    user.qwkfiles:=pynq(getstr(283));
  end;

  procedure checkwantpause;
  begin
    dyny:=TRUE;
    if pynq(getstr(652)) then {should screen pausing be active?}
      include(user.ac,pause)
    else
      exclude(user.ac,pause);
    done1:=TRUE;
  end;

  procedure dousernote;
  begin
    if (how=3) then spstr(285) else spstr(56);
    mpl(25); inputl(s,25);
    if (s<>'') then begin user.usernote:=s; done1:=TRUE; end;
  end;

  procedure doedtype;
  var c:char;
  begin
    print('Editor type:'); nl;
    print('[0] Select each time');
    print('[1] Line Editor');
    print('[2] Full Screen Editor (ANSI/Avatar required)');
    nl;
    prt('Choose one: '); onek(c,'012'^M);
    if c<>^M then begin
      user.edtype:=value(c);
      done1:=TRUE;
    end;
  end;

  procedure ww(www:integer);
  begin
    nl;
    case www of
      1:doaddress;   2:doage;         3:findarea;
      4:docitystate; 5:docomputer;    6:dojob;
      7:doname;      8:dophone;       9:dopw;
     10:dorealname; 11:doscreen;     12:dosex;
     13:dowherebbs; 14:dozipcode;    15:mailbox;
     16:tog_ansi;                    18:tog_pause;
     19:tog_input;                   21:(*chcolors*);
     22:tog_expert; 23:qwk_opt;      24:checkwantpause;
     25:dousernote;                  29:doedtype;
    end;
  end;

begin
  try:=0; done1:=FALSE;
  case how of
    1:repeat ww(which) until (done1) or (hangup);
    2,3:ww(which);
  end;
end;

end.
