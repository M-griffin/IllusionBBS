(*****************************************************************************)
(* Illusion BBS - Full screen editor                                         *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

Unit MailFSE;

interface

Uses
  Crt, Dos,
  common, misc2;

function FSE(fn:astr; cantabort:boolean):boolean;

implementation

function FSE(fn:astr; cantabort:boolean):boolean;

Const
   MaxWidth = 78;
   RtMrg : Integer = 76;
   LeftM : Integer = 1;

Type
   Line = String[MaxWidth];
   LPtr = ^LineRec;
   LineRec = Record
     Last : LPtr;
     Data : Line;
     Next : LPtr;
   End;

Var
   S,                          { Used for temp. work }
   BlankLine:string[80];       { String of 80 spaces }
   Finished,                   { Done editing? }
   readin,                     { Did we read in a file? }
   Changed:Boolean;            { File changed? }
   didquote:boolean;           { Did we already quote? }
   WorkFile:Text;              { File we're working on }
   ansiesc,ansicode:boolean;   { Escape / '[' received }
   insrt:boolean;              { Insert mode?          }
   Ln,LastLn,NextLn,           { Line pointers         }
   FirstLn,EndLn: LPtr;        { =============         }
   TabSet:Array [1..MaxWidth] Of Boolean;
   I,J,                        { cursor position: i = line, j = column }
   Len,                        { length of current line }
   NLines,                     { length of file }
   Top:integer;                { first line on screen }
   Ch:Char;                    { Input var. }

(*-------------------------------------------------------------------*)

procedure disposeall;
begin
  repeat
    ln:=endln^.next;                { goto 1st line }
    Ln^.Last^.Next := Ln^.Next;     { isolate current line }
    Ln^.Next^.Last := Ln^.Last;
    Dispose(Ln);                    { and zap it}
  until (ln=endln);
end;

Procedure ReadFile;
Var  Filefound,
     OvFlw     : Boolean;
     inputline : string[255];
     maxlines  : integer;
Begin
  fn:=allcaps(fn);
  New(Ln); Ln^.Data:=''; FirstLn:=Ln; EndLn:=Ln;
  Assign(WorkFile,fn);
  {$I-} Reset(WorkFile); {I+}
  
  If (IoResult=0) Then Begin
    OvFlw:=False; MaxLines:=MemAvail Div sizeof(linerec);
    If MaxLines < 0 Then MaxLines:=300;
    NLines := 0;
    spstr(751); {reading file}
    While Not (Eof(WorkFile) Or OvFlw) Do Begin
      ReadLn(WorkFile,InputLine);
      If Length(InputLine) > MaxWidth Then Begin
        spstr(752);
        OvFlw := True; sleep(1000);
      End Else Begin
        Ln^.Data := InputLine;
        LastLn   := Ln;
        New(Ln);
        Ln^.data := '';
        Ln^.last := LastLn;
        LastLn^.Next := Ln;
        inc(NLines);
        If NLines > MaxLines Then Begin
          spstr(753); {not enough mem to load file}
          OvFlw := True; sleep(1000);
        End;
      End;
    End;       {not EOF}
    EndLn := Ln;
    If Not OvFlw Then begin
      readin:=TRUE; close(workfile); exit;
    end else begin
      FirstLn^.Last:=EndLn;
      EndLn^.Next:=FirstLn;    { close chain, endless loop }
      disposeall;
      New(Ln); Ln^.Data:=''; FirstLn:=Ln; EndLn:=Ln;
    end;
  end;

  { else new file }

  NLines := 1;
  New(Ln);
  Ln^.Data      := '';
  FirstLn^.Next := Ln;
  Ln^.Last      := FirstLn;
  EndLn         := Ln;
End;

Procedure WriteFile;     { save changes to file }
Begin
  ReWrite(WorkFile);
  Ln := EndLn^.Next;
  Repeat
    WriteLn(WorkFile,Ln^.Data);
    Ln := Ln^.Next
  Until Ln = EndLn;
  Close(WorkFile);
End;





Procedure StatusBot;
Begin
  {if insrt then s:='Insert   ' else s:='Overwrite';}
  
  if insrt then 
    spstr(805)
  else 
    spstr(806);
    
  (*
  clearwaves;
  addwave('MO',s,txt);
  spstr(805); { Displays Message Foot }
  clearwaves;
  *)
End;


Procedure StatusLine;
Begin
  ansig(1,1); 
  spstr(801); { Display Message Header }
  StatusBot;
  ansig(j,i-top+12);
End;



Procedure ClearEOL;
begin
  if ((okansi) and (outcom)) then begin
    if (okavatar) then pr1(^V^G) else pr1(#27+'[K');
  end;
  if (wantout) then clreol;
end;


Procedure WriteLine(Row:Byte);    { direct write to screen }
Var Len        : Byte;            { writes blanks where there is no text}
    Contents   : String[80];
Begin
  s := BlankLine;
  Contents := Copy(Ln^.Data,1,78);
  Len      := Ord(Contents[0]);
  Insert(Contents,s,1);
  s[0]:=chr(79);
  ansig(1,row);
  if s=copy(blankline,1,79) then cleareol else prompt(s);
  ansig(j,i-top+12);
End;


Procedure Screen;     { rewrites the bottom 19 lines }
Var Row   : Byte;
    TopLn : LPtr;
    k     : integer;
    yy    : integer;
    xx    : integer;
    
Begin                 { makes sure i and ln are in register }
  Ln := EndLn^.Next;
  If Top > 1 Then
   For K := 2 To Top Do Ln := Ln^.Next;
  TopLn := Ln;
  For Row := 12 to 22 do Begin
    WriteLine(Row);
    If Ln <> EndLn Then Ln := Ln^.Next;
  End;
  Ln:=TopLn; Row:=I-Top;
  While Row > 0 do Begin
    Ln  := Ln^.Next;
    dec(row);
  End;
  
  yy:=wherey;  
  xx:=wherex;

  StatusBot;
  
  ansig(xx,yy);  
End;

function questionbox(q,a:astr):char;
var x,ii:integer; c:char;
begin
  x:=(80-(length(q)+5)) div 2;
  ansig(x,10);
  sprompt('|wÕ'); for ii:=1 to length(q)+2 do sprompt('Í'); sprompt('¸');
  ansig(x,11);
  sprompt('|w³'); for ii:=1 to length(q)+2 do prompt(' '); sprompt('³');
  ansig(x,12);
  sprompt('|w³ |C'+q+'|w ³');
  ansig(x,13);
  sprompt('|w³'); for ii:=1 to length(q)+2 do prompt(' '); sprompt('³');
  ansig(x,14);
  sprompt('|wÔ'); for ii:=1 to length(q)+2 do prompt('Í'); sprompt('¾');
  ansig(x+length(q)+2,12); cl(ord('C')); onek(c,a); cl(ord('w'));
  questionbox:=c;
end;

Procedure Help;
var c:char;
Begin
  Cls; lil:=0;
  printf('fsehelp');
  lil:=0;
  getkey(c);
  cls;
  StatusLine;
  Screen;
End;

Procedure PageUp;
Begin
  If (Top>10) Then Begin
    dec(top,10); dec(i,10); End
  Else Begin
    i:=1; Top:=1; End;
  Screen;
End;

Procedure PageDown;
begin
  inc(top,10); inc(i,10);
  if top>nlines-10 then begin
    dec(top,10); i:=nlines;
  end;
  Screen;
End;

Procedure Cursor;       { make sure the cursor is visible on the screen }
Var shifted:boolean;
Begin
  shifted:=FALSE;
  If I < 1 Then Begin
    I:=1;
    Ln:=EndLn^.Next;
  End;

  If (I>NLines) Then Begin
    I:=NLines;
    Ln:=EndLn^.Last;
  End;

  If (j<1) Then J:=1;
  If (j>MaxWidth) Then J:=MaxWidth;
  Len:=Ord(Ln^.Data[0]);

  If (I<Top) Then Begin
    top:=top-10; if top<1 then top:=1;
    Shifted := True;
  End;


{ previously 18, 12 # of lines between Header & Footer }
  If (I>Top+10) Then Begin
    top:=top+10; if top>nlines then top:=nlines;
    Shifted:=True;
  End;

  If Shifted Then Begin
    Screen;
  End;
End;

Procedure CursorLeft;
Begin
  dec(j);
  If J < 1 Then Begin
    dec(i);
    If I < 1 Then Begin
      I  := 1;
      J  := 1;
      Ln := EndLn^.Next ;
      Exit;
    End;
    J := Length(Ln^.Last^.Data) + 1 ;
    Ln := Ln^.Last ;
  End;
End;

Procedure CursorRight;
Begin
  inc(j);
  if j > MaxWidth then Begin
    inc(i);
    If I > NLines then Begin
      I  := NLines;
      Ln := EndLn^.Last ;
    End Else If I < NLines Then Ln := Ln^.Next;
    J := 1;
  End;
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
Begin
  More:=Copy(Ln^.Data,J,Len-J+1);
  Delete(Ln^.Data,J,Len-J+1);
  if i=nlines then writeline(i-top+12);
  InsertLn(More);
  inc(i);
  j := LeftM;
  if i=nlines then begin
    Ln:=Ln^.Next; writeline(i-top+12);
  end else Screen;
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
    insertln(''); inc(i); j:=leftm;
    if i=nlines then begin
      ln:=ln^.next; writeline(i-top+12);
    end else screen;
  end;
  ansig(j,i-top+12);
end;

Procedure StackLine;   { put current line on top of previous line }
begin
  j := length(ln^.last^.data)+1;
  ln^.last^.data := ln^.last^.data + ln^.data;
  ln^.last^.next := ln^.next;     { isolate current line }
  ln^.next^.last := ln^.last;
  Dispose(Ln);                    { and zap it}
  dec(i);
  dec(NLines);
  Screen;
End;

Procedure DeleteLine;
Begin
  if nlines<=0 then exit;
  if nlines=1 then begin
    ln^.data:=''; writeline(i-top+12); j:=1; ansig(j,i-top+12);
  end else begin
    Ln^.Last^.Next := Ln^.Next;     { isolate current line }
    Ln^.Next^.Last := Ln^.Last;
    Dispose(Ln);                    { and zap it}
    J:=1 ;  if i>=nlines then dec(i);
    dec(nlines);
    Changed := True;
    Screen;
  end;
End;

Procedure DeleteEOL;
Begin
  If J < MaxWidth Then Begin
    Ln^.Data := Copy ( Ln^.Data, 1 , J - 1 ) ;
    Changed := True;
  End;
  If J > 1 Then dec(J);
  writeline(i-top+12);
End;

Procedure DeleteBOL;
Begin
  If J > 1 Then Begin
    Ln^.Data := Copy ( BlankLine, 1, J ) + Copy ( Ln^.Data, J + 1 , MaxWidth ) ;
    Changed := True;
  End;
  If J < MaxWidth Then inc(j);
  writeline(i-top+12);
End;

Procedure DeleteWord;
Var
  EndW : Byte;
Begin
  While ((Copy(Ln^.Data,J,1)<>' ') And (J>0)) Do dec(j);
  If (J=0) Then J:=1;
  EndW:=J+1;
  While ((Copy(Ln^.Data,EndW,1)<>' ') And (EndW<MaxWidth)) Do inc(EndW);
  If J=1 Then Ln^.Data:=Copy(Ln^.Data,EndW+1,MaxWidth)
   Else Ln^.Data:=Copy(Ln^.Data,1,J )+Copy(Ln^.Data,EndW+1,MaxWidth);
  Changed:=True;
  writeline(i-top+12);
End;

Procedure PrevWord;
Begin
(* if i am in a word then skip to the space *)
  While (Not ((Ln^.Data[j] = ' ') Or ( j >= Length(Ln^.Data) ))) And
         (( i <> 1 ) Or ( j <> 1 )) Do
      CursorLeft;
(* find end of previous word *)
  While ((Ln^.Data[j] = ' ') Or ( j >= Length(Ln^.Data) )) And
         (( i <> 1 ) Or ( j <> 1 )) Do
      CursorLeft;
(* find start of previous word *)
  While (Not ((Ln^.Data[j] = ' ') Or ( j >= Length(Ln^.Data) ))) And
         (( i <> 1 ) Or ( j <> 1 )) do
      CursorLeft;
   CursorRight;
End;

Procedure NextWord;
Begin
(* if i am in a word, then move to the whitespace *)
  while (not ((Ln^.Data[j] = ' ') or ( j >= length(Ln^.Data)))) and
        ( i < NLines ) do
    CursorRight;
(* skip over the space to the other word *)
  while ((Ln^.Data[j] = ' ') or ( j >= Length(Ln^.Data))) and
         ( i < NLines ) do
    CursorRight;
End;

Procedure Tab;
Begin
  If (J<MaxWidth) Then Begin
    Repeat
      inc(j);
    Until (TabSet[J]=True) Or (J=MaxWidth);
  End;
End;

Procedure BackTab;
Begin
  If (J>1) Then Begin
    Repeat
       dec(j);
    Until (TabSet[J]=True) Or (J=1);
  End;
End;

procedure quote;
var f:text;
    repto,repfrom,reptitle:string;
    k:integer; ch,ch1:string[9];
    s:array[1..9] of string;
    done,addedline:boolean; c1,c2:char;
    
    str:string; { end of Quote string }

    procedure insertqln(contents:line);
    begin
      insertln(contents); ln:=ln^.next; inc(i); j:=length(ln^.data)+1;
      addedline:=TRUE;
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
    spstr(147);
    statusline; screen; exit;
  end else begin
    readln(f,repfrom);
    readln(f,repto);
    readln(f,reptitle);
    done:=FALSE; addedline:=FALSE;
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
    
     
    if (didquote=TRUE) then 	{ Add Finish Quote if Quote was Initated } 
    begin
      str:=getstr(800);		{ end of line quoting }
      while (pos('@F',str)<>0) do str:=substone(str,'@F',caps(repfrom));
      while (pos('@T',str)<>0) do str:=substone(str,'@T',caps(repto));
      while (pos('@R',str)<>0) do str:=substone(str,'@R',reptitle);
      insertqln(str);    
      if addedline then insertqln('');
      if addedline then insertqln('');
      didquote:=FALSE
    end;
    
    close(f); cls; statusline; screen;
  end;
end;

procedure clearit;
begin
  if questionbox('Clear message and start over? ','YN')='Y' then begin
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
    i:=1; j:=1; top:=1; didquote:=FALSE; ansiesc:=FALSE; ansicode:=FALSE;
  end;
  cls; statusline; screen;
end;

Procedure AddChar;       { keyboard entry }
var c:char; z:byte;
begin
  if ansicode then begin
    case ch of
      'A':if i>1 then begin
            dec(i); ln:=ln^.last; cursor; ansig(j,i-top+12);
          end;
      'B':if i<nlines then begin
            inc(i); ln:=ln^.next; cursor; ansig(j,i-top+12);
          end;
      'C':begin cursorright; cursor; ansig(j,i-top+12); end;
      'D':begin cursorleft; cursor; ansig(j,i-top+12); end;
      'H':begin j:=leftm; ansig(j,i-top+12); end;
      'K':begin j:=len+1; ansig(j,i-top+12); end;
    end;
    ansicode:=FALSE; ansiesc:=FALSE; exit;
  end else
  if ansiesc then
    if ch='[' then begin
      ansicode:=TRUE; ansiesc:=FALSE; exit;
    end else begin
      ansiesc:=FALSE; ansicode:=FALSE;
    end;

  if ((ch='/') and (j=1) {and (i=nlines) {and (ln^.data='')}) then begin
    sprompt(getstr(88));
    getkey(c);
    for z:=1 to lenn(getstr(88)) do prompt(^H' '^H);
    cl(ord('w'));
    case upcase(c) of
      'S':finished:=TRUE;
      'A':if (not cantabort) then begin
            changed:=FALSE; finished:=TRUE;
          end else begin
            statusline; ansig(j,i-top+12);
          end;
      'H','?':help;
      'C':clearit;
      'Q':quote;
    end;
    screen;
  end else begin
    Changed := True;
    While J > Len + 1 Do Begin
      Ln^.Data := Ln^.Data + ' ' ;
      inc(Len);
    End;
    If (J=Len+1) Then Ln^.Data := Ln^.Data + Ch
      Else If InSrt Then Insert(Ch,Ln^.Data,J)
        Else Ln^.Data[J] := Ch;
    inc(J);
    if (j=len+2) then prompt(ch) else WriteLine(I-Top+12);
    If  (J>RtMrg+2) Then WordWrap;
  end;
End;

Procedure Command;
var c1:char;
Begin
  Case Ch Of

(*
{^PgUp} #132 : Begin
                 I   := 1;
                 Top := 1;
                 Ln  := FirstLn;
                 Screen;
               End;
{^PgDn} #118 : Begin
                 I   := NLines;
                 Top := NLines - 21;
                 Ln  := EndLn;
                 Screen;
               End;
*)
   ^Q: begin J:=LeftM; ansig(j,i-top+12); end;
   ^W: begin J:=Len+1; ansig(j,i-top+12); end;
   ^Z: DeleteBOL;
   ^P: DeleteEOL;
   ^I: begin Tab; ansig(j,i-top+12); end;
   ^O: begin BackTab; ansig(j,i-top+12); end;
   ^F: begin NextWord; ansig(j,i-top+12); end;
   ^A: begin PrevWord; ansig(j,i-top+12); end;
   ^D: begin cursorright; cursor; ansig(j,i-top+12); end;
   ^S: begin cursorleft; cursor; ansig(j,i-top+12); end;
   ^E: If I > 1 Then Begin
         dec(i);
         Ln := Ln^.Last;
         cursor; ansig(j,i-top+12);
       End;
   ^X: If I < NLines Then Begin
         inc(i);
         Ln := Ln^.Next;
         cursor; ansig(j,i-top+12);
       End;
   #127,
   ^G: Begin
         Delete(Ln^.Data,J,1);
         WriteLine(I-Top+12);
       End;
   ^H: If ((j=1) and (i=1)) then
       else If (j=1) Then
         StackLine
       Else Begin
         dec(j);
         Delete(Ln^.Data,J,1);
         Cursor;
         if j=len+1 then prompt(^H' '^H) else WriteLine(i-Top+12);
       End;
   ^M: Begin
         If InSrt Then Begin
           If (J=Len) Then inc(J);
           CutLine;
         End Else Begin
           J:=1;
           if i=nlines then begin
             insertln(''); Ln:=Ln^.Next;
           end else Ln:=Ln^.Next;
           inc(i); cursor; ansig(j,i-top+12);
         End;
       End;
   ^R: PageUp;
   ^C: PageDown;
   ^Y: DeleteLine;
   ^N: Begin
         Ln := Ln^.Last;
         InsertLn('');
         Screen;
       End;
   ^V: Begin
         insrt:=not insrt;
         Screen;
         {StatusLine;}
       End;
   ^T: deleteword;
   ^U: help;
   ^L: begin cls; statusline; screen; end;
   ^K: begin
         ansig(72,2);
         onekcr:=FALSE; onek(c1,'SAH?QDEFRC'^M); onekcr:=TRUE;
         case c1 of
           'S':finished:=TRUE;
           'A':if (not cantabort) then begin
                 changed:=FALSE; finished:=TRUE;
               end else begin
                 statusline; ansig(j,i-top+12);
               end;
           'H','?':help;
           ^M :begin statusline; ansig(j,i-top+12); end;
           'C':clearit;
           'Q':quote;
           'D','E','F','R':if (buf='') then begin
                 statusline; ansig(j,i-top+12);
                 dm(' '+macros^.macro[pos(c1,'DEFR')],c1);
               end;
         end; {case}
       end;
  #27: ansiesc:=TRUE;
  End; {case}
End;

Begin {Main}
  Cls; fse:=FALSE;
  BlankLine := ''; For J := 1 To 80 Do BlankLine := BlankLine + ' ';
  For I:=1 To MaxWidth Do TabSet[I]:=( I Mod 5 )=0;

  Readin:=FALSE; ReadFile;
  FirstLn^.Last:=EndLn;
  EndLn^.Next:=FirstLn;    { close chain, endless loop }
  J:=1;   I:=1;
  Top:=1;
  Finished:=False; Changed:=False; didquote:=FALSE;
  ansiesc:=FALSE; ansicode:=FALSE; insrt:=TRUE;

  StatusLine; if readin then screen else ln:=ln^.last;
  macok:=FALSE; write_msg:=TRUE;
  Repeat
    Cursor; lil:=0;
    getkey(ch);
    Case Ch Of
      #0..#31,#127 : Command;
              Else   AddChar;
    End;
    if hangup then begin changed:=FALSE; finished:=TRUE; end;
  Until Finished;

  write_msg:=FALSE;
  If Changed Then begin
    WriteFile; fse:=TRUE;
  end;
  disposeall;
  macok:=TRUE; Cls;
end;

End.
