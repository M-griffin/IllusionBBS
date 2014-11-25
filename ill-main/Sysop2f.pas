(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2f/11] (chat configuration)               *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2f;

interface

uses
  crt, dos,
  common;

procedure pochat;

implementation

procedure pochat;
var c:char;
    s:astr;
begin
  c:=#0;
  repeat
    with systat^ do
    begin
      if (c in [#0,^M]) then
      begin
        cls;
        sprint('|WChat Configuration');
        nl;
        sprint('|K[|CA|K] |cSplit screen chat    |w'+syn(splitchat)+' ');
        sprint('|K[|CB|K] |cChat hours start     |w'+
               tch(cstr(lowtime div 60))+':'+tch(cstr(lowtime mod 60)));
        sprint('|K[|CC|K] |cChat hours end       |w'+
               tch(cstr(hitime div 60))+':'+tch(cstr(hitime mod 60)));
        sprint('|K[|CD|K] |cChat attempts/call   |w'+cstr(maxchat));
        sprint('|K[|CE|K] |cSysop chat color     |w'+cstr(sysopcolor));
        sprint('|K[|CF|K] |cUser chat color      |w'+cstr(usercolor));
        sprint('|K[|CG|K] |cOverride chat hours  |w'+emergchat);
        sprint('|K[|CH|K] |cChat songs           |w'+syn(specialfx and 2=2)+' ');
        nl;
        sprompt('|wCommand |K[|CQ|c:uit|K] |W');
      end;
      ansig(17,12);
      sprompt(#32+^H+'|W');
      onek(c,'QABCDEFGH'^M);
      case c of
        'A':switchyn(26,3,splitchat);
        'B':begin
              s:=tch(cstr(lowtime div 60))+':'+tch(cstr(lowtime mod 60));
              sprompt('|w|I3204(in hh:mm format)');
              inputxy(26,4,s,5);
              if (s[3]=':') and (length(s)=5) then
                lowtime:=value(copy(s,1,2))*60+value(copy(s,4,2));
              ansig(26,4);
              sprompt(tch(cstr(lowtime div 60))+':'+tch(cstr(lowtime mod 60))+'|LC');
            end;
        'C':begin
              s:=tch(cstr(hitime div 60))+':'+tch(cstr(hitime mod 60));
              sprompt('|w|I3205(in hh:mm format)');
              inputxy(26,5,s,5);
              if (s[3]=':') and (length(s)=5) then
                hitime:=value(copy(s,1,2))*60+value(copy(s,4,2));
              ansig(26,5);
              sprompt(tch(cstr(hitime div 60))+':'+tch(cstr(hitime mod 60))+'|LC');
            end;
        'D':maxchat:=inputnumxy(26,6,maxchat,3,0,255);
        'E':sysopcolor:=inputnumxy(26,7,sysopcolor,3,0,255);
        'F':usercolor:=inputnumxy(26,8,usercolor,3,0,255);
        'G':inputxy(26,9,emergchat,20);
        'H':begin
              specialfx:=specialfx xor 2;
              sprompt('|w|I2610'+syn(specialfx and 2=2)+' ');
            end;
      end;
    end;
  until (c='Q') or (hangup);
end;

end.
