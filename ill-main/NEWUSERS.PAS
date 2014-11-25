(*****************************************************************************)
(* Illusion BBS - New user applications                                      *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit newusers;

interface

uses
  crt, dos,
  mail4, misc2, misc3, infoform, miscx, iplx,
  common, sysop3;

procedure newuser;
procedure newuserinit;

implementation

procedure p2;
var user:userrec;
    i,j:integer;
    nuvdat:file of nuvrec;
    nuvstuff:nuvrec;
    val:valrec;
    valf:file of valrec;
    tries:integer; pw:astr;
    result:byte;
begin
  if (systat^.newuserpw<>'') then
  begin
    tries:=0; pw:='';
    while ((pw<>systat^.newuserpw) and
          (tries<systat^.maxlogontries) and (not hangup)) do begin
      spstr(16);
      echo:=FALSE; input(pw,20); echo:=TRUE;
      if ((systat^.newuserpw<>pw) and (pw<>'')) then begin
        sl1('|R>>|w Illegal newuser password: "'+pw+'"');
        inc(tries);
      end;
    end;
    if (tries>=systat^.maxlogontries) then begin
      spstr(480);
      hangup:=TRUE;
    end;
  end;
  
  spstr(803);
  if (not pynq(getstr(804))) then hangup:=true
  else begin
    spstr(481);
    result:=iplmodule('APPLY','');
    if (result=1) then hangup:=true;
  end;

  if (not hangup) then begin
    SetFileAccess(ReadOnly,DenyNone);
    reset(uf);
    j:=0;
    for i:=1 to filesize(uf)-1 do
    begin
      seek(uf,i); read(uf,user);
      if ((user.deleted) and (j=0)) then j:=i;
    end;
    if (j<>0) then usernum:=j else usernum:=filesize(uf);

    assign(valf,systat^.datapath+'AUTOVAL.DAT');
    SetFileAccess(ReadOnly,DenyNone);
    reset(valf); read(valf,val); close(valf);

    with thisuser do
    begin
      firston:=date; laston:=date;
      note:='New User on '+date+''; usernote:=val.unote;
      lockedout:=FALSE; deleted:=FALSE; lockedfile:='';
      loggedon:=0; msgpost:=0; emailsent:=0; ontoday:=0;
      illegal:=0; forusr:=0; conference:='@';
      downloads:=0; uploads:=0; dk:=0; uk:=0;
      ttimeon:=0; lastmsg:=1; lastfil:=1;
      credit:=val.credit; timebank:=0;

      for i:=1 to 20 do vote[i]:=0;
      for i:=1 to sizeof(res1) do res1[i]:=0;
      for i:=1 to sizeof(res2) do res2[i]:=0;
      for i:=1 to sizeof(res3) do res3[i]:=0;
      for i:=1 to sizeof(res4) do res4[i]:=0;
      for i:=1 to sizeof(res5) do res5[i]:=0;
      for i:=1 to sizeof(res6) do res6[i]:=0;

      readinzscan; { load old / create new NEWSCAN.DAT record }
      with zscanr do
      begin
        fzscan:=[];
        for i:=0 to maxuboards do include(fzscan,i);
      end;
      savezscanr;

      trapactivity:=FALSE; trapseperate:=FALSE;
      timebankadd:=0;
      mpointer:=-1;
      chatauto:=FALSE; chatseperate:=FALSE;
      slogseperate:=FALSE;

      for i:=1 to 10 do
      begin
        if (i in [1..8]) then flistc[i][1]:=1 else flistc[i][1]:=0;
        case i of
          1:flistc[i][2]:=ord('W');
          2:flistc[i][2]:=ord('B');
          3:flistc[i][2]:=ord('b');
          4:flistc[i][2]:=ord('K');
          5:flistc[i][2]:=ord('w');
          6,
          7:flistc[i][2]:=ord('K');
          8:flistc[i][2]:=ord('w');
          9,
         10:flistc[i][2]:=ord('w');
        end;
      end;

      { Initalize to Default Settings 1 ON / 0 OFF}

      flistc[1][1] :=  1; { FileName }
      flistc[2][1] :=  1; { FileSize }
      flistc[3][1] :=  0; { FilePoints }
      flistc[4][1] :=  1; { Popularity }
      flistc[5][1] :=  1; { Descriptions }
      flistc[6][1] :=  1; { Uploader }
      flistc[7][1] :=  1; { Date }
      flistc[8][1] :=  1; { Verbose }

      qwkarc:=systat^.qwkcomp; qwkfiles:=FALSE;

      sl:=val.sl; dsl:=val.dsl; realsl:=sl; realdsl:=dsl;
      filepoints:=val.fp;

      ar:=val.ar;
      tltoday:=systat^.timeallow[sl];
    end;

    setfileaccess(readwrite,denynone);
    reset(uf);
    seek(uf,usernum);
    write(uf,thisuser);
    close(uf);

    isr(thisuser.name,usernum);

    if (systat^.nuv) then
    begin
      with nuvstuff do
      begin
        newusernum:=usernum;
        for i:=1 to 20 do
        begin
          votes[i].name:='';
          votes[i].number:=0;
          votes[i].vote:=0;
          votes[i].comment:='';
        end;
      end;
      assign(nuvdat,systat^.datapath+'NUV.DAT');
      setfileaccess(readwrite,denynone);
      reset(nuvdat);
      seek(nuvdat,filesize(nuvdat));
      write(nuvdat,nuvstuff);
      close(nuvdat);
    end;

    useron:=TRUE;
    window(1,1,80,linemode); clrscr;
    schangewindow(not cwindowon,curwindow);
    cls;

    if ((exist(systat^.textpath+'newuser.inf'))) then
      readq('newuser',0);

    topscr;
    if (systat^.newapp<>-1) then
      spstr(490);
    nl;
  end;
end;

procedure newuser;
var result:byte;

begin
  sl1('|R*** |wApplied as a new user.');

  begin
    with thisnode do
    begin
      whereuser:=getstr(667);
      savenode;
    end;
    p2;

    if (systat^.newapp<>-1) then begin
      SendMail(systat^.newapp,'\New User Application');
    end;    
           
    
    inc(systat^.todayzlog.newusers); savesystat;
    with thisnode do
    begin
      whereuser:=getstr(436);
      savenode;
    end;
    wasnewuser:=TRUE;
  end;
  useron:=TRUE;
end;

procedure newuserinit;
begin
  clrscr;{windowthing;}
  if (systat^.closedsystem) then begin
    spstr(480);
    hangup:=TRUE;
  end else with thisuser do begin
    name:='';
    trapactivity:=FALSE;
    trapseperate:=FALSE;
    inittrapfile;
  end;
end;

end.
