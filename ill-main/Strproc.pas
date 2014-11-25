(*****************************************************************************)
(* Illusion BBS - String manipulation for IPL                                *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit strproc;

interface

uses
  crt, dos;

function B2St(B : Boolean) : String;
function CleanUp( str : String ) : String;
function LowCase(C : Char) : Char;
function sRepeat(C : Char; N : Byte) : String;
function St(N : LongInt) : String;
function Stc(I : LongInt) : String;
function strFilename(S : String) : String;
function strLow(s : String) : String;
function strMixed(S : String) : String;
function strReal(R : Real; Ch, Dc : Byte) : String;
function strReplace(S, Find, Rep : String) : String;
function strToInt(S : String) : LongInt;
function UpStr(S : String) : String;

implementation

function sRepeat(C : Char; N : Byte) : String;
var L : Byte; S : String;
begin
   S := '';
   for L := 1 to N do S := S + C;
   sRepeat := S;
end;

function StrToInt(S : String) : LongInt;
var i : LongInt;
    j : Integer;
begin
  Val(S,I,J);
  if (j <> 0) then
  begin
    s := Copy(s,1,j-1);
    Val(s,i,j)
  end;
  StrToInt := i;
  if (s = '') then StrToInt := 0;
end;

function B2St(B : Boolean) : String;
begin
   if B then B2St := 'Yes' else B2St := 'No';
end;

function UpStr(S : String) : String;
var N : Integer;
begin
   for N := 1 to Length(S) do S[N] := UpCase(S[N]);
   UpStr := S;
end;

function LowCase(C : Char) : Char;
begin
   if ('A' <= C) and (C <= 'Z') then LowCase := Chr(Ord(C)+32) else
                                     LowCase := C;
end;

function St(N : LongInt) : String;
var S : String;
begin
   System.Str(N, S);
   St := S;
end;

function LTrim(s : String; c: CHAR ) : String;
begin
  while s[1]=c do delete(s, 1, 1);
  ltrim:=s;
end;

function RTrim( s: String; c: CHAR ): String;
begin
   while (LENGTH(s) > 0) and (s[LENGTH(s)] = c) do DEC(s[0]);
   RTrim := s;
end;

function CleanUp( str : String ) : String;
begin
   if Length(Str) > 0 then CleanUp := LTrim(RTrim(str, ' '), ' ') else CleanUp := Str;
end;

function strReplace(S, Find, Rep : String) : String;
var Z : Byte;
begin
   strReplace := '';
   Find := UpStr(Find);
   if S = '' then Exit;
   while Pos(Find,UpStr(S)) > 0 do
   begin
      Z := Pos(Find,UpStr(S));
      Delete(S,Z,Length(Find));
      Insert(Rep,S,Z);
   end;
   strReplace := S;
end;

function strMixed(S : String) : String;
var Z : Byte;
begin
   strMixed := '';
   if S = '' then Exit;
   S[1] := UpCase(S[1]);
   for Z := 2 to Length(S) do
      if (not (UpCase(S[Z-1]) in ['A'..'Z','0'..'9','''','"'])) then
         S[Z] := UpCase(S[Z]) else S[Z] := LowCase(S[Z]);
   strMixed := S;
end;

function strLow(s : String) : String;
var z : Byte;
begin
   for z := 1 to Ord(s[0]) do s[z] := lowCase(s[z]);
   strLow := s;
end;

function Stc(I : LongInt) : String;
VAR
   s: STRING;
   x: INTEGER;
BEGIN
   S := st(I);
   if Length(S) < 4 then
   begin
      Stc := S;
      Exit;
   end;
   x := LENGTH( s ) - 2;
   WHILE x > 1 DO BEGIN
         INSERT( ',', s, x );
         DEC( x, 3 );
   {W}END;
   Stc := s;
END;

function strReal(R : Real; Ch, Dc : Byte) : String;
var S : String;
begin
   System.Str(R:Ch:Dc, S);
   strReal := S;
end;

function strFilename(S : String) : String;
begin
   while Pos('\',S) > 0 do Delete(S,1,Pos('\',S));
   while Pos('/',S) > 0 do Delete(S,1,Pos('/',S));
   while Pos(':',S) > 0 do Delete(S,1,Pos(':',S));
   strFilename := S;
end;

end.
