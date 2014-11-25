(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2d/11] (file system config)               *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2d;

interface

uses
  crt, dos,
  common;

procedure pofile;

implementation

procedure pofile;
var s:astr;
    c:char;

  function dtype:string;
  begin
    case systat^.descimport of
      0:dtype:='Do not import';
      1:dtype:='Ask user';
      2:dtype:='Always import';
    end;
  end;

begin
  c:=#0;
  repeat
    with systat^ do
    begin
      if (c in [#0,^M]) then
      begin
        cls;
        sprint('|WFile System Configuration');
        nl;
        sprint('|K[|CA|K] |cCompress area numbers    |w'+mln(syn(compressfilebases),10)+
               '|K[|CP|K] |cUse UL/DL ratio          |w'+syn(uldlratio));
        sprint('|K[|CB|K] |cAuto-validate uploads    |w'+mln(syn(validateallfiles),10)+
               '|K[|CR|K] |cUse file point system    |w'+syn(fileptratio));
        sprint('|K[|CC|K] |cUpload time refund (%)   |w'+mn(ulrefund,10)+
               '|K[|CS|K] |cFile point return (%)    |w'+cstr(fileptcomp));
        sprint('|K[|CD|K] |c"To SysOp" file base     |w'+mn(tosysopdir,10)+
               '|K[|CT|K] |cKb per file point        |w'+cstr(fileptcompbasesize));
        sprint('|K[|CE|K] |cSearch for duplicates    |w'+mln(syn(searchdup),10)+
               '|K[|CU|K] |cUnlisted DL file points  |w'+cstr(unlistfp));
        sprint('|K[|CF|K] |cMin. disk space for UL   |w'+mn(minspaceforupload,10)+
               '|K[|CV|K] |cFile points per post     |w'+cstr(postcredits));
        sprint('|K[|CG|K] |cMinimum kb for resume    |w'+mn(minresume,10)+
               '|K[|CW|K] |cSwap for file transfer   |w'+syn(swapxfer));
        sprint('|K[|CH|K] |cDOS redirection device   |w'+remdevice);
        sprint('|K[|CI|K] |cImport descriptions      |w'+dtype);
        sprint('|K[|CJ|K] |cFile sysop access        |w'+fsop);
        sprint('|K[|CK|K] |cSee unvalidated files    |w'+seeunval);
        sprint('|K[|CL|K] |cDownload unval''d files  |w '+dlunval);
        sprint('|K[|CM|K] |cNo UL/DL ratio access    |w'+nodlratio);
        sprint('|K[|CN|K] |cNo file point checking   |w'+nofilepts);
        sprint('|K[|CO|K] |cULs require validation   |w'+ulvalreq);
        nl;
        sprompt('|wCommand |K[|CQ|c:uit|K] |W');
      end;
      ansig(17,19);
      sprompt(#32+^H+'|W');
      onek(c,'QABCDEFGHIJKLMNOPRSTUVW'^M);
      nl;
      case c of
        'A':switchyn(30,3,compressfilebases);
        'B':switchyn(30,4,validateallfiles);
        'C':ulrefund:=inputnumxy(30,5,ulrefund,3,0,255);
        'D':tosysopdir:=inputnumxy(30,6,tosysopdir,3,0,255);
        'E':switchyn(30,7,searchdup);
        'F':minspaceforupload:=inputnumxy(30,8,minspaceforupload,5,0,32767);
        'G':minresume:=inputnumxy(30,9,minresume,5,0,32767);
        'H':inputxy(30,10,remdevice,-10);
        'I':begin
              inc(descimport);
              if (descimport>2) then descimport:=0;
              sprompt('|w|I3011'+dtype+'|LC');
            end;
        'J':inputxy(30,12,fsop,20);
        'K':inputxy(30,13,seeunval,20);
        'L':inputxy(30,14,dlunval,20);
        'M':inputxy(30,15,nodlratio,20);
        'N':inputxy(30,16,nofilepts,20);
        'O':inputxy(30,17,ulvalreq,20);
        'P':switchyn(69,3,uldlratio);
        'R':switchyn(69,4,fileptratio);
        'S':fileptcomp:=inputnumxy(69,5,fileptcomp,5,0,65535);
        'T':fileptcompbasesize:=inputnumxy(69,6,fileptcompbasesize,5,0,65535);
        'U':unlistfp:=inputnumxy(69,7,unlistfp,3,0,255);
        'V':postcredits:=inputnumxy(69,8,postcredits,5,0,65535);
        'W':switchyn(69,9,swapxfer);
      end;
    end;
  until (c='Q') or (hangup);
end;

end.
