(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2i/11] (logon configuration)              *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2i;

interface

uses
  crt, dos,
  common;

procedure pologonconfig;

implementation

procedure pologonconfig;
var s:astr;
    c:char;
    nuu:word;
begin
  c:=#0;
  repeat
    with systat^ do
    begin
      if (c in [#0,^M]) then
      begin
        cls;
        sprint('|WLogon Configuration');
        nl;
        sprint('|K[|CA|K] |cCaller number         |w'+mn(callernum,13)+
               '|K[|CP|K] |cDefault line length   |w'+cstr(linelen));
        sprint('|K[|CB|K] |cOffhook when local    |w'+mln(syn(offhooklocallogon),13)+
               '|K[|CR|K] |cDefault page length   |w'+cstr(pagelen));
        sprint('|K[|CC|K] |cHandles allowed       |w'+mln(syn(allowalias),13));
        sprint('|K[|CD|K] |cClosed system         |w'+mln(syn(closedsystem),13));
        sprint('|K[|CE|K] |cNew user password     |w'+newuserpw);
        sprint('|K[|CF|K] |cNU letter sent to     |w'+cstr(newapp));
        sprint('|K[|CG|K] |cMatrix logon          |w'+aonoff(shuttlelog,'Active','Inactive'));
        sprint('|K[|CH|K] |cMatrix password       |w'+shuttlepw);
        sprint('|K[|CI|K] |cMatrix menu (ansi)    |w'+matrixmenu_ansi);
        sprint('|K[|CJ|K] |cMatrix menu (tty)     |w'+matrixmenu_tty);
        sprint('|K[|CK|K] |cAsk phone number      |w'+syn(phonepw));
        sprint('|K[|CL|K] |cAsk system PW access  |w'+spw);
        sprint('|K[|CM|K] |cLogon attempts        |w'+cstr(maxlogontries));
        sprint('|K[|CN|K] |cStartup menu          |w'+allcaps(allstartmenu));
        sprint('|K[|CO|K] |cFast logon access     |w'+fastlogonacs);
        nl;
        sprompt('|wCommand |K[|CQ|c:uit|K] |W');
      end;
      ansig(17,19);
      sprompt(#32+^H+'|W');
      onek(c,'QABCDEFGHIJKLMNOPR'^M);
      case c of
        'A':callernum:=inputnumxy(27,3,callernum,10,0,2147483647);
        'B':switchyn(27,4,offhooklocallogon);
        'C':switchyn(27,5,allowalias);
        'D':switchyn(27,6,closedsystem);
        'E':inputxy(27,7,newuserpw,-20);
        'F':begin
              setfileaccess(readonly,denynone);
              reset(uf); nuu:=filesize(uf)-1; close(uf);
              newapp:=inputnumxy(27,8,newapp,5,-1,nuu);
            end;
        'G':begin
              shuttlelog:=not shuttlelog;
              sprompt('|w|I2709'+aonoff(shuttlelog,'Active  ','Inactive'));
            end;
        'H':inputxy(27,10,shuttlepw,-20);
        'I':inputxy(27,11,matrixmenu_ansi,-8);
        'J':inputxy(27,12,matrixmenu_tty,-8);
        'K':switchyn(27,13,phonepw);
        'L':inputxy(27,14,spw,20);
        'M':maxlogontries:=inputnumxy(27,15,maxlogontries,3,0,255);
        'N':inputxy(27,16,allstartmenu,-8);
        'O':inputxy(27,17,fastlogonacs,20);
        'P':linelen:=inputnumxy(66,3,linelen,3,0,255);
        'R':pagelen:=inputnumxy(66,4,pagelen,3,0,255);
      end;
    end;
  until (c='Q') or (hangup);
end;

end.
