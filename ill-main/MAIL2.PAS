(****************************************************************************)
(* Illusion BBS - Mail functions [2/?]                                      *)
(****************************************************************************)

Unit Mail2;

{$I MKB.Def}

Interface

Uses CRT, DOS, Mail0, Common,
     MkGlobT, MkMsgAbs, MkString;

Procedure MBaseList;
Procedure MBaseChange(VAR Done:boolean; mStr:astr);
Procedure ConfigZscan;
Procedure LoadMsgZscan;
Procedure SaveMsgZscan;

Implementation




(*
procedure mbaselist;
var b,b2 : integer;
begin
   b:=1;
   printf('msgbase.top');
   while (b <= numBoards) and (not hangup) do begin
      if (mbunhidden in memboard.mbstat) or (mbaseAc(b)) then begin
           b2:=ccboards[1][b];
           sysMciSet('ME',memboard.name);
           sysMciSet('MI',cstr(b2));
           if (b in zscanr.mzscan) then sysMciSet('MS','Yes')
           else sysMciSet('MS','NO');
           case memboard.mbtype of
              0 : sysMciSet('MT','Local');
              1 : sysMciSet('MT','Echo');
              2 : sysMciSet('MT','XMail');
           end;
           printf('msgbase.mid');
           sysResetMciList;
      end;
      inc(b);
   end;
  printf('msgbase.bot');
end;
*)


Procedure MBaseList;
Var abort,next:boolean;
    currec,numrec,curalias,rb:word;
    acc       :boolean;  { Access to base? }    
    t         :BaseTyp;  { Base types }
    
    OldBoardLoaded:Word;

Begin
  abort:=FALSE; next:=FALSE;
  OldBoardLoaded:=BoardLoaded;
  Currec:=0; rb:=0;

  SetFileAccess(ReadOnly, DenyNone);
  Reset(bf);
  NumRec:=FileSize(bf);
  Close(bf);

  printf('msgbase.top'); {msg base list header}  

  if (numrec=0) then
  begin
    spstr(709); {no msg bases}
    exit;
  end;

  while ((currec<numrec) and (not abort)) do
    begin
      clearwaves;
    
      if LoadBoard(currec) then;

      acc:=aacs(Memboard.acs);

      if ((mbvisible in memboard.mbstat) or (acc)) then
        begin
          if (acc) then
            begin            
              addwave('MN',memboard.name,txt);           
              addwave('M#',cstr(rb),txt); 
              LoadMsgZscan;
              if (msgzscan.qwkscan) then addwave('MQ','Yes',txt)
              else addwave('MQ','No',txt);
              if (msgzscan.mailscan) then addwave('MM','Yes',txt)
              else addwave('MM','No',txt);           

              for t:=Public to News do
                begin
                  if t in MemBoard.BaseStat then
                    case t of
                      Public   : addwave('MS','Public',txt);    {s:=s+'P';}
                      Private  : addwave('MS','Private',txt);   {s:=s+'R';}
                      Networked: addwave('MS','Networked',txt); {s:=s+'N';}
                      News     : addwave('MS','News',txt);      {s:=s+'A';}
                    end
                  else
                    addwave('MS','Private',txt);      {s:=s+'A';}                    
                end;
               inc(rb); 
            end
          else
          
          if (not empty) then wkey(abort,next);
                    
        end;
      inc(currec);      
      printf('msgbase.mid');
      clearwaves;  
    end; {While}
    
    
   printf('msgbase.bot');  
  LoadBoard(OldBoardLoaded);
end; {proc MBaseList}




Procedure MBaseChange(VAR Done:boolean; mStr:astr);
var s:astr;
    i:integer;
begin
  if mstr<>'' then
    case mstr[1] of
      '+':begin
            i:=board;
            if (board>=numboards) then i:=0 else
              repeat
                inc(i);
                changeboard(i);
              until (board=i) or (i>numboards);
            if (board<>i) then spstr(735) {highest}
              else lastcommandovr:=TRUE;
          end;
      '-':begin
            i:=board;
            if board<=0 then i:=numboards else
              repeat
                dec(i);
                changeboard(i);
              until (board=i) or (i<=0);
            if (board<>i) then spstr(710)
              else lastcommandovr:=TRUE;
          end;
      'L':mbaselist;
    else
          begin
            changeboard(value(mstr));
            if pos(';',mstr)>0 then begin
              s:=copy(mstr,pos(';',mstr)+1,length(mstr));
              curmenu:=systat^.menupath+s+'.mnu';
              newmenutoload:=TRUE;
              done:=TRUE;
            end;
            lastcommandovr:=TRUE;
          end;
    end
  else begin
    if (novice in thisuser.ac) then mbaselist;
    nl;
    s:='?';
    repeat
      spstr(84); {change msg area prompt}
      input(s,3); i:=value(s);
      if s='?' then begin mbaselist; nl; end else
        if (i>=0) and (i<=numboards) and (i<>board) then
          changeboard(i);
    until (s<>'?') or (hangup);
    lastcommandovr:=TRUE;
  end;
