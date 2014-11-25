(*****************************************************************************)
(* Illusion BBS - Pull down menu routines                                    *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit pdmenu;

interface

uses
  crt, dos,
  common, myio;

const
  max_pull_topics=45;
  max_pull_width=35;
  max_mainpicks=5;
  max_subpicks=15;
  mainind='\';           {symbol that indicates main menu description}

type
  strscreen=string[80];
  pull_array=array [1..max_pull_topics] of string[max_pull_width];
  menudisplay=record
    topx:byte;
    topy:byte;
    fcol:byte;
    bcol:byte;
    mfcol:byte;
    mbcol:byte;
    hfcol:byte;
    hbcol:byte;
    borcol:byte;
    gap:byte;
    leftchar:char;
    rightchar:char;
  end;

var pttt:menudisplay;

procedure pulldown(definition:pull_array; var pickm,picks:byte);

implementation

procedure default_settings;
begin
  with pttt do
  begin
    topy:=1;
    topx:=6;
    gap:=2;             {gap between picks}
    leftchar:=#016;     {left-hand topic highlight character}
    rightchar:=#017;    {right-hand topic highlight character}
    fcol:=white;        {normal option foreground color}
    bcol:=blue;         {normal option background color}
    mfcol:=white;       {highlight fgnd col for main pick when sub-menu displayed}
    mbcol:=lightgray;   {highlight bgnd col for main pick when sub-menu displayed}
    hfcol:=white;       {highlighted option foreground}
    hbcol:=lightgray;   {highlighted option background}
    borcol:=lightblue;  {border foreground color}
  end;
end;

procedure fastwrite(col,row,attr:byte; st:strscreen);
begin
  gotoxy(col,row);
  textattr:=attr;
  write(st);
end;

function attr(f,b:byte):byte;
begin
  attr:=(b shl 4) or f;
end;

function replicate(n:byte; character:char):strscreen;
var tempstr:strscreen;
begin
  fillchar(tempstr[1],n,character);
  tempstr[0]:=chr(n);
  replicate:=tempstr;
end;

procedure cleartext(x1,y1,x2,y2,f,b:integer);
var y:integer;
begin
  if x2>80 then x2:=80;
  for y:=y1 to y2 do fastwrite(x1,y,attr(f,b),replicate(x2-x1+1,' '));
end;

procedure box(x1,y1,x2,y2,f,b,boxtype:integer);
var sz:byte;
begin
  sz:=textattr;
  textattr:=attr(f,b);
  myio.box(boxtype,x1,y1,x2,y2);
  window(1,1,80,linemode);
  textattr:=sz;
end;

procedure fbox(x1,y1,x2,y2,f,b,boxtype:integer);
begin
  box(x1,y1,x2,y2,f,b,boxtype);
  cleartext(x1+1,y1+1,x2-1,y2-1,f,b);
end;

function getkey:char;
var
  h,m,s,s100:word;
  n1,n2:longint;
  finished:boolean;
  ch:char;
begin
  finished:=false;
  gettime(h,m,s,s100);
  n1:=(((h*60)+m)*60)+s;
  n2:=(((h*60)+m)*60)+s;

  repeat
    gettime(h,m,s,s100);
    n2:=(((h*60)+m)*60)+s;
  until (keypressed) or (finished) or (n2-n1>20);

  if (n2-n1>20) then
  begin
    finished:=true;
    ch:=#27;
  end;
  while not finished do
  begin
    finished:=true;
    ch:=readkey;
    if ch=#0 then
    begin
      ch:=readkey;
      case ord(ch) of
        15,16..25,30..38,44..50,59..68,71..73,
        75,77,79..127:ch:=chr(ord(ch)+128);
        else finished:=false;
      end;
    end;
  end;
  getkey:=ch;
end;

procedure pulldown(definition:pull_array; var pickm,picks:byte);
const
  cursup=#200  ;  cursdown=#208  ;  cursleft=#203  ;   cursright=#205;
  homekey=#199 ;  endkey  =#207  ;  esc     =#027  ;   enter    =#13;
  f1     =#187 ;
type
  sub_details=record
    text:array[0..max_subpicks] of string[30];
    total:byte;
    width:byte;
    lastpick:byte;
  end;
var
  submenu:array [1..max_mainpicks] of sub_details;
  tot_main:byte;
  main_wid:byte;
  finished:boolean;
  chm:char;
  x1,y1,x2,y2:byte;
  saved_screen:windowrec;
  i:integer;

  procedure save_screen;
  begin
    savescreen(saved_screen,1,1,80,linemode);
  end;

  procedure partrestorescreen(x1,y1,x2,y2:byte);
  var i:word;
      y,x:byte;
  begin
    for y:=y1 to y2 do
      for x:=x1 to x2 do
      begin
        i:=160*(y-1)+2*(x-1);
        inline($fa);
        mem[vidseg:i]:=saved_screen[i];
        mem[vidseg:i+1]:=saved_screen[i+1];
        inline($fb);
      end;
  end;

  procedure restore_screen;
  begin
    removewindow(saved_screen);
  end;

  procedure load_menu_parameters;
  var i,maj,min,widest:integer;
      instr:string[30];
      finished:boolean;
  begin
    fillchar(submenu,sizeof(submenu),#0);
    tot_main:=0;
    maj:=0;
    widest:=0;
    i:=0;
    finished:=false;
    while (i<max_pull_topics) and (finished=false) do
    begin
      inc(i);
      if definition[i]<>'' then
      begin
        instr:=definition[i];
        if instr[1]=mainind then
        begin
          if maj<>0 then
          begin
            submenu[maj].total:=min;
            submenu[maj].width:=widest;
          end;
          if instr=mainind+mainind then
          begin
            tot_main:=maj;
            finished:=true;
          end;
          inc(maj);
          delete(instr,1,1);
          submenu[maj].text[0]:=instr;
          min:=0;
          widest:=0;
        end else
        begin
          inc(min);
          submenu[maj].text[min]:=instr;
          if length(instr)>widest then widest:=length(instr);
        end;
      end;
    end;
  end;

  procedure display_main_picks(no:byte; col:byte);
  var x,i:byte;
  begin
    x:=1;
    if no=1 then
      x:=x+pttt.topx+pttt.gap
    else
    begin
      for i:=1 to no-1 do x:=x+length(submenu[i].text[0])+pttt.gap;
      x:=x+pttt.topx+pttt.gap;
    end;
    if col>0 then
      fastwrite(x,pttt.topy,attr(pttt.mfcol,pttt.mbcol),submenu[no].text[0])
    else
      fastwrite(x,pttt.topy,attr(pttt.fcol,pttt.bcol),submenu[no].text[0]+replicate(pttt.gap,' '));
    gotoxy(x,pttt.topy);
  end;

  procedure display_main_menu;
  var i:byte;
  begin
    main_wid:=pttt.gap+1;
    for i:=1 to tot_main do main_wid:=main_wid+pttt.gap+length(submenu[i].text[0]);
    for i:=1 to tot_main do display_main_picks(i,0);
    display_main_picks(pickm,1);
  end;

  procedure remove_sub_menu;
  var a:integer;
  begin
    partrestorescreen(pttt.topx,pttt.topy+1,80,linemode);
    if (x2>=pttt.topx+main_wid) then
    begin
      a:=pttt.topx+main_wid+1;
      partrestorescreen(a,pttt.topy+1,80,pttt.topy+1);
    end;
    submenu[pickm].lastpick:=picks;
  end;

  procedure display_sub_picks(no:byte; col:byte);
  begin
    if col=1 then
      fastwrite(x1+1,pttt.topy+1+no,attr(pttt.hfcol,pttt.hbcol),
                pttt.leftchar+submenu[pickm].text[no]+pttt.rightchar)
    else
      fastwrite(x1+1,pttt.topy+1+no,attr(pttt.fcol,pttt.bcol),
                ' '+submenu[pickm].text[no]+' ');
    gotoxy(x1+1,pttt.topy+1+no);
  end;

  procedure display_sub_menu(no :byte);
  var botline:string;
      i:byte;
  begin
    if (submenu[pickm].total=0) then exit;
    x1:=pttt.topx-1;
    if no<>1 then
    begin
      for i:=1 to pred(no) do x1:=x1+pttt.gap+length(submenu[i].text[0]);
      x1:=x1-1+pttt.gap;
    end
    else
      inc(x1,2);
    x2:=x1+submenu[no].width+3;
    if x2>80 then
    begin
      x1:=80-(x2-x1);
      x2:=80;
    end;
    y1:=pttt.topy+1;
    y2:=y1+1+submenu[no].total;
    fbox(x1,y1,x2,y2,pttt.borcol,pttt.bcol,1);
    for i:=1 to submenu[pickm].total do display_sub_picks(i,2);
    picks:=submenu[pickm].lastpick;
    if not (picks in [1..submenu[pickm].total]) then picks:=1;
    display_sub_picks(picks,1);
  end;

begin
  load_menu_parameters;
  save_screen;
  finished:=false;
  if (pickm<1) then pickm:=1;
  display_main_menu;
  for i:=1 to tot_main do submenu[i].lastpick:=1;
  submenu[pickm].lastpick:=picks;
  if picks<>0 then display_sub_menu(pickm);
  repeat
    chm:=getkey;
    case upcase(chm) of
      enter:begin
              finished:=true;
              if submenu[pickm].total=0 then picks:=0;
            end;
      esc:begin
            display_main_picks(pickm,0);
            remove_sub_menu;
            finished:=true;
            pickm:=0;
            picks:=0;
          end;
      cursright,'6':begin
                       display_main_picks(pickm,0);
                       remove_sub_menu;
                       if pickm<tot_main then inc(pickm) else pickm:=1;
                       display_main_picks(pickm,1);
                       display_sub_menu(pickm);
                     end;
      cursleft,'4':begin
                     display_main_picks(pickm,0);
                     remove_sub_menu;
                     if pickm>1 then dec(pickm) else pickm:=tot_main;
                     display_main_picks(pickm,1);
                     display_sub_menu(pickm);
                   end;
      cursdown,'2':if (submenu[pickm].total<>0) then
                   begin
                      display_sub_picks(picks,0);
                      if picks<submenu[pickm].total then inc(picks) else picks:=1;
                      display_sub_picks(picks,1);
                   end;
      cursup,'8':if (submenu[pickm].total<>0) then
                 begin
                   display_sub_picks(picks,0);
                   if picks<>1 then dec(picks) else picks:=submenu[pickm].total;
                   display_sub_picks(picks,1);
                 end;
      endkey,'1':if (submenu[pickm].total<>0) then
                 begin
                   display_sub_picks(picks,0);
                   picks:=submenu[pickm].total;
                   display_sub_picks(picks,1);
                 end else
                 begin
                   display_main_picks(pickm,0);
                   pickm:=tot_main;
                   display_main_picks(pickm,1);
                   display_main_picks(pickm,2);
                   display_sub_menu(pickm);
                 end;
      homekey,'7':if (submenu[pickm].total<>0) then
                  begin
                    display_sub_picks(picks,0);
                    picks:=1;
                    display_sub_picks(picks,1);
                  end else begin
                    display_main_picks(pickm,0);
                    pickm:=1;
                    display_main_picks(pickm,1);
                    display_main_picks(pickm,2);
                    display_sub_menu(pickm);
                  end;
    end;
  until finished;
  restore_screen;
end;

begin
  checkvidseg;
  default_settings;
end.
