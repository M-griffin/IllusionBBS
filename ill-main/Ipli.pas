{ Iniquity/Illusion Programming Language - Global Constants }

const

   cTitle             = 'Illusion Programming Language';
   cProgram           = 'Illusion/PL [executable file]';
   cVersion           = 'v1.02a';

   idLength           = 40;
   idVersion          = 30;

   maxFile            = 20;
   maxVar             = 500;
   maxIdentLen        = 30;
   maxVarDeclare      = 30;
   maxParam           = 10;
   maxProc            = 2;
   maxArray           = 3;
   maxGoto            = 100;

   chDigit            = ['0'..'9'];
   chNumber           = ['0'..'9','.'];
   chAny              = [#0..#255];
   chIdent1           = ['a'..'z','A'..'Z','_'];
   chIdent2           = ['a'..'z','A'..'Z','0'..'9','_'];

   errUeEndOfFile     = 1;
   errFileNotfound    = 2;
   errFileRecurse     = 3;
   errOutputFile      = 4;
   errExpected        = 5;
   errUnknownIdent    = 6;
   errInStatement     = 7;
   errIdentTooLong    = 8;
   errExpIdentifier   = 9;
   errTooManyVars     = 10;
   errDupIdent        = 11;
   errOverMaxDec      = 12;
   errTypeMismatch    = 13;
   errSyntaxError     = 14;
   errStringNotClosed = 15;
   errStringTooLong   = 16;
   errTooManyParams   = 17;
   errBadProcRef      = 18;
   errNumExpected     = 19;
   errToOrDowntoExp   = 20;
   errExpOperator     = 21;
   errOverArrayDim    = 22;
   errNoInitArray     = 23;
   errTooManyGotos    = 24;
   errDupLabel        = 25;
   errLabelNotFound   = 26;
   errFileParamVar    = 27;
   errBadFunction     = 28;
   errOperation       = 29;

   xrrUeEndOfFile     = 1;
   xrrFileNotFound    = 2;
   xrrInvalidFile     = 3;
   xrrVerMismatch     = 4;
   xrrUnknownOp       = 5;
   xrrTooManyVars     = 6;
   xrrMultiInit       = 7;
   xrrDivisionByZero  = 8;
   xrrMathematical    = 9;

type
   tIqVar     = (vNone,vStr,vByte,vShort,vWord,vInt,vLong,vReal,vBool,vFile);
   tIqWord    = (wOpenBlock,wCloseBlock,wCmtStartBlock,wCmtEndBlock,
                 wCommentLine,wCmtNumberSign,wVarDeclare,wVarSep,wSetVar,
                 wOpenBrack,wCloseBrack,wOpenString,wCloseString,wStrAdd,
                 wCharPrefix,wProcDef,wOpenParam,wCloseParam,wParamVar,
                 wParamSpec,wFuncSpec,wParamSep,wFor,wTo,wDownto,wDo,wTrue,
                 wFalse,wOpEqual,wOpNotEqual,wOpGreater,wOpLess,wOpEqGreat,
                 wOpEqLess,wIf,wThen,wElse,wWhile,wRepeat,wUntil,wNot,wAnd,
                 wOr,wStrCh,wOpenArr,wCloseArr,wArrSep,wVarDef,wOpenStrLen,
                 wCloseStrLen,wGoto,wLabel,wExit);
   tIqOp      = (oOpenBlock,oCloseBlock,oVarDeclare,oStr,oByte,oShort,oWord,
                 oInt,oLong,oReal,oBool,oSetVar,oOpenBrack,oCloseBrack,
                 oVariable,oOpenString,oCloseString,oProcDef,oProcExec,
                 oParamSep,oFor,oTo,oDownto,oTrue,oFalse,oOpEqual,
                 oOpNotEqual,oOpGreater,oOpLess,oOpEqGreat,oOpEqLess,
                 oStrAdd,oProcType,oIf,oElse,oWhile,oOpenNum,oCloseNum,
                 oRepeat,oNot,oAnd,oOr,oStrCh,oArrDef,oVarDef,oStrLen,
                 oVarNormal,oGoto,oFile,oExit);

const
   iqv : array[tIqVar] of String[maxIdentLen] =
       ('none','str','byte','short','word','int','long','real','bool','file');
   iqw : array[tIqWord] of String[maxIdentLen] =
       ('{','}','|','|','%','#','@',',','=','(',')','"','"','+','#','proc',
        '[',']','+',';',':',',','for','to','downto','do','true','false','=',
        '<>','>','<','>=','<=','if','then','else','while','repeat','until',
        'not','and','or','.','(',')',',','=','<','>','goto',':','exit');
   iqo : array[tIqOp] of Char =
       ('[',']','+','s','b','h','w','i','l','r','o','-','(',')','v','"','"',
        '%','ø','/','#','Ü','ß','t','f','=','!','>','<','}','{','&',':','?',
        '*','|','`','''','é','ï','î','þ','~',#0,'ä','\','í','Û','f','x');
   vnums : set of tIqVar = [vByte,vShort,vWord,vInt,vLong,vReal];

{$IFDEF ipx}
type
   pData = ^tData;
   tData = array[1..65535] of Byte;

   tArray = array[1..maxArray] of Word;

   pVar = ^tVar;
   tVar = record
      id     : Word;
      vtype  : tIqVar;
      param  : array[1..maxParam] of Char;
      numPar : Byte;
      proc   : Boolean;
      pid    : array[1..maxParam] of Word;
      ppos   : LongInt;
      dsize  : Word;
      size   : Word;
      data   : pData;
      kill   : Boolean;
      arr    : Byte;
      arrdim : tArray;
   end;
   tVars = array[1..maxVar] of pVar;

{$ELSE}
type
   pVar = ^tVar;
   tVar = record
      id     : Word;
      ident  : String[maxIdentLen];
      vtype  : tIqVar;
      param  : array[1..maxParam] of Char;
      numPar : Byte;
      proc   : Boolean;
      inproc : Boolean;
      arr    : Byte;
   end;
   tVars = array[1..maxVar] of pVar;

   pGoto = ^tGoto;
   tGoto = record
      ident  : String[maxIdentLen];
      xPos   : LongInt;
      stat   : Byte;
   end;

var
   cVar   : tVars;
   cVars  : Word;
   cID    : Word;
   cGoto  : array[1..maxGoto] of pGoto;
   cGotos : Word;
{$ENDIF}

var
   xUstart,
   xFBstart,
   xDIRstart : Word;
   result  : Word;
   ioError : Byte;

function cVarType(c : Char) : tIqVar;
begin
   c := upCase(c);
   case c of
     'S' : cVarType := vStr;
     'B' : cVarType := vByte;
     'H' : cVarType := vShort;
     'W' : cVarType := vWord;
     'I' : cVarType := vInt;
     'L' : cVarType := vLong;
     'R' : cVarType := vReal;
     'O' : cVarType := vBool;
     'F' : cVarType := vFile;
      else cVarType := vNone;
   end;
end;

function xVarSize(t : tIqVar) : Word;
begin
   case t of
      vNone  : xVarSize := 0;
      vStr   : xVarSize := 256;
      vByte  : xVarSize := 1;
      vShort : xVarSize := 1;
      vWord  : xVarSize := 2;
      vInt   : xVarSize := 2;
      vLong  : xVarSize := 4;
      vReal  : xVarSize := 6;
      vBool  : xVarSize := 1;
      vFile  : xVarSize := 128;
   end;
end;

procedure cInitProcs(var cV : tVars; var x : Word; var iw : Word);
 procedure ip(i : String; p : String; t : tIqVar);
 begin
    Inc(x);
    New(cV[x]);
    with cV[x]^ do
    begin
       id := iw;
       Inc(iw);
       vtype := t;
       Move(p[1],param,Ord(p[0]));
       numPar := Ord(p[0]);
       proc := True;
{$IFDEF ipx}
       size := 0;
       dsize := 0;
       data := nil;
       FillChar(pid,SizeOf(pid),0);
       ppos := 0;
       kill := True;
{$ELSE}
       ident := i;
       inproc := False;
{$ENDIF}
       arr := 0;
       {arrdim}
    end;
 end;
 procedure is(i : String; t : tIqVar; si : Word);
 begin
    Inc(x);
    New(cV[x]);
    with cV[x]^ do
    begin
       id := iw;
       Inc(iw);
       vtype := t;
      {param}
       numPar := 0;
       proc := False;
{$IFDEF ipx}
       size := si+1;
       dsize := size;
       GetMem(data,dsize);
       FillChar(data^,dsize,0);
       FillChar(pid,SizeOf(pid),0);
       ppos := 0;
       kill := True;
{$ELSE}
       ident := i;
       inproc := False;
{$ENDIF}
       arr := 0;
       {arrdim}
    end;
 end;
 procedure iv(i : String; t : tIqVar);
 begin
    is(i,t,xVarSize(t)-1);
 end;
 procedure ivp(i : String; t : tIqVar; si : Word; pd : Pointer);
 begin
    Inc(x);
    New(cV[x]);
    with cV[x]^ do
    begin
       id := iw;
       Inc(iw);
       vtype := t;
      {param}
       numPar := 0;
       proc := False;
{$IFDEF ipx}
       if t = vStr then size := si+1 else size := si;
       dsize := size;
       data := pd;
{      GetMem(data,dsize);
       FillChar(data^,dsize,0);}
       FillChar(pid,SizeOf(pid),0);
       ppos := 0;
       kill := False;
{$ELSE}
       ident := i;
       inproc := False;
{$ENDIF}
       arr := 0;
       {arrdim}
    end;
 end;
begin
   iw := 0; { output routines }
   ip('out',         's',       vNone);
   ip('outln',       's',       vNone);
   ip('clrscr',      '',        vNone);
   ip('clreol',      '',        vNone);
   ip('beep',        '',        vNone);
   ip('cout',        's',       vNone);
   ip('coutln',      's',       vNone);
   ip('dnln',        'b',       vNone);
   ip('gotoxy',      'bb',      vNone);
   ip('posup',       'b',       vNone);
   ip('posdown',     'b',       vNone);
   ip('posleft',     'b',       vNone);
   ip('posright',    'b',       vNone);
   ip('posx',        'b',       vNone);
   ip('posy',        'b',       vNone);
   ip('setback',     'b',       vNone);
   ip('setfore',     'b',       vNone);
   ip('setblink',    'o',       vNone);
   ip('setcolor',    'bb',      vNone);
   ip('sout',        's',       vNone);
   ip('soutln',      's',       vNone);
   ip('strout',      'w',       vNone);
   ip('stroutln',    'w',       vNone);
   ip('xout',        's',       vNone);
   ip('xoutln',      's',       vNone);
   ip('aout',        's',       vNone);
   ip('showtext',    's',       vBool);
   ip('showfile',    's',       vBool);
   ip('fline',       '',        vNone);
   ip('wherex',      '',        vByte);
   ip('wherey',      '',        vByte);
   ip('delay',       'w',       vNone);
   ip('sound',       'ww',      vNone);
   ip('addwave',     'ss',      vNone);
   ip('clearwaves',  '',        vNone);

   iw := 100; { input routines }
   ip('inkey',       '',        vStr);
   ip('instr',       'ssssb',   vStr);
   ip('instrf',      'ssssbb',  vStr);
   ip('keypressed',  '',        vBool);
   ip('indate',      's',       vStr);
   ip('intime',      's',       vStr);
   ip('inphone',     's',       vStr);
   ip('inpostal',    '',        vStr);
   ip('inzipcode',   '',        vStr);
   ip('inyesno',     'o',       vBool);

   iw := 200; { string funtions }
   ip('strup',       's',       vStr);
   ip('strlow',      's',       vStr);
   ip('stryesno',    'o',       vStr);
   ip('strpos',      'ss',      vByte);
   ip('strtrim',     's',       vStr);
   ip('strmixed',    's',       vStr);
   ip('strnocol',    's',       vStr);
   ip('strsize',     'sb',      vStr);
   ip('strsizenc',   'sb',      vStr);
   ip('strsizer',    'sb',      vStr);
   ip('strint',      'l',       vStr);
   ip('strreal',     'rbb',     vStr);
   ip('strintc',     'l',       vStr);
   ip('strsquish',   'sb',      vStr);
   ip('strreplace',  'sss',     vStr);
   ip('strcopy',     'sbb',     vStr);
   ip('strdel',      'sbb',     vStr);
   ip('strrepeat',   'sb',      vStr);
   ip('strlen',      's',       vByte);
   ip('strcode',     'sbs',     vStr);
   ip('strget',      'w',       vStr);
   ip('strval',      's',       vLong);

   iw := 300; { ipl-related routines }
   ip('iplver',      '',        vStr);
   ip('iplname',     '',        vStr);
   ip('iplpar',      'b',       vStr);
   ip('iplnumpar',   '',        vByte);

   iw := 400; { user manipulation }
   ip('userget',     '',        vNone);
   ip('userput',     '',        vNone);
   ip('userload',    'w',       vNone);
   ip('usersave',    '',        vNone);
   ip('usersearch',  's',       vBool);

   iw := 500; { file i/o routines }
   ip('fileassign', 'Fs',       vNone);
   ip('fileopen',   'F',        vNone);
   ip('filecreate', 'F',        vNone);
   ip('fileclose',  'F',        vNone);
   ip('fileread',   'F*w',      vNone);
   ip('filewrite',  'F*w',      vNone);
   ip('fileseek',   'Fl',       vNone);
   ip('fileend',    'F',        vBool);
   ip('filesize',   'F',        vLong);
   ip('filepos',    'F',        vLong);
   ip('filereadln', 'FS',       vNone);
   ip('filewriteln','Fs',       vNone);

   iw := 600; { misc routines }
   ip('menucmd',    'ss',       vNone);
   ip('badhandle',  's',        vBool);
   ip('logwrite',   's',        vNone);
   ip('cmdline',    's',        vNone);

   iw := 700; { multinode routines }
   ip('nodeuser',   's',        vByte);
   ip('nodestatus', 's',        vNone);
   ip('nodegetstatus','',       vStr);

   iw := 800; { date/time routines }
   ip('datevalid',  's',        vBool);
   ip('dateage',    's',        vWord);
   ip('getyear',    '',         vWord);
   ip('getmonth',   '',         vWord);
   ip('getday',     '',         vWord);
   ip('getdow',     '',         vWord);
   ip('gethour',    '',         vWord);
   ip('getminute',  '',         vWord);
   ip('getsecond',  '',         vWord);

   iw := 900; { math routines }
   ip('abs',      'r',      vReal);
   ip('arccos',   'r',      vReal);
   ip('arcsin',   'r',      vReal);
   ip('arctan',   'r',      vReal);
   ip('cosin',    'r',      vReal);
   ip('cotan',    'r',      vReal);
   ip('exp',      'r',      vReal);
   ip('ln',       'r',      vReal);
   ip('log10',    'r',      vReal);
   ip('log2',     'r',      vReal);
   ip('pi',       '',       vReal);
   ip('random',   'l',      vLong);
   ip('round',    'r',      vLong);
   ip('sin',      'r',      vReal);
   ip('sqr',      'r',      vReal);
   ip('sqrt',     'r',      vReal);
   ip('tan',      'r',      vReal);
   ip('trunc',    'r',      vLong);

   iw := 1000; { data file manipulation }
   ip('dirload',  'sl',     vNone);
   ip('dirsave',  'sl',     vNone);
   ip('fbload',   'l',      vNone);
   ip('fbsave',   'l',      vNone);

   iw := 2000; { user-record variables }
   xUstart := x+1;
   iv('unumber',     vInt);
   is('uhandle',     vStr,    36);
   is('urealname',   vStr,    36);
   is('upassword',   vStr,    20);
   is('uphone',      vStr,    13);
   is('ubdate',      vStr,    8);
   is('ulocation',   vStr,    40);
   is('uaddress',    vStr,    36);
   is('unote',       vStr,    40);
   is('usex',        vStr,    1);
   iv('usl',         vByte);
   iv('udsl',        vByte);
   iv('ubaud',       vLong);
   iv('ucalls',      vWord);
   iv('umsgarea',    vWord);
   iv('ufilearea',   vWord);
   is('ulastcall',   vStr,    8);
   iv('upagelen',    vWord);
   iv('uemail',      vWord);
   is('uconf',       vStr,    1);
   iv('blah',        vByte);
   is('ufirstcall',  vStr,    8);
   is('ustartmenu',  vStr,    8);
   is('usysopnote',  vStr,    40);
   iv('uposts',      vWord);
   iv('uemails',     vWord);
   iv('uuploads',    vWord);
   iv('udownloads',  vWord);
   iv('uuploadkb',   vLong);
   iv('udownloadkb', vLong);
   iv('ucallst',     vWord);
   iv('ufansi',      vBool);
   iv('ufavatar',    vBool);
   iv('ufrip',       vBool);
   iv('ufdeleted',   vBool);
   iv('ufexpert',    vBool);
   iv('ufhotkey',    vBool);
   iv('ufpause',     vBool);
   iv('ufilepts',    vWord);
   is('uzipcode',    vStr,    10);
   iv('ulinelen',    vByte);
   iv('ueditor',     vByte);
   iv('utimebank',   vWord);
   iv('utimeleft',   vWord);
   iv('ucredits',    vWord);
   is('ureference',  vStr,    40);
   is('uoccupation', vStr,    40);
   is('ucomputer',   vStr,    30);

   iw := 2100; { internal variables - non-killable }
   ivp('hangup',     vBool,   1,   @HangUp);
   ivp('hungup',     vBool,   1,   @HungUp);
   ivp('remoteout',  vBool,   1,   @OutCom);
   ivp('remotein',   vBool,   1,   @InCom);
   ivp('localio',    vBool,   1,   @LocalIOOnly);
   ivp('useron',     vBool,   1,   @UserOn);
   ivp('loggedin',   vBool,   1,   @LoggedIn);
   ivp('quitafter',  vBool,   1,   @QuitAfterDone);

   ivp('ioerror',    vByte,   1,   @ioError); { for file io errors }
   ivp('datapath',   vStr,    255, @systat^.DataPath);
   ivp('textpath',   vStr,    255, @systat^.TextPath);

   ivp('node',       vByte,   1,   @nodenum);
   ivp('numbatch',   vByte,   1,   @numbatchfiles);

   ivp('chatreason', vStr,    255, @chatr);
   ivp('inputstring',vStr,    255, @inputString);

   ivp('result',     vWord,   2,   @result);

   ivp('numusers',   vWord,   2,   @systat^.numUsers);

   iw := 2200; { configuration record variables - direct }
   ivp('chandles',   vBool,   1,   @systat^.AllowAlias);
   ivp('cdefpagelen',vByte,   1,   @systat^.pagelen);
   ivp('cdeflinelen',vByte,   1,   @systat^.linelen);

   iw := 2300; { .dir record variables }
   xDIRstart := x+1;
   is('dirfilename', vStr,    12);
   is('dirdesc',     vStr,    36);
   iv('dirfilepts',  vInt);
   iv('dirdownloads',vWord);
   iv('dirblocks',   vLong);
   iv('diruluser',   vInt);
   is('diruploader', vStr,    36);
   is('diruldate',   vStr,    8);
   iv('dirverbose',  vLong);
   iv('dirnotval',   vBool);
   iv('dirrequest',  vBool);
   iv('dirresume',   vBool);

   iw := 2400; { fboards.dat record variables }
   xFBstart := x+1;
   is('fbname',      vStr,    40);
   is('fbdirfile',   vStr,    12);
   is('fbpath',      vStr,    40);
   iv('fbmaxfiles',  vInt);
   iv('fbarchive',   vByte);
   iv('fbcomment',   vByte);
   is('fbaccess',    vStr,    20);
   is('fbulacs',     vStr,    20);
   is('fbnameacs',   vStr,    20);
   iv('fbindex',     vLong);
   iv('fbnoratio',   vBool);
   iv('fbvisible',   vBool);
   iv('fbdirinpath', vBool);
   iv('fbgifspecs',  vBool);

   iw := 2500; { today's zlog variables }
   ivp('thdate',      vStr,   8,   @systat^.todayzlog.date);
   ivp('thactive',    vInt,   2,   @systat^.todayzlog.active);
   ivp('thcalls',     vInt,   2,   @systat^.todayzlog.calls);
   ivp('thnewusers',  vInt,   2,   @systat^.todayzlog.newusers);
   ivp('thposts',     vInt,   2,   @systat^.todayzlog.pubpost);
   ivp('themails',    vInt,   2,   @systat^.todayzlog.privpost);
   ivp('therrors',    vInt,   2,   @systat^.todayzlog.criterr);
   ivp('thuploads',   vInt,   2,   @systat^.todayzlog.uploads);
   ivp('thdownloads', vInt,   2,   @systat^.todayzlog.downloads);
   ivp('thuploadkb',  vLong,  4,   @systat^.todayzlog.uk);
   ivp('thdownloadkb',vLong,  4,   @systat^.todayzlog.dk);

   ioError := 0;
end;
