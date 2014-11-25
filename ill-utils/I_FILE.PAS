{ illusion file base utils }
{ bm 02-02-97, 03-12-97 }

{$A+,B-,D-,E-,F+,G+,I+,L-,N-,O-,R-,S-,V-,X+}

program file_utils;

uses crt,dos;

{$I ..\main\rec25.pas}

var systat:systatrec;
    systatf:file of systatrec;
    fbf:file of ulrec;
    fb:ulrec;
    dirf:file of ulfrec;
    dir:ulfrec;
    s:string[20];
    i,j:word;

function cstr(i:longint):string;
var c:string[16];
begin
  str(i,c);
  cstr:=c;
end;

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

function tch(s:string):string;
begin
  if (length(s)>2) then
    s:=copy(s,length(s)-1,2)
  else
    if (length(s)=1) then s:='0'+s;
  tch:=s;
end;

function date:string;
var y,m,d:string[3];
    yy,mm,dd,dow:word;
begin
  getdate(yy,mm,dd,dow);
  str(yy-1900,y); str(mm,m); str(dd,d);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
end;

function isc(var c:char):boolean;
begin
  if (pos(c,'kbgcrmywKBGCRMYWA')<>0)
    then isc:=TRUE else isc:=FALSE;
end;

function stripcolor(o:string):string;
var s:string;
    i:integer;
    lc:boolean; lt:byte;
begin
  s:=''; lc:=FALSE; lt:=0;
  for i:=1 to length(o) do
    if (lc) then
      lc:=FALSE
    else
    if (lt>0) then
      dec(lt)
    else
    if (o[i]='|') then
    begin
      if (i<>length(o)) and (isc(o[i+1])) then
        lc:=TRUE
      else
      if (i<length(o)-1) and (o[i+1] in ['0'..'2']) and (o[i+2] in ['0'..'9']) then
        lt:=2
      else
        s:=s+o[i];
    end else
      s:=s+o[i];
  stripcolor:=s;
end;

function fileexist(fn:string):boolean;
var srec:searchrec;
begin
  findfirst(fn,anyfile,srec);
  fileexist:=(doserror=0);
end;

