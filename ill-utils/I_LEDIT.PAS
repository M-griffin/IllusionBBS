{ I_LEdit - Illusion Bulletin Board System }
{ (c) 1996, Illusion Development           }
{ coded by Billy Ma, 4-12-96               }

{$A+,B-,D-,E-,F+,G+,I+,L-,N-,O-,R-,S-,V-,X+}
{$M 16384,0,655360}

program i_string_editor;

uses crt,dos;

{$I ..\main\rec25.pas}

var i,totlines,curline:word;
    t:text;
    s:string;
    lines:array[1..1500] of ^string;
    sl,el,curindex,totindex,hilite,numopt:byte;
    optlines:array[1..12] of word;
    index:array[1..80] of word;
    c:char;

const insmode:boolean=false;

procedure cursor(b:boolean);
var reg:registers;
begin
  if b then
    with reg do
    begin
      ax:=$0100;
      ch:=sl;
      cl:=el;
      intr($10,reg);
    end
  else
    with reg do
    begin
      ah:=$03;
      bh:=0;
      intr($10,reg);
      sl:=ch;
      el:=cl;
      ax:=$0100;
      cx:=$2020;
      intr($10,reg);
    end;
end;

function line:string;
var s:string[79];
begin
  fillchar(s,sizeof(s),'ִ');
  s[0]:=chr(79);
  line:=s;
end;

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

function cstr(i:longint):string;
var c:string[16];
begin
  str(i,c);
  cstr:=c;
end;

function allcaps(s:string):string;
var i:byte;
begin
  for i:=1 to length(s) do s[i]:=upcase(s[i]);
  allcaps:=s;
end;

