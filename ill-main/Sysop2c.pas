(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2c/11] (message system config)            *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2c;

interface

uses
  crt, dos,
  common;

procedure pomsg;

implementation

procedure pomsg;
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
        sprint('|WMessage System Configuration');
        nl;
        sprint('|K[|CA|K] |cMaximum posts per call   |w'+mn(maxpubpost,10)+
               '|K[|CS|K] |cMaximum mail in mailbox  |w'+cstr(maxwaiting));
        sprint('|K[|CB|K] |cMax email sent per call  |w'+mn(maxprivpost,10)+
               '|K[|CT|K] |cCosysop maximum mail     |w'+cstr(csmaxwaiting));
        sprint('|K[|CC|K] |cStrip special codes      |w'+mln(syn(strip),10)+
               '|K[|CU|K] |cAdd tear/origin lines    |w'+syn(addtear));
        sprint('|K[|CD|K] |cMin disk space for post  |w'+mn(minspaceforpost,10)+
               '|K[|CV|K] |cCompress area numbers    |w'+syn(compressmsgbases));
        sprint('|K[|CE|K] |cDefault origin line      |w'+origin);
        sprint('|K[|CF|K] |cDefault text color       |w'+text_color+'|'+text_color+'  Normal Text');
        sprint('|K[|CG|K] |cDefault quote color      |w'+quote_color+'|'+quote_color+'  > Quoted Text');
        sprint('|K[|CH|K] |cDefault tear color       |w'+tear_color+'|'+tear_color+'  --- Illusion v'+ver);
        sprint('|K[|CI|K] |cDefault origin color     |w'+origin_color+'|'+origin_color+'  * Origin:');
        sprint('|K[|CJ|K] |cMsg base sysop access    |w'+msop);
        sprint('|K[|CK|K] |cPost public messages     |w'+normpubpost);
        sprint('|K[|CL|K] |cSend email access        |w'+normprivpost);
        sprint('|K[|CM|K] |cPost anonymous messages  |w'+anonpubpost);
        sprint('|K[|CN|K] |cSee public anon. author  |w'+anonpubread);
        sprint('|K[|CO|K] |cSend anonymous email     |w'+anonprivpost);
        sprint('|K[|CP|K] |cSee email anon. author   |w'+anonprivread);
        sprint('|K[|CR|K] |cNo post/call ratio       |w'+nopostratio);
        nl;
        sprompt('|wCommand |K[|CQ|c:uit|K] |W');
      end;
      ansig(17,21);
      sprompt(#32+^H+'|W');
      onek(c,'QABCDEFGHIJKLMNOPRSTUV'^M);
      case c of
        'A':maxpubpost:=inputnumxy(30,3,maxpubpost,3,0,255);
        'B':maxprivpost:=inputnumxy(30,4,maxprivpost,3,0,255);
        'C':switchyn(30,5,strip);
        'D':minspaceforpost:=inputnumxy(30,6,minspaceforpost,5,0,32767);
        'E':inputxy(30,7,origin,50);
        'F':begin
              ansig(30,8);
              s:=text_color;
              inputed(s,1,'O');
              if (isc(s[1])) then text_color:=s[1];
              sprompt('|w|I3008'+text_color+'|'+text_color+'  Normal Text');
            end;
        'G':begin
              ansig(30,9);
              s:=quote_color;
              inputed(s,1,'O');
              if (isc(s[1])) then quote_color:=s[1];
              sprompt('|w|I3009'+quote_color+'|'+quote_color+'  > Quoted Text');
            end;
        'H':begin
              ansig(30,10);
              s:=tear_color;
              inputed(s,1,'O');
              if (isc(s[1])) then tear_color:=s[1];
              sprompt('|w|I3010'+tear_color+'|'+tear_color+'  --- Illusion v'+ver);
            end;
        'I':begin
              ansig(30,11);
              s:=origin_color;
              inputed(s,1,'O');
              if (isc(s[1])) then origin_color:=s[1];
              sprompt('|w|I3011'+origin_color+'|'+origin_color+'  * Origin:');
            end;
        'J'..'P':
            begin
              ansig(30,12+ord(c)-74);
              case c of
                'J':inputed(msop,20,'O');
                'K':inputed(normpubpost,20,'O');
                'L':inputed(normprivpost,20,'O');
                'M':inputed(anonpubpost,20,'O');
                'N':inputed(anonpubread,20,'O');
                'O':inputed(anonprivpost,20,'O');
                'P':inputed(anonprivread,20,'O');
              end;
            end;
        'R':inputxy(30,19,nopostratio,20);
        'S':maxwaiting:=inputnumxy(69,3,maxwaiting,3,0,255);
        'T':csmaxwaiting:=inputnumxy(69,4,csmaxwaiting,3,0,255);
        'U':switchyn(69,5,addtear);
        'V':switchyn(69,6,compressmsgbases);
      end;
    end;
  until (c='Q') or (hangup);
end;

end.
