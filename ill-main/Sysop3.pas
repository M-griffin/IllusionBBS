(*****************************************************************************)
(* Illusion BBS - SysOp routines  [3/11] (user editor)                       *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop3;

interface

uses
  crt, dos,
  common;

procedure restric_list;
procedure uedit1;
procedure autoval(var u:userrec; un:integer);
procedure showuserinfo(typ,usern:integer; user1:userrec);
procedure uedit(usern:integer);

implementation
     
uses infoform, miscx, cuser;

procedure uedit1;
begin
  uedit(usernum);
end;

procedure restric_list;
begin
  begin
    nl;
    sprint('|WRestrictions:');
    nl;
    lcmds(27,3,'LCan logon ONLY once/day','CCan''t page SysOp');
    lcmds(27,3,'VPosts marked unvalidated','FForce fast logon');
    lcmds(27,3,'ACan''t add to BBS list','*Can''t post/send anon.');
    lcmds(27,3,'PCan''t post at all','ECan''t send email');
    lcmds(27,3,'KCan''t vote','MAutomatic mail deletion');
    nl;
    sprint('|WSpecial:');
    nl;
    lcmds(27,3,'1No UL/DL ratio check','2No post/call ratio check');
    lcmds(27,3,'3No file points check','4Protection from deletion');
  end;
end;

function spflags(u:userrec):astr;
var r:uflags;
    s:astr;
begin
  s:='';
  for r:=rlogon to rmsg do
    if r in u.ac then
      s:=s+copy('LCVFA*PEKM',ord(r)+1,1)
    else s:=s+'-';
  s:=s+'/';
  for r:=fnodlratio to fnodeletion do
    if r in u.ac then
      s:=s+copy('1234',ord(r)-19,1)
    else s:=s+'-';
  spflags:=s;
end;

procedure autoval(var u:userrec; un:integer);
var c:char;
begin
  prt('Select auto-validation profile to use (A-Z): ');
  onek(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
  if (c in ['A'..'Z']) then begin
    autovalidate(c,u,un);
    print('User validated with profile '+c+'.');
    pausescr;
  end;
end;

procedure showuserinfo(typ,usern:integer; user1:userrec);
var ii:array[0..14] of astr;
    zz,i:integer;
    abort,next:boolean;
    stat,arlist,thispw,lockname:^string;

  function ed:string;
  begin
    case user1.edtype of 0:ed:='Choose'; 1:ed:='Line'; 2:ed:='FSE'; end;
  end;

  function em:string;
  begin
    if (rip in user1.ac) then em:='RIP' else
    if (ansi in user1.ac) then em:='ANSI' else
    if (avatar in user1.ac) then em:='AVATAR' else
    em:='TTY';
  end;

  procedure shi1(var i:integer);
  var c:char;
      r:uflags;
      a,b:integer;
  begin
    if user1.lockedout then lockname^:='|R'+user1.lockedfile+'.MSG' else lockname^:='|C(none)';
    if (aacs(systat^.seepw)) or ((spd='KB') and (so)) then thispw^:=user1.pw else thispw^:='|R(not displayed)';
    arlist^:='';
    for c:='A' to 'Z' do if c in user1.ar then arlist^:=arlist^+c else arlist^:=arlist^+'-';

    stat^:='';
    if (user1.deleted) then stat^:=stat^+'|RDeleted' else
    if (user1.trapactivity) and ((usern<>usernum) or (usernum=1)) then
    if (user1.trapseperate) then stat^:=stat^+'|RTrapping (separate)'
    else stat^:=stat^+'|RTrapping (common)'
    else if (user1.lockedout) then stat^:=stat^+'|RLocked out' else
    if (alert in user1.ac) then stat^:=stat^+'|RAlert!' else stat^:=stat^+'|CNormal';

    with user1 do
      case i of

  0:ii[0]:='|WUser Editor ['+cstr(usern)+'/'+cstr(filesize(uf)-1)+']';
  1:ii[1]:='A. User name : |C'+mln(name,28)      +' |wK. Status  : |C'+stat^;
  2:ii[2]:='B. Real name : |C'+mln(realname,28)  +' |wL. Security: |C'+cstr(sl);
  3:ii[3]:='C. Address   : |C'+mln(street,28)    +' |wM. D/L Sec.: |C'+cstr(dsl);
  4:ii[4]:='D. City/State: |C'+mln(citystate,28) +' |wN. AR: |C'+arlist^;
  5:ii[5]:='E. Zip code  : |C'+mln(zipcode,28)   +' |wO. AC: |C'+spflags(user1);
  6:ii[6]:='F. Occupation: |C'+mln(occupation,28)+' |wP. Sex/Age : |C'+sex+cstr(ageuser(bday))+' ('+bday+')';
  7:ii[7]:='G. Computer  : |C'+mln(computer,28)  +' |wR. Last/1st: |C'+laston+' ('+firston+')';
  8:ii[8]:='H. Reference : |C'+mln(wherebbs,28)  +' |wT. Phone # : |C'+ph;
  9:ii[9]:='I. SysOp note: |C'+mln(note,28)      +' |wV. Password: |C'+thispw^;
10:ii[10]:='J. User note : |C'+mln(usernote,28)  +' |wW. Credit  : |C'+cstr(credit);
11:ii[11]:='1. Call records- TC: |C'+mn(loggedon,7) +'|wTT: |C'+mln(cstrl(ttimeon),6)+
                          '|wCT: |C'+mn(ontoday,7)+'|wTL: |C'+mn(tltoday,6)+'|w TB: |C'+mn(timebank,6);
12:ii[12]:='2. Mail records- PP: |C'+mn(msgpost,7)+'|wES: |C'+mn(emailsent,6);
13:ii[13]:='3. File records- DL: |C'+mln(cstr(downloads)+'-'+cstrl(dk)+'k',17)+
                          '|wUL: |C'+mln(cstr(uploads)+'-'+cstrl(uk)+'k',17)+'|w FP: |C'+mn(filepoints,7);
14:ii[14]:='4. Pref records- HK: |C'+onoff(onekey in ac)+'    |wEX: |C'+onoff(not (novice in ac))+
                       '   |wPA: |C'+onoff(pause in ac)+'    |wED: |C'+mln(ed,7)+'|wEM: |C'+em;

      end;
    printacr(ii[i],abort,next);
    inc(i); if (i=11) or (i=1) then nl;
  end;

  procedure shi2(var i:integer);
  begin
    shi1(i);
  end;

begin
  new(stat); new(arlist); new(thispw); new(lockname);
  abort:=FALSE;
  i:=0;
  case typ of
    1:while (i<=14) and (not abort) do shi1(i);
    2:while (i<=5) and (not abort) do shi2(i);
  end;
  dispose(stat); dispose(arlist); dispose(thispw); dispose(lockname);
end;

procedure uedit(usern:integer);
type f_statusflagsrec=(fs_deleted,fs_trapping,fs_chatbuffer,
                       fs_lockedout,fs_alert,fs_slogging);
const autolist:boolean=TRUE;
      userinfotyp:byte=1;
      f_state:array[0..14] of boolean=
        (FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,
         FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE);
      f_gentext:string[30]='';
      f_acs:string[50]='';
      f_sl1:word=0; f_sl2:word=255;
      f_dsl1:word=0; f_dsl2:word=255;
      f_ar:set of acrq=[];
      f_ac:set of uflags=[];
      f_status:set of f_statusflagsrec=[];
      f_laston1:word=0; f_laston2:word=65535;
      f_firston1:word=0; f_firston2:word=65535;
      f_numcalls1:word=0; f_numcalls2:word=65535;
      f_age1:word=0; f_age2:word=65535;
      f_gender:char='M';
      f_postratio1:word=0; f_postratio2:word=65535;
      f_dlkratio1:word=0; f_dlkratio2:word=65535;
      f_dlratio1:word=0; f_dlratio2:word=65535;
var user,user1:userrec;
    r:uflags;
    f:file;
    ii,is,s:astr;
    i,i1,x,oldusern:integer;
    byt:byte;
    c:char;
    save,save1,abort,next:boolean;
    nuvdat:file of nuvrec;
    nuvstuff:nuvrec;

  function unam:astr;
  begin
    unam:=caps(user.name)+' #'+cstr(usern);
  end;

  function searchtype(i:integer):string;
  var s:string;
  begin
    case i of
      0:s:='General text';           1:s:='Search ACS';
      2:s:='User SL';                3:s:='User DSL';
      4:s:='User AR flags';          5:s:='User AC flags';
      6:s:='User status';            7:s:='Days since last on';
      8:s:='Days since first on';    9:s:='Number of calls';
     10:s:='User age';               11:s:='User gender';
     12:s:='# 1/10''s call/post';    13:s:='#k DL/1k UL';
     14:s:='# DLs/1 UL';
    end;
    searchtype:=s;
  end;

  function find_fs:string;
  var fsf:f_statusflagsrec;
      s:string;
  begin
    s:='';
    for fsf:=fs_deleted to fs_slogging do
      if (fsf in f_status) then
        case fsf of
          fs_deleted   :s:=s+'Deleted,';
          fs_trapping  :s:=s+'Trapping,';
          fs_chatbuffer:s:=s+'Chat buffering,';
          fs_lockedout :s:=s+'Locked out,';
          fs_alert     :s:=s+'Alert,';
          fs_slogging  :s:=s+'Sep. SysOp Log,';
        end;
    if (s<>'') then s:=copy(s,1,length(s)-1) else s:='None.';
    find_fs:=s;
  end;

  procedure pcuropt;
  var r:uflags;
      s:string;
      i:integer;
      c:char;
      abort,next:boolean;
  begin
    cls;
    sprint('|WSearch limiting options ['+cstr(usern)+'/'+cstr(filesize(uf)-1)+']'); nl;
    i:=-1;
    abort:=FALSE; next:=FALSE;
    while ((i<14) and (not abort) and (not hangup)) do begin
      inc(i);
      if (i in [0..9]) then
        c:=chr(i+48)
      else
        case i of
          10:c:='A';
          11:c:='G';
          12:c:='P';
          13:c:='K';
          14:c:='N';
        end;
      sprompt(c+'. '+mln(searchtype(i),19)+': |C');
      s:='';
      if (not f_state[i]) then
        s:='Inactive'
      else
      begin
        case i of
          0:s:='"'+f_gentext+'"';
          1:s:='"'+f_acs+'"';
          2:s:=cstr(f_sl1)+' SL ... '+cstr(f_sl2)+' SL';
          3:s:=cstr(f_dsl1)+' DSL ... '+cstr(f_dsl2)+' DSL';
          4:for c:='A' to 'Z' do if (c in f_ar) then s:=s+c else s:=s+'-';
          5:begin
              for r:=rlogon to rmsg do
                if (r in f_ac) then
                  s:=s+copy('LCVFA*PEKM',ord(r)+1,1)
                else
                  s:=s+'-';
              s:=s+'/';
              for r:=fnodlratio to fnodeletion do
              begin
                if (r in f_ac) then
                  s:=s+copy('1234',ord(r)-19,1)
                else
                  s:=s+'-';
              end;
            end;
          6:s:=find_fs;
          7:s:=cstr(f_laston1)+' days ... '+cstr(f_laston2)+' days';
          8:s:=cstr(f_firston1)+' days ... '+cstr(f_firston2)+' days';
          9:s:=cstr(f_numcalls1)+' calls ... '+cstr(f_numcalls2)+' calls';
         10:s:=cstr(f_age1)+' years ... '+cstr(f_age2)+' years';
         11:s:=aonoff(f_gender='M','Male','Female');
         12:s:=cstr(f_postratio1)+' ... '+cstr(f_postratio2);
         13:s:=cstr(f_dlkratio1)+' ... '+cstr(f_dlkratio2);
         14:s:=cstr(f_dlratio1)+' ... '+cstr(f_dlratio2);
        end;
      end;
      sprint(s);
      wkey(abort,next);
    end;
    nl;
  end;

  function okusr(x:integer):boolean;
  var fsf:f_statusflagsrec;
      u:userrec;
      i,j:longint;
      ok:boolean;

    function nofindit(s:string):boolean;
    begin
      nofindit:=(pos(allcaps(f_gentext),allcaps(s))=0);
    end;

  begin
    with u do begin
      seek(uf,x); read(uf,u); ok:=TRUE;
      i:=-1;
      while ((ok) and (i<14)) do begin
        inc(i);
        if (f_state[i]) then
          case i of
            0:if ((nofindit(name)) and (nofindit(realname)) and
                  (nofindit(street)) and (nofindit(citystate)) and
                  (nofindit(zipcode)) and (nofindit(computer)) and
                  (nofindit(ph)) and (nofindit(note)) and (nofindit(usernote)) and
                  (nofindit(occupation)) and (nofindit(wherebbs))) then
                ok:=FALSE;
            1:if (not aacs1(u,x,f_acs)) then ok:=FALSE;
            2:if ((sl<f_sl1) or (sl>f_sl2)) then ok:=FALSE;
            3:if ((dsl<f_dsl1) or (dsl>f_dsl2)) then ok:=FALSE;
            4:if (not (ar>=f_ar)) then ok:=FALSE;
            5:if (not (ac>=f_ac)) then ok:=FALSE;
            6:for fsf:=fs_deleted to fs_slogging do
                if (fsf in f_status) then
                  case fsf of
                    fs_deleted   :if (not deleted) then ok:=FALSE;
                    fs_trapping  :if (not trapactivity) then ok:=FALSE;
                    fs_chatbuffer:if (not chatauto) then ok:=FALSE;
                    fs_lockedout :if (not lockedout) then ok:=FALSE;
                    fs_alert     :if (not (alert in ac)) then ok:=FALSE;
                    fs_slogging  :if (not slogseperate) then ok:=FALSE;
                  end;
            7:if ((daynum(laston)>daynum(date)-f_laston1) or
                  (daynum(laston)<daynum(date)-f_laston2)) then ok:=FALSE;
            8:if ((daynum(firston)>daynum(date)-f_firston1) or
                  (daynum(firston)<daynum(date)-f_firston2)) then ok:=FALSE;
            9:if ((loggedon<f_numcalls1) or (loggedon>f_numcalls2)) then ok:=FALSE;
           10:if (((ageuser(bday)<f_age1) or (ageuser(bday)>f_age2)) and
                  (ageuser(bday)<>0)) then
                ok:=FALSE;
           11:if (sex<>f_gender) then ok:=FALSE;
           12:begin
                j:=msgpost; if (j=0) then j:=1; j:=loggedon div j;
                if ((j<f_postratio1) or (j>f_postratio2)) then ok:=FALSE;
              end;
           13:begin
                j:=uk; if (j=0) then j:=1; j:=dk div j;
                if ((j<f_dlkratio1) or (j>f_dlkratio2)) then ok:=FALSE;
              end;
           14:begin
                j:=uploads; if (j=0) then j:=1; j:=downloads div j;
                if ((j<f_dlratio1) or (j>f_dlratio2)) then ok:=FALSE;
              end;
          end;
      end;
    end;
    okusr:=ok;
  end;

  procedure search(i:integer);
  var u:userrec;
      n:integer;
      c:char;
  begin
    n:=usern;
    repeat
      inc(usern,i);
      if (usern<=0) then usern:=filesize(uf)-1;
      if (usern>=filesize(uf)) then usern:=1;
    until ((okusr(usern)) or (usern=n));
  end;

  procedure clear_f;
  var i:integer;
  begin
    for i:=0 to 14 do f_state[i]:=FALSE;
    f_gentext:=''; f_acs:='';
    f_sl1:=0; f_sl2:=255; f_dsl1:=0; f_dsl2:=255;
    f_ar:=[]; f_ac:=[]; f_status:=[];
    f_laston1:=0; f_laston2:=65535; f_firston1:=0; f_firston2:=65535;
    f_numcalls1:=0; f_numcalls2:=65535; f_age1:=0; f_age2:=65535;
    f_gender:='M';
    f_postratio1:=0; f_postratio2:=65535; f_dlkratio1:=0; f_dlkratio2:=65535;
    f_dlratio1:=0; f_dlratio2:=65535;
  end;

  procedure stopt;
  var fsf:f_statusflagsrec;
      i,usercount:integer;
      c,ch:char;
      done:boolean;
      s:astr;

    procedure chbyte(var x:integer);
    var s:astr;
        i:integer;
    begin
      input(s,3); i:=x;
      if (s<>'') then i:=value(s);
      if ((i>=0) and (i<=255)) then x:=i;
    end;

    procedure chword(var x:word);
    var s:astr;
        w:word;
    begin
      input(s,5);
      if (s<>'') then begin
        w:=value(s);
        if ((w>=0) and (w<=65535)) then x:=w;
      end;
    end;

    procedure inp_range(var w1,w2:word; r1,r2:word);
    begin
      print('Range: '+cstr(r1)+'..'+cstr(r2));
      prt('Lower limit ['+cstr(w1)+'] : '); chword(w1);
      prt('Upper limit ['+cstr(w2)+'] : '); chword(w2);
    end;

    function get_f_ac:string;
    var r:uflags;
        s:string;
    begin
      for r:=rlogon to rmsg do
        if (r in f_ac) then
          s:=s+copy('LCVFA*PEKM',ord(r)+1,1)
        else
          s:=s+'-';
      s:=s+'/';
      for r:=fnodlratio to fnodeletion do
      begin
        if (r in f_ac) then
          s:=s+copy('1234',ord(r)-19,1)
        else
          s:=s+'-';
      end;
      get_f_ac:=s;
    end;

  begin
    done:=FALSE;
    pcuropt;
    repeat
      prt('Change (?=help): '); onek(c,'Q0123456789AGPKN?CLTU'^M);
      nl;
      case c of
        '0'..'9':i:=ord(c)-48;
        'A':i:=10; 'G':i:=11; 'P':i:=12; 'K':i:=13; 'N':i:=14;
      else
        i:=-1;
      end;
      if (i<>-1) then
      begin
        sprompt('|W');
        if (f_state[i]) then
          sprint(searchtype(i))
        else
        begin
          f_state[i]:=TRUE;
          sprint(searchtype(i)+' is now *ON*');
        end;
        nl;
      end;

      case c of
        '0':begin
              print('General text ["'+f_gentext+'"]');
              pchar; input(s,30);
              if (s<>'') then f_gentext:=s;
            end;
        '1':begin
              prt('Search ACS ["'+f_acs+'"]');
              pchar; inputl(s,50);
              if (s<>'') then f_acs:=s;
            end;
        '2':begin
              prt('Lower limit ['+cstr(f_sl1)+'] : ');
              chword(f_sl1);
              prt('Upper limit ['+cstr(f_sl2)+'] : ');
              chword(f_sl2);
            end;
        '3':inp_range(f_dsl1,f_dsl2,0,255);
        '4':repeat
              sprompt('Current: |C');
              for c:='A' to 'Z' do
                if c in f_ar then prompt(c) else prompt('-');
              nl;
              prt('AR flags (<CR>=Quit): ');
              onek(ch,^M'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
              nl;
              if (ch<>^M) then
              if (ch in ['A'..'Z']) then
                  if (ch in f_ar) then exclude(f_ar,ch) else include(f_ar,ch);
            until ((ch=^M) or (hangup));
        '5':begin
              repeat
(*              sprint('Current: |C'+get_f_ac); *)
                prt('Restrictions (?=list,Q:uit):');
                onek(c,'Q LCVFA*PEKM1234?'^M);
                nl;
                case c of
                  ^M,' ','Q': ;
                  '?':restric_list;
                else
                  if (tacch(c) in f_ac) then exclude(f_ac,tacch(c))
                  else include(f_ac,tacch(c));
                end;
              until ((c in [^M,' ','Q']) or (hangup));
            end;
        '6':repeat
              s:=find_fs;
              sprint('Current: |C'+s);
              prt('Toggle (?=help): '); onek(ch,'QACDLST? '^M);
              if (pos(ch,'ACDLST')<>0) then begin
                case ch of
                  'A':fsf:=fs_alert;
                  'C':fsf:=fs_chatbuffer;
                  'D':fsf:=fs_deleted;
                  'L':fsf:=fs_lockedout;
                  'S':fsf:=fs_slogging;
                  'T':fsf:=fs_trapping;
                end;
                if (fsf in f_status) then exclude(f_status,fsf)
                  else include(f_status,fsf);
              end else
                if (ch='?') then begin
                  nl;
                  lcmds(15,3,'AAlert','CChat-buffering');
                  lcmds(15,3,'DDeleted','LLocked-out');
                  lcmds(15,3,'SSeparate SysOp logging','TTrapping');
                  nl;
                end;
            until ((ch in ['Q',' ',^M]) or (hangup));
        '7':inp_range(f_laston1,f_laston2,0,65535);
        '8':inp_range(f_firston1,f_firston2,0,65535);
        '9':inp_range(f_numcalls1,f_numcalls2,0,65535);
        'A':inp_range(f_age1,f_age2,0,65535);
        'G':begin
              prt('Gender ['+f_gender+'] : ');
              onek(c,'QMF'^M); nl;
              if (c in ['F','M']) then f_gender:=c;
            end;
        'P':inp_range(f_postratio1,f_postratio2,0,65535);
        'K':inp_range(f_dlkratio1,f_dlkratio2,0,65535);
        'N':inp_range(f_dlratio1,f_dlratio2,0,65535);
        'C':if pynq('Are you sure') then clear_f;
        ^M,'L':pcuropt;
        'T':begin
              prt('Which? '); onek(ch,'Q0123456789AGPKN'^M);
              case ch of
                '0'..'9':i:=ord(ch)-48;
                'A':i:=10; 'G':i:=11; 'P':i:=12; 'K':i:=13; 'N':i:=14;
              else
                i:=-1;
              end;
              if (i<>-1) then begin
                f_state[i]:=not f_state[i];
                sprompt('|C[> |W'+searchtype(i)+' is now *');
                if (f_state[i]) then print('ON*') else print('OFF*');
              end;
              nl;
            end;
        'U':begin
              abort:=FALSE; usercount:=0;
              for i:=1 to filesize(uf)-1 do begin
                if (okusr(i)) then begin
                  seek(uf,i); read(uf,user1);
                  printacr('|C'+caps(user1.name)+' #'+cstr(i),abort,next);
                  inc(usercount);
                end;
                if (abort) then i:=filesize(uf)-1;
              end;
              if (not abort) then
                sprint('|LF|B ** |C'+cstr(usercount)+' Users.|LF');
            end;
        'Q':done:=TRUE;
        '?':begin
              sprint('|w(|W#||w)Change option');
              lcmds(16,3,'LList options','TToggle options on/off');
              lcmds(16,3,'CClear options','UUser''s who match');
              lcmds(16,3,'QQuit','');
              nl;
            end;
      end;
      if (pos(c,'C0123456789AGPKN')<>0) then nl;
    until ((done) or (hangup));
  end;

(* {-M-}
  procedure killusermail;
  var u:userrec;
      pinfo:pinforec;
      mixr:msgindexrec;
      i,j:longint;
  begin
    savepinfo(pinfo);
    initbrd(-1);
    for i:=0 to himsg do begin
      seek(mixf,i); blockread(mixf,mixr,1);
      j:=mixr.messagenum;
      if (not (mideleted in mixr.msgindexstat) and (j=usern)) then s:=rmail(i,false);
    end;
    loadpinfo(pinfo);
  end; *)

  procedure killuservotes;
  var vdata:file of vdatar;
      vd:vdatar;
      i:integer;
  begin
    assign(vdata,systat^.datapath+'voting.dat');
    SetFileAccess(ReadWrite,DenyNone);
    {$I-} reset(vdata); {$I+}
    if (ioresult=0) then begin
      for i:=1 to filesize(vdata) do
        if (user.vote[i]>0) then begin
          seek(vdata,i-1); read(vdata,vd);
          dec(vd.choices[user.vote[i]-1].numvoted);
          dec(vd.numvoted);
          seek(vdata,i-1); write(vdata,vd);
          user.vote[i]:=0;
        end;
      close(vdata);
    end;
  end;

  procedure delusr;
  var i:integer;
  begin
    if (not user.deleted) then begin
      save:=TRUE; user.deleted:=TRUE;
      dsr(user.name);
      sysoplog('* Deleted user: '+caps(user.name)+' #'+cstr(usern));
      i:=usernum; usernum:=usern;
      rsm(false);
      usernum:=i;

(*{-M-} killusermail; *)
      killuservotes;
    end;
  end;

  procedure renusr;
  begin
    if (user.deleted) then begin
      nl; print('Can''t rename deleted users.'); nl; pausescr; end
    else begin
      nl; sprompt('Enter new name: '); mpl(36); input(ii,36);
      if (ii<>'') and (ii[1] in ['A'..'Z','?']) then begin
        dsr(user.name); isr(ii,usern);
        user.name:=ii; save:=TRUE;
        if (usern=usernum) then thisuser.name:=ii;
      end;
    end;
  end;

  procedure chhflags;
  var done:boolean;
      c:char;
  begin
    nl;
    done:=FALSE;
    repeat
      sprint('Current: |C'+spflags(user));
      prt('Restrictions (?=list,Q:uit):');
      onek(c,'Q LCVFA*PEKM1234?'^M);
      case c of
        ^M,' ','Q':done:=TRUE;
        '?':restric_list;
      else
            begin
              if (c='4') and (not so) then print('You can''t change that!')
              else if (c in ['1'..'3']) and (not aacs('r'+c)) then print('Access denied.')
              else begin
                acch(c,user);
                save:=TRUE;
              end;
            end;
      end;
      nl;
    until (done) or (hangup);
    save:=TRUE;
  end;

  procedure chhsl;
  begin
    nl; prt('Enter new SL: '); mpl(3); ini(byt);
    if (not badini) then begin
      save:=TRUE;
      if (byt<thisuser.sl) or (usernum=1) then begin
        if (usernum=usern) and (byt<thisuser.sl) then
          if not pynq('Lower your own security level') then exit;
        user.sl:=byt;
      end else begin
        sysoplog('* Illegal SL change: '+caps(user.name)+' #'+cstr(usern)+
                 ' to '+cstr(byt));
        print('Access denied.');
      end;
    end;
  end;

  procedure chhdsl;
  begin
    nl;
    prt('Enter new DSL: '); mpl(3); ini(byt);
    if (not badini) then begin
      save:=TRUE;
      if (byt<thisuser.dsl) or (usernum=1) then begin
        if (usernum=usern) and (byt<thisuser.sl) then
          if not pynq('Lower your own DSL level') then exit;
        user.dsl:=byt;
      end else begin
        sysoplog('* Illegal DSL change: '+caps(user.name)+' #'+cstr(usern)+
                 ' to '+cstr(byt));
        print('Access denied.'^G);
      end;
    end;
  end;

  procedure chrecords(beg:byte);
  var on:byte;
      done:boolean;
      c:char;
      i:integer;
  begin
    on:=beg;
    done:=FALSE;
    with user do
      repeat
        cls;
        case on of
          1:begin
              sprint('|WCall records ['+cstr(usern)+'/'+cstr(filesize(uf)-1)+']'); nl;
              sprint('1. Total calls   : |C'+mn(loggedon,5)+'  |w4. Total time on  : |C'+mn(trunc(ttimeon),8));
              sprint('2. Calls today   : |C'+mn(ontoday,5)+ '  |w5. Time left today: |C'+mn(tltoday,5));
              sprint('3. Illegal logons: |C'+mn(illegal,5)+ '  |w6. Time bank      : |C'+mn(timebank,5));
              nl;
              prt('Select: (1-6,M:ail,F:ile,P:refs,Q:uit):');
              onek(c,'Q123456MFP'^M);
            end;
          2:begin
              sprint('|WMail records ['+cstr(usern)+'/'+cstr(filesize(uf)-1)+']'); nl;
              sprint('1. Public posts : |C'+mn(msgpost,5)+  '  |w2. Private posts : |C'+mn(emailsent,5));
              nl;
              prt('Select: (1-2,C:all,F:ile,P:refs,Q:uit):');
              onek(c,'Q12CFP'^M);
            end;
          3:begin
              sprint('|WFile records ['+cstr(usern)+'/'+cstr(filesize(uf)-1)+']'); nl;
              sprint('1. # of DLs: |C'+mn(downloads,5)+  '  |w4. DL k: |C'+cstr(trunc(dk)));
              sprint('2. # of ULs: |C'+mn(uploads,5)+    '  |w5. UL k: |C'+cstr(trunc(uk)));
              sprint('3. File pts: |C'+mn(filepoints,5));
              nl;
              prt('Select: (1-5,C:all,M:ail,P:refs,Q:uit):');
              onek(c,'Q12345CMP'^M);
            end;
          4:begin
              sprint('|WPreferences ['+cstr(usern)+'/'+cstr(filesize(uf)-1)+']'); nl;
             sprompt('1. Hotkeys: |C'+onoff(onekey in ac)+      '  |w4. Editor   : |C');
              case edtype of 0:print('Choose'); 1:print('Line'); 2:print('FSE'); end;
             sprompt('2. Expert : |C'+onoff(not (novice in ac))+'  |w5. Emulation: |C');
              if (rip in ac) then print('RIP') else
              if (ansi in ac) then print('ANSI') else
              if (avatar in ac) then print('AVATAR') else
              print('TTY');
              sprint('3. Pause  : |C'+onoff(pause in ac));
              nl;
              prt('Select: (1-5,C:all,M:ail,F:ile,Q:uit):');
              onek(c,'Q12345CMF'^M);
            end;
        end; {case}

        if (on in [1,2,3]) then begin
          case c of
            'Q',^M:done:=TRUE;
            'C':on:=1;
            'M':on:=2;
            'F':on:=3;
            'P':on:=4;
            '1'..'6':begin
              nl; prt('New value: '); mpl(5); inu(i);
              if not badini then
                case on of
                  1:case value(c) of
                      1:loggedon:=i; 4:ttimeon:=i; 2:ontoday:=i; 5:tltoday:=i;
                      3:illegal:=i; 6:timebank:=i;
                    end;
                  2:case value(c) of
                      1:msgpost:=i; 2:emailsent:=i;
                    end;
                  3:case value(c) of
                      1:downloads:=i; 3:filepoints:=i; 4:dk:=i; 2:uploads:=i; 5:uk:=i;
                    end;
                end;
            end;
          end;
        end else begin
          case c of
            'Q',^M:done:=true;
            'C':on:=1;
            'M':on:=2;
            'F':on:=3;
            '1':if (onekey in ac) then exclude(ac,onekey) else include(ac,onekey);
            '2':if (novice in ac) then exclude(ac,novice) else include(ac,novice);
            '3':if (pause in ac) then exclude(ac,pause) else include(ac,pause);
            '4':cstuff(29,3,user);
            '5':cstuff(16,3,user);
          end;
        end;
      until (done) or (hangup);
  end;

  function onoff(b:boolean; s1,s2:astr):astr;
  begin
    if b then onoff:=s1 else onoff:=s2;
  end;

  procedure lcmds3(len:byte; c1,c2,c3:astr);
  var s:astr;
  begin
    s:='';
    s:=s+'|w(|W'+c1[1]+'|w)'+mln(copy(c1,2,lenn(c1)-1),len-1);
    if (c2<>'') then
      s:=s+'|w(|W'+c2[1]+'|w)'+mln(copy(c2,2,lenn(c2)-1),len-1);
    if (c3<>'') then
      s:=s+'|w(|W'+c3[1]+'|w)'+copy(c3,2,lenn(c3)-1);
    printacr(s,abort,next);
  end;

  procedure statususr;
  var cc:char;
  begin
    repeat
      cls;
      sprint('|WUser Status ['+cstr(usern)+'/'+cstr(filesize(uf)-1)+']'); nl;

      sprompt('1. Deleted        : |C');
      if fnodeletion in user.ac then sprint('|RProtected')
      else if user.deleted then print('Yes')
      else print('No');

      sprompt('2. Locked out     : |C');
      if user.lockedout then begin
        prompt('Yes ('); prompt(user.lockedfile);
        print(')');
      end else sprint('No');

      sprompt('3. Alert          : |C');
      if alert in user.ac then print('Yes') else print('No');

      sprint('4. Trapping status: '+onoff(user.trapactivity,
        '|R'+onoff(user.trapseperate,'Trapping to TRAP'+cstr(usern)+
        '.###','Trapping to TRAP.###'),'|COff')+onoff(systat^.globaltrap,
        '|R <GLOBAL>',''));

      sprint('5. Auto-chat state: '+onoff(user.chatauto,
        onoff(user.chatseperate,'|ROutput to CHAT'+cstr(usern)+'.###',
        '|ROutput to CHAT.###'),'|COff')+onoff(systat^.autochatopen,
        '|R <GLOBAL>',''));

      sprint('6. SysOp Log state: '+onoff(user.slogseperate,'|RLogging to SLOG'+
        cstr(usern)+'.'+cstr(nodenum),+'|CNormal output'));

      nl;
      prt('Your commands (1-6,Q:uit): ');
      onek(cc,'123456Q'^M); nl;

      case cc of
        '1':begin
              if user.deleted then begin
                if pynq('Restore this user') then begin
                  isr(user.name,usern); user.deleted:=false;
                end else
                  save:=save1;
              end else
              if fnodeletion in user.ac then begin
                print('Access denied. This user is protected from deletion.');
                sysoplog('* Attempted to delete user: '+caps(user.name)+' #'+cstr(usern));
                nl; pausescr; save:=save1;
              end else begin
                if pynq('Delete this user') then delusr else save:=save1;
              end;
            end; {1}
        '2':begin
              if pynq('Lock-out this user') then begin
                nl;
                print('Account is now frozen. Each time the user logs on, a file will');
                print('be displayed before the connection is terminated.');
                nl;
                prt('Enter the lockout filename: '); mpl(8); input(ii,8);
                if ii='' then
                  user.lockedout:=false
                else begin
                  user.lockedout:=true;
                  user.lockedfile:=ii;
                  sysoplog('* Locked out '+unam+' - Lockfile: '+ii);
                end;
              end else begin
                user.lockedout:=false;
                nl;
                print('Account is not frozen.'); nl; pausescr;
              end;
           end; {2}
        '3':if pynq('Alert when user logs on') then
              include(user.ac,alert)
            else
              exclude(user.ac,alert);
        '4':begin
              dyny:=user.trapactivity;
              user.trapactivity:=
                pynq('Trap user activity');
              if (user.trapactivity) then begin
                dyny:=user.trapseperate;
                user.trapseperate:=
                  pynq('Log to separate file');
              end else
                user.trapseperate:=FALSE;
            end;
        '5':begin
              dyny:=user.chatauto;
              user.chatauto:=pynq('Auto-chat buffer open');
              if (user.chatauto) then begin
                dyny:=user.chatseperate;
                user.chatseperate:=pynq('Separate buffer file');
              end else
                user.chatseperate:=FALSE;
            end;
        '6':begin
              dyny:=user.slogseperate;
              user.slogseperate:=pynq('Output SysOp Log separately');
            end;
      end; {case}
    until cc='Q';
  end;

begin
  SetFileAccess(ReadWrite,DenyNone);
  reset(uf);
  if ((usern<1) or (usern>filesize(uf)-1)) then begin close(uf); exit; end;
  if (usern=usernum) then begin
    user:=thisuser;
    seek(uf,usern); write(uf,user);
  end;
  seek(uf,usern); read(uf,user);

  clear_f;

  oldusern:=0;
  save:=FALSE;

  repeat

    abort:=FALSE;
    if (autolist) or (usern<>oldusern) or (c=^M) then begin
      cls;
      showuserinfo(userinfotyp,usern,user);
      oldusern:=usern;
    end;

    nl;
    prt('Option (?=help): ');
    onek(c,'Q?[]={}*ABCDEFGHIJKLMNOPRSTUVWY1234-_;:\+'^M);

    case c of

      '?':begin
            nl;
            sprint('|w<|WCR|w>Redisplay user       (|W;|w)New list mode         (|W:|w)Autolist mode toggle');
            lcmds3(23,'[Back one user',']Forward one user','=Oops (reload old data)');
            lcmds3(23,'{Search backward','}Search forward','*Auto-validate user');
            lcmds3(23,'Search options','UGoto user name/#','\SysOp Log');
            lcmds3(23,'-New user answers','_Other Q. answers','+Add to NUV');
            nl; pausescr;
            save:=FALSE;
          end;

      { These commands need the user record saved beforehand and reread after
        the command is processed }

      '[',']','{','}','U','Q':
          begin
            if save then
            begin
              seek(uf,usern); write(uf,user);
              if usern=usernum then thisuser:=user;
              save:=FALSE;
              sysoplog('* Modified user: '+caps(user.name)+' #'+cstr(usern));
            end;
            case c of
              '[':begin
                    dec(usern);
                    if (usern<=0) then usern:=filesize(uf)-1;
                  end;
              ']':begin
                    inc(usern);
                    if (usern>=filesize(uf)) then usern:=1;
                  end;
              '{':begin
                    nl; prompt('Searching ... ');
                    search(-1); nl;
                  end;
              '}':begin
                    nl; prompt('Searching ... ');
                    search(1);  nl;
                  end;
              'U':begin
                    nl; prt('Enter user name, number, or partial search string: ');
                    finduserws(i);
                    if (i>0) then begin
                      seek(uf,i); read(uf,user);
                      usern:=i;
                    end;
                  end;
            end;
            seek(uf,usern);
            read(uf,user);
            if (usern=usernum) then thisuser:=user;
          end;

      '=':begin
            nl;
            if pynq('Reload old user data') then
            begin
              seek(uf,usern);
              read(uf,user);
              if (usern=usernum) then thisuser:=user;
              save:=FALSE;
              sprint('|ROld data reloaded.');
            end;
          end;

      { These commands don't require anything special }

      'S','-','_',';',':','\','+':
          begin
            case c of
              'S':stopt;
              '+':if systat^.nuv then
                  begin
                    assign(nuvdat,systat^.datapath+'NUV.DAT');
                    SetFileAccess(ReadWrite,DenyNone);
                    {$I-} reset(nuvdat); {$I+}
                    if ioresult<>0 then rewrite(nuvdat);
                    seek(nuvdat,filesize(nuvdat));
                    with nuvstuff do begin
                      newusernum:=usern;
                      for i:=1 to 20 do
                      begin
                        votes[i].name:='';
                        votes[i].number:=0;
                        votes[i].vote:=0;
                        votes[i].comment:='';
                      end;
                    end;
                    write(nuvdat,nuvstuff);
                    close(nuvdat);
                    sprint('User has been added for NUV voting.|LF|PA');
                  end else
                    sprint('New User Voting is not active.|LF|PA');
              '-':begin
                    readasw(usern,systat^.textpath+'newuser');
                    pausescr;
                  end;
              '_':begin
                    nl;
                    prt('Print questionairre file: '); mpl(8); input(s,8); nl;
                    readasw(usern,systat^.textpath+s);
                    pausescr;
                  end;
              ';':begin
                    nl;
                    prt('List mode (L:ong,S:hort) : ');
                    onek(c,'QSL '^M);
                    case c of
                      'S':userinfotyp:=2;
                      'L':userinfotyp:=1;
                    end;
                  end;
              ':':autolist:=not autolist;
              '\':begin
                    s:=systat^.trappath+'slog'+cstr(usern)+'.'+cstr(nodenum);
                    printf(s);
                    if (nofile) then begin nl; print('"'+s+'" not found.'); end;
                    nl; pausescr;
                  end;
            end;
          end;

      { These commands need sufficient access to be changed }

      '*','K','C','D','M','O','N','P','F','I','R','J','W',
      'A','V','B','L','G','H','E','1','2','3','4','T':
          begin
            if ((thisuser.sl<=user.sl) or (thisuser.dsl<=user.dsl)) and
               (usernum<>1) and (usernum<>usern) then begin
              sysoplog('* Tried to modify '+caps(user.name)+' #'+cstr(usern));
              print('Access denied.');
            end else
            begin
              save1:=save; save:=TRUE;
              case c of
                '*':begin
                      autoval(user,usern);
{                     ssm(abs(usern),'You were validated on '+date+' '+time+'.'); }
                    end;
                'K':statususr;
                'C':cstuff(1,3,user);
                'D':cstuff(4,3,user);
                'M':chhdsl;
                'O':chhflags;
                'N':begin
                      nl;
                      repeat
                        sprompt('Current: |C');
                        for c:='A' to 'Z' do
                          if c in user.ar then prompt(c) else prompt('-');
                        nl;
                        prt('AR flag (<CR>=Quit) : ');
                        onek(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
                        if (c<>^M) then
                          if (not (c in thisuser.ar)) and (usernum<>1) then begin
                            sysoplog('* Tried to give '+caps(user.name)+
                                     ' #'+cstr(usern)+' AR flag "'+c+'"');
                            print('Access denied.'^G)
                          end else
                            if (c in ['A'..'Z']) then
                              if (c in user.ar) then exclude(user.ar,c)
                                                else include(user.ar,c);
                        nl;
                      until (c=^M) or (hangup);
                      c:=#0;
                    end;
                'P':begin
                      cstuff(2,3,user);
                      cstuff(12,3,user);
                    end;
                'F':cstuff(6,3,user);
                'I':begin
                      nl;
                      sprompt('New SysOp note: '); mpl(39); inputl(s,39);
                      if (s<>'') then user.note:=s;
                    end;
                'J':cstuff(25,3,user);
                'R':begin
                      nl;
                      sprompt('New last-on date: ');
                      inputdate(s);
                      if (length(s)=8) and (daynum(s)<>0) then user.laston:=s;
                      nl; nl;
                      sprompt('New first-on date: ');
                      inputdate(s);
                      nl;
                      if (length(s)=8) and (daynum(s)<>0) then user.firston:=s;
                    end;
                'A':renusr;
                'T':cstuff(8,3,user);
                'B':cstuff(10,3,user);
                'L':chhsl;
                'G':cstuff(5,3,user);
                'H':cstuff(13,3,user);
                'E':cstuff(14,3,user);
                'V':cstuff(9,3,user);
                '1'..'4':chrecords(value(c));
                'W':begin
                      nl;
                      sprompt('Enter new amount of credits: '); mpl(5);
                      inu(i); if (not badini) then user.credit:=i;
                    end;
                else
                      save:=save1;
              end;
            end;
          end;

    end; {big case statement}

    if (usern=usernum) then thisuser:=user;
  until (c='Q') or hangup;
  close(uf);
  topscr;
end;

end.
