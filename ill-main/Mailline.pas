(*****************************************************************************)
(* Illusion BBS - Line editor                                                *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

Unit MailLine;

interface

Uses
  Crt, Dos,
  common;

function LineEdit(fn:astr; cantabort:boolean):boolean;

implementation

function LineEdit(fn:astr; cantabort:boolean):boolean;

Const
   MaxWidth = 80;
   RtMrg : Integer = 79;
   LeftM : Integer = 1;

Type
   Line = String[MaxWidth];
   Lptr = ^Linerec;
   LineRec = Record
     Last : Lptr;
     Data : Line;
     Next : LPtr;
   End;

Var
   Finished,                               { Finished editing?       }
   changed:Boolean;                        { Save it? (changed made) }
   didquote:boolean;                       { Did we quote already?   }
   workfile:Text;                          { File to save to (fn)    }
   ln,lastln,nextln,                       { LINE POINTERS           }
   firstln,endln: Lptr;                    { =============           }
   TabSet:array [1..maxwidth] of boolean;  { Tab stops               }
   NLines,                                 { Total Lines             }
   I,J,                                    { J=current char, i=temp. }
   Len:integer;                            { length of current line  }
   Ch:Char;                                { input char              }

(*--------------------------------------------------------------------*)

Procedure readfile;
begin
  assign(workfile,fn);
  New(Ln); Ln^.Data:=''; FirstLn:=Ln; EndLn:=Ln;
  Nlines := 1;
  New(Ln);
  Ln^.Data:='';
  FirstLn^.Next:=Ln;
  Ln^.Last:=Firstln;
  EndLn:=Ln;
end;

Procedure WriteFile;  { save changes to file }
Begin
  Rewrite(workfile);
  Ln:=endln^.next;
  repeat
    writeln(workfile,ln^.data);
    ln:=ln^.next;
  until ln=endln^.last;
  close(workfile);
end;

procedure disposeall;
begin
  repeat
    ln:=endln^.next;
    ln^.last^.next:=ln^.next;
    ln^.next^.last:=ln^.last;
    dispose(ln);
  until (ln=endln);
end;

procedure statusline;
var k:integer;
begin
  spstr(72); {msg line editor header}
  sprompt('|W[|K');
  for k:=2 to (thisuser.linelen-2) do begin
    case (k mod 5) of
      0:sprompt('|wù|K');
      else sprompt('.');
    end;
  end;
  sprint('|W]|w');
end;

procedure listit(stline:integer; linenum,disptotal:boolean);
var k:integer; oldln:Lptr;
    abort,next:boolean;
begin
  If disptotal then begin
    clearwaves;
    addwave('TL',cstr(nlines-1),txt);
    spstr(754); {total lines}
    clearwaves;
  end;
  abort:=FALSE; next:=FALSE; dosansion:=FALSE;
  Oldln:=ln; Ln := Endln^.next; i:=stline;
  For k:=2 to stline do ln:=ln^.next;
  while ((ln<>endln^.last) and (not abort)) do begin
    if linenum then print(cstr(i)+':');
    spromptt(ln^.data,FALSE,FALSE); nl;
    wkey(abort,next);
    if (ln<>endln^.last) then ln:=ln^.next; inc(i);
  end;
  ln:=oldln; dosansion:=FALSE;
end;

procedure help;
begin
  spstr(755);
end;

procedure clearit;
begin
  disposeall;
  New(Ln); Ln^.Data:=''; FirstLn:=Ln; EndLn:=Ln;
  NLines := 1;
  New(Ln);
  Ln^.Data      := '';
  FirstLn^.Next := Ln;
  Ln^.Last      := FirstLn;
  EndLn         := Ln;
  FirstLn^.Last:=EndLn;
  EndLn^.Next:=FirstLn;
  Ln:=Ln^.Last;
  j:=1; didquote:=FALSE;
end;

Procedure DeleteLine;
Begin
  if nlines<=0 then exit;
  Ln^.Last^.Next := Ln^.Next;     { isolate current line }
  Ln^.Next^.Last := Ln^.Last;
  Dispose(Ln);                    { and zap it}
  J:=1 ; dec(nlines);
  Changed := True;
End;

Procedure InsertLn(contents:line);  {insert after current line}
Begin
  New(NextLn);
  NextLn^.Data := Contents;
  NextLn^.Last := Ln;
  NextLn^.Next := Ln^.Next;
  Ln^.Next^.Last := NextLn;
  Ln^.Next := NextLn;
  inc(nlines);
End;

Procedure CutLine;    { start new line after <CR> }
Var
  More : Line;
  i    : integer;
Begin
  More:=Copy(Ln^.Data,J,Len-J+1);
  Delete(Ln^.Data,J,Len-J+1);
  for i:=1 to (len-j+1) do prompt(^H' '^H);
  InsertLn(More); nl;
  j := LeftM;
  Ln:=Ln^.Next; sprompt(ln^.data);
End;

Procedure WordWrap;
var n:integer;
Begin
  N := 0;
  Repeat
    dec(J);
    inc(n);
  Until (Ln^.Data[J] = ' ') Or (J = 1);
  if j>1 then begin
    inc(j);
    inc(len);
    CutLine;
    J:=LeftM+N-1;
  end else begin
    insertln(''); nl; j:=leftm; ln:=ln^.next;
  end;
end;

procedure quote;
var f:text;
    repto,repfrom,reptitle:string;
    k:integer; ch,ch1:string[9];
    s:array[1..9] of string;
    done:boolean; c1,c2:char;
    str:string; { end of line quote }

    procedure insertqln(contents:line);
    begin
      ln^.data:=contents; insertln(''); ln:=ln^.next; j:=LeftM;
    end;

    procedure qlines;
    var s:string; ii:integer;
    begin
      if didquote then exit;
      for ii:=1 to 2 do begin
        case ii of 1:s:=getstr(144); 2:s:=getstr(145); end;
        while (pos('@F',s)<>0) do s:=substone(s,'@F',caps(repfrom));
        while (pos('@T',s)<>0) do s:=substone(s,'@T',caps(repto));
        while (pos('@R',s)<>0) do s:=substone(s,'@R',reptitle);
        insertqln(s);
      end;
      didquote:=TRUE;
    end;

begin
  assign(f,'msgtmp.'+cstr(nodenum));
  {$I-} reset(f); {$I+}
  if (ioresult<>0) then begin
    spstr(421);
    exit;
  end else begin
    readln(f,repfrom);
    readln(f,repto);
    readln(f,reptitle);
    done:=FALSE;
    repeat
      spstr(146);
      ch:='';
      for k:=1 to 9 do s[k]:=''; k:=1;
      while ((not(eof(f))) and (k<=9)) do begin
         readln(f,s[k]); ch:=ch+cstr(k);
         sprint('|w'+cstr(k)+'|K: |w'+s[k]); inc(k);
      end;

      if eof(f) then done:=TRUE;
      spstr(148); onek(c1,ch+'Q'^M);
      if (c1='Q') then done:=TRUE else
      if (c1<>^M) then begin
        ch1:=copy(ch,pos(c1,ch),length(ch)-pos(c1,ch)+1);
        spstr(149); onek(c2,ch1+'Q'^M);
        if (c2=^M) then c2:=c1;
        if (c2='Q') then done:=TRUE else begin
          qlines;
          for k:=value(c1) to value(c2) do
            if (pos(cstr(k),ch)<>0) then insertqln(s[k]);
        end;
      end;

    until done;
    
    
  (*  remove end of Line quoting for now.. Line Editor Sucks!!
  
    str:=getstr(800); { end of line quoting }    
    insertqln(str);  
    
  *)    
    
    close(f); spstr(150);
    k:=nlines-5; if k<=0 then k:=1;
    statusline; listit(k,FALSE,FALSE);
  end;
end;

Procedure AddChar;       { keyboard entry }
var c:char; i:byte;
begin
  if ((ch='/') and (j=1)) then begin
    sprompt(getstr(88));
    getkey(c); if trapping then write(trapfile,c);
    for i:=1 to lenn(getstr(88)) do prompt(^H' '^H);
    cl(ord('w'));
    case upcase(c) of
      'S':finished:=TRUE;
      'A':if (not cantabort) then
            if (pynq('Abort message')) then begin
              changed:=FALSE; finished:=TRUE;
            end;
      'L':listit(1,pynq('|LF|wList message with line numbers'),TRUE);
      'H','?':help;
      'C':if pynq('Clear message') then begin
            clearit; statusline;
          end;
      'Q':quote;
    end;
  end else begin
    Changed := True;
    Ln^.Data := Ln^.Data + Ch;
    if trapping then write(trapfile,ch);
    inc(J); prompt(ch);
    If  (J>RtMrg) Then WordWrap;
  end;
End;

procedure bkspc;
begin
  if (j=1) and (nlines>1) then begin
    spstr(756); {back to previous line}
    deleteline; ln:=endln^.last; prompt(ln^.data);
    j:=length(ln^.data)+1;
  end else begin
    dec(j); Delete(ln^.data,j,1);
    prompt(^H' '^H);
  end;
end;

Procedure Command;
var c1:char;
Begin
  Case ch of
    ^[: addchar;
    ^M: Begin
          j:=1; insertln(''); ln:=ln^.next; nl;
        end;
    ^H: bkspc;
{   ^B: if (not (rbackspace in thisuser.ac)) then dm(' /'^N'-'^N'\'^N'|'^N,ch);}
    ^I: begin
          if (j<RtMrg) then begin
            repeat
              outkey(' '); if trapping then write(trapfile,' ');
              ln^.data:=ln^.data+' '; inc(j);
            until ((tabset[j]) or (j=RtMrg))
          end;
        end;
{   ^N: if (not (rbackspace in thisuser.ac)) then begin
          outkey('*'); ln^.data:=ln^.data+^H;
          if (trapping) then write(trapfile,^H);
          inc(j);
        end;
}
    ^P: if (aacs(memboard.mciacs)) then begin
          getkey(c1); c1:=upcase(c1);
          if (j=1) then
            case c1 of
              'C':begin sprompt('|WC|w'); ln^.data:=#2; inc(j); end;
              'T':begin sprompt('|WTBX|w'); ln^.data:=boxedtitle; inc(j,3); end;
            end;
        end;
    ^S: dm('ú '+nam+' ',ch);
    ^W: if (j>1) then repeat
          bkspc;
        until (j=1) or (ln^.data[j]=' ') or (ln^.data=^H);
    ^X: if j>1 then repeat bkspc; until (j=1);
  end;
end;

Begin
  LineEdit:=FALSE;
  for i:=1 to maxwidth do tabset[i]:=(i mod 5)=0;

  readfile;
  firstln^.last:=endln;
  endln^.next:=firstln;
  j:=1;

  Finished:=False;  Changed:=False;  didquote:=False;

  Statusline; ln:=ln^.last;
  macok:=TRUE;

  Repeat
    Len:=ord(ln^.data[0]);
    getkey(ch); lil:=0;
    case ch of
      #0..#31,#127 : Command;
              Else   Addchar;
    end;
    if hangup then begin changed:=FALSE; finished:=TRUE; end;
  until finished;

  if changed then begin
    writefile; lineedit:=true;
  end;
  disposeall;
end;

end.
