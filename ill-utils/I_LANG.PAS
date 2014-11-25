{$A+,B-,D-,E-,F+,G+,I+,L-,N-,O-,R-,S-,V-,X+}

program i_lang;

uses crt,dos;

{$I ..\main\rec25.pas}

var t:text;
    f:file of string;
    s,s1,s2:string;
    l,w:word;
    systat:systatrec;
    systatf:file of systatrec;

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

function cstrzero(i:longint):string;
var c:string[3];
begin
  str(i,c);
  while (length(c)<3) do c:='0'+c;
  cstrzero:=c;
end;

procedure compile;
begin
  assign(t,paramstr(2));
  {$I-} reset(t); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Cannot find '+allcaps(paramstr(2)));
    halt;
  end;

  assign(f,systat.datapath+'STRINGS.DAT');
  {$I-} rewrite(f); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Cannot create '+systat.datapath+'STRINGS.DAT');
    halt;
  end;

  writeln('Compiling '+allcaps(paramstr(2))+' to STRINGS.DAT...');
  writeln;

  fillchar(s,sizeof(s),#0);
  for w:=0 to 999 do write(f,s);
  l:=0;
  while not eof(t) do
  begin
    fillchar(s,sizeof(s),#0);
    fillchar(s2,sizeof(s2),#0);
    readln(t,s);
    inc(l);
    write(^M,'Line ',l,', ');
    if (s[1]<>';') then
    begin
      w:=value(copy(s,1,3));
      write('String ',w);
      if (s[1] in ['0'..'9']) and
         (s[2] in ['0'..'9']) and
         (s[3] in ['0'..'9']) then
      begin
        seek(f,w);
        read(f,s1);
        if (s1[0]=#0) then
        begin
          seek(f,w);
          delete(s,1,6);
          s2:=copy(s,1,length(s));
          write(f,s2);
        end else
        begin
          writeln; writeln;
          writeln('Error: Duplicate string');
          writeln('This error occurs when two strings in the language file have been assigned');
          writeln('the same index number.');
          close(t);
          close(f);
          halt;
        end;
      end else
      begin
        writeln; writeln;
        writeln('Error: Cannot determine string number');
        close(t);
        close(f);
        halt;
      end;
    end else
      write('Comment');
    clreol;
  end;
  close(t);
  close(f);
  writeln;
end;

procedure dump;
begin
  assign(f,systat.datapath+'STRINGS.DAT');
  {$I-} reset(f); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Cannot find '+systat.datapath+'STRINGS.DAT');
    halt;
  end;

  assign(t,paramstr(2));
  {$I-} reset(t); {$I+}
  if (ioresult=0) then
  begin
    writeln(allcaps(paramstr(2))+' already exists');
    halt;
  end;
  rewrite(t);
  writeln(t,'; Dumped by I_LANG version '+ver);
  writeln(t,';');

  write('Dumping contents of STRINGS.DAT into '+allcaps(paramstr(2))+'...');

  l:=0;
  while (not eof(f)) do
  begin
    read(f,s);
    writeln(t,cstrzero(l)+'   '+s);
    inc(l);
  end;

  writeln;

  close(f);
  close(t);
end;

procedure disphelp;
begin
  writeln('Syntax:  I_LANG <function> <language file>');
  writeln;
  writeln('Functions:');
  writeln;
  writeln('   Compile    Compiles the <language file> into Illusion''s STRINGS.DAT');
  writeln('   Dump       Dumps the contents of STRINGS.DAT into <language file>');
  halt;
end;

begin
  textmode(co80);

  textattr:=15; write('I_LANG');
  textattr:=8;  write(' - ');
  textattr:=15; writeln('Illusion Language File Utilities version '+ver);
  textattr:=7;  writeln('Copyright 1992-1998, Illusion Development.  All rights reserved.');
  textattr:=8;  writeln(line);
  textattr:=7;  writeln;

  if (paramcount<>2) then disphelp;

  assign(systatf,'ILLUSION.CFG');
  {$I-} reset(systatf); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Cannot find ILLUSION.CFG');
    halt;
  end;
  read(systatf,systat);
  close(systatf);

  s:=allcaps(paramstr(1));
  if (s='COMPILE') then compile else
  if (s='DUMP') then dump else disphelp;

end.
