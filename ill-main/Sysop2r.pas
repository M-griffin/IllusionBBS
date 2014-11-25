(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2r/11] (miscellaneous)                    *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2r;

interface

uses
  crt, dos,
  common;

procedure pomisc;

implementation

procedure pomisc;
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
        sprint('|WMiscellaneous Configuration');
        nl;
        sprint('|K[|CA|K] |cWFC screen saver (mins)    |w'+cstr(wfcblanktime));
        sprint('|K[|CB|K] |cWFC fireworks screen saver |w'+syn(specialfx and 8=8));
        sprint('|K[|CC|K] |cPre-event warning (secs)   |w'+cstr(eventwarningtime));
        sprint('|K[|CD|K] |cMax. number of oneliners   |w'+cstr(MaxOneliners));
        nl;
        sprint('|K[|CE|K] |cInput field color          |w'); displaycolor(32,8,inputfieldcolor); nl;
        nl;
        sprompt('|wCommand |K[|CQ|c:uit|K] |W');
      end;
      ansig(17,10);
      sprompt(#32+^H+'|W');
      onek(c,'QABCDE'^M);
      case c of
        'A':wfcblanktime:=inputnumxy(32,3,wfcblanktime,3,0,255);
        'B':begin
              specialfx:=specialfx xor 8;
              sprompt('|w|I3204'+syn(specialfx and 8=8));
            end;
        'C':eventwarningtime:=inputnumxy(32,5,eventwarningtime,5,0,32767);
        'D':MaxOneliners:=InputNumxy(32,6,MaxOneliners,3,1,255);
        'E':inputcolorxy(32,8,inputfieldcolor);
      end;
    end;
  until (c='Q') or (hangup);
end;

end.