function mln(s:string; l:integer):string;
begin
  if (length(s)<l) then
  begin
    fillchar(s[ord(s[0])+1],l-ord(s[0]),#32);
    s[0]:=chr(l);
  end else
    s[0]:=chr(l);
  mln:=s;
end;

procedure fastwrite(x,y,a:byte; s:string);
var i:byte; w:word;
begin
  w:=((y+3-1)*80+(x-1))*2;
  for i:=1 to length(s) do
  begin
    mem[$b800:w]:=ord(s[i]);
    mem[$b800:w+1]:=a;
    inc(w,2);
  end;
end;

procedure input(var s:string);
var cur,first:integer;
    c:char;

  procedure update;
  begin
    if (first>1) then fastwrite(5,wherey,15,#17) else fastwrite(5,wherey,15,#32);
    if (first<length(s)-72) then fastwrite(79,wherey,15,#16) else fastwrite(79,wherey,15,#32);
    fastwrite(6,wherey,(7 shl 4)+8,mln(copy(s,first,73),73));
    if (cur>length(s)) then fastwrite(78,wherey,(7 shl 4)+8,#32);
    gotoxy(cur-first+1+5,wherey);
  end;

begin
  cur:=length(s)+1;
  if (cur>73) then first:=cur-72 else first:=1;

  gotoxy(cur-first+1+5,wherey);
  textattr:=(7 shl 4)+8;
  clreol;
  fastwrite(79,wherey,7,'  ');

  repeat

    if (cur<first) then dec(first) else
    if (cur>first+72) then inc(first);
    update;

    c:=readkey;

    case c of
      ^X,
      ^Y:begin
           s:=''; cur:=1; first:=1;
           gotoxy(cur-first+1+5,wherey);
           clreol;
           fastwrite(79,wherey,7,'  ');
         end;
      #0:if keypressed then
         begin
           c:=readkey;
           case c of
            {l} #75:if (cur>1) then dec(cur);
            {r} #77:if (cur<=length(s)) then inc(cur);
          {del} #83:if (cur<=length(s)) then delete(s,cur,1);
         {home} #71:begin cur:=1; first:=1; end;
          {end} #79:begin
                      cur:=length(s)+1;
                      if (cur>73) then first:=cur-72 else first:=1;
                    end;
          {ins} #82:insmode:=not insmode;
           end;
           c:=#0;
         end;
      #8:if (cur>1) then
         begin
           delete(s,cur-1,1);
           dec(cur);
         end;
      #32..#255:
         begin
           if (cur=length(s)+1) and (length(s)<249) then
           begin
             inc(cur);
             s:=s+c;
           end else
           if (cur<=length(s)) then
           begin
             if (insmode) then
               insert(c,s,cur)
             else
               s[cur]:=c;
             inc(cur);
           end;
         end;
    end;

  until (c=#13);

  update;

end;

procedure writeat(x,y:byte; s:string);
const letclr=('kbgcrmywKBGCRMYW');
var i:word;
    j:integer;
begin
  gotoxy(x,y);
  textattr:=7;
  if (s<>'') then
    for i:=1 to length(s) do
    begin
      if (wherex=80) then
        fastwrite(79,y,15,'+')
      else
      if (s[i]='|') and (i<length(s)) then
      begin
        j:=pos(s[i+1],letclr);
        if (j<>0) then
        begin
          textattr:=j-1;
          inc(i);
        end else
        if (s[i+1] in ['0'..'2']) and (s[i+2] in ['0'..'9']) and
           (i<=length(s)-2) and (value(copy(s,i+1,2)) in [0..24]) then
        begin
          j:=value(copy(s,i+1,2));
          case j of
             0..15:textattr:=(textattr and $F0) or j;
            16..23:textattr:=(textattr and $8F) or (j shl 4);
                24:textattr:=(textattr xor $80);
          end;
          inc(i,2);
        end else
          write(s[i]);
      end else
        write(s[i]);
    end;
  textattr:=7;
  clreol;
end;

procedure writeopt(b:byte);
var s:string;
    comments:array[1..4] of string[80];
    i,j,k:word;
begin
  i:=optlines[b];
  if (b<=numopt) then
  begin
    if (b=hilite) then s:='|K|23' else s:='|K';
    s:=s+copy(lines[i]^,1,3)+'|K';
    if (lines[i]^[5]='*') then s:=s+'*' else s:=s+' ';
    s:=s+'|w '+copy(lines[i]^,7,length(lines[i]^)-6);
  end else
    s:='|Kתתת';
  writeat(1,b+1,s);
  if (b=hilite) then
  begin
    fillchar(comments,sizeof(comments),#0);
    if (lines[i-1]^[1]=';') and (i>1) then
    begin
      j:=i;
      while (lines[j-1]^[1]=';') and (lines[j-1]^[2]=' ') do dec(j);
      if (copy(lines[i]^,1,3)=copy(lines[j-1]^,2,3)) then
        for k:=j-1 to i-1 do comments[k-(j-1)+1]:=copy(lines[k]^,2,length(lines[k]^)-1);
    end;
    for k:=1 to 4 do writeat(1,k+15,comments[k]);
  end;
end;

begin
  textmode(co80);

  textattr:=15; write('I_LEDIT');
  textattr:=8;  write(' - ');
  textattr:=15; writeln('Illusion Language File Editor version '+ver);
  textattr:=7;  writeln('Copyright 1992-1998, Illusion Development.  All rights reserved.');
  textattr:=8;  writeln(line);
  textattr:=7;  writeln;

  if (paramcount=0) then
  begin
    writeln('Syntax:  I_LEDIT <language file>');
    halt;
  end;

  assign(t,paramstr(1));
  {$I-} reset(t); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Error: Cannot find '+allcaps(paramstr(1)));
    halt;
  end;

  writeat(1,5,'Loading...');
  totlines:=0;
  while (not eof(t)) do
  begin
    inc(totlines);
    new(lines[totlines]);
    readln(t,lines[totlines]^);
  end;

  write('Indexing...');
  i:=1;
  while (lines[i]^[1]=';') and (i<=totlines) do inc(i);
  if (i<=totlines) then
  begin
    index[1]:=i;
    totindex:=1;
  end else
  begin
    writeat(1,5,'Error: This does not appear to be a valid language file');
    writeln;
    halt;
  end;
  i:=0;
  for curline:=index[1] to totlines do
  begin
    if (lines[curline]^[1]<>';') then
    begin
      inc(i);
      if (i=12) then
      begin
        inc(totindex);
        index[totindex]:=curline+1;
        i:=0;
      end;
    end;
  end;
  if (i=0) then dec(totindex);

  cursor(false);
  window(1,4,80,25);
  clrscr;
  writeat(1,15,'|WComments:');
  writeat(1,21,'|W[Enter] |wedit  |K[F1] MCI list  |K-- |W[Left] [Right] [Home] [End] |wwhen editing');
  writeat(1,22,'|W[Esc] |wquit  |W[F2] |wquit & save |K-- |W[PgUp] [PgDn] [Up] [Down] |wmove lightbar');
  writeat(63,1,'|KMemAvail: '+cstr(memavail));

  c:=#0;
  curindex:=1;

  repeat

    numopt:=0; hilite:=1;
    fillchar(optlines,sizeof(optlines),0);
    curline:=index[curindex];
    while (numopt<12) and (curline<=totlines) do
    begin
      if (lines[curline]^[1]<>';') then
      begin
        inc(numopt);
        optlines[numopt]:=curline;
      end;
      inc(curline);
    end;

    for i:=1 to 12 do writeopt(i);

    repeat

      i:=hilite;

      c:=upcase(readkey);
      case c of
        #72,'8':begin
                  if (hilite=1) then hilite:=numopt else dec(hilite);
                  writeopt(i);
                  writeopt(hilite);
                end;
        #80,'2':begin
                  if (hilite=numopt) then hilite:=1 else inc(hilite);
                  writeopt(i);
                  writeopt(hilite);
                end;
        #73,'9':if (curindex=1) then curindex:=totindex else dec(curindex);
        #81,'3':if (curindex=totindex) then curindex:=1 else inc(curindex);
        #13:begin
              gotoxy(1,hilite+1);
              s:=copy(lines[optlines[hilite]]^,7,length(lines[optlines[hilite]]^)-6);
              cursor(true);
              input(s);
              cursor(false);
              while (length(lines[optlines[hilite]]^)<6) do
                lines[optlines[hilite]]^:=lines[optlines[hilite]]^+' ';
              lines[optlines[hilite]]^:=copy(lines[optlines[hilite]]^,1,6)+s;
              writeopt(hilite);
            end;
      end;

    until (c in [#27,#60,#73,'9',#81,'3']);

  until (c in [#27,#60]);

  clrscr;
  cursor(true);

  if (c=#27) then
  begin
    writeat(1,2,'Save language file? ');
    repeat
      c:=upcase(readkey);
    until (c in ['Y','N']);
    if (c='Y') then writeln('Yes') else writeln('No');
    if (c='Y') then c:=#60 else c:=#0;
  end;
  if (c=#60) then
  begin
    writeat(1,3,'Saving...');
    rewrite(t);
    for i:=1 to totlines do writeln(t,lines[i]^);
    writeln('Done.');
  end;

  for i:=1 to totlines do dispose(lines[i]);
  close(t);

end.
