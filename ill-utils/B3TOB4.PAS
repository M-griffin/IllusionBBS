{$A+,B-,D-,E-,F+,G+,I+,L-,N-,O-,R-,S-,V-,X+}

program b3_to_b4_DIR_convertor;

uses crt,dos;

{$I ..\main\rec25.pas}

var u:ulfrec;
    uf:file of ulfrec;
    s:searchrec;
    i:byte;
    c:char;

function line:string;
var ss:string[79];
begin
  fillchar(ss[1],79,'Ä');
  ss[0]:=chr(79);
  line:=ss;
end;

begin
  textmode(co80);

  textattr:=15; write('B3TOB4');
  textattr:=8;  write(' - ');
  textattr:=15; writeln('*.DIR Conversion Utility version 1.99á4');
  textattr:=7;  writeln('Copyright 1992-1997, Illusion Development.  All rights reserved.');
  textattr:=8;  writeln(line);
  textattr:=7;  writeln;

  writeln('This conversion utility will convert old *.DIR files to the new format used by');
  writeln('version 1.99 beta 4 and later.  If you have already run this utility, do NOT');
  writeln('run it again.  Processing .DIR files used by 1.99á4 and later will result in');
  writeln('the loss of data.');
  writeln;
  write('Do you wish to continue? [Y/N] ');
  repeat
    c:=upcase(readkey);
  until (c in ['Y','N',#27,^M]);
  if (c<>'Y') then
  begin
    writeln('No');
    halt;
  end;
  writeln('Yes');
  writeln;

  findfirst('*.dir',anyfile-directory-volumeid,s);
  if (doserror<>0) then
  begin
    writeln('Cannot find any .DIR files');
    writeln('Make sure this program is executed from the DATA directory');
    halt;
  end;
  write('Processing .DIR files...');
  while (doserror=0) do
  begin
    assign(uf,s.name);
    reset(uf);
    if (filesize(uf)>0) then
    begin
      seek(uf,0); read(uf,u);
      seek(uf,u.blocks+1); truncate(uf);
      for i:=1 to filesize(uf)-1 do
      begin
        seek(uf,i); read(uf,u);
        seek(uf,i-1); write(uf,u);
      end;
    end;
    close(uf);
    findnext(s);
  end;
  writeln(' Done.');
end.
