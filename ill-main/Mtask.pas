(*****************************************************************************)
(* Illusion BBS - Detection and timeslicing                                  *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R+,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit mtask;

interface

uses dos;

const systype:byte=0;             { 0=DOS, 1=DV, 2=WIN, 3=OS/2 4=Win95 }

procedure find_systype;
procedure timeslice;              {give up the rest of our timeslice}
procedure begin_critical;         {turn switching off for time critical ops}
procedure end_critical;           {turn switching back on}

implementation

var reg:registers;

function os2_getversion:word; assembler;
asm
  mov    ah, 30h
  int    21h
  mov    bh, ah
  xor    ah, ah
  mov    cl, 10
  div    cl
  mov    ah, bh
  xchg   ah, al
end;

procedure find_systype;
var b:boolean;
begin
  systype:=0;

  reg.cx:=$4445;        { DESQVIEW }
  reg.dx:=$5351;        {          }
  reg.ax:=$2B01;        {    |     }
  intr($21,reg);        {    |     }
  b:=(reg.al<>$0ff);    {    |     }
  if b then systype:=1; {    V     }

  reg.ax:=$1600;        { WINDOWS  }
  intr($2f,reg);        {          }
  case reg.al of        {    |     }
    $00:;               {    |     }       { No Win enhanced }
    $80:;               {    |     }       { No Win enhanced }
    $01:;               {    |     }       { Win 2.x }
    $ff:;               {    |     }       { Win 2.x }
    else begin          {    |     }
      if lo(DosVersion)>=7 then
        systype:=4      {    |     }       { DOS Ver >=7? Win95 }
      else              {    |     }
        systype:=2;     {    |     }       { Else Win 3.x }
      exit;             {    |     }
    end;                {    |     }
  end;                  {    V     }

  if (os2_GetVersion>=$0100) then systype:=3;  { OS/2 }
end;

procedure timeslice;
begin
  case systype of
    1:begin              { DV       - int $15 }
        asm
          mov  ax, 1000h
          int  15h
        end;
      end;
    2,3,4:
      begin              { WIN,OS/2 - int $2F }
        asm
          mov  ax, 1680h
          int  2fh
        end;
      end;
  end;
end;

procedure Begin_Critical;
begin
  case systype of
    0:;
    1:begin
        asm
          mov  ax, 101bh
          int  15h
        end;
      end;
    2,3,4:
        begin
          asm
            mov  ax, 1681h
            int  2fh
          end;
        end;
  end;
end;

procedure End_Critical;
begin
  case systype of
    0:;
    1:begin
        asm
          mov  ax, 101ch
          int  15h
        end;
      end;
    2,3,4:
        begin
          asm
            mov  ax, 1682h
            int  2fh
          end;
        end;
  end;
end;

end.
