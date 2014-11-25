(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2h/11] (offline mail configuration)       *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2h;

interface

uses
  crt, dos,
  common;

procedure poqwk;

implementation

procedure poqwk;
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
        sprint('|WOffline Mailer Configuration');
        nl;
        sprint('|K[|CA|K] |cQWK/REP filename     |w'+qwkfilename);
        sprint('|K[|CB|K] |cWelcome filename     |w'+qwkwelcome);
        sprint('|K[|CC|K] |cNews filename        |w'+qwknews);
        sprint('|K[|CD|K] |cGoodbye filename     |w'+qwkgoodbye);
        sprint('|K[|CE|K] |cDefault archiver     |w'+qwkcomp);
        nl;
        sprompt('|wCommand |K[|CQ|c:uit|K] |W');
      end;
      ansig(17,9);
      sprompt(#32+^H+'|W');
      onek(c,'QABCDE'^M);
      case c of
        'A':inputxy(26,3,qwkfilename,-8);
        'B':inputxy(26,4,qwkwelcome,-8);
        'C':inputxy(26,5,qwknews,-8);
        'D':inputxy(26,6,qwkgoodbye,-8);
        'E':inputxy(26,7,qwkcomp,-3);
      end; {case}
    end;
  until (c='Q') or (hangup);
end;

end.
