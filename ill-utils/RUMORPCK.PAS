{$A+,B-,D-,E-,F+,G+,I+,L-,N-,O-,R-,S-,V-,X+}

program rumor_packer;

uses crt,dos;

{$I i_194.inc}

var
  systat:systatrec;
  systatf:file of systatrec;
  limit,i:word;
  rumor:rumorrec;
  rumorf,rumorf1:file of rumorrec;

function value(s:string):longint;
var i:longint;
    j:integer;
begin
  val(s,i,j);
  if (j<>0) then
  begin
    s:=copy(s,1,j-1);
    val(s,i,j)
  end;
  value:=i;
  if (s='') then value:=0;
end;

begin
  writeln('Rumor Packer version 1.00');
  writeln('For use with the Illusion Bulletin Board System v1.94b');
  writeln('Programmed by Billy Ma, Illusion Development');
  writeln;
  if (paramcount<>1) or (value(paramstr(1))<1) then
  begin
    writeln('Syntax: RUMORPCK <limit #>');
    writeln;
    writeln('  <limit #>  Specifies the number of rumors to pack to');
    halt;
  end else
    limit:=value(paramstr(1));
  write('Loading ILLUSION.CFG...');
  assign(systatf,'ILLUSION.CFG');
  {$I-} reset(systatf); {$I+};
  if (ioresult<>0) then
  begin
    writeln('Unable to open.');
    halt;
  end;
  read(systatf,systat);
  close(systatf);
  writeln('Done.');
  write('Loading RUMOR.DAT...');
  assign(rumorf,systat.datapath+'RUMOR.DAT');
  {$I-} reset(rumorf); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Unable to open.');
    halt;
  end else
  if (limit>filesize(rumorf)) then
  begin
    writeln('Limit requested exceeds file size.');
    halt;
  end else
    writeln('Done.');
  write('Packing to ',limit,' rumors...');
  assign(rumorf1,'RUMOR.$$$');
  rewrite(rumorf1);
  for i:=limit downto 1 do
  begin
    seek(rumorf,filesize(rumorf)-i);
    read(rumorf,rumor);
    write(rumorf1,rumor);
  end;
  close(rumorf1);
  close(rumorf);
  erase(rumorf);
  rename(rumorf1,systat.datapath+'RUMOR.DAT');
  writeln('Done.');
end.
