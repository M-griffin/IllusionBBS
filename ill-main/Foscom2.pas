(*****************************************************************************)
(* Illusion BBS - Fossil routines                                            *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit foscom2;

interface

uses dos,crt,myio;

var regs:registers;
    fosport:byte;

procedure com_install(comport:byte);
procedure com_deinstall;
procedure com_set_speed(baud:longint);
procedure com_set_flow(typ:char);     { typ: X=XON/XOFF, C=CTS/RTS, B=Both }
procedure fos_dtr(state:boolean);
procedure com_lower_dtr;
procedure com_raise_dtr;
function  com_carrier:Boolean;
procedure com_purge_tx;
procedure com_flush_rx;
procedure com_flush_tx;
function  com_tx_ready:boolean;
procedure com_tx(character:char);
procedure com_tx_string(outstring:string);
function  com_rx:char;
function  com_rx_empty:boolean;

procedure fos_clear_regs;

implementation

procedure fos_clear_regs;
begin
  { this was commented out for a reason, but i can't remember why now
  fillchar(regs,sizeof(regs),0);
  }
end;

procedure com_install(comport:byte);
begin
  fos_clear_regs;
  with regs do
  begin
    fosport:=comport-1;
    ah:=4;
    dx:=(fosport);
    intr($14,regs);
    if ax<>$1954 then
    begin
      writeln;
      writeln('Critical Error: Fossil driver is not loaded.');
      writeln('Make sure the Fossil driver is loaded, refer to');
      writeln('the documentation for help.');
      cursoron(true);
      halt(1);
    end;
  end;
end;

procedure com_deinstall;assembler;
asm
  mov ah,05h
  mov dl,fosport
  int 14h
end;

procedure com_set_speed(baud:longint);
var code:integer;
begin
  if baud>38400 then
  begin
    regs.ah:=$1E;
    regs.al:=$00;
    regs.bh:=$00;
    regs.bl:=$00;
    regs.ch:=$03;
    if (baud=57600) then regs.cl:=$82 else
    if (baud=76800) then regs.cl:=$83 else
    if (baud=115200) then regs.cl:=$84;
    regs.dx:=fosport;
    intr($14,regs);
  end else
  begin
    regs.ah := $00;
    case baud of
      0    :exit;
      300  :regs.al:=(2 shl 5)+3;
      600  :regs.al:=(3 shl 5)+3;
      1200 :regs.al:=(4 shl 5)+3;
      2400 :regs.al:=(5 shl 5)+3;
      4800 :regs.al:=(6 shl 5)+3;
      9600 :regs.al:=(7 shl 5)+3;
      19200:regs.al:=(0 shl 5)+3;
    end;
    if baud=38400 then regs.al:=(1 shl 5)+3;
    regs.dx:=fosport;
    intr($14,regs);
  end;
end;

procedure com_set_flow(typ:char);     { typ: X=XON/XOFF, C=CTS/RTS, B=Both }
begin
  fos_clear_regs;
  with regs do
  begin
    ah:=$0F;
    dx:=(fosport);
    case typ of
      'X':al:=$09;
      'C':al:=$02;
      'B':al:=$0B;
    end;
    intr($14,regs);
  end;
end;

procedure fos_dtr(state:boolean);assembler;
asm
  mov ah,06h
  mov dl,fosport
  cmp state,True
  je @1
  cmp state,False
  je @2
  @1:mov al,01h
     jmp @E
  @2:mov al,00h
     jmp @E
  @E:int 14h
end;

procedure com_lower_dtr;
begin
  fos_dtr(false);
end;

procedure com_raise_dtr;
begin
  fos_dtr(true);
end;

function com_carrier:boolean;
var carr:byte;
begin
  asm
    mov ah,03h
    mov dl,fosport
    int 14h
    mov carr,al
  end;
  com_carrier:=((carr and 128)=128);
end;

procedure com_purge_tx;assembler;
asm
  mov ah,09h
  mov dl,fosport
  int 14h
end;

procedure com_flush_rx;assembler; {actually, this purges the buffer, not flushes}
asm
  mov ah,0Ah
  mov dl,fosport
  int 14h
end;

procedure com_flush_tx;assembler;
asm
  mov ah,08h
  mov dl,fosport
  int 14h
end;

function com_tx_ready:boolean;
var txready:byte;
begin
  asm
    mov ah,03h
    mov dl,fosport
    int 14h
    mov txready,ah
  end;
  com_tx_ready:=((txready and 32)=32);
end;

procedure com_tx(character:char);assembler;
asm
  mov ah,01h
  mov al,character
  mov dl,fosport
  int 14h
end;

procedure com_tx_string(outstring:string);
var outlen,outseg,outofs,sent:integer;
begin
  outlen:=ord(outstring[0]);
  outseg:=seg(outstring);
  outofs:=ofs(outstring)+1;
  asm
    @1:
    mov ah,19h
    mov cx,outlen
    mov dl,fosport
    mov es,outseg
    mov di,outofs
    int 14h
    mov sent,ax
    cmp sent,0
    je @1
  end;
  if sent<outlen then
  begin
    delete(outstring,1,sent);
    com_tx_string(outstring);
  end;
end;

function com_rx:char;
var ichar:byte;
begin
  asm
    mov ah,2
    mov dl,fosport
    int 14h
    mov ichar,al
  end;
  com_rx := chr(ichar);
end;

function com_tx_empty:boolean;
var txempty:word;
begin
  asm
    mov ah,03h
    mov dl,fosport
    int 14h
    mov txempty,ax
  end;
  com_tx_empty:=((txempty and $4000)<>0);
end;

function com_rx_empty:boolean;
var rxempty:word;
begin
  asm
    mov ah,0Ch
    mov dl,fosport
    int 14h
    mov rxempty,ax
  end;
  com_rx_empty:=(rxempty=$ffff);
end;

end.
