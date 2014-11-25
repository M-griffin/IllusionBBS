(*****************************************************************************)
(* Illusion BBS - ANSI driver                                                *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O-,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit tpansii;

interface

uses crt,dos;

const isavatar:boolean=FALSE;
      isctrly:boolean=FALSE;

function getnumber(var s:string):integer;
procedure ansioutput(c:char);
procedure setsnow;

implementation

procedure getxy(var x,y:integer);
begin
  inline($b8/$00/$03/ { mov ax,$0300  }
         $31/$db/     { xor bx,bx     }
         $cd/$10/     { int $10       }
         $31/$c0/     { xor ax,ax     }
         $88/$d0/     { mov al,dl     }
         $c4/$be/>x/  { les di,>x[bp] }
         $ab/         { stosw         }
         $88/$f0/     { mov al,dh     }
         $c4/$be/>y/  { les di,>y[bp] }
         $ab);        { stosw         }
end;

procedure setxy(x,y:integer);
begin
  inline($8b/$9e/>x/            {   mov       bx,>x[bp]             }
         $8b/$86/>y/            {   mov       ax,>y[bp]             }
         $3e/$8b/$0e/>windmin/  {ds:mov       cx,word PTR[>WindMin] }
         $3e/$8b/$16/>windmax/  {ds:mov       dx,word PTR[>WindMax] }
         $88/$c7/               {   mov       bh,al                 }
         $38/$cb/               {   cmp       bl,cl                 }
         $73/$04/               {   jae       C0                    }
         $88/$cb/               {   mov       bl,cl                 }
         $eb/$06/               {   jmp short C1                    }
         $38/$d3/               {C0:cmp       bl,dl                 }
         $76/$02/               {   jbe       C1                    }
         $88/$d3/               {   mov       bl,dl                 }
         $38/$ef/               {C1:cmp       bh,ch                 }
         $73/$04/               {   jae       C2                    }
         $88/$ef/               {   mov       bh,ch                 }
         $eb/$06/               {   jmp short C3                    }
         $38/$f7/               {C2:cmp       bh,dh                 }
         $76/$02/               {   jbe       C3                    }
         $88/$f7/               {   mov       bh,dh                 }
         $89/$da/               {C3:mov       dx,bx                 }
         $31/$db/               {   xor       bx,bx                 }
         $b8/$00/$02/           {   mov       ax,$0200              }
         $cd/$10);              {   int       $10                   }
end;

procedure putc(c:char);
begin
  inline($3e/$a0/>directvideo/   {     ds:mov   al,byte PTR[>DirectVideo] }
         $3c/$01/                {        cmp   al,1                      }
         $75/$5b/                {        jne   BIOS                      }
         $b8/$40/$00/            {        mov   ax,$0040                  }
         $8e/$c0/                {        mov   es,ax                     }
         $26/$8b/$1e/$50/$00/    {     es:mov   bx,word PTR[$0050]        }
         $26/$a1/$4a/$00/        {     es:mov   ax,word PTR[$004A]        }
         $31/$c9/                {        xor   cx,cx                     }
         $88/$f9/                {        mov   cl,bh                     }
         $f7/$e1/                {        mul   cx                        }
         $30/$ff/                {        xor   bh,bh                     }
         $01/$d8/                {        add   ax,bx                     }
         $d1/$e0/                {        shl   ax,1                      }
         $89/$c7/                {        mov   di,ax                     }
         $26/$a0/$49/$00/        {     es:mov   al,byte PTR[$0049]        }
         $3c/$07/                {        cmp   al,7                      }
         $75/$05/                {        jne   COLO                      }
         $b8/$00/$b0/            {        mov   ax,$B000                  }
         $eb/$03/                {        jmp   short MONO                }
         $b8/$00/$b8/            {COLO:   mov   ax,$B800                  }
         $8e/$c0/                {MONO:   mov   es,ax                     }
         $8a/$46/<c/             {        mov   al,<c[bp]                 }
         $3e/$8a/$26/>textattr/  {     ds:mov   ah,byte PTR[>TextAttr]    }
         $3e/$8a/$1e/>checksnow/ {     ds:mov   bl,byte PTR[>CheckSnow]   }
         $80/$fb/$01/            {        cmp   bl,1                      }
         $74/$04/                {        je    SLOW                      }
         $ab/                    {        stosw                           }
         $e9/$28/$00/            {        jmp   EXIT                      }
         $89/$c3/                {SLOW:   mov   bx,ax                     }
         $ba/$da/$03/            {        mov   dx,$03DA                  }
         $ec/                    {HORZ:   in    al,dx                     }
         $d0/$d8/                {        rcr   al,1                      }
         $72/$fb/                {        jc    HORZ                      }
         $fa/                    {        cli                             }
         $ec/                    {VERT:   in    al,dx                     }
         $24/$09/                {        and   al,9                      }
         $75/$fb/                {        jnz   VERT                      }
         $89/$d8/                {        mov   ax,bx                     }
         $ab/                    {        stosw                           }
         $fb/                    {        sti                             }
         $e9/$11/$00/            {        jmp   EXIT                      }
         $b4/$09/                {BIOS:   mov   ah,$09                    }
         $8a/$46/<c/             {        mov   al,<c[bp]                 }
         $b7/$00/                {        mov   bh,0                      }
         $3e/$8a/$1e/>textattr/  {     ds:mov   bl,byte PTR[>TextAttr]    }
         $b9/$01/$00/            {        mov   cx,$0001                  }
         $cd/$10);               {        int   $10                       }
                                 {EXIT:                                   }
end;

procedure scroll;
begin
  inline($3e/$a0/>directvideo/   {      ds:mov       al,byte PTR[>DirectVideo] }
         $3e/$8b/$0e/>windmin/   {      ds:mov       cx,word PTR[>WindMin]     }
         $3e/$8b/$16/>windmax/   {      ds:mov       dx,word PTR[>WindMax]     }
         $3c/$01/                {         cmp       al,1                      }
         $74/$03/                {         je        DIRECT                    }
         $e9/$a4/$00/            {         jmp       BIOS                      }
         $1e/                    {DIRECT:  push      ds                        }
         $31/$c0/                {         xor       ax,ax                     }
         $8e/$c0/                {         mov       es,ax                     }
         $26/$8b/$1e/$4a/$04/    {      es:mov       bx,word PTR[$044A]        }
         $88/$f0/                {         mov       al,dh                     }
         $28/$e8/                {         sub       al,ch                     }
         $50/                    {         push      ax                        }
         $88/$d0/                {         mov       al,dl                     }
         $28/$c8/                {         sub       al,cl                     }
         $fe/$c0/                {         inc       al                        }
         $50/                    {         push      ax                        }
         $88/$e8/                {         mov       al,ch                     }
         $f7/$e3/                {         mul       bx                        }
         $30/$ed/                {         xor       ch,ch                     }
         $01/$c8/                {         add       ax,cx                     }
         $d1/$e0/                {         shl       ax,1                      }
         $89/$c7/                {         mov       di,ax                     }
         $d1/$e3/                {         shl       bx,1                      }
         $01/$d8/                {         add       ax,bx                     }
         $89/$c6/                {         mov       si,ax                     }
         $b9/$00/$b0/            {         mov       cx,$B000                  }
         $26/$a0/$49/$04/        {      es:mov       al,byte PTR[$0449]        }
         $3c/$07/                {         cmp       al,7                      }
         $74/$04/                {         je        MONO                      }
         $81/$c1/$00/$08/        {         add       cx,$0800                  }
         $8e/$c1/                {MONO:    mov       es,cx                     }
         $fc/                    {         cld                                 }
         $59/                    {         pop       cx                        }
         $5A/                    {         pop       dx                        }
         $d1/$eb/                {         shr       bx,1                      }
         $29/$cb/                {         sub       bx,cx                     }
         $d1/$e3/                {         shl       bx,1                      }
         $3e/$a0/>checksnow/     {      ds:mov       al,byte PTR[>CheckSnow]   }
         $8c/$c0/                {         mov       ax,es                     }
         $8e/$d8/                {         mov       ds,ax                     }
         $3c/$01/                {         cmp       al,1                      }
         $75/$1f/                {         jne       FAST                      }
         $52/                    {SLOW0:   push      dx                        }
         $51/                    {         push      cx                        }
         $ba/$da/$03/            {SLOW1:   mov       dx,$03DA                  }
         $ec/                    {HORZ:    in        al,dx                     }
         $d0/$d8/                {         rcr       al,1                      }
         $72/$fb/                {         jc        HORZ                      }
         $fa/                    {         cli                                 }
         $ec/                    {VERT:    in        al,dx                     }
         $24/$09/                {         and       al,9                      }
         $75/$fb/                {         jnz       VERT                      }
         $a5/                    {         movsw                               }
         $fb/                    {         sti                                 }
         $e2/$ee/                {         loop      SLOW1                     }
         $59/                    {         pop       cx                        }
         $5a/                    {         pop       dx                        }
         $01/$de/                {         add       si,bx                     }
         $01/$df/                {         add       di,bx                     }
         $4a/                    {         dec       dx                        }
         $74/$0d/                {         jz        FILL                      }
         $eb/$e1/                {         jmp short SLOW0                     }
         $51/                    {FAST:    push      cx                        }
         $f2/$a5/                {         rep movsw                           }
         $59/                    {         pop       cx                        }
         $01/$df/                {         add       di,bx                     }
         $01/$de/                {         add       si,bx                     }
         $4a/                    {         dec       dx                        }
         $75/$f5/                {         jnz       FAST                      }
         $1f/                    {FILL:    pop       ds                        }
         $3e/$8a/$26/>textattr/  {      ds:mov       ah,byte PTR[>TextAttr]    }
         $b0/$20/                {         mov       al,' '                    }
         $3e/$8a/$1e/>checksnow/ {      ds:mov       bl,byte PTR[>CheckSnow]   }
         $80/$fb/$01/            {         cmp       bl,1                      }
         $75/$16/                {         jne       FAST1                     }
         $89/$c3/                {         mov       bx,ax                     }
         $ba/$da/$03/            {         mov       dx,$03DA                  }
         $ec/                    {HORZ1:   in        al,dx                     }
         $d0/$d8/                {         rcr       al,1                      }
         $72/$fb/                {         jc        HORZ1                     }
         $fa/                    {         cli                                 }
         $ec/                    {VERT1:   in        al,dx                     }
         $24/$09/                {         and       al,9                      }
         $75/$fb/                {         jnz       VERT1                     }
         $ab/                    {         stosw                               }
         $fb/                    {         sti                                 }
         $e2/$f1/                {         loop      HORZ1                     }
         $eb/$0e/                {         jmp short DONE                      }
         $f2/$ab/                {FAST1:   rep stosw                           }
         $eb/$0a/                {         jmp short DONE                      }
         $b8/$01/$06/            {BIOS:    mov       ax,$0601                  }
         $3e/$8a/$3e/>textattr/  {      ds:mov       bh,byte PTR[>TextAttr]    }
         $cd/$10)                {         int            $10                  }
                                 {DONE:                                        }
end;

procedure carriagereturn;
var x,y:integer;
begin
  getxy(x,y);
  if (x>lo(windmin)) then setxy(lo(windmin),y);
end;

procedure linefeed;
var x,y:integer;
begin
  getxy(x,y);
  if (y<hi(windmax)) then setxy(x,succ(y)) else scroll;
end;

procedure backspace;
var x,y:integer;
begin
  getxy(x,y);
  if (x>lo(windmin)) then setxy(pred(x),y) else
    if (y>hi(windmin)) then setxy(lo(windmax),pred(y));
{*  putc(' ');*} {* messing up message ANSI B.S.!!!!! *}
end;

procedure character(c:char);
var x,y:integer;
begin
  getxy(x,y); putc(c);
  if (x<lo(windmax)) then setxy(succ(x),y) else
    if (y<hi(windmax)) then setxy(lo(windmin),succ(y))
  else begin
    scroll;
    setxy(lo(windmin),y);
  end;
end;

function getnumber(var s:string):integer;
var t:string;
    l:longint;
    e,n:integer;
begin
  if (length(s)=0) then getnumber:=0
  else begin
    n:=pos(';',s);
    if (n = 0) then begin
      t:=s;
      s:=''
    end else begin
      t:=copy(s,1,n-1);
      delete(s,1,n)
    end;
    val(t,l,e);
    if (e<>0) then n:=0 else n:=integer(l);
    getnumber:=n;
  end;
end;

procedure ansiup(var s:string);
var x,y,n:integer;
begin
  getxy(x,y);
  n:=getnumber(s);
  if (n<1) then n:=1;
  y:=y-lo(n);
  if (y<hi(windmin)) then y:=hi(windmin) else
    if (y>hi(windmax)) then y:=hi(windmax);
  setxy(x,y);
end;

procedure ansidn(var s:string);
var x,y,n:integer;
begin
  getxy(x,y);
  n:=getnumber(s);
  if (n<1) then n:=1;
  y:=y+lo(n);
  if (y>hi(windmax)) then y:=hi(windmax) else
    if (y<hi(windmin)) then y:=hi(windmin);
  setxy(x,y);
end;

procedure ansilt(var s:string);
var x,y,n:integer;
begin
  getxy(x,y);
  n:=getnumber(s);
  if (n<1) then n:=1;
  x:=x-lo(n);
  if (x<lo(windmin)) then x:=lo(windmin) else
    if (x>lo(windmax)) then x:=lo(windmax);
  setxy(x,y);
end;

procedure ansirt(var s:string);
var x,y,n:integer;
begin
  getxy(x,y);
  n:=getnumber(s);
  if (n<1) then n:=1;
  x:=x+lo(n);
  if (x>lo(windmax)) then x:=lo(windmax) else
    if (x<lo(windmin)) then x:=lo(windmin);
  setxy(x,y);
end;

procedure ansito(var s:string);
var i,n:integer;
begin
  n:=getnumber(s);
  i:=getnumber(s);
  if (n<1) then n:=1;
  if (i<1) then i:=1;
  gotoxy(i,n);
end;

procedure ansixy(save:boolean);
const
  x:word=0;
  y:word=0;
begin
  if (save) then begin
    x:=wherex;
    y:=wherey;
  end else
    if ((x>0) and (y>0)) then gotoxy(x,y);
end;

procedure ansics(var s:string);
begin
  if (getnumber(s)=2) then clrscr;
end;

procedure reverse;
begin
  inline($3e/$a0/>textattr/     { ds:mov       al,byte PTR[TextAttr] }
         $88/$c3/               {    mov       bl,al                 }
         $80/$e3/$07/           {    and       bl,7                  }
         $b9/$04/$00/           {    mov       cx,4                  }
         $d2/$e3/               {    shl       bl,cl                 }
         $88/$c7/               {    mov       bh,al                 }
         $b9/$04/$00/           {    mov       cx,4                  }
         $d2/$ef/               {    shr       bh,cl                 }
         $80/$e7/$07/           {    and       bh,7                  }
         $24/$88/               {    and       al,136                }
         $08/$fb/               {    or        bl,bh                 }
         $08/$d8/               {    or        al,bl                 }
         $3e/$a2/>textattr);    { ds:mov       byte PTR[TextAttr],al }
end;

procedure conceal;
begin
  inline($3e/$a0/>textattr/  { ds:mov al,byte PTR[>TextAttr] }
         $24/$70/            {    and al,112                 }
         $88/$c3/            {    mov bl,al                  }
         $b9/$04/$00/        {    mov cx,4                   }
         $d2/$eb/            {    shr bl,cl                  }
         $08/$d8/            {    or  al,bl                  }
         $3e/$a2/>textattr); { ds:mov byte PTR[>TextAttr],al }
end;


procedure ansico(var s:string);
var n:integer;

  procedure ftc(f:byte);
  begin
    textattr:=(textattr and 248) or f;
  end;

  procedure btc(b:byte);
  begin
    textattr:=(textattr and 143) or (b shl 4);
  end;

begin
  if (length(s)=0) then normvideo;
  while (length(s)>0) do begin
    n:=getnumber(s);
    if (n<0) then n:=0;
                                    { : B : b   b   b : f   f   f   f : }
    case lo(n) of
      0:textattr:=7;                { normal video }
      1:textattr:=textattr or 8;    { turn on f1   }
      2:textattr:=textattr and 247; { knock off f1 }
      5:textattr:=textattr or 128;  { turn on B    }
      6:textattr:=textattr or 128;  { turn on B    }
      7:reverse;
      8:conceal;
      30:ftc(black);
      31:ftc(red);
      32:ftc(green);
      33:ftc(brown);
      34:ftc(blue);
      35:ftc(magenta);
      36:ftc(cyan);
      37:ftc(lightgray);
      40:btc(black);
      41:btc(red);
      42:btc(green);
      43:btc(brown);
      44:btc(blue);
      45:btc(magenta);
      46:btc(cyan);
      47:btc(lightgray)
    end;
  end;
end;

procedure ansioutput(c:char);
const isansi:boolean=FALSE;
      ansis:string[50]='';
      lastc:char=#0;
      ns:string[1]='';
var ii:byte;
begin
  if (isansi) then begin
    if (c in ['H','F','A'..'D','s','u','J','K','m']) then begin
      case c of
        'H','F':ansito(ansis);
        'A':ansiup(ansis);
        'B':ansidn(ansis);
        'C':ansirt(ansis);
        'D':ansilt(ansis);
        's':ansixy(TRUE);
        'u':ansixy(FALSE);
        'J':ansics(ansis);
        'K':clreol;
        'm':ansico(ansis);
      end;
      isansi:=FALSE;
    end
    else
      if (c in ['0'..'9',';']) and (length(ansis)<255) then
        ansis:=ansis+c
      else
        isansi:=FALSE;

  end else if (isctrly) then begin
    if length(ansis)<1 then ansis:=ansis+c else begin
      for ii:=1 to ord(c) do character(ansis[1]);
      isctrly:=FALSE; ansis:='';
    end;

  end else if (isavatar) then begin
    if (ansis[1]=^H) and (length(ansis)=2) then begin
      gotoxy(ord(c),ord(ansis[2])); isavatar:=FALSE; ansis:='';
    end else
    if ( ((c=^H) and (lastc=^V)) or ((lastc=^H) and (length(ansis)=1)) ) then ansis:=ansis+c else
    if ((c in [^B,^C,^D,^E,^F,^G]) or (lastc=^A)) then begin
      if lastc=^A then textattr:=(ord(c) and $7F) else
      case c of
        ^B:textattr:=textattr xor $80;
        ^C:ansiup(ns);
        ^D:ansidn(ns);
        ^E:ansilt(ns);
        ^F:ansirt(ns);
        ^G:clreol;
      end;
      isavatar:=FALSE; ansis:='';
    end else if (c<>^A) then begin character(lastc); character(c); isavatar:=FALSE; ansis:=''; end;

  end else begin
    if (c<' ') then
      case c of
        #7 : begin sound(440); delay(80); nosound; end;
        #8 : backspace;
        #10: linefeed;
        ^V : begin isavatar:=TRUE; ansis:=''; end;
        ^Y : begin isctrly:=TRUE; ansis:=''; end;
        #12: clrscr;
        #13: carriagereturn;
        #27: if (lastc=c) then character(^[);
      else
        character(c);
      end
    else
      if (lastc<>^[) then character(c)
      else
        if (c='[') then begin
          isansi:=TRUE;
          ansis:='';
        end else begin
          character(^[);
          character(c);
        end;
  end;
  lastc:=c;
end;

procedure setsnow;
begin
  inline($3e/$a0/>directvideo/ {      ds:mov       al,byte PTR[>DirectVideo] }
         $3c/$01/              {         cmp       al,1                      }
         $74/$07/              {         jz        DIRECT                    }
         $b8/$00/$0f/          {         mov       ax,$0F00                  }
         $cd/$10/              {         int            $10                  }
         $eb/$08/              {         jmp short CHKMODE                   }
         $31/$c0/              {DIRECT:  xor       ax,ax                     }
         $8e/$c0/              {         mov       es,ax                     }
         $26/$a0/$49/$04/      {      es:mov       al,byte PTR[$0449]        }
         $3c/$07/              {CHKMODE: cmp       al,7                      }
         $74/$0c/              {         je        SETFAST                   }
         $b4/$12/              {         mov       ah,$12                    }
         $bb/$10/$ff/          {         mov       bx,$FF10                  }
         $cd/$10/              {         int            $10                  }
         $80/$ef/$ff/          {         sub       bh,$FF                    }
         $74/$04/              {         jz        NOTFAST                   }
         $31/$c0/              {SETFAST: xor       ax,ax                     }
         $eb/$02/              {         jmp short SET                       }
         $b0/$01/              {NOTFAST: mov       al,$01                    }
         $3e/$a2/>checksnow);  {SET:  ds:mov       byte PTR[>CheckSnow],al   }
end;

end.
