(*****************************************************************************)
(* Illusion BBS - Modem routines                                             *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit mmodem;

interface

uses
  crt, dos,
  common, foscom2, myio;

Type
  ResultType=string[25];

const
  mdmstr:astr='';

procedure wr(c:char);
procedure wrs(s:astr);
procedure wrd;
procedure doresultcode(var rc:resulttype;       { result code }
                            t:real;             { time to get code }
                       showit:boolean);         { show code on screen? }
function fixspeed(s:word):longint;
procedure outmodemstring(s:astr);
procedure dophonehangup(showit:boolean);
procedure dophoneoffhook(showit:boolean);

implementation

uses wfcmenu;

procedure wr(c:char);
var j:integer;
begin
  if c in [#32..#255] then
    mdmstr:=mdmstr+c;
end;

procedure wrs(s:astr);
begin
  mdmstr:=s;
  wrd;
end;

procedure wrd;
var i:byte;
begin
  if (mdmstr<>'') then
  begin
    window(55,4,75,14);
    gotoxy(19,11);
    textattr:=7;
    writeln;
    if length(mdmstr)<20 then
    begin
      for i:=1 to (20-length(mdmstr)) div 2 do write(' ');
      for i:=1 to length(mdmstr) do write(mdmstr[i]);
    end else
      write(mln(mdmstr,20));
    mdmstr:='';
    window(1,1,80,linemode);
  end;
end;

procedure doresultcode(var rc:resulttype;       { result code }
                            t:real;             { time to get code }
                       showit:boolean);         { show code on screen? }
var r:real;
    done:boolean;
    c:char;
begin
  rc:=''; r:=timer; done:=false;
  repeat
    c:=ccinkey1;
    if (c=#13) and (rc<>'') then done:=true;
    if (c<#32) then c:=#0;
    if (c<>#0) and (c<>#13) then rc:=rc+c;
  until (done) or (abs(r-timer)>=t);
  if showit then wrs(rc);
end;

function fixspeed(s:word):longint;
var n:longint;
begin
  case s of
    4800,
    7200:n:=9600;       { Updates made here must also be       }
    12000,              { made to the duplicate case statement }
    14400,              { in "iport" in common2.pas            }
    16800:n:=19200;
    21600,
    24000,
    26400,
    28800,
    31200,
    33600:n:=38400;
    else n:=s;
  end;
  if modemr^.portlock then n:=modemr^.lockspeed;
  fixspeed:=n;
end;

procedure outmodemstring(s:astr);
var i:integer;
begin
  for i:=1 to length(s) do
    case s[i] of
      '~':sleep(500);
      '|':com_tx(^M);
    else
      begin
        com_tx(s[i]);
        delay(5);
      end;
    end; {case}
  sleep(200);
  {com_flush_rx;}
  com_tx(^M);
end;

procedure dophonehangup(showit:boolean);
var rc:^resulttype;
    c:char;
begin
  if (spd<>'KB') then
  begin


    {new(rc);}
    
    { New Skipped 4 Tries of Handup Bullshit }
    
    wfcmsg('Terminating call');
    
    com_flush_rx;
    
    {outmodemstring(modemr^.esccode);}
    {outmodemstring(modemr^.hangup);}
    {doresultcode(rc^,4.0,showit);}
      
    {dispose(rc);}

    term_ready(TRUE);
  end;
end;

procedure dophoneoffhook(showit:boolean);
var rc:^resulttype;
    c:char;
    done:boolean;
    t:real;
begin
  if (showit) then wfcmsg('Taking phone off hook');

  {sleep(150);}
  com_flush_rx;
  outmodemstring(modemr^.offhook);
  {sleep(150);}

  t:=timer;
  new(rc);
  repeat
    doresultcode(rc^,1.0,showit);
  until (pos(modemr^.codeok,rc^)<>0) or (timer-t>=5.0);
  dispose(rc);

  {sleep(50);}
  com_flush_rx;
end; {proc dophoneoffhook}

end.
