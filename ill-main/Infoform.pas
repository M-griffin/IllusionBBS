(*****************************************************************************)
(* Illusion BBS - InfoForm questionaire system                               *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit infoform;

interface

uses
  crt, dos,
  doors, common;

procedure finduserws(var usernum:integer);
procedure readq(filen:astr; infolevel:integer);
procedure readasw(usern:integer; fn:astr);
procedure readasw1(fn:astr);

implementation

procedure finduserws(var usernum:integer);
var user:userrec;
    sr:smalrec;
    nn,duh:astr;
    t,i,i1,gg:integer;
    c:char;
    sfo,ufo,done,asked:boolean;
begin
  ufo:=(filerec(uf).mode<>fmclosed);
  if (not ufo) then begin
    SetFileAccess(ReadOnly,DenyNone);
    reset(uf);
  end;
  input(nn,36);
  usernum:=value(nn);
  if (nn='SYSOP') then nn:='1';
  if (usernum>0) then begin
    if (usernum>filesize(uf)-1) then begin
      print('Unknown User.');
      usernum:=0;
    end else begin
      seek(uf,usernum);
      read(uf,user);
    end;
  end else
    if (nn<>'') then begin
      sfo:=(filerec(sf).mode<>fmclosed);
      if (not sfo) then begin
        SetFileAccess(ReadOnly,DenyNone);
        reset(sf);
      end;
      done:=FALSE; asked:=FALSE;
      gg:=0;
      while ((gg<filesize(sf)-1) and (not done)) do begin
        inc(gg);
        seek(sf,gg); read(sf,sr);
        if (pos(nn,sr.name)<>0) then
          if (sr.name=nn) then
            usernum:=sr.number
          else begin
            if (not asked) then begin nl; asked:=TRUE; end;
            sprint('|wIncomplete match |C--> |W'+caps(sr.name)+' #'+
                   cstr(sr.number));
            sprompt('|WIs this correct |B[|CY|B/|CN|B,|CQ|B=|CQuit|B] : |C');
            onek(c,'QYN'^M);
            done:=TRUE;
            case c of
              'Q':usernum:=0;
              'Y':usernum:=sr.number;
            else
                  done:=FALSE;
            end;
          end;
      end;
      if (usernum=0) then print('User not found.');
      if (not sfo) then close(sf);
    end;
  if (not ufo) then close(uf);
end;

procedure readq(filen:astr; infolevel:integer);
const level0name:string='';
var infile,outfile,outfile1:text;
    outp,lin,s,mult,got,lastinp,ps,ns,es,infilename,outfilename:astr;
    i,x,y:integer;
    abort,next,plin:boolean;
    c:char;

  procedure gotolabel(got:astr);
  var s:astr;
  begin
    got:=':'+allcaps(got);
    reset(infile);
    repeat
      readln(infile,s);
    until (eof(infile)) or (allcaps(s)=got);
  end;

  procedure dumptofile;
  begin
      { output answers to *.ASW file, and delete temporary file }
    reset(outfile1);
    {$I-} append(outfile); {$I+}
    if (ioresult<>0) then rewrite(outfile);

    while (not eof(outfile1)) do begin
      readln(outfile1,s);
      writeln(outfile,s);
    end;
    close(outfile1); close(outfile);
    erase(outfile1);
  end;

begin
  infilename:=filen;
  if (not exist(infilename)) then begin
    fsplit(infilename,ps,ns,es);
    infilename:=ps+ns+'.INF';
    if (not exist(infilename)) then begin
      infilename:=systat^.textpath+ns+'.INF';
      if (not exist(infilename)) then begin
        sysoplog('** InfoForm not found: "'+filen);
        print('** InfoForm not found: "'+filen);
        exit;
      end;
    end;
  end;

  assign(infile,infilename);
  {$I-} reset(infile); {$I+}
  if (ioresult<>0) then begin
    sysoplog('** InfoForm not found: "'+filen+'"');
    print('** InfoForm not found: "'+filen+'"');
    exit;
  end;

  fsplit(infilename,ps,ns,es);
  outfilename:=systat^.textpath+ns+'.ASW';

  assign(outfile1,systat^.textpath+'TEMP$'+cstr(infolevel)+'.ASW');
  if (infolevel=0) then begin
    level0name:=outfilename;
    assign(outfile,outfilename);
    sysoplog('** Answered InfoForm "'+filen+'"');
    rewrite(outfile1);
    writeln(outfile1,'User: '+nam);
    writeln(outfile1,'Date: '+dat);
    writeln(outfile1);
  end else begin
    sysoplog('**>> Answered InfoForm "'+filen+'"');
    rewrite(outfile1);
    assign(outfile,level0name);
  end;

  nl;

  repeat
    abort:=FALSE;
    readln(infile,outp);
    if (pos('*',outp)<>0) and (copy(outp,1,1)<>';') then outp:=';A'+outp;
    if (length(outp)=0) then nl else
      case outp[1] of
        ';':begin
              if (pos('*',outp)<>0) then
                if (outp[2]<>'D') then outp:=copy(outp,1,pos('*',outp)-1);
              lin:=copy(outp,3,length(outp)-2);
              i:=80-length(lin);
              s:=copy(outp,1,2);
              if (s[1]=';') then
                case s[2] of
                  'C','D','G','I','K','L','Q','T','V',';':i:=1; { do nothing }
                else
                      sprompt(lin);
                end;
              s:=#1#1#1;
              case outp[2] of
                'A':inputl(s,i);
                'B':input(s,i);
                'C':begin
                      mult:=''; i:=1;
                      s:=copy(outp,pos('"',outp),length(outp)-pos('"',outp));
                      repeat
                        mult:=mult+s[i];
                        inc(i);
                      until (s[i]='"') or (i>length(s));
                      lin:=copy(outp,i+3,length(s)-(i-1));
                      sprompt(lin);
                      onek(c,mult);
                      s:=c;
                    end;
                'D':begin
                      dodoorfunc(outp[3],copy(outp,4,length(outp)-3));
                      s:=#0#0#0;
                    end;
                'G':begin
                      got:=copy(outp,3,length(outp)-2);
                      gotolabel(got);
                      s:=#0#0#0;
                    end;
                'H':hangup:=TRUE;
                'I':begin
                      mult:=copy(outp,3,length(outp)-2);
                      i:=pos(',',mult);
                      if i<>0 then begin
                        got:=copy(mult,i+1,length(mult)-i);
                        mult:=copy(mult,1,i-1);
                        if allcaps(lastinp)=allcaps(mult) then
                          gotolabel(got);
                      end;
                      s:=#0#0#0;
                    end;
                'K':begin
                      close(infile);
                      close(outfile1); erase(outfile1);
                      if (infolevel<>0) then begin
                        {$I-} append(outfile); {$I+}
                        if (ioresult<>0) then rewrite(outfile);
                        writeln(outfile,'** Aborted InfoForm: "'+filen+'"');
                        close(outfile);
                      end;
                      sysoplog('** Aborted InfoForm.  Answers not saved.');
                      exit;
                    end;
                'L':begin
                      writeln(outfile1,copy(outp,3,length(outp)-2));
                      s:=#0#0#0;
                    end;
                'Q':begin
                      close(outfile1);
                      dumptofile;
                      readq(copy(outp,3,length(outp)-2),infolevel+1);
                      rewrite(outfile1);
                      s:=#0#0#0;
                    end;
                'T':begin
                      s:=copy(outp,3,length(outp)-2);
                      printf(s);
                      s:=#0#0#0;
                    end;
                'V':begin
                      s:=copy(outp,3,1); c:=s[1];
                      if c in ['A'..'Z'] then begin
                        autovalidate(c,thisuser,usernum);
                        commandline('User validated with profile '+c+'.');
                      end;
                      s:=#0#0#0;
                    end;
                'Y':if yn then s:='YES' else s:='NO';
                ';':s:=#0#0#0;
              end;
              if (s<>#1#1#1) then begin
                outp:=lin+s;
                lastinp:=s;
              end;
              if (s=#0#0#0) then outp:=#0#0#0;
            end;
        ':':outp:=#0#0#0;
      else
            printacr(outp,abort,next);
      end;
    if (outp<>#0#0#0) then begin
      writeln(outfile1,outp);
    end;
  until ((eof(infile)) or (hangup));
  if (hangup) then begin
    writeln(outfile1);
    writeln(outfile1,'** HUNG UP **');
  end;

  close(outfile1);
  dumptofile;
  close(infile);
end;

procedure readasw(usern:integer; fn:astr);
var qf:text;
    user:userrec;
    qs,ps,ns,es:astr;
    i,userntimes:integer;
    abort,next,userfound,usernfound,ufo:boolean;

  procedure exactmatch;
  begin
    reset(qf);
    repeat
      readln(qf,qs);
      if (copy(qs,1,6)='User: ') then begin
        i:=value(copy(qs,pos('#',qs)+1,length(qs)-pos('#',qs)));
        if (i=usern) then begin
          inc(userntimes); usernfound:=TRUE;
          if (allcaps(qs)=allcaps('User: '+user.name+' #'+cstr(usern))) then
            userfound:=TRUE;
        end;
      end;
      if (not empty) then wkey(abort,next);
    until (eof(qf)) or (userfound) or (abort);
  end;

  procedure usernmatch;
  begin
    sprompt('|RNo exact user name matches; user number was found ');
    if (userntimes=1) then sprompt('once')
      else sprompt(cstr(userntimes)+' times');
    sprint('.');
    nl;

    reset(qf);
    repeat
      readln(qf,qs);
      if (copy(qs,1,6)='User: ') then begin
        i:=value(copy(qs,pos('#',qs)+1,length(qs)-pos('#',qs)));
        if (i=usern) then
          if (userntimes=1) then userfound:=TRUE
          else begin
            sprompt('|BUser: |C'+copy(qs,7,length(qs)-6));
            userfound:=pynq('  -- Is this right');
          end;
      end;
      if (not empty) then wkey(abort,next);
    until (eof(qf)) or (userfound) or (abort);
    nl;
  end;

begin
  ufo:=(filerec(uf).mode<>fmclosed);
  if (not ufo) then begin
    SetFileAccess(ReadOnly,DenyNone);
    reset(uf);
  end;
  if ((usern>=1) and (usern<=filesize(uf)-1)) then begin
    seek(uf,usern); read(uf,user);
  end else begin
    print('Invalid user number: '+cstr(usern));
    exit;
  end;
  if (not ufo) then close(uf);

  nl;
  abort:=FALSE; next:=FALSE;
  fn:=allcaps(fn);
  fsplit(fn,ps,ns,es);
  fn:=allcaps(systat^.textpath+ns+'.ASW');
  if (not exist(fn)) then begin
    fn:=allcaps(systat^.datapath+ns+'.ASW');
    if (not exist(fn)) then begin
      print('InfoForm answer file not found: "'+fn+'"');
      exit;
    end;
  end;
  assign(qf,fn);
  {$I-} reset(qf); {$I+}
  if (ioresult<>0) then print('"'+fn+'": unable to open.')
  else begin
    userfound:=FALSE; usernfound:=FALSE; userntimes:=0;
    exactmatch;
    if (not userfound) and (usernfound) and (not abort) then usernmatch;

    if (not userfound) and (not abort) then
      print('Questionairre answers not found.')
    else begin
      sprint(qs);
      repeat
        readln(qf,qs);
        if (copy(qs,1,6)<>'User: ') then printacr(qs,abort,next)
          else userfound:=FALSE;
      until eof(qf) or (not userfound) or (abort);
    end;
    close(qf);
  end;
end;

procedure readasw1(fn:astr);
var ps,ns,es:astr;
    usern:integer;
begin
  nl;
  print('Read InfoForm answers -');
  nl;
  if (fn='') then begin
    sprint('Enter filename:');
    pchar; mpl(8); input(fn,8);
    nl;
    if (fn='') then exit;
  end;
  fsplit(fn,ps,ns,es);
  fn:=allcaps(systat^.datapath+ns+'.ASW');
  if (not exist(fn)) then begin
    fn:=allcaps(systat^.textpath+ns+'.ASW');
    if (not exist(fn)) then begin
      print('InfoForm answer file not found: "'+fn+'"');
      exit;
    end;
  end;
  print('Enter user number, user name, or partial search string:');
  prt(':'); finduserws(usern);
  if (usern<>0) then
    readasw(usern,fn)
  else begin
    nl;
    if pynq('List entire answer file') then begin
      nl;
      printf(ns+'.ASW');
    end;
  end;
end;

end.
