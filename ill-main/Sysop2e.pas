(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2e/11] (new user voting configuration)    *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2e;

interface

uses
  crt, dos,
  common;

procedure ponuv;

implementation

procedure ponuv;
var c:char;
begin
  c:=#0;
  repeat
    with systat^ do
    begin
      if (c in [#0,^M]) then
      begin
        cls;
        sprint('|WNew User Voting Configuration');
        nl;
        sprint('|K[|CA|K] |cUse new user voting  |w'+syn(nuv));
        sprint('|K[|CB|K] |cYes votes needed     |w'+aonoff(nuvyes=0,'Disabled',cstr(nuvyes)));
        sprint('|K[|CC|K] |cNo votes needed      |w'+aonoff(nuvno=0,'Disabled',cstr(nuvno)));
        sprint('|K[|CD|K] |cValidation profile   |w'+nuvval);
        nl;
        sprompt('|wCommand |K[|CQ|c:uit|K] |W');
      end;
      ansig(17,8);
      sprompt(#32+^H+'|W');
      onek(c,'QABCD'^M);
      case c of
        'A':switchyn(26,3,nuv);
        'B':begin
              sprompt('|w|I2904 (0 to disable auto-validation)');
              nuvyes:=inputnumxy(26,4,nuvyes,3,0,255);
              sprompt('|w|I2604'+aonoff(nuvyes=0,'Disabled',cstr(nuvyes))+'|LC');
            end;
        'C':begin
              sprompt('|w|I2905 (0 to disable auto-deletion)');
              nuvno:=inputnumxy(26,5,nuvno,3,0,255);
              sprompt('|w|I2605'+aonoff(nuvno=0,'Disabled',cstr(nuvno))+'|LC');
            end;
        'D':begin
              inputcharxy(26,6,nuvval);
              sprompt('|w|I2606'+nuvval);
            end;
      end;
    end;
  until (c='Q') or (hangup);
end;

end.
