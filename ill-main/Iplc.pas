(*****************************************************************************)
(* Illusion Programming Language Compiler                                    *)
(*****************************************************************************)

program IPLC;

{$M $8000, 0, $8000}

uses
   Crt, StrProc, Common;

{$UNDEF ipx}
{$I ipli.pas}

type
   tFile = record
      f         : file;
      col       : Byte;
      lastCol   : Byte;
      line      : Word;
      pos       : LongInt;
      sCol      : Byte;
      sLast     : Byte;
      sLine     : Word;
      sPos      : LongInt;
      size      : LongInt;
   end;

const
   ws = [' ',#9];

var
   inF    : array[1..maxFile] of tFile;
   outF   : file;

   curF   : Byte;
   error  : Byte;
   errStr : String;

   c      : Char;
   id, sr : String;

   lupd   : Byte;

   lastLf : Boolean;

procedure cParse(svarini : Word; one : Boolean); forward;
procedure cExec(vn : Word; result : Boolean); forward;
function cOutNumber : Word; forward;

procedure cInit;
begin
   cID := 0;
   curF := 0;
   error := 0;
   errStr := '';

   FillChar(cVar,SizeOf(cVar),0);
   FillChar(cGoto,SizeOf(cGoto),0);
   cVars := 0;
   cGotos := 0;
end;

function cErrorMsg : String;
var s : String;
begin
   if error = errExpected then if errStr = '"' then errStr := '"' else errStr := '"'+errStr+'"';
   case error of
     errUeEndOfFile     : s := 'Unexpected end-of-file';
     errFileNotFound    : s := 'File not found, "'+errStr+'"';
     errFileRecurse     : s := 'Too many recursed include files (max '+st(maxFile)+')';
     errOutputFile      : s := 'Error writing output file, "'+errStr+'"';
     errExpected        : s := errStr+' expected';
     errUnknownIdent    : s := 'Unknown identifier, "'+errStr+'"';
     errInStatement     : s := 'Error in statement';
     errIdentTooLong    : s := 'Identifier too long, "'+errStr+'" (max '+st(maxIdentLen)+')';
     errExpIdentifier   : s := 'Identifier expected';
     errTooManyVars     : s := 'Too many variables (max '+st(maxVar)+')';
     errDupIdent        : s := 'Duplicate identifier, "'+errStr+'"';
     errOverMaxDec      : s := 'Too many variables declared in one statement (max '+st(maxVarDeclare)+')';
     errTypeMismatch    : s := 'Type mismatch';
     errSyntaxError     : s := 'Syntax error';
     errStringNotClosed : s := 'String constant exceeds end-of-line';
     errStringTooLong   : s := 'String too long (max 255 characters)';
     errTooManyParams   : s := 'Too many parameters (max '+st(maxParam)+')';
     errBadProcRef      : s := 'Invalid procedure/function reference';
     errNumExpected     : s := 'Numeric variable expected';
     errToOrDowntoExp   : s := 'Expected "to" or "downto"';
     errExpOperator     : s := 'Operator expected';
     errOverArrayDim    : s := 'Too many dimensions in array (max '+st(maxArray)+')';
     errNoInitArray     : s := 'Cannot initialize an array with a default value';
     errTooManyGotos    : s := 'Too many "goto" labels (max '+st(maxGoto)+')';
     errDupLabel        : s := 'Duplicate label, "'+errStr+'"';
     errLabelNotFound   : s := 'Label not found, "'+errStr+'"';
     errFileParamVar    : s := 'File parameters must be variable types';
     errBadFunction     : s := 'Functions cannot return variables of this type';
     errOperation       : s := 'Logical operations cannot be performed with this type';
                     else s := '';
   end;
   cErrorMsg := s;
end;

procedure cError(err : Byte; par : String);
begin
   if error > 0 then Exit;
   error := err;
   errStr := par;
end;

procedure cFatalError(err : Byte; par : String);
begin
   cError(err,par);
   WriteLn('(error) #'+st(error)+': '+cErrorMsg);
end;

procedure cTerminate;
var z : Word;
begin
   for z := 1 to cVars do Dispose(cVar[z]);
   cVars := 0;
end;

{::::::::::::::::::::::::::::::::::::::::::::::::( file parsing routines ):::}

procedure cToPos(p : LongInt);
begin
   Seek(outF,p+idLength);
end;

function cFilePos : LongInt;
begin
   cFilePos := filePos(outF)-idLength;
end;

{ serach through variable index for indentifier name }
function cFindVar(s : String) : Integer;
var x, z : Word;
begin
   cFindVar := 0;
   if cVars = 0 then Exit;
   z := 0;
   x := 1;
   repeat
      if upStr(cVar[x]^.ident) = upStr(s) then z := x;
      Inc(x);
   until (x > cVars) or (z > 0);
   cFindVar := z;
end;

{ write a string to the output file }
procedure cOut(x : String);
var z, y : Byte;
begin
   if error <> 0 then Exit;
   for z := 1 to Byte(x[0]) do
   begin
      y := Byte(x[z]) xor (cFilePos mod 255);
      BlockWrite(outF,y,1);
   end;
end;

{ write a word to the output file }
procedure cOutW(w : Word);
var z : Byte;
begin
   if error <> 0 then Exit;
   z := Lo(w) xor (cFilePos mod 255);
   BlockWrite(outF,z,1);
   z := Hi(w) xor (cFilePos mod 255);
   BlockWrite(outF,z,1);
end;

procedure cUpdateCompile;
var x, z : Byte;
begin
   GotoXY(14,WhereY);
   Write(mrn(st(inF[curF].line),5));
   GotoXY(20,WhereY);
   Write(mln(st(inF[curF].col),4));

   x := inF[curF].pos*49 div inF[curF].size;
   if x = lupd then Exit;

   lupd := x;
   GotoXY(25,WhereY);
   for z := 1 to x do Write('.');
   GotoXY(76,WhereY);
   Write(inF[curF].pos*100 div inF[curF].size,'%');
end;

{ read a character from the current source file, updating the current column }
procedure cGetChar;
begin
   c := #0;
   if (not Eof(inF[curF].f)) and (error = 0) then
   begin
      BlockRead(inF[curF].f,c,1);
      Inc(inF[curF].pos);
      if not (c in [#10,#13]) then Inc(inF[curF].col);
   end else cError(errUeEndOfFile,'');
   cUpdateCompile;
end;

{ go back to the previous char in file, as if not read }
procedure cGoBack;
begin
   with inF[curF] do
   begin
      if pos <= 1 then Exit;
      Dec(pos);
      Seek(f,filePos(f)-1);
      Dec(col);
      if col < 1 then
      begin
         col := lastCol;
         lastCol := 1;
         Dec(line);
      end;
   end;
end;

{ returns true if the current character is a linefeed, and processes line # }
function cCheckLf : Boolean;
begin
   if c = #13 then with inF[curF] do
   begin
      Inc(line);
      lastCol := col;
      col := 1;
      lastLf := True;
   end else lastLf := False;
   if c = #10 then lastLf := True;
   cCheckLf := lastLf;
end;

{ checks for cr/linefeeds, block/line comments; true if found }
function cCheckChar : Boolean;
begin
   cCheckChar := False;
   if (c = iqw[wCmtNumberSign,1]) and (lastLf) then
   begin
      while (error = 0) and (c <> #13) do
      begin
         cGetChar;
         cCheckLf;
      end;
      cCheckChar := True;
   end else
   if c = iqw[wCmtStartBlock,1] then
   begin
      repeat
         cGetChar;
         cCheckLf;
      until (error <> 0) or (c = iqw[wCmtEndBlock]);
      cCheckChar := True;
   end else if c = iqw[wCommentLine] then
   begin
      while (error = 0) and (c <> #13) do
      begin
         cGetChar;
         cCheckLf;
      end;
      cCheckChar := True;
   end else if cCheckLf then cCheckChar := True else
   if c = #10 then cCheckChar := True;
end;

{ checks for a string }
function cGetStr(x : String) : Boolean;
var p : Byte;
begin
   cGetStr := False;
   sr := '';
   repeat
      cGetChar;
      if not cCheckChar then
      if (UpCase(c) <> UpCase(x[1])) and (not (c in ws)) then cError(errExpected,x);
   until (error <> 0) or (UpCase(c) = UpCase(x[1]));
   if error > 1 then Exit;

   sr := c;
   if Ord(x[0]) = 1 then
   begin
      cGetStr := True;
      Exit;
   end;

   p := 2;
   while (p <= Ord(x[0])) and (error = 0) do
   begin
      cGetChar;
      cCheckChar;
      if UpCase(c) <> UpCase(x[p]) then cError(errExpected,x);
      sr := sr+c;
      Inc(p);
   end;

   if UpStr(sr) <> UpStr(x) then cError(errExpected,x) else
   if error = 0 then cGetStr := True;
end;

function cGetIdent(exist : Boolean) : Boolean;
begin
   cGetIdent := False;
   id := '';
   repeat
      cGetChar;
      if not cCheckChar then
      if (not (c in chIdent1)) and (not (c in ws)) then cError(errExpIdentifier,'');
   until (error <> 0) or (c in chIdent1);
   if error <> 0 then Exit;

   while (error = 0) and (c in chIdent2) do
   begin
      id := id+c;
      cGetChar;
   end;
   cGoBack;

   if Length(id) > maxIdentLen then cError(errIdentTooLong,id) else
   if id = '' then cError(errExpIdentifier,'') else
   if (Exist) and (cFindVar(id) = 0) then cError(errUnknownIdent,id) else
   if error = 0 then cGetIdent := True;
end;

{ save current pos to memory }
procedure cSavePos;
begin
   with inF[curF] do
   begin
      sCol := col;
      sLine := line;
      sPos := FilePos(f)+1;
      sLast := lastCol;
   end;
end;

{ retore saved file position }
procedure cLoadPos;
begin
   with inF[curF] do
   begin
      col := sCol;
      line := sLine;
      pos := sPos;
      lastCol := sLast;
      Seek(f,pos-1);
   end;
end;

{ return true if the parameter is the next string in the file }
function cNextStr(x : String) : Boolean;
var p, b : Byte;
begin
   cNextStr := False;
   sr := '';
   cSavePos;
   repeat
      cGetChar;
      if not cCheckChar then
      if (UpCase(c) <> UpCase(x[1])) and (not (c in ws)) then
      begin
          cLoadPos;
          Exit;
      end;
   until (error <> 0) or (UpCase(c) = UpCase(x[1]));
   if error <> 0 then Exit;

   sr := c;
   p := 2;
   while (p <= Ord(x[0])) and (error = 0) do
   begin
      cGetChar;
      cCheckChar;
      if UpCase(c) <> UpCase(x[p]) then
      begin
         cLoadPos;
         Exit;
      end;
      sr := sr+c;
      Inc(p);
   end;

   if UpStr(sr) <> UpStr(x) then Exit;
   if error = 0 then cNextStr := True;
end;

procedure cNextChar;
begin
   repeat
      cGetChar;
   until (not (c in ws)) and (not cCheckChar);
end;

procedure cOutPos(p : LongInt; w : Word);
var sav : LongInt;
begin
   sav := cFilePos;
   cToPos(p);
   cOutW(w);
   cToPos(sav);
end;

procedure cCheckArray(vn : Word);
var x : Byte;
begin
   if cVar[vn]^.arr > 0 then
   begin
      cGetStr(iqw[wOpenArr]);
      for x := 1 to cVar[vn]^.arr do
      begin
         cOutNumber;
         if x < cVar[vn]^.arr then cGetStr(iqw[wArrSep]) else cGetStr(iqw[wCloseArr]);
      end;
   end;
end;

function cDoNumber : Word;
var de, dit, don, lnum : Boolean; rn : Integer; len : Word;
begin
   len := 0;
   don := False;
   lnum := False;
   cDoNumber := 0;
   repeat
      cGetChar;
      dit := cCheckChar;
      if dit then begin {Woo!} end else
      if c in chDigit then
      begin
         if lnum then cError(errInStatement,'');
         lnum := True;
         de := False;
         cOut(c);
         Inc(len);
         repeat
            cGetChar;
            if c = '.' then
               if de then cError(errInStatement,'') else de := True;
            if c in chNumber then
            begin
               cOut(c);
               Inc(len);
            end;
         until (error <> 0) or (not (c in chNumber));
         if error = 0 then cGoBack;
      end else
      if c in chIdent1 then
      begin
         if not lnum then
         begin
            cGoBack;
            lnum := True;
            if cGetIdent(True) then
            begin
               rn := cFindVar(id);
{              if rn < 0 then
               begin
                  if iproc[-rn].vtype in vnums then
                  begin
                     Inc(len);
                     cExec(rn,True);
                  end;
               end else}
               if cVar[rn]^.vtype in vnums then
               begin
                  Inc(len);
                  if cVar[rn]^.proc then cExec(rn,True) else
                  begin
                     cOut(iqo[oVariable]);
                     cOutW(cVar[rn]^.id);
                     cCheckArray(rn);
                  end;
               end else cError(errTypeMismatch,'');
            end;
         end else don := True;
      end else
      if c in ['+','-','/','*'] then begin lnum := False; cOut(c); end else
      if c in ws then begin { woo skip it :) } end else
      if c = iqw[wOpenBrack,1] then
      begin
         cOut(iqo[oOpenBrack]);
         Inc(len,cDoNumber);
         cGetStr(iqw[wCloseBrack]);
         cOut(iqo[oCloseBrack]);
      end else don := True;
(*    if c in [iqw[wCloseBrack,1],
               iqw[wParamSep,1],
               iqw[wCloseParam,1],
               iqw[wOpEqual,1],
{              iqw[wOpNotEqual,1],}
               iqw[wOpGreater,1],
               iqw[wOpLess,1],
               iqw[wCloseBlock,1],
               iqw[wCloseArr,1],
               iqw[wOpenBlock,1]]
{              iqw[wOpEqGreat,1],
               iqw[wOpEqLess,1]]}
               then don := True else cError(errInStatement,''); *)
   until (dit) or (don) or (error <> 0);
   if error <> 0 then Exit;
   if len = 0 then cError(errInStatement,'') else if don then cGoBack;
   cDoNumber := len;
end;

function cOutNumber : Word;
begin
   cOut(iqo[oOpenNum]);
   cOutNumber := cDoNumber;
   cOut(iqo[oCloseNum]);
end;

{ compile a string - opening and closing "'s are processed here }
procedure cOutString;
var some : Boolean; rn : Word; x : String; z : Char;
 function osString : String;
 var z : String; ok : Boolean;
 begin
    z := '';
    osString := '';
    ok := False;
    cGetStr(iqw[wOpenString]);
    cOut(iqo[oOpenString]);
    if error <> 0 then Exit;

    repeat
       cGetChar;
       if cCheckLf then cError(errStringNotClosed,'') else
       if Length(z) >= 255 then cError(errStringTooLong,'') else
       if c = iqw[wCloseString,1] then
       begin
          cGetChar;
          if c = iqw[wCloseString,1] then
          begin
             z := z+c;
             cOut(c+c);
          end else
          begin
             cGoBack;
             ok := True;
          end;
       end else
       begin
          z := z+c;
          cOut(c);
       end;
    until (error <> 0) or (ok);
    if error <> 0 then Exit;

    cOut(iqo[oCloseString]);
    if error = 0 then osString := z;
 end;
begin
   some := False;
   cNextChar;
   if error <> 0 then Exit;
   if c = iqw[wOpenString,1] then
   begin
      cGoBack;
      osString;
      if error = 0 then some := True;
   end else
   if c in chIdent1 then
   begin
      cGoBack;
      if cGetIdent(True) then
      begin
         rn := cFindVar(id);
         if cVar[rn]^.vtype in [vStr] then
         begin
            if cVar[rn]^.proc then cExec(rn,True) else
            begin
               cOut(iqo[oVariable]);
               cOutW(cVar[rn]^.id);
               cCheckArray(rn);
            end;
            some := True;
         end else cError(errTypeMismatch,'');
      end;
   end else
   if c = iqw[wCharPrefix,1] then
   begin
      x := '';
      repeat
         cGetChar;
         x := x+c;
      until not (c in chDigit);
      Dec(x[0]);
      if error = 0 then
      begin
         z := Chr(strToInt(x));
         cOut(iqo[oOpenString]);
         cOut(z);
         if z = iqo[oCloseString] then cOut(z);
         cOut(iqo[oCloseString]);
         cGoBack;
         some := True;
      end;
   end else
   if c in chDigit then cError(errTypeMismatch,'') else
      cError(errInStatement,'');
   if error <> 0 then Exit;
   cNextChar;
   if c = iqw[wStrCh] then
   begin
      cOut(iqo[oStrCh]);
      cOutNumber;
      cNextChar;
   end;
   if c = iqw[wStrAdd] then
   begin
      cOut(iqo[oStrAdd]);
      cOutString;
   end else cGoBack;
   if not some then cError(errInStatement,'');
end;

procedure cOutFile;
var vn : Word;
begin
   cGetIdent(True);
   if error <> 0 then Exit;
   vn := cFindVar(id);
   if cVar[vn]^.vType <> vFile then cError(errTypeMismatch,'');
end;

procedure cOutBoolean;
type tOp = (opNone,opEqual,opNotEqual,opGreater,opLess,opEqGreat,opEqLess);
var ga, gb, nm, inot : Boolean; ta, tb : tIqVar; o : tOp; rn : Word;
begin
   ta := vNone; tb := vNone;
   ga := False; gb := False;
   nm := True;  o := opNone;
   inot := False;

   { get the first identifier .. }
   repeat
      cGetChar;
      if not cCheckChar then
      if c in ws then begin end else
      if c = iqw[wOpenBrack] then
      begin
         cOut(iqo[oOpenBrack]);
         cOutBoolean;
         ta := vBool;
         nm := False;
         cGetStr(iqw[wCloseBrack]);
         cOut(iqo[oCloseBrack]);
         ga := True;
      end else
      if c in chIdent1 then
      begin
         cGoBack;
         if cGetIdent(False) then
         begin
            rn := cFindVar(id);
            if rn = 0 then
            begin
               if strLow(id) = iqw[wNot] then
               begin
                  inot := True;
                  cOut(iqo[oNot]);
               end else
               if strLow(id) = iqw[wTrue] then
               begin
                  ta := vBool;
                  ga := True;
                  nm := False;
                  cOut(iqo[oTrue]);
               end else if strLow(id) = iqw[wFalse] then
               begin
                  ta := vBool;
                  ga := True;
                  nm := False;
                  cOut(iqo[oFalse]);
               end else cError(errUnknownIdent,id);
            end else
            begin
               ta := cVar[rn]^.vType;
               if ta = vBool then nm := False else
               if ta = vFile then cError(errOperation,'');
               if cVar[rn]^.proc then cExec(rn,True) else
               begin
                  cOut(iqo[oVariable]);
                  cOutW(cVar[rn]^.id);
                  cCheckArray(rn);
               end;
               ga := True;
            end;
         end;
      end else
      if c in chDigit then
      begin
         cGoBack;
         cOutNumber;
         ta := vReal;
         ga := True;
      end else
      if c in ['#','"'] then
      begin
         cGoBack;
         cOutString;
         ta := vStr;
         ga := True;
      end else cError(errExpIdentifier,'');
   until (error <> 0) or (ga);
   if error <> 0 then Exit;

   { get the operator .. }
   if cNextStr(iqw[wOpEqual])    then begin cOut(iqo[oOpEqual]);    o := opEqual; end else
   if cNextStr(iqw[wOpNotEqual]) then begin cOut(iqo[oOpNotEqual]); o := opNotEqual; end else
   if cNextStr(iqw[wOpEqGreat])  then begin cOut(iqo[oOpEqGreat]);  o := opEqGreat; end else
   if cNextStr(iqw[wOpEqLess])   then begin cOut(iqo[oOpEqLess]);   o := opEqLess; end else
   if cNextStr(iqw[wOpGreater])  then begin cOut(iqo[oOpGreater]);  o := opGreater; end else
   if cNextStr(iqw[wOpLess])     then begin cOut(iqo[oOpLess]);     o := opLess; end else
   if nm then cError(errExpOperator,'');

   if o <> opNone then
   begin
   { get the second identifier if necessary .. }
   repeat
      cGetChar;
      if not cCheckChar then
      if c in ws then begin end else
      if c = iqw[wOpenBrack] then
      begin
         cOut(iqo[oOpenBrack]);
         cOutBoolean;
         tb := vBool;
         cGetStr(iqw[wCloseBrack]);
         cOut(iqo[oCloseBrack]);
         gb := True;
      end else
      if c in chIdent1 then
      begin
         cGoBack;
         if cGetIdent(False) then
         begin
            rn := cFindVar(id);
            if rn = 0 then
            begin
               if strLow(id) = iqw[wTrue] then
               begin
                  tb := vBool;
                  gb := True;
                  cOut(iqo[oTrue]);
               end else if strLow(id) = iqw[wFalse] then
               begin
                  tb := vBool;
                  gb := True;
                  cOut(iqo[oFalse]);
               end else cError(errUnknownIdent,id);
            end else
            begin
               tb := cVar[rn]^.vType;
               if tb = vFile then cError(errOperation,'');
               if cVar[rn]^.proc then cExec(rn,True) else
               begin
                  cOut(iqo[oVariable]);
                  cOutW(cVar[rn]^.id);
                  cCheckArray(rn);
               end;
               gb := True;
            end;
         end;
      end else
      if c in chDigit then
      begin
         cGoBack;
         cOutNumber;
         tb := vReal;
         gb := True;
      end else
      if c in ['#','"'] then
      begin
         cGoBack;
         cOutString;
         tb := vStr;
         gb := True;
      end else cError(errExpIdentifier,'');
   until (error <> 0) or (gb);
   if error <> 0 then Exit;

   if ((ta = vStr)  and (tb <> vStr)) or
      ((ta = vBool) and (tb <> vBool)) or
      ((ta = vFile) and (tb <> vFile)) or
      ((ta in vnums) and (not (tb in vnums))) then cError(errTypeMismatch,'');
   end;

   if cNextStr(iqw[wAnd]) then
   begin
      cOut(iqo[oAnd]);
      cOutBoolean;
   end else
   if cNextStr(iqw[wOr]) then
   begin
      cOut(iqo[oOr]);
      cOutBoolean;
   end;

end;

procedure cSetVariable(vt : tIqVar);
begin
   if vt in vnums then cOutNumber else
   if vt = vStr then cOutString else
   if vt = vBool then cOutBoolean else
   if vt = vFile then cError(errInStatement,'');
end;

procedure cCreateVar;
var iden : array[1..maxVarDeclare] of String[maxIdentLen]; typ : tIqVar;
    t : Char; ni, ci, fv : Word; ar : Byte; sp : LongInt;
begin
   cOut(iqo[oVarDeclare]);
   cGetIdent(False);
   if error <> 0 then Exit;
   id := strLow(id);
   if id = iqv[vStr  ] then typ := vStr   else
   if id = iqv[vByte ] then typ := vByte  else
   if id = iqv[vShort] then typ := vShort else
   if id = iqv[vWord ] then typ := vWord  else
   if id = iqv[vInt  ] then typ := vInt   else
   if id = iqv[vLong ] then typ := vLong  else
   if id = iqv[vReal ] then typ := vReal  else
   if id = iqv[vBool ] then typ := vBool  else
   if id = iqv[vFile ] then typ := vFile else
      cError(errUnknownIdent,id);
   if error <> 0 then Exit;
   case typ of
      vStr   : t := iqo[oStr];
      vByte  : t := iqo[oByte];
      vShort : t := iqo[oShort];
      vWord  : t := iqo[oWord];
      vInt   : t := iqo[oInt];
      vLong  : t := iqo[oLong];
      vReal  : t := iqo[oReal];
      vBool  : t := iqo[oBool];
      vFile  : t := iqo[oFile];
   end;
   cOut(t);
   cNextChar;
   ar := 0;

   if typ = vStr then
   begin
      if c = iqw[wOpenStrLen] then
      begin
         cOut(iqo[oStrLen]);
         cOutNumber;
         cGetStr(iqw[wCloseStrLen]);
         cNextChar;
      end;
   end;

   if c = iqw[wOpenArr] then
   begin
      cOut(iqo[oArrDef]);
      sp := cFilePos;
      cOutW(0);
      repeat
         if ar >= maxArray then cError(errOverArrayDim,'');
         cOutNumber;
         Inc(ar);
      until (error <> 0) or (not cNextStr(iqw[wArrSep]));
      cGetStr(iqw[wCloseArr]);
      cOutPos(sp,ar);
   end else
   begin
      cGoBack;
      cOut(iqo[oVarNormal]);
   end;

   ni := 0;
   repeat
      if cVars+ni >= maxVar then cError(errTooManyVars,'') else
      if cGetIdent(False) then
      begin
         if cFindVar(id) <> 0 then cError(errDupIdent,id) else
         begin
            for ci := 1 to ni do if upStr(id) = upStr(iden[ci]) then cError(errDupIdent,id);
            if error = 0 then
            begin
               Inc(ni);
               if ni > maxVarDeclare then cError(errOverMaxDec,'') else iden[ni] := id;
            end;
         end;
      end;
   until (error <> 0) or (not cNextStr(iqw[wVarSep]));
   if error <> 0 then Exit;

   cOutW(ni);

   fv := cVars;
   for ci := 1 to ni do
   begin
      Inc(cVars);
      New(cVar[cVars]);
      with cVar[cVars]^ do
      begin
         id := cID;

         cOutW(cID);

         Inc(cID);
         ident := iden[ci];
         vtype := typ;
         FillChar(param,SizeOf(param),0);
         numPar := 0;
         proc := False;
         arr := ar;
      end;
   end;

   cVars := fv;
   if cNextStr(iqw[wVarDef]) then
   begin
      if ar > 0 then cError(errNoInitArray,'') else
      begin
         cOut(iqo[oVarDef]);
         cSetVariable(typ);
      end;
   end;
   Inc(cVars,ni);

end;

procedure cDefineProc;
var iden : array[1..maxVarDeclare] of String[maxIdentLen]; typ : tIqVar;
    t : Char; ni, si, ci, pv, psize : Word;
begin
   cOut(iqo[oProcDef]);
   cGetIdent(False);
   if cFindVar(id) <> 0 then cError(errDupIdent,id) else
   if cVars >= maxVar then cError(errTooManyVars,'');
   if error <> 0 then Exit;
   ni := 0;

   Inc(cVars);
   pv := cVars;
   New(cVar[cVars]);
   with cVar[cVars]^ do
   begin
      id := cID;

      cOutW(cID);

      Inc(cID);
      ident := iplc.id;
      vtype := vNone;
      FillChar(param,SizeOf(param),0);
      numPar := 0;
      proc := True;
      arr := 0;
   end;

   if (cNextStr(iqw[wOpenParam])) and (not cNextStr(iqw[wCloseParam])) then
   begin
      repeat
         cGetIdent(False);
         id := strLow(id);
         if id = iqv[vStr  ] then typ := vStr   else
         if id = iqv[vByte ] then typ := vByte  else
         if id = iqv[vShort] then typ := vShort else
         if id = iqv[vWord ] then typ := vWord  else
         if id = iqv[vInt  ] then typ := vInt   else
         if id = iqv[vLong ] then typ := vLong  else
         if id = iqv[vReal ] then typ := vReal  else
         if id = iqv[vBool ] then typ := vBool  else
            cError(errUnknownIdent,id);
         case typ of
            vStr   : t := iqo[oStr];
            vByte  : t := iqo[oByte];
            vShort : t := iqo[oShort];
            vWord  : t := iqo[oWord];
            vInt   : t := iqo[oInt];
            vLong  : t := iqo[oLong];
            vReal  : t := iqo[oReal];
            vBool  : t := iqo[oBool];
            vFile  : t := iqo[oFile];
         end;
         if cNextStr(iqw[wParamVar]) then t := upCase(t) else
            if typ = vFile then cError(errFileParamVar,'');
         cOut(t);
         si := ni;

         repeat
            if ni >= maxParam then cError(errTooManyParams,'') else
            if cVars+ni >= maxVar then cError(errTooManyVars,'') else
            if cGetIdent(False) then
            begin
               if cFindVar(id) <> 0 then cError(errDupIdent,id) else
               begin
                  for ci := 1 to ni do if upStr(id) = upStr(iden[ci]) then cError(errDupIdent,id);
                  if error = 0 then
                  begin
                     Inc(ni);
                     if ni > maxVarDeclare then cError(errOverMaxDec,'') else
                     begin
                        iden[ni] := id;
                        cVar[pv]^.param[ni] := t;
                        Inc(cVar[pv]^.numPar);
                     end;
                  end;
               end;
            end;
         until (error <> 0) or (not cNextStr(iqw[wVarSep]));
         if error <> 0 then Exit;

         cOutW(ni-si);

         for ci := si+1 to ni do
         begin
            Inc(cVars);
            New(cVar[cVars]);
            with cVar[cVars]^ do
            begin
               id := cID;
               cOutW(cID);
               Inc(cID);
               ident := iden[ci];
               vtype := typ;
               FillChar(param,SizeOf(param),0);
               numPar := 0;
               proc := False;
               arr := 0;
            end;
         end;
      until (error <> 0) or (not cNextStr(iqw[wParamSpec]));
      cGetStr(iqw[wCloseParam]);
   end;

   if cNextStr(iqw[wFuncSpec]) then
   begin
      cGetIdent(False);
      id := strLow(id);
      if id = iqv[vStr  ] then typ := vStr   else
      if id = iqv[vByte ] then typ := vByte  else
      if id = iqv[vShort] then typ := vShort else
      if id = iqv[vWord ] then typ := vWord  else
      if id = iqv[vInt  ] then typ := vInt   else
      if id = iqv[vLong ] then typ := vLong  else
      if id = iqv[vReal ] then typ := vReal  else
      if id = iqv[vBool ] then typ := vBool  else
      if id = iqv[vFile ] then cError(errBadFunction,'') else
                               cError(errUnknownIdent,id);
      case typ of
         vStr   : t := iqo[oStr];
         vByte  : t := iqo[oByte];
         vShort : t := iqo[oShort];
         vWord  : t := iqo[oWord];
         vInt   : t := iqo[oInt];
         vLong  : t := iqo[oLong];
         vReal  : t := iqo[oReal];
         vBool  : t := iqo[oBool];
         vFile  : t := iqo[oFile]; { <--- not allowed }
      end;
      cVar[pv]^.vtype := typ;
      cOut(iqo[oProcType]);
      cOut(t);
   end;

   if error <> 0 then Exit;
   cVar[pv]^.inproc := True;
   cParse(cVars-ni,False);
   cVar[pv]^.inproc := False;
end;

procedure cExec(vn : Word; result : Boolean);
var z : Byte; rv : Word;
begin
   cOut(iqo[oProcExec]);
   cOutW(cVar[vn]^.id);
   if cVar[vn]^.numPar > 0 then
   begin
      cGetStr(iqw[wOpenParam]);

      for z := 1 to cVar[vn]^.numPar do
      begin
         if cVar[vn]^.param[z] = upCase(cVar[vn]^.param[z]) then
         begin
            cGetIdent(True);
            rv := cFindVar(id);
            if (cVar[rv]^.vtype <> cVarType(cVar[vn]^.param[z])) and (cVar[vn]^.param[z] <> '*') then
               cError(errTypeMismatch,'');
            cOut(iqo[oVariable]);
            cOutW(cVar[rv]^.id);
          { cCheckArray(rv); }
         end else
         begin
            if cVarType(cVar[vn]^.param[z]) in vnums then cOutNumber else
            if cVarType(cVar[vn]^.param[z]) = vStr then cOutString else
            if cVarType(cVar[vn]^.param[z]) = vBool then cOutBoolean else
            if cVarType(cVar[vn]^.param[z]) = vFile then cOutFile;
         end;
         cOut(iqo[oParamSep]);
         if z < cVar[vn]^.numPar then cGetStr(iqw[wParamSep]);
      end;

      cGetStr(iqw[wCloseParam]);
   end else
   begin
      if cNextStr(iqw[wOpenParam]) then cGetStr(iqw[wCloseParam]);
      if (result) and (cVar[vn]^.vtype = vNone) then cError(errBadProcRef,'');
   end;
end;

procedure cForLoop;
var vc : Word; up : Boolean;
begin
   cOut(iqo[oFor]);
   cGetIdent(True);
   if error <> 0 then Exit;
   vc := cFindVar(id);
   if not (cVar[vc]^.vtype in vnums) then cError(errNumExpected,'');
   if error <> 0 then Exit;
   cOutW(cVar[vc]^.id);
   cCheckArray(vc);
   cGetStr(iqw[wSetVar]);
   if error <> 0 then Exit;
   cOutNumber;
   if error <> 0 then Exit;
   if cNextStr(iqw[wTo]) then up := True else
   if cNextStr(iqw[wDownto]) then up := False else
      cError(errToOrDowntoExp,'');
   if error <> 0 then Exit;
   if up then cOut(iqo[oTo]) else cOut(iqo[oDownto]);
   cOutNumber;
   if error <> 0 then Exit;
   cGetStr(iqw[wDo]);
   if cNextStr(iqw[wOpenBlock]) then
   begin
      cGoBack;
      cParse(cVars,False);
   end else cParse(cVars,True);
end;

procedure cWhileDo;
begin
   cOut(iqo[oWhile]);
   cOutBoolean;
   if error <> 0 then Exit;
   cGetStr(iqw[wDo]);
   if error <> 0 then Exit;
   if cNextStr(iqw[wOpenBlock]) then
   begin
      cGoBack;
      cParse(cVars,False);
   end else cParse(cVars,True);
end;

procedure cRepeatUntil;
begin
   cOut(iqo[oRepeat]);
   if cNextStr(iqw[wOpenBlock]) then
   begin
      cGoBack;
      cParse(cVars,False);
   end else cParse(cVars,True);
   if error <> 0 then Exit;
   cGetStr(iqw[wUntil]);
   if error <> 0 then Exit;
   cOutBoolean;
end;

procedure cIfThenElse;
begin
   cOut(iqo[oIf]);
   cOutBoolean;
   if error <> 0 then Exit;
   cGetStr(iqw[wThen]);
   if error <> 0 then Exit;
   if cNextStr(iqw[wOpenBlock]) then
   begin
      cGoBack;
      cParse(cVars,False);
   end else cParse(cVars,True);
   if cNextStr(iqw[wElse]) then
   begin
      cOut(iqo[oElse]);
      if cNextStr(iqw[wOpenBlock]) then
      begin
         cGoBack;
         cParse(cVars,False);
      end else cParse(cVars,True);
   end;
end;

function cFindGoto(s : String) : Integer;
var x, z : Byte;
begin
   cFindGoto := 0;
   if cGotos = 0 then Exit;
   z := 0;
   x := 1;
   repeat
      if upStr(cGoto[x]^.ident) = upStr(s) then z := x;
      Inc(x);
   until (x > cGotos) or (z > 0);
   cFindGoto := z;
end;

procedure cGotoLabel;
var z : Word;
begin
   cOut(iqo[oGoto]);
   cGetIdent(False);
   if error <> 0 then Exit;
   z := cFindGoto(id);
   if z = 0 then
   begin
      if cGotos >= maxGoto then cError(errTooManyGotos,'') else
      begin
         Inc(cGotos);
         New(cGoto[cGotos]);
         cGoto[cGotos]^.ident := id;
         cGoto[cGotos]^.xPos := cFilePos;
         cGoto[cGotos]^.stat := 1;
         cOutW(0);
      end;
   end else
   begin
      cGoto[z]^.stat := 0;
      cOutW(cGoto[z]^.xPos);
   end;
end;

procedure cLabelPos;
var z : Word; x : LongInt;
begin
   cGetIdent(False);
   if error <> 0 then Exit;
   z := cFindGoto(id);
   if z = 0 then
   begin
      if cGotos >= maxGoto then cError(errTooManyGotos,'') else
      begin
         Inc(cGotos);
         New(cGoto[cGotos]);
         cGoto[cGotos]^.ident := id;
         cGoto[cGotos]^.xPos := cFilePos;
         cGoto[cGotos]^.stat := 2;
      end;
   end else
   begin
      if cGoto[z]^.stat = 1 then
      begin
         cGoto[z]^.stat := 0;
         x := cFilePos;
         cOutPos(cGoto[z]^.xPos,x);
         cGoto[z]^.xPos := x;
      end else cError(errDupLabel,cGoto[z]^.ident);
   end;
end;

function cFuncRet(vn : Word) : Boolean;
begin
   cFuncRet := False;
   if not cVar[vn]^.inproc then Exit;
   if cNextStr(iqw[wSetVar]) then
   begin
      cOut(iqo[oSetVar]);
      cOutW(cVar[vn]^.id);
      cSetVariable(cVar[vn]^.vtype);
      cFuncRet := True;
   end;
end;

procedure cExitModule;
begin
   cOut(iqo[oExit]);
   if cNextStr(iqw[wOpenParam]) then
   begin
      cOut(iqo[oOpenBrack]);
      cOutNumber;
      cGetStr(iqw[wCloseParam]);
      cOut(iqo[oCloseBrack]);
   end
end;

procedure cParseIdent;
var s, z : String; vn : Word;
begin
   s := '';
   repeat
      s := s+c;
      cGetChar;
      cCheckChar;
   until (error <> 0) or (not (c in chIdent2));
   if Length(s) > maxIdentLen then cError(errIdentTooLong,s);
   if error <> 0 then Exit;
   cGoBack;
   vn := cFindVar(s);
   if vn = 0 then
   begin
      z := strLow(s);
      if z = iqw[wProcDef] then cDefineProc else
      if z = iqw[wFor] then cForLoop else
      if z = iqw[wIf] then cIfThenElse else
      if z = iqw[wWhile] then cWhileDo else
      if z = iqw[wRepeat] then cRepeatUntil else
      if z = iqw[wGoto] then cGotoLabel else
      if z = iqw[wExit] then cExitModule else
         cError(errUnknownIdent,s);
   end else
   begin
      if cVar[vn]^.proc then
      begin
         if not cFuncRet(vn) then cExec(vn,False);
      end else
      begin
         cOut(iqo[oSetVar]);
         cOutW(cVar[vn]^.id);
         cCheckArray(vn);
         if not cGetStr(iqw[wSetVar]) then Exit;
         cSetVariable(cVar[vn]^.vtype);
      end;
   end;
end;

{ parse and compile a block of source data }
procedure cParse(svarini : Word; one : Boolean);
var svar, tvar, sgoto : Word; clos, gotone : Boolean; sav, sav2 : LongInt;
begin
   if not one then cGetStr(iqw[wOpenBlock]);
   if error <> 0 then Exit;
   cOut(iqo[oOpenBlock]);
   sav := cFilePos;
   sgoto := cGotos;
   cOutW(0);
   clos := False;
   svar := svarini;
   gotone := False;
   repeat
      cGetChar;
      if not cCheckChar then
      begin
         if c = iqw[wOpenBlock,1] then
         begin
            cGoBack;
            cParse(cVars,False);
            gotone := True;
         end else
         if c = iqw[wCloseBlock,1] then clos := True else
         if c in chIdent1 then
         begin
            cParseIdent;
            gotone := True;
         end else
         if c = iqw[wVarDeclare,1] then
         begin
            cCreateVar;
            gotone := True;
         end else
         if c = iqw[wLabel,1] then
         begin
            cLabelPos;
            gotone := True;
         end else
         if c in ws then begin { wow! :) } end else
            cError(errSyntaxError,'');
      end;
   until (clos) or (error <> 0) or (one and gotone);

   for tvar := cVars downto svar+1 do Dispose(cVar[tvar]);
   cVars := svar;
   for tvar := cGotos downto sgoto+1 do
   begin
      if cGoto[tvar]^.stat = 1 then cError(errLabelNotFound,cGoto[tvar]^.ident);
      Dispose(cGoto[tvar]);
   end;
   cOut(iqo[oCloseBlock]);
   sav2 := cFilePos;
   cToPos(sav);
   cOutW(sav2-sav-2);
   cToPos(sav2);
end;

procedure cProcess(fn : String);
var fnx : String;
begin
   c := #0;
   id := '';
   sr := '';

   if curF = maxFile then
   begin
      cError(errFileRecurse,'');
      Exit;
   end else Inc(curF);

   FillChar(inF[curF],SizeOf(inF[curF]),0);
   inF[curF].line := 1;
   inF[curF].col := 1;
   inF[curF].pos := 1;
   lastLf := True;

   Assign(inF[curF].f,fn);
   {$I-}
   Reset(inF[curF].f,1);
   {$I+}
   if ioResult <> 0 then
   begin
      fnx := fn+extIPLcode;
      Assign(inF[curF].f,fnx);
      {$I-}
      Reset(inF[curF].f,1);
      {$I+}
      if ioResult <> 0 then
      begin
         cFatalError(errFileNotFound,fn);
         Exit;
      end else fn := fnx;
   end;
   inF[curF].size := FileSize(inF[curF].f);

   Write(strFilename(fn));
   GotoXY(18,WhereY);
   Write('0:0');
   GotoXY(24,WhereY);
   Write('[');
   GotoXY(74,WhereY);
   Write('] 0%');

   lupd := 255;

   cParse(cVars,False);

   inF[curF].pos := inF[curF].size;
   cUpdateCompile;
   Delay(100);

   GotoXY(1,WhereY);
   clrEol;

   if error <> 0 then
   WriteLn('('+fn+'/error@'+st(inF[curF].line)+':'+st(inF[curF].col)+') #'+st(error)+': '+cErrorMsg) else
   WriteLn(fn+' compiled successfully; '+stc(inF[curF].line)+' lines, '+stc(inF[curF].pos)+' bytes');

   Close(inF[curF].f);
   Dec(curF);
end;

function strResizeNc(S : String; L : Byte) : String;
begin
   if Length(S) > L then S[0] := Chr(L) else
   if Length(S) < L then
   begin
      FillChar(S[Length(S)+1],L-Length(S),#32);
      S[0] := Chr(L);
   end;
   strResizeNc := S;
end;

procedure cCompile(fn : String);
var os : String; oh : String[idLength];
begin
   os := strFilename(fn);
   if Pos('.',os) > 0 then Delete(os,Pos('.',os),255);
   os := os+extIPLexe;

   FillChar(oh,SizeOf(oh),#32);
   oh := strResizeNc(cProgram,idVersion)+cVersion+#13#10#26;

   Assign(outF,os);
   {$I-}
   Rewrite(outF,1);
   {$I+}
   if ioResult <> 0 then
   begin
      cFatalError(errOutputFile,os);
      Exit;
   end;

   BlockWrite(outF,oh[1],idLength);

   cProcess(fn);

   if error = 0 then WriteLn(os+' created ('+stc(fileSize(outF))+' bytes).');

   Close(outF);
   if error <> 0 then Erase(outF);
end;

function line:string;
var s:string[79];
begin
  fillchar(s,sizeof(s),'Ä');
  s[0]:=chr(79);
  line:=s;
end;

begin
   textmode(co80);
   textattr:=15; write('IPLC');
   textattr:=8;  write(' - ');
   textattr:=15; writeln('Illusion Programming Language Compiler version '+ver);
   textattr:=7;  writeln('Copyright 1996-1998, Illusion Development & Mike Fricker.  All rights reserved.');
   textattr:=8;  writeln(line);
   textattr:=7;  writeln;
   window(1,5,80,25);
   writeln('IPL engine '+cVersion); writeln;

   cInit;
   cInitProcs(cVar,cVars,cID);
   if paramCount = 0 then
      WriteLn('Usage: IPLC <filename[.ips]>') else
      cCompile(paramStr(1));

   cTerminate;
end.
