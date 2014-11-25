(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2o/11] (network addresses)                *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2o;

interface

uses
  crt, dos,
  common;

procedure ponetaddr;
function getaddr(a:akarec):string;

implementation

function getaddr(a:akarec):string;
begin
  getaddr:=cstr(a.zone)+':'+cstr(a.net)+'/'+cstr(a.node)+'.'+cstr(a.point);
end;

procedure ponetaddr;
var c:char;
    s:astr;
    i,j:byte;
begin
  c:=#0;
  repeat
    with systat^ do
    begin
      if (c in [#0,^M]) then
      begin
        cls;
        sprint('|WNetwork Addresses');
        nl;
        for i:=1 to 10 do
          sprint('|K[|C'+chr(i+64)+'|K] |c'+mln(getaddr(aka[i]),30)+
                ' |K[|C'+chr(i+74)+'|K] |c'+getaddr(aka[i+10]));
        nl;
        sprompt('|wCommand |K[|CE|c:dit|K/|CQ|c:uit|K] |W');
      end;
      ansig(1,15); sprompt('|LC');
      ansig(23,14);
      sprompt(#32+^H+'|W');
      onek(c,'QE'^M);
      case c of
        'E':begin
              sprompt('|wEdit address |K[|CA-T|K] |W');
              onek(c,'ABCDEFGHIJKLMNOPQRST'^M);
              if (c in ['A'..'T']) then
              begin
                i:=ord(c)-64;
                if (i<=10) then ansig(5,i+2) else ansig(40,i-10+2);
                s:=getaddr(aka[i]);
                inputed(s,30,'OS');
                fillchar(aka[i],sizeof(aka[i]),0);
                with aka[i] do
                begin
                  j:=pos(':',s);
                  if (j<2) then
                    zone:=value(s)
                  else
                  begin
                    zone:=value(copy(s,1,j-1));
                    delete(s,1,j);
                    j:=pos('/',s);
                    if (j<2) then
                      net:=value(s)
                    else
                    begin
                      net:=value(copy(s,1,j-1));
                      delete(s,1,j);
                      j:=pos('.',s);
                      if (j<2) then
                        node:=value(s)
                      else
                      begin
                        node:=value(copy(s,1,j-1));
                        delete(s,1,j);
                        point:=value(s);
                      end;
                    end;
                  end;
                end;
                if (i<=10) then ansig(5,i+2) else ansig(40,i-10+2);
                sprompt('|c'+mln(getaddr(aka[i]),30));
              end;
            end;
      end;
    end;
  until (c='Q') or (hangup);
end;

end.
