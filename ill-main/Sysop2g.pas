(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2g/11] (validation profiles)              *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2g;

interface

uses
  crt, dos,
  common;

procedure poautoval;

implementation

var val:array[1..26] of ^valrec;
    valf:file of valrec;

function show_arflags(ss:integer):string;
var c:char;
    s:string[26];
begin
  s:='';
  for c:='A' to 'Z' do
    if c in val[ss]^.ar then s:=s+c else s:=s+'-';
  show_arflags:=s;
end;

function show_restric(ss:integer):string;
var r:uflags;
    s:string[15];
begin
  s:='';
  for r:=rlogon to rmsg do
    if r in val[ss]^.ac then
      s:=s+copy('LCVFA*PEKM',ord(r)+1,1)
    else s:=s+'-';
  s:=s+'/';
  for r:=fnodlratio to fnodeletion do
    if r in val[ss]^.ac then
      s:=s+copy('1234',ord(r)-19,1)
    else s:=s+'-';
  show_restric:=s;
end;

procedure zswac(var u:valrec; r:uflags);
begin
  if (r in u.ac) then exclude(u.ac,r) else include(u.ac,r);
end;

procedure zacch(c:char; var u:valrec);
begin
  case c of
    'L':zswac(u,rlogon);
    'C':zswac(u,rchat);
    'V':zswac(u,rvalidate);
    'F':zswac(u,rfastlogon);
    'A':zswac(u,ramsg);
    '*':zswac(u,rpostan);
    'P':zswac(u,rpost);
    'E':zswac(u,remail);
    'K':zswac(u,rvoting);
    'M':zswac(u,rmsg);
    '1':zswac(u,fnodlratio);
    '2':zswac(u,fnopostratio);
    '3':zswac(u,fnofilepts);
    '4':zswac(u,fnodeletion);
  end;
end;

function hsonoff(b:boolean):string;
begin
  if b then hsonoff:='Hard' else hsonoff:='Soft';
end;

procedure modify(i:byte);
var c,d:char;
    s:astr;
begin
  cls;
  c:=#0;
  repeat
    if (c in [#0,^M,'[',']']) then
    begin
      ansig(1,1);
      sprint('|WValidation Profile ['+chr(i+64)+'/Z]');
      nl;
      sprint('|K[|CA|K] |cProfile name  |w'+mlnnomci(val[i]^.name,30));
      sprint('|K[|CB|K] |cSL            |w'+mn(val[i]^.sl,3));
      sprint('|K[|CC|K] |cDSL           |w'+mn(val[i]^.dsl,3));
      sprint('|K[|CD|K] |cAR flags      |w'+show_arflags(i));
      sprint('|K[|CE|K] |cAC flags      |w'+show_restric(i));
      sprint('|K[|CF|K] |cFile points   |w'+aonoff(val[i]^.fp=-1,'Unaffected',cstr(val[i]^.fp))+'|LC');
      sprint('|K[|CG|K] |cCredits       |w'+aonoff(val[i]^.credit=-1,'Unaffected',cstr(val[i]^.credit))+'|LC');
      sprint('|K[|CH|K] |cAR upgrade    |w'+hsonoff(val[i]^.artype));
      sprint('|K[|CI|K] |cAC upgrade    |w'+hsonoff(val[i]^.actype));
      sprint('|K[|CJ|K] |cUser note     |w'+mlnnomci(val[i]^.unote,20));
      nl;
      sprompt('|wCommand |K[|C[|K/|C]|K/|CQ|c:uit|K] |W');
    end;
    ansig(20,14);
    sprompt(#32+^H+'|W');
    onek(c,'QABCDEFGHIJ[]'^M);
    case c of
      'A':inputxy(19,3,val[i]^.name,30);
      'B':val[i]^.sl:=inputnumxy(19,4,val[i]^.sl,3,0,255);
      'C':val[i]^.dsl:=inputnumxy(19,5,val[i]^.dsl,3,0,255);
      'D':begin
            repeat
              sprompt('|W|I1906'+show_arflags(i)+' '+^H);
              onek(d,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
              if (d in ['A'..'Z']) then
                if (d in val[i]^.ar) then exclude(val[i]^.ar,d)
                                     else include(val[i]^.ar,d);
            until (d=^M) or (hangup);
            sprompt('|w|I1906'+show_arflags(i));
          end;
      'E':begin
            repeat
              sprompt('|W|I1907'+show_restric(i)+' '+^H);
              onek(d,'LCVFA*PEKM1234'^M);
              if (d<>^M) then zacch(d,val[i]^);
            until (d=^M) or (hangup);
            sprompt('|w|I1907'+show_restric(i));
          end;
      'F':begin
            sprompt('|w|I2408 (-1 to ignore)');
            val[i]^.fp:=inputnumxy(19,8,val[i]^.fp,5,-1,32767);
            sprompt('|w|I1908'+mn(val[i]^.fp,20));
          end;
      'G':begin
            sprompt('|w|I2409 (-1 to ignore)');
            val[i]^.credit:=inputnumxy(19,9,val[i]^.credit,5,-1,32767);
            sprompt('|w|I1909'+mn(val[i]^.credit,20));
          end;
      'H':begin
            val[i]^.artype:=not val[i]^.artype;
            sprompt('|w|I1910'+hsonoff(val[i]^.artype));
          end;
      'I':begin
            val[i]^.actype:=not val[i]^.actype;
            sprompt('|w|I1911'+hsonoff(val[i]^.actype));
          end;
      'J':inputxy(19,12,val[i]^.unote,20);
      '[':if (i>1) then dec(i) else i:=26;
      ']':if (i<25) then inc(i) else i:=1;
    end;
  until (c='Q') or (hangup);
end;

procedure poautoval;
var c,d:char;
    i:integer;
    s:string[20];
begin
  for i:=1 to 26 do new(val[i]);
  assign(valf,systat^.datapath+'AUTOVAL.DAT');
  SetFileAccess(ReadWrite,DenyNone);
  reset(valf);
  for i:=1 to 26 do read(valf,val[i]^);
  close(valf);
  c:=#0;
  repeat
    cls;
    sprint('|WValidation Profiles');
    nl; cl(ord('w'));
    for i:=1 to 13 do
    begin
      if (i=1) then sprompt('|C');
      sprint('|K[|C'+chr(i+64)+'|K] |c'+mln(val[i]^.name,32)+'|K[|C'+chr(i+77)+'|K] |c'+val[i+13]^.name);
    end;
    nl;
    sprompt('|wCommand |K[|CE|c:dit|K/|CQ|c:uit|K] |W');
    ansig(23,17);
    sprompt(#32+^H+'|W');
    onek(c,'QE'^M);
    case c of
      'E':begin
            sprompt('|wEdit autoval |K[|CA|c-|CZ|K] |W');
            onek(d,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
            if (d in ['A'..'Z']) then modify(ord(d)-64);
          end;
    end;
  until (c='Q') or (hangup);
  rewrite(valf);
  for i:=1 to 26 do write(valf,val[i]^);
  close(valf);
  for i:=1 to 26 do dispose(val[i]);
end;

end.
