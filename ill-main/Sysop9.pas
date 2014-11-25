(*****************************************************************************)
(* Illusion BBS - SysOp routines  [9/11] (file base editor)                  *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop9;

interface

procedure dlboardedit;

implementation

uses
  crt, dos,
  common, 
  MsgF; { existdir2, ... }  
  

var zc:integer;

type zscanfuncr=procedure(var zscanr1:zscanrec; x,y:integer);

procedure dozscanfunc(zscanfunc:zscanfuncr; x,y:integer);
var zscanf:file;
    zscanr1:zscanrec;
    i:integer;
begin
  assign(zscanf,systat^.datapath+'NEWSCAN.DAT');
  SetFileAccess(ReadWrite,DenyNone);
  {$I-} reset(zscanf,sizeof(zscanrec)); {$I+}
  if (ioresult<>0) then
    rewrite(zscanf)
  else
  begin
    if (filesize(zscanf)=1) then exit;
    sprompt('|wProgress: |W0%  ');
    for i:=0 to filesize(zscanf)-1 do
    begin
      seek(zscanf,i); blockread(zscanf,zscanr1,1);
      if (usernum=i) then zscanr1:=zscanr;
      zscanfunc(zscanr1,x,y);
      seek(zscanf,i); blockwrite(zscanf,zscanr1,1);
      if (usernum=i) then zscanr:=zscanr1;
      prompt(^H^H^H^H+mln(cstr(100*i div (filesize(zscanf)-1))+'%',4));
    end;
    print(^H^H^H^H+'100%');
  end;
  close(zscanf);
end;

procedure fbase_del(var zscanr1:zscanrec; x,y:integer);
begin
  for zc:=x to maxulb-1 do
    if (zc+1 in zscanr1.fzscan) then include(zscanr1.fzscan,zc)
                                else exclude(zscanr1.fzscan,zc);
  include(zscanr1.fzscan,maxulb);
end;

procedure fbase_ins(var zscanr1:zscanrec; x,y:integer);
begin
  for zc:=numboards downto x+1 do
    if (zc-1 in zscanr1.fzscan) then include(zscanr1.fzscan,zc)
                                else exclude(zscanr1.fzscan,zc);
  include(zscanr1.fzscan,x);
end;

procedure fbase_pos(var zscanr1:zscanrec; x,y:integer);
var s_fzscan:boolean;
    i,j,k:integer;
begin
  s_fzscan:=(x in zscanr1.fzscan);
  i:=x; if (x>y) then j:=-1 else j:=1;
  while (i<>y) do
  begin
    if (i+j in zscanr1.fzscan) then include(zscanr1.fzscan,i)
                               else exclude(zscanr1.fzscan,i);
    inc(i,j);
  end;
  if (s_fzscan) then include(zscanr1.fzscan,y)
                else exclude(zscanr1.fzscan,y);
end;

procedure dlboardedit;
const ltype:integer=1;
var i1,ii,culb,i2:integer;
    c:char;
    s0:astr;
    f:file;
    hadpause,abort,next,done:boolean;

  function newindexno:longint;
  var ubrd:ulrec;
      i,j:integer;
  begin
    SetFileAccess(ReadWrite,DenyNone);
    reset(ulf);
    j:=-1;
    for i:=0 to filesize(ulf)-1 do
    begin
      read(ulf,ubrd);
      if (ubrd.permindx>j) then j:=ubrd.permindx;
    end;
    inc(j);
    newindexno:=j;
  end;

  procedure dlbed(x:integer);
  var i,j:integer;
  begin
    if ((x>=0) and (x<=maxulb)) then
    begin
      i:=x;
      if (i>=0) and (i<=filesize(ulf)-2) then
        for j:=i to filesize(ulf)-2 do
        begin
          seek(ulf,j+1); read(ulf,memuboard);
          seek(ulf,j); write(ulf,memuboard);
        end;
      seek(ulf,filesize(ulf)-1); truncate(ulf);
      dec(maxulb);
      dozscanfunc(fbase_del,x,0);
    end;
  end;

  procedure dlbei(x:integer);
  var s:string;
      i,j,k:integer;
  begin
    i:=x;
    if ((i>=0) and (i<=filesize(ulf)) and (maxulb<maxuboards)) then
    begin
      for j:=filesize(ulf)-1 downto i do
      begin
        seek(ulf,j); read(ulf,memuboard);
        write(ulf,memuboard);
      end;
      with memuboard do
      begin
        getdir(0,s);
        name:='[ Unnamed File Base ]';
        filename:='NEWBASE';
        dlpath:=s[1]+':\ILLUSION\DLS\';
        maxfiles:=2000;
        arctype:=1; cmttype:=1;
        fbstat:=[];
        acs:='';
        ulacs:='';
        nameacs:='';
        permindx:=newindexno;
        for k:=1 to 6 do res2[k]:=0;
        for k:=1 to 2 do res1[k]:=0;
      end;
      seek(ulf,i); write(ulf,memuboard);
      inc(maxulb);
      dozscanfunc(fbase_ins,x,0);
    end;
  end;

  procedure dlbep(x,y:integer);
  var tempuboard:ulrec;
      i,j:integer;
  begin
    if (y>x) then dec(y);
    seek(ulf,x); read(ulf,tempuboard);
    i:=x;
    if (x>y) then j:=-1 else j:=1;
    while (i<>y) do
    begin
      if (i+j<filesize(ulf)) then
      begin
        seek(ulf,i+j); read(ulf,memuboard);
        seek(ulf,i); write(ulf,memuboard);
      end;
      inc(i,j);
    end;
    seek(ulf,y); write(ulf,tempuboard);
    dozscanfunc(fbase_pos,x,y);
  end;

  function flagstate(fb:ulrec):astr;
  var s:astr;
  begin
    s:='';
    with fb do
    begin
      if (fbusegifspecs in fbstat) then s:=s+'G' else s:=s+'-';
      if (fbdirdlpath in fbstat) then s:=s+'D' else s:=s+'-';
      if (fbnoratio in fbstat) then s:=s+'N' else s:=s+'-';
      if (fbunhidden in fbstat) then s:=s+'V' else s:=s+'-';
    end;
    flagstate:=s;
  end;

  procedure dlbem;
  var xloaded,i,ii:integer;
      c,d:char;
      s:astr;
      b:boolean;
      bb:byte;
  begin
    c:=#0;
    xloaded:=-1;
    sprompt('|wEdit file base |K[|W0|w-|W'+cstr(filesize(ulf)-1)+'|K] |W');
    inu(ii);
    if (ii>=0) and (ii<=maxulb) and (not badini) then
    begin
      exclude(thisuser.ac,pause);
      while (c<>'Q') and (not hangup) do
      begin
        if (xloaded<>ii) then
        begin
          seek(ulf,ii);
          read(ulf,memuboard);
          xloaded:=ii;
        end;
        with memuboard do
          repeat
            if (c in [#0,^M,'[',']']) then
            begin
              if (c in [#0,^M]) then cls;
              ansig(1,1);
              sprint('|WFile Base ['+cstr(ii)+'/'+cstr(maxulb)+']|LC');
              nl;
              sprint('|K[|CA|K] |cBase name         |w'+mln(name,40));
              sprint('|K[|CB|K] |cFilename          |w'+mlnnomci(filename,8));
              sprint('|K[|CC|K] |cFiles path        |w'+mlnnomci(dlpath,40));
              sprint('|K[|CD|K] |cRequired access   |w'+mlnnomci(acs,20));
              sprint('|K[|CE|K] |cUpload access     |w'+mlnnomci(ulacs,20));
              sprint('|K[|CF|K] |cSee ULer''s name   |w'+mlnnomci(nameacs,20));
              sprint('|K[|CG|K] |cMaximum files     |w'+mn(maxfiles,4));
              sprint('|K[|CH|K] |cArchive type      |w'+
                     aonoff(arctype=0,'None',systat^.filearcinfo[arctype].ext)+'|LC');
              sprint('|K[|CI|K] |cComment type      |w'+aonoff(cmttype=0,'None',cstr(cmttype))+'|LC');
              sprint('|K[|CJ|K] |cUse GIF specs     |w'+syn(fbusegifspecs in fbstat)+' ');
              sprint('|K[|CK|K] |cDIR in file path  |w'+syn(fbdirdlpath in fbstat)+' ');
              sprint('|K[|CL|K] |cNo ratios         |w'+syn(fbnoratio in fbstat)+' ');
              sprint('|K[|CM|K] |cVisible to all    |w'+syn(fbunhidden in fbstat)+' ');
              sprint('    |cPermanent index   |w'+cstrl(permindx)+'|LC');
              nl;
              sprompt('|wCommand |K[|C[|K/|C]|K/|CQ|c:uit|K] |W');
            end;
            ansig(21,18);
            sprompt(#32+^H+'|W');
            onek(c,'QABCDEFGHIJKLM[]'^M);
            case c of
              'A':begin
                    ansig(23,3);
                    inputed(name,40,'O');
                  end;
              'B':begin
                    inputxy(23,4,filename,-8);
                    if (pos('.',filename)>0) then filename:=copy(s,1,pos('.',s)-1);
                    sprompt('|w|I2304'+mlnnomci(filename,8));
                  end;
              'C':begin
                    s:=dlpath;
                    inputxy(23,5,s,-40);
                    s:=sqoutsp(s);
                    sprompt('|w|I2305'+s);
                    if (s<>'') then
                    begin
                      while (copy(s,length(s)-1,2)='\\') do s:=copy(s,1,length(s)-1);
                      if (copy(s,length(s),1)<>'\') then s:=s+'\';
                      dlpath:=s;
                      if (not existdir2(s)) then
                      begin
                        sprompt(' - Create?');
                        onek(d,'YN'^M);
                        if (d='Y') then
                        begin
                          {$I-} mkdir(bslash(FALSE,s)); {$I+}
                        end;
                      end;
                    end;
                    sprompt('|w|I2305'+mlnnomci(dlpath,55));
                  end;
              'D':inputxy(23,6,acs,20);
              'E':inputxy(23,7,ulacs,20);
              'F':inputxy(23,8,nameacs,20);
              'G':maxfiles:=inputnumxy(23,9,maxfiles,4,0,2000);
              'H':begin
                    sprompt('|w|I2610 (0 for none)');
                    if (arctype=0) then s:='0' else s:=systat^.filearcinfo[arctype].ext;
                    inputxy(23,10,s,3);
                    if (s<>'') then
                    begin
                      bb:=arctype;
                      if (value(s) in [1..maxarcs]) then
                        bb:=value(s)
                      else
                        for i:=1 to maxarcs do
                          if s=systat^.filearcinfo[i].ext then bb:=i;
                      if (value(s)=0) and (copy(s,1,1)='0') then bb:=0;
                      arctype:=bb;
                    end;
                    sprompt('|w|I2310'+aonoff(arctype=0,'None',systat^.filearcinfo[arctype].ext)+'|LC');
                  end;
              'I':begin
                    sprompt('|w|I2411 (0 to disable)');
                    cmttype:=inputnumxy(23,11,cmttype,1,0,3);
                    sprompt('|w|I2311'+aonoff(cmttype=0,'None',cstr(cmttype))+'|LC');
                  end;
              'J':begin
                    b:=fbusegifspecs in fbstat;
                    if (b) then exclude(fbstat,fbusegifspecs)
                           else include(fbstat,fbusegifspecs);
                    switchyn(23,12,b);
                  end;
              'K':begin
                    b:=fbdirdlpath in fbstat;
                    if (b) then exclude(fbstat,fbdirdlpath)
                           else include(fbstat,fbdirdlpath);
                    switchyn(23,13,b);
                  end;
              'L':begin
                    b:=fbnoratio in fbstat;
                    if (b) then exclude(fbstat,fbnoratio)
                           else include(fbstat,fbnoratio);
                    switchyn(23,14,b);
                  end;
              'M':begin
                    b:=fbunhidden in fbstat;
                    if (b) then exclude(fbstat,fbunhidden)
                           else include(fbstat,fbunhidden);
                    switchyn(23,15,b);
                  end;
              '[':if (ii>0) then dec(ii) else ii:=maxulb;
              ']':if (ii<maxulb) then inc(ii) else ii:=0;
            end;
          until (pos(c,'Q[]')<>0) or (hangup);
        seek(ulf,xloaded);
        write(ulf,memuboard);
      end;
      if hadpause then include(thisuser.ac,pause);
    end;
  end;

  procedure dlbepi;
  var i,j:integer;
  begin
    sprompt('|wMove file base |K[|C0|c-|C'+cstr(maxulb)+'|K] |W');
    inu(i);
    if ((not badini) and (i>=0) and (i<=maxulb)) then
    begin
      sprompt('|wMove before |K[|C0|c-|C'+cstr(maxulb+1)+'|K] |W');
      inu(j);
      if ((not badini) and (j>=0) and (j<=maxulb+1) and (j<>i) and (j<>i+1)) then
      begin
        nl;
        dlbep(i,j);
      end;
    end;
  end;

begin
  c:=#0;
  hadpause:=pause in thisuser.ac;
  SetFileAccess(ReadWrite,DenyNone);
  reset(ulf);
  repeat
    abort:=false; next:=false;
    cls;
    case ltype of
      1:sprint('|w#   File base name                  Flags ACS        UL ACS     Name ACS   Max');
      2:sprint('|w#   File base name            Filename Download path');
      3:sprint('|w#   File base name                       Arc Comment  P-Index');
    end;
    sprint('|K|LI');
    ii:=0;
    while (ii<=maxulb) and (not abort) and (not hangup) do
    begin
      seek(ulf,ii); read(ulf,memuboard);
      with memuboard do
        case ltype of
          1:sprint('|W'+mn(ii,3)+' |w'+mln(name,31)+' |w'+flagstate(memuboard)+
                   '  '+mln(acs,10)+' '+mln(ulacs,10)+' '+mln(nameacs,10)+' '+mn(maxfiles,4));
          2:sprint('|W'+mn(ii,3)+' |w'+mln(name,25)+' |w'+mln(filename,8)+' '+
                   mln(dlpath,40));
          3:sprint('|W'+mn(ii,3)+' |w'+mln(name,36)+' |w'+mn(arctype,3)+' '+
                   mn(cmttype,3)+'      '+mn(permindx,7));
        end;
      wkey(abort,next);
      inc(ii);
      readuboard:=-1; loaduboard(0);
    end;
    sprint('|K|LI');
    sprompt('|wFile Base Editor |K[|CD|c:elete|K/|CI|c:nsert|K/|CE|c:dit|K/|CM|c:ove|K/|CT|c:oggle|K/|CQ|c:uit|K] |W');
    onek(c,'QDIEMT'^M);
    case c of
      'D':begin
            sprompt('|wDelete file base |K[|C0|c-|C'+cstr(maxulb)+'|K] |W');
            inu(ii);
            if ((ii>=0) and (ii<=maxulb) and (not badini)) then
            begin
              readuboard:=-1; loaduboard(ii);
              if (fbdirdlpath in memuboard.fbstat) then
                s0:=memuboard.dlpath
              else
                s0:=systat^.datapath;
              s0:=s0+memuboard.filename+'.DIR';
              sysoplog('* Deleted file base: '+memuboard.name);
              dlbed(ii);
              if pynq('Delete directory file') then
              begin
                {$I-}
                assign(f,s0);
                SetFileAccess(ReadOnly,DenyNone);
                reset(f);
                close(f);
                {$I+}
                if (ioresult=0) then erase(f);
              end;
            end;
          end;
      'I':begin
            sprompt('|wInsert before |K[|C0|c-|C'+cstr(maxulb+1)+'|K] |W');
            inu(ii);
            if ((ii>=0) and (ii<=maxulb+1) and (not badini)) then
            begin
              sysoplog('* Inserted new file base');
              dlbei(ii);
            end;
          end;
      'E':dlbem;
      'M':dlbepi;
      'T':ltype:=ltype mod 3+1;   { toggle between 1, 2 & 3 }
    end;
  until (c='Q') or (hangup);
  close(ulf);
  if (systat^.compressfilebases) and (useron) then newcomptables;
  if ((fileboard<0) or (fileboard>maxulb)) then fileboard:=1;
  readuboard:=-1; loaduboard(fileboard);
  if (hadpause) then include(thisuser.ac,pause);
end;

end.
