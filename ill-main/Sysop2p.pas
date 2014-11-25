(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2p/11] (protocol editor)                  *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2p;

interface

procedure poproedit;

implementation

uses
  crt, dos,
  common;

procedure poproedit;
var ii,xloaded:integer;
    c:char;
    abort,next:boolean;

  procedure xed(ii:integer);
  var x:integer;
  begin
    if (ii>=0) and (ii<=filesize(xf)-1) then
    begin
      if (ii>=0) and (ii<filesize(xf)-1) then
        for x:=ii to filesize(xf)-2 do
        begin
          seek(xf,x+1); read(xf,protocol);
          seek(xf,x); write(xf,protocol);
        end;
      seek(xf,filesize(xf)-1);
      truncate(xf);
    end;
  end;

  function newindexno:longint;
  var xpr:^protrec;
      i,j:integer;
  begin
    SetFileAccess(ReadWrite,DenyNone);
    reset(xf);
    j:=-1;
    new(xpr);
    for i:=1 to filesize(xf) do
    begin
      read(xf,xpr^);
      if (xpr^.permindx>j) then j:=xpr^.permindx;
    end;
    dispose(xpr);
    inc(j);
    newindexno:=j;
  end;

  procedure xei(ii:integer);
  var x:integer;
  begin
    if (ii>=0) and (ii<=filesize(xf)) and (filesize(xf)<maxprotocols) then
    begin
      for x:=filesize(xf)-1 downto ii do
      begin
        seek(xf,x);
        read(xf,protocol);
        write(xf,protocol);
      end;
      with protocol do
      begin
        xbstat:=[xbxferokcode];
        ckeys:='x';
        descr:='(x) New Protocol';
        acs:='';
        templog:='';
        ulcmd:='QUIT'; dlcmd:='QUIT';
        for x:=1 to 6 do begin ulcode[x]:=''; dlcode[x]:=''; end;
        envcmd:='';
        dlflist:='';
        logpf:=0; logps:=0;
        permindx:=newindexno;
      end;
      seek(xf,ii);
      write(xf,protocol);
    end;
  end;

  function substone(src,old,new:astr):astr;
  var p:integer;
  begin
    p:=pos(old,src);
    if (p>0) then begin
      insert(new,src,p+length(old));
      delete(src,p,length(old));
    end;
    substone:=src;
  end;

  procedure xem;
  var s:astr;
      j,ii:integer;
      c:char;
      b,hadpause:boolean;
  begin
    xloaded:=-1;
    sprompt('|wEdit protocol |K[|C0|c-|C'+cstr(filesize(xf)-1)+'|K] |W');
    inu(ii);
    hadpause:=(pause in thisuser.ac);
    if hadpause then exclude(thisuser.ac,pause);
    if (not badini) and (ii>=0) and (ii<=filesize(xf)-1) then
    begin
      cls;
      c:=#0;
      while (c<>'Q') and (not hangup) do
      begin
        if (xloaded<>ii) then
        begin
          seek(xf,ii);
          read(xf,protocol);
          xloaded:=ii;
          c:=#0;
        end;
        with protocol do
          repeat
            if (c in [#0,^M]) then
            begin
              ansig(1,1);
              sprint('|WProtocol Editor ['+cstr(ii)+'/'+cstr(filesize(xf)-1)+']|LC');
              nl;
              sprint('|K[|CA|K] |cActive protocol     |w'+mln(syn(xbactive in xbstat),14)+
                    ' |K[|C1|K] |cBatch protocol      |w'+syn(xbisbatch in xbstat)+' ');
              sprint('|K[|CB|K] |cCommand key         |w'+mln(ckeys,14)+
                    ' |K[|C2|K] |cResume protocol     |w'+syn(xbisresume in xbstat)+' ');
              sprint('|K[|CC|K] |cDescription         |w'+descr+'|LC');
              sprint('|K[|CD|K] |cAccess required     |w'+acs+'|LC');
              sprint('|K[|CE|K] |cTemporary log file  |w'+templog+'|LC');
              sprint('|K[|CF|K] |cFilename position   |w'+cstr(logpf)+'|LC');
              sprint('|K[|CG|K] |cCode position       |w'+cstr(logps)+'|LC');
              sprint('|K[|CH|K] |cReceive command     |w'+ulcmd+'|LC');
              sprint('|K[|CI|K] |cSend command        |w'+dlcmd+'|LC');
              sprint('|K[|CJ|K] |cDL batch list file  |w'+dlflist+'|LC');
              sprint('|K[|CK|K] |cEnvironment command |w'+envcmd+'|LC');
              sprint('|K[|CL|K] |cResult codes mean   |w'+
                     aonoff(xbxferokcode in xbstat,'Transfer successful','Transfer unsuccessful')+'|LC');
              for j:=1 to 4 do
                sprint('|K[|C'+chr(j+76)+'|K] |cReceive code #'+mln(cstr(j),6)+'|w'+mln(ulcode[j],15)+
                       '|K[|C'+chr(j+83)+'|K] |cSend code #'+mln(cstr(j),9)+'|w'+dlcode[j]+'|LC');
              sprint('|K[|CR|K] |cReceive code #5|w     '+mln(ulcode[5],15)+
                     '|K[|CX|K] |cSend code #5|w        '+dlcode[5]+'|LC');
              sprint('|K[|CS|K] |cReceive code #6|w     '+mln(ulcode[6],15)+
                     '|K[|CY|K] |cSend code #6|w        '+dlcode[6]+'|LC');
              nl;
              sprompt('|wCommand |K[|C[|K/|C]|K/|CQ|c:uit|K] |W');
            end;
            ansig(21,22);
            sprompt(#32+^H+'|W');
            onek(c,'QABCDEFGHIJKLMNOPRSTUVWXY12[]'^M);
            case c of
              'A':begin
                    b:=xbactive in xbstat;
                    if (b) then exclude(xbstat,xbactive)
                           else include(xbstat,xbactive);
                    switchyn(25,3,b);
                  end;
              '1':begin
                    b:=xbisbatch in xbstat;
                    if (b) then exclude(xbstat,xbisbatch)
                           else include(xbstat,xbisbatch);
                    switchyn(64,3,b);
                  end;
              '2':begin
                    b:=xbisresume in xbstat;
                    if (b) then exclude(xbstat,xbisresume)
                           else include(xbstat,xbisresume);
                    switchyn(64,4,b);
                  end;
              'B':inputxy(25,4,ckeys,14);
              'C':begin
                    inputxy(25,5,descr,40);
                    ansig(25,5);
                    sprompt(descr+'|LC');
                  end;
              'D':inputxy(25,6,acs,20);
              'E':inputxy(25,7,templog,25);
              'F':logpf:=inputnumxy(25,8,logpf,5,0,32767);
              'G':logps:=inputnumxy(25,9,logps,5,0,32767);
              'H':inputxy(25,10,ulcmd,55);
              'I':inputxy(25,11,dlcmd,55);
              'J':inputxy(25,12,dlflist,25);
              'K':inputxy(25,13,envcmd,55);
              'L':begin
                    b:=xbxferokcode in xbstat;
                    if (b) then exclude(xbstat,xbxferokcode)
                           else include(xbstat,xbxferokcode);
                    ansig(25,14);
                    sprompt('|w'+aonoff(xbxferokcode in xbstat,'Transfer successful','Transfer unsuccessful')+'|LC');
                  end;
              'M'..'P':inputxy(25,ord(c)-76+14,ulcode[ord(c)-76],6);
              'R':inputxy(25,19,ulcode[5],6);
              'S':inputxy(25,20,ulcode[6],6);
              'T'..'Y':inputxy(64,ord(c)-83+14,dlcode[ord(c)-83],6);
              '[':if (ii>0) then dec(ii) else ii:=filesize(xf)-1;
              ']':if (ii<filesize(xf)-1) then inc(ii) else ii:=0;
            end;
          until (pos(c,'Q[]')<>0) or (hangup);
        seek(xf,xloaded);
        write(xf,protocol);
      end;
    end;
    if hadpause then include(thisuser.ac,pause);
  end;

  procedure xep;
  var i,j,k:integer;
  begin
    sprompt('|wMove protocol |K[|C0|c-|C'+cstr(filesize(xf)-1)+'|K] |W');
    inu(i);
    if ((not badini) and (i>=0) and (i<=filesize(xf)-1)) then
    begin
      sprompt('|wMove before |K[|C0|c-|C'+cstr(filesize(xf))+'|K] |W');
      inu(j);
      if ((not badini) and (j>=0) and (j<=filesize(xf)) and
          (j<>i) and (j<>i+1)) then
      begin
        xei(j);
        if (j>i) then k:=i else k:=i+1;
        seek(xf,k); read(xf,protocol);
        seek(xf,j); write(xf,protocol);
        if (j>i) then xed(i) else xed(i+1);
      end;
    end;
  end;

begin
  SetFileAccess(ReadWrite,DenyNone);
  reset(xf); xloaded:=-1; c:=#0;
  repeat
    abort:=FALSE; next:=FALSE;
    cls;
    sprint('|w#   Active ACS       Description');
    sprint('|K|LI');
    ii:=0;
    seek(xf,0);
    while (ii<=filesize(xf)-1) and (not abort) and (not hangup) do
    begin
      read(xf,protocol);
      with protocol do
      begin
        sprint('|W'+mn(ii,3)+' |w'+mln(syn(xbactive in xbstat),7)+
               ''+mln(acs,10)+'|w'+descr);
        wkey(abort,next);
        inc(ii);
      end;
    end;
    sprint('|K|LI');
    sprompt('|wProtocol Editor |K[|CD|c:elete|K/|CI|c:nsert|K/|CE|c:dit|K/|CM|c:ove|K/|CQ|c:uit|K] |W');
    onek(c,'QDIEM'^M);
    case c of
      'D':begin
            sprompt('Delete protocol |K[|C0|c-|C'+cstr(filesize(xf)-1)+'|K] |W');
            inu(ii);
            seek(xf,ii); read(xf,protocol);
            sysoplog('* Deleted protocol: '+protocol.descr);
            xed(ii);
          end;
      'I':begin
            sprompt('|wInsert before |K[|C0|c-|C'+cstr(filesize(xf))+'|K] |W');
            inu(ii);
            sysoplog('* Inserted new protocol');
            xei(ii);
          end;
      'E':xem;
      'M':xep;
    end;
  until (c='Q') or (hangup);
  close(xf);
end;

end.
