(*****************************************************************************)
(* Illusion BBS - Common functions and procedures [0/3]                      *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O-,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit common;

interface

uses
  crt, dos, MkMsgAbs, myio, foscom2, timejunk, mtask, tpansii, exec;

{$I func.pas}
{$I rec25.pas}

const strlen=160;
      boxedtitle='`#[';

type FileShareType = (DenyCompatibility,DenyAll,DenyWrite,DenyRead,DenyNone);
     FileAccessType = (ReadOnly,WriteOnly,ReadWrite);
     wherecurrenttype = (normal,help,userval);
     screentype=array[0..3999] of byte;
     mcitype=(txt,xya);
     str2=string[2];
     wavetype=record                       { record for wave codes }
                letters:str2;
                s:astr;
                t:mcitype;
                x,y,a:byte;
              end;
     str1rec=array[0..9] of string[255];   { contains commonly used strings }
     str2rec=array[0..19] of string[255];  { string buffer }

var uf:file of userrec;           { USERS.DAT                             }
    bf:file of boardrec;          { MBOARDS.DAT                           }
    xf:file of protrec;           { PROTOCOL.DAT                          }
    ulf:file of ulrec;            { FBOARDS.DAT                           }
    ulff:file of ulfrec;          { *.DIR                                 }
    sf:file of smalrec;           { USERS.IDX                             }
    smf:file of smr;              { SHORTMSG.DAT                          }
    verbf:file of verbrec;        { VERBOSE.DAT                           }
    nodef:file of noderec;        { NODES.DAT                             }
    compf:file of areaidxrec;     { MSG.IDX                               }
    msgzscanf:file of msgscanrec; { *.MSI                                 }
    fstringf:file;                { STRINGS.DAT                           }

    sysopf,                       { SYSOP.###                             }
    sysopf1,                      { SLOGxxxx ###                          }
    trapfile,                     { TRAP*.###                             }
    cf:text;                      { CHAT*.###                             }

    systat:^systatrec;            { configuration information             }
    modemr:^modemrec;             { modem configuration                  }

    thisuser:userrec;             { user's account records                }
    macros:^macrorec;             { user's macros, if any                 }
    zscanr:zscanrec;              { user's zscan records                  }

    events:array[0..maxevents] of ^eventrec;
    numevents:integer;            { # of events                           }

    protocol:protrec;             { protocol in memory                    }
    numprotocols:integer;         { # of protocols                        }

    memuboard,tempuboard:ulrec;   { uboard in memory, temporary uboard    }
    readuboard,                   { current uboard # in memory            }
    maxulb,                       { # of file bases                       }
    fileboard:integer;            { file base user is in                  }

    conference:confrrec;          { current conference }

    thisnode:noderec;             { Node record in memory                 }
    
    compmsg:areaidxrec;

    spd:string[6];                { current modem speed, "KB" for local   }
    realspd:string[6];            { real logon speed                      }
    nodenum:byte;                 { current node                          }

    waves:array[1..60] of ^wavetype; { wave codes                         }
    numwaves:byte;                { number of wave codes in memory        }

    strglobal:^str1rec;           { string stuff }
    strbuff:^str2rec;             {      |       }
    firstbuff:word;               {      V       }

    wherecurrent:wherecurrenttype; { used for sysop window input          }

    InputString:String;
    
    (********** NEW FILE BASE VARS **********)
        
    
    { FILE/MESSAGE BASE COMPRESSION TABLES }   
    ccuboards : array[0..1,0..maxuboards] of byte;
    
    pap       : integer;
    filemnu   : boolean;
    filepmnu  : char;    { 2nd char in command str for filep.mnu }
    
    door32    : LongInt; { Door32 Socket Handle }
    
    userip    : string;  { Users IP Address from Gamesrv }

    

{ GLOBAL MESSAGE SYSTEM VARIABLES AND TYPES }
{ ----------------------------------------- }

Type
  ScanTyp=
   (stReadM,   { Read Message }
    stReadP,   { Read Prompt  }
    stTitles); { Show Titles  }

Var
    Msg:AbsMsgPtr;                { Message Object }

    memboard:boardrec;            { board in memory (compressed)          }
    numboards,                    { # of message bases                    }
    board:word;                   { message base user is in               }
    BoardLoaded:Word;             { Real board number loaded              }
    BoardReal  :Word;             { Real board number user is in          }
    RealOnly   :Boolean;          { Real names only?                      }
    msgzscan:msgscanrec;          { zscan in memory                       }

(*****************************************************************************)

    buf:string[255];              { macro buffer                          }

    chatr,                        { last chat reason                      }
    cmdlist,                      { list of cmds on current menu          }
    ll,                           { "last-line" string for word-wrapping  }
    start_dir:string;             { directory BBS was executed from       }

    tim,                          { time last keystroke entered           }
    timeon:datetimerec;           { time user logged on                   }

    choptime,                     { time to chop off for system events    }
    extratime,                    { extra time - given by F7/F8, etc      }
    freetime,                     { free time                             }
    oltime,
    commandlinecount,             { set to "timer" when commandline is called }
    topscrcount:real;             { set to "timer" when topscr is called  }

    answerbaud,                   { baud rate to answer the phone at      }
    exteventtime:longint;         { # minutes before external event       }

    chatt,                        { number chat attempts made by user     }
    etoday,                       { E-mail sent by user this call         }
    lastprot,                     { last protocol #                       }
    ldate,                        { last daynum()                         }
    lil,                          { lines on screen since last pausescr() }
    mread,                        { # public messages has read this call  }
    ptoday,                       { posts made by user this call          }
    realsl,                       { real SL level of user (for F9)        }
    realdsl,                      { real DSL level of user                }
    usernum:integer;              { user's user number                    }

    chelplevel,                   { current help level                    }
    curco,                        { current ansi color                    }
    elevel,                       { errorlevel to exit with               }
    tshuttlelogon:byte;           { type of special matrix logon command  }

    outputbuff:^string;

const
    iplTRUE:boolean=TRUE;
    iplFALSE:boolean=FALSE;

    aborted:boolean=FALSE;        { was it aborted?                       }
    allowabort:boolean=TRUE;      { are aborts allowed?                   }
    echo:boolean=TRUE;            { is text being echoed? (FALSE=use echo chr)}
    hangup:boolean=TRUE;          { is user offline now?                  }
    nofile:boolean=TRUE;          { did last pfl() file NOT exist?        }
    onekcr:boolean=TRUE;          { does ONEK prints<CR> upon exit?       }
    onekda:boolean=TRUE;          { does ONEK display the choice?         }
    getkeyspin:boolean=FALSE;     { does getkey spin the cusor?           }
    sysopon:boolean=TRUE;         { is SysOp logged onto the WFC menu?    }
    wantout:boolean=TRUE;         { output text locally?                  }

    badfpath:boolean=FALSE;       { is the current DL path BAD?           }
    badini:boolean=FALSE;         { was last call to ini/inu value()=0, s<>"0"? }
    beepend:boolean=FALSE;        { whether to beep after caller logs off }
    bnp:boolean=FALSE;            { was file base name printed yet?       }
    cfo:boolean=FALSE;            { is chat file open?                    }
    ch:boolean=FALSE;             { are we in chat mode?                  }
    chatcall:boolean=FALSE;       { is the chat call (alert users) on?    }
    checkit:boolean=FALSE;        { }
    croff:boolean=FALSE;          { are CRs turned off?                   }
    ctrljoff:boolean=FALSE;       { turn color to #1 after ^Js??          }
    cwindowon:boolean=FALSE;      { is SysOp window ON?                   }
    didlogfirst:boolean=FALSE;    { Did we already execute the logon1st?  }
    doneafternext:boolean=FALSE;  { offhook and exit after next logoff?   }
    doneday:boolean=FALSE;        { are we done now? ready to drop to DOS? }
    dontgoaway:boolean=FALSE;     { remove commandline after time is out? }
    dosansion:boolean=FALSE;      { output chrs to DOS for ANSI codes?!!? }
    dyny:boolean=FALSE;           { does YN return Yes as default?        }
    enddayf:boolean=FALSE;        { perfrom "endday" after logoff?        }
    fastlogon:boolean=FALSE;      { if a FAST LOGON is requested          }
    hungup:boolean=FALSE;         { did user drop carrier?                }
    incom:boolean=FALSE;          { accepting input from com?             }
    inmsgfileopen:boolean=FALSE;  { are we /U ULing a file into a message? }
    inwfcmenu:boolean=FALSE;      { are we in the WFC menu?               }
    isqwk:boolean=FALSE;          { are we processing a QWK packet?       }
    lastcommandgood:boolean=FALSE;{ was last command a REAL command?      }
    lastcommandovr:boolean=FALSE; { override PAUSE? (NO pause?)           }
    localioonly:boolean=FALSE;    { local I/O ONLY?                       }
    loggedin:boolean=FALSE;       { user logged in?                       }
    macok:boolean=FALSE;          { are macros OKay right now?            }
    newmenutoload:boolean=FALSE;  { menu command returns TRUE if new menu to load }
    outcom:boolean=FALSE;         { outputting to com?                    }
    packbasesonly:boolean=FALSE;  { pack message bases ONLY?              }
    filesortonly:boolean=FALSE;   { sort file bases ONLY?                 }
    quitafterdone:boolean=FALSE;  { quit after next user logs off?        }
    shutupchatcall:boolean=FALSE; { was chat call "SHUT UP" for this call? }
    trapping:boolean=FALSE;       { are we trapping users text?           }
    useron:boolean=FALSE;         { is there a user on right now?         }
    wasnewuser:boolean=FALSE;     { did a NEW USER log on?                }
    write_msg:boolean=FALSE;      { is user writing a message?            }
    litbar:boolean=FALSE;         { in light bar menu?                    }

    telluserevent:byte=0;         { told user about the up-coming event?  }
    exiterrors:byte=254;          { errorlevel for Critical Error exit    }
    exitnormal:byte=255;          { errorlevel for Normal exit            }
    linemode:byte=25;             { 25/43/50 line mode.                   }
    whereisoverlay:byte=1;        { 0=disk, 1=EMS, 2=XMS                  }

var
    windowon:boolean;
    curwindow:byte;
    first_time:boolean;           { first time loading a menu?            }
    menustack:array[1..8] of string[12]; { menu stack                     }
    menustackptr:integer;         { menu stack pointer                    }
    last_menu,                    { last menu loaded                      }
    last_menu2,                   { last menu loaded / fallback from Files}
    curmenu:string;               { current menu loaded                   }
    menur:menurec;                { menu information                      }
    cmdr:array[1..50] of commandrec; { command information                }
    noc:integer;                  { # of commands on menu                 }
    fqarea,mqarea:boolean;        { file/message quick area changes       }
    haseverytime:boolean;         { everytime command                     }

    lastkeypress:datetimerec;     { time of last keypress for screen saver }
    newdate:string[8];            { NewScan pointer date                  }
    lrn:integer;                  { last record # for recno/nrecno        }
    lfn:string;                   { last filename for recno/nrecno        }

    batchtime:real;               { }
    numbatchfiles:integer;        { # files in DL batch queue             }
    batch:array[1..maxbatchfiles] of record
      fn:string[65];
      section:integer;
      pts:integer;
      blks:longint;
      tt:real;
    end;

    numubatchfiles:integer;       { # files in UL batch queue }
    ubatch:array[1..maxubatchfiles] of record
      fn:string[12];
      section:integer;
      description:string[65];
      vr:byte;
    end;
    ubatchv:array[1..maxubatchfiles] of ^verbrec;
    hiubatchv:integer;

type
   tInFlag = (               { Input flags for "dReadString"                }
      inNormal,              { No case conversion is performed.             }
      inCapital,             { First letter capitallized.                   }
      inUpper,               { All characters are converted to upper case   }
      inLower,               { All characters are converted to lower case   }
      inMixed,               { Mixed case. AKA: word Auto-Capitalization    }
      inWeird,               { All vowels are lowered (ie. MiKe FRiCKeR)    }
      inWarped,              { All constants are lowered (ie. mIkE frIckEr) }
      inCool);               { Only "I"s are lowered (ie. FiEND)            }

   tInChar = set of Char;

const
   rsAbort      = '/AA';     { Allow aborting with ESC or Ctrl-Z, returns '' }
   rsBackGr     = '/BG';     { Use a background (ReadStrBk) color?           }
   rsMin        = '/MN';     { Must enter at least one character             }
   rsNoClean    = '/NC';     { Disables "String-cleaning" (no space trim)    }
   rsNoCR       = '/NR';     { After ENTER is hit, will disable the CR       }
   rsNoEdit     = '/NE';     { Disables all line editing commands            }
   rsNoIns      = '/NI';     { Leave Insert mode off permenantly             }
   rsNormal     = '';        { Default entry mode                            }
   rsPassword   = '/PW';     { Enables password mode (echo char is used)     }
   rsReq        = '/RQ';     { Must fill entire length with chars to exit    }
   rsSpace      = '/SP';     { Enables use of a space for the 1st character  }

   chAlpha      = ['A'..'Z','a'..'z']; { Alpha characters (letters)          }
   chAnyNum     = ['0'..'9','-','+'];  { All numbers with negitive/positives }
   chFilename   = ['!','#'..')',#45,#46,'0'..':','@'..'Z','`'..#123,
                   #125,'~','_'];      { Valid DOS filename characters only  }
   chFileNoExt  = ['!','#'..')',#45,'0'..'9','@'..'Z','`'..#123,
                   #125,'~','_'];      { Valid DOS filename characters only  }
   chDirectory  = ['!','#'..')',#45,#46,'0'..':','@'..'Z','\','`'..#123,
                   #125,'~','_'];      { Valid DOS directory characters only }
   chNormal     = [#32..#254];         { Allow any character (under Chr #32) }
   chNumeric    = ['0'..'9'];          { Number characters from 0 to 9       }

procedure ansig(x,y:integer);
procedure uncrunch(var Addr1,Addr2; BlkLen:Integer);
procedure SetFileAccess(AccessMode:FileAccessType; ShareMode:FileShareType);
Function ResetF(var f):Byte;
procedure shelldos(bat:boolean; cl:string; var rcode:integer);
procedure DisableInterrupts;
procedure EnableInterrupts;
{procedure delay(count:longint);}
procedure sleep(ms:word);
procedure checkwindows;                        (* update sysop window after commandline call *)
procedure autovalidate(c:char; var u:userrec; un:integer);
function isc(var c:char):boolean;
function stripcolor(o:string):string;          (* Remove color from a string *)
function lenn(s:string):integer;
procedure loaduboard(i:integer);
Function LoadBoard(b:word): Boolean;
procedure lcmds(len,c:byte; c1,c2:string);
procedure tc(n:integer);
procedure tb(i:integer);
function mso:boolean;                                          (* Msg Sysop  *)
function fso:boolean;                                          (* File Sysop *)
function cso:boolean;                                          (* CoSysop    *)
function so:boolean;                                           (* Sysop      *)
function timer:real;
function fbaseac(b:byte):boolean;
function mbaseac(nb:integer):boolean;
procedure changefileboard(b:integer);
procedure changeboard(b:integer);
function freek(d:integer):longint;                        (* See disk space  *)
function nma:integer;                                 (* Time Left (tltoday) *)
function okansi:boolean;                                  (* Ansi or Avatar  *)
function okavatar:boolean;                                (* True for avatar *)
function okrip:boolean;                                   (* True for rip    *)
function nsl:real;                  (* Time left after freetime and choptime *)
procedure checkhangup;                                  (* Check for carrier *)
function ccinkey1:char;
function intime(tim:real; tim1,tim2:integer):boolean; (* check whether in time range *)
function sysop:boolean;                                 (* chat availability *)
procedure sl1(s:string);                                (* write to sysoplog *)
procedure sysoplog(s:string);                  (* write indented to sysoplog *)
procedure figurepcr(var badratio:boolean; var want,have,need:integer);
function tch(s:string):string;
function time:string;
function propertime:string;
function date:string;
function date2:string;
function value(s:string):longint;
function cstr(i:longint):string;
function nam:string;
function ageuser(bday:string):integer;   (* returns age of user by birthdate *)
function allcaps(s:string):string;           (* returns a capitalized string *)
function caps(s:string):string;            (* returns a capitalized string.. *)
function leapyear(yr:integer):boolean;
function days(mo,yr:integer):integer;
function daycount(mo,yr:integer):integer;
function daynum(dt:string):integer;
function dat:string;
procedure pr1(s:string);
procedure pr(s:string);
procedure sde;         (* restore curco colors (DOS and tc) loc. after local *)
procedure sdc;
procedure setc(c:byte);
procedure cl(c:integer);
function sqoutsp(s:string):string;
function exdrv(s:string):byte;
function mlnnomci(s:string; l:integer):string;
function mlndot(s:string; l:integer):string;
function mln(s:string; l:integer):string;
function mrn(s:string; l:integer):string;
function mn(i,l:longint):string;
procedure pchar;
procedure dosansi(c:char);
procedure mpl(c:integer);
function substone(src,old,new:string):string;
procedure clearwaves;
procedure addwave(lt:str2; s:astr; t:mcitype);
function findwave(lt:str2):byte;
procedure spromptt1(var s:string; xmci,xclr:boolean);
procedure spromptt(s:string; xmci,xclr:boolean);
procedure sprompt(s:string);
procedure sprint(s:string);
procedure prompt(s:string);
procedure print(s:string);
procedure nl;
procedure spstr(b:word);
function getstr(b:word):string;
procedure prt(s:string);
procedure printacr(s:string; var abort,next:boolean);
procedure prestrict(u:userrec);
function empty:boolean;
function inkey:char;
procedure outkey(c:char);
function checkeventday(i:integer; t:real):boolean;
function checkpreeventtime(i:integer; t:real):boolean;
function checkeventtime(i:integer; t:real):boolean;
function checkevents(t:real):integer;
procedure dm(i:string; var c:char);
procedure doeventstuff;
procedure getkey(var c:char);
procedure cls;
procedure swac(var u:userrec; r:uflags);
procedure acch(c:char; var u:userrec);
function aonoff(b:boolean; s1,s2:string):string;
function onoff(b:boolean):string;
function syn(b:boolean):string;
function yn:boolean;
function pynq(s:string):boolean;
procedure onek(var c:char; ch:string);
function centre(s:string):string;
procedure wkey(var abort,next:boolean);
function ctim(rl:real):string;
function tlef:string;
function longtim(dt:datetimerec):string;
function dt2r(dt:datetimerec):real;
procedure r2dt(r:real; var dt:datetimerec);
procedure timediff(var dt:datetimerec; dt1,dt2:datetimerec);
procedure getdatetime(var dt:datetimerec);
function cstrl(li:longint):string;
function cstrr(rl:real; base:integer):string;
procedure pfl(fn:string; var abort,next:boolean; cr:boolean);
function exist(fn:string):boolean;
procedure printfile(fn:string);
procedure printf(fn:string);
procedure skey(c:char);
function aacs1(u:userrec; un:integer; s:string):boolean;
function aacs(s:string):boolean;
procedure loadurec(var u:userrec; i:integer);
procedure saveurec(u:userrec; i:integer);

(* The following procedures/functions have been placed in the overlay *)

procedure newcomptables;
function  realmsgidx(alias:word):integer;
procedure cline(var s:string; dd:string);
procedure remove_port;
procedure iport;
procedure commandline(s:string);
procedure sclearwindow;
procedure schangewindow(needcreate:boolean; newwind:integer);
procedure sendcom1(c:char);
function recom1(var c:char):boolean;
procedure term_ready(ready_status:boolean);
function checkpw:boolean;
procedure sysopshell(takeuser:boolean);
procedure readinzscan;
procedure savezscanr;
procedure redrawforansi;
Procedure SetCondensedLines;
Procedure Set25Lines;
function getrumor:string;
procedure pausescr;
procedure tleft;
procedure topscr;
procedure readinmacros;
procedure saveuf;
procedure savenode;
procedure wait(b:boolean);
function tacch(c:char):uflags;
procedure rsm(showit:boolean);
procedure inittrapfile;
procedure chatfile(b:boolean);
procedure inu(var i:integer);
procedure ini(var i:byte);
procedure inputwn1(var v:string; l:integer; flags:string; var changed:boolean);
procedure inputwn(var v:string; l:integer; var changed:boolean);
procedure inputwnwc(var v:string; l:integer; var changed:boolean);
procedure inputmain(var s:string; ml:integer; flags:string);
procedure inputwc(var s:string; ml:integer);
procedure input(var s:string; ml:integer);
procedure inputl(var s:string; ml:integer);
procedure inputcaps(var s:string; ml:integer);
procedure inputphone(var s:string);
procedure inputdate(var s:string);
procedure inputed(var s:string; len:integer; flags:string);
procedure inputxy(x,y:byte; var s:string; len:integer);
procedure inputcharxy(x,y:byte; var c:char);
procedure switchyn(x,y:byte; var b:boolean);
function inputnumxy(x,y:byte; l:longint; len:integer; lo,hi:longint):longint;
procedure displaycolor(x,y,color:byte);
procedure inputcolorxy(x,y:byte; var color:byte);
procedure savesystat;  (* save systat *)
procedure readsystat;
procedure mmkey(var s:string);
procedure com_flush_rx;
function com_carrier:boolean;
function com_rx_empty:boolean;
procedure com_set_speed(speed:word);
procedure chat(split:boolean);
procedure showudstats;
procedure skey1(c:char);
function  iReadDate(def : String) : String;
function  iReadPhone(def : String) : String;
function  iReadPostalCode : String;
function  iReadTime(def : String) : String;
function  iReadZipCode : String;
function  iEditString(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Len : Byte; pgLen : Byte) : String;
function  iGetString(f, c, p, l, d, e : String) : String;
function  iReadString(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Len : Byte) : String;

implementation

uses common1, common2, common3, chatstuf, mail4;

(* The following procedures/functions have been placed in the overlay *)

function checkpw:boolean; begin checkpw:=common1.checkpw; end;
procedure newcomptables; begin common1.newcomptables; end;
function realmsgidx(alias:word):integer; begin realmsgidx:=common1.realmsgidx(alias); end;
procedure cline(var s:string; dd:string); begin common1.cline(s,dd); end;
procedure pausescr; begin common1.pausescr; end;
procedure wait(b:boolean); begin common1.wait(b); end;
procedure inittrapfile; begin common1.inittrapfile; end;
procedure chatfile(b:boolean); begin chatstuf.chatfile(b); end;
function chinkey:char; begin chinkey:=chatstuf.chinkey; end;
procedure chat(split:boolean); begin chatstuf.chat(split); end;
procedure sysopshell(takeuser:boolean); begin common1.sysopshell(takeuser); end;
procedure globat(i:integer); begin common1.globat(i); end;
procedure exiterrorlevel; begin common1.exiterrorlevel; end;
procedure showsysfunc; begin common1.showsysfunc; end;
procedure readinzscan; begin common1.readinzscan; end;
procedure savezscanr; begin common1.savezscanr; end;
procedure redrawforansi; begin common1.redrawforansi; end;
Procedure setcondensedlines; begin common1.setcondensedlines; end;
Procedure set25lines; begin common1.set25lines; end;
Function getrumor:string; begin getrumor:=common1.getrumor; end;
procedure rsm(showit:boolean); begin common1.rsm(showit); end;

procedure showudstats; begin common2.showudstats; end;
procedure skey1(c:char); begin common2.skey1(c); end;
procedure savesystat; begin common2.savesystat; end;
procedure readsystat; begin common2.readsystat; end;
procedure remove_port; begin common2.remove_port; end;
procedure iport; begin common2.iport; end;
procedure sendcom1(c:char); begin common2.sendcom1(c); end;
function recom1(var c:char):boolean; begin recom1:=common2.recom1(c); end;
procedure term_ready(ready_status:boolean); begin common2.term_ready(ready_status); end;
procedure commandline(s:string); begin common2.commandline(s); end;
procedure sclearwindow; begin common2.sclearwindow; end;
procedure schangewindow(needcreate:boolean; newwind:integer);
          begin common2.schangewindow(needcreate,newwind); end;
procedure topscr; begin common2.topscr; end;
procedure tleft; begin common2.tleft; end;
procedure readinmacros; begin common2.readinmacros; end;
procedure saveuf; begin common2.saveuf; end;
procedure savenode; begin common2.savenode; end;

procedure inu(var i:integer); begin common3.inu(i); end;
procedure ini(var i:byte); begin common3.ini(i); end;
procedure inputwn1(var v:string; l:integer; flags:string; var changed:boolean);
  begin common3.inputwn1(v,l,flags,changed); end;
procedure inputwn(var v:string; l:integer; var changed:boolean);
  begin common3.inputwn(v,l,changed); end;
procedure inputwnwc(var v:string; l:integer; var changed:boolean);
  begin common3.inputwnwc(v,l,changed); end;
procedure inputmain(var s:string; ml:integer; flags:string);
  begin common3.inputmain(s,ml,flags); end;
procedure inputwc(var s:string; ml:integer); begin common3.inputwc(s,ml); end;
procedure input(var s:string; ml:integer); begin common3.input(s,ml); end;
procedure inputl(var s:string; ml:integer); begin common3.inputl(s,ml); end;
procedure inputcaps(var s:string; ml:integer); begin common3.inputcaps(s,ml); end;
procedure inputphone(var s:string); begin common3.inputphone(s); end;
procedure inputdate(var s:string); begin common3.inputdate(s); end;
procedure mmkey(var s:string); begin common3.mmkey(s); end;
procedure inputed(var s:string; len:integer; flags:string);
  begin common3.inputed(s,len,flags); end;
procedure inputxy(x,y:byte; var s:string; len:integer);
  begin common3.inputxy(x,y,s,len); end;
procedure switchyn(x,y:byte; var b:boolean);
  begin common3.switchyn(x,y,b); end;
function inputnumxy(x,y:byte; l:longint; len:integer; lo,hi:longint):longint;
  begin inputnumxy:=common3.inputnumxy(x,y,l,len,lo,hi); end;
procedure inputcharxy(x,y:byte; var c:char);
  begin common3.inputcharxy(x,y,c); end;
procedure displaycolor(x,y,color:byte);
  begin common3.displaycolor(x,y,color); end;
procedure inputcolorxy(x,y:byte; var color:byte);
  begin common3.inputcolorxy(x,y,color); end;
function  iReadDate(def : String) : String;
  begin iReadDate:=common3.iReadDate(def); end;
function  iReadPhone(def : String) : String;
  begin iReadPhone:=common3.iReadPhone(def); end;
function  iReadPostalCode : String;
  begin iReadPostalCode:=common3.iReadPostalCode; end;
function  iReadTime(def : String) : String;
  begin iReadTime:=common3.iReadTime(def); end;
function  iReadZipCode : String;
  begin iReadZipCode:=common3.iReadZipCode; end;
function  iEditString(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Len : Byte; pgLen : Byte) : String;
  begin iEditString:=common3.iEditString(Def,iFl,iCh,Opt,Len,pgLen); end;
function  iGetString(f, c, p, l, d, e : String) : String;
  begin iGetString:=common3.iGetString(f,c,p,l,d,e); end;
function  iReadString(Def : String; iFl : tInFlag; iCh : tInChar; Opt : String; Len : Byte) : String;
  begin iReadString:=common3.iReadString(Def,iFl,iCh,Opt,Len); end;

procedure com_flush_rx; begin foscom2.com_flush_rx; end;
function com_carrier:boolean; begin com_carrier:=foscom2.com_carrier; end;
function com_rx_empty:boolean; begin com_rx_empty:=foscom2.com_rx_empty; end;
procedure com_set_speed(speed:word); begin foscom2.com_set_speed(speed); end;

(*****************************************************************************)

{$I UNCRUNCH.PAS}

(*
function hexdig(d:integer):char;
begin
  if d<10 then hexdig:=chr(d+ord('0')) else hexdig:=chr(d-10+ord('A'));
end;

function hexstr(num:integer):string;
var i:integer;
    s:string;
begin
  for i:=4 downto 1 do begin
    s[i]:=hexdig(num mod 16);
    num:=num div 16;
  end;
  s[0]:=chr(4);
  hexstr:=s;
end;
*)

procedure setFileAccess(AccessMode:FileAccessType; ShareMode:FileShareType);
begin
  FileMode:=ord(accessmode);
  If lo(dosversion)>=3 then  { Network calls only under DOS 3.0 or greater }
    FileMode:=FileMode or (ord(sharemode) shl 4)
end;

{$F+}
Function ResetF(var f):Byte;
var try:byte;
    ioerror:integer;
Begin
  ResetF:=0;
  Try:=1;
  repeat
    {$I-} reset(file(f)); {$I+}
    ioerror:=ioresult;

    if ioerror=0 then
      exit
    else
    if ioerror=5 then
      sleep(250)
    else begin
      ResetF:=1;
      exit;
    end;

    inc(try);
  until try=10;
  ResetF:=2;
End;
{$F-}

procedure shelldos(bat:boolean; cl:string; var rcode:integer);
const s:string[6]=^M^J^[+'[0m';
var t:text;
    oldline:byte;
    i,speed:integer;
    method:integer; needed:word; env:boolean;
    oldprompt:^string;
begin
  nosound;
  oldline:=linemode;
  if (bat) then begin
    assign(t,'I_SHL'+cstr(nodenum)+'.BAT');
    rewrite(t);
    writeln(t,cl);
    close(t);
    cl:='I_SHL'+cstr(nodenum)+'.BAT';
  end;
  if (cl<>'') then cl:='/c '+cl;

  for i:=1 to length(s) do dosansi(s[i]);
  remove_port;
  if linemode<>25 then set25lines;

  if (systat^.swapshell) then begin
    case systat^.swapshelltype of
      0:method:=use_file;
      1:method:=use_ems;
      2:method:=use_xms;
      else method:=use_all;
    end;
    method:=method or hide_file;
    needed:=$ffff;
    env:=true;
  end;

  new(oldprompt);
  oldprompt^:=getenv('PROMPT');
  putenv('PROMPT=[Illusion] '+oldprompt^);

  if (not systat^.swapshell) then dos.exec(getenv('COMSPEC'),cl) else begin
    tc(7); writeln('Swapping Overlay ... ');
    i:=do_exec(getenv('COMSPEC'),cl,method,needed,env);
    if (i>$00FF) then begin
      writeln('SWAP FAILURE - Shelling without swap.');
      sl1('|R* SWAP FAILURE');
      case i of
        $0101:sl1('|R* No space for swapping.');
        $0102:sl1('|R* Program too low in memory for swapping.');
        $0200..
        $02FF:sl1('|R* Error executing program.');
        $0300..
        $03FF:sl1('|R* DOS error during swap.');
        $0400:sl1('|R* Error allocating enviroment buffer.');
        $0500:sl1('|R* Error preparing swap file.');
        $0501:sl1('|R* MCBs error.');
        $0502:sl1('|R* Error while swapping out.');
        $0600..
        $06FF:sl1('|R* Redirection error during swap.');
      end;
      dos.exec(getenv('COMSPEC'),cl);
    end;
  end;

  putenv('PROMPT='+oldprompt^);
  dispose(oldprompt);
  rcode:=lo(dosexitcode);
  if (bat) then begin
    assign(t,'I_SHL'+cstr(nodenum)+'.BAT');
    {$I-} erase(t); {$I+}
    if (ioresult<>0) then ;
  end;
  if (spd='KB') then speed:=modemr^.waitbaud else speed:=value(spd);
  iport;
  if oldline<>25 then setcondensedlines;
  openport(modemr^.comport,speed,'N',8,1);
end;

procedure DisableInterrupts;
begin
  inline($FA);  {cli}
end;

procedure EnableInterrupts;
begin
  inline($FB);  {sti}
end;

(*
procedure delay(count:longint);
var machineid:byte absolute $ffff:$000e;
    { $FF=PC  $FE=XT  $FB=Later_Model_XT  $FD=PC_Junior
      $FC=XT-286,AT,PS/2_Model_50&60  $FA=PS/2_Model_30
      $F9=PC_Convertible  $F8=PS/2_Model_70&80 }
    read_port:byte;
    clock_count:longint;
    accum_count:word;
    i:byte;
begin
  if machineid=$FB then read_port:=$62 else read_port:=$61;

  port[$43]:=$B2;                { set timer chip to one shot mode }
  port[$42]:=lo(count);          { lower byte }
  port[$42]:=hi(count);          { higher byte }
  port[$61]:=port[$61] and $FC;  { trigger timer }
  port[$61]:=port[$61] or  $01;  { start count at 1 }

  for i:=1 to 10 do begin
    repeat  { read bit 5 until low, and $20 allows read bit 5 only }
    until (port[$61] and $20 <> 0);
    port[$61]:=port[$61] and $FC;  { trigger timer }
    port[$61]:=port[$61] or  $01;  { start count at 1 }
  end;
end;
*)
(*
procedure sleep(i:longint);
var r,j:real;
begin
  r:=timer; j:=i/1000;
  repeat until (abs(r-timer)>=j);
end;
*)
procedure sleep(ms:word); assembler;
asm
  mov ax,1000
  mul ms
  mov cx,dx
  mov dx,ax
  mov ah,$86
  int $15
end;

procedure sendoutputbuff;
var i:byte;
begin
  if (length(outputbuff^)=0) then exit;
  if (outcom) then com_tx_string(outputbuff^);
  outputbuff^:='';
end;

procedure checkwindows;
begin
  if (useron and (nsl>0)) and (not dontgoaway) then
    if ( (abs(timer-commandlinecount)>=5.0) and (commandlinecount>0))
    then begin
      commandlinecount:=-1; topscr;
    end else
    if (abs(timer-topscrcount)>=60.0) then topscr;
end;

procedure ansig(x,y:integer);
begin
  if (okansi) then
  begin
    if (outcom) then
    begin
      if (okavatar) then
        pr1(^V^H+chr(y)+chr(x))
      else
        pr1(#27+'['+cstr(y)+';'+cstr(x)+'H');
    end;
    if (wantout) then gotoxy(x,y);
  end;
end;

procedure autovalidate(c:char; var u:userrec; un:integer);
var settings:set of uflags;
    val:^valrec;
    valf:file of valrec;
    v:byte;
    n:char;
begin
  settings:=[rlogon,rchat,rvalidate,rfastlogon,ramsg,rpostan,rpost,remail,
             rvoting,rmsg,fnodlratio,fnopostratio,fnofilepts,fnodeletion];
  with u do begin
    if (un=usernum) then begin
      realsl:=sl;
      realdsl:=dsl;
    end;
    v:=ord(c)-65;
    new(val);
    assign(valf,systat^.datapath+'AUTOVAL.DAT');
    SetFileAccess(ReadOnly,DenyNone);
    reset(valf);
    seek(valf,v);
    read(valf,val^);
    close(valf);

    sl:=val^.sl; dsl:=val^.dsl;
    usernote:=val^.unote;
    if val^.credit<>-1 then credit:=val^.credit;
    if val^.fp<>-1 then filepoints:=val^.fp;
    if (val^.actype) then begin
      ac:=ac-settings;
      ac:=ac+(val^.ac*settings);
    end else
      ac:=ac+(val^.ac*settings);

    if (val^.artype) then
      ar:=val^.ar
    else
      for n:='A' to 'Z' do if (n in val^.ar) then ar:=ar+[n];
    tltoday:=systat^.timeallow[sl];

    if (useron) then topscr;
    saveurec(u,un);
    newcomptables;
    dispose(val);
    if un=usernum then begin
      thisuser:=u; realsl:=sl; realdsl:=dsl;
    end;
  end;
end;

function isc(var c:char):boolean;
begin
  if (pos(c,'kbgcrmywKBGCRMYWA')<>0)
    then isc:=TRUE else isc:=FALSE;
end;

function stripcolor(o:string):string;
var s:string;
    i:integer;
    lc:boolean; lt:byte;
begin
  s:=''; lc:=FALSE; lt:=0;
  for i:=1 to length(o) do
    if (lc) then
      lc:=FALSE
    else
    if (lt>0) then
      dec(lt)
    else
    if (o[i]='|') then
    begin
      if (i<>length(o)) and (isc(o[i+1])) then
        lc:=TRUE
      else
      if (i<length(o)-1) and (o[i+1] in ['0'..'2']) and (o[i+2] in ['0'..'9']) then
        lt:=2
      else
        s:=s+o[i];
    end else
      s:=s+o[i];
  stripcolor:=s;
end;

function lenn(s:string):integer;
begin
  lenn:=length(stripcolor(s));
end;

procedure loaduboard(i:integer);
var ulfo:boolean;
begin
  if (readuboard<>i) then begin
    ulfo:=(filerec(ulf).mode<>fmclosed);
    if (not ulfo) then begin
      SetFileAccess(ReadOnly,DenyNone);
      Reset(ulf);
    end;
    if ((i>=0) and (i<=filesize(ulf)-1)) then begin
      seek(ulf,i);
      read(ulf,memuboard);
    end else
      memuboard:=tempuboard;
    readuboard:=i;
    if (not ulfo) then close(ulf);
  end;
end;

Function LoadBoard(b:word): Boolean;
  Var
    OpenError : Word;
    CloseError: Word;     { Not checked }
    Ok        : Boolean;

  Begin
    LoadBoard:=FALSE;
    SetFileAccess(ReadWrite,DenyNone);
    Reset(bf);
    OpenError:=IoResult;
    If OpenError = 0 Then
      Begin
        Seek(bf,b);
  {$I-} Read(bf,MemBoard); {$I+}
        Ok:=(IoResult=0);
        Close(bf);
        CloseError:=IoResult;
      End;

    If Ok Then
      With MemBoard do Begin
        RealOnly:=mbRealName in mbStat;
        BoardLoaded:=b;
        LoadBoard:=TRUE;
      End;
  End;

procedure lcmds(len,c:byte; c1,c2:string);
var s:^string;
begin
  new(s);
  s^:=copy(c1,2,lenn(c1)-1);
  if (c2<>'') then s^:=mln(s^,len-1);
  sprompt('|w(|W'+c1[1]+'|w)'+s^);
  if (c2<>'') then
    sprompt('|w(|W'+c2[1]+'|w)'+copy(c2,2,lenn(c2)-1));
  dispose(s);
  nl;
end;

procedure tc(n:integer);
begin
  textcolor(n);
end;

procedure tb(i:integer);
begin
  textbackground(i);
end;

function mso:boolean;
begin
  mso:=(aacs(systat^.msop)) or (aacs(memboard.subopacs)) or (cso);
end;

function fso:boolean;
begin
  fso:=(aacs(systat^.fsop)) or (cso);
end;

function cso:boolean;
begin
  cso:=((so) or (aacs(systat^.csop)));
end;

function so:boolean;
begin
  so:=(aacs(systat^.sop));
end;

function timer:real;
var r:registers;
    h,m,s,t:real;
begin
  r.ax:=44*256;
  msdos(dos.registers(r));
  h:=(r.cx div 256); m:=(r.cx mod 256); s:=(r.dx div 256); t:=(r.dx mod 256);
  timer:=h*3600+m*60+s+t/100;
end;

function fbaseac(b:byte):boolean;
begin
  fbaseac:=FALSE;
  if ((b<0) or (b>maxulb)) then exit;
  loaduboard(b);
  fbaseac:=aacs(memuboard.acs);
end;

function mbaseac(nb:integer):boolean;
begin
  mbaseac:=FALSE;
  if ((nb<0) or (nb>numboards)) then exit;
  if loadboard(nb) then;
  mbaseac:=aacs(memboard.acs);
end;

procedure changefileboard(b:integer);
begin
  if (b>=0) and (b<=maxulb) then
    if (fbaseac(b)) then begin
      fileboard:=b;
      thisuser.lastfil:=fileboard;
    end;
end;

procedure changeboard(b:integer);
var rb:word;
begin
  rb:=RealMsgIdx(b);
  if (rb>=0) and (rb<=numboards) then
    if (mbaseac(rb)) then begin
      Board:=b;
      BoardReal:=rb;
      thisuser.lastmsg:=board;
    end;
end;

function freek(d:integer):longint;
var lng:longint;
begin
  lng:=diskfree(d);
  freek:=lng div 1024;
end;

function nma:integer;
begin
  nma:=thisuser.tltoday;
end;

function okansi:boolean;
begin
  okansi:=((ansi in thisuser.ac)
        or (avatar in thisuser.ac)
        or (rip in thisuser.ac));
end;

function okavatar:boolean;
begin
  okavatar:=(avatar in thisuser.ac);
end;

function okrip:boolean;
begin
  okrip:=(rip in thisuser.ac);
end;

function nsl:real;
var ddt,dt:datetimerec;
    beenon:real;
begin
  if ((useron) or (not inwfcmenu)) then begin
    getdatetime(dt);
    timediff(ddt,timeon,dt);
    beenon:=dt2r(ddt);
    nsl:=((nma*60.0+extratime+freetime)-(beenon+choptime));
  end else
    nsl:=3600.0
end;

procedure checkhangup;
begin
  if (not localioonly) and (not com_carrier) then
    if ((outcom) and (not hangup)) then begin
      hangup:=TRUE; hungup:=TRUE;
    end;
  checkwindows;
end;

function ccinkey1:char;
var c:char;
begin
  if (recom1(c)) then begin
    ccinkey1:=c;
  end else
    ccinkey1:=#0;
end;

function intime(tim:real; tim1,tim2:integer):boolean;
(* "tim" is seconds (timer) time; tim1/tim2 are minutes time. *)
begin
  intime:=TRUE;
  while (tim>=24.0*60.0*60.0) do tim:=tim-24.0*60.0*60.0;
  if (tim1<>tim2) then
    if (tim2>tim1) then
      if (tim<=tim1*60.0) or (tim>=tim2*60.0) then
        intime:=FALSE
      else
    else
      if (tim<=tim1*60.0) and (tim>=tim2*60.0) then
        intime:=FALSE;
end;

function sysop:boolean;
var s:boolean;
  function sysop1:boolean;
  var a:byte absolute $0000:$0417;
  begin
    if (a and 16)=0 then sysop1:=TRUE else sysop1:=FALSE;
  end;
begin
  s:=sysop1;
  if (not intime(timer,systat^.lowtime,systat^.hitime)) then s:=FALSE;
  if (rchat in thisuser.ac) then s:=FALSE;
  sysop:=s;
end;

procedure opensysopf;
begin
  assign(sysopf,systat^.trappath+date+'.'+cstr(nodenum));
  {$I-} append(sysopf); {$I+}
  if (ioresult<>0) then begin
    rewrite(sysopf);
    append(sysopf);
  end;
end;

function tch1(s:string):string;
begin
  if (length(s)>2) then
    s:=copy(s,length(s)-1,2)
  else
    if (length(s)=1) then s:=' '+s;
  tch1:=s;
end;

function logtime:string;
var h,m,s,ap:string[3];
    hh,mm,ss,ss100:word;
begin
  gettime(hh,mm,ss,ss100);
  if hh=0 then begin hh:=12; ap:='am'; end else
  if hh<12 then ap:='am' else
  if hh=12 then ap:='pm' else
  begin ap:='pm'; hh:=hh-12; end;
  str(hh,h); str(mm,m); str(ss,s);
  logtime:=tch1(h)+':'+tch(m)+ap;
end;

procedure sl1(s:string);
begin
  if (systat^.stripclog) then s:=stripcolor(s);
  if (textrec(sysopf).mode<>fmoutput) then opensysopf;
  writeln(sysopf,logtime+'  '+s);
  if ((thisuser.slogseperate) and (textrec(sysopf1).mode=fmoutput)) then
    writeln(sysopf1,s);
end;

procedure sysoplog(s:string);
begin
  sl1('   '+s);
end;

procedure figurepcr(var badratio:boolean; var want,have,need:integer);
var x1,x2,x3:integer;
    y1,y2,y3:real;
    donepcr:boolean;
begin
  badratio:=false;

  x1:=thisuser.msgpost; x2:=thisuser.loggedon;
  if x1<1 then x1:=1; if x2<1 then x2:=1;

  y1:=int(x1); y2:=int(x2);
  y3:=y1/y2; y3:=y3*100; x3:=trunc(y3); have:=x3;

  x1:=1; x2:=systat^.postratio[thisuser.sl];
  if x2>=1 then begin
    y1:=int(x1); y2:=int(x2); y3:=y1/y2;
    x3:=trunc(y3*100); want:=x3; donepcr:=FALSE;
    if (thisuser.msgpost<1) then have:=0;
  end else
    donepcr:=TRUE;

  if (not donepcr) then begin
    if (have<want) then badratio:=TRUE;
    if (fnopostratio in thisuser.ac) or aacs(systat^.nopostratio) then
      badratio:=FALSE;
    if badratio then begin
      need:=trunc(y3*thisuser.loggedon);
      need:=need-thisuser.msgpost;
      if (need<1) then need:=1;
    end;
  end;
end;

function tch(s:string):string;
begin
  if (length(s)>2) then
    s:=copy(s,length(s)-1,2)
  else
    if (length(s)=1) then s:='0'+s;
  tch:=s;
end;

function time:string;
var h,m,s:string[3];
    hh,mm,ss,ss100:word;
begin
  gettime(hh,mm,ss,ss100);
  str(hh,h); str(mm,m); str(ss,s);
  time:=tch(h)+':'+tch(m)+':'+tch(s);
end;

function propertime:string;
var h,m,s,ap:string[3];
    hh,mm,ss,ss100:word;
begin
  gettime(hh,mm,ss,ss100);
  if hh=0 then begin hh:=12; ap:='am'; end else
  if hh<12 then ap:='am' else
  if hh=12 then ap:='pm' else
  begin ap:='pm'; hh:=hh-12; end;
  str(hh,h); str(mm,m); str(ss,s);
  propertime:=tch(h)+':'+tch(m)+':'+tch(s)+' '+ap;
end;

function date:string;
var y,m,d:string[3];
    yy,mm,dd,dow:word;
begin
  getdate(yy,mm,dd,dow);
  str(yy-1900,y); str(mm,m); str(dd,d);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
end;

function date2:string;
var y,m,d:string[3];
    yy,mm,dd,dow:word;
begin
  getdate(yy,mm,dd,dow);
  str(yy-1900,y); str(mm,m); str(dd,d);
  date2:=tch(m)+'-'+tch(d)+'-'+tch(y);
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

function cstr(i:longint):string;
var c:string[16];
begin
  str(i,c);
  cstr:=c;
end;

function nam:string;
begin
  nam:=caps(thisuser.name)+' #'+cstr(usernum);
end;

function ageuser(bday:string):integer;
var i:integer;
begin
  i:=value(copy(date,7,2))-value(copy(bday,7,2));
  if (daynum(copy(bday,1,6)+copy(date,7,2))>daynum(date)) then dec(i);
  ageuser:=i;
end;

function allcaps(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do s[i]:=upcase(s[i]);
  allcaps:=s;
end;

function caps(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do
    if (s[i] in ['A'..'Z']) then s[i]:=chr(ord(s[i])+32);
  for i:=1 to length(s) do
    if (s[i]=' ') and (s[i+1] in ['a'..'z']) then s[i+1]:=upcase(s[i+1]);
  s[1]:=upcase(s[1]);
  caps:=s;
end;

function leapyear(yr:integer):boolean;
begin
  leapyear:=(yr mod 4=0) and ((yr mod 100<>0) or (yr mod 400=0));
end;

function days(mo,yr:integer):integer;
var d:integer;
begin
  d:=value(copy('312831303130313130313031',1+(mo-1)*2,2));
  if ((mo=2) and (leapyear(yr))) then inc(d);
  days:=d;
end;

function daycount(mo,yr:integer):integer;
var m,t:integer;
begin
  t:=0;
  for m:=1 to (mo-1) do t:=t+days(m,yr);
  daycount:=t;
end;

function daynum(dt:string):integer;
var d,m,y,t,c:integer;
begin
  t:=0;
  m:=value(copy(dt,1,2));
  d:=value(copy(dt,4,2));
  y:=value(copy(dt,7,2))+1900;
  for c:=1985 to y-1 do
    if (leapyear(c)) then inc(t,366) else inc(t,365);
  t:=t+daycount(m,y)+(d-1);
  daynum:=t;
  
  (* if y<1985 then daynum:=0; *)
  
end;

function dat:string;   (*  5:43 pm  Fri Jul 28, 1989  *)
const mon:array [1..12] of string[3] =
          ('Jan','Feb','Mar','Apr','May','Jun',
           'Jul','Aug','Sep','Oct','Nov','Dec');
var ap,x,y:string; i:integer;
    year,month,day,dayofweek,hour,minute,second,sec100:word;
begin
  getdate(year,month,day,dayofweek);
  gettime(hour,minute,second,sec100);

  if (hour<12) then
    ap:='am'
  else begin
    ap:='pm';
    if (hour>12) then dec(hour,12);
  end;
  if (hour=0) then hour:=12;

  dat:=cstr(hour)+':'+tch(cstr(minute))+' '+ap+'  '+
       copy('SunMonTueWedThuFriSat',dayofweek*3+1,3)+' '+
       mon[month]+' '+cstr(day)+', '+cstr(year);
end;

procedure pr1(s:string);
var i:integer;
begin
  sendoutputbuff;
  com_tx_string(s);
end;

procedure pr(s:string);
begin
  pr1(s+#13);
end;

procedure scc;    {* make local textcolor = curco *}
var f:integer;
begin
  if (okansi) then begin
    f:=curco and 7;
    if (curco and 8)<>0 then inc(f,8);
    if (curco and 128)<>0 then inc(f,16);
    tc(f);
    textbackground((curco shr 4) and 7);
  end;
end;

procedure sde; { restore curco colors (DOS and tc) loc. after local }
var c:byte;
    b:boolean;
begin
  if (okansi) then begin
    c:=curco; curco:=255-curco;
    b:=outcom; outcom:=FALSE;
    setc(c);
    outcom:=b;
  end;
end;

procedure sdc; { restore curco colors (DOS and tc) loc/rem after loc/rem }
var c:byte;
begin
  if (okansi) then begin
    c:=curco; curco:=255-curco;
    setc(c);
  end;
end;

function getc(c:byte):string;
const xclr:array[0..7] of char=('0','4','2','6','1','5','3','7');
var s:string;
    b:boolean;

  procedure adto(ss:string);
  begin
    if (s[length(s)]<>';') and (s[length(s)]<>'[') then s:=s+';';
    s:=s+ss; b:=TRUE;
  end;

begin
  b:=FALSE;
  if ((curco and (not c)) and $88)<>0 then begin
    s:=#27+'[0';
    curco:=$07;
  end else
    s:=#27+'[';
  if (c and 7<>curco and 7) then adto('3'+xclr[c and 7]);
  if (c and $70<>curco and $70) then adto('4'+xclr[(c shr 4) and 7]);
  if (c and 128<>0) then adto('5');
  if (c and 8<>0) then adto('1');
  if (not b) then adto('3'+xclr[c and 7]);
  s:=s+'m';
  getc:=s;
end;

procedure omtcolor(c:byte);
begin
  pr1(^V^A+chr(c and $7F));
  if (c and $80<>0) then pr1(^V^B);
end;

procedure setc(c:byte);
var s:string;
    i:integer;
begin
  if ((c<>curco) or (dosansion)) then begin
    s:=getc(c); curco:=c;
    if (okansi) then begin
      if (outcom) then
        if (okavatar) then omtcolor(c) else pr1(s);
      if (wantout) then begin
        textattr:=c;
        if (dosansion) then begin
          s:=#27+'[0;'+copy(s,3,length(s)-2);
          for i:=1 to length(s) do dosansi(s[i]);
        end;
      end;
    end;
    scc;
  end;
end;

procedure cl(c:integer);
begin
  if (okansi) then
    case c of
      0..15 :setc((curco and $F0) or c);
      16..23:setc((curco and $8F) or (c shl 4));
      24    :setc(curco xor $80);
      {k}107:setc(0);
      {b} 98:setc(1);
      {g}103:setc(2);
      {c} 99:setc(3);
      {r}114:setc(4);
      {m}109:setc(5);
      {y}121:setc(6);
      {w}119:setc(7);
      {K} 75:setc(8);
      {B} 66:setc(9);
      {G} 71:setc(10);
      {C} 67:setc(11);
      {R} 82:setc(12);
      {M} 77:setc(13);
      {Y} 89:setc(14);
      {W} 87:setc(15);
      {A} 65:setc((curco and $F0) or random(16));
    end;
end;

function sqoutsp(s:string):string;
begin
  while (pos(' ',s)>0) do delete(s,pos(' ',s),1);
  sqoutsp:=s;
end;

function exdrv(s:string):byte;
begin
  s:=fexpand(s);
  exdrv:=ord(s[1])-64;
end;

function mlnnomci(s:string; l:integer):string;
begin
  if (length(s)<l) then begin
    fillchar(s[ord(s[0])+1],l-ord(s[0]),#32);
    s[0]:=chr(l);
  end else
    s[0]:=chr(l);
  mlnnomci:=s;
end;

function mln(s:string; l:integer):string;
var k:byte;
begin
  k:=lenn(s);
  if k<l then begin
    fillchar(s[ord(s[0])+1],l-k,#32);
    s[0]:=chr(ord(s[0])+(l-k));
  end else begin
    s[0]:=chr(ord(s[0])+(l-k));
    while lenn(s)>l do
      s[0]:=chr(ord(s[0])-1);
  end;
  mln:=s;
end;

function mlndot(s:string; l:integer):string;
var k:byte;
begin
  s:=s+'|b';
  k:=lenn(s);
  if k<l then begin
    fillchar(s[ord(s[0])+1],l-k,'.');
    s[0]:=chr(ord(s[0])+(l-k));
  end else begin
    s[0]:=chr(ord(s[0])+(l-k));
    while lenn(s)>l do
      s[0]:=chr(ord(s[0])-1);
  end;
  mlndot:=s;
end;

function mrn(s:string; l:integer):string;
var k:byte; t:string[80];
begin
  k:=lenn(s);
  if k<l then begin
    fillchar(t,sizeof(t),#32);
    t[0]:=chr(l-k);
    insert(t,s,1);
  end else begin
    s[0]:=chr(ord(s[0])+(l-k));
    while lenn(s)>l do
      s[0]:=chr(ord(s[0])-1);
  end;
  mrn:=s;
end;

function mn(i,l:longint):string;
begin
  mn:=mlnnomci(cstr(i),l);
end;

procedure dosansi(c:char);
begin
  ansioutput(c);
end;

procedure mpl(c:integer);
var x:integer;
begin
  if (okansi) then begin
    setc(systat^.inputfieldcolor);
    x:=wherex;
    if (outcom) then pr1(mln(' ',c));
    if (wantout) then write(mln(' ',c));
    gotoxy(x,wherey);
    if (outcom) then begin
      if (okavatar) then pr1(^Y+^H+chr(c)) else pr1(#27+'['+cstr(c)+'D');
    end;
  end;
end;

function substone(src,old,new:string):string;
var p:integer;
begin
  if (old<>'') then begin
    p:=pos(old,allcaps(src));
    if (p>0) then begin
      insert(new,src,p+length(old));
      delete(src,p,length(old));
    end;
  end;
  substone:=src;
end;

procedure clearwaves;
var i:byte;
begin
  for i:=1 to numwaves do dispose(waves[i]);
  numwaves:=0;
end;

procedure addwave(lt:str2; s:astr; t:mcitype);
begin
  inc(numwaves);
  new(waves[numwaves]);
  waves[numwaves]^.letters:=lt;
  waves[numwaves]^.s:=s;
  waves[numwaves]^.t:=t;
  waves[numwaves]^.x:=1;
  waves[numwaves]^.y:=1;
  waves[numwaves]^.a:=7;
end;

function findwave(lt:str2):byte;
var i:byte;
begin
  i:=1;
  while (i<=numwaves) and (waves[i]^.letters<>lt) do inc(i);
  if (i>numwaves) then findwave:=0 else findwave:=i;
end;

function mcn(s:string; l:integer):string;
var i:integer;
begin
  i:=lenn(s);
  if i<l then
    s:=copy('                                               ',1,
      (l-i) div 2)+s;
  s:=mln(s,l);
  mcn:=s;
end;

function findvote:word;
var vdata:file of vdatar;
    vd:vdatar; num:integer;
    vna:word;
begin
  vna:=0;
  assign(vdata,systat^.datapath+'VOTING.DAT');
  setfileaccess(readonly,denynone);
  reset(vdata);
  for num:=1 to filesize(vdata) do
  begin
    seek(vdata,num-1);
    read(vdata,vd);
    if (thisuser.vote[num]=0) or (thisuser.vote[num]>vd.numchoices) then inc(vna);
  end;
  close(vdata);
  findvote:=vna;
end;

procedure spromptt1(var s:string; xmci,xclr:boolean);
  { xmci=xlate mcis?  xclr=xlate colors? }
type str2=string[2];
var mci,clr,wave,   { Processing mci/color code? }
    badwave,        { Bad wave code? }
    badclr,         { Bad color code? }
    badmci:boolean; { Bad MCI code? }
    c,mc:char;      { MCI 1st char }
    js:str2;
    ss,
    dum:string;     { User name temp. string }
    i,j,l,justc:integer;
    badratio:boolean;          { PCR }
    want,have,need:integer;    {stuff}

  function c36to10(m:str2):word;
  var i:integer; d:array[1..2] of byte;
  begin
    for i:=1 to 2 do begin
      d[i]:=ord(m[i]);
      if (d[i]>=48) and (d[i]<=58) then dec(d[i],48) else dec(d[i],55);
    end;
    c36to10:=(d[1]*36)+d[2];
  end;

  procedure sendit(c:char);
  var oldco:byte;

     procedure sendc(c:char);
     begin
       if (wantout) then
         if (not dosansion) then write(c) else dosansi(c);
       if (length(outputbuff^)=250) then sendoutputbuff;
       outputbuff^:=outputbuff^+c;
     end;

  begin
    if (trapping) then write(trapfile,c);
    if (c<#32) and (not (tpansii.isavatar or tpansii.isctrly)) then begin
      case c of
        ^G:begin
             sendoutputbuff;
             if (outcom) then sendcom1(c);
             exit;
           end;
        ^J:begin
             if ((ctrljoff) and (not dosansion)) or (ch) then begin
               if ((curco and $70)<>0) then begin
                 sendoutputbuff;
                 oldco:=curco;
                 curco:=curco and $8F;
                 sdc;
                 sendcom1(^J);
                 curco:=oldco;
                 sdc;
                 if ch then lil:=0
               end else begin
                 if ch then lil:=0;
                 sendc(^J);
               end;
             end else begin
               if dosansion then lil:=0;
               sendc(^J);
             end;

             inc(lil);
             if (lil>=thisuser.pagelen-1) then begin
               lil:=0;
               sendoutputbuff;
               if (pause in thisuser.ac) then pausescr;
             end;
             exit;
           end;
        ^L:begin
             lil:=0;
             dosansion:=TRUE;
           end;
        ^M:begin
             if (not ctrljoff) and (not dosansion) and (not ch) then begin
               sendoutputbuff;
               oldco:=7;
               if ((outcom) and (okansi)) then
                 if (okavatar) then omtcolor(oldco) else pr1(getc(oldco));
               curco:=oldco; textattr:=oldco;
               sendc(^M);
             end;
           end;
        ^[,^Y,^V:dosansion:=TRUE;
      end; { case }

      sendc(c);

    end else
       sendc(c);
  end; {proc sendit}

begin
  checkhangup; if (hangup) then exit;
  mci:=FALSE; mc:=#0; dum:=nam; justc:=-1;
  clr:=FALSE; wave:=FALSE;

  if (not okansi) then s:=stripcolor(s);

  for i:=1 to length(s) do
  begin

    if clr then
    begin
      if (s[i] in ['~','|','%','','']) then badclr:=TRUE
      else
      if ((mc=#0) and (isc(s[i]))) then
      begin
        if xclr then
        begin
          sendoutputbuff;
          cl(ord(s[i]));
          clr:=FALSE;
        end else
        begin
          sendit('|');
          sendit(s[i]);
          clr:=FALSE;
        end;
      end else
      begin
        if (mc=#0) then
          mc:=s[i]
        else
        if (mc in ['0'..'2']) then
        begin
          if ((xclr) and (value(mc+s[i])<=24) and (s[i] in ['0'..'9'])) then
          begin
            sendoutputbuff;
            cl(value(mc+s[i]));
          end else
          begin
            sendit('|'); sendit(mc); sendit(s[i]);
          end;
          clr:=FALSE;
        end else
        begin
          case mc of
            {A}
            {B}
            {C}
            'D':case upcase(s[i]) of
                  'H':begin                               { delays }
                        sendoutputbuff;
                        if xmci then sleep(500);
                        ss:='';
                      end;
                  'M':begin
                        sendoutputbuff;
                        if xmci then delay(1);
                        ss:='';
                      end;
                  'Q':begin
                        sendoutputbuff;
                        if xmci then sleep(250);
                        ss:='';
                      end;
                  'S':begin
                        sendoutputbuff;
                        if xmci then sleep(1000);
                        ss:='';
                      end;
                  else badclr:=TRUE;
                end;
            'I':if (s[i] in ['0'..'9']) and (length(s)-i>=3) and (xmci) then
                begin
                  sendoutputbuff;
                  for j:=1 to 3 do
                    if not (s[i+j] in ['0'..'9']) then badclr:=TRUE;
                  if (not badclr) and (xclr) then
                  begin
                    ansig(value(copy(s,i,2)),value(copy(s,i+2,2)));
                    inc(i,3);
                  end;
                  ss:='';
                end else
                  badclr:=TRUE;
            {K}
            'L':case upcase(s[i]) of
                  'F':if xmci then ss:=^M^J else ss:='';  { cr/lf          }
                  'I':begin                               { line across scr}
                        fillchar(ss[1],thisuser.linelen-1,'Ä');
                        ss[0]:=chr(thisuser.linelen-1);
                      end;
                  'C':ss:=#27+'[K';                       { clreol         }
                  else badclr:=TRUE;
                end;
            {M}
            'P':case upcase(s[i]) of
                  'A':begin                               { pause          }
                        sendoutputbuff;
                        if xmci then pausescr;
                        ss:='';
                      end;
                  'G':ss:=^G;                             { beep           }
                  'K':begin
                        sendoutputbuff;
                        if xmci then getkey(c);
                        ss:='';
                      end;
                  else badclr:=TRUE;
                end;
            'S':case upcase(s[i]) of
                  'B':ss:=^H;                             { backspace      }
                  'C':begin                               { screen clear   }
                        sendoutputbuff;
                        if xmci then cls;
                        ss:='';
                      end;
                  else badclr:=TRUE;
                end;
            {Y}
            {W}
            else badclr:=TRUE;
          end; {CASE}
          if not(xclr) and not(xmci) then badclr:=TRUE;
          if not badclr then
          begin
            spromptt1(ss,xmci,xclr);
            dosansion:=FALSE;
          end;
          clr:=FALSE;
        end;
      end;
      if badclr then
      begin
        ss:='|';
        if (mc<>#0) then ss:=ss+mc;
        if s[i]='|' then begin
          clr:=TRUE; badclr:=FALSE; mc:=#0;
        end else
        if s[i]='' then begin
          xclr:=not xclr; xmci:=not xmci; clr:=FALSE;
        end else
        if s[i]='' then begin
          xmci:=not xmci; clr:=FALSE;
        end else
        if s[i]='%' then begin
          mci:=TRUE; badmci:=FALSE; mc:=#0; clr:=FALSE; wave:=FALSE;
        end else
        if s[i]='~' then begin
          wave:=TRUE; badwave:=FALSE; mc:=#0; clr:=FALSE; mci:=FALSE;
        end else
          ss:=ss+s[i];
        for j:=1 to length(ss) do sendit(ss[j]);
      end;
    end else

    if mci then
    begin
      if (s[i] in ['~','|','%','','']) then badmci:=TRUE
      else
      if ((mc=#0) and (xmci)) then mc:=upcase(s[i])
      else
      if (mc=#0) then mc:=s[i]
      else
      begin
        case mc of
          'M':case upcase(s[i]) of                  { MSG }
                'A':ss:=cstr(board);                    { base number    }
                'C':begin                               { current msg #  }
                      If Msg<>nil then
                        ss:=cstr(Msg^.GetMsgNum)
                      else
                        ss:='0';
                    end;
                'F':begin                               { first msg #    }
                      If Msg<>nil then begin
                        l:=Msg^.GetMsgNum;
                        Msg^.SeekFirst(1);
                        Msg^.MsgStartUp;
                        ss:=cstr(Msg^.GetMsgNum);
                        Msg^.SeekFirst(l);
                        Msg^.MsgStartup;
                      end else
                        ss:='0';
                      end;
                'H':begin                               { user's PCR     }
                      figurepcr(badratio,want,have,need);
                      ss:=cstr(have)+'%';
                    end;
                'N':begin                               { base name      }
                      if loadboard(BoardReal) then;
                      ss:=memboard.name;
                    end;
                'R':begin                               { required PCR   }
                      figurepcr(badratio,want,have,need);
                      ss:=cstr(want)+'%';
                    end;
                'S':begin                               { PCR status     }
                      figurepcr(badratio,want,have,need);
                      if (aacs(systat^.nopostratio)) or (fnopostratio in thisuser.ac) then
                        ss:=getstr(542)
                      else
                        ss:=aonoff(badratio,getstr(543),getstr(544));
                    end;
                'T':begin                               { total msgs     }
                      if Msg<>nil then
                        ss:=cstr(Msg^.GetHighMsgNum)
                      else
                        ss:='0';
                    end;
                'W':ss:=cstr(MailWaitingForUser(usernum)); { mail waiting }
                else badmci:=TRUE;
              end;
          'F':case upcase(s[i]) of                  { FILE }
                '#':ss:=cstr(ccuboards[1][fileboard]);  { base #         }
                'A':ss:=cstr(numubatchfiles);           { # in ul batch  }
                'B':ss:=cstr(numbatchfiles);            { # in dl batch  }
                'D':ss:=cstr(thisuser.downloads);       { # of downloads }
                'K':begin                               { k free         }
                      loaduboard(fileboard);
                      ss:=cstrl(freek(exdrv(memuboard.dlpath)));
                    end;
                'P':begin                               { file points    }
                      if (aacs(systat^.nofilepts)) or (fnofilepts in thisuser.ac) then
                        ss:=getstr(542)
                      else
                        ss:=cstr(thisuser.filepoints);
                    end;
                'N':begin                               { base name      }
                      loaduboard(fileboard);
                      ss:=memuboard.name;
                    end;
                'U':ss:=cstr(thisuser.uploads);         { # of uploads   }
                'W':ss:=cstrl(thisuser.uk);             { uploads in k   }
                'X':ss:=cstrl(thisuser.dk);             { downloads in k }
                else badmci:=TRUE;
              end;
          'C':case upcase(s[i]) of                  { CHAT }
                'R':ss:=chatr;                          { reason         }
                'S':if (sysop) then ss:=getstr(539)     { sysop status   }
                               else ss:=getstr(540);
                else badmci:=TRUE;
              end;
          'I':case upcase(s[i]) of                  { IP Addressed of User *NEW* }
                'P':ss:=userip;                         { Connecting User's IP }
                
                else badmci:=TRUE;
              end;
          'N':case upcase(s[i]) of                  { NODE / MODEM }
                'N':ss:=cstr(nodenum);                  { node #         }
                'S':ss:=realspd;                        { Connect speed  }
                else badmci:=TRUE;
              end;
          'O':case upcase(s[i]) of                  { MISC }
                'B':ss:=systat^.bbsname;                 { bbs name       }
                'C':ss:=cmdlist;                        { menu cmds.     }
                'D':ss:=date;                           { da date        }
                'E':case systype of                     { environment    }
                      0:ss:=getstr(535);
                      1:ss:=getstr(536);
                      2:ss:=getstr(537);
                      3:ss:=getstr(538);
                      4:ss:=getstr(603);
                    end;
                'F':ss:=thisuser.conference;            { current conf char }
                'M':ss:=cstr(trunc(nsl/60));            { minutes left   }
                'N':ss:=conference.name;                { current conf name }
                'P':ss:=propertime;                     { properized time }
                'R':ss:=getrumor;                       { rumor          }
                'S':ss:=systat^.sysopname;               { sysop name     }
                'T':ss:=time;                           { un-p. time     }
                'V':ss:=cstr(findvote);                 { voting ?s left }
                else badmci:=TRUE;
              end;
          'U':case upcase(s[i]) of                  { USER }
                'A':ss:=thisuser.street;                { address        }
                'B':ss:=thisuser.bday;                  { birthday       }
                'C':ss:=thisuser.citystate;             { city/state     }
                'D':ss:=cstr(thisuser.dsl);             { DSL            }
                'E':ss:=cstr(thisuser.illegal);         { illegal logons }
                'F':ss:=copy(thisuser.realname,         { first name     }
                        1,pos(' ',thisuser.realname)-1);
                'G':begin                               { gender m/f     }
                      ss[1]:=thisuser.sex;
                      ss[0]:=chr(1);
                    end;
                'H':ss:=copy(dum,1,pos('#',dum)-2);     { handle (no #)  }
                'I':ss:=cstr(thisuser.emailsent);       { email sent     }
                'J':ss:=cstr(ageuser(thisuser.bday));   { age            }
                'K':ss:=cstr(thisuser.loggedon);        { total calls    }
                'L':begin                               { last name      }
                      dum:=caps(thisuser.realname);
                      l:=length(dum);
                      while ((dum[l]<>' ') and (l>1)) do begin
                        ss:=copy(dum,l,(length(dum)-l)+1);
                        dec(l);
                      end;
                    end;
                'M':ss:=cstr(thisuser.msgpost);         { public posts   }
                'N':ss:=dum;                            { name (inc. #)  }
                'O':ss:=thisuser.occupation;            { occupation     }
                'P':ss:=thisuser.ph;                    { phone #        }
                'Q':ss:=cstr(thisuser.ttimeon);         { total min      }
                'R':ss:=thisuser.realname;              { real name      }
                'S':ss:=cstr(thisuser.sl);              { SL             }
                'T':ss:=tlef;                           { time left      }
                'U':ss:=thisuser.usernote;              { user note      }
                'V':ss:=thisuser.note;                  { sysop note     }
                'W':ss:=thisuser.wherebbs;              { reference      }
                'X':ss:=cstr(thisuser.credit);          { credits        }
                'Y':ss:=thisuser.computer;              { computer type  }
                'Z':ss:=thisuser.zipcode;               { zip code       }
                '$':ss:=cstr(thisuser.timebank);        { min. in tbank  }
                '0':begin                               { video type     }
                      if ((ansi in thisuser.ac) or (avatar in thisuser.ac)) then
                      begin
                        if (ansi in thisuser.ac) then ss:=getstr(482);
                        if (avatar in thisuser.ac) then ss:=getstr(483);
                        if (rip in thisuser.ac) then ss:=getstr(484);
                      end else
                        ss:=getstr(485);
                    end;
                '1':ss:=thisuser.firston;               { firston date   }
                '2':ss:=thisuser.laston;                { laston date    }
                '3':ss:=aonoff(thisuser.forusr=0,       { mail forwarded }
                        'No',cstr(thisuser.forusr));
                '4':ss:=cstr(thisuser.ontoday);         { # calls today  }
                '5':ss:=thisuser.pw;                    { password       }
                '6':case thisuser.edtype of             { editor type    }
                      0:ss:=getstr(487);
                      1:ss:=getstr(488);
                      2:ss:=getstr(489);
                    end;
                '7':ss:=cstr(thisuser.linelen)+'x'+     { screen size    }
                        cstr(thisuser.pagelen);
                '8':ss:=syn(pause in thisuser.ac);      { pause status   }
                '9':ss:=syn(not (novice in thisuser.ac)); { xpert status }
                else badmci:=TRUE;
              end;
          else badmci:=TRUE;
        end; {CASE}
        if not(xmci) then badmci:=TRUE;
        if not badmci then begin
          if (i<=length(s)-3) and (s[i+1] in ['{','}','@']) and
             (s[i+2] in ['0'..'9']) and (s[i+3] in ['0'..'9']) then
          begin
            justc:=value(copy(s,i+2,2));
            case s[i+1] of
              '{':spromptt(mln(ss,justc),xmci,xclr);
              '}':spromptt(mrn(ss,justc),xmci,xclr);
              '@':spromptt(mcn(ss,justc),xmci,xclr);
            end;
            inc(i,3);
          end else
            spromptt1(ss,xmci,xclr);
        end;
        mci:=FALSE;
      end;
      if badmci then
      begin
        ss:='%';
        if (mc<>#0) then ss:=ss+mc;
        if s[i]='%' then begin
          mci:=TRUE; badmci:=FALSE; mc:=#0;
        end else
        if s[i]='|' then begin
          clr:=TRUE; badclr:=FALSE; mc:=#0; mci:=FALSE; wave:=FALSE;
        end else
        if s[i]='' then begin
          xclr:=not xclr; xmci:=not xmci; mci:=FALSE;
        end else
        if s[i]='' then begin
          xmci:=not xmci; mci:=FALSE;
        end else
        if s[i]='~' then begin
          wave:=TRUE; badwave:=FALSE; mc:=#0; mci:=FALSE; clr:=FALSE;
        end else
          ss:=ss+s[i];
        for j:=1 to length(ss) do sendit(ss[j]);
      end;
    end else

    if wave then
    begin
      if (s[i] in ['~','|','%','','']) then badwave:=TRUE
      else
      if (mc=#0) then mc:=s[i]
      else
      begin
        js:=upcase(mc)+upcase(s[i]);
        if (numwaves>0) then
        begin
          j:=findwave(js);
          if (j=0) then
          begin
            if (mc in ['0'..'9']) and (s[i] in ['0'..'9']) then
              ss:=''
            else
              badwave:=TRUE;
          end else
          begin
            if (waves[j]^.t=xya) then
            begin
              waves[j]^.x:=wherex;
              waves[j]^.y:=wherey;
              waves[j]^.a:=curco;
              ss:='';
            end else
{             if (waves[j]^.s='') then
                ss:=''
              else }
                ss:=waves[j]^.s;
          end;
        end else
          badwave:=TRUE;
        if not(xmci) then badwave:=TRUE;
        if not badwave then
        begin
          if (i<=length(s)-3) and (s[i+1] in ['{','}','@']) and
             (s[i+2] in ['0'..'9']) and (s[i+3] in ['0'..'9']) then
          begin
            justc:=value(copy(s,i+2,2));
            case s[i+1] of
              '{':spromptt(mln(ss,justc),xmci,xclr);
              '}':spromptt(mrn(ss,justc),xmci,xclr);
              '@':spromptt(mcn(ss,justc),xmci,xclr);
            end;
            inc(i,3);
          end else
            spromptt1(ss,xmci,xclr);
        end;
        wave:=FALSE;
      end;
      if badwave then begin
        ss:='~';
        if (mc<>#0) then ss:=ss+mc;
        if s[i]='~' then begin
          wave:=TRUE; badwave:=FALSE; mc:=#0;
        end else
        if s[i]='|' then begin
          clr:=TRUE; badclr:=FALSE; mc:=#0; mci:=FALSE; wave:=FALSE;
        end else
        if s[i]='' then begin
          xclr:=not xclr; xmci:=not xmci; wave:=FALSE;
        end else
        if s[i]='' then begin
          xmci:=not xmci; wave:=FALSE;
        end else
        if s[i]='%' then begin
          mci:=TRUE; badmci:=FALSE; mc:=#0; clr:=FALSE; wave:=FALSE;
        end else
          ss:=ss+s[i];
        for j:=1 to length(ss) do sendit(ss[j]);
      end;

    end else if s[i]='|' then begin
      clr:=TRUE; badclr:=FALSE; mc:=#0;
    end else if s[i]='%' then begin
      mci:=TRUE; badmci:=FALSE; mc:=#0;
    end else if s[i]='~' then begin
      wave:=TRUE; badwave:=FALSE; mc:=#0;
    end else if s[i]='' then begin
      xclr:=not xclr; xmci:=not xmci;
    end else if s[i]='' then begin
      xmci:=not xmci;
    end else
      sendit(s[i]);

  end; {for i:= loop}
  if mci or clr or wave then begin
    if mci then sendit('%') else
    if clr then sendit('|') else
    sendit('~');
    if mc<>#0 then sendit(mc);
  end;
  sendoutputbuff;
end;

procedure spromptt(s:string; xmci,xclr:boolean);
begin
  spromptt1(s,xmci,xclr);
end;

procedure sprompt(s:string);
begin
  spromptt1(s,TRUE,TRUE);
end;

procedure sprint(s:string);
begin
  spromptt1(s,TRUE,TRUE); nl;
end;

procedure prompt(s:string);
begin
  spromptt1(s,FALSE,FALSE);
end;

procedure print(s:string);
begin
  prompt(s); nl;
end;

procedure nl;
begin
  prompt(^M^J);
end;

procedure spstr(b:word);
var i:byte;
    s:astr;
begin
  s:=getstr(b);
  
{ 
  if s[1]='&' then
  begin
    delete(s,1,1);
    while (s[1]=' ') and (length(s)>0) do delete(s,1,1);
    if (pos(' ',s)=0) then
      iplmodule(s,'')
    else
      iplmodule(copy(s,1,pos(' ',s)-1),
                copy(s,pos(' ',s)+1,length(s)-pos(' ',s)));
  end else
} 

  if s[1]='@' then
  begin
    delete(s,1,1);
    i:=pos('@',s);
    if (i<>0) then
    begin
      printf(copy(s,1,i-1));
      delete(s,1,i);
      sprompt(s);
    end
    else
      printf(s);
  end else
    sprompt(s);
end;

function getstr(b:word):string;
begin
  if (b<10) then
    getstr:=strglobal^[b]
  else
  if (abs(b-firstbuff)<19) and (b-firstbuff>=0) then
    getstr:=strbuff^[b-firstbuff]
  else
  begin
    seek(fstringf,b);
    blockread(fstringf,strbuff^,20);
    firstbuff:=b;
    getstr:=strbuff^[0];
  end;
end;

procedure prt(s:string);
begin
  cl(ord('B')); sprompt(s); cl(ord('C'));
end;



procedure printacr(s:string; var abort,next:boolean);
var xmci, isansi:boolean;

  procedure doboxedtitle(s:string);
  const B_UL='Ö'; B_UR='·'; B_LL='Ó'; B_LR='½';
        B_TOP='Ä'; B_BOT='Ä'; B_LFT='º'; B_RGT='º';
  var b:array[0..7] of char;
      x,numsp:integer;
      i:string;

    function ritr(c:char; l:integer):string;
    var s:string; i:integer;
    begin
      s:=''; for i:=1 to l do s:=s+c; ritr:=s;
    end;

  begin
    i:=s;
    for x:=0 to 7 do
      case x of
        0:b[x]:=B_UL;   1:b[x]:=B_UR;   2:b[x]:=B_LL;  3:b[x]:=B_LR;
        4:b[x]:=B_TOP;  5:b[x]:=B_BOT;  6:b[x]:=B_LFT; 7:b[x]:=B_RGT;
      end;
    numsp:=(thisuser.linelen div 2)-((lenn(i)+4) div 2);
    printacr('|B'+ritr(#32,numsp)+b[0]+ritr(b[4],lenn(i)+2)+b[1],abort,next);
    printacr('|B'+ritr(#32,numsp)+b[6]+' |C'+i+'|B '+b[7],abort,next);
    printacr('|B'+ritr(#32,numsp)+b[2]+ritr(b[5],lenn(i)+2)+b[3],abort,next);
  end; {doboxtitle}

begin {printacr}
  isansi:=(pos(^[,s)<>0) or (pos(^V,s)<>0);

  if ((allowabort) and (abort)) then exit;
  abort:=FALSE; checkhangup;
  xmci:=(not write_msg);

  if (s[1]=#2) and (not isansi) then begin
    spromptt(centre(s),xmci,TRUE); wkey(abort,next); nl;
  end else
  if (length(s)>=3) and (copy(s,1,3)=BOXEDTITLE) then begin
    doboxedtitle(copy(s,4,length(s)-3));
  end else begin
    {
    if (not isansi) then spromptt1(s,xmci,TRUE,TRUE) else spromptt1(s,xmci,FALSE,FALSE);
    }
    spromptt1(s,xmci,TRUE);
    wkey(abort,next);
  end;
  if (abort) then begin curco:=255-curco; cl(ord('w')); end;
  if (not croff) then if (not abort) then nl;
  croff:=FALSE;
end;

procedure prestrict(u:userrec);
var r:uflags;
begin
  for r:=rlogon to rmsg do
    if (r in u.ac) then write(copy('LCVFA*PEKM',ord(r)+1,1)) else write('-');
  writeln;
end;

function empty:boolean;
var e:boolean;
begin
  e:=(not keypressed);
  if ((not localioonly) and (incom) and (e)) then e:=(com_rx_empty);
  if (hangup) then
  begin
    if (not localioonly) then com_flush_rx;
    e:=TRUE;
  end;
  empty:=e;
end;

function inkey:char;
var c:char;
begin
  c:=#0; inkey:=#0;
  checkhangup;
  if (keypressed) then
  begin
    c:=readkey;

    if (wherecurrent<>normal) then
    begin
      skey1(c);
      c:=#1;
    end else
    if ((c=#0) and (keypressed)) then
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
    inkey:=c;
  end else
    if (incom) then inkey:=ccinkey1;
end;

procedure outtrap(c:char);
begin
  if (c<>^G) then write(trapfile,c);
end;

procedure outkey(c:char);
var i:byte;
begin
  if ((not echo) and (c in [#32..#255])) then begin
    sendcom1(gc(getstr(000),1));
    if (systat^.localsec) and (c>#32) then c:=gc(getstr(000),1);
    if wantout then if dosansion then dosansi(c) else write(c);
  end else
    spromptt(c,FALSE,FALSE);
end;

function checkeventday(i:integer; t:real):boolean;
var year,month,day,dayofweek:word;
    e:integer;
begin
  checkeventday:=FALSE;
  with events[i]^ do begin
    getdate(year,month,day,dayofweek);
    e:=0;
    if (timer+t>=24.0*60.0*60.0) then begin
      inc(dayofweek); e:=1;
      if (dayofweek>6) then dayofweek:=0;
    end;
    if (monthly) then begin
      if (value(copy(date,4,2))+e=execdays) then
        checkeventday:=TRUE;
    end else begin
      if ((1 shl (6-dayofweek)) and execdays<>0) then
        checkeventday:=TRUE;
    end;
  end;
end;

function checkpreeventtime(i:integer; t:real):boolean;
begin
  with events[i]^ do
    if (busytime=0) then
      checkpreeventtime:=FALSE
    else
      checkpreeventtime:=intime(timer+t,exectime-busytime,exectime);
end;

function checkeventtime(i:integer; t:real):boolean;
begin
  with events[i]^ do
    if (duration=0) then
      checkeventtime:=FALSE
    else
      checkeventtime:=intime(timer+t,exectime,exectime+duration);
end;

function checkevents(t:real):integer;
var i:integer;
begin
  for i:=0 to numevents do
    with events[i]^ do
      if (active) then
        if (checkeventday(i,t)) then begin
          checkevents:=i;
          if (checkpreeventtime(i,t)) or (checkeventtime(i,t)) then begin
            if (etype in ['D','E','P']) then exit;
            if ((etype='A') and (not aacs(execdata)) and (useron)) then exit;
          end;
        end;
  checkevents:=-1;
end;

procedure dm(i:string; var c:char);
begin
  buf:=i;
  if (buf<>'') then begin
    c:=buf[1];
    buf:=copy(buf,2,length(buf)-1);
  end;
end;

procedure doeventstuff;
var e:integer;
    aaa:boolean;
begin
  case telluserevent of
    0:begin
        oltime:=timer;
        e:=checkevents(systat^.eventwarningtime);
        if (e<>-1) then begin
          telluserevent:=1;
          nl;
          aaa:=allowabort; allowabort:=FALSE;
          printf('revent'+cstr(e));
          allowabort:=aaa;
          if (nofile) then begin
            nl; nl;
      sprint(^G'|RNOTICE: |YScheduled Event Approaching.'^G);
      sprint(^G'|YSystem will be shut down in '+
          copy(ctim(systat^.eventwarningtime),4,5)+' minutes.'^G);
      nl; nl;
      end;
    end else
      if (checkevents(0)=-1) then telluserevent:=0;
    end;
  1:begin
    oltime:=timer;
    e:=checkevents(0);
    if (e<>-1) then begin
      telluserevent:=2;
      sysoplog('++ Logged user off in preparation for event #'+cstr(e));
      nl; nl; sprint(^G'|YSystem Event - Disconnecting...'^G); nl; nl;
      hangup:=TRUE;
    end;
    end;
  end;
end;

procedure getkey(var c:char);
var dt,ddt:datetimerec;
    aphase,spinnum:integer;
    b,tf,t1:boolean;
begin
  lil:=0; spinnum:=1;
  if (buf<>'') then begin
    c:=buf[1];
    buf:=copy(buf,2,length(buf)-1);
  end else begin
    if (not empty) then begin
      if (ch) then c:=chinkey else c:=inkey;
    end else begin
      getdatetime(tim);
      t1:=FALSE; tf:=FALSE;
      c:=#0;
      if (alert in thisuser.ac) then aphase:=1 else aphase:=0;
      while ((c=#0) and (not hangup)) do begin
        if (aphase<>0) then begin
          case aphase of
            1:begin sound(250); sleep(100); end;
            2:begin sound(500); sleep(150); end;
            3:begin sound(1000); sleep(250); end;
            4:begin sound(500); sleep(150); end;
            5:begin sound(250); sleep(100); end;
          end;
          aphase:=aphase mod 5+1;
        end;

        if getkeyspin then begin
          prompt(gc(getstr(000),spinnum+2));
          inc(spinnum);
          if spinnum>=5 then spinnum:=1;
          sleep(50);
          prompt(^H);
        end;

        if systype>0 then timeslice;
        if (ch) then c:=chinkey else c:=inkey;
        getdatetime(dt);
        timediff(ddt,tim,dt);
        if (systat^.timeout<>-1) and
           (dt2r(ddt)>systat^.timeout*60) and (c=#0) then begin
          nl; nl;
          printf('timedout');
          if (nofile) then
            print('Time out has occurred.  Log off time was at '+time+'.');
          nl; nl;
          hangup:=TRUE;
          sysoplog('|R! User was Timed-out at '+time);
        end;
        if (systat^.timeoutbell<>-1) and
           (dt2r(ddt)>systat^.timeoutbell*60) and (not tf) and (c=#0) then begin
          tf:=TRUE;
          outkey(^G); sleep(100); outkey(^G);
        end;
        checkhangup;
      end;
      nosound;
    end;
  end;
  if (checkit) then
    if (ord(c) and 128>0) then checkit:=FALSE;
  if getkeyspin then prompt(' '^H);
  if (c<#32) then skey(c);
end;

procedure cls;
begin
  if (not okansi) then exit;
  if (okansi) then begin
    if (outcom) then begin
      if (okavatar) then pr(^L) else pr(#27+'[2J');
    end;
    if (wantout) then clrscr;
  end;
  if (trapping) then writeln(trapfile,^L);
  cl(ord('w'));
  lil:=0;
end;

procedure swac(var u:userrec; r:uflags);
begin
  if (r in u.ac) then
    exclude(u.ac,r) else include(u.ac,r);
end;

function tacch(c:char):uflags;
begin
  case c of
    'L':tacch:=rlogon;
    'C':tacch:=rchat;
    'V':tacch:=rvalidate;
    'F':tacch:=rfastlogon;
    'A':tacch:=ramsg;
    '*':tacch:=rpostan;
    'P':tacch:=rpost;
    'E':tacch:=remail;
    'K':tacch:=rvoting;
    'M':tacch:=rmsg;
    '1':tacch:=fnodlratio;
    '2':tacch:=fnopostratio;
    '3':tacch:=fnofilepts;
    '4':tacch:=fnodeletion;
  end;
end;

procedure acch(c:char; var u:userrec);
begin
  swac(u,tacch(c));
end;

function aonoff(b:boolean; s1,s2:string):string;
begin
  if (b) then aonoff:=s1 else aonoff:=s2;
end;

function onoff(b:boolean):string;
begin
  if (b) then onoff:=getstr(531) else onoff:=getstr(532);
end;

function syn(b:boolean):string;
begin
  if (b) then syn:=getstr(533) else syn:=getstr(534);
end;

function yn:boolean;
var c:char; i:byte;
    done1:boolean;
begin
  done1:=false;
  if (not hangup) then begin
    if okansi then begin
      if dyny then spstr(193) else spstr(194);
    end else begin
      if dyny then spstr(195) else spstr(196);
    end;
    repeat
      repeat
        getkey(c); c:=upcase(c);
      until (c in ['Y','N',' ','C',^M,^N,'4','6','D']) or (hangup);
      if ((c=^M) or (c=^N)) then begin
        if dyny then c:='Y' else c:='N';
      end;
      case c of
        ' ','4','6','D','C':begin
              dyny:=not dyny;
              if okansi then begin
                if dyny then begin
                  if gc(getstr(194),1)<>'@' then
                    for i:=1 to length(stripcolor(getstr(194))) do prompt(^H#32^H);
                  spstr(193);
                end else begin
                  if gc(getstr(193),1)<>'@' then
                    for i:=1 to length(stripcolor(getstr(193))) do prompt(^H#32^H);
                  spstr(194);
                end;
              end else begin
                if dyny then begin
                  if gc(getstr(196),1)<>'@' then
                    for i:=1 to length(stripcolor(getstr(196))) do prompt(^H#32^H);
                  spstr(195);
                end else begin
                  if gc(getstr(195),1)<>'@' then
                    for i:=1 to length(stripcolor(getstr(195))) do prompt(^H#32^H);
                  spstr(196);
                end;
              end;
              done1:=FALSE; c:='X';
            end;
        'Y':begin
              if not dyny then begin
                if okansi then
                begin
{}{}              if gc(getstr(194),1)<>'@' then
                    for i:=1 to length(stripcolor(getstr(194))) do prompt(^H#32^H)
                end else
                  if gc(getstr(196),1)<>'@' then
                    for i:=1 to length(stripcolor(getstr(196))) do prompt(^H#32^H);
              end else begin
                if okansi then
                begin
                  if gc(getstr(193),1)<>'@' then
                    for i:=1 to length(stripcolor(getstr(193))) do prompt(^H#32^H)
                end else
                  if gc(getstr(195),1)<>'@' then
                    for i:=1 to length(stripcolor(getstr(195))) do prompt(^H#32^H);
              end;
              if okansi then
                spstr(197)
              else
                spstr(199);
              yn:=TRUE; done1:=TRUE;
            end;
        'N':begin
              if dyny then begin
                if okansi then
                begin
                  if gc(getstr(193),1)<>'@' then
                    for i:=1 to length(stripcolor(getstr(193))) do prompt(^H#32^H)
                end else
                  if gc(getstr(195),1)<>'@' then
                    for i:=1 to length(stripcolor(getstr(195))) do prompt(^H#32^H);
              end else begin
                if okansi then
                begin
{}{}              if gc(getstr(194),1)<>'@' then
                    for i:=1 to length(stripcolor(getstr(194))) do prompt(^H#32^H)
                end else
                  if gc(getstr(196),1)<>'@' then
                    for i:=1 to length(stripcolor(getstr(196))) do prompt(^H#32^H);
              end;
              if okansi then
                spstr(198)
              else
                spstr(200);
              yn:=FALSE; done1:=TRUE;
            end;
      end;
      checkhangup;
      if (hangup) then yn:=false;
    until hangup or done1;
  end; nl;
  dyny:=FALSE;
end;

function pynq(s:string):boolean;
begin
  sprompt(s);
  pynq:=yn;
end;

procedure onek(var c:char; ch:string);
var s:string;
begin
  repeat
    if (not (onekey in thisuser.ac)) then begin
      input(s,3);
      if length(s)>=1 then c:=s[1] else
        if (s='') and (pos(^M,ch)<>0) then c:=^M else
          c:=' ';
    end else begin
      getkey(c);
      c:=upcase(c);
    end;
  until (pos(c,ch)>0) or (hangup);
  if (hangup) then c:=ch[1];
  if (onekey in thisuser.ac) then begin
    if (onekda) then
      if (c in [#13,#32..#255]) then
        outkey(c);
    if (onekcr) then nl;
  end;
end;

function centre(s:string):string;
var i:integer;
begin
  if (s[1]=#2) then s:=copy(s,2,length(s)-1);
  i:=lenn(s);
  if i<thisuser.linelen then
    s:=copy('                                               ',1,
      (thisuser.linelen-i) div 2)+s;
  centre:=s;
end;

procedure wkey(var abort,next:boolean);
var c:char;
begin
  if (empty) then exit;
  if ((abort) or (hangup)) then exit;

  getkey(c);
  case upcase(c) of
    ' ',^C,^X,^K:abort:=TRUE;
          'N',^N:begin abort:=TRUE; next:=TRUE; end;
          'P',^S:pausescr;
  end;
  if (not allowabort) then begin abort:=FALSE; next:=FALSE; end;
  if (abort) then begin com_purge_tx; spstr(5); end;
end;

function ctim(rl:real):string;
var h,m,s:string;
begin
  s:=tch(cstr(abs(trunc(rl-int(rl/60.0)*60.0))));
  m:=tch(cstr(abs(trunc(int(rl/60.0)-int(rl/3600.0)*60.0))));
  h:=cstr(abs(trunc(rl/3600.0)));
  if (length(h)=1) then h:='0'+h;
  ctim:=h+':'+m+':'+s;
end;

function tlef:string;
begin
  tlef:=ctim(nsl);
end;

function longtim(dt:datetimerec):string;
var s:string;
    d:integer;

  procedure ads(comma:boolean; i:integer; lab:string);
  begin
    if (i<>0) then begin
      s:=s+cstrl(i)+' '+lab;
      if (i<>1) then s:=s+'s';
      if (comma) then s:=s+', ';
    end;
  end;

begin
  s:='';
  with dt do begin
    d:=day;
    if (d>=7) then begin
      ads(TRUE,abs(d div 7),'week');
      d:=d mod 7;
    end;
    ads(TRUE,abs(d),'day');
    ads(TRUE,abs(hour),'hour');
    ads(TRUE,abs(min),'minute');
    ads(FALSE,abs(sec),'second');
  end;
  if (s='') then s:='0 seconds';
  if (copy(s,length(s)-1,2)=', ') then s:=copy(s,1,length(s)-2);
  longtim:=s;
end;

function dt2r(dt:datetimerec):real;
begin
  with dt do
    dt2r:=day*86400.0+hour*3600.0+min*60.0+sec;
end;

procedure r2dt(r:real; var dt:datetimerec);
begin
  with dt do begin
    day:=trunc(r/86400.0); r:=r-(day*86400.0);
    hour:=trunc(r/3600.0); r:=r-(hour*3600.0);
    min:=trunc(r/60.0); r:=r-(min*60.0);
    sec:=trunc(r);
  end;
end;

procedure timediff(var dt:datetimerec; dt1,dt2:datetimerec);
begin
  with dt do begin
    day:=dt2.day-dt1.day;
    hour:=dt2.hour-dt1.hour;
    min:=dt2.min-dt1.min;
    sec:=dt2.sec-dt1.sec;

    if (hour<0) then begin inc(hour,24); dec(day); end;
    if (min<0) then begin inc(min,60); dec(hour); end;
    if (sec<0) then begin inc(sec,60); dec(min); end;
  end;
end;

procedure getdatetime(var dt:datetimerec);
var w1,w2,w3,w4:word;
begin
  gettime(w1,w2,w3,w4);
  with dt do begin
    day:=daynum(date);
    hour:=w1;
    min:=w2;
    sec:=w3;
  end;
end;

function cstrl(li:longint):string;
var c:string;
begin
  str(li,c);
  cstrl:=c;
end;

function cstrr(rl:real; base:integer):string;
var i:integer;
    s:string;
    r1,r2:real;
begin
  if (rl<=0.0) then cstrr:='0'
  else begin
    r1:=ln(rl)/ln(1.0*base);
    r2:=exp(ln(1.0*base)*(trunc(r1)));
    s:='';
    while (r2>0.999) do begin
      i:=trunc(rl/r2);
      s:=s+copy('0123456789ABCDEF',i+1,1);
      rl:=rl-i*r2;
      r2:=r2/(1.0*base);
    end;
    cstrr:=s;
  end;
end;

procedure pfl(fn:string; var abort,next:boolean; cr:boolean);
var fil:text;
    filbuf1:array[1..1024] of char;
    ofn:string;
    ls:string[255];
    ps:integer;
    c:char;
    oldpause,oaa,isrip:boolean;
begin
  oaa:=allowabort;
  allowabort:=TRUE;
  abort:=FALSE; next:=FALSE;
  oldpause:=(pause in thisuser.ac);
  nofile:=FALSE;
  isrip:=FALSE;
  if (not hangup) then begin
    assign(fil,sqoutsp(fn));
    {$I-} reset(fil); {$I+}
    if (ioresult<>0) then nofile:=TRUE
    else begin
      SetTextBuf(fil,filbuf1);
      if okrip and (copy(allcaps(fn),length(fn)-3,4)='.RIP') then
        begin
          exclude(thisuser.ac,pause);
          pr1(#27'[2!'); pr1('!|e'); pr1('!|E'); pr1('!|1K'); sleep(60);
          isrip:=TRUE;
        end
      else isrip:=FALSE;
      abort:=FALSE;
      while ((not eof(fil)) and (not nofile) and
             (not abort) and (not hangup)) do begin
        ps:=0;
        repeat
          inc(ps);
          read(fil,ls[ps]);
        until ((ls[ps]=^M) or (ps=255) or (eof(fil)) or (hangup));
        ls[0]:=chr(ps);
        if (ls[ps]=^M) then begin
          if (not eof(fil)) then read(fil,c);
          ls[0]:=chr(ps-1);
        end else
          croff:=TRUE;
        if ((pos(^[,ls)<>0) or (pos(^V,ls)<>0) or (pos('!|',ls)<>0)) then ctrljoff:=TRUE;
        if not isrip then printacr(ls,abort,next) else begin spromptt1(ls,FALSE,FALSE); nl; end;
      end;
      close(fil);
    end;
  end;
  if (oldpause) then include(thisuser.ac,pause);
  if (abort) then aborted:=true;
  allowabort:=oaa;
  ctrljoff:=FALSE;
  if isrip then
    begin
      for ps:=1 to 3 do pr1('!|#'); pr1(#27'[1!');
    end;
  curco:=255-curco; cl(ord('w'));
  redrawforansi;
end;

function exist(fn:string):boolean;
var srec:searchrec;
begin
  findfirst(sqoutsp(fn),anyfile,srec);
  exist:=(doserror=0);
end;

procedure printfile(fn:string);
var s:string;
    year,month,day,dayofweek:word;
    i:integer;
    abort,next:boolean;
begin
  fn:=allcaps(fn); s:=fn;
  if (copy(fn,length(fn)-3,4)='.ANS') then begin
    if (exist(copy(fn,1,length(fn)-4)+'.AN1')) then
      repeat
        i:=random(10);
        if (i=0) then
          fn:=copy(fn,1,length(fn)-4)+'.ANS'
        else
          fn:=copy(fn,1,length(fn)-4)+'.AN'+cstr(i);
      until (exist(fn));

    getdate(year,month,day,dayofweek);
    s:=fn; s[length(s)-1]:=chr(dayofweek+48);
    if (exist(s)) then fn:=s;
  end;
  pfl(fn,abort,next,TRUE);
end;

procedure printf(fn:string);              { see if an *.ANS file is available }
var ffn:^string;
    ps,ns,es:string;                      { if you have ansi graphics invoked }
    i,j:integer;
begin
  nofile:=TRUE;
  aborted:=false;
  fn:=sqoutsp(fn);
  if (fn='') then exit;
  if (pos('\',fn)<>0) then j:=1
  else begin
    j:=2;
    fsplit(fexpand(fn),ps,ns,es);
    if (not exist(systat^.textpath+ns+'.*')) then
      if (not exist(systat^.datapath+ns+'.*')) then exit;
  end;
  new(ffn);
  for i:=1 to j do begin
    ffn^:=fn;
    if ((pos('\',fn)=0) and (pos(':',fn)=0)) then
      case i of
        1:ffn^:=systat^.textpath+ffn^;
        2:ffn^:=systat^.datapath+ffn^;
      end;
    ffn^:=fexpand(ffn^);
    if (pos('.',fn)<>0) then printfile(ffn^)
      else begin
        if ((okrip) and (exist(ffn^+'.RIP'))) then printfile(ffn^+'.RIP') else
        if ((okavatar) and (exist(ffn^+'.AVT'))) then printfile(ffn^+'.AVT') else
        if ((okansi) and (exist(ffn^+'.ANS'))) then printfile(ffn^+'.ANS');
        if (nofile) then
          if (exist(ffn^+'.MSG')) then printfile(ffn^+'.MSG');
      end;
    if (not nofile) then begin dispose(ffn); exit; end;
  end;
  dispose(ffn);
end;

procedure skey(c:char);   (* Global user keys *)
var ddt,dt:datetimerec;
    bb:byte;
begin
  case c of
   ^D,^E,^F,^R:
      if (macok) and (buf='') then dm(' '+macros^.macro[pos(c,^D^E^F^R)],c);
   ^T:if ch and useron then begin
        bb:=curco;
        sprint('|cDate/Time: |C'+dat);
        r2dt(nsl,dt);
        sprint('|cTime left: |C'+longtim(dt));
        getdatetime(dt);
        timediff(ddt,timeon,dt);
        sprint('|cTime on  : |C'+longtim(ddt));
        nl;
        curco:=bb; sdc;
      end;
  end;
end;

procedure pchar;
begin
  if (gc(getstr(0),2)<>' ') then prt(gc(getstr(000),2));
end;

function aacs1(u:userrec; un:integer; s:string):boolean;
var s1,s2:string;
    p1,p2,i,j:integer;
    c,c1,c2:char;
    b,badratio:boolean;
    want,have,need:integer;

  procedure getrest;
  begin
    s1:=c;
    p1:=i;
    if ((i<>1) and (s[i-1]='!')) then begin s1:='!'+s1; dec(p1); end;
    if (c in ['C','F','G','R','V','X']) then begin
      s1:=s1+s[i+1];
      inc(i);
    end else begin
      j:=i+1;
      repeat
        if (s[j] in ['0'..'9']) then begin
          s1:=s1+s[j];
          inc(j);
        end;
      until ((j>length(s)) or (not (s[j] in ['0'..'9'])));
      i:=j-1;
    end;
    p2:=i;
  end;

  function argstat(s:string):boolean;
  var vs:string;
      year,month,day,dayofweek,hour,minute,second,sec100:word;
      vsi:integer; val,val2:valrec; valf:file of valrec;
      conf:confrrec; conff:file of confrrec;
      boolstate,res:boolean;
  begin
    boolstate:=(s[1]<>'!');
    if (not boolstate) then s:=copy(s,2,length(s)-1);
    vs:=copy(s,2,length(s)-1); vsi:=value(vs);
    case s[1] of
      'A':res:=(ageuser(u.bday)>=vsi);
      'B':res:=((value(realspd)>=value(vs+'00')) or (spd='KB'));
      'C':if (upcase(vs[1]) in ['@'..'Z']) then
          begin
            vs[1]:=upcase(vs[1]);
            if (u.conference='@') then
            begin
              assign(conff,systat^.datapath+'CONF.DAT');
              setfileaccess(readwrite,denynone);
              reset(conff);
              seek(conff,ord(vs[1])-64);
              read(conff,conf);
              close(conff);
              res:=aacs1(u,un,conf.acs);
            end else
              res:=(u.conference=vs[1]);
          end else
            res:=true;
      'D':res:=(u.dsl>=vsi);
      'E':res:=(u.credit>=vsi);
      'F':res:=(upcase(vs[1]) in u.ar);
      'G':res:=(u.sex=upcase(vs[1]));
      'H':begin
            gettime(hour,minute,second,sec100);
            res:=(hour=vsi);
          end;
      'I':res:=(vsi>=numbatchfiles);
      'J':res:=(vsi>=numubatchfiles);
      'N':res:=(nodenum=vsi);
      'P':res:=(u.filepoints>=vsi);
      'R':res:=(tacch(upcase(vs[1])) in u.ac);
      'S':res:=(u.sl>=vsi);
      'T':res:=(trunc(nsl) div 60>=vsi);
      'U':res:=(un=vsi);
      'V':begin
            case upcase(vs[1]) of
              'V':begin
                    assign(valf,systat^.datapath+'AUTOVAL.DAT');
                    SetFileAccess(ReadOnly,DenyNone);
                    reset(valf); read(valf,val); read(valf,val2);
                    close(valf);
                    res:=((u.sl<>val.sl) or (u.dsl<>val.dsl) or
                    ((val.sl=val2.sl) and (val.dsl=val2.dsl)));
                  end;
              'P':begin
                    figurepcr(badratio,want,have,need);
                    res:=(not badratio);
                  end;
              'F':res:=fastlogon;
            end;
          end;
      'X':case upcase(vs[1]) of
            'A':res:=(ansi in thisuser.ac);
            'L':res:=(spd='KB');
            'T':res:=((not (ansi in thisuser.ac)) and (not (avatar in thisuser.ac)));
            'V':res:=(avatar in thisuser.ac);
          end;
      'W':begin
            getdate(year,month,day,dayofweek);
            res:=(dayofweek=ord(s[1])-48);
          end;
      'Y':res:=(trunc(timer) div 60>=vsi);
    end;
    if (not boolstate) then res:=not res;
    argstat:=res;
  end;

begin
  s:=allcaps(s);
  i:=0;
  while (i<length(s)) do begin
    inc(i);
    c:=s[i];
    if (c in ['A'..'Z']) and (i<>length(s)) then begin
      getrest;
      b:=argstat(s1);
      delete(s,p1,length(s1));
      if (b) then s2:='^' else s2:='%';
      insert(s2,s,p1);
      dec(i,length(s1)-1);
    end;
  end;
  s:='('+s+')';
  while (pos('&',s)<>0) do delete(s,pos('&',s),1);
  while (pos('^^',s)<>0) do delete(s,pos('^^',s),1);
  while (pos('(',s)<>0) do begin
    i:=1;
    while ((s[i]<>')') and (i<=length(s))) do begin
      if (s[i]='(') then p1:=i;
      inc(i);
    end;
    p2:=i;
    s1:=copy(s,p1+1,(p2-p1)-1);
    while (pos('|',s1)<>0) do begin
      i:=pos('|',s1);
      c1:=s1[i-1]; c2:=s1[i+1];
      s2:='%';
      if ((c1 in ['%','^']) and (c2 in ['%','^'])) then begin
        if ((c1='^') or (c2='^')) then s2:='^';
        delete(s1,i-1,3);
        insert(s2,s1,i-1);
      end else
        delete(s1,i,1);
    end;
    while(pos('%%',s1)<>0) do delete(s1,pos('%%',s1),1);   {leave only "%"}
    while(pos('^^',s1)<>0) do delete(s1,pos('^^',s1),1);   {leave only "^"}
    while(pos('%^',s1)<>0) do delete(s1,pos('%^',s1)+1,1); {leave only "%"}
    while(pos('^%',s1)<>0) do delete(s1,pos('^%',s1),1);   {leave only "%"}
    delete(s,p1,(p2-p1)+1);
    insert(s1,s,p1);
  end;
  aacs1:=(not (pos('%',s)<>0));
end;

function aacs(s:string):boolean;
begin
  aacs:=aacs1(thisuser,usernum,s);
end;

procedure loadurec(var u:userrec; i:integer);
var ufo:boolean;
begin
  ufo:=(filerec(uf).mode<>fmclosed);
  if (not ufo) then begin
    setfileaccess(ReadOnly,DenyNone);
    reset(uf);
  end;
  if (i<>usernum) then begin
    seek(uf,i);
    read(uf,u);
  end else
    u:=thisuser;
  if (not ufo) then close(uf);
end;

procedure saveurec(u:userrec; i:integer);
var ufo:boolean;
begin
  ufo:=(filerec(uf).mode<>fmclosed);
  if (not ufo) then begin
    SetFileAccess(ReadWrite,DenyNone);
    reset(uf);
  end;
  seek(uf,i); write(uf,u);
  if (i=usernum) then thisuser:=u;
  if (not ufo) then close(uf);
end;

end.
