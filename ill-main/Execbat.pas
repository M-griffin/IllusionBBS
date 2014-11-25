(*****************************************************************************)
(* Illusion BBS - Batch file execution                                       *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit execbat;

interface

uses
  crt, dos,
  common,
  myio;

var
  wind:windowrec;
  sx,sy:integer;
  wascls,savtw:boolean;
  savcurwind:integer;

procedure execbatch(var ok:boolean; showit:boolean;
                    bfn,tfn,dir,batline:astr; oklevel:integer);
procedure pexecbatch(showit:boolean; bfn,tfn,dir,batline:astr;
                     var retlevel:integer);
procedure shel(s:astr);
procedure shel1;
procedure shel2;

implementation

procedure execbatch(var ok:boolean;     { result                     }
                    showit:boolean;     { show working on user side  }
                    bfn:astr;           { .BAT filename              }
                    tfn:astr;           { UNUSED -----------------   }
                    dir:astr;           { directory takes place in   }
                    batline:astr;       { .BAT file line to execute  }
                    oklevel:integer);   { DOS errorlevel for success }
var bfp:text;
    odir,todev:astr;
    i,rcode:integer;
begin
  todev:=' >nul';
  if ((showit) and (incom)) then
    todev:=' >'+systat^.remdevice+' <'+systat^.remdevice
  else
    if (wantout) then todev:=''; {' >con';}

  getdir(0,odir);
  dir:=fexpand(dir);
  while copy(dir,length(dir),1)='\' do dir:=copy(dir,1,length(dir)-1);
  assign(bfp,bfn);
  rewrite(bfp);
  writeln(bfp,'@echo off');
  writeln(bfp,chr(exdrv(dir)+64)+':');
  writeln(bfp,'cd '+dir);
  writeln(bfp,batline+todev);
  writeln(bfp,':done');
  writeln(bfp,chr(exdrv(odir)+64)+':');
  writeln(bfp,'cd '+odir);
  writeln(bfp,'exit');
  close(bfp);

  if (wantout) then begin
    tc(15); textbackground(1); clreol; write(batline); clreol;
    tc(7); textbackground(0); writeln;
  end;
{  if (todev=' >con') then todev:='' else todev:=' >nul';}

  shelldos(FALSE,bfn+todev,rcode);

  chdir(odir);
  {$I-} erase(bfp); {$I+}
  if (oklevel<>-1) then ok:=(rcode=oklevel) else ok:=TRUE;
end;

procedure pexecbatch(showit:boolean;     { show working on user side  }
                     bfn:astr;           { .BAT filename              }
                     tfn:astr;           { UNUSED -----------         }
                     dir:astr;           { directory takes place in   }
                     batline:astr;       { .BAT file line to execute  }
                 var retlevel:integer);  { DOS errorlevel returned    }
var tfp,bfp:text;
    odir,todev:astr;
    okblah:boolean;
begin

  todev:=' >nul';
  if (showit) and (incom) then
    todev:=' >'+systat^.remdevice+' <'+systat^.remdevice
  else
    if (wantout) then todev:=' >con';

  getdir(0,odir);
  dir:=fexpand(dir);
  while copy(dir,length(dir),1)='\' do dir:=copy(dir,1,length(dir)-1);
  assign(bfp,bfn);
  rewrite(bfp);
  writeln(bfp,'@echo off');
  writeln(bfp,chr(exdrv(dir)+64)+':');
  writeln(bfp,'cd '+dir);
  writeln(bfp,batline+todev);
  writeln(bfp,':done');
  writeln(bfp,chr(exdrv(odir)+64)+':');
  writeln(bfp,'cd '+odir);
  writeln(bfp,'exit');
  close(bfp);

  if (wantout) then begin
    tc(15); textbackground(1); clreol; write(batline); clreol;
    tc(7); textbackground(0); writeln;
  end;
  if (todev=' >con') then todev:='' else todev:=' >nul';

  shelldos(FALSE,bfn+todev,retlevel);

  chdir(odir);
  {$I-} erase(bfp); {$I+}
end;

procedure shel(s:astr);
begin
  wascls:=FALSE;
  savcurwind:=curwindow;
  if (s<>'') then begin
    wascls:=TRUE;
    sx:=wherex; sy:=wherey;
    setwindow(wind,1,1,80,linemode,7,0,0);
    clrscr;
    textbackground(1); tc(15); clreol;
    write(s);
    textbackground(0); tc(7); writeln;
  end else
    if (savcurwind<>0) then sclearwindow;
{      if (not systat.istopwindow) then sclearwindow;}
end;

procedure shel1;
begin
  shel('');
end;

procedure shel2;
begin
  if (wascls) then begin
    clrscr;
    removewindow(wind);
    gotoxy(sx,sy);
    topscr;
  end else
    if (savcurwind<>0) then schangewindow(TRUE,savcurwind);
end;

end.
