{$A+,B-,D-,E-,F+,G+,I+,L-,N-,O-,R-,S-,V-,X+}

program network_configuration;

uses crt,dos;

{$I i_194.inc}

var fidor:fidorec;
    ff:file of fidorec;
    systat:systatrec;
    fs:file of systatrec;
    s:string;
    ch:char;

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

function syn(b:boolean):string;
begin
  if b then syn:='Yes' else syn:='No';
end;

function line:string;
var s:string[79];
begin
  fillchar(s,sizeof(s),'Ä');
  s[0]:=chr(79);
  line:=s;
end;

function input(x,y,width:byte; s:string):string;
var
  curpos:byte;
  i:byte;
  olds:string;

  procedure redraw;
  begin
    gotoxy(x,y);
    write(s);
    clreol;
    gotoxy(x+curpos-1,y);
  end;

begin
  olds:=s;
  curpos:=length(s)+1;
  gotoxy(x,y);
  textattr:=15;
  write(s);

  repeat

    ch:=readkey;

    case ch of
      #32..#255:
         if curpos<=width then
         begin
             write(ch);
             if curpos<length(s) then
                 s[curpos]:=ch
             else
                 s:=s+ch;
             inc(curpos);
         end;
      #0:if (keypressed) then
         begin
             ch:=readkey;
             case ch of
             {r} #77:if curpos<length(s)+1 then
                     begin
                       inc(curpos);
                       redraw;
                     end;
             {l} #75:if curpos>1 then
                     begin
                       dec(curpos);
                       redraw;
                     end;
             end;
             ch:=#0;
         end;
      ^H:if curpos>1 then
         begin
            delete(s,curpos-1,1);
            dec(curpos);
            redraw;
         end;
    end;

  until ch=^M;

  textattr:=7;
  redraw;

  input:=s;
end;

begin

  textmode(co80);
  textattr:=15; write('I_MSG');
  textattr:=8;  write(' - ');
  textattr:=15; writeln('Illusion Message Area Configuration version '+ver);
  textattr:=7;  writeln('Copyright 1992-1996, Illusion Development.  All rights reserved.');
  textattr:=8;  writeln(line);
  textattr:=7;  writeln;
  window(1,5,80,25);

  assign(fs,'ILLUSION.CFG');
  {$I-} reset(fs); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Cannot find ILLUSION.CFG.');
    halt;
  end;
  read(fs,systat);
  close(fs);

  assign(ff,systat.datapath+'NETWORK.DAT');
  {$I-} reset(ff); {$I+}
  if (ioresult<>0) then
  begin
    writeln('Cannot find NETWORK.DAT.');
    halt;
  end;
  read(ff,fidor);
  close(ff);

  repeat
    with fidor do
    begin
      gotoxy(1,1);
      s:=cstr(zone)+':'+cstr(net)+'/'+cstr(node)+'.'+cstr(point);
      write('A. Network address : '+s); clreol; writeln;
      write('B. Origin line     : '+origin); clreol; writeln;
      write('C. Base Mail Path  : '+mailpath); clreol; writeln;
      write('D. Echomail Toss   : '+echotoss); clreol; writeln;
      write('E. Echomail Scan   : '+echoscan); clreol; writeln;
      write('F. Post-proc. cmd  : '+postproccmd); clreol; writeln;
      write('G. Log File        : '+logname); clreol; writeln;
      writeln;
      write('H. Strip box/center codes : '+syn(strip)); clreol; writeln;
      write('I. Add tear/origin lines  : '+syn(addtear)); clreol; writeln;
      writeln;
      write('J. Default Text Color   : '+text_color); clreol; writeln;
      write('K. Default Quote Color  : '+quote_color); clreol; writeln;
      write('L. Default Tear Color   : '+tear_color); clreol; writeln;
      write('M. Default Origin Color : '+origin_color); clreol; writeln;
      writeln;
      write('N. Messages Path   : '+systat.msgpath); clreol; writeln;
      writeln;
      writeln('Q. Quit and Save');
      gotoxy(80,23);
      ch:=upcase(readkey);
      case ch of
        'A':begin
              clrscr;
              writeln('Current default network address: '+s);
              writeln;
              write('Enter your zone number : ');
              s:=input(26,3,5,'');
              if (s<>'') then zone:=value(s);
              writeln;
              write('Enter your net number  : ');
              s:=input(26,4,5,'');
              if (s<>'') then net:=value(s);
              writeln;
              write('Enter your node number : ');
              s:=input(26,5,5,'');
              if (s<>'') then node:=value(s);
              writeln;
              write('Enter your point number: ');
              s:=input(26,6,5,'');
              if (s<>'') then point:=value(s);
            end;
        'B':origin:=input(22,2,50,origin);
        'C':begin
              mailpath:=input(22,3,40,mailpath);
              if (mailpath<>'') or (mailpath<>' ') then
                if (copy(mailpath,length(mailpath),1)<>'\') then
                  mailpath:=mailpath+'\';
            end;
        'D':echotoss:=input(22,4,40,echotoss);
        'E':echoscan:=input(22,5,40,echoscan);
        'F':postproccmd:=input(22,6,40,postproccmd);
        'G':logname:=input(22,7,40,logname);
        'H':strip:=not strip;
        'I':addtear:=not addtear;
        'J':begin
              s:=input(27,12,1,text_color);
              text_color:=s[1];
            end;
        'K':begin
              s:=input(27,13,1,quote_color);
              quote_color:=s[1];
            end;
        'L':begin
              s:=input(27,14,1,tear_color);
              tear_color:=s[1];
            end;
        'M':begin
              s:=input(27,15,1,origin_color);
              origin_color:=s[1];
            end;
        'N':systat.msgpath:=input(22,17,40,systat.msgpath);
      end;
    end;
  until ch='Q';
  reset(ff);
  write(ff,fidor);
  close(ff);
  reset(fs);
  write(fs,systat);
  close(fs);
  clrscr;
  writeln('Saved.');
end.
