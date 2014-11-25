(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2b/11] (main bbs config)                  *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2b;

interface

uses
  crt, dos,
  sysop3, common;

procedure pobbs;

implementation

function swaptype(i:byte):string;
begin
  case i of
    0:swaptype:='Disk';
    1:swaptype:='EMS';
    2:swaptype:='XMS';
    3:swaptype:='All';
  end;
end;

procedure pobbs;
var s:astr;
    c:char;
begin
  c:=#0;
  repeat
    with systat^ do
    begin
      if (c in [#0,^M]) then
      begin
        cls;
        sprint('|WMain BBS Configuration');
        nl;
        sprint('|K[|CA|K] |cBBS name             |w'+bbsname);
        sprint('|K[|CB|K] |cBBS phone number     |w'+bbsphone);
        sprint('|K[|CC|K] |cBBS location         |w'+bbslocation);
        sprint('|K[|CD|K] |cSysop name/handle    |w'+sysopname);
        sprint('|K[|CE|K] |cSystem password      |w'+sysoppw);
        sprint('|K[|CF|K] |cFull sysop access    |w'+sop);
        sprint('|K[|CG|K] |cFull cosysop access  |w'+csop);
        sprint('|K[|CH|K] |cSee PWs remotely     |w'+seepw);
        sprint('|K[|CI|K] |cSwapping             |w'+
          aonoff(swapshell,'Active ('+swaptype(swapshelltype)+')','In-active'));
        sprint('|K[|CJ|K] |cOverlay position     |w'+swaptype(putovr));
        sprint('|K[|CK|K] |cUse BIOS for output  |w'+syn(usebios));
        sprint('|K[|CL|K] |cSnow checking (CGA)  |w'+syn(cgasnow));
        sprint('|K[|CM|K] |cTimeout bell (min)   |w'+mn(timeoutbell,14)+
               '|K[|CR|K] |cRequire Ansi         |w'+syn(reqansi));
        sprint('|K[|CN|K] |cTimeout (min)        |w'+mn(timeout,14)+
               '|K[|CS|K] |cAllow Avatar         |w'+syn(allowavatar));
        sprint('|K[|CO|K] |cAnimated pause       |w'+mln(syn(specialfx and 1=1),14)+
               '|K[|CT|K] |cAllow Rip            |w'+syn(allowrip));
        sprint('|K[|CP|K] |cExecute system BATs  |w'+syn(sysbatexec));
        nl;
        sprompt('|wCommand |K[|CQ|c:uit|K] |W');
      end;
      ansig(17,20);
      sprompt(#32+^H+'|W');
      onek(c,'QABCDEFGHIJKLMNOPRST'^M);
      case c of
        'A':inputxy(26,3,bbsname,40);
        'B':inputxy(26,4,bbsphone,-12);
        'C':inputxy(26,5,bbslocation,39);
        'D':inputxy(26,6,sysopname,30);
        'E':inputxy(26,7,sysoppw,-20);
        'F':inputxy(26,8,sop,20);
        'G':inputxy(26,9,csop,20);
        'H':inputxy(26,10,seepw,20);
        'I':begin
              if not (swapshell) then
              begin
                swapshell:=TRUE;
                swapshelltype:=0;
              end else
              begin
                inc(swapshelltype);
                if (swapshelltype>3) then
                  swapshell:=FALSE;
              end;
              sprompt('|w|I2611'+mln(aonoff(swapshell,'Active ('+swaptype(swapshelltype)+')','In-active'),13)+'|LC');
            end;
        'J':begin
              inc(putovr);
              if (putovr>2) then putovr:=0;
              sprompt('|w|I2612'+mln(swaptype(putovr),4)+'|LC');
            end;
        'K':switchyn(26,13,usebios);
        'L':switchyn(26,14,cgasnow);
        'M':timeoutbell:=inputnumxy(26,15,timeoutbell,5,0,32767);
        'N':timeout:=inputnumxy(26,16,timeout,5,0,32767);
        'O':begin
              specialfx:=specialfx xor 1;
              sprompt('|w|I2617'+aonoff(specialfx and 1=1,'Yes','No '));
            end;
        'P':switchyn(26,18,sysbatexec);
        'R':switchyn(65,15,reqansi);
        'S':switchyn(65,16,allowavatar);
        'T':switchyn(65,17,allowrip);
      end;
    end;
  until (c='Q') or (hangup);
end;

end.
