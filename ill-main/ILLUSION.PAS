(****************************************************************************)
(*>                                                                        <*)
(*>     Illusion Bulletin Board System                                     <*)
(*>     Copyright 1992-98 by Kyle Oppenheim and Billy Ma                   <*)
(*>     All rights reserved.                                               <*)
(*>                                                                        <*)
(****************************************************************************)

{$M 65520,65536,205520}
{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

{$DEFINE OS2}

Program Illusion;

Uses
  Crt,      Dos,
  {$IFNDEF OS2} overlay, {$ENDIF}

  OvrStart, InitP,    FosCom2,  TeleC,

  Cuser,    Doors,    MyIO,
  NewUsers, CRC32,    Newfile2, Newfile,

  Misc1,    Misc2,    Misc3,    InfoForm, MiscX,
  Menus,    Menus2,   Menus3,   Logon1,   Logon2,

  WfcMenu,  TimeJunk, TpAnsii,  PDmenu,   BBSlist,  Execbat,
  Common,   Common1,  Common2,  Common3,  ChatStuf, Mtask,

  Iplx,     Exec;
  

{ O MsgF      } {$O BBSlist   } {$O ChatStuf  } {$O CRC32     } {$O cUser     }
{$O Doors     } {$O ExecBat   } {$O InfoForm  } {$O InitP     }
{$O Logon1    } {$O Logon2    } {$O Menus2    } {$O Menus3    } {$O Misc1     }
{$O Misc2     } {$O Misc3     } {$O MiscX     } {$O MModem    } {$O mmSound   }
{$O MyIO      } {$O NewUsers  } {$O pdMenu    } {$O Telec     } {$O TimeJunk  }
{$O WFCmenu   } {$O AutoMsg   }

{$O Common1   } { $O Common2  } {$O Common3   }

{$O Sysop2    } {$O Sysop21   } {$O Sysop2a   } {$O Sysop2b   } {$O Sysop2c   }
{$O Sysop2d   } {$O Sysop2e   } {$O Sysop2f   } {$O Sysop2g   } {$O Sysop2h   }
{$O Sysop2i   } {$O Sysop2j   } {$O Sysop2k   } {$O Sysop2l   } {$O Sysop2m   }
{$O Sysop2n   } {$O Sysop2o   } {$O Sysop2p   } {$O Sysop2r   } {$O Sysop2s   }
{$O Sysop3    } {$O Sysop4    } {$O Sysop6    } {$O Sysop7    } {$O Sysop7m   }
{$O Sysop8    } {$O Sysop9    } {$O Sysop10   } {$O Sysop11   }

{$O Mail0     } {$O Mail1     } {$O Mail2     } {$O Mail3     } {$O Mail4     }
{$O Mail5     } {$O Mail6     } {$O Mail7     } {$O MailFSE   } {$O MailLine  }

{$O MkMsgABS  } {$O MkMsgJAM  } {$O MkMsgEZY  } {$O MkMsgSQU  } {$O MkMsgFID  }
{$O MkMsgHUD  } {$O MkOffAbs  } {$O MkOffQWK  } {$O MkString  } {$O MkMisc    }
{$O MkFile    } {$O MkDos     } {$O MkGlobT   } {$O MkFFile   }

{$O IplX      } {$O StrProc   }

{$O NewFile   } {$O NewFile2  }
{$O FMenu     } {$O FMenu2    }
{$O FilePEd   ] {$O FilePEd2  }


var exitsave  : Pointer;
    execfirst : Boolean;
    NewMenuCmd: String;

Procedure ErrorHandle;
var t:text; f:file;
    S:String[80];
    VidSeg:Word;
    X,Y,j:Integer;
    C:Char;
    dirinfo:searchrec;
Begin
  ExitProc:=ExitSave;
  If (ErrorAddr<>Nil) then Begin
    chdir(start_dir);
    if (textrec(sysopf).mode=fmoutput) then
    begin
      writeln(sysopf,'|R*>>|Y Runtime error '+cstr(exitcode)+
              ' at '+date+' '+time+'|R <<*|Y'+
              ' (Check ERROR.LOG in BBS dir)');
      flush(sysopf); close(sysopf);
    end;
    if (textrec(trapfile).mode=fmoutput) then begin
      writeln(trapfile,'*>> Runtime error '+cstr(exitcode)+' at '+date+' '+
              time+' <<*');
      flush(trapfile); close(trapfile);
    end;

    assign(t,'ERROR.LOG');
    {$I-} append(t); {$I+}
    if (ioresult<>0) then begin
      rewrite(t);
      append(t);
      write(t,'Ú'); for j:=1 to 77 do write (t,'Ä'); writeln(t,'¿');
      writeln(t,'³ Critical error log - Contains screen images at the instant of an error.     ³');
      writeln(t,'³ The "±" character shows the cursor position at time of error.               ³');
      writeln(t,'³ Note: You may delete this file with no harm to your system. The following   ³');
      writeln(t,'³ information MAY be important.                                               ³');
      write(t,'À'); for j:=1 to 77 do write (t,'Ä'); writeln (t,'Ù');
      writeln(t,'');
    end;
    writeln(t,'RT #'+cstr(exitcode)+' at '+date+' '+time+'  BBS-Ver: '+ver);
    if (useron) then begin
      if (spd<>'KB') then s:='at '+realspd+' baud' else s:='Locally';
      writeln(t,'User "'+allcaps(thisuser.name)+' #'+cstr(usernum)+
              '" was on at '+s+' on node '+cstr(nodenum));
    end;
    writeln(t,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ[ Screen Image ]ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
    if (mem[$0000:$0449]=7) then vidseg:=$B000 else vidseg:=$B800;
    for y:=1 to linemode do begin
      s:='';
      for x:=1 to 80 do begin
        c:=chr(mem[vidseg:(160*(y-1)+2*(x-1))]);
        if (c=#0) then c:=#32;
        if ((x=wherex) and (y=wherey)) then c:=#177;
        if ((x<>80) or ((x=80) and (c<>#32))) then s:=s+c;
      end;
      writeln(t,s);
    end;
    writeln(t,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
    close(t);

    assign(f,'CRITICAL.ERR');
    rewrite(f); close(f); setfattr(f,dos.hidden);

    sprint('|R*>>|Y System error occured at '+date+' '+time+'|R <<*');
    term_ready(TRUE); remove_port;
    if linemode<>25 then set25lines; cursoron(TRUE);

{   thisnode.active:=FALSE;
    thisnode.username:='';
    thisnode.unum:=0;
    thisnode.whereuser:='Node Offline';
    savenode; }

    if (exiterrors<>-1) then halt(exiterrors) else halt(254);
  end;
end;

Procedure MenuExec;
Var Dt    : LDateTimeRec;
    Cmd   : ^String;
    I     : Integer;
    Aa,Abort,Next,Done:Boolean;
Begin
  new(cmd);
  If (ExecFirst) then begin
    execfirst:=false;
    Cmd^:=NewMenuCmd;
    NewMenuCmd:='';
  End Else MainMenuHandle(Cmd^);

  if ((copy(cmd^,1,2)='\\') and ((thisuser.sl=255) or (so))) then begin
    domenucommand(done,copy(cmd^,3,length(cmd^)-2),newmenucmd);
    if (newmenucmd<>'') then cmd^:=newmenucmd else cmd^:='';
  end;

  If (Cmd^='|') then
    fullscr_verline
  else
  if (cmd^<>'') then begin
    newmenucmd:='';
    repeat domenuexec(cmd^,newmenucmd) until (newmenucmd='');
  end;
  dispose(cmd);
end;




{ -- MAIN -- }

VAR
  I,RCode         : Integer;  { Temp. variables   }
  NeedToHangup    : Boolean;  { Hangup carryover  }
  Systatf         : File of SystatRec;

BEGIN { MAIN }

  { - Install error handler }

  exitsave:=exitproc;
  exitproc:=@errorhandle;

  { - Don't allow Ctrl-C break }

  SetCBreak(FALSE);

  { - Startup }

  checksnow:=TRUE;
  directvideo:=FALSE;
  writeln('Illusion BBS System  Version '+ver+'  by Mercyful Fate');

  useron:=FALSE;
  usernum:=0;
  

  new(systat);
  
  getdir(0,start_dir);
  assign(systatf,start_dir+'\ILLUSION.CFG');
  SetFileAccess(ReadOnly,DenyNone);
  {$I-} reset(systatf); {$I+}
  if (ioresult<>0) then
  begin
    writeln;
    writeln('Unable to open the ILLUSION.CFG data file. This file is');
    writeln('REQUIRED to even load Illusion.');
    writeln('Check the following:');
    writeln;
    writeln('ú You "initialized" Illusion with the INIT program before');
    writeln('  running it.');
    writeln('ú ILLUSION.CFG is not missing or corrupt. (If it is, recreate');
    writeln('  it with the INIT program.)');
    writeln;
    if (exiterrors<>-1) then halt(exiterrors) else halt(254);
  end else
  begin
    {$I-} read(systatf,systat^); {$I+}
    close(systatf);
  end;


  { - Initialize }

  init;

  { - Do msg packing / file sorting }

  if (packbasesonly) or (filesortonly) then begin
    wfcinit;
    if (packbasesonly) then begin
{     doshowpackbases;   {-M-}
      sprint('|YMessage base packing has not been implemented.');
    end;
    if (filesortonly) then begin
      sort;
      sprint('|YFile bases have been sorted.');
    end;
    nl;
    cursoron(TRUE);
    thisnode.active:=FALSE;
    thisnode.username:='';
    thisnode.unum:=0;
    thisnode.whereuser:='Node Offline';
    savenode;
    halt(0);
  end;

  { - Set variables }

  clearwaves;
  needtohangup:=FALSE;

  { - Start loop until quit to DOS }

  repeat
    write_msg:=FALSE;
    sysopon:=not systat^.localsec;
    wantout:=not systat^.localscreensec;
    checksnow:=systat^.cgasnow;
    setsnow;

    wfcmenus(needtohangup);
    needtohangup:=FALSE;

    useron:=FALSE; usernum:=0;
    if (not doneday) then begin
      if (getuser) then newuser;
      if (not hangup) then begin
        macok:=TRUE;
        if (not hangup) then logon;
        if (not hangup) then begin
          with thisuser do begin
            newdate:=laston;
            if (not mbaseac(lastmsg)) then lastmsg:=1;
            if (not fbaseac(lastfil)) then lastfil:=1;
            board:=lastmsg;
            boardreal:=RealMsgIdx(board);
            fileboard:=lastfil;
          end;
          batchtime:=0.0; numbatchfiles:=0; numubatchfiles:=0; hiubatchv:=0;
          newcomptables;

          menustackptr:=0; for i:=1 to 8 do menustack[i]:='';

          if thisuser.userstartmenu<>'' then
          last_menu:=thisuser.userstartmenu+'.MNU' else
          last_menu:=systat^.allstartmenu+'.MNU';

          if (not exist(systat^.menupath+last_menu)) then begin
            sysoplog('"'+systat^.menupath+last_menu+'" is MISSING.  Loaded "MAIN.MNU" instead.');
            last_menu:='MAIN.MNU';
          end;
          curmenu:=systat^.menupath+last_menu; readin;

          if (novice in thisuser.ac) then chelplevel:=2 else chelplevel:=1;
        end;

        newmenucmd:=''; i:=1;
        while ((i<=noc) and (newmenucmd='')) do begin
          if (cmdr[i].ckeys='FIRSTCMD') then
            if (aacs(cmdr[i].acs)) then newmenucmd:='FIRSTCMD';
          inc(i);
        end;
        execfirst:=(newmenucmd='FIRSTCMD');

        { ** MAIN BBS LOOP ** }

        while (not hangup) do menuexec;

        { **               ** }

      end;

      if (quitafterdone) then begin
        elevel:=exitnormal; hangup:=TRUE; doneday:=TRUE; needtohangup:=TRUE;
      end;
      logoff;

      if (textrec(sysopf1).mode=fmoutput) then begin
        {$I-} close(sysopf1); {$I+}
        if (ioresult<>0) then writeln('Errors closing SLOGxxxx.'+cstr(nodenum));
      end;

      if (not localioonly) and (com_carrier) and (not doneday) then
        if (spd<>'KB') then needtohangup:=TRUE;
      if (enddayf) then endday;
      enddayf:=FALSE;
    end;
  until (doneday);

  { - Shutdown }

  if (needtohangup) then hangupphone;
  reset(sysopf); close(sysopf);
  term_ready(TRUE); remove_port;
  close(fstringf);
  dispose(macros); dispose(strglobal); dispose(strbuff); dispose(outputbuff);
  clearwaves;

  if (existdir(modemr^.temppath+'ARCHIVE\')) then purgedir(modemr^.temppath+'ARCHIVE\');
  if (existdir(modemr^.temppath+'UPLOAD\')) then purgedir(modemr^.temppath+'UPLOAD\');
  if (existdir(modemr^.temppath+'QWK\')) then purgedir(modemr^.temppath+'QWK\');
  if (existdir(modemr^.temppath+'ARCHIVE\')) then rmdir(modemr^.temppath+'ARCHIVE');
  if (existdir(modemr^.temppath+'UPLOAD\')) then rmdir(modemr^.temppath+'UPLOAD');
  if (existdir(modemr^.temppath+'QWK\')) then rmdir(modemr^.temppath+'QWK');
  if (existdir(modemr^.temppath)) then purgedir(modemr^.temppath);
  if (existdir(modemr^.temppath)) then rmdir(copy(modemr^.temppath,1,length(modemr^.temppath)-1));

  thisnode.active:=FALSE;
  thisnode.username:='';
  thisnode.unum:=0;
  thisnode.whereuser:='Node Offline';
  savenode;

  if (exist('BBSDONE.BAT')) and (systat^.sysbatexec) then shelldos(FALSE,'BBSDONE.BAT',rcode);

  window(1,1,80,linemode); tc(7); clrscr;
  if linemode<>25 then set25lines;
  writeln('Illusion BBS v'+ver+' exiting with errorlevel ',elevel,' at '+date+' '+time);
  writeln;
  halt(elevel);
end.