end;

Procedure LoadMsgZscan;
var i:word;
begin
  SetFileAccess(ReadWrite,DenyNone);
  assign(msgzscanf,systat^.datapath+cstr(memboard.permindx)+'.MSI');
  {$I-} reset(msgzscanf); {$I+}
  if (ioresult=0) then begin
    if (usernum>filesize(msgzscanf)-1) then begin
      seek(msgzscanf,filesize(msgzscanf));
      msgzscan.mailscan := not (MemBoard.ScanType=1);
      msgzscan.qwkscan  := not (MemBoard.ScanType=1);
      for i:=filesize(msgzscanf) to usernum do
        write(msgzscanf,msgzscan);
    end;
    seek(msgzscanf,usernum);
    read(msgzscanf,msgzscan);
    close(msgzscanf);
  end else begin
    rewrite(msgzscanf);
    msgzscan.mailscan := not (MemBoard.ScanType=1);
    msgzscan.qwkscan  := not (MemBoard.ScanType=1);
    for i:=0 to systat^.numusers do
      write(msgzscanf,msgzscan);
    seek(msgzscanf,usernum);
    read(msgzscanf,msgzscan);
    close(msgzscanf);
  end;
end;

Procedure SaveMsgZscan;
begin
  SetFileAccess(ReadWrite,DenyNone);
  assign(msgzscanf,systat^.datapath+cstr(memboard.permindx)+'.MSI');
  reset(msgzscanf);
  seek(msgzscanf,usernum);
  write(msgzscanf,msgzscan);
  close(msgzscanf);
end;

Procedure ConfigZscan;
var os,s:string;
    i,j,k:word;
    tq,tn,done:boolean;

  Procedure Toggle(base:word);
  Var i:word;
  begin
    i:=RealMsgIdx(base);
    if (i>0) and (i<=numboards) then
    begin
      LoadBoard(i);

      clearwaves;
      addwave('MN',memboard.name,txt);
      if (memboard.scantype=2) then
        spstr(711) {mandatory}
      else
      begin
        LoadMsgZscan;
        if (tn) then
        begin
          msgzscan.mailscan:=not msgzscan.mailscan;
          if (msgzscan.mailscan) then spstr(712) else spstr(713); {scanned/not}
        end;
        if (tq) then
        begin
          msgzscan.qwkscan:=not msgzscan.qwkscan;
          if (msgzscan.qwkscan) then spstr(714) else spstr(715); {scanned/not}
        end;
        SaveMsgZscan;
      end;
      clearwaves;
    end;
  end;

begin
  MBaseList;
  done:=FALSE;
  tn:=true;
  tq:=false;
  repeat
    clearwaves;
    if (tn) and (not tq) then addwave('SF',getstr(716),txt) else {normal}
    if (not tn) and (tq) then addwave('SF',getstr(717),txt) else {qwk}
    if (tn) and (tq)     then addwave('SF',getstr(718),txt);     {norm&qwk}
    spstr(719); {[t]oggling...}
    clearwaves;
    spstr(720); {prompt}
    mpl(8);
    input(s,8);
    s:=sqoutsp(s);
    if (s='Q') then
      done:=TRUE
    else
    if (s='?') then
      mbaselist
    else
    if (s='T') then
    begin
      if (tn and tq) then
        tq:=false
      else
      if (tn and (not tq)) then
      begin
        tq:=true;
        tn:=false;
      end else
        tn:=true;
    end else
    begin
      os:='';
      nl;
      while (s<>'') do
      begin
        j:=pos(',',s);
        if (j=0) then
        begin
          os:=s;
          s:='';
        end else
        begin
          os:=copy(s,1,j-1);
          delete(s,1,j);
        end;
        j:=pos('-',os);
        if (j=0) then
        begin
          i:=value(os);
          if (i>0) then
            toggle(i);
        end else
        begin
          i:=value(copy(os,1,j-1));
          k:=value(copy(os,j+1,length(os)-j));
          if (i>0) and (k>0) then
          begin
            if (i>k) then {swap them}
            begin
              j:=k;
              k:=i;
              i:=j;
            end;
            for j:=i to k do
              toggle(j);
          end;
        end;
      end;
    end;
  until (done) or (hangup);
  lastcommandovr:=TRUE;
end;

End.
