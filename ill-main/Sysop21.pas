(*****************************************************************************)
(* Illusion BBS - SysOp routines  [21/11] (1..5 commands)                    *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop21;

interface

uses
  crt, dos,
  common;

procedure getsecrange(editing:astr; var sec:secrange);

implementation

procedure getsecrange(editing:astr; var sec:secrange);
var pag:byte;
    c:char;
    i,j,k:byte;
    h:integer;
    done:boolean;

  procedure showsecrange(beg:byte);
  var s:astr;
      i,j:byte;
      k:integer;
  begin
    i:=0;
    repeat
      s:='|w';
      for j:=0 to 6 do begin
        k:=beg+i+j*20;
        if (k<=255) then begin
          s:=s+mn(k,3)+':'+mn(sec[k],5);
          if (j<>7) then s:=s+' ';
        end;
      end;
      sprint(s);
      inc(i);
    until (i>19) or (hangup);
  end;

begin
  done:=FALSE;
  pag:=0;
  repeat
    cls;
    sprint(editing);
    nl;
    showsecrange(pag);
    nl;
    sprompt('|wRange Settings |K[|CS|c:et|K/|CT|c:oggle|K/|CQ|c:uit|K] |W');
    onek(c,'QST'^M);
    case c of
      'Q':done:=TRUE;
      'S':begin
            nl;
            sprompt('|wFrom |K[|C0|c-|C255|K] |W');
            ini(i);
            if (not badini) then begin
              sprompt('|wTo   |K[|C0|c-|C255|K] |W');
              ini(j);
              if ((not badini) and (j>=i)) then
              begin
                sprompt('|wValue |K[|C0|c-|C32767|K] |W');
                inu(h);
                if (not badini) then for k:=i to j do sec[k]:=h;
              end;
            end;
          end;
      'T':if (pag=0) then pag:=140 else pag:=0;
    end;
  until ((done) or (hangup));
end;

end.
