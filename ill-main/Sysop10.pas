(*****************************************************************************)
(* Illusion BBS - SysOp routines  [10/11] (voting editor, result output)     *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop10;

interface

uses
  crt, dos,
  common;

procedure initvotes;
procedure voteprint;

implementation

procedure voteprint;
var vdata:file of vdatar;
    vd:vdatar;
    user:userrec;
    t:text;
    vn,i1,i2:integer;
    sr:smalrec;
begin
  assign(t,systat^.textpath+'VOTES.TXT');
  rewrite(t);
  writeln(t);
  writeln(t,'Votes as of '+dat);
  print('Beginning output to file "VOTES.TXT"');
  i1:=1;
  setfileaccess(readonly,denynone);
  reset(uf);
  assign(vdata,systat^.datapath+'VOTING.DAT');
  setfileaccess(readonly,denynone);
  reset(vdata);
  setfileaccess(readonly,denynone);
  reset(sf);
  for vn:=1 to filesize(vdata) do
  begin
    seek(vdata,vn-1);
    read(vdata,vd);
    if (vd.numchoices<>0) then
    begin
      writeln(t);
      writeln(t,vd.question);
      print('  '+vd.question);
      for i1:=0 to vd.numchoices-1 do
      begin
        writeln(t,'   '+vd.choices[i1].ans[1]);
        if (vd.choices[i1].ans[2]<>'') then
          writeln(t,'   '+vd.choices[i1].ans[2]);
        for i2:=1 to filesize(sf)-1 do
        begin
          seek(sf,i2);
          read(sf,sr);
          seek(uf,sr.number);
          read(uf,user);
          if (user.vote[vn]=i1+1) then
            writeln(t,'      '+caps(sr.name)+' #'+cstr(sr.number));
        end;
      end;
    end;
  end;
  close(sf);
  close(uf);
  close(t);
  close(vdata);
  print('Output complete.');
  sysoplog('* Outputted voting results');
end;

procedure initvotes;
const v1:astr='Packing voting data...';
      v2:astr='Packing voting results...';
var vdata:file of vdatar;
    vd:vdatar;
    abort,next:boolean;
    c:char;
    ii:integer;
    i,j:word;
    u1:userrec;

  procedure modqs(r:byte);
  var i,j:word;
      s:astr;

    procedure resetq(r:byte);
    var i:word;
    begin
      if pynq('|LF|wReset responses') then
      begin
        sprompt('|LFResetting...');
        setfileaccess(readwrite,denynone);
        reset(uf);
        for i:=1 to filesize(uf)-1 do
        begin
          seek(uf,i);
          read(uf,u1);
          u1.vote[r]:=0;
          seek(uf,i);
          write(uf,u1);
        end;
        close(uf);
        thisuser.vote[r]:=0;
        with vd do
        begin
          numvoted:=0;
          for i:=0 to maxvoteas do
            choices[i].numvoted:=0;
        end;
      end;
    end;

    procedure inpln(r:byte);
    var a,b:boolean;
    begin
      sprompt('Line 1: ');
      inputed(vd.choices[r].ans[1],65,'O');
      sprompt('Line 2: ');
      inputed(vd.choices[r].ans[2],65,'O');
    end;

  begin
    c:=#0;
    cls;
    repeat
      seek(vdata,r-1);
      read(vdata,vd);
      if (c in [#0,^M,'[',']',' ','R']) then
      begin
        if (c in [#0,^M,' ','R']) then cls;
        ansig(1,1);
        sprint('|WVoting Topic Editor ['+cstr(r)+'/'+cstr(filesize(vdata))+']|LC');
        nl;
        sprompt('|K[|C1|K] |cQuestion          |w'+vd.question); sprint('|LC');
        sprompt('|K[|C2|K] |cAccess to vote    |w'+vd.voteacs); sprint('|LC');
        sprompt('|K[|C3|K] |cAdded by          |w'+vd.addedby); sprint('|LC');
        sprompt('|K[|C4|K] |cAcs to add choice |w'+vd.addacs); sprint('|LC');
        nl;
        sprint('|K[|CR|K] |cReset voting');
        sprint('|K[|CSpace|K] |cEdit choices');
        nl;
        sprompt('|wCommand |K[|C[|K/|C]|K/|CQ|c:uit|K] |W');
      end;
      ansig(21,11);
      sprompt(#32+^H+'|W');
      onek(c,'1234QR[] '^M);
      case c of
        '1':inputxy(23,3,vd.question,56);
        '2':inputxy(23,4,vd.voteacs,20);
        '3':inputxy(23,5,vd.addedby,35);
        '4':inputxy(23,6,vd.addacs,20);
        'R':resetq(r);
        '[':if (r>1) then
              dec(r)
            else
              r:=filesize(vdata);
        ']':if (r<filesize(vdata)) then
              inc(r)
            else
              r:=1;
        ' ':begin
              c:=#0;
              repeat
                cls;
                sprint('|w#   Answer choice');
                sprint('|K|LI');
                abort:=false; next:=false;
                if vd.numchoices>0 then
                  for i:=0 to vd.numchoices-1 do
                  begin
                    printacr('|W'+mln(cstr(i),4)+'|w'+vd.choices[i].ans[1],abort,next);
                    if (vd.choices[i].ans[2]<>'') then
                      printacr('    |w'+vd.choices[i].ans[2],abort,next);
                  end;
                sprint('|K|LI');
                sprompt('|wVoting Choice Editor |K[|CD|c:elete|K/|CI|c:nsert|K/|CE|c:dit|K/|CQ|c:uit|K] |W');
                onek(c,'QDIE'^M);
                nl;
                case c of
                  'E':if (vd.numchoices>0) then
                      begin
                        sprompt('|wEdit choice |K[|C0|c-|C'+cstr(vd.numchoices)+'|K] |W');
                        input(s,3);
                        nl;
                        if (value(s)>=0) and (value(s)<=vd.numchoices) then inpln(value(s));
                      end else
                        sprompt('|RNothing to edit!|LF|PA');
                  'I':if (vd.numchoices<maxvoteas) then
                      begin
                        sprompt('|wInsert before |K[|C0|c-|C'+
                          aonoff(vd.numchoices>0,cstr(vd.numchoices),'0')+'|K] |W');
                        input(s,3);
                        if ((vd.numchoices=0) and (value(s)=0)) or
                          ((vd.numchoices>0) and (value(s)>=0) and (value(s)<=vd.numchoices)) then
                        begin
                          nl;
                          sprint(v1);
                          if (value(s)<=vd.numchoices) then
                            for i:=vd.numchoices downto value(s) do
                              vd.choices[i+1]:=vd.choices[i];
                          fillchar(vd.choices[value(s)],sizeof(vd.choices[value(s)]),#0);
                          sprint(v2);
                          setfileaccess(readwrite,denynone);
                          reset(uf);
                          for i:=1 to filesize(uf)-1 do
                          begin
                            seek(uf,i);
                            read(uf,u1);
                            if (u1.vote[r]>=value(s)+1) and (u1.vote[r]<>0) then
                            begin
                              inc(u1.vote[r]);
                              seek(uf,i);
                              write(uf,u1);
                            end;
                          end;
                          close(uf);
                          if (thisuser.vote[r]>=value(s)+1) and (thisuser.vote[r]<>0) then
                            inc(thisuser.vote[r]);
                          nl;
                          inpln(value(s));
                          inc(vd.numchoices);
                        end;
                      end else
                        sprompt('|RMaximum number of choices reached.|LF|PA');
                  'D':if (vd.numchoices>0) then
                      begin
                        sprompt('|wDelete choice |K[|C0|c-|C'+cstr(vd.numchoices-1)+'|K] |W');
                        input(s,3);
                        j:=value(s);
                        if (j>=0) and (j<=vd.numchoices-1) then
                        begin
                          nl;
                          sprint(v1);
                          if (value(s)<vd.numchoices-1) then
                            for i:=value(s) to vd.numchoices-1 do
                              vd.choices[i]:=vd.choices[i+1];
                          dec(vd.numchoices);
                          sprint(v2);
                          setfileaccess(readwrite,denynone);
                          reset(uf);
                          for i:=1 to filesize(uf)-1 do
                          begin
                            seek(uf,i);
                            read(uf,u1);
                            if (u1.vote[r]>=j+1) then
                            begin
                              if (u1.vote[r]>j+1) then
                                dec(u1.vote[r])
                              else
                                u1.vote[r]:=0;
                              seek(uf,i);
                              write(uf,u1);
                            end;
                          end;
                          close(uf);
                          if (thisuser.vote[r]>value(s)+1) then
                            dec(thisuser.vote[r])
                          else
                          if (thisuser.vote[r]=value(s)+1) then
                            thisuser.vote[r]:=0;
                        end;
                      end else
                        sprompt('|RNothing to delete!|LF|PA');
                end; {case}
                if (pos(c,'MID1')<>0) then resetq(r);
              until c='Q';
              c:=#0;
            end;
      end;
      if not (c in ['[',']']) then
      begin
        seek(vdata,r-1);
        write(vdata,vd);
      end;
    until (c='Q') or (hangup);
    c:=#0;
  end;

begin

  assign(vdata,systat^.datapath+'VOTING.DAT');
  setfileaccess(readwrite,denynone);
  reset(vdata);
  repeat
    cls;
    abort:=false; next:=false;
    sprint('|w#   Question');
    sprint('|K|LI');
    seek(vdata,0);
    ii:=0;
    while (not eof(vdata)) and (not abort) do
    begin
      inc(ii);
      read(vdata,vd);
      sprint('|W'+mln(cstr(ii),4)+'|w'+vd.question);
      wkey(abort,next);
    end;
    sprint('|K|LI');
    sprompt('|wVoting Booth Editor |K[|CD|c:elete|K/|CI|c:nsert|K/|CE|c:dit|K/|CO|c:utput|K/|CQ|c:uit|K] |W');
    onek(c,'QOIDE'^M);
    nl;
    case c of
      'D':if (filesize(vdata)>0) then
          begin
            sprompt('|wDelete question |K[|C1|c-|C'+cstr(filesize(vdata))+'|K] |W');
            inu(ii);
            if (not badini) and (ii>0) and (ii<=filesize(vdata)) then
            begin
              seek(vdata,ii-1);
              read(vdata,vd);
              sysoplog('* Deleted topic: '+vd.question);
              sprint(v1);
              if filesize(vdata)>1 then
                for i:=ii-1 to filesize(vdata)-2 do
                begin
                  seek(vdata,i+1);
                  read(vdata,vd);
                  seek(vdata,i);
                  write(vdata,vd);
                end;
              seek(vdata,filesize(vdata)-1);
              truncate(vdata);
              sprint(v2);
              setfileaccess(readwrite,denynone);
              reset(uf);
              for i:=1 to filesize(uf)-1 do
              begin
                seek(uf,i);
                read(uf,u1);
                for j:=ii to maxvoteqs-1 do
                  u1.vote[j]:=u1.vote[j+1];
                seek(uf,i);
                write(uf,u1);
              end;
              close(uf);
              for i:=ii to maxvoteqs-1 do
                thisuser.vote[i]:=thisuser.vote[i+1];
            end;
          end else
            sprint('|RNothing to delete!|LF|PA');

      'I':if (filesize(vdata)<maxvoteqs) then
          begin
            sprompt('|wInsert before |K['+
              aonoff(filesize(vdata)>0,'|C1|c-|C'+cstr(filesize(vdata)+1),'|C0|c-|C0')+'|K] |W');
            inu(ii);
            if (not badini) and (((filesize(vdata)=0) and (ii=0)) or
              ((filesize(vdata)>0) and (ii>0) and (ii<=filesize(vdata)+1))) then
            begin
              sysoplog('* Inserted new voting topic');
              sprint(v1);
              if (ii>0) and (ii<=filesize(vdata)) then
                for i:=filesize(vdata)-1 downto ii-1 do
                begin
                  seek(vdata,i);
                  read(vdata,vd);
                  write(vdata,vd);
                end;
              fillchar(vd,sizeof(vd),#0);
              vd.question:='[ New Voting Topic ]';
              vd.addedby:=caps(thisuser.name);
              vd.voteacs:='VV';
              vd.addacs:='%';
              if (filesize(vdata)=0) then
                ii:=1;
              seek(vdata,ii-1);
              write(vdata,vd);
              sprint(v2);
              setfileaccess(readwrite,denynone);
              reset(uf);
              for i:=1 to filesize(uf)-1 do
              begin
                seek(uf,i);
                read(uf,u1);
                for j:=maxvoteqs downto ii+1 do
                  u1.vote[j]:=u1.vote[j-1];
                u1.vote[ii]:=0;
                seek(uf,i);
                write(uf,u1);
              end;
              close(uf);
              for i:=maxvoteqs downto ii+1 do
                thisuser.vote[i]:=thisuser.vote[i-1];
              thisuser.vote[ii]:=0;
            end;
          end else
            sprint('|RMaximum number of questions reached.|LF|PA');

      'E':if (filesize(vdata)>0) then
          begin
            sprompt('|wEdit question |K[|C1|c-|C'+cstr(filesize(vdata))+'|K] |W');
            inu(ii);
            if (not badini) and (ii>0) and (ii<=filesize(vdata)) then
              modqs(ii);
          end else
            sprint('|RNothing to modify!|LF|PA');

      'O':begin
            if (pynq('Output voting results to VOTES.TXT')) then
            begin
              nl;
              voteprint;
              nl;
              if (pynq('View VOTES.TXT')) then
              begin
                printf('VOTES.TXT');
                pausescr;
              end;
            end;
          end;

    end;

  until (c='Q') or (hangup);

  close(vdata);
end;

end.
