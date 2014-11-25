(*****************************************************************************)
(* Illusion BBS - BBS List                                                   *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit bbslist;

interface

uses
  crt, dos,
  common;

procedure abbs(m1:astr);

implementation

procedure abbs(m1:astr);
label skipmodify,skipdelete;
var bbs,bbs1:bbslistrec;
    bbsf:file of bbslistrec;
    abort,next,lon:boolean;
    ii,iii:integer;
    which:char;

  procedure showbbs(l:boolean;c:integer);
  begin
    with bbs do
    begin
      clearwaves;
      addwave('B#',cstr(c),txt);
      addwave('PH',ph,txt);
      addwave('BN',name,txt);
      addwave('BP',bps,txt);
      addwave('SW',software,txt);
      addwave('ED',info,txt);
      addwave('DM',bbsdate,txt);
      if l then spstr(645) else spstr(644);
      clearwaves;
    end;
  end;

  function inp(b:byte):boolean;
  var s:astr; j:integer;
      isuscan:boolean;
      c:char;
  begin
    inp:=FALSE;
    with bbs do
    case b of
      1:begin
          spstr(90); onek(c,'DT');
          if (c='T') then
          begin
            bps:='TELNET';
            spstr(91); {enter telnet addr}
            mpl(20);
            inputl(s,20);
          end else
          begin
            bps:='';
            isuscan:=pynq(getstr(647));
            spstr(648); {ph#}
            if isuscan then
            begin
              inputphone(s);
              spstr(649); {LF}
            end else
            begin
              mpl(12);
              input(s,12);
            end;
          end;
          if (s<>'') then begin ph:=s; inp:=true; end;
        end;
      2:begin
          spstr(650); {bbs name}
          mpl(30);
          inputl(s,30);
          if (s<>'') then begin name:=s; inp:=true; end;
        end;
      3:if (bps<>'TELNET') then
        begin
          spstr(651); {max bps}
          mpl(6);
          input(s,6);
          if (s<>'') then begin bps:=s; inp:=true; end;
        end else
          inp:=true;
      4:begin
          spstr(655); {bbs s/w}
          mpl(10);
          input(s,10);
          if (s<>'') then begin software:=s; inp:=true; end;
        end;
      5:begin
          spstr(660); {more info}
          mpl(50);
          inputl(s,50);
          info:=s;
          inp:=true;
        end;
    end; {case}
  end;

  procedure add_bbs;
  var c,cc:integer;
  begin
    with bbs do
    begin
      if pynq(getstr(646)) then
      begin
        SetFileAccess(ReadWrite,DenyNone);
        {$I-} reset(bbsf); {$I+}
        if ioresult<>0 then
        begin
          rewrite(bbsf);
          close(bbsf);
          SetFileAccess(ReadWrite,DenyNone);
          reset(bbsf);
        end;

        for c:=1 to 5 do
        begin

          repeat until (inp(c)) or (hangup);
          if c=1 then
            for cc:=0 to filesize(bbsf)-1 do
            begin
              seek(bbsf,cc);
              read(bbsf,bbs1);

              if bbs1.ph=bbs.ph then
              begin          { DUPLICATE }
                spstr(661);
                bbs:=bbs1;
                showbbs(TRUE,0);
                nl;
                close(bbsf);
                exit;
              end;
            end;
        end;

        for c:=1 to sizeof(res1) do res1[c]:=0;
        bbsdate:=date;
        spstr(663);
        showbbs(TRUE,0);
        if pynq(getstr(662)) then
        begin
          seek(bbsf,filesize(bbsf));
          write(bbsf,bbs);
          sysoplog('Added to BBS list: '+bbs.name);
        end;
        close(bbsf);

      end;
    end;
  end;

  procedure list_bbs;
  var c:integer;
  begin
    abort:=FALSE;
    next:=FALSE;
    c:=0;

    SetFileAccess(ReadOnly,DenyNone);
    {$I-} reset(bbsf); {$I+}

    if (ioresult<>0) then
      spstr(642)  {bbs list empty}
    else
    if filesize(bbsf)=0 then
    begin
      spstr(642); {bbs list empty}
      close(bbsf);
    end else
    begin
      lon:=pynq(getstr(641)); {show extended}
      spstr(643);             {list header}
      while (c<=filesize(bbsf)-1) and (not abort) and (not hangup) do
      begin
        seek(bbsf,c);
        read(bbsf,bbs);
        showbbs(lon,c+1);
        inc(c);
        wkey(abort,next);
      end;
      close(bbsf);
    end;
  end;

  procedure modify_bbs;
  var changed:boolean;
      c:integer;
  begin
    SetFileAccess(ReadWrite,DenyNone);
    {$I-} reset(bbsf); {$I+}
    if ioresult<>0 then
      sprint('|wNo BBSs found to modify.')
    else
    begin
      nl;
      nl;

      repeat
        prt('Modify which entry (1-'+cstr(filesize(bbsf))+'): ');
        inu(c);
      until ((c in [1..filesize(bbsf)]) or (c=0)) or (hangup);

      if (c<>0) then
      begin
        dec(c);
        seek(bbsf,c);
        read(bbsf,bbs);
        changed:=false;

        repeat
          nl;
          showbbs(TRUE,0);
          prt('Command (?=help): ');
          onek(which,'Q?12345');
          nl;
          case which of
            '?':begin
                  lcmds(25,3,'1Phone Number'  ,'2BBS Name');
                  lcmds(25,3,'3Max. bps rate' ,'4BBS Software');
                  lcmds(25,3,'5Extended Info.','');
                end;
            '1'..'5':if not inp(value(which)) then
                       sprint('|wNo change.')
                     else
                       changed:=true;
          end; {case}
        until (which='Q') or (hangup);

        nl;
        if (changed) and (pynq('Save changes')) then
        begin
          bbs.bbsdate:=date;
          seek(bbsf,c);
          write(bbsf,bbs);
          sysoplog('Modified BBS list: '+bbs.name);
        end;

      end;
      close(bbsf);
    end;
  end;

  procedure delete_bbs;
  var c:integer;
  begin
    SetFileAccess(ReadWrite,DenyNone);
    {$I-} reset(bbsf); {$I+}

    if ioresult<>0 then
      sprint('|wNo BBSs found to delete.')
    else
    begin
      nl;
      nl;

      repeat
        prt('Delete which entry (1-'+cstr(filesize(bbsf))+'): ');
        inu(c);
      until ((c in [1..filesize(bbsf)]) or (c=0)) or (hangup);

      if (c<>0) then
      begin
        dec(c);
        seek(bbsf,c);
        read(bbsf,bbs);
        nl;
        showbbs(TRUE,0);
        if pynq('Delete this entry') then
        begin
          sysoplog('Deleted from BBS list: '+bbs.name);
          if (filesize(bbsf)>1) then
          begin
            ii:=0;
            iii:=0;
            while (ii<filesize(bbsf)) do
            begin
              seek(bbsf,ii);
              read(bbsf,bbs);
              if (ii<>c) then
                if (ii=iii) then
                  inc(iii)
                else
                begin
                  seek(bbsf,iii);
                  write(bbsf,bbs);
                  inc(iii);
                end;
              inc(ii);
            end;
            seek(bbsf,iii);
            truncate(bbsf);
          end else
          begin
            close(bbsf);
            erase(bbsf);
            exit;
          end;
        end;
      end;
      close(bbsf);
    end;
  end;

begin
  assign(bbsf,systat^.datapath+'BBSLIST.DAT');
  m1:=allcaps(m1);

  if m1='A' then
    add_bbs
  else
  if m1='L' then
    list_bbs
  else
  if m1='M' then
    modify_bbs
  else
  if m1='D' then
    delete_bbs;
end;

end.
