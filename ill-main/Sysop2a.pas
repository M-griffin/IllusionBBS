(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2a/11] (modem/node config)                *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2a;

interface

uses
  crt, dos,
  common, common2;

procedure pomodem;

implementation

function showmodemstring(s:astr):astr;
var o:astr;
    i:integer;
begin
  o:='';
  for i:=1 to length(s) do
    case s[i] of
      ^@..^L,^N..^[:
         o:=o+'^'+chr(ord(s[i])+64);
      ^M:o:=o+'|';
    else o:=o+s[i];
    end;
  showmodemstring:=o;
end;

procedure newmodemstring(var vs:astr; len:integer; x,y:byte);
var i:integer;
    s:astr;
begin
  s:=showmodemstring(vs);
  ansig(x,y);
  inputed(s,len,'O');
  if (s<>vs) then begin
    vs:=s;
    for i:=1 to length(vs) do
      case vs[i] of
        '|':vs[i]:=^M;
        '^':if ((i<>length(vs)) and (vs[i+1] in ['@'..'['])) then begin
              vs[i]:=chr(ord(vs[i+1])-64);
              delete(vs,i+1,1);
            end;
      end;
  end;
end;

procedure pomodem;
var modemrf:file of modemrec;
    s:string[80];
    i:integer;
    c,ccc:char;

function handshaking:astr;
var s:astr;
begin
  case modemr^.Handshake of
    HaCtsRts : s:='CTS/RTS';
    HaXonXoff: s:='XON/XOFF';
  end;
  handshaking:=s;
end;

function lcl(s:string):string;
begin
  if (incom) then
    lcl:='|K'+stripcolor(s)
  else
    lcl:=s;
end;

function lsl(s:string):string;
begin
  if (modemr^.lowspeed=0) then
    lsl:='|K'+stripcolor(s)
  else
    lsl:=s;
end;

begin
  c:=^M;
  repeat
    with modemr^ do
    begin
      if (c in [^M,'C','K'..'M']) then
      begin
        cls;
        sprint('|WModem Configuration for Node #'+cstr(nodenum));
        nl;
    sprint(lcl('|K[|CA|K] |cCOM port           |w')+cstr(comport));
    sprint(lcl('|K[|CB|K] |cMaximum baud rate  |w')+cstrl(waitbaud));
    sprint(lcl('|K[|CC|K] |cLocked port        |w')+
           aonoff(PortLock,'Locked at '+cstrl(lockspeed),'Not locked'));
        sprint('|K[|CD|K] |cHandshaking        |w'+HandShaking);
        sprint('|K[|CE|K] |cRe-init time (min) |w'+cstr(nocallinittime));
        sprint('|K[|CF|K] |cAnswer delay       |w'+cstr(answerdelay)+'/10 seconds');
        nl;
        sprint('|K[|CG|K] |cLowspeed lockout   |w'+
           aonoff((LowSpeed=0),'Disabled|LC',cstrl(lowspeed)+' and below'));
    sprint(lsl('|K[|CH|K] |cLowspeed password  |w')+aonoff((Lowspeed=0),'Not used|LC',LowPw+'|LC'));
        nl;
        sprint('|K[|CI|K] |cTEMP directory     |w'+temppath);
        sprint('|K[|CJ|K] |cDOOR directory     |w'+DoorPath);
        nl;
        sprint('|K[|CK|K] |cCommand Strings...');
        sprint('|K[|CL|K] |cResult Strings...');
        sprint('|K[|CM|K] |cConnect Strings...');
        nl;
        sprompt('|wCommand |K[|CQ|c:uit|K] |W');
      end;
      ansig(17,20);
      sprompt(#32+^H+'|W');
      s:='QDEFGIJKLM'^M;
      if not (incom) then s:=s+'ABC';
      if (lowspeed<>0) then s:=s+'H';
      onek(c,s);
      case c of
        'A':begin
              s:=cstr(comport);
              ansig(24,3);
              inputed(s,2,'O');
              if (value(s) in [1..64]) then
              begin
                remove_port;
                comport:=value(s);
                iport;
              end;
            end;
        'B':begin
              s:=cstr(waitbaud);
              ansig(24,4);
              inputed(s,5,'O');
              if ((value(s) div 100) in [3,12,24,48,72,96,120,144,168,192,216,240]) or
                 (value(s)=26400) or (value(s)=28800) or (value(s)=33600) or
                 (value(s)=38400) or (value(s)=57600) or (value(s)=64000) or
                 (value(s)=76800) or (value(s)=115200) then
                waitbaud:=value(s);
              ansig(24,4);
              sprompt('|w'+cstr(waitbaud));
            end;
        'C':begin
              cls;
              sprint('|WPort Locking');
              nl;
              sprint('|wThis option does NOT lock your port; it just lets Illusion know that');
              sprint('|wyour FOSSIL driver has locked the port.  Make sure your FOSSIL driver');
              sprint('|wconfiguration matches this setting.');
              nl;
              portlock:=pynq('|wIs your modem port locked');
              if portlock then
              begin
                nl;
                sprint('|wAnd the speed your port is locked at?');
                nl;
                sprint('|K[|C1|K] |c19200');
                sprint('|K[|C2|K] |c38400');
                sprint('|K[|C3|K] |c57600');
                sprint('|K[|C4|K] |c76800');
                sprint('|K[|C5|K] |c115200');
                nl;
                sprompt('|wModem Speed |K[|WQ|w:uit|K] |W');
                onek(ccc,'Q12345'^M);
                case ccc of
                  '1':lockspeed:=19200;
                  '2':lockspeed:=38400;
                  '3':lockspeed:=57600;
                  '4':lockspeed:=76800;
                  '5':lockspeed:=115200;
                  'Q',^M:portlock:=FALSE;
                end; {case}
              end; {if portlock}
            end;
        'D':begin
              if (handshake=haxonxoff) then
                handshake:=hactsrts
              else
                handshake:=haxonxoff;
              ansig(24,6);
              sprompt('|w'+mln(handshaking,10));
            end;
        'E':begin
              ansig(24,7);
              s:=cstr(nocallinittime);
              inputed(s,5,'O');
              if (value(s)<>0) then nocallinittime:=value(s);
              ansig(24,7);
              sprompt('|w'+mln(cstr(nocallinittime),5));
            end;
        'F':begin
              ansig(24,8);
              s:=cstr(answerdelay);
              sprompt(mln(s,3)+'|w/10 seconds');
              ansig(24,8);
              inputed(s,3,'O');
              if (value(s)<>0) then answerdelay:=value(s);
              ansig(24,8);
              sprompt('|w'+cstr(answerdelay)+'/10 seconds    ');
            end;
        'G':begin
              ansig(29,10);
              sprompt('|w (0 to disable)');
              ansig(24,10);
              s:=cstr(lowspeed);
              inputed(s,5,'O');
              lowspeed:=value(s);
              ansig(24,10);
              sprompt('|w'+aonoff((LowSpeed=0),'Disabled|LC',cstrl(lowspeed)+' and below')+mln('',15));
              ansig(1,11);
              sprompt(lsl('|K[|CH|K] |cLowspeed password  |w')+aonoff((Lowspeed=0),'Not used|LC',LowPw+'|LC'));
            end;
        'H':if (lowspeed>0) then
            begin
              ansig(24,11);
              inputed(lowpw,20,'OS');
            end;
        'I':begin
              ansig(24,13);
              inputed(modemr^.temppath,49,'OSUB');
              ansig(24,13);
              sprompt('|w'+modemr^.temppath+'|LC');
            end;
        'J':begin
              ansig(24,14);
              inputed(modemr^.doorpath,49,'OSU');
              if (modemr^.doorpath<>'') and
                 (copy(modemr^.doorpath,length(modemr^.doorpath),1)<>'\') then
                modemr^.doorpath:=modemr^.doorpath+'\';
              ansig(24,14);
              sprompt('|w'+modemr^.doorpath+'|LC');
            end;
        'K':begin
              ccc:=#0;
              repeat
                if (ccc in [#0,^M]) then
                begin
                  clearwaves;
                  cls;
                  sprint('|WCommand Strings');
                  nl;
                  sprint('"^" control codes (^@..^[)');
                  sprint('"|" carriage return');
                  print('"~" 1/2 second delay');
                  nl;
                  sprompt('|K[|CA|K] |cInit. string #1|w  '); print(showmodemstring(init[1]));
                  sprompt('|K[|CB|K] |cInit. string #2|w  '); print(showmodemstring(init[2]));
                  sprompt('|K'+stripcolor('|K[|CC|K] |cEscape string  |w  '));
                  print(showmodemstring(EscCode));
                  sprompt('|K[|CD|K] |cAnswer string  |w  '); print(showmodemstring(answer));
                  sprompt('|K[|CE|K] |cHangup string  |w  '); print(showmodemstring(hangup));
                  sprompt('|K[|CF|K] |cOffhook string |w  '); print(showmodemstring(offhook));
                  nl;
                  sprompt('|wCommand |K[|CQ|c:uit|K] |W');
                end;
                ansig(17,14);
                sprompt(#32+^H+'|W');
                onek(ccc,'QABCDEF'^M);
                case ccc of
                  'A':newmodemstring(init[1],53,22,7);
                  'B':newmodemstring(init[2],53,22,8);
                  'C':EscCode:='+++';
                  'D':newmodemstring(answer,40,22,10);
                  'E':newmodemstring(hangup,40,22,11);
                  'F':newmodemstring(offhook,40,22,12);
                end;
              until ccc='Q';
            end;
        'L':begin
              ccc:=#0;
              repeat
                if (ccc in [#0,^M]) then
                begin
                  cls;
                  sprint('|WResult Strings');
                  nl;
                  sprint('|K[|CA|K]|c ERROR       |w'+CodeError);
                  sprint('|K[|CB|K]|c NO CARRIER  |w'+CodeNocarrier);
                  sprint('|K[|CC|K]|c OK          |w'+CodeOk);
                  sprint('|K[|CD|K]|c RING        |w'+CodeRing);
                  nl;
                  sprompt('|wCommand |K[|CQ|c:uit|K] |W');
                end;
                ansig(17,8);
                sprompt(#32+^H+'|W');
                onek(ccc,'QABCD'^M);
                if (ccc in ['A'..'D']) then
                begin
                  ansig(17,3+ord(ccc)-65);
                  case ccc of
                    'A':inputed(codeerror,31,'OS');
                    'B':inputed(codenocarrier,31,'OS');
                    'C':inputed(CodeOk,31,'OS');
                    'D':inputed(codering,31,'OS');
                  end;
                end;
              until ccc='Q';
            end;
        'M':begin
              ccc:=#0;
              repeat
                if (ccc in [#0,^M]) then
                begin
                  cls;
                  sprint('|WConnect Strings');
                  nl;
                  for i:=0 to 18 do begin
                    case i of
                       0:s:='300';    1:s:='1200';   2:s:='2400';
                       3:s:='4800';   4:s:='7200';   5:s:='9600';
                       6:s:='12000';  7:s:='14400';  8:s:='16800';
                       9:s:='19200'; 10:s:='21600'; 11:s:='24000';
                      12:s:='26400'; 13:s:='28800'; 14:s:='31200';
                      15:s:='33600'; 16:s:='38400'; 17:s:='57600';
                      18:s:='115200';
                    end;
                    if (i<16) then
                      sprint('|K[|C'+chr(i+65)+'|K]|c CONNECT '+mln(s,6)+'  |w'+resultcode[i])
                    else
                    if (i<18) then
                      sprint('|K[|C'+chr(i+65+1)+'|K]|c CONNECT '+mln(s,6)+'  |w'+resultcode[i])
                    else
                      sprint('|K[|CT|K]|c CONNECT '+mln(s,6)+'  |w'+resultcode[19])
                  end; {for i}
                  nl;
                  sprompt('|wCommand |K[|CQ|c:uit|K] |W');
                end;
                ansig(17,23);
                sprompt(#32+^H+'|W');
                onek(ccc,'QABCDEFGHIJKLMNOPRST'^M);
                if (ccc in ['A'..'P','R'..'T']) then
                begin
                  if (ccc>'Q') then
                  begin
                    if (ccc='T') then
                    begin
                      ansig(21,21);
                      s:=resultcode[19];
                    end else
                    begin
                      ansig(21,3+ord(ccc)-65-1);
                      s:=resultcode[ord(ccc)-65-1];
                    end;
                  end else
                  begin
                    ansig(21,3+ord(ccc)-65);
                    s:=resultcode[ord(ccc)-65];
                  end;
                  inputed(s,31,'OS');
                  case ccc of
                    'A'..'P':ResultCode[ord(ccc)-65]:=s;
                    'R'..'S':ResultCode[ord(ccc)-65-1]:=s;
                    'T':resultcode[19]:=s;
                  end; {case ccc}
                end;
              until ccc='Q';
            end;
      end; {case}
    end; {with modemr}
  until (c='Q') or (hangup);
  assign(modemrf,systat^.datapath+'\NODE.'+cstr(nodenum));
  SetFileAccess(ReadWrite,DenyNone);
  reset(modemrf); seek(modemrf,0); write(modemrf,modemr^); close(modemrf);
end;

end.
