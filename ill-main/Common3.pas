(*****************************************************************************)
(* Illusion BBS - Common functions and procedures [3/3]                      *)
(*****************************************************************************)

{$A+,B-,E+,F+,I+,N-,O+,R-,S+,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit common3;

interface

uses
  crt, dos, myio, foscom2, common;

procedure inu(var i:integer);
procedure ini(var i:byte);
procedure inputwn1(var v:string; l:integer; flags:string; var changed:boolean);
procedure inputwn(var v:string; l:integer; var changed:boolean);
procedure inputwnwc(var v:string; l:integer; var changed:boolean);
procedure inputmain(var s:string; ml:integer; flags:string);
procedure inputwc(var s:string; ml:integer);
procedure input(var s:string; ml:integer);
procedure inputl(var s:string; ml:integer);
procedure inputcaps(var s:string; ml:integer);
procedure inputphone(var s:string);
procedure inputdate(var s:string);
procedure mmkey(var s:string);
procedure inputed(var s:string; len:integer; flags:string);
procedure inputxy(x,y:byte; var s:string; len:integer);
procedure switchyn(x,y:byte; var b:boolean);
function inputnumxy(x,y:byte; l:longint; len:integer; lo,hi:longint):longint;
procedure inputcharxy(x,y:byte; var c:char);
function gc(s:string;b:word):char;
procedure displaycolor(x,y,color:byte);
procedure inputcolorxy(x,y:byte; var color:byte);

function  iReadDate(def : String) : String;
function  iReadPhone(def : String) : String;
function  iReadPostalCode : String;
function  iReadTime(def : String) : String;
function  iReadZipCode : String;

function  iEditString(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Len : Byte; pgLen : Byte) : String;
function  iGetString(f, c, p, l, d, e : String) : String;
function  iReadString(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Len : Byte) : String;

implementation

uses common1, common2, strproc;

procedure inu(var i:integer);
var s:string[5];
begin
  badini:=FALSE;
  input(s,5); i:=value(s);
  if (s='') then badini:=TRUE;
end;

procedure ini(var i:byte);
var s:string[3];
begin
  badini:=FALSE;
  input(s,3); i:=value(s);
  if s='' then badini:=TRUE;
end;

procedure inputwn1(var v:string; l:integer; flags:string; var changed:boolean);
var s,os:string;
begin
  os:=v;
  inputmain(s,l,flags);
  if (s=' ') then
    if pynq('Set string to null') then v:='' else
  begin
  end
  else if (s<>'') then v:=s;
  if (os<>v) then changed:=TRUE;
end;

procedure inputwn(var v:string; l:integer; var changed:boolean);
begin
  inputwn1(v,l,'',changed);
end;

procedure inputwnwc(var v:string; l:integer; var changed:boolean);
begin
  inputwn1(v,l,'c',changed);
end;

(* flags: "U" - Uppercase only
          "L" - Linefeeds OFF - no linefeed after <CR> pressed
          "D" - Display old if no change
          "P" - Capitalize characters ("ERIC OMAN" --> "Eric Oman")
*)
procedure inputmain(var s:string; ml:integer; flags:string);
var os:string;
    cp:integer;
    c:char;
    origcolor:byte;
    xxupperonly,xxnolf,xxredisp,xxcaps:boolean;

  procedure dobackspace;
  begin
    if (cp>1) then begin
      dec(cp);
      outkey(^H); outkey(' '); outkey(^H);
    end;
  end;

begin
  flags:=allcaps(flags);
  xxupperonly:=(pos('U',flags)<>0);
  xxnolf:=(pos('L',flags)<>0); xxredisp:=(pos('D',flags)<>0);
  xxcaps:=(pos('P',flags)<>0);
  origcolor:=curco; os:=s;

  checkhangup;
  if (hangup) then exit;
  cp:=1;
  repeat
    getkey(c);
    if (xxupperonly) then c:=upcase(c);
    if (xxcaps) then
      if (cp>1) then begin
        if (c in ['A'..'Z','a'..'z']) then
          if (s[cp-1] in ['A'..'Z','a'..'z',#39,'0'..'9',#128..#255]) then begin
            if (c in ['A'..'Z']) then c:=chr(ord(c)+32);
          end else
            if (c in ['a'..'z']) then c:=chr(ord(c)-32);
      end else
        c:=upcase(c);
    if (c in [#32..#255]) then
      if (cp<=ml) then begin
        s[cp]:=c; inc(cp); outkey(c);
      end else
    begin
    end
    else case c of
      ^H:dobackspace;
      ^X:while (cp<>1) do dobackspace;
    end;
  until ((c=^M) or (c=^N) or (hangup));
  s[0]:=chr(cp-1);
  if ((xxredisp) and (s='')) then begin
    s:=os;
    prompt(s);
  end;
  if (not xxnolf) then nl;
end;

procedure inputwc(var s:string; ml:integer);
  begin inputmain(s,ml,''); end;

procedure input(var s:string; ml:integer);
  begin inputmain(s,ml,'u'); end;

procedure inputl(var s:string; ml:integer);
  begin inputmain(s,ml,''); end;

procedure inputcaps(var s:string; ml:integer);
  begin inputmain(s,ml,'p'); end;

procedure inputphone(var s:string);
var c:char;
    i:byte;
    cc:string;
begin   {(xxx) xxx-xxxx; xxx-xxx-xxxx}
  onekcr:=FALSE;
  mpl(14);
  sprompt('('); i:=1;
  repeat
    if i=13 then cc:=^M^H else cc:='1234567890'^H^M;
    onek(c,cc);
    if (c in [#48..#57]) then begin
      s[i]:=c; inc(i);
      case i of
        4:begin sprompt(') '); s[i]:='-'; inc(i); end;
        8:begin sprompt('-'); s[i]:='-'; inc(i); end;
      end; {case}
    end else if (c=^H) then begin
      case i of
        1:;
        5:begin
            prompt(^H^H^H'   '^H^H^H);
            dec(i,2);
            s[0]:=chr(i-1);
          end;
        9:begin
            prompt(^H^H'  '^H^H);
            dec(i,2);
            s[0]:=chr(i-1);
          end;
        else begin
          prompt(^H' '^H);
          dec(i);
          s[0]:=chr(i-1);
        end;
      end;
    end;
  until (c=^M) or (hangup);
  s[0]:=chr(i-1);
  onekcr:=TRUE;
end;

procedure inputdate(var s:string);
var c:char;
    i:byte;
    cc:string;
begin  {xx/xx/xx}
  onekcr:=FALSE;
  i:=1;
  mpl(8);
  repeat
    case i of
      1:cc:='01'^H^M;
      2:if s[1]='1' then cc:='012'^H else cc:='123456789'^H^M;
      4:cc:='0123'^H^M;
      5:if s[4]='3' then cc:='01'^H else
        if s[4]='0' then cc:='123456789'^H^M else cc:='0123456789'^H^M;
      7:cc:='0123456789'^H^M;
      8:if s[7]='0' then cc:='123456789'^H else cc:='0123456789'^H^M;
      9:cc:=^M^H;
    end;
    onek(c,cc);
    if (c in [#48..#57]) then begin
      s[i]:=c;
      inc(i);
      case i of
        3:begin sprompt('/'); s[i]:='/'; inc(i); end;
        6:begin sprompt('/'); s[i]:='/'; inc(i); end;
      end; {case}
    end else if (c=^H) then begin
      case i of
        1:;
        4,7:begin
              prompt(^H^H'  '^H^H);
              dec(i,2);
              s[0]:=chr(i-1);
            end;
        else begin
          prompt(^H' '^H);
          dec(i);
          s[0]:=chr(i-1);
        end;
      end;
    end;
  until (c=^M) or (hangup);
  s[0]:=chr(i-1);
  onekcr:=TRUE;
end;

{ flags:  U  all uppercase
          P  proper caps
          O  redisplay after
          S  if O then redisplay without color
          L  no linefeed after
          B  check for trailing backslash
}

procedure inputed(var s:string; len:integer; flags:string);
var cur:integer;
    c,cc:char;
    i,oldco:byte;
    change:shortint;
    insrt,caps,pcaps:boolean;

  function dback(i:byte):string;
  begin
    if (i>0) then
      dback:=^[+'['+cstr(i)+'D'
    else
      dback:='';
  end;

  procedure update;
  begin
    spromptt(dback(cur-1)+mlnnomci(s,len)+dback(len),false,false);
    cur:=cur+change;
    spromptt(mlnnomci(s,cur-1),false,false);
  end;

begin
  flags:=allcaps(flags);
  caps:=pos('U',flags)<>0;
  pcaps:=pos('P',flags)<>0;
  oldco:=curco;
  insrt:=TRUE;

  checkhangup;
  if (hangup) then exit;

  if (length(s)>len) then s[0]:=chr(len);

  cur:=length(s)+1;
  setc(systat^.inputfieldcolor);
  prompt(mlnnomci(s,len)+dback(len-cur+1));

  repeat

    getkey(c);
    if (caps) then c:=upcase(c);
    if (pcaps) then
      if (cur>1) then begin
        if (c in ['A'..'Z','a'..'z']) then
          if (s[cur-1] in ['A'..'Z','a'..'z',#39]) then begin
            if (c in ['A'..'Z']) then c:=chr(ord(c)+32);
          end else
            if (c in ['a'..'z']) then c:=chr(ord(c)-32);
      end else
        c:=upcase(c);
    if (c in [#32..#126,#128..#255]) then
    begin
      if (cur<=len) then
      begin
        if (cur=length(s)+1) then
        begin
          s:=s+c;
          inc(cur);
          outkey(c);
        end else
        begin
          if (insrt) then
          begin
            if (length(s)=len) then delete(s,length(s),1);
            insert(c,s,cur)
          end else
            s[cur]:=c;
          change:=1;
          update;
        end;
      end;
    end else
      case c of
        ^V:insrt:=not insrt;
        ^H:if (cur>1) then
           begin
             if (cur<=length(s)) then
             begin
               change:=-1;
               delete(s,cur-1,1);
               update;
             end else
             begin
               s:=copy(s,1,length(s)-1);
               dec(cur);
               prompt(^H+' '+^H);
             end;
           end;
        ^X,^Y:
           begin
             change:=1-cur;
             s:='';
             update;
           end;
        #127:
           if (cur<=length(s)) then
           begin
             change:=0;
             delete(s,cur,1);
             update;
           end;
        #27:
           begin
             getkey(cc);
             if (cc='[') then
             begin
               getkey(cc);
               change:=0;
               case cc of
                 'C':if (cur<len) and (cur<=length(s)) then
                     begin
                       outkey(s[cur]);
                       inc(cur);
                     end;
                 'D':if (cur>1) then
                     begin
                       prompt(dback(1));
                       dec(cur);
                     end;
                 'H':begin
                       prompt(dback(cur-1));
                       cur:=1;
                     end;
                 'K':begin
                       prompt(copy(s,cur,length(s)-cur+1));
                       cur:=length(s)+1;
                     end;
               end;
             end;
           end;
      end;

  until (c=^M) or (c=^N) or (hangup);

  dosansion:=FALSE;
  ctrljoff:=FALSE;

  if (pos('B',flags)<>0) then
    if (s<>'') and (copy(s,length(s),1)<>'\') then s:=s+'\';
  if (pos('O',flags)<>0) then
  begin
    setc(7);
    if (pos('S',flags)<>0) then
      sprompt(''+dback(cur-1)+mlnnomci(s,len))
    else
      sprompt(dback(cur-1)+mln(s,len));
  end;

  dosansion:=FALSE;
  ctrljoff:=FALSE;
  setc(oldco);
  if (pos('L',flags)=0) then nl;
end;

procedure inputxy(x,y:byte; var s:string; len:integer);
begin
  ansig(x,y);
  if (len<0) then
  begin
    len:=abs(len);
    inputed(s,len,'OSU');
  end else
    inputed(s,len,'OS');
end;

function inputnumxy(x,y:byte; l:longint; len:integer; lo,hi:longint):longint;
var s:astr;
    li:longint;
begin
  s:=cstr(l);
  ansig(x,y);
  inputed(s,len,'OS');
  if (s<>'') and (value(s)>=lo) and (value(s)<=hi) then li:=value(s) else li:=l;
  ansig(x,y);
  sprompt('|w'+mn(li,len));
  inputnumxy:=li;
end;

procedure inputcharxy(x,y:byte; var c:char);
var s:astr;
begin
  s:=c;
  ansig(x,y);
  inputed(s,1,'OS');
  c:=s[1];
end;

procedure displaycolor(x,y,color:byte);
const clr:array[0..15] of string[13]=
          ('Black','Blue','Green','Cyan','Red','Magenta','Brown','Light Gray',
           'Dark Gray','Light Blue','Light Green','Light Cyan','Light Red',
           'Light Magenta','Yellow','White');
begin
  ansig(x,y); setc(color);
  sprompt(aonoff((color and 128)<>0,'Blinking ','')+
          clr[color and 15]+' on '+clr[(color shr 4) and 7]+'|k|LC');
  ansig(x,y);
end;

procedure inputcolorxy(x,y:byte; var color:byte);
var oldco:byte;
    c,cc:char;
begin
  checkhangup;
  if (hangup) then exit;

  oldco:=curco;
  displaycolor(x,y,color);

  repeat
    getkey(c);
    if (c=#27) then
    begin
      getkey(cc);
      if (cc='[') then
      begin
        getkey(cc);
        case cc of
          'A','C':if (color=255) then color:=0 else inc(color);
          'B','D':if (color=0) then color:=255 else dec(color);
        end;
        displaycolor(x,y,color);
      end;
    end;
  until (c=^M) or (c=^N) or (hangup);

  dosansion:=false;
  ctrljoff:=false;
  displaycolor(x,y,color);
  setc(oldco);
  nl;
end;

procedure switchyn(x,y:byte; var b:boolean);
begin
  ansig(x,y);
  b:=not b;
  sprompt('|w'+syn(b)+' ');
end;

function gc(s:string;b:word):char;
begin
  gc:=s[b];
end;

procedure mmkey(var s:string);
var s1:string;
    i,newarea:integer;
    c,cc:char;
    achange,bb:boolean;
begin
  s:='';
  if (buf<>'') then
    if (copy(buf,1,1)='`') then begin
      buf:=copy(buf,2,length(buf)-1);
      i:=pos('`',buf);
      if (i<>0) then begin
        s:=allcaps(copy(buf,1,i-1));
        buf:=copy(buf,i+1,length(buf)-i);
        nl;
        exit;
      end;
    end;

  if (not (onekey in thisuser.ac)) then
    input(s,60)
  else
    repeat
      achange:=FALSE;
      repeat
        getkey(c); c:=upcase(c);
      until ((c in [^H,^M,#32..#255]) or (hangup));
      if (c<>^H) then begin
        outkey(c);
      end;
      if (c='/') then begin
        s:=c;
        repeat
          getkey(c); c:=upcase(c);
        until (c in [^H,^M,#32..#255]) or (hangup);
        if (c<>^M) then begin
          case c of
            #225:bb:=bb; {* do nothing *}
          else
            outkey(c);
          end;
        end else
          nl;
        if (c in [^H,#127]) then prompt(' '+c);
        if (c in ['/',#225]) then begin
          bb:=systat^.localsec;
          cc:=gc(getstr(0),1);
          if (c=#225) then begin
            systat^.localsec:=TRUE;
            echo:=FALSE;
          end;
          setc(systat^.inputfieldcolor);
          input(s,60);
          systat^.localsec:=bb;
          echo:=TRUE;
        end else
          if (not (c in [^H,#127,^M])) then begin s:=s+c; nl; end;
      end else
      if (c=';') then begin
        input(s,60);
        s:=c+s;
      end else
      if (c in ['0'..'9']) and ((fqarea) or (mqarea)) then begin
        s:=c; getkey(c);
        if (c in ['0'..'9']) then begin
          print(c);
          s:=s+c;
        end;
        if (c=^M) then nl;
        if (c in [^H,#127]) then prompt(c+' '+c);
      end else
        if (c=^M) then nl
        else
        if (c<>^H) then begin
          s:=c;
          nl;
        end;
    until (not (c in [^H,#127])) or (hangup);
  if (pos(';',s)<>0) then                 {* "command macros" *}
    if (copy(s,1,2)<>'\\') then begin
      if (onekey in thisuser.ac) then begin
        s1:=copy(s,2,length(s)-1);
         if (copy(s1,1,1)='/') then s:=copy(s1,1,2) else s:=copy(s1,1,1);
         s1:=copy(s1,length(s)+1,length(s1)-length(s));
      end else begin
        s1:=copy(s,pos(';',s)+1,length(s)-pos(';',s));
        s:=copy(s,1,pos(';',s)-1);
      end;
      while (pos(';',s1)<>0) do s1[pos(';',s1)]:=^M;
      dm(' '+s1,c);
    end;
end;

function iReadDate(def : String) : String;
var S : String; Done : Boolean; N,P : Integer; C : Char;
begin
   if def = '' then S := '  /  /  ' else S := def;
   Done := False;
   sprompt(S);
   if def = '' then
   begin
      P := 1;
      sprompt(#8#8#8#8#8#8#8#8);
   end else P := 9;
   repeat
      GetKey(C);
      case C of
        '0'..'9' :
           case P of
             1,4,7,8 : if ((P = 1) and (C in ['0'..'1'])) or
                          ((P = 4) and ((value(copy(S,1,2))=2) and (C in ['0'..'2'])) or
                                       ((value(copy(S,1,2))<>2) and (C in ['0'..'3']))) or
                          (P = 7) or (P = 8) then
                       begin
                          sprompt(C);
                          S[P] := C;
                          Inc(P);
                       end;
             2,5     : if ((P = 2) and (((S[1]='0') and (C in ['1'..'9']))
                                       or
                                       ((S[1]='1') and (C in ['0'..'2']))))
                          or
                          ((P = 5) and ((S[4] in ['1'..'2']) or
                                       ((S[4]='0') and (C in ['1'..'9'])) or
                                       ((S[4]='3') and
                                         (((value(copy(S,1,2)) in [1,3,5,7,8,10,12]) and (C in ['0'..'1'])) or
                                          ((value(copy(S,1,2)) in [4,6,9,11]) and (C='0'))))))
                       then
                       begin
                          sprompt(C+'/');
                          S[P] := C;
                          S[P+1] := '/';
                          Inc(P,2);
                       end;
           end;
        #13 : if P = 9 then Done := True;
        #8  :
          case P of
            4,7     : begin
                         sprompt(#8#8#32#8);
                         S[P] := ' ';
                         Dec(P,2);
                      end;
           2,5,8,9  : begin
                         sprompt(#8#32#8);
                         S[P] := ' ';
                         Dec(P);
                      end;
          end;
      end;
   until (HangUp) or (Done);
   iReadDate := S;
   nl;
end;

function iReadPhone(def : String) : String;
var S : String; Done : Boolean; N,P : Integer; C : Char;
begin
   S := def;
   if S = '' then S := '   -   -    ';
   Done := False;
   sprompt(S);
   if Def = '' then
   begin
      P := 1;
      sprompt(#8#8#8#8#8#8#8#8#8#8#8#8);
   end else P := 13;
   repeat
      GetKey(C);
      case C of
        '0'..'9' :
           case P of
             1,2,5,6,9,10,11,12
                     : begin
                          sprompt(C);
                          S[P] := C;
                          Inc(P);
                       end;
             3       : begin
                          sprompt(C+'-');
                          S[P] := C;
                          Inc(P,2);
                       end;
             7       : begin
                          sprompt(C+'-');
                          S[P] := C;
                          Inc(P,2);
                       end;
           end;
        #13 : if P = 13 then Done := True;
        #8  :
          case P of
            5,9      : begin
                          sprompt(#8#8#32#8);
                          S[P] := ' ';
                          Dec(P,2);
                       end;
            2,3,6,7,10,11,12,13
                     : begin
                          sprompt(#8#32#8);
                          S[P] := ' ';
                          Dec(P);
                       end;
          end;
      end;
   until (HangUp) or (Done);
   iReadPhone := S;
   nl;
end;

function iReadTime(def : String) : String;
var S : String; Done : Boolean; N,P : Integer; C : Char;
begin
   S := def;
   if S = '' then S := '  :  ';
   Done := False;
   sprompt(S);
   if Def = '' then
   begin
      P := 1;
      sprompt(#8#8#8#8#8);
   end else P := 6;
   repeat
      GetKey(C);
      case C of
        '0'..'9' :
           case P of
             1,4,5
                     : if ((P = 1) and (C in ['0'..'2'])) or
                          ((P = 4) and (C in ['0'..'5'])) or
                          (P = 5) then
                       begin
                          sprompt(C);
                          S[P] := C;
                          Inc(P);
                       end;
             2       : begin
                          sprompt(C+':');
                          S[P] := C;
                          S[P+1] := ':';
                          Inc(P,2);
                       end;
           end;
        #13 : if P = 6 then Done := True;
        #8  :
          case P of
            4        : begin
                          sprompt(#8#8#32#8);
                          S[P] := ' ';
                          Dec(P,2);
                       end;
            2,5,6    : begin
                          sprompt(#8#32#8);
                          S[P] := ' ';
                          Dec(P);
                       end;
          end;
      end;
   until (HangUp) or (Done);
   iReadTime := S;
   nl;
end;

function iReadZipCode : String;
var S : String; Done : Boolean; N,P : Integer; C : Char;
begin
   S := '     -    ';
   Done := False;
   sprompt(S);
   P := 1;
   sprompt(#8#8#8#8#8#8#8#8#8#8);
   repeat
      GetKey(C);
      case C of
        '0'..'9' :
           case P of
             1,2,3,4,7,8,9,10
                     : begin
                          sprompt(C);
                          S[P] := C;
                          Inc(P);
                       end;
             5       : begin
                          sprompt(C+'-');
                          S[P] := C;
                          Inc(P,2);
                       end;
           end;
        #13 : if P = 11 then Done := True;
        #8  :
          case P of
            2,3,4,5,8,9,10,11
                     : begin
                          sprompt(#8#32#8);
                          S[P] := ' ';
                          Dec(P);
                       end;
            7        : begin
                          sprompt(#8#8#32#8);
                          S[P] := ' ';
                          Dec(P,2);
                       end;
          end;
      end;
   until (HangUp) or (Done);
   iReadZipCode := S;
   nl;
end;

function iReadPostalCode : String;
var S : String; Done : Boolean; N,P : Integer; C : Char;
begin
   S := '   -   ';
   Done := False;
   sprompt(S);
   P := 1;
   sprompt(#8#8#8#8#8#8#8);
   repeat
      GetKey(C);
      C:=Upcase(C);
      case C of
        '0'..'9','A'..'Z' :
           case P of
             1,2,5,6,7
                     : if ((C in ['A'..'Z']) and (P in [1,6])) or
                          ((C in ['0'..'9']) and (P in [2,5,7])) then
                       begin
                          sprompt(C);
                          S[P] := C;
                          Inc(P);
                       end;
             3       : if C in ['A'..'Z'] then
                       begin
                          sprompt(C+'-');
                          S[P] := C;
                          Inc(P,2);
                       end;
           end;
        #13 : if P = 8 then Done := True;
        #8  :
          case P of
            2,3,6,7,8
                     : begin
                          sprompt(#8#32#8);
                          S[P] := ' ';
                          Dec(P);
                       end;
            5        : begin
                          sprompt(#8#8#32#8);
                          S[P] := ' ';
                          Dec(P,2);
                       end;
          end;
      end;
   until (HangUp) or (Done);
   iReadPostalCode := S;
   nl;
end;

function iGetString(f, c, p, l, d, e : String) : String;
var Inp : tInFlag; Cha : tInChar; Len, plen : Byte;
begin
   iGetString := inputString;
   if (f = '') or (c = '') or (p = '') or (l = '') then Exit;
   case UpCase(F[1]) of
      'N' : Inp := inNormal;
      'C' : Inp := inCapital;
      'U' : Inp := inUpper;
      'L' : Inp := inLower;
      'M' : Inp := inMixed;
      'V' : Inp := inWeird;
      'W' : Inp := inWarped;
      'I' : Inp := inCool;
       else Inp := inNormal;
   end;
   case UpCase(C[1]) of
      'A' : Cha := chAlpha;
      'I' : Cha := chAnyNum;
      'F' : Cha := chFilename;
      'D' : Cha := chDirectory;
      'E' : Cha := chFileNoExt;
      'N' : Cha := chNumeric;
       else Cha := chNormal;
   end;
   Len := value(l);
   if (l = '*') or (Len = 0) then Len := 255;
   if d = '*' then d := inputString;
   plen := value(e);
   if (e = '*') or (plen = 0) then iGetString := iReadString(d,Inp,Cha,p,Len) else
                                   iGetString := iEditString(d,Inp,Cha,p,Len,plen);
end;

function iEditString(Def   : String;
                     iFl   : tInFlag;
                     iCh   : tInChar;
                     Opt   : String;
                     Len   : Byte;
                     pgLen : Byte) : String;

var
   Ch           : Char;
   Done         : Boolean;
   S            : String;
   pStr         : Integer;
   pSrt         : Integer;
   pCur         : Integer;
   xSrt         : Integer;

   optAbort     : Boolean;
   optNoIns     : Boolean;
   optPassword  : Boolean;
   optNoCR      : Boolean;
   optNoEdit    : Boolean;
   optMin       : Boolean;
   optSpace     : Boolean;
   optReq       : Boolean;
   optNoClean   : Boolean;
   optBackgr    : Boolean;

   Ins          : Boolean;

 procedure esInitOptions;
 begin
    opt := allcaps(opt);
    optAbort     := Pos(rsAbort,Opt)    > 0;
    optNoIns     := Pos(rsNoIns,Opt)    > 0;
    optPassword  := Pos(rsPassword,Opt) > 0;
    optNoCR      := Pos(rsNoCR,Opt)     > 0;
    optNoEdit    := Pos(rsNoEdit,Opt)   > 0;
    optMin       := Pos(rsMin,Opt)      > 0;
    optSpace     := Pos(rsSpace,Opt)    > 0;
    optReq       := Pos(rsReq,Opt)      > 0;
    optNoClean   := Pos(rsNoClean,Opt)  > 0;
    optBackgr    := Pos(rsBackGr,Opt)   > 0;
 end;

 procedure esAbort;
 begin
    if not optAbort then Exit;
    S := Def;
    Done := True;
 end;

 function xCur : Integer;
 begin
    xCur := WhereX-xSrt+1;
 end;

 procedure esPos;
 begin
    pCur := pStr-pSrt+1;
 end;

 procedure esProcessChar(var C : Char);
 begin
    case iFl of
    inCapital : begin
                   if (pStr > 1) and (not (UpCase(S[pStr-1]) in ['A'..'Z','0'..'9','''','"']))
                      then C := UpCase(C); { else C := LowCase(C);}
                   if pStr = 1 then C := UpCase(C);
                end;
      inUpper : C := UpCase(C);
      inLower : C := LowCase(C);
      inMixed : begin
                   if (pStr > 1) and (not (UpCase(S[pStr-1]) in ['A'..'Z','0'..'9','''','"']))
                      then C := UpCase(C) else C := LowCase(C);
                   if pStr = 1 then C := UpCase(C);
                end;
      inWeird : if UpCase(C) in ['A','E','I','O','U'] then C := LowCase(C) else
                   C := UpCase(C);
     inWarped : if UpCase(C) in ['A','E','I','O','U'] then C := UpCase(C) else
                   C := LowCase(C);
       inCool : if UpCase(C) = 'I' then C := LowCase(C) else C := UpCase(C);
    end;
 end;

 procedure esWrite(S : String);
 var i:byte;
 begin
    if (optPassword) and (length(s)>0) then
    begin
      for i:=1 to length(s) do
      begin
        sendcom1(gc(getstr(000),1));
        if (systat^.localsec) and (s[i]>#32) then s[i]:=gc(getstr(000),1);
        if wantout then if dosansion then dosansi(s[i]) else write(s[i]);
      end;
    end else
      spromptt(s,false,false);
 end;

 procedure oMoveRight(C : Byte);
 begin
    if C+WhereX > 80 then C := 80-WhereX;
    GotoXY(WhereX+C,WhereY);
    if (outcom) then
    begin
       if okavatar then pr1(^V^H+char(WhereY)+char(WhereX)) else
                        pr1(#27+'['+cstr(C)+'C');
    end;
 end;

 procedure oMoveLeft(C : Byte);
 begin
    if C > WhereX-1 then C := WhereX-1;
    GotoXY(WhereX-C,WhereY);
    if (outcom) then
    begin
       if okavatar then pr1(^V^H+char(WhereY)+char(WhereX)) else
                        pr1(#27+'['+cstr(C)+'D');
    end;
 end;

 procedure oPosX(X : Integer);
 var P : Integer;
 begin
    P := WhereX;
    if X > P then oMoveRight(X-P) else
    if X < P then oMoveLeft(P-X);
 end;

 procedure esRedraw;
 begin
    esPos;
    oPosX(xSrt);
    esWrite(mlnnomci(Copy(S,pSrt,pgLen),pgLen));
    oPosX(xSrt+pCur-1);
 end;

 procedure esRedrawToEol;
 begin
    esPos;
    esWrite(mlnnomci(Copy(S,pStr,pgLen-pCur+1),pgLen-pCur+1));
    oPosX(xSrt+pCur-1);
 end;

 procedure esScrollRight;
 begin
    esPos;
    if pgLen > 5 then Inc(pSrt,5) else Inc(pSrt,1);
    if pSrt > Length(S) then pSrt := Length(S);
    if pSrt > Len then pSrt := Len;
    esPos;
    esRedraw;
 end;

 procedure esScrollLeft;
 begin
    esPos;
    if pgLen > 5 then Dec(pSrt,5) else Dec(pSrt,1);
    if pSrt < 1 then pSrt := 1;
    esPos;
    esRedraw;
 end;

 procedure esAddChar(Ch : Char);
 begin
    if (Length(S) >= Len) or ((pStr = 1) and (Ch = ' ') and (not optSpace)) then Exit;

    esProcessChar(Ch);

    if not (Ch in iCh) then Exit;

    esPos;
    if pCur > pgLen then esScrollRight;

    if pStr > Length(S) then
    begin
       Inc(pStr);
       esWrite(Ch);
       S := S+Ch;
       esPos;
    end else
    if Ins then
    begin
       Insert(Ch,S,pStr);
       esRedrawToEol;
       Inc(pStr);
       Inc(pCur);
       esWrite(Ch);
    end else
    begin
       S[pStr] := Ch;
       Inc(pStr);
       Inc(pCur);
       esWrite(Ch);
    end;

 end;

 procedure esBackSpace;
 begin
    if Length(S) = 0 then Exit;
    if (pCur > 1) and (pStr = Length(S)+1) then
    begin
       Delete(S,Length(S),1);
       sprompt(#8#32#8);
       Dec(pStr);
    end else
    if (Length(S) > 0) and (pCur = 1) and
       (pStr = Length(S)+1) and (pSrt > 1) then
    begin
       Delete(S,Length(S),1);
       pStr := Length(S)+1;
       esScrollLeft;
    end else if pStr > 1 then
    begin
       Delete(S,pStr-1,1);
       Dec(pStr);
       if pCur = 1 then esScrollLeft else
       begin
          Dec(pCur);
          sprompt(#8);
          esRedrawToEol;
       end;
    end;
 end;

 procedure esDeleteChar;
 begin
    if (pStr = 0) or (pStr > Length(S)) or (Length(S) = 0) then Exit;
    Delete(S,pStr,1);
    esRedrawToEol;
 end;

 procedure esCursorRight;
 begin
    if pStr = Length(S)+1 then Exit;
    esPos;
    if pCur = pgLen then esScrollRight;

    Inc(pStr);
    oMoveRight(1);
    esPos;
 end;

 procedure esCursorLeft;
 begin
    if pStr = 1 then Exit;
    esPos;
    if pCur = 1 then esScrollLeft;

    Dec(pStr);
    oMoveLeft(1);
    esPos;
 end;

 procedure esCursorHome;
 begin
    if pStr = 1 then Exit;
    pStr := 1;
    pSrt := 1;
    pCur := 1;
    esPos;
    esRedraw;
 end;

 procedure esCursorEnd;
 begin
    if pStr > Length(S) then Exit;
    esPos;
    pStr := Length(S)+1;
    pSrt := Length(S)-pgLen+2;
    if pSrt < 1 then pSrt := 1;
    pCur := pgLen-1;
    esRedraw;
 end;

 procedure esTab;
 var N : Byte;
 begin
    for N := 1 to 4 do esAddChar(' ');
 end;

 procedure esClearEol;
 begin
    if (Length(S) = 0) or (pStr = Length(S)+1) then Exit;
    S[0] := Chr(pStr-1);
    esRedrawToEol;
 end;

 procedure esClearItAll;
 begin
    if Length(S) = 0 then Exit;
    S := '';
    pStr := 1;
    pSrt := 1;
    pCur := 1;
    esRedraw;
 end;

 procedure esBackground;
 begin
    setc(systat^.inputfieldcolor);
    sprompt(sRepeat(' ',Len));
    oPosX(xSrt);
 end;

begin
   esInitOptions;
   Ins := (not optNoEdit) and (not optNoIns);
   Done := False;
   S := Def;
   xSrt := WhereX;
   if pgLen = 0 then
   begin
      pgLen := Len;
      if pgLen+xSrt > 79 then pgLen := 79-xSrt+1;
   end;
   if optBackgr then esBackground;
   for pStr := 1 to Length(S) do
   begin
      esProcessChar(S[pStr]);
      if not (S[pStr] in iCh) then S[pStr] := ' ';
   end;
   if Length(S) > Len then Delete(S,Len+1,255);
   pStr := Length(S)+1;
   pSrt := Length(S)-pgLen+1;
   if pSrt < 1 then pSrt := 1;
   esPos;
   esWrite(Copy(S,pSrt,pgLen));

   repeat
      esPos;
      GetKey(Ch);
      case Ch of
        #27       : begin
                      getkey(ch);
                      if (ch='[') then
                      begin
                        getkey(ch);
                        case ch of
                          'C': if not optNoEdit then esCursorRight;
                          'D': if not optNoEdit then esCursorLeft;
                          'H': if not optNoEdit then esCursorHome;
                          'K': if not optNoEdit then esCursorEnd;
                        end;
                      end;
                    end;
{            #117 : if not optNoEdit then esClearEol; }
        ^V        : if (not optNoEdit) and (not optNoIns) then Ins := not Ins;
        #127      : if not optNoEdit then esDeleteChar;
        ^Z,
        #9        : esTab;
        #8        : esBackSpace;
        #13       : if ((not optMin) or (Length(S) > 0)) and
                       ((not optReq) or (Length(S) = Len)) then Done := True;
        ^X,^Y     : if not optNoEdit then esClearItAll;
        #32..#254 : esAddChar(Ch);
      end;
   until (HangUp) or (Done);
   if not optNoCR then nl;
   if not optNoClean then S := CleanUp(S);
   iEditString := S;
end;

function iReadString(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Len : Byte) : String;
begin
   iReadString := iEditString(Def,iFl,iCh,Opt,Len,0);
end;

end.
