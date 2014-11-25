{$A+,B-,D-,E-,F+,G+,I+,L-,N-,O-,R-,S-,V-,X+}

program voting_data_recounter;

uses crt,dos;

{$I ..\main\rec25.pas}

var u,v,x:integer;

    systat:systatrec;
    systatf:file of systatrec;

    user:userrec;
    userf:file of userrec;

    vote:vdatar;
    votef:file of vdatar;

procedure nofile(s:string);
begin
  writeln('Cannot find '+s);
  halt;
end;

function line:string;
var s:string[79];
begin
  fillchar(s,sizeof(s),'Ä');
  s[0]:=chr(79);
  line:=s;
end;

begin

  textmode(co80);
  textattr:=15; write('I_VOTE');
  textattr:=8;  write(' - ');
  textattr:=15; writeln('Illusion Voting Data Recounter version '+ver);
  textattr:=7;  writeln('Copyright 1992-1998, Illusion Development.  All rights reserved.');
  textattr:=8;  writeln(line);
  textattr:=7;  writeln;
  window(1,5,80,25);

  assign(systatf,'ILLUSION.CFG');
  {$I-} reset(systatf); {$I+}
  if (ioresult<>0) then nofile('ILLUSION.CFG');
  read(systatf,systat);
  close(systatf);

  assign(userf,systat.datapath+'USERS.DAT');
  {$I-} reset(userf); {$I+}
  if (ioresult<>0) then nofile('USERS.DAT');

  assign(votef,systat.datapath+'VOTING.DAT');
  {$I-} reset(votef); {$I+}
  if (ioresult<>0) then nofile('VOTING.DAT');

  write('Resetting votes...');
  for v:=0 to filesize(votef)-1 do
  begin
    seek(votef,v);
    read(votef,vote);
    for x:=0 to vote.numchoices-1 do vote.choices[x].numvoted:=0;
    vote.numvoted:=0;
    seek(votef,v);
    write(votef,vote);
  end;

  for u:=1 to filesize(userf)-1 do
  begin
    seek(userf,u);
    read(userf,user);
    gotoxy(1,1);
    write('User #',u,', ');
    if (not user.deleted) then
    begin
      x:=wherex;
      for v:=0 to filesize(votef)-1 do
      begin
        gotoxy(x,1);
        write('Question #',(v+1)); clreol;
        seek(votef,v);
        read(votef,vote);
        if (user.vote[v+1]>0) then
        begin
          inc(vote.choices[(user.vote[v+1])-1].numvoted);
          inc(vote.numvoted);
        end;
        seek(votef,v);
        write(votef,vote);
      end;
    end else
    begin
      write('Deleted'); clreol;
    end;
  end;

  close(votef);
  close(userf);
  writeln;
end.
