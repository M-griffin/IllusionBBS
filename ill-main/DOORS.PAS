(*****************************************************************************)
(* Illusion BBS - Online door routines                                       *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit doors;

interface

uses
  crt, dos,
  execbat, myio, common;

function process_door(s:astr):astr;
procedure write_door32_sys;
procedure write_dorinfo1_def(rname:boolean);     { RBBS-PC DORINFO1.DEF }
procedure write_door_sys(rname:boolean);         { GAP DOOR.SYS }
procedure write_chain_txt;                       { WWIV CHAIN.TXT }
procedure write_callinfo_bbs(rname:boolean);     { Wildcat! CALLINFO.BBS }
procedure write_sfdoors_dat(rname:boolean);      { Spitfire SFDOORS.DAT }
procedure dodoorfunc(kind:char; cline:astr);
procedure write_doorfile_sr;                     { SRDoor DOORFILE.SR }

implementation

function timestr:astr;
var i:astr;
begin
  i:=cstrr(nsl/60,10);
  timestr:=i;
end;

function process_door(s:astr):astr;
var i:integer;
    sda,namm:astr;
    sdoor:string[255];
begin
  namm:=caps(thisuser.realname);
  sdoor:='';
  for i:=1 to length(s) do begin
    if copy(s,i,1)='%' then begin
      sda:='';
      case upcase(s[i+1]) of
        'B':if spd<>'KB' then sda:=spd else sda:='0';
        'D':begin
              loaduboard(fileboard);
              sda:=memuboard.dlpath;
            end;
        'F':sda:=copy(namm,1,pos(' ',namm)-1);
        'G':if okansi then sda:='1' else sda:='0';
        'I':begin
              loaduboard(fileboard);
              sda:=systat^.datapath;
              if (copy(sda,length(sda),1)<>'\') then sda:=sda+'\';
              sda:=sda+memuboard.filename+'.DIR';
            end;
        'L':begin
              if (pos(' ',namm)=0) then sda:=namm else
                sda:=copy(namm,pos(' ',namm)+1,length(namm));
            end;
        'N':sda:=caps(thisuser.name);
        'O':sda:=cstr(nodenum);
        'T':sda:=timestr;
        'R':sda:=(copy(nam,pos('#',nam)+1,length(nam)));
      end;
      sdoor:=sdoor+sda;
      inc(i);
    end
    else sdoor:=sdoor+copy(s,i,1);
  end;
  process_door:=sdoor;
end;

procedure write_dorinfo1_def(rname:boolean);  (* RBBS-PC's DORINFO1.DEF *)
var fp:text;
    first,last:astr;
    s:astr;
begin
  assign(fp,modemr^.doorpath+'dorinfo1.def');
  setfileaccess(readwrite,denynone);
  rewrite(fp);
  writeln(fp,stripcolor(systat^.bbsname));
  first:=copy(systat^.sysopname,1,pos(' ',systat^.sysopname)-1);
  last:=copy(systat^.sysopname,length(first)+2,length(systat^.sysopname));
  writeln(fp,first);
  writeln(fp,last);
  if spd='KB' then writeln(fp,'COM0') else writeln(fp,'COM'+cstr(modemr^.comport));
  if spd='KB' then s:='0' else s:=spd;
  writeln(fp,s+' BAUD,N,8,1');
  writeln(fp,'0');
  if (rname) then begin
    if pos(' ',thisuser.realname)=0 then begin
      first:=thisuser.realname;
      last:='';
    end else begin
      first:=copy(thisuser.realname,1,pos(' ',thisuser.realname)-1);
      last:=copy(thisuser.realname,length(first)+2,length(thisuser.realname));
    end;
    first:=allcaps(first);
    last:=allcaps(last);
  end else begin
    if pos(' ',thisuser.name)=0 then begin
      first:=thisuser.name;
      last:='';
    end else begin
      first:=copy(thisuser.name,1,pos(' ',thisuser.name)-1);
      last:=copy(thisuser.name,length(first)+2,length(thisuser.name));
    end;
  end;
  writeln(fp,caps(first));
  writeln(fp,caps(last));
  writeln(fp,thisuser.citystate);
  if (ansi in thisuser.ac) then writeln(fp,'1') else writeln(fp,'0');
  writeln(fp,thisuser.sl);
  s:=timestr;
  if length(s)>3 then s:='999';
  writeln(fp,s);
  writeln(fp,'0');
  close(fp);
end;


procedure write_door32_sys;
var fp:text;
    first,last:astr;
    s:astr;
begin

  assign(fp,modemr^.doorpath+'door32.sys');
  setfileaccess(readwrite,denynone);
  rewrite(fp);

  if (localioonly) then begin writeln(fp,'0');
  end else writeln(fp,'2');
  if (localioonly) then begin writeln(fp,'2');
  end else writeln(fp,door32);

  if spd='KB' then s:='0' else s:=spd;
  writeln(fp,s);
  writeln(fp,'Illusion BBS 3.0');
  writeln(fp,cstr(usernum));                            { record num }  
  writeln(fp,thisuser.realname);  
  writeln(fp,thisuser.name);  
  writeln(fp,thisuser.sl);
  writeln(fp,cstr(trunc(nsl) div 60));
  writeln(fp,'1');
  writeln(fp,cstr(nodenum));
  writeln(fp,s);
  writeln(fp,'0');
  close(fp);
end;


procedure write_door_sys(rname:boolean);    (* GAP's DOOR.SYS *)
var fp:text;
    i:integer;
    s:astr;
begin
  assign(fp,modemr^.doorpath+'door.sys');
  setfileaccess(readwrite,denynone);
  rewrite(fp);
  if spd<>'KB' then                                     { com port }
    writeln(fp,'COM'+cstr(modemr^.comport)+':')
  else
    writeln(fp,'COM0:');
  if spd<>'KB' then                                     { baud rate }
    writeln(fp,spd)
  else
    writeln(fp,cstr(modemr^.waitbaud));
  writeln(fp,'8');                                      { parity }
  writeln(fp,cstr(nodenum));                            { node number }
  writeln(fp,cstr(modemr^.lockspeed));                   { DTE rate }
  if wantout then writeln(fp,'Y') else writeln(fp,'N'); { scrn display }
  writeln(fp,'Y');                                      { printer toggle }
  if sysop then writeln(fp,'Y') else writeln(fp,'N');   { page bell }
  if alert in thisuser.ac then                          { caller alarm }
    writeln(fp,'Y') else writeln(fp,'N');
  if (rname) then writeln(fp,thisuser.realname)         { user full name }
    else writeln(fp,thisuser.name);
  writeln(fp,thisuser.citystate);                       { calling from }
  writeln(fp,copy(thisuser.ph,1,3)+' '+                 { home phone }
             copy(thisuser.ph,5,8));
  writeln(fp,copy(thisuser.ph,1,3)+' '+                 { work/data phone }
             copy(thisuser.ph,5,8));
  writeln(fp,thisuser.pw);                              { password }
  writeln(fp,cstr(thisuser.sl));                        { sl }
  writeln(fp,cstr(thisuser.loggedon));                  { total times on }
  writeln(fp,thisuser.laston);                          { last date called }
  writeln(fp,cstrl(trunc(nsl)));                        { seconds remaining }
  writeln(fp,cstr(trunc(nsl) div 60));                  { minutes remaining }
  if okansi then writeln(fp,'GR') else writeln(fp,'NG');{ graphics mode }
  writeln(fp,cstr(thisuser.pagelen));                   { page length }
  if novice in thisuser.ac then writeln(fp,'N')         { user mode }
    else writeln(fp,'Y');
  s:='';
  for i:=1 to 7 do
    if chr(i+64) in thisuser.ar then s:=s+cstr(i);
  writeln(fp,s);                                        { conferences/forums }
  writeln(fp,'7');                                      { conf exited from }
  writeln(fp,'12/31/99');                               { expire date }
  writeln(fp,cstr(usernum));                            { record num }
  writeln(fp,'X');                                      { default protocol }
  writeln(fp,cstr(thisuser.uploads));                   { total uls }
  writeln(fp,cstr(thisuser.downloads));                 { total dls }
  writeln(fp,cstr(trunc(thisuser.dk)));                 { daily dl k total }
  writeln(fp,'999999');                                 { daily dl max k }
  writeln(fp,thisuser.bday);                            { birthday }
  writeln(fp,copy(systat^.datapath,1,length(systat^.datapath)-1)); {path to main}
  writeln(fp,copy(systat^.datapath,1,length(systat^.datapath)-1)); {path to gen}
  writeln(fp,systat^.sysopname);                         { sysop name }
  writeln(fp,systat^.sysopname);                         { sysop alias }
  writeln(fp,'00:00');                                  { event time }
  writeln(fp,'Y');                                      { error correcting }
  writeln(fp,'N');                                      { ansi + ng }
  writeln(fp,'Y');                                      { record locking }
  writeln(fp,'7');                                      { default color }
  writeln(fp,'10');                                     { time credits }
  writeln(fp,newdate);                                  { last file newscan }
  writeln(fp,copy(time,1,5));                           { time of this call }
  writeln(fp,'00:00');                                  { time of last call }
  writeln(fp,'2000');                                   { max daily files avail}
  writeln(fp,'1');                                      { dls so far }
  writeln(fp,cstr(thisuser.uk));                        { total k ul'd }
  writeln(fp,cstr(thisuser.dk));                        { total k dl'd }
  writeln(fp,thisuser.usernote);                        { user comment }
  writeln(fp,'1');                                      { doors opened }
  writeln(fp,'100');                                    { messages left }
  close(fp);
end;

procedure write_chain_txt;
var fp:text;
    ton,tused:real;
    s:string[20];

  function bo(b:boolean):astr;
  begin
    if b then bo:='1' else bo:='0';
  end;

begin
  assign(fp,modemr^.doorpath+'chain.txt');
  setfileaccess(readwrite,denynone);
  rewrite(fp);
  with thisuser do begin
    writeln(fp,usernum);                      { user number        }
    writeln(fp,name);                         { user name          }
    writeln(fp,realname);                     { real name          }
    writeln(fp,'');                           { "call sign" ?      }
    writeln(fp,ageuser(bday));                { age                }
    writeln(fp,sex);                          { sex                }
    str(credit:7,s); writeln(fp,s+'.00');     { credit             }
    writeln(fp,laston);                       { laston date        }
    writeln(fp,linelen);                      { # screen columns   }
    writeln(fp,pagelen);                      { # screen rows      }
    writeln(fp,sl);                           { SL                 }
    writeln(fp,bo(so));                       { is he a SysOp?     }
    writeln(fp,bo(cso));                      { is he a CoSysOp?   }
    writeln(fp,bo(okansi));                   { is graphics on?    }
    writeln(fp,bo(incom));                    { is remote?         }
    str(nsl:10:2,s); writeln(fp,s);           { time left (sec)    }
    writeln(fp,systat^.datapath);              { data path          }
    writeln(fp,systat^.datapath);              { data path          }
    writeln(fp,date+'.'+cstr(nodenum));       { SysOp log filespec }
    s:=spd; if (s='KB') then s:='0';          { baud rate          }
    writeln(fp,s);
    writeln(fp,modemr^.comport);               { COM port           }
    writeln(fp,stripcolor(systat^.bbsname));   { system name        }
    writeln(fp,systat^.sysopname);             { SysOp's name       }
    with timeon do begin
      ton:=hour*3600.0+min*60.0+sec;
      tused:=timer-ton;
      if (tused<0) then tused:=tused+3600.0*24.0;
    end;
    writeln(fp,trunc(ton));                   { secs on f/midnight }
    writeln(fp,trunc(tused));                 { time used (sec)    }
    writeln(fp,uk);                           { upload K           }
    writeln(fp,uploads);                      { uploads            }
    writeln(fp,dk);                           { download K         }
    writeln(fp,downloads);                    { downloads          }
    writeln(fp,'8N1');                        { COM parameters     }
    writeln(fp,cstr(modemr^.lockspeed));       { com port baud rate }
    writeln(fp,'0');                          { wwivnet node num }
  end;
  close(fp);
end;

procedure write_callinfo_bbs(rname:boolean);
var fp:text;
    s:astr;

  function bo(b:boolean):astr;
  begin
    if b then bo:='1' else bo:='0';
  end;

begin
  assign(fp,modemr^.doorpath+'callinfo.bbs');
  setfileaccess(readwrite,denynone);
  rewrite(fp);
  with thisuser do begin
    if (rname) then writeln(fp,allcaps(thisuser.realname)) else writeln(fp,allcaps(thisuser.name));
    if spd='300' then s:='1' else
      if spd='1200' then s:='2' else
      if spd='2400' then s:='0' else
      if spd='9600' then s:='3' else
      if spd='KB' then s:='5' else
      s:='4';
    writeln(fp,s);
    writeln(fp,allcaps(thisuser.citystate));
    writeln(fp,cstr(thisuser.sl));
    writeln(fp,timestr);
    if okansi then writeln(fp,'COLOR') else writeln(fp,'MONO');
    writeln(fp,thisuser.pw);
    writeln(fp,cstr(usernum));
    writeln(fp,'0');
    writeln(fp,copy(time,1,5));
    writeln(fp,copy(time,1,5)+' '+date);
    writeln(fp,'A');
    writeln(fp,'0');
    writeln(fp,'999999');
    writeln(fp,'0');
    writeln(fp,'999999');
    writeln(fp,thisuser.ph);
    writeln(fp,thisuser.laston+' 00:00');
    if (novice in thisuser.ac) then writeln(fp,'NOVICE') else writeln(fp,'EXPERT');
    writeln(fp,'All');
    writeln(fp,'01/01/80');
    writeln(fp,cstr(thisuser.loggedon));
    writeln(fp,cstr(thisuser.pagelen));
    writeln(fp,'0');
    writeln(fp,cstr(thisuser.uploads));
    writeln(fp,cstr(thisuser.downloads));
    writeln(fp,'8  { Databits }');
    if ((incom) or (outcom)) then writeln(fp,'REMOTE') else writeln(fp,'LOCAL');
    if ((incom) or (outcom)) then writeln(fp,'COM'+cstr(modemr^.comport)) else writeln(fp,'COM0');
    writeln(fp,thisuser.bday);
    if spd='KB' then writeln(fp,cstr(modemr^.waitbaud)) else writeln(fp,spd);
    if ((incom) or (outcom)) then writeln(fp,'TRUE') else writeln(fp,'FALSE');
    writeln(fp,'Normal Connection');
    writeln(fp,'12/31/99 23:59');
    writeln(fp,'1');
    writeln(fp,'1');
  end;
  close(fp);
end;

procedure write_sfdoors_dat(rname:boolean);   { Spitfire SFDOORS.DAT }
var fp:text;
    s:astr;
begin
  assign(fp,modemr^.doorpath+'SFDOORS.DAT');
  setfileaccess(readwrite,denynone);
  rewrite(fp);
  writeln(fp,cstr(usernum));
  if (rname) then writeln(fp,allcaps(thisuser.realname)) else writeln(fp,allcaps(thisuser.name));
  writeln(fp,thisuser.pw);
  if (rname) then begin
    if (pos(' ',thisuser.realname)=0) then s:=thisuser.realname
    else s:=copy(thisuser.realname,1,pos(' ',thisuser.realname)-1);
  end else begin
    if (pos(' ',thisuser.name)=0) then s:=thisuser.name
    else s:=copy(thisuser.name,1,pos(' ',thisuser.name)-1);
  end;
  writeln(fp,s);
  if (spd='KB') then writeln(fp,'0') else writeln(fp,cstr(modemr^.comport));
  writeln(fp,timestr);
  writeln(fp,'0');   { seconds since midnight }
  writeln(fp,start_dir);
  if okansi then writeln(fp,'TRUE') else writeln(fp,'FALSE');
  writeln(fp,cstr(thisuser.sl));
  writeln(fp,cstr(thisuser.uploads));
  writeln(fp,cstr(thisuser.downloads));
  writeln(fp,cstr(systat^.timeallow[thisuser.sl]));
  writeln(fp,'0');   { time on (seconds) }
  writeln(fp,'0');   { extra time (seconds) }
  writeln(fp,'FALSE');
  writeln(fp,'FALSE');
  writeln(fp,'FALSE');
  if (spd='KB') then writeln(fp,'0') else writeln(fp,spd);
  close(fp);
end;

procedure write_doorfile_sr;
var fp:text;
    s:string[20];
begin
  assign(fp,modemr^.doorpath+'DOORFILE.SR');
  setfileaccess(readwrite,denynone);
  rewrite(fp);
  writeln(fp,allcaps(thisuser.name));
  writeln(fp,'-1');
  writeln(fp,'-1');
  writeln(fp,cstr(thisuser.pagelen));
  s:=spd; if (s='KB') then s:='2400';
  writeln(fp,s);
  if spd='KB' then writeln(fp,'0') else writeln(fp,modemr^.comport);
  s:=timestr;
  if length(s)>3 then s:='999';
  writeln(fp,s);
  writeln(fp,thisuser.realname);
  close(fp);
end;

procedure dodoorfunc(kind:char; cline:astr);
var doorstart,doorend,doortime:datetimerec;
    s,cline2:astr;
    retcode,savsl,savdsl:integer;
    realname:boolean;
begin
  realname:=FALSE;
  if ((sqoutsp(cline)='') and (incom)) then begin
    print('This command is inoperative!');
    if (cso) then print('(An MString of "" will shell to DOS LOCALLY!)');
    exit;
  end;

  if ((realsl<>-1) and (realdsl<>-1)) then begin
    savsl:=thisuser.sl; savdsl:=thisuser.dsl;
    thisuser.sl:=realsl; thisuser.dsl:=realdsl;
    saveuf;
  end;

  cline2:=cline;
  if copy(allcaps(cline2),1,2)='R;' then begin
    realname:=TRUE;
    cline2:=copy(cline2,3,length(cline2)-2);
  end;
  chdir(start_dir);
  s:=process_door(cline2);
  case kind of
    'C':begin
          commandline('Outputting CHAIN.TXT (WWIV) ...');
          write_chain_txt;
        end;
    'D':begin
          commandline('Outputting DORINFO1.DEF (RBBS-PC) ...');
          write_dorinfo1_def(realname);
        end;
    'G':begin
          commandline('Outputting DOOR.SYS (GAP) ...');
          write_door_sys(realname);
        end;
    'S':begin
          commandline('Outputting SFDOORS.DAT (Spitfire) ...');
          write_sfdoors_dat(realname);
        end;
    'W':begin
          commandline('Outputting CALLINFO.BBS (Wildcat!) ...');
          write_callinfo_bbs(realname);
        end;
    'R':begin
          commandline ('Outputting DOORFILE.SR (SRDoor) ...');
          write_doorfile_sr;
        end;
    'Z':begin
          commandline ('Outputting DOOR32.SYS (Door32) ...');
          write_door32_sys;
        end;

    end;
  commandline('Now running "'+s+'"');
  sysoplog('>> '+date+' '+time+'- Door "'+s+'"');
  close(sysopf);

  getdatetime(doorstart);
  shel1; shelldos(FALSE,s,retcode); shel2;
  getdatetime(doorend);
  timediff(doortime,doorstart,doorend);

  chdir(start_dir);
  append(sysopf);

  if ((realsl<>-1) and (realdsl<>-1)) then begin
    thisuser.sl:=savsl; thisuser.dsl:=savdsl;
    SetFileAccess(ReadOnly,DenyNone);
    reset(uf); seek(uf,usernum); read(uf,thisuser); close(uf);
  end;

  if (not localioonly) then com_flush_rx;
  getdatetime(tim);

  sysoplog('>> '+date+' '+time+'- Returned (spent '+longtim(doortime)+')');
  cursoron(TRUE);
  commandlinecount:=0;
  topscr;
end;

end.
