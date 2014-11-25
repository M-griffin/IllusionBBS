(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2m/11] (security configuration)           *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2m;

interface

uses
  crt, dos,
  common;

procedure posecurity;

implementation

procedure posecurity;
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
        sprint('|WSecurity Configuration');
        nl;
        sprint('|K[|CA|K] |cLocal security          |w'+syn(localsec));
        sprint('|K[|CB|K] |cLocal screen security   |w'+syn(localscreensec));
        sprint('|K[|CC|K] |cGlobal user trapping    |w'+syn(globaltrap));
        sprint('|K[|CD|K] |cAuto line chat capture  |w'+syn(autochatopen));
        nl;
        sprompt('|wCommand |K[|CQ|c:uit|K] |W');
      end;
      ansig(17,8);
      sprompt(#32+^H+'|W');
      onek(c,'QABCD'^M);
      case c of
        'A':switchyn(29,3,localsec);
        'B':switchyn(29,4,localscreensec);
        'C':switchyn(29,5,globaltrap);
        'D':switchyn(29,6,autochatopen);
      end;
    end;
  until (c='Q') or (hangup);
end;

end.
