(*****************************************************************************)
(* Illusion BBS - SysOp routines  [7m/11] (modify menu commands)             *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop7m;

interface

uses
  crt, dos,
  common;

procedure memm(scurmenu:astr);

implementation

procedure memm(scurmenu:astr);
var ii:integer;
    c:char;
begin
  sprompt('Edit command |K[|C1|c-|C'+cstr(noc)+'|K] |W');
  inu(ii);
  if (ii>=1) and (ii<=noc) then
  begin
    cls;
    c:=#0;
    repeat
      with cmdr[ii] do
      begin
        if (c in [#0,^M,'[',']']) then
        begin
          ansig(1,1);
          sprint('|WMenu Filename: '+scurmenu+' ['+cstr(ii)+'/'+cstr(noc)+']|LC');
          nl;
          sprint('|K[|CA|K] |cExtended desc   |w'+ldesc+'|LC');
          sprint('|K[|CB|K] |cNormal desc     |w'+sdesc+'|LC');
          sprint('|K[|CC|K] |cMenu keys       |w'+ckeys+'|LC');
          sprint('|K[|CD|K] |cAccess required |w'+acs+'|LC');
          sprint('|K[|CE|K] |cCommand letters |w'+cmdkeys+'  ');
          sprint('|K[|CF|K] |cMString         |w'+mstring+'|LC');
          sprint('|K[|CG|K] |cVisible to all  |w'+syn(visible)+' ');
          nl;
          sprompt('|wCommand |K[|C[|K/|C]|K/|CQ|c:uit|K] |W');
        end;
        ansig(21,11);
        sprompt(#32+^H+'|W');
        onek(c,'QABCDEFG[]'^M);
        nl;
        case c of
          'A':inputxy(21,3,cmdr[ii].ldesc,59);
          'B':inputxy(21,4,cmdr[ii].sdesc,35);
          'C':inputxy(21,5,cmdr[ii].ckeys,-14);
          'D':inputxy(21,6,cmdr[ii].acs,20);
          'E':inputxy(21,7,cmdr[ii].cmdkeys,-2);
          'F':inputxy(21,8,cmdr[ii].mstring,50);
          'G':switchyn(21,9,visible);
          '[':if (ii>1) then dec(ii) else ii:=noc;
          ']':if (ii<noc) then inc(ii) else ii:=1;
        end;
      end;
    until (c='Q') or (hangup);
  end;
end;

end.
