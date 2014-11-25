(*****************************************************************************)
(* Illusion BBS - Chat                                                       *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit chatstuf;

INTERFACE

uses crt, dos, common, misc2, misc3;

Const
  wcolor:Boolean=TRUE;  { last key pressed by sysop? }
Var
  rclrs,fadeit:boolean;

procedure chatfile(b:boolean);
function  chinkey:char;

procedure SplitScreenChat;
procedure NormalChat;
procedure chat(split:boolean);

IMPLEMENTATION

procedure chatfile(b:boolean);
var bf:file of byte;
    s:string[91];
    cr:boolean;
begin
  s:='chat';
  if (thisuser.chatseperate) then s:=s+cstr(usernum);
  s:=systat^.trappath+s+'.'+cstr(nodenum);
  if (not b) then begin
    if (cfo) then begin
      commandline('Chat Capturing OFF');
      cfo:=FALSE;
      if (textrec(cf).mode<>fmclosed) then close(cf);
    end;
  end else begin
    cfo:=TRUE;
    if (textrec(cf).mode=fmoutput) then close(cf);
    assign(cf,s); assign(bf,s);
    cr:=FALSE;
    {$I-} reset(cf); {$I+}
    if (ioresult<>0) then
      rewrite(cf)
    else begin
      close(cf);
      append(cf);
    end;
    writeln(cf,^M^J^M^J+dat+^M^J+'[ Recorded with user: '+nam+^M^J+'------------------------------------'+^M^J);
    commandline('Chat Capture ON ('+s+')');
  end;
end;

function chinkey:char;
const chatclrs:array[0..3,1..2] of integer=((15,4),(9,12),(3,14),(11,15));
var c:char; cc:integer;
begin
  c:=#0; chinkey:=#0;
  if (keypressed) then
  begin
    c:=readkey;
    if (rclrs) then begin
      cc:=random(4); setc(chatclrs[cc][1]);
    end else
      if (not wcolor) then cl(systat^.sysopcolor);
    wcolor:=TRUE;
    if (wherecurrent<>normal) then
    begin
      skey1(c);
      c:=#1;
    end else
    if (c=#0) and (keypressed) then
    begin
      c:=readkey;
      skey1(c);
      if (c=#68) then c:=#1 else c:=#0;
      if (buf<>'') then
      begin
        c:=buf[1];
        buf:=copy(buf,2,length(buf)-1);
      end;
    end;
    chinkey:=c;
  end else
    if ((not localioonly) and (incom) and (not com_rx_empty)) then
    begin
      c:=ccinkey1;
      if (rclrs) then begin
        cc:=random(4); setc(chatclrs[cc][2]);
      end else
        if (wcolor) then cl(systat^.usercolor);
      wcolor:=FALSE;
      chinkey:=c;
    end;
end;

{----------------------------------------------------------------------------}

procedure SplitScreenChat;

type linetype = array[1..50] of string[80];
     string8 = string[8];

var lines   : ^linetype;                   { stored lines    }
    x,y     : array[1..2] of byte;         { x/y coord's     }
    cx,cy   : byte;                        { current x/y     }
    numlines: byte;                        { number of lines }
    c       : char;                        { input char      }
    w       : byte;                        { temp. for windows }
    cv,cc   : byte;                        { counting var    }
    wrap    : astr;                        { linewrap        }
    lasttime: string8;                     { last time update}

procedure ansigC(x,y:byte);
begin
  ansig(x,y);
  cx:=x; cy:=y;
end;

procedure switch;
var w,newy:byte;
begin
  if wcolor then w:=2 else w:=1;
  newy:=y[w];
  if newy<>cy then begin
    if wcolor then w:=1 else w:=2;
    ansigC(x[w],y[w]);
    sprompt('_');
    if wcolor then w:=2 else w:=1;
    ansigC(x[w],y[w]);
  end;
end;

Procedure ClearEOL;
begin
  if ((okansi) and (outcom)) then begin
    if (okavatar) then pr1(^V^G) else pr1(#27+'[K');
  end;
  clreol;
end;

procedure writeline(yv:integer);
begin
  ansigC(1,yv);
  if lines^[yv]<>'' then begin
    sprompt(lines^[yv]); cleareol;
    inc(cx,length(lines^[yv]));
  end else
    cleareol;
end;

function chattime:string8;
var s:string[11];
begin
  s:=propertime;
  chattime:=copy(s,1,5)+copy(s,9,3);
end;

procedure updatetime;
var x,y,z:byte;
begin
  x:=cx; y:=cy; z:=curco;
  ansigC(2,numlines);
  setc(31);
  lasttime:=chattime;
  sprompt(lasttime);
  setc(z);
  ansigC(x,y);
end;

procedure redrawscreen;
var yv:byte;
begin
  setc(15);
  cls;
  setc(31);
  sprompt(mln(' '+nam+' ['+cstr(thisuser.pagelen)+' lines]',79));
  ansigC(1,numlines div 2 + 1);
  sprompt(mln(' '+systat^.sysopname+' ['+cstr(linemode-2)+' lines]',79));
  ansigC(1,numlines);
  sprompt('          '+mln('³ Mode: ['+cstr(numlines)+' lines] ^Q:Quit, ^L:Redraw, ^N:New Window, ^U:Help',69));
  setc(7);

  cl(systat^.usercolor);
  for yv:=2 to ((numlines-3) div 2 + 1) do
    if lines^[yv]<>'' then writeline(yv);

  cl(systat^.sysopcolor);
  for yv:=((numlines-3) div 2 + 3) to (numlines - 1) do
    if lines^[yv]<>'' then writeline(yv);

  if wcolor then cl(systat^.sysopcolor) else cl(systat^.usercolor);

  switch; updatetime;
end; {proc redrawscreen}

procedure moveup(w:byte);
var yv,st,sp:byte;
begin
  if w=1 then begin
    st:=(numlines-3) div 2 - 4;
    sp:=(numlines-3) div 2 + 1;
  end else begin
    st:=numlines-6;
    sp:=numlines-1;
  end;

  for yv:=st to sp do begin
    lines^[yv-5]:=lines^[yv];
    lines^[yv]:='';
  end;

  y[w]:=st+1;
end;

procedure redrawwindow(w:byte);
var yv,st,sp:byte;
begin
  if w=1 then begin
    st:=2;
    sp:=(numlines-3) div 2 + 1;
  end else begin
    st:=(numlines-3) div 2 + 3;
    sp:=(numlines-1);
  end;

  for yv:=st to sp do writeline(yv);
end; {proc redrawwindow}

procedure help;
begin
  cls;
  sprint('|WSplit Screen Chat Help');
  nl;
  sprint('|W^U    |wHelp');
  sprint('|W^Q    |wQuit');
  sprint('|W^L    |wRedraw screen');
  sprint('|W^N    |wNew window');
  sprint('|W^O    |wHangup');
  sprint('|W^X    |wErase line');
  sprint('|W^W    |wErase last word');
  sprint('|W/rclrs  |wRandom colors');
  nl;
  pausescr;
  redrawscreen;
end;

begin
  numlines:=linemode-2;
  if thisuser.pagelen<numlines then numlines:=thisuser.pagelen;
  if (numlines mod 2=0) then dec(numlines);

  x[1]:=1; x[2]:=1;
  y[1]:=2; y[2]:=(numlines-3) div 2 + 3;
  wcolor:=TRUE;
  new(lines);
  fillchar(lines^,sizeof(lines^),#0);
  redrawscreen;

  repeat
    repeat
      getkey(c);
      if wcolor then w:=2 else w:=1;
      case ord(c) of
        32..126,128..255:
          begin
            switch;
            if (x[w]<79) then begin
              lines^[y[w]][x[w]]:=c;
              inc(x[w]);
              outkey(c); if (trapping) then write(trapfile,c); inc(cx);
            end;
          end;
        13:
          begin
            switch; prompt(' '); dec(x[w]); inc(cx);
          end;
        127,8:
          begin
            switch;
            if (x[w]>1) then begin
              dec(x[w]); prompt(' '^H^H' '^H); dec(cx);
            end;
          end;
        24:
          begin
            switch;
            prompt(' '^H);
            for cv:=1 to x[w]-1 do begin prompt(^H' '^H); dec(cx); end;
            x[w]:=1;
          end;
        23:
          begin
            switch;
            if x[w]>1 then begin
              prompt(' '^H);
              repeat
                dec(x[w]); prompt(^H' '^H); dec(cx);
              until (x[w]=1) or (lines^[y[w]][x[w]]=' ');
            end;
          end;
        7:if (outcom) then sendcom1(^G);
        12:
          begin
            lines^[y[1]][0]:=chr(x[1]-1);
            lines^[y[2]][0]:=chr(x[2]-1);
            redrawscreen;
          end;
        14:
          begin
            if w=1 then begin
              for cv:=2 to ((numlines-3) div 2 + 1) do lines^[cv]:='';
              y[1]:=2;
            end else begin
              for cv:=((numlines-3) div 2 + 3) to (numlines-1) do lines^[cv]:='';
              y[2]:=(numlines-3) div 2 + 3;
            end;
            redrawwindow(w);
            x[w]:=1;
            ansigC(x[w],y[w]);
          end;
        17:
          begin
            ch:=FALSE;
          end;
        15:
          begin
            ansigC(1,numlines);
            setc(31); cleareol;
            sprompt(' Ctrl-O (Drop) received.');
            sleep(750);
            cls;
            hangup:=TRUE;
          end;
        21:
          begin
            lines^[y[1]][0]:=chr(x[1]-1);
            lines^[y[2]][0]:=chr(x[2]-1);
            Help;
          end;
      end; {case}

      if lasttime<>chattime then updatetime;
    until ((c=^M) or (x[1]=79) or (x[2]=79) or (hangup) or (not ch));

    lines^[y[w]][0]:=chr(x[w]);
    wrap:='';

    if (c<>^M) and (ch) and (not hangup) then begin
      cv:=x[w]-1;
      while (cv>0) and (lines^[y[w]][cv]<>' ') do dec(cv);
      if (cv>(x[w] div 2)) and (cv<>x[w]-1) then begin
        wrap:=copy(lines^[y[w]],cv+1,x[w]-cv-1);
        for cc:=x[w]-2 downto cv do prompt(^H);
        for cc:=x[w]-2 downto cv do prompt(' ');
        lines^[y[w]][0]:=chr(cv-1);
      end;
    end;

    if allcaps(lines^[y[w]])='/RCLRS' then rclrs:=not rclrs;

    if (ch) and (not hangup) then begin
      inc(y[w]); x[w]:=1;
      if w=1 then
        cc:=(numlines-3) div 2 + 1
      else
        cc:=(numlines-1);

      if (y[w]>cc) then begin
        moveup(w);
        lines^[y[w]]:=wrap;
        redrawwindow(w); inc(x[w],length(wrap));
      end else begin
        lines^[y[w]]:=wrap;
        writeline(y[w]); inc(x[w],length(wrap));
      end;

      ansigC(x[w],y[w]);
    end;

  until ((not ch) or (hangup));

  dispose(lines);
  cls;
end; {proc splitscreenchat}

{----------------------------------------------------------------------------}

procedure inli1(var s:string);             (* Input routine for chat *)
var cv,cc,cp,g,i:integer;
    c,c1:char; f:string;
begin
  cp:=1;
  s:='';
  if (ll<>'') then begin
    prompt(ll);
    s:=ll; ll:='';
    cp:=length(s)+1;
  end;
  repeat
    getkey(c); checkhangup;
    case ord(c) of
      32..123,125..126,128..255:
              if (cp<79) then begin
                s[cp]:=c; inc(cp);
                if fadeit then begin
                  f[1]:=c; f[0]:=chr(1);
                  fadein(30,f);
                end else outkey(c);
                if (trapping) then write(trapfile,c);
              end;
      124:if okansi then begin
           getkey(c1);
           if c1 in ['0'..'9'] then cl(ord(c1)-48) else
            if (pos(c1,'kbgcrmywKBGCRMYW')<>0) then cl(ord(c1));
         end;
      27:if (cp<79) then begin
           s[cp]:=c; inc(cp);
           outkey(c);
           if (trapping) then write(trapfile,c);
         end;
      127,8:
        if (cp>1) then begin
          dec(cp);
          prompt(^H' '^H);
        end;
      24:begin
           for cv:=1 to cp-1 do prompt(^H' '^H);
           cp:=1;
         end;
       7:if (outcom) then sendcom1(^G);
      23:if cp>1 then
           repeat
             dec(cp);
             prompt(^H' '^H);
           until (cp=1) or (s[cp]=' ');
       9:begin
           cv:=5-(cp mod 5);
           if (cp+cv<79) then
             for cc:=1 to cv do begin
               s[cp]:=' ';
               inc(cp);
               prompt(' ');
             end;
         end;
  end;
  until ((c=^M) or (cp=79) or (hangup) or (not ch));
  if (not ch) then begin c:=#13; ch:=FALSE; end;
  s[0]:=chr(cp-1);
  if (c<>^M) then begin
    cv:=cp-1;
    while (cv>0) and (s[cv]<>' ') and (s[cv]<>^H) do dec(cv);
    if (cv>(cp div 2)) and (cv<>cp-1) then begin
      ll:=copy(s,cv+1,cp-cv);
      for cc:=cp-2 downto cv do prompt(^H);
      for cc:=cp-2 downto cv do prompt(' ');
      s[0]:=chr(cv-1);
    end;
  end;
  nl;
end;

procedure NormalChat;
var s,xx:string;
    t1:real;
    i:integer;
begin
  cl(systat^.sysopcolor); wcolor:=TRUE;
  repeat
    inli1(xx);
    if (xx[1]='/') then xx:=allcaps(xx);
    if (copy(xx,1,6)='/TYPE ') and (cso) then begin
      s:=copy(xx,7,length(xx));
      if (s<>'') then begin
        printfile(s);
        if (nofile) then sprint('<File Not Found>');
      end;
    end
    else if ((xx='/HELP') or (xx='/?')) then begin
                nl;
                sprint('|WIllusion Chat Commands');
                nl;
  if (cso) then sprint('|W/TYPE d:\path\filename.ext |wType a file');
                sprint('|W/BYE                       |wHang up');
                sprint('|W/CLS                       |wClear screen');
                sprint('|W/PAGE                      |wPage SysOp and user');
                sprint('|W/RCLRS                     |wToggle random colors');
                sprint('|W/FADE                      |wToggle fade-in');
                sprint('|W/SPIN                      |wToggle spinning cursor');
                sprint('|W/Q                         |wExit chat mode');
                nl;
    end
    else if (xx='/CLS') then cls
    else if (xx='/PAGE') then begin
      for i:=650 to 700 do begin
        sound(i); delay(2);
        nosound;
      end;
      repeat
        dec(i); sound(i); delay(1);
        nosound;
      until (i=200);
      prompt(^G^G);
    end

    else if (xx='/ACS') then begin
      prt('ACS: '); mpl(20); inputl(s,20);
      if (aacs(s)) then sprint('You have access to that!')
        else sprint('You DO NOT have access to that.');
    end

    else if (xx='/RCLRS') then
      rclrs:=not rclrs

    else if (xx='/FADE') then
      fadeit:=not fadeit

    else if (xx='/SPIN') then
      getkeyspin:=not getkeyspin

    else if (xx='/BYE') then begin
      print('Dropping Carrier ...');
      hangup:=TRUE;
    end
    else if (xx='/Q') then begin
      t1:=timer;
      while (abs(t1-timer)<0.6) and (empty) do;
      if (empty) then begin ch:=FALSE; print('Chat Ended ...'); end;
    end;
    if (cfo) then writeln(cf,xx);
  until ((not ch) or (hangup));
end; {proc normalchat}

{----------------------------------------------------------------------------}

procedure chat(split:boolean);
var chatstart,chatend,tchatted:datetimerec;
    savecho,savspin,savwantout:boolean;
    s:astr;
begin
  nosound;
  getdatetime(chatstart);
  dosansion:=FALSE;

  rclrs:=FALSE;  fadeit:=FALSE;
  ch:=TRUE;      chatcall:=FALSE;

  savecho:=echo;       echo:=TRUE;
  savspin:=getkeyspin; getkeyspin:=FALSE;
  savwantout:=wantout; wantout:=TRUE;

  if (systat^.autochatopen) or (thisuser.chatauto) then
    chatfile(TRUE);

  exclude(thisuser.ac,alert);

  if (chatr<>'') then begin
    commandline(chatr); print(' '); chatr:='';
  end;

  nl; nl;
  spstr(168); nl;

  if (not okansi) or (thisuser.pagelen<23) then split:=FALSE;
  if split then SplitScreenChat else NormalChat;

  getkeyspin:=FALSE;
  nl; spstr(169); nl;

  getdatetime(chatend);
  timediff(tchatted,chatstart,chatend);

  freetime:=freetime+dt2r(tchatted);

  tleft;
  s:='Chatted for '+longtim(tchatted);
  if (cfo) then begin
    s:=s+'  [ Recorded in CHAT';
    if (thisuser.chatseperate) then s:=s+cstr(usernum);
    s:=s+'.MSG ]';
  end;
  sysoplog(s);

  if ((hangup) and (cfo)) then
  begin
    writeln(cf);
    writeln(cf,'NO CARRIER');
    writeln(cf);
    writeln(cf,'>> Carrier lost ...');
    writeln(cf);
  end;

  if (cfo) then chatfile(FALSE);

  ch:=FALSE; echo:=savecho; getkeyspin:=savspin; wantout:=savwantout;
  commandline('');
end;

end.
