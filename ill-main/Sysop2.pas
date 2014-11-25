(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2/11] (system config menu)                *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2;

interface

uses
  crt, dos,
  sysop2a, sysop2b, sysop2c, sysop2d, sysop2e, sysop2f, sysop2g, sysop2h,
  sysop2i, sysop2k, sysop2l, sysop2j, sysop21, sysop2m, sysop2n, sysop2o,
  sysop2p, sysop2r, sysop2s, common;

procedure changestuff;

implementation

procedure changestuff;
var c:char;
    hadpause,done:boolean;
begin
  readsystat;
  hadpause:=(pause in thisuser.ac);
  if (hadpause) then exclude(thisuser.ac,pause);
  repeat
    done:=FALSE;
    cls;
    sprint('|WIllusion System Configuration');
    nl;
    sprint('|K[|CA|K] |cModem/Node Configuration          |K[|CB|K] |cMain BBS Configuration');
    sprint('|K[|CC|K] |cMessage System Configuration      |K[|CD|K] |cFile System Configuration');
    sprint('|K[|CE|K] |cNew User Voting Configuration     |K[|CF|K] |cChat Configuration');
    sprint('|K[|CG|K] |cValidation Profiles               |K[|CH|K] |cOffline Mailer Configuration');
    sprint('|K[|CI|K] |cLogon Configuration               |K[|CJ|K] |cSysop Window Configuration');
    sprint('|K[|CK|K] |c[archive configuration]           |K[|CL|K] |cConference Editor');
    sprint('|K[|CM|K] |cSecurity Configuration            |K[|CN|K] |cPathname Configuration');
    sprint('|K[|CO|K] |cNetwork Addresses                 |K[|CP|K] |cProtocol Editor');
    sprint('|K[|CR|K] |cMiscellaneous Configuration       |K[|CS|K] |cRumor Editor');
    nl;
    sprint('|K[|C1|K] |cTime Limitations                  |K[|C2|K] |cCall Per Day Limitations');
    sprint('|K[|C3|K] |cUpload/Download Files Ratio       |K[|C4|K] |cUpload/Download Kilobytes ratio');
    sprint('|K[|C5|K] |cPost/Call Ratio');
    nl;
    sprompt('|wCommand |K[|CQ|c:uit|K] |W');
    onek(c,'QABCDEFGHIJKLMNOPRS12345'^M);
    case c of
      'A':pomodem;
      'B':pobbs;
      'C':pomsg;
      'D':pofile;
      'E':ponuv;
      'F':pochat;
      'G':poautoval;
      'H':poqwk;
      'I':pologonconfig;
      'J':posysopwind;
      'K':poarcconfig;
      'L':poconf;
      'M':posecurity;
      'N':popath;
      'O':ponetaddr;
      'P':poproedit;
      'R':pomisc;
      'S':porumoredit;
      '1':getsecrange('|WTime Limitations',systat^.timeallow);
      '2':getsecrange('|WCall Per Day Limitations',systat^.callallow);
      '3':getsecrange('|WUpload/Download Files Ratio',systat^.dlratio);
      '4':getsecrange('|WUpload/Download Kilobytes Ratio',systat^.dlkratio);
      '5':getsecrange('|WPost/Call Ratio',systat^.postratio);
      'Q':done:=TRUE;
    end;
  until ((done) or (hangup));
  if (hadpause) then include(thisuser.ac,pause);
  savesystat;
  topscr;
end;

end.