function allcaps(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do s[i]:=upcase(s[i]);
  allcaps:=s;
end;

function propercase(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do
    if (s[i] in ['A'..'Z']) then s[i]:=chr(ord(s[i])+32);
  for i:=1 to length(s) do
    if (s[i]=' ') and (s[i+1] in ['a'..'z']) then s[i+1]:=upcase(s[i+1]);
  s[1]:=upcase(s[1]);
  propercase:=s;
end;

procedure nofile(s:string);
begin
  writeln('Cannot find '+s);
  halt;
end;

procedure disphelp;
begin
  writeln('Syntax:  I_FILE Abandoned <new uploader>');
  writeln;
  writeln('   Replaces the uploader of abandoned files with <new uploader>');
  writeln;
  writeln('Syntax:  I_FILE FLColors');
  writeln;
  writeln('   Sets all users'' file list colors to match user #1''s');
  writeln;
  writeln('Syntax:  I_FILE Corrector');
  writeln;
  writeln('   Corrects the offline status, number of file points, and file sizes of file');
  writeln('   list entries in DIR files.');
  writeln;
  writeln('Syntax:  I_FILE VFilter');
  writeln;
  writeln('   Filters the verbose description data file, removing unused entries and');
  writeln('   repairing possible cross-linked descriptions.');
  halt;
end;

procedure verbosefilter;
var oldvf,newvf:file of verbrec;
    v:verbrec;
begin
  assign(oldvf,systat.datapath+'VERBOSE.DAT');
  {$I-} reset(oldvf); {$I+}
  if (ioresult<>0) then nofile('VERBOSE.DAT');
  assign(newvf,systat.datapath+'VERBOSE.$$$');
  rewrite(newvf);

  writeln('Filtering VERBOSE.DAT...');
  writeln;

  for i:=0 to filesize(fbf)-1 do
  begin
    seek(fbf,i);
    read(fbf,fb);
    writeln('Processing '+stripcolor(fb.name)+'...');
    assign(dirf,systat.datapath+fb.filename+'.DIR');
    {$I-} reset(dirf); {$I+}
    if (ioresult=0) and (filesize(dirf)>0) then
    begin
      for j:=0 to filesize(dirf)-1 do
      begin
        seek(dirf,j);
        read(dirf,dir);
        if (dir.vpointer>-1) then
        begin
          if (dir.vpointer<filesize(oldvf)) then
          begin
            seek(oldvf,dir.vpointer);
            read(oldvf,v);
            dir.vpointer:=filesize(newvf);
            seek(newvf,filesize(newvf));
            write(newvf,v);
          end else
            dir.vpointer:=-1;
          seek(dirf,j);
          write(dirf,dir);
        end;
      end;
      close(dirf);
    end;
  end;

  writeln;
  writeln('Change in file size: '+cstr(filesize(newvf)-filesize(oldvf)));

  close(oldvf);
  close(newvf);
  erase(oldvf);
  rename(newvf,systat.datapath+'VERBOSE.DAT');
end;

procedure abandoned;
var u:userrec;
    uf:file of userrec;
    count:word;
    bad:boolean;
begin
  if (paramcount<2) then
  begin
    writeln('Insufficient parameters');
    halt;
  end;

  s:='';
  for i:=2 to paramcount do s:=s+paramstr(i)+' ';
  s:=copy(s,1,length(s)-1);

  writeln('Replacing abandoned files'' uploader name with "'+s+'"...');
  writeln;

  assign(uf,systat.datapath+'USERS.DAT');
  {$I-} reset(uf); {$I+}
  if (ioresult<>0) then nofile('USERS.DAT');

  count:=0;

  for i:=0 to filesize(fbf)-1 do
  begin
    seek(fbf,i);
    read(fbf,fb);
    writeln('Processing '+stripcolor(fb.name)+'...');
    assign(dirf,systat.datapath+fb.filename+'.DIR');
    {$I-} reset(dirf); {$I+}
    if (ioresult=0) and (filesize(dirf)>0) then
    begin
      for j:=0 to filesize(dirf)-1 do
      begin
        seek(dirf,j);
        read(dirf,dir);
        if (dir.owner<filesize(uf)) then
        begin
          seek(uf,dir.owner);
          read(uf,u);
          bad:=(allcaps(u.name)<>allcaps(dir.stowner));
        end else
          bad:=true;
        if bad then
        begin
          inc(count);
          dir.owner:=0;
          dir.stowner:=propercase(s);
          seek(dirf,j);
          write(dirf,dir);
        end;
      end;
      close(dirf);
    end;
  end;

  close(uf);

  writeln;
  writeln(cstr(count)+' file(s) found abandoned.');
end;

procedure filelistcolors;
var uf:file of userrec;
    u1,u:userrec;
begin
  assign(uf,systat.datapath+'USERS.DAT');
  {$I-} reset(uf); {$I+}
  if (ioresult<>0) then nofile('USERS.DAT');

  writeln('Setting the file list colors of all accounts to user #1''s configuration...');
  writeln;

  if (filesize(uf)<=2) then
  begin
    writeln('There is only one user account!');
    halt;
  end;

  seek(uf,1);
  read(uf,u1);

  for i:=2 to filesize(uf)-1 do
  begin
    write(^M'Processing user #'+cstr(i)+'...');
    seek(uf,i);
    read(uf,u);
    u.flistc:=u1.flistc;
  end;

  close(uf);
  writeln;
end;

procedure filecorrector;
var actual:longint;
    offline,online,size,fp:word;
    f:file;
begin
  writeln('Correcting file entries in file transfer section...');
  writeln;

  offline:=0; online:=0; size:=0; fp:=0;

  for i:=0 to filesize(fbf)-1 do
  begin
    seek(fbf,i);
    read(fbf,fb);
    writeln('Processing '+stripcolor(fb.name)+'...');
    assign(dirf,systat.datapath+fb.filename+'.DIR');
    {$I-} reset(dirf); {$I+}
    if (ioresult=0) and (filesize(dirf)>0) then
    begin
      for j:=0 to filesize(dirf)-1 do
      begin
        seek(dirf,j);
        read(dirf,dir);
        if not (isrequest in dir.filestat) and (not fileexist(fb.dlpath+dir.filename)) then
        begin
          writeln('  '+dir.filename+' added offline.');
          include(dir.filestat,isrequest);
          inc(offline);
        end else
        if (isrequest in dir.filestat) and (fileexist(fb.dlpath+dir.filename)) then
        begin
          writeln('  '+dir.filename+' added online.');
          exclude(dir.filestat,isrequest);
          inc(online);
        end;
        if not (isrequest in dir.filestat) then
        begin
          assign(f,fb.dlpath+dir.filename);
          reset(f,1);
          actual:=trunc((filesize(f)+127.0)/128.0);
          if (actual<>dir.blocks) then
          begin
            writeln('  '+dir.filename+
                    ' - old: '+cstr(round(dir.blocks*128/1024))+'k'+
                    ' - new: '+cstr(round(actual*128/1024))+'k');
            dir.blocks:=actual;
            inc(size);
          end;
          close(f);
        end;
        if (fbnoratio in fb.fbstat) then
        begin
          if (dir.filepoints<>0) then
          begin
            dir.filepoints:=0;
            writeln('  '+dir.filename+'''s file points set to 0.');
            inc(fp);
          end;
        end else
        begin
          actual:=round((dir.blocks/8)/systat.fileptcompbasesize);
          if (actual<>dir.filepoints) then
          begin
            writeln('  '+dir.filename+'''s file points set to '+cstr(actual));
            dir.filepoints:=actual;
            inc(fp);
          end;
        end;
        seek(dirf,j);
        write(dirf,dir);
      end;
      close(dirf);
    end;
  end;

  writeln;
  writeln(cstr(offline)+' file(s) flagged offline.');
  writeln(cstr(online)+' file(s) flagged online.');
  writeln(cstr(size)+' file(s)'' sizes were corrected.');
  writeln(cstr(fp)+' file(s)'' file points were corrected.');
end;

function line:string;
var ss:string[79];
begin
  fillchar(ss[1],79,'Ä');
  ss[0]:=chr(79);
  line:=ss;
end;

begin

  textmode(co80);
  textattr:=15; write('I_FILE');
  textattr:=8;  write(' - ');
  textattr:=15; writeln('Illusion File Base Utilities version '+ver);
  textattr:=7;  writeln('Copyright 1992-1998, Illusion Development.  All rights reserved.');
  textattr:=8;  writeln(line);
  textattr:=7;  writeln;
  window(1,5,80,24);

  if (paramcount<1) then disphelp;

  assign(systatf,'ILLUSION.CFG');
  {$I-} reset(systatf); {$I+}
  if (ioresult<>0) then nofile('ILLUSION.CFG');
  read(systatf,systat);
  close(systatf);

  assign(fbf,systat.datapath+'FBOARDS.DAT');
  {$I-} reset(fbf); {$I+}
  if (ioresult<>0) then nofile('FBOARDS.DAT');

  s:=allcaps(paramstr(1));
  if (s='ABANDONED') then abandoned else
  if (s='FLCOLORS') then filelistcolors else
  if (s='CORRECTOR') then filecorrector else
  if (s='VFILTER') then verbosefilter else
  disphelp;

  close(fbf);

end.
