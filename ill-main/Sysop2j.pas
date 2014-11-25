(*****************************************************************************)
(* Illusion BBS - SysOp routines [2j/11] (sysop window config)               *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2j;

interface

uses
  crt, dos,
  common;

procedure posysopwind;

implementation

procedure posysopwind;
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
        sprint('|WSysop Window Configuration');
        nl;
        sprint('|K[|CA|K] |cWindow default status        |w'+onoff(systat^.windowdefon));
        sprint('|K[|CB|K] |cWindow position              |wOn '+aonoff(systat^.windowontop,'top   ','bottom'));
        nl;
        sprint('|K[|CC|K] |cNormal text color            |w'); displaycolor(34,6,wind_normalc); nl;
        sprint('|K[|CD|K] |cHighlighted text color       |w'); displaycolor(34,7,wind_highlightc); nl;
        sprint('|K[|CE|K] |cLabels text color            |w'); displaycolor(34,8,wind_labelc); nl;
        sprint('|K[|CF|K] |cImportant/Warning text color |w'); displaycolor(34,9,wind_flashc); nl;
        nl;
        sprompt('|wCommand |K[|CQ|c:uit|K] |W');
      end;
      ansig(17,11);
      sprompt(#32+^H+'|W');
      onek(c,'QABCDEF'^M);
      case c of
        'A':begin
              windowdefon:=not windowdefon;
              sprompt('|w|I3403'+onoff(windowdefon));
            end;
        'B':begin
              windowontop:=not windowontop;
              sprompt('|w|I3404On '+aonoff(windowontop,'top   ','bottom'));
            end;
        'C':inputcolorxy(34,6,wind_normalc);
        'D':inputcolorxy(34,7,wind_highlightc);
        'E':inputcolorxy(34,8,wind_labelc);
        'F':inputcolorxy(34,9,wind_flashc);
      end;
    end;
  until (c='Q') or (hangup);
end;

end.
