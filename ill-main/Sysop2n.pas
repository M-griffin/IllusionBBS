(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2n/11] (pathname configuration)           *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2n;

interface

uses
  crt, dos,
  common;

procedure popath;

implementation

procedure searchandreplace(c:char;old,new:astr);
var ii:word;
begin
  setfileaccess(readwrite,denynone);
  reset(bf);
  ii:=0;
  while (ii<=numboards) do
  begin
    seek(bf,ii);
    read(bf,memboard);
    if (memboard.msgareaid[1]=c) then
    begin
      with memboard do
        msgareaid:=substone(msgareaid,old,new);
      seek(bf,ii);
      write(bf,memboard);
    end;
    inc(ii);
  end;
  close(bf);
end;

procedure popath;
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
        sprint('|WPathname Configuration');
        nl;
        sprint('|K[|CA|K] |cData files         |w'+datapath);
        sprint('|K[|CB|K] |cText files         |w'+textpath);
        sprint('|K[|CC|K] |cMenu files         |w'+menupath);
        sprint('|K[|CD|K] |cLog files          |w'+trappath);
        sprint('|K[|CE|K] |cMultinode files    |w'+multpath);
        sprint('|K[|CF|K] |cIPL executables    |w'+iplxpath);
        sprint('|K[|CG|K] |cProtocol drivers   |w'+protpath);
        sprint('|K[|CH|K] |cArchive utilities  |w'+arcpath);
        nl;
        sprint('|K[|CI|K] |cHudson messages    |w'+hudsonpath);
        sprint('|K[|CJ|K] |cJAM messages       |w'+jampath);
        sprint('|K[|CK|K] |cSquish messages    |w'+squishpath);
        sprint('|K[|CL|K] |cEzycom messages    |w'+ezycompath);
        nl;
        sprompt('|wCommand |K[|CQ|c:uit|K] |W');
      end;
      ansig(17,17);
      sprompt(#32+^H+'|W');
      onek(c,'QABCDEFGHIJKL'^M);
      case c of
        'A'..'H':
           begin
             ansig(24,3+ord(c)-65);
             case c of
               'A':inputed(datapath,56,'OSUB');
               'B':inputed(textpath,56,'OSUB');
               'C':inputed(menupath,56,'OSUB');
               'D':inputed(trappath,56,'OSUB');
               'E':inputed(multpath,56,'OSUB');
               'F':inputed(iplxpath,56,'OSUB');
               'G':inputed(protpath,56,'OSUB');
               'H':inputed(arcpath,56,'OSUB');
             end;
           end;
        'I'..'L':
           begin
             ansig(24,4+ord(c)-65);
             case c of
               'I':begin
                     s:=hudsonpath;
                     inputed(s,56,'OSUB');
                     if (s<>hudsonpath) then searchandreplace('H',hudsonpath,s);
                     hudsonpath:=s;
                   end;
               'J':begin
                     s:=jampath;
                     inputed(s,56,'OSUB');
                     if (s<>jampath) then searchandreplace('J',jampath,s);
                     jampath:=s;
                   end;
               'K':begin
                     s:=squishpath;
                     inputed(s,56,'OSUB');
                     if (s<>squishpath) then searchandreplace('S',squishpath,s);
                     squishpath:=s;
                   end;
               'L':begin
                     s:=ezycompath;
                     inputed(s,56,'OSUB');
                     if (s<>ezycompath) then searchandreplace('E',ezycompath,s);
                     ezycompath:=s;
                   end;
             end;
           end;
      end;
    end;
  until (c='Q') or (hangup);
end;

end.
