program b5_to_b6;

uses crt,dos;

{$I ..\main\rec25.pas}

type

  oldULFRec=                            { *.DIR : file records }
  record
    Filename         : String[12];      { filename }
    Description      : String[60];      { file description }
    FilePoints       : Integer;         { file points }
    NAcc             : Integer;         { number of downloads }
    Ft               : Byte;            { file type (useless?) }
    Blocks           : Integer;         { number of 128 byte blocks }
    Owner            : Integer;         { uploader of file }
    StOwner          : String[36];      { uploader's name }
    Date             : String[8];       { date uploaded }
    DateN            : Integer;         { numeric date uploaded }
    VPointer         : LongInt;         { pointer to verbose descr (-1 if none) }
    FileStat         : set of FilStat;  { file status }

    res1:Array[1..10] of Byte;          { reserved }
  end;

  newULFRec=                            { *.DIR : file records }
  record
    Filename         : String[12];      { filename }
    Description      : String[60];      { file description }
    FilePoints       : Integer;         { file points }
    NAcc             : Integer;         { number of downloads }
    Ft               : Byte;            { file type (useless?) }
    Blocks           : LongInt;         { number of 128 byte blocks }
    Owner            : Integer;         { uploader of file }
    StOwner          : String[36];      { uploader's name }
    Date             : String[8];       { date uploaded }
    DateN            : Integer;         { numeric date uploaded }
    VPointer         : LongInt;         { pointer to verbose descr (-1 if none) }
    FileStat         : set of FilStat;  { file status }

    res1:Array[1..10] of Byte;          { reserved }
  end;

  oldBBSListRec=                        { BBSLIST.DAT : BBS list }
  record
    Ph               : String[12];      { phone number }
    Name             : String[30];      { BBS name }
    BPS              : String[5];       { maximum BPS rate }
    MB               : String[5];       { megabytes online }
    Software         : String[10];      { BBS software }
    NUP              : String[15];      { new user password }
    Info             : String[30];      { extended info }
    BBSDate          : String[8];       { date added/modified last }

    res1:Array[1..50] of Byte;          { reserved }
  end;

  newBBSListRec=                        { BBSLIST.DAT : BBS list }
  record
    Ph               : String[20];      { phone number }
    Name             : String[30];      { BBS name }
    BPS              : String[6];       { maximum BPS rate }
    Software         : String[10];      { BBS software }
    Info             : String[50];      { extended info }
    BBSDate          : String[8];       { date added/modified last }

    res1:Array[1..50] of Byte;          { reserved }
  end;

var
  systat:systatrec;
  systatf:file of systatrec;
  s:searchrec;
  oldd:oldulfrec;
  newd:newulfrec;
  oldf:file of oldulfrec;
  newf:file of newulfrec;
  f:file;
  oldb:oldbbslistrec;
  newb:newbbslistrec;
  oldbf:file of oldbbslistrec;
  newbf:file of newbbslistrec;

function line:string;
var ss:string[79];
begin
  fillchar(ss[1],79,'Ä');
  ss[0]:=chr(79);
  line:=ss;
end;

begin
  textmode(co80);

  textattr:=15; write('B5TOB6');
  textattr:=8;  write(' - ');
  textattr:=15; writeln('Conversion Utility version 1.99á6');
  textattr:=7;  writeln('Copyright 1992-1997, Illusion Development.  All rights reserved.');
  textattr:=8;  writeln(line);
  textattr:=7;  writeln;

  assign(systatf,'ILLUSION.CFG');
  {$I-} reset(systatf); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Cannot find ILLUSION.CFG');
    halt;
  end;
  read(systatf,systat);
  close(systatf);

  findfirst(systat.datapath+'*.DIR',anyfile-directory-readonly-volumeid,s);
  while (doserror=0) do
  begin
    assign(f,systat.datapath+s.name);
    reset(f,1);
    if (filesize(f) mod sizeof(oldd)<>0) then
    begin
      writeln(s.name+' is not a valid pre-1.99á6 .DIR file, skipping...');
      close(f);
    end else
    begin
      close(f);
      assign(oldf,systat.datapath+s.name);
      reset(oldf);
      if (filesize(oldf)=0) then
        writeln(s.name+' contains no data...')
      else
      begin
        writeln('Processing '+s.name+'...');
        assign(newf,systat.datapath+'B5TOB6.$$$');
        rewrite(newf);
        while not (eof(oldf)) do
        begin
          read(oldf,oldd);
          with oldd do
          begin
            newd.filename:=filename;
            newd.description:=description;
            newd.filepoints:=filepoints;
            newd.nacc:=nacc;
            newd.ft:=ft;
            newd.blocks:=blocks;
            newd.owner:=owner;
            newd.stowner:=stowner;
            newd.date:=date;
            newd.daten:=daten;
            newd.vpointer:=vpointer;
            newd.filestat:=filestat;
            fillchar(newd.res1,sizeof(newd.res1),#0);
          end;
          write(newf,newd);
        end;
        close(newf);
        close(oldf);
        erase(oldf);
        rename(newf,systat.datapath+s.name);
      end;
    end;
    findnext(s);
  end;

  writeln;
  assign(f,systat.datapath+'BBSLIST.DAT');
  {$I-} reset(f,1); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Cannot find BBSLIST.DAT');
    halt;
  end;
  if (filesize(f) mod sizeof(oldbbslistrec)<>0) then
  begin
    writeln('BBSLIST.DAT is not a valid pre-1.99á6 file, skipping...');
    close(f);
  end else
  begin
    writeln('Processing BBSLIST.DAT...');
    assign(oldbf,systat.datapath+'BBSLIST.DAT');
    reset(oldbf);
    read(oldbf,oldb);
    close(oldbf);
    with oldb do
    begin
      newb.ph:=ph;
      newb.name:=name;
      newb.bps:=bps;
      newb.software:=software;
      newb.info:=info;
      newb.bbsdate:=bbsdate;
      fillchar(newb.res1,sizeof(newb.res1),#0);
    end;
    assign(newbf,systat.datapath+'B5TOB6.$$$');
    rewrite(newbf);
    write(newbf,newb);
    close(newbf);
    erase(oldbf);
    rename(newbf,systat.datapath+'BBSLIST.DAT');
  end;

end.
