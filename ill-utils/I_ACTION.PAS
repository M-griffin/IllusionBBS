{$A+,B-,D-,E-,F+,G+,I+,L-,N-,O-,R-,S-,V-,X+}

program i_action;

uses crt,dos;

{$I ..\main\rec25.pas}

var act:actionrec;
    actf:file of actionrec;
    t:text;
    s:string;
    l:word;
    systat:systatrec;
    systatf:file of systatrec;
    i:byte;

function value(s:string):longint;
var i:longint;
    j:integer;
begin
  val(s,i,j);
  if (j<>0) then begin
    s:=copy(s,1,j-1);
    val(s,i,j)
  end;
  value:=i;
  if (s='') then value:=0;
end;

function line:string;
var ss:string[79];
begin
  fillchar(ss[1],79,'Ä');
  ss[0]:=chr(79);
  line:=ss;
end;

function allcaps(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do s[i]:=upcase(s[i]);
  allcaps:=s;
end;

begin
  textmode(co80);

  textattr:=15; write('I_ACTION');
  textattr:=8;  write(' - ');
  textattr:=15; writeln('Illusion Teleconference Actions Compiler version '+ver);
  textattr:=7;  writeln('Copyright 1992-1998, Illusion Development.  All rights reserved.');
  textattr:=8;  writeln(line);
  textattr:=7;  writeln;

  if (paramcount<>1) then
  begin
    writeln('Syntax:  I_ACTION <action text file>');
    halt;
  end;

  assign(systatf,'ILLUSION.CFG');
  {$I-} reset(systatf); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Cannot find ILLUSION.CFG');
    halt;
  end;
  read(systatf,systat);
  close(systatf);

  assign(t,paramstr(1));
  {$I-} reset(t); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Cannot find '+allcaps(paramstr(1)));
    halt;
  end;

  assign(actf,systat.datapath+'ACTION.DAT');
  {$I-} rewrite(actf); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Cannot create '+systat.datapath+'ACTION.DAT');
    halt;
  end;

  writeln('Compiling '+allcaps(paramstr(1))+'...');
  writeln;

  l:=0; i:=1;
  while not eof(t) do
  begin
    fillchar(s,sizeof(s),#0);
    readln(t,s);
    inc(l);
    write(^M,'Line ',l);
    if (s[1]<>';') then
    begin
      case i of
        1:act.act:=s;
        2:act.objectmsg:=s;
        3:act.globalmsg:=s;
        4:act.yourmsg:=s;
        5:act.noobject:=s;
      end;
      inc(i);
      if (i=6) then
      begin
        write(actf,act);
        i:=1;
      end;
    end;
    clreol;
  end;
  if (i<>1) then
  begin
    writeln;
    writeln;
    write('Error:  Unexpected end of file');
  end;
  close(t);
  close(actf);
  writeln;
end.
