(*****************************************************************************)
(* Illusion BBS - IPL code parser                                            *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit IPLX;

interface

uses
  crt, dos;

function iplExecute(fn, par : String) : Word;
function iplModule(fn, par : string) : integer;
function xVer : String;

var iplError : Word;

implementation

uses
   Common, StrProc, Menus, Mail4, MiscX;

{$DEFINE ipx}
{$I ipli.pas}

var
   errStr : String;
   error  : Byte;
   xPar   : String;

function xVer : String;
begin
  xVer := cVersion;
end;

function xErrorMsg : String;
var s : ^String;
begin
   new(s);
   case error of
     xrrUeEndOfFile     : s^ := 'Unexpected end-of-file';
     xrrFileNotFound    : s^ := 'File not found, "'+errStr+'"';
     xrrInvalidFile     : s^ := 'File is not executable, "'+errStr+'"';
     xrrVerMismatch     : s^ := 'File version mismatch (script: '+errStr+', parser: '+cVersion+')';
     xrrUnknownOp       : s^ := 'Unknown script command, "'+errStr+'"';
     xrrTooManyVars     : s^ := 'Too many variables initialized at once (max '+st(maxVar)+')';
     xrrMultiInit       : s^ := 'Variable initialized recursively';
     xrrDivisionByZero  : s^ := 'Division by zero';
     xrrMathematical    : s^ := 'Mathematical parsing error';
                     else s^ := '';
   end;
   xErrorMsg := s^;
   dispose(s);
end;

function xExecute(fn : String) : LongInt;

var
   f      : file;
   xVars  : Word;
   xVar   : tVars;
   xpos   : LongInt;
   xid    : String[idVersion];
   xver   : String[idLength-idVersion];
   c      : Char;
   w      : Word;

 function xProcExec(dp : Pointer) : tIqVar; forward;
 procedure xParse(svar : Word); forward;
 function xEvalNumber : Real; forward;

 procedure xInit;
 begin
    error := 0;
    result := 0;
    errStr := '';
    xVars := 0;
    xpos := 0;
    FillChar(xVar,SizeOf(xVar),0);
 end;

 procedure xError(err : Byte; par : String);
 begin
    if error > 0 then Exit;
    error := err;
    xExecute := xpos;
    errStr := par;
 end;

 procedure xToPos(p : LongInt);
 begin
    Seek(f,p+idLength);
    xPos := p+1;
 end;

 function xFilePos : LongInt;
 begin
    xFilePos := filePos(f)-idLength;
 end;

 procedure xGetChar;
 begin
    if (not Eof(f)) and (error = 0) then
    begin
       BlockRead(f,c,1);
       c := Chr(Byte(c) xor ((xFilePos-1) mod 255));
       Inc(xpos);
    end else
    begin
       c := #0;
       xError(xrrUeEndOfFile,'');
    end;
{   sbInfo('(IPL) Executing "'+fn+'" ... [pos '+st(xpos)+']',True);}
 end;

 procedure xGetWord;
 var blah : array[1..2] of byte absolute w;
 begin
    if (not Eof(f)) and (error = 0) then
    begin
       BlockRead(f,blah[1],1);
       blah[1] := blah[1] xor ((xFilePos-1) mod 255);
       Inc(xpos);
       BlockRead(f,blah[2],1);
       blah[2] := blah[2] xor ((xFilePos-1) mod 255);
       Inc(xpos);
    end else
    begin
       w := 0;
       xError(xrrUeEndOfFile,'');
    end;
 end;

 procedure xGoBack;
 begin
    if (xpos = 0) or (error <> 0) then Exit;
    xToPos(xFilePos-1);
 end;

 function xFindVar(i : Word) : Word;
 var x, z : Word;
 begin
    xFindVar := 0;
    if xVars = 0 then Exit;
    z := 0;
    x := 1;
    repeat
       if xVar[x]^.id = i then z := x;
       Inc(x);
    until (x > xVars) or (z > 0);
    xFindVar := z;
 end;

 function xDataPtr(vn : Word; var a : tArray) : Pointer;
 begin
    with xVar[vn]^ do
    begin
       if arr = 0 then xDataPtr := data else
       begin
          if arr = 1 then xDataPtr := @data^[size*(a[1]-1)+1] else
          if arr = 2 then xDataPtr := @data^[size*((a[1]-1)*arrdim[2]+a[2])] else
          if arr = 3 then xDataPtr := @data^[size*((a[1]-1)*(arrdim[2]*arrdim[3])+(a[2]-1)*arrdim[3]+a[3])];
       end;
    end;
 end;

 procedure xCheckArray(vn : Word; var a : tArray);
 var z : Byte;
 begin
    for z := 1 to maxArray do a[z] := 1;
    if xVar[vn]^.arr = 0 then Exit;
    for z := 1 to xVar[vn]^.arr do a[z] := Round(xEvalNumber);
 end;

 function xVarNumReal(vn : Word; var a : tArray) : Real;
 begin
    case xVar[vn]^.vtype of
       vByte   : xVarNumReal := Byte(xDataPtr(vn,a)^);
       vShort  : xVarNumReal := ShortInt(xDataPtr(vn,a)^);
       vWord   : xVarNumReal := Word(xDataPtr(vn,a)^);
       vInt    : xVarNumReal := Integer(xDataPtr(vn,a)^);
       vLong   : xVarNumReal := LongInt(xDataPtr(vn,a)^);
       vReal   : xVarNumReal := Real(xDataPtr(vn,a)^);
    end;
 end;

 function xNumReal(var num; t : tIqVar) : Real;
 begin
    case t of
       vByte   : xNumReal := Byte(num);
       vShort  : xNumReal := ShortInt(num);
       vWord   : xNumReal := Word(num);
       vInt    : xNumReal := Integer(num);
       vLong   : xNumReal := LongInt(num);
       vReal   : xNumReal := Real(num);
    end;
 end;

 function xEvalNumber : Real;
 var cc : Char; vn : Word; me : Boolean; pr : Real;

  procedure ParseNext;
  begin
     xGetChar;
     if c = iqo[oCloseNum] then cc := ^M else cc := c;
  end;

  function add_subt : Real;
  var E : Real; Opr : Char;

   function mult_DIV : Real;
   var S : Real; Opr : Char;

    function Power : Real;
    var T : Real;

     function SignedOp : Real;

      function UnsignedOp : Real;
{     type stdFunc = (fabs, fsqrt, fsqr, fsin, fcos, farctan, fln, flog, fexp, ffact);
           stdFuncList = array[stdFunc] of String[6];
      const StdFuncName : stdFuncList = ('ABS','SQRT','SQR','SIN','COS','ARCTAN','LN','LOG','EXP','FACT');}
      var E, L, Start : Integer; F : Real; {Sf : stdFunc;} ad : tArray;
          ns : String;

       function Fact(I : Integer) : Real;
       begin
          if I > 0 then Fact := I*Fact(I-1) else Fact := 1;
       end;

      begin
         if cc = iqo[oVariable] then
         begin
            xGetWord;
            vn := xFindVar(w);
            xCheckArray(vn,ad);
            F := xVarNumReal(vn,ad);
            ParseNext;
         end else
         if cc = iqo[oProcExec] then
         begin
            F := 0;
            F := xNumReal(F,xProcExec(@F));
            ParseNext;
         end else
         if cc in chDigit then
         begin
            ns := '';
            repeat ns := ns+cc; ParseNext; until not (cc in chDigit);
            if cc = '.' then repeat ns := ns+cc; ParseNext until not (cc in chDigit);
            if cc = 'E' then
            begin
               ns := ns+cc;
               ParseNext;
               repeat ns := ns+cc; ParseNext; until not (cc in chDigit);
            end;
            Val(ns,F,start);
            if start <> 0 then me := True;
         end else
         if cc = iqo[oOpenBrack] then
         begin
            ParseNext;
            F := add_subt;
            if cc = iqo[oCloseBrack] then ParseNext else me := True;
         end else
         begin
            me := True;
            f := 0;
         end;
         UnsignedOp := F;
      end;

     begin
        if cc = '-' then
        begin
           ParseNext;
           SignedOp := -UnsignedOp;
        end else SignedOp := UnsignedOp;
     end;

    begin
       T := SignedOp;
       while cc = '^' do
       begin
          ParseNext;
          if t <> 0 then t := Exp(Ln(abs(t))*SignedOp) else t := 0;
       end;
       Power:=t;
    end;

   begin
      s := Power;
      while cc in ['*','/'] do
      begin
         Opr := cc;
         ParseNext;
         case Opr of
           '*' : s := s*Power;
           '/' : begin pr := Power;
                       if pr = 0 then xError(xrrDivisionByZero,'') else s := s/pr;
                 end;
         end;
      end;
      mult_DIV := s;
   end;

  begin
     E := mult_DIV;
     while cc in ['+','-'] do
     begin
        Opr := cc;
        ParseNext;
        case Opr of
          '+' : e := e+mult_DIV;
          '-' : e := e-mult_DIV;
        end;
     end;
     add_subt := E;
  end;
 begin
    xGetChar; { open num }
{   while Pos(' ',Formula) > 0 do Delete(Formula,Pos(' ',Formula),1);}
{   if Formula[1] = '.' then Formula := '0'+Formula;}
{   if Formula[1] = '+' then Delete(Formula,1,1);}
{   for curPos := 1 to Ord(Formula[0]) do Formula[curPos] := UpCase(Formula[curPos]);}
    me := False;
    ParseNext;
    xEvalNumber := add_subt;
    if cc <> ^M then me := True;
    if me then xError(xrrMathematical,'');
 end;

 function xEvalString : String;
 var rn : Word; x : String; ps : Byte; ad : tArray;
  function esString : String;
  var z : String; ok : Boolean;
  begin
     z := '';
     esString := '';
     ok := False;
     xGetChar; { open " string }

     repeat
        xGetChar;
        if c = iqo[oCloseString] then
        begin
           xGetChar;
           if c = iqo[oCloseString] then z := z+c else
           begin
              xGoBack;
              ok := True;
           end;
        end else z := z+c;
     until (error <> 0) or (ok);
     if error <> 0 then Exit;

     esString := z;
  end;
 begin
    xGetChar; { check first char of string }
    x := '';
    if c = iqo[oOpenString] then
    begin
       xGoBack;
       x := esString;
    end else
    if c = iqo[oVariable] then
    begin
       xGetWord;
       rn := xFindVar(w);
       xCheckArray(rn,ad);
       x := String(xDataPtr(rn,ad)^);
    end else
    if c = iqo[oProcExec] then
    begin
       xProcExec(@x);
    end;
    if error <> 0 then Exit;
    xGetChar;
    if c = iqo[oStrCh] then
    begin
       ps := Round(xEvalNumber);
       x := x[ps];
       xGetChar;
    end;
    if c = iqo[oStrAdd] then x := x+xEvalString else xGoBack;
    xEvalString := x;
 end;

 function xEvalBool : Boolean;
 type tOp = (opNone,opEqual,opNotEqual,opGreater,opLess,opEqGreat,opEqLess);
 var ga, gb, final : Boolean; ta, tb : tIqVar; o : tOp; rn : Word;
     ab, bb, inot : Boolean; af, bf : file; ar, br : Real; as, bs : String; ad : tArray;
 begin
    ta := vNone; tb := vNone;
    ga := False; gb := False;
    o := opNone; inot := False;

    { get the first identifier .. }
    repeat
       xGetChar;
       if c = iqo[oOpenBrack] then
       begin
          ab := xEvalBool;
          ta := vBool;
          xGetChar; { close bracket }
          ga := True;
       end else
       if c = iqo[oNot] then
       begin
          inot := not inot;
       end else
       if c = iqo[oTrue] then
       begin
          ab := True;
          ta := vBool;
          ga := True;
       end else
       if c = iqo[oFalse] then
       begin
          ab := False;
          ta := vBool;
          ga := True;
       end else
       if c = iqo[oVariable] then
       begin
          xGetWord; { variable id }
          rn := xFindVar(w);
          xCheckArray(rn,ad);
          ta := xVar[rn]^.vType;
          if ta = vBool then ab := ByteBool(xDataPtr(rn,ad)^) else
          if ta = vStr then as := String(xDataPtr(rn,ad)^) else
          if ta in vnums then ar := xVarNumReal(rn,ad);
          ga := True;
       end else
       if c = iqo[oProcExec] then
       begin
          ta := xProcExec(@as);
          if ta = vBool then ab := ByteBool(as[0]) else
{         if ta = vStr then as := String(xVar[rn]^.data^) else}
          if ta in vnums then ar := xNumReal(as,ta);
          ga := True;
       end else
       if c = iqo[oOpenNum] then
       begin
          xGoBack;
          ar := xEvalNumber;
          ta := vReal;
          ga := True;
       end else
       if c in ['#','"'] then
       begin
          xGoBack;
          as := xEvalString;
          ta := vStr;
          ga := True;
       end;
    until (error <> 0) or (ga);
    if error <> 0 then Exit;

    xGetChar; { get the operator .. }
    if c = iqo[oOpEqual] then o := opEqual else
    if c = iqo[oOpNotEqual] then o := opNotEqual else
    if c = iqo[oOpGreater] then o := opGreater else
    if c = iqo[oOpLess] then o := opLess else
    if c = iqo[oOpEqGreat] then o := opEqGreat else
    if c = iqo[oOpEqLess] then o := opEqLess else
    begin
       final := ab;
       xGoBack;
    end;

    if o <> opNone then
    begin

    { get the second identifier if necessary .. }
    repeat
       xGetChar;
       if c = iqo[oOpenBrack] then
       begin
          bb := xEvalBool;
          tb := vBool;
          xGetChar; { close bracket }
          gb := True;
       end else
       if c = iqo[oTrue] then
       begin
          bb := True;
          tb := vBool;
          gb := True;
       end else
       if c = iqo[oFalse] then
       begin
          bb := False;
          tb := vBool;
          gb := True;
       end else
       if c = iqo[oVariable] then
       begin
          xGetWord; { variable id }
          rn := xFindVar(w);
          xCheckArray(rn,ad);
          tb := xVar[rn]^.vType;
          if tb = vBool then bb := ByteBool(xDataPtr(rn,ad)^) else
          if tb = vStr then bs := String(xDataPtr(rn,ad)^) else
          if tb in vnums then br := xVarNumReal(rn,ad);
          gb := True;

       end else
       if c = iqo[oProcExec] then
       begin
          tb := xProcExec(@bs);
          if tb = vBool then bb := ByteBool(bs[0]) else
          if tb in vnums then br := xNumReal(bs,tb);
          gb := True;
       end else
       if c = iqo[oOpenNum] then
       begin
          xGoBack;
          br := xEvalNumber;
          tb := vReal;
          gb := True;
       end else
       if c in ['#','"'] then
       begin
          xGoBack;
          bs := xEvalString;
          tb := vStr;
          gb := True;
       end;
    until (error <> 0) or (gb);
    if error <> 0 then Exit;
    final := False;

    case o of
      opEqual    : if ta = vStr then  final := as = bs else
                   if ta = vBool then final := ab = bb else
                                      final := ar = br;
      opNotEqual : if ta = vStr then  final := as <> bs else
                   if ta = vBool then final := ab <> bb else
                                      final := ar <> br;
      opGreater  : if ta = vStr then  final := as > bs else
                   if ta = vBool then final := ab > bb else
                                      final := ar > br;
      opLess     : if ta = vStr then  final := as < bs else
                   if ta = vBool then final := ab < bb else
                                      final := ar < br;
      opEqGreat  : if ta = vStr then  final := as >= bs else
                   if ta = vBool then final := ab >= bb else
                                      final := ar >= br;
      opEqLess   : if ta = vStr  then final := as <= bs else
                   if ta = vBool then final := ab <= bb else
                                      final := ar <= br;
    end;

    end;

    if inot then final := not final;
    xGetChar;
    if c = iqo[oAnd] then final := xEvalBool and final else
    if c = iqo[oOr]  then final := xEvalBool or final else
           xGoBack;

    xEvalBool := final;
 end;

 procedure xSetString(vn : Word; var a : tArray; s : String);
 begin
    if Ord(s[0]) >= xVar[vn]^.size then s[0] := Chr(xVar[vn]^.size-1);
    Move(s,xDataPtr(vn,a)^,xVar[vn]^.size);
 end;

 procedure xSetVariable(vn : Word);
 var ad : tArray;
 begin
    xCheckArray(vn,ad);
    case xVar[vn]^.vtype of
       vStr    : xSetString(vn,ad,xEvalString);
       vByte   : Byte(xDataPtr(vn,ad)^) := Round(xEvalNumber);
       vShort  : ShortInt(xDataPtr(vn,ad)^) := Round(xEvalNumber);
       vWord   : Word(xDataPtr(vn,ad)^) := Round(xEvalNumber);
       vInt    : Integer(xDataPtr(vn,ad)^) := Round(xEvalNumber);
       vLong   : LongInt(xDataPtr(vn,ad)^) := Round(xEvalNumber);
       vReal   : Real(xDataPtr(vn,ad)^) := xEvalNumber;
       vBool   : ByteBool(xDataPtr(vn,ad)^) := xEvalBool;
     { vFile   : will never occur ? }
    end;
 end;

 procedure xSetNumber(vn : Word; r : Real; var a : tArray);
 begin
    case xVar[vn]^.vtype of
       vByte   : Byte(xDataPtr(vn,a)^) := Round(r);
       vShort  : ShortInt(xDataPtr(vn,a)^) := Round(r);
       vWord   : Word(xDataPtr(vn,a)^) := Round(r);
       vInt    : Integer(xDataPtr(vn,a)^) := Round(r);
       vLong   : LongInt(xDataPtr(vn,a)^) := Round(r);
       vReal   : Real(xDataPtr(vn,a)^) := r;
    end;
 end;

 function xDataSize(vn : Word) : Word;
 var sz, z : Word;
 begin
    with xVar[vn]^ do
    begin
       sz := size;
       for z := 1 to arr do sz := sz*arrdim[z];
       xDataSize := sz;
    end;
 end;

 procedure xCreateVar;
 var t : tIqVar; ci, ni, fi, slen : Word; cn, ar : Byte; ard : tArray;
 begin
    xGetChar; { variable type }
    t := cVarType(c);
    xGetChar; { check for array/strlen }
    slen := 256;
    ar := 0;
    for cn := 1 to maxArray do ard[cn] := 1;
    if c = iqo[oStrLen] then
    begin
       slen := Round(xEvalNumber)+1;
       xGetChar; { now check for array }
    end;
    if c = iqo[oArrDef] then
    begin
       xGetWord;
       ar := w;
       for cn := 1 to ar do ard[cn] := Round(xEvalNumber);
    end; {  else xGoBack;  -- must be a normal string }
    xGetWord; { number of vars }
    ni := w;
    fi := xVars+1;
    for ci := 1 to ni do if error = 0 then
    begin
       if xVars >= maxVar then xError(xrrTooManyVars,'') else
       begin
          xGetWord; { variable id }
          if xFindVar(w) > 0 then
          begin
             xError(xrrMultiInit,'');
             Exit;
          end;
          Inc(xVars);
          New(xVar[xVars]);
          with xVar[xVars]^ do
          begin
             id := w;
             vtype := t;
           { param }
             numPar := 0;
             proc := False;
             ppos := 0;
             if t = vStr then size := slen else size := xVarSize(t);
             kill := True;
             arr := ar;
             arrdim := ard;

             dsize := xDataSize(xVars);
             GetMem(data,dsize);
             FillChar(data^,dsize,0);
          end;
       end;
    end;

    if error <> 0 then Exit;
    xGetChar; { check for setvar }
    if c = iqo[oVarDef] then
    begin
       xSetVariable(fi);
       for ci := fi+1 to xVars do Move(xVar[fi]^.data^,xVar[ci]^.data^,xVar[fi]^.dsize);
    end else xGoBack;
 end;

 procedure xLoadDir(Filename: String; RecNum: LongInt);
 var Dir: ULFrec; DirF: File of ULFrec;
     x: Word; b: ByteBool;
 begin
   Assign(DirF,Filename);
   {$I-} Reset(DirF); {$I+}
   ioError := ioResult;
   if (ioError<>0) then begin exit; end;
   {$I-} Seek(DirF,RecNum); {$I+}
   ioError := ioResult;
   if (ioError<>0) then begin Close(DirF); exit; end;
   {$I-} Read(DirF,Dir); {$I+}
   ioError := ioResult;
   if (ioError<>0) then begin Close(DirF); exit; end;
   Close(DirF);
   x := xDIRstart-1;
   with Dir do
   begin
      Move(Filename       ,xVar[x+01]^.data^,SizeOf(Filename     ));
      Move(Description    ,xVar[x+02]^.data^,SizeOf(Description  ));
      Move(FilePoints     ,xVar[x+03]^.data^,SizeOf(FilePoints   ));
      Move(NAcc           ,xVar[x+04]^.data^,SizeOf(NAcc         ));
      Move(Blocks         ,xVar[x+05]^.data^,SizeOf(Blocks       ));
      Move(Owner          ,xVar[x+06]^.data^,SizeOf(Owner        ));
      Move(StOwner        ,xVar[x+07]^.data^,SizeOf(StOwner      ));
      Move(Date           ,xVar[x+08]^.data^,SizeOf(Date         ));
      Move(VPointer       ,xVar[x+09]^.data^,SizeOf(VPointer     ));
      b := NotVal in FileStat;
      Move(b              ,xVar[x+10]^.data^,1);
      b := IsRequest in FileStat;
      Move(b              ,xVar[x+11]^.data^,1);
      b := ResumeLater in FileStat;
      Move(b              ,xVar[x+12]^.data^,1);
   end;
 end;

 procedure xSaveDir(Filename: String; RecNum: LongInt);
 var Dir: ULFrec; DirF: File of ULFrec;
     x: Word; b: ByteBool;
 begin
   Assign(DirF,Filename);
   {$I-} Reset(DirF); {$I+}
   ioError := ioResult;
   if (ioError<>0) then exit;
   {$I-} Seek(DirF,RecNum); {$I+}
   ioError := ioResult;
   if (ioError<>0) then begin Close(DirF); exit; end;
   x := xDIRstart-1;
   fillchar(Dir,SizeOf(Dir),#0);
   with Dir do
   begin
      Move(xVar[x+01]^.data^,Filename       ,SizeOf(Filename     ));
      Move(xVar[x+02]^.data^,Description    ,SizeOf(Description  ));
      Move(xVar[x+03]^.data^,FilePoints     ,SizeOf(FilePoints   ));
      Move(xVar[x+04]^.data^,NAcc           ,SizeOf(NAcc         ));
      Move(xVar[x+05]^.data^,Blocks         ,SizeOf(Blocks       ));
      Move(xVar[x+06]^.data^,Owner          ,SizeOf(Owner        ));
      Move(xVar[x+07]^.data^,StOwner        ,SizeOf(StOwner      ));
      Move(xVar[x+08]^.data^,Date           ,SizeOf(Date         ));
      Move(xVar[x+09]^.data^,VPointer       ,SizeOf(VPointer     ));
      if ByteBool(xVar[x+10]^.data^[1]) then include(FileStat,NotVal) else exclude(FileStat,NotVal);
      if ByteBool(xVar[x+11]^.data^[1]) then include(FileStat,IsRequest) else exclude(FileStat,IsRequest);
      if ByteBool(xVar[x+12]^.data^[1]) then include(FileStat,ResumeLater) else exclude(FileStat,ResumeLater);
   end;
   {$I-} Write(DirF,Dir); {$I+}
   ioError := ioResult;
   Close(DirF);
 end;

 procedure xLoadFB(RecNum: LongInt);
 var FB: ULrec; FBF: File of ULrec;
     x: Word; b: ByteBool;
 begin
   Assign(FBF,systat^.datapath+'FBOARDS.DAT');
   {$I-} Reset(FBF); {$I+}
   ioError := ioResult;
   if (ioError<>0) then begin exit; end;
   {$I-} Seek(FBF,RecNum); {$I+}
   ioError := ioResult;
   if (ioError<>0) then begin Close(FBF); exit; end;
   {$I-} Read(FBF,FB); {$I+}
   ioError := ioResult;
   if (ioError<>0) then begin Close(FBF); exit; end;
   Close(FBF);
   x := xFBstart-1;
   with FB do
   begin
      Move(Name           ,xVar[x+01]^.data^,SizeOf(Name         ));
      Move(Filename       ,xVar[x+02]^.data^,SizeOf(Filename     ));
      Move(DLPath         ,xVar[x+03]^.data^,SizeOf(DLPath       ));
      Move(MaxFiles       ,xVar[x+04]^.data^,SizeOf(MaxFiles     ));
      Move(ArcType        ,xVar[x+05]^.data^,SizeOf(ArcType      ));
      Move(CmtType        ,xVar[x+06]^.data^,SizeOf(CmtType      ));
      Move(Acs            ,xVar[x+07]^.data^,SizeOf(Acs          ));
      Move(ULAcs          ,xVar[x+08]^.data^,SizeOf(ULAcs        ));
      Move(NameAcs        ,xVar[x+09]^.data^,SizeOf(NameAcs      ));
      Move(PermIndx       ,xVar[x+10]^.data^,SizeOf(PermIndx     ));
      b := fbNoRatio in FBStat;
      Move(b              ,xVar[x+11]^.data^,1);
      b := fbUnhidden in FBStat;
      Move(b              ,xVar[x+12]^.data^,1);
      b := fbDirDLPath in FBStat;
      Move(b              ,xVar[x+13]^.data^,1);
      b := fbUseGifSpecs in FBStat;
      Move(b              ,xVar[x+14]^.data^,1);
   end;
 end;

 procedure xSaveFB(RecNum: LongInt);
 var FB: ULrec; FBF: File of ULrec;
     x: Word; b: ByteBool;
 begin
   Assign(FBF,systat^.datapath+'FBOARDS.DAT');
   {$I-} Reset(FBF); {$I+}
   ioError := ioResult;
   if (ioError<>0) then exit;
   {$I-} Seek(FBF,RecNum); {$I+}
   ioError := ioResult;
   if (ioError<>0) then begin Close(FBF); exit; end;
   x := xFBstart-1;
   fillchar(FB,SizeOf(FB),#0);
   with FB do
   begin
      Move(xVar[x+01]^.data^,Name           ,SizeOf(Name         ));
      Move(xVar[x+02]^.data^,Filename       ,SizeOf(Filename     ));
      Move(xVar[x+03]^.data^,DLPath         ,SizeOf(DLPath       ));
      Move(xVar[x+04]^.data^,MaxFiles       ,SizeOf(MaxFiles     ));
      Move(xVar[x+05]^.data^,ArcType        ,SizeOf(ArcType      ));
      Move(xVar[x+06]^.data^,CmtType        ,SizeOf(CmtType      ));
      Move(xVar[x+07]^.data^,Acs            ,SizeOf(Acs          ));
      Move(xVar[x+08]^.data^,ULAcs          ,SizeOf(ULAcs        ));
      Move(xVar[x+09]^.data^,NameAcs        ,SizeOf(NameAcs      ));
      Move(xVar[x+10]^.data^,PermIndx       ,SizeOf(PermIndx     ));
      if ByteBool(xVar[x+11]^.data^[1]) then include(FBStat,fbNoRatio) else exclude(FBStat,fbNoRatio);
      if ByteBool(xVar[x+12]^.data^[1]) then include(FBStat,fbUnhidden) else exclude(FBStat,fbUnhidden);
      if ByteBool(xVar[x+13]^.data^[1]) then include(FBStat,fbDirDLPath) else exclude(FBStat,fbDirDLPath);
      if ByteBool(xVar[x+14]^.data^[1]) then include(FBStat,fbUseGIFSpecs) else exclude(FBStat,fbUseGIFSpecs);
   end;
   {$I-} Write(FBF,FB); {$I+}
   ioError := ioResult;
   Close(FBF);
 end;

 procedure xGetUser;
 var x : Word; ss : String[1]; b : ByteBool; l : LongInt;
 begin
    x := xUstart-1;
    with ThisUser do
    begin
      Move(UserNum        ,xVar[x+01]^.data^,SizeOf(UserNum      ));
      Move(Name           ,xVar[x+02]^.data^,SizeOf(Name         ));
      Move(RealName       ,xVar[x+03]^.data^,SizeOf(RealName     ));
      Move(PW             ,xVar[x+04]^.data^,SizeOf(PW           ));
      Move(Ph             ,xVar[x+05]^.data^,SizeOf(Ph           ));
      Move(Bday           ,xVar[x+06]^.data^,SizeOf(Bday         ));
      Move(CityState      ,xVar[x+07]^.data^,SizeOf(CityState    ));
      Move(Street         ,xVar[x+08]^.data^,SizeOf(Street       ));
      Move(UserNote       ,xVar[x+09]^.data^,SizeOf(UserNote     ));
      ss := Sex;
      Move(ss             ,xVar[x+10]^.data^,SizeOf(ss           ));
      Move(SL             ,xVar[x+11]^.data^,SizeOf(SL           ));
      Move(DSL            ,xVar[x+12]^.data^,SizeOf(DSL          ));
      l := value(spd);
      Move(l              ,xVar[x+13]^.data^,SizeOf(l            ));
      Move(LoggedOn       ,xVar[x+14]^.data^,SizeOf(LoggedOn     ));
      Move(board          ,xVar[x+15]^.data^,SizeOf(board        ));
      Move(ccuboards[1][fileboard],xVar[x+16]^.data^,SizeOf(ccuboards[1][fileboard]));
      Move(LastOn         ,xVar[x+17]^.data^,SizeOf(LastOn       ));
      Move(PageLen        ,xVar[x+18]^.data^,SizeOf(PageLen      ));
      l := MailWaitingForUser(usernum);
      Move(l              ,xVar[x+19]^.data^,SizeOf(l            ));
      Move(conference     ,xVar[x+20]^.data^,SizeOf(conference   ));
      Move(FirstOn        ,xVar[x+22]^.data^,SizeOf(FirstOn      ));
      Move(UserStartMenu  ,xVar[x+23]^.data^,SizeOf(UserStartMenu));
      Move(Note           ,xVar[x+24]^.data^,SizeOf(Note         ));
      Move(MsgPost        ,xVar[x+25]^.data^,SizeOf(MsgPost      ));
      Move(EmailSent      ,xVar[x+26]^.data^,SizeOf(EmailSent    ));
      Move(Uploads        ,xVar[x+27]^.data^,SizeOf(Uploads      ));
      Move(Downloads      ,xVar[x+28]^.data^,SizeOf(Downloads    ));
      Move(Uk             ,xVar[x+29]^.data^,SizeOf(Uk           ));
      Move(Dk             ,xVar[x+30]^.data^,SizeOf(Dk           ));
      Move(OnToday        ,xVar[x+31]^.data^,SizeOf(OnToday      ));
      b := Ansi in AC;
      Move(b              ,xVar[x+32]^.data^,1);
      b := Avatar in AC;
      Move(b              ,xVar[x+33]^.data^,1);
      b := Rip in AC;
      Move(b              ,xVar[x+34]^.data^,1);
      Move(Deleted        ,xVar[x+35]^.data^,1);
      b := not (Novice in AC);
      Move(b              ,xVar[x+36]^.data^,1);
      b := OneKey in AC;
      Move(b              ,xVar[x+37]^.data^,1);
      b := Pause in AC;
      Move(b              ,xVar[x+38]^.data^,1);
      Move(FilePoints     ,xVar[x+39]^.data^,SizeOf(FilePoints   ));
      Move(zipCode        ,xVar[x+40]^.data^,SizeOf(zipCode      ));
      Move(LineLen        ,xVar[x+41]^.data^,SizeOf(LineLen      ));
      Move(EdType         ,xVar[x+42]^.data^,SizeOf(EdType       ));
      Move(TimeBank       ,xVar[x+43]^.data^,SizeOf(TimeBank     ));
      Move(tlToday        ,xVar[x+44]^.data^,SizeOf(tlToday      ));
      Move(Credit         ,xVar[x+45]^.data^,SizeOf(Credit       ));
      Move(WhereBBS       ,xVar[x+46]^.data^,SizeOf(WhereBBS     ));
      Move(Occupation     ,xVar[x+47]^.data^,SizeOf(Occupation   ));
      Move(Computer       ,xVar[x+48]^.data^,SizeOf(Computer     ));
    end;
 end;

 procedure xPutUser;
 var x : Word; ss : String[1]; l : LongInt;
 begin
    x := xUstart-1;
    with ThisUser do
    begin
      Move(xVar[x+01]^.data^,UserNum        ,SizeOf(UserNum      ));
      Move(xVar[x+02]^.data^,Name           ,SizeOf(Name         ));
      Move(xVar[x+03]^.data^,RealName       ,SizeOf(RealName     ));
      Move(xVar[x+04]^.data^,PW             ,SizeOf(PW           ));
      Move(xVar[x+05]^.data^,Ph             ,SizeOf(Ph           ));
      Move(xVar[x+06]^.data^,Bday           ,SizeOf(Bday         ));
      Move(xVar[x+07]^.data^,CityState      ,SizeOf(CityState    ));
      Move(xVar[x+08]^.data^,Street         ,SizeOf(Street       ));
      Move(xVar[x+09]^.data^,UserNote       ,SizeOf(UserNote     ));
      Move(xVar[x+10]^.data^,ss             ,SizeOf(ss           ));
      Sex := ss[1];
      Move(xVar[x+11]^.data^,SL             ,SizeOf(SL           ));
      Move(xVar[x+12]^.data^,DSL            ,SizeOf(DSL          ));
      Move(xVar[x+14]^.data^,LoggedOn       ,SizeOf(LoggedOn     ));
      Move(xVar[x+15]^.data^,l              ,SizeOf(l            ));
      changeboard(l);
      Move(xVar[x+16]^.data^,l              ,SizeOf(l            ));
      changefileboard(ccuboards[0][l]);
      Move(xVar[x+17]^.data^,LastOn         ,SizeOf(LastOn       ));
      Move(xVar[x+18]^.data^,PageLen        ,SizeOf(PageLen      ));
      Move(xVar[x+20]^.data^,conference     ,SizeOf(conference   ));
      Move(xVar[x+22]^.data^,FirstOn        ,SizeOf(FirstOn      ));
      Move(xVar[x+23]^.data^,UserStartMenu  ,SizeOf(UserStartMenu));
      Move(xVar[x+24]^.data^,Note           ,SizeOf(Note         ));
      Move(xVar[x+25]^.data^,MsgPost        ,SizeOf(MsgPost      ));
      Move(xVar[x+26]^.data^,EmailSent      ,SizeOf(EmailSent    ));
      Move(xVar[x+27]^.data^,Uploads        ,SizeOf(Uploads      ));
      Move(xVar[x+28]^.data^,Downloads      ,SizeOf(Downloads    ));
      Move(xVar[x+29]^.data^,Uk             ,SizeOf(Uk           ));
      Move(xVar[x+30]^.data^,Dk             ,SizeOf(Dk           ));
      Move(xVar[x+31]^.data^,OnToday        ,SizeOf(OnToday      ));
      if ByteBool(xVar[x+32]^.data^[1]) then include(AC,ANSI) else exclude(AC,ANSI);
      if ByteBool(xVar[x+33]^.data^[1]) then include(AC,Avatar) else exclude(AC,Avatar);
      if ByteBool(xVar[x+34]^.data^[1]) then include(AC,Rip) else exclude(AC,Rip);
      Deleted:=ByteBool(xVar[x+35]^.data^[1]);
      if ByteBool(xVar[x+36]^.data^[1]) then exclude(AC,Novice) else include(AC,Novice);
      if ByteBool(xVar[x+37]^.data^[1]) then include(AC,OneKey) else exclude(AC,OneKey);
      if ByteBool(xVar[x+38]^.data^[1]) then include(AC,Pause) else exclude(AC,Pause);
      Move(xVar[x+39]^.data^,FilePoints     ,SizeOf(FilePoints   ));
      Move(xVar[x+40]^.data^,ZipCode        ,SizeOf(ZipCode      ));
      Move(xVar[x+41]^.data^,LineLen        ,SizeOf(LineLen      ));
      Move(xVar[x+42]^.data^,EdType         ,SizeOf(EdType       ));
      Move(xVar[x+43]^.data^,TimeBank       ,SizeOf(TimeBank     ));
      Move(xVar[x+44]^.data^,tlToday        ,SizeOf(tlToday      ));
      Move(xVar[x+45]^.data^,Credit         ,SizeOf(Credit       ));
      Move(xVar[x+46]^.data^,WhereBBS       ,SizeOf(WhereBBS     ));
      Move(xVar[x+47]^.data^,Occupation     ,SizeOf(Occupation   ));
      Move(xVar[x+48]^.data^,Computer       ,SizeOf(Computer     ));
    end;
 end;

 function mStrParam(ps : String; n : Byte) : String;
 var z, x : Byte;
 begin
   z := 1;
   mStrParam := '';
   ps := cleanUp(ps);
   while (Length(ps) > 0) and (z < n) do
   begin
      x := Pos(' ',ps);
      if x > 0 then
      begin
         Delete(ps,1,x);
         ps := cleanUp(ps);
      end else ps := '';
      Inc(z);
   end;
   if ps = '' then Exit;

   x := Pos(' ',ps);
   if x > 0 then Delete(ps,x,255);
   mStrParam := ps;
 end;

 function mStrParCnt(ps : String) : Byte;
 var z, x : Byte;
 begin
   z := 0;
   mStrParCnt := 0;
   ps := cleanUp(ps);
   if ps = '' then Exit;

   while (Length(ps) > 0) do
   begin
      x := Pos(' ',ps);
      if x > 0 then
      begin
         Delete(ps,1,x);
         ps := cleanUp(ps);
      end else ps := '';
      Inc(z);
   end;

   mStrParCnt := z;
 end;

 procedure xFileReadLn(var f : file; var s; len : Word);
 var c : Char; z : String;
 begin
    c := #0;
    z := '';
    while (not eof(f)) and (not (c in [#13,#10])) do
    begin
       {$I-}
       BlockRead(f,c,1);
       {$I+}
       if not (c in [#13,#10]) then z := z+c;
    end;
    if (z = '') and (eof(f)) then
    begin
       if ioError = 0 then ioError := 1;
    end else
    begin
       Move(z,s,len);
       {$I-}
       repeat BlockRead(f,c,1); until (eof(f)) or (not (c in [#13,#10]));
       if not eof(f) then Seek(f,filePos(f)-1);
       {$I+}
       if ioError = 0 then ioError := ioResult;
    end;
 end;

 procedure xFileWriteLn(var f : file; var s : String; len : Word);
 var lf : String[2];
 begin
    lf := #13#10;
    {$I-}
    if (len > 0) then BlockWrite(f,s[1],len);
    BlockWrite(f,lf[1],2);
    {$I+}
    if (ioError = 0) and (ioResult <> 0) then ioError := ioResult;
 end;

 function xProcExec(dp : Pointer) : tIqVar;
 type
    tParam = record
       s : array[1..maxParam] of String;
       b : array[1..maxParam] of Byte;
       h : array[1..maxParam] of ShortInt;
       w : array[1..maxParam] of Word;
       i : array[1..maxParam] of Integer;
       l : array[1..maxParam] of LongInt;
       r : array[1..maxParam] of Real;
       o : array[1..maxParam] of Boolean;
{      f : array[1..maxParam] of File;}
       v : array[1..maxParam] of Word;
    end;
 var vn, x, pid, sv : Word; p : tParam; ts : String; tb : ByteBool; ty : Byte;
     sub : LongInt; tl : LongInt; ss : array[1..maxParam] of Word; ttb : Boolean;
     tw, tw1 : Word; counter : Byte; tr : Real;
     abort,next : Boolean;
  procedure par(var dat; siz : Word);
  begin
     if dp <> nil then Move(dat,dp^,siz);
  end;
 begin
    xGetWord; { proc id # }
    pid := w;
    vn := xFindVar(pid);
    for x := 1 to xVar[vn]^.numPar do with xVar[vn]^ do
    begin
       if param[x] = UpCase(param[x]) then
       begin
          xGetChar; { variable }
          xGetWord; { var id }
          p.v[x] := xFindVar(w);
          if xVar[p.v[x]]^.vType = vStr then ss[x] := xVar[p.v[x]]^.size;
       end else
       case param[x] of
          's' : p.s[x] := xEvalString;
          'b' : p.b[x] := Round(xEvalNumber);
          'h' : p.h[x] := Round(xEvalNumber);
          'w' : p.w[x] := Round(xEvalNumber);
          'i' : p.i[x] := Round(xEvalNumber);
          'l' : p.l[x] := Round(xEvalNumber);
          'r' : p.r[x] := xEvalNumber;
          'o' : p.o[x] := xEvalBool;
       end;
       xGetChar; { / var separator }
    end;

    xProcExec := xVar[vn]^.vtype;

    if xVar[vn]^.ppos > 0 then
    begin
       sub := xFilePos;

       xToPos(xVar[vn]^.ppos);
{      xPos := xVar[vn]^.ppos;}

       sv := xVars;

       for x := 1 to xVar[vn]^.numPar do
       begin
          if xVars >= maxVar then xError(errTooManyVars,'');
          Inc(xVars);
          New(xVar[xVars]);
          with xVar[xVars]^ do
          begin
             id := xVar[vn]^.pid[x];
             vtype := cVarType(xVar[vn]^.param[x]);
             numPar := 0;
             proc := False;
             ppos := 0;
             if vtype = vStr then size := ss[xVars] else size := xVarSize(vtype);
             arr := 0;
             {arrdim}
             dsize := xDataSize(xVars);

             if xVar[vn]^.param[x] = upCase(xVar[vn]^.param[x]) then
             begin
                data := xVar[p.v[x]]^.data;
                kill := False;
             end else
             begin
                GetMem(data,dsize);
                case xVar[vn]^.param[x] of
                   's' : begin
                            if Ord(p.s[x,0]) >= size then p.s[x,0] := Chr(size-1);
                            Move(p.s[x],data^,size);
                         end;
                   'b' : Byte(Pointer(data)^) := p.b[x];
                   'h' : ShortInt(Pointer(data)^) := p.h[x];
                   'w' : Word(Pointer(data)^) := p.w[x];
                   'i' : Integer(Pointer(data)^) := p.i[x];
                   'l' : LongInt(Pointer(data)^) := p.l[x];
                   'r' : Real(Pointer(data)^) := p.r[x];
                   'o' : Boolean(Pointer(data)^) := p.o[x];
                 { 'f' : should never occur ? }
                end;
                kill := True;
             end;
          end;
       end;

       if xVar[vn]^.vtype <> vNone then
       begin
{         xVar[vn]^.size := xVarSize(xVar[vn]^.vtype);}
          xVar[vn]^.dsize := xDataSize(vn);
          GetMem(xVar[vn]^.data,xVar[vn]^.dsize);
          FillChar(xVar[vn]^.data^,xVar[vn]^.dsize,0);
       end;

       xParse(sv);

       if xVar[vn]^.vtype <> vNone then
       begin
          if dp <> nil then Move(xVar[vn]^.data^,dp^,xVar[vn]^.dsize);
          FreeMem(xVar[vn]^.data,xVar[vn]^.dsize);
          xVar[vn]^.dsize := 0;
       end;

       xToPos(sub);

       Exit;
    end;

 { %%%%% internal procedures %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% }

    case pid of

     { output routines }
       0   : prompt(p.s[1]);                            { out             }
       1   : print(p.s[1]);                             { outln           }
       2   : cls;                                       { clrscr          }
       3   : sprompt('|LC');                            { clreol          }
       4   : sprompt('|PG');                            { beep            }
       5   : spromptt1(p.s[1],false,true);              { cout            }
       6   : begin spromptt1(p.s[1],false,true); nl; end; { coutln        }
       7   : for counter:=1 to p.b[1] do nl;            { dnln            }
       8   : ansig(p.b[1],p.b[2]);                      { gotoxy          }
       9   : sprompt(#27+'['+cstr(p.b[1])+'A');         { posup           }
       10  : sprompt(#27+'['+cstr(p.b[1])+'B');         { posdown         }
       11  : sprompt(#27+'['+cstr(p.b[1])+'D');         { posleft         }
       12  : sprompt(#27+'['+cstr(p.b[1])+'C');         { posright        }
       13  : ;{oPosX(p.b[1]);                             { posx            }
       14  : ;{oPosY(p.b[1]);                             { posy            }
       15  : if (p.b[1] in [0..7]) then cl(p.b[1]+16);  { setback         }
       16  : if (p.b[1] in [0..15]) then cl(p.b[1]);    { setfore         }
       17  : begin                                      { setblink        }
               if (p.o[1]) and (curco<128) then inc(curco,128);
               if (not p.o[1]) and (curco>127) then dec(curco,128);
             end;
       18  : begin                                      { setcolor        }
               if (p.b[1] in [0..15]) then cl(p.b[1]);
               if (p.b[2] in [0..7]) then cl(p.b[2]+16);
             end;
       19  : sprompt(p.s[1]);                             { sout            }
       20  : sprint(p.s[1]);                              { soutln          }
       21  : spstr(p.w[1]);                               { strout          }
       22  : begin spstr(p.w[1]); nl; end;                { stroutln        }
       23  : spromptt1(p.s[1],false,true);                { xout            }
       24  : begin spromptt1(p.s[1],false,true); nl; end; { xoutln          }
       25  : spromptt1(p.s[1],false,false);               { aout            }
       26  : begin printf(p.s[1]); tb:=not nofile; par(tb,1); end;              { showtext }
       27  : begin pfl(p.s[1],abort,next,true); tb:=not nofile; par(tb,1); end; { showfile }
       28  : nl;                                          { fline           }
       29  : begin ty := crt.WhereX; par(ty,1); end;      { wherex          }
       30  : begin ty := crt.WhereY; par(ty,1); end;      { wherey          }
       31  : delay(p.w[1]);
       32  : begin sound(p.w[1]); delay(p.w[2]); nosound; end;
       33  : addwave(p.s[1],p.s[2],txt);
       34  : clearwaves;

     { input routines }
       100 : begin ts[0] := #1; GetKey(ts[1]); par(ts,256); end; { inkey      }
       101 : begin ts := iGetString(p.s[2],p.s[3],p.s[4],st(p.b[5]),p.s[1],''); par(ts,256); end;
       102 : begin ts := iGetString(p.s[2],p.s[3],p.s[4],st(p.b[5]),p.s[1],st(p.b[6])); par(ts,256); end;
       103 : begin tb := (not hangup) and (not empty); par(tb,1); end;
       104 : begin ts := iReadDate(p.s[1]); par(ts,256); end;
       105 : begin ts := iReadTime(p.s[1]); par(ts,256); end;
       106 : begin ts := iReadPhone(p.s[1]); par(ts,256); end;
       107 : begin ts := iReadPostalCode; par(ts,256); end;
       108 : begin ts := iReadZipCode; par(ts,256); end;
       109 : begin dyny:=p.o[1]; tb := yn; par(tb,1); end;       { inyesno    }

     { string functions }
       200 : begin ts := upStr(p.s[1]); par(ts,256); end;            { strup  }
       201 : begin ts := strLow(p.s[1]); par(ts,256); end;           { strlow }
       202 : begin ts := b2st(p.o[1]); par(ts,256); end;             { stryesno }
       203 : begin ty := Pos(p.s[1],p.s[2]); par(ty,1); end;         { strpos }
       204 : begin ts := cleanUp(p.s[1]); par(ts,256); end;          { strtrim }
       205 : begin ts := strMixed(p.s[1]); par(ts,256); end;         { strmixed }
       206 : begin ts := stripcolor(p.s[1]); par(ts,256); end;       { strnocol }
       207 : begin ts := mln(p.s[1],p.b[2]); par(ts,256); end;       { strsize }
       208 : begin ts := mlnnomci(p.s[1],p.b[2]); par(ts,256); end;  { strsizenc }
       209 : begin ts := mrn(p.s[1],p.b[2]); par(ts,256); end;       { strsizer }
       210 : begin ts := cstr(p.l[1]); par(ts,256); end;             { strint }
       211 : begin ts := strReal(p.r[1],p.b[2],p.b[3]); par(ts,256); end;    { strreal }
       212 : begin ts := stc(p.l[1]); par(ts,256); end;              { strintc }
       213 : ; { strsquish }
       214 : begin ts := strReplace(p.s[1],p.s[2],p.s[3]); par(ts,256); end; { strreplace }
       215 : begin ts := Copy(p.s[1],p.b[2],p.b[3]); par(ts,256); end;       { strcopy }
       216 : begin ts := p.s[1]; Delete(ts,p.b[2],p.b[3]); par(ts,256); end; { strdel }
       217 : begin ts := sRepeat(p.s[1,1],p.b[2]); par(ts,256); end; { strrepeat }
       218 : begin ty := Ord(p.s[1,0]); par(ty,1); end;              { strlen }
       219 : ; { strcode }
       220 : begin ts := getstr(p.w[1]); par(ts,256); end;           { strget }
       221 : begin tl := value(p.s[1]); par(tl,4); end;              { strval }

     { ipl-related routines }
       300 : begin ts := cVersion; par(ts,256); end;
       301 : begin ts := cTitle; par(ts,256); end;
       302 : begin ts := mStrParam(xPar,p.b[1]); par(ts,256); end;
       303 : begin ty := mStrParCnt(xPar); par(ty,1); end;

     { user manipulation }
       400 : xGetUser;                                            { userget }
       401 : xPutUser;                                            { userput }
       402 : begin {$I-} setfileaccess(readwrite,denynone);       { userload }
                   reset(uf);
                   seek(uf,p.w[1]); ioError:=ioResult;
                   if (ioError=0) then begin read(uf,thisuser); ioError:=ioResult; end;
                   close(uf); {$I+} end;
       403 : saveuf;                                              { usersave }
       404 : begin tb:=usersearch(p.s[1]); par(tb,256); end;

     { file i/o routines }
       500 : Assign(file(Pointer(xVar[p.v[1]]^.data)^),p.s[2]);
       501 : begin {$I-} Reset(file(Pointer(xVar[p.v[1]]^.data)^),1); {$I+} ioError := ioResult; end;
       502 : begin {$I-} Rewrite(file(Pointer(xVar[p.v[1]]^.data)^),1); {$I+} ioError := ioResult; end;
       503 : begin {$I-} Close(file(Pointer(xVar[p.v[1]]^.data)^)); {$I+} ioError := ioResult; end;
       504 : begin {$I-} BlockRead(file(Pointer(xVar[p.v[1]]^.data)^),xVar[p.v[2]]^.data^,p.w[3]); {$I+}
                   ioError := ioResult; end;
       505 : begin {$I-} BlockWrite(file(Pointer(xVar[p.v[1]]^.data)^),xVar[p.v[2]]^.data^,p.w[3]); {$I+}
                   ioError := ioResult; end;
       506 : begin {$I-} Seek(file(Pointer(xVar[p.v[1]]^.data)^),p.l[2]-1); {$I+} ioError := ioResult; end;
       507 : begin {$I-} tb := Eof(file(Pointer(xVar[p.v[1]]^.data)^)); {$I+} ioError := ioResult; par(tb,1); end;
       508 : begin {$I-} tl := FileSize(file(Pointer(xVar[p.v[1]]^.data)^)); {$I+} ioError := ioResult; par(tl,4); end;
       509 : begin {$I-} tl := FilePos(file(Pointer(xVar[p.v[1]]^.data)^))+1; {$I+} ioError := ioResult; par(tl,4); end;
       510 : begin {$I-} xFileReadLn(file(Pointer(xVar[p.v[1]]^.data)^),xVar[p.v[2]]^.data^,ss[2]); {$I+} end;
       511 : begin {$I-} xFileWriteLn(file(Pointer(xVar[p.v[1]]^.data)^),p.s[2],Length(p.s[2])); {$I+} end;

     { misc routines }
       600 : domenucommand(ttb,p.s[1]+p.s[2],ts);
       601 : begin tb := (UpStr(p.s[1]) = 'NEW') or (UpStr(p.s[1]) = 'ALL') or
                   (UpCase(p.s[1,1]) in ['0'..'9']); par(tb,1); end;
       602 : sysoplog(p.s[1]);
       603 : commandline(p.s[1]);

     { multinode routines }
       700 : ;{begin ty := nodeUser(p.s[1]); par(ty,1); end; }
       701 : begin thisnode.whereuser:=p.s[1]; savenode; end;
       702 : begin ts := thisnode.whereuser; par(ts,256); end;

     { date/time routines }
       800 : ;{begin tb := dtValidDate(p.s[1]); par(tb,1); end; }
       801 : begin tw := ageuser(p.s[1]); par(tw,2); end;
       802 : begin getdate(tw,tw1,tw1,tw1); par(tw,2); end;
       803 : begin getdate(tw1,tw,tw1,tw1); par(tw,2); end;
       804 : begin getdate(tw1,tw1,tw,tw1); par(tw,2); end;
       805 : begin getdate(tw1,tw1,tw1,tw); par(tw,2); end;
       806 : begin gettime(tw,tw1,tw1,tw1); par(tw,2); end;
       807 : begin gettime(tw1,tw,tw1,tw1); par(tw,2); end;
       808 : begin gettime(tw1,tw1,tw,tw1); par(tw,2); end;

     { math routines }
       900 : begin tr:=abs(p.r[1]); par(tr,6); end;
       901 : begin tr:=arctan(sqrt(1-p.r[1]*p.r[1])/p.r[1]); par(tr,6); end;
       902 : begin tr:=arctan(p.r[1]/sqrt(1-p.r[1]*p.r[1])); par(tr,6); end;
       903 : begin tr:=arctan(p.r[1]); par(tr,6); end;
       904 : begin tr:=cos(p.r[1]); par(tr,6); end;
       905 : begin tr:=cos(p.r[1])/sin(p.r[1]); par(tr,6); end;
       906 : begin tr:=exp(p.r[1]); par(tr,6); end;
       907 : begin tr:=ln(p.r[1]); par(tr,6); end;
       908 : begin tr:=ln(p.r[1])/ln(10.0); par(tr,6); end;
       909 : begin tr:=ln(p.r[1])/ln(2.0); par(tr,6); end;
       910 : begin tr:=pi; par(tr,6); end;
       911 : begin tl:=random(p.l[1]); par(tl,4); end;
       912 : begin tl:=round(p.r[1]); par(tl,4); end;
       913 : begin tr:=sin(p.r[1]); par(tr,6); end;
       914 : begin tr:=sqr(p.r[1]); par(tr,6); end;
       915 : begin tr:=sqrt(p.r[1]); par(tr,6); end;
       916 : begin tr:=sin(p.r[1])/cos(p.r[1]); par(tr,6); end;
       917 : begin tl:=trunc(p.r[1]); par(tl,4); end;

     { data file manipulation }
       1000: xLoadDir(p.s[1],p.l[2]);
       1001: xSaveDir(p.s[1],p.l[2]);
       1002: xLoadFB(p.l[1]);
       1003: xSaveFB(p.l[1]);

     end;

 { %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% }
 end;

 procedure xSkip;
 begin
    xGetChar; { open block }
    xGetWord; { size of block }
    xToPos(xFilePos+w);
 end;

 procedure xProcDef;
 var k, pi, ni : Word; t : Char;
 begin
    if xVars >= maxVar then
    begin
       xError(xrrTooManyVars,'');
       Exit;
    end;
    xGetWord; { procedure var id }
    if xFindVar(w) > 0 then
    begin
       xError(xrrMultiInit,'');
       Exit;
    end;
    Inc(xVars);
    New(xVar[xVars]);
    with xVar[xVars]^ do
    begin
       id := w;
       vtype := vNone;
       numPar := 0;
       proc := False;
       ppos := 0;
       size := 0;
       dsize := 0;
       arr := 0;
       {arrdim}
    end;
    xGetChar;
    pi := 0;
    while (error = 0) and (not (c in [iqo[oProcType],iqo[oOpenBlock]])) do
    begin
       t := c;
       xGetWord;
       ni := w;
       for k := 1 to ni do
       begin
          Inc(pi);
          xVar[xVars]^.param[pi] := t;
          xGetWord;
          xVar[xVars]^.pid[pi] := w;
       end;
       xGetChar;
    end;
    if c = iqo[oProcType] then
    begin
       xGetChar;
       xVar[xVars]^.vtype := cVarType(c);
       xVar[xVars]^.size := xVarSize(xVar[xVars]^.vtype);
    end else xGoBack;
    xVar[xVars]^.numpar := pi;
    xVar[xVars]^.ppos := xFilePos;

    xSkip; {ToPos(xFilePos+pSize);}
 end;

 procedure xLoopFor;
 var vc : Word; nstart, nend, count : Real; up : Boolean; spos : LongInt;
     ad : tArray;
 begin
    xGetWord; { counter variable }
    vc := xFindVar(w);
    xCheckArray(vc,ad);
    nstart := xEvalNumber; { start num }
    xGetChar; { direction (to/downto) }
    up := c = iqo[oTo];
    nend := xEvalNumber; { ending num }
    count := nstart;

    spos := xFilePos; { save pos }

    if (up and (nstart > nend)) or ((not up) and (nstart < nend)) then xSkip else
    if up then
    while count <= nend do
    begin
       xSetNumber(vc,count,ad);
       xToPos(spos);
       xParse(xVars);
       count := count+1;
    end else
    while count >= nend do
    begin
       xSetNumber(vc,count,ad);
       xToPos(spos);
       xParse(xVars);
       count := count-1;
    end;
 end;

 procedure xWhileDo;
 var ok : Boolean; spos : LongInt;
 begin
    spos := xFilePos;
    ok := True;
    while (error = 0) and (ok) do
    begin
       ok := xEvalBool;
       if ok then
       begin
          xParse(xVars);
          xToPos(spos);
       end else xSkip;
    end;
 end;

 procedure xRepeatUntil;
 var ok : Boolean; spos : LongInt;
 begin
    spos := xFilePos;
    ok := True;
    repeat
       xToPos(spos);
       xParse(xVars);
    until (error <> 0) or (xEvalBool);
 end;

 procedure xIfThenElse;
 var ok : Boolean;
 begin
    ok := xEvalBool;

    if ok then xParse(xVars) else xSkip;

    xGetChar; { check for else }
    if c = iqo[oElse] then
    begin
       if not ok then xParse(xVars) else xSkip;
    end else xGoBack;
 end;

 procedure xGotoPos;
 var p : LongInt;
 begin
    xGetWord;
    p := w;
    xToPos(p);
 end;

 procedure xExitModule;
 begin
    xGetChar;
    if c = iqo[oOpenBrack] then
    begin
       result := Round(xEvalNumber);
       xGetChar; { close brack }
    end else xGoBack;
 end;

 procedure xParse(svar : Word);
 var done : Boolean; z : Word;
 begin
    xGetChar; { open block }
    xGetWord; { size of block }
    done := False;

    repeat
       xGetChar;
       if c = iqo[oCloseBlock] then done := True else
       if c = iqo[oOpenBlock] then
       begin
          xGoBack;
          xParse(xVars);
       end else
       if c = iqo[oVarDeclare] then xCreateVar else
       if c = iqo[oSetVar] then
       begin
          xGetWord;
          xSetVariable(xFindVar(w));
       end else
       if c = iqo[oProcExec] then xProcExec(nil) else
       if c = iqo[oProcDef] then xProcDef else
       if c = iqo[oFor] then xLoopFor else
       if c = iqo[oIf] then xIfThenElse else
       if c = iqo[oWhile] then xWhileDo else
       if c = iqo[oRepeat] then xRepeatUntil else
       if c = iqo[oGoto] then xGotoPos else
       if c = iqo[oExit] then
       begin
          xExitModule;
          done := True;
       end else xError(xrrUnknownOp,c);
    until (error <> 0) or (done) or (hangup);

   {xGetChar; { close block }

    for z := xVars downto svar+1 do
    begin
       if (xVar[z]^.kill) and (xVar[z]^.data <> nil) then
          FreeMem(xVar[z]^.data,xVar[z]^.dsize);
       Dispose(xVar[z]);
    end;
    xVars := svar;
 end;

 procedure xTerminate;
 var z : Word;
 begin
    for z := 1 to xVars do
    begin
       if (xVar[z]^.kill) and (xVar[z]^.data <> nil) then FreeMem(xVar[z]^.data,xVar[z]^.dsize);
       Dispose(xVar[z]);
    end;
    xVars := 0;
 end;

begin
   xExecute := 0;
   xInit;
   w := 0;
   Assign(f,fn);
   {$I-}
   Reset(f,1);
   {$I+}
   if ioResult <> 0 then
   begin
      xError(xrrFileNotFound,fn);
      Exit;
   end;

   if FileSize(f) < idLength then
   begin
      Close(f);
      xError(xrrInvalidFile,fn);
      Exit;
   end;

   FillChar(xid,SizeOf(xid),32);
   FillChar(xver,SizeOf(xver),32);
   xid[0] := chr(idVersion);
   xver[0] := chr(idLength-idVersion);
   BlockRead(f,xid[1],idVersion);
   BlockRead(f,xver[1],idLength-idVersion);
   while not (xver[Ord(xver[0])] in ['0'..'9','a'..'z']) do Dec(xver[0]);

   if cleanUp(xid) <> cProgram then
   begin
      Close(f);
      xError(xrrInvalidFile,fn);
      Exit;
   end;

   if cleanUp(xver) <> cVersion then
   begin
      Close(f);
      xError(xrrVerMismatch,cleanUp(xver));
      Exit;
   end;

   cInitProcs(xVar,xVars,w);

   xParse(xVars);

   xTerminate;

   Close(f);

   xExecute := xpos;
end;

function iplExecute(fn, par : String) : Word;
var z, m1, m2 : LongInt; x : String;
begin
   m1 := maxavail;
   xPar := par;
   iplExecute := 250;
   iplError := 0;

   fn := upStr(fn);
   if Pos('.',fn) = 0 then fn := fn+extIPLexe;
   if not Exist(fn) then
   begin
      x := systat^.iplxpath+fn;
      if not Exist(x) then
      begin
         sysoplog('xIPL: Error opening "'+x+'"; file not found');
         Exit;
      end else fn := x;
   end;

   sysoplog('IPL: Executed "'+fn+'"');
   z := xExecute(fn);
   if error <> 0 then
   begin
      m2 := maxavail;
      if (error <> 0) or (m1-m2 <> 0) then
        commandline('(IPL) Error: '+xErrorMsg+' [pos '+st(z)+']    memdiff: '+st(m1-m2));
      iplError := error;
   end else iplExecute := result;
end;

function iplModule(fn, par : string) : integer;
var r : word;
begin
   iplModule := -1;
   if pos('\',fn) = 0 then
     fn := systat^.iplxpath+fn;
   if pos('.',strFilename(fn)) = 0 then fn := fn+extIPLexe;
   r := iplExecute(fn, par);
   if iplError <> 0 then exit;
   iplModule := r;
end;

end.
