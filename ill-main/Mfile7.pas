(*****************************************************************************)
(* Illusion BBS - File routines  [7/15] (ascii receive/send)                 *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit Mfile7;

interface

uses
  crt, dos,
  Mfile0, common;

procedure recvascii(fn:astr; var dok:boolean; tpb:real);
procedure sendascii(fn:astr);

implementation

procedure recvascii(fn:astr; var dok:boolean; tpb:real);
var f:file;
    r1:array[0..1023] of byte;
    byte_count,start_time:longint;
    bytes_this_line,kbyte_count,line_count:integer;
    b:byte;
    start,abort,error,done,timeo,kba,prompti,badf:boolean;
    c:char;

    procedure checkkb;
    var c:char;
    begin
      if (keypressed) then begin
        c:=readkey;
        if (c=#27) then begin
          abort:=TRUE; done:=TRUE; kba:=TRUE;
          spstr(403);
        end;
      end;
    end;

begin
  abort:=FALSE; done:=FALSE; timeo:=FALSE; kba:=FALSE; badf:=FALSE;
  line_count:=0; start:=FALSE;
  start_time:=trunc(timer); byte_count:=0;
  assign(f,fn);
  {$I-} rewrite(f,1); {$I+}
  if (ioresult<>0) then begin
    if (useron) then spstr(404);
    done:=TRUE; abort:=TRUE; badf:=TRUE;
  end;
  prompti:=pynq(getstr(405));
  if (useron) then spstr(406);
  while (not done) and (not hangup) do begin
    error:=TRUE;
    checkkb;
    if (kba) then begin
      done:=TRUE;
      abort:=TRUE;
    end;
    if (not kba) then
      if (prompti) then begin
        com_flush_rx;
        sendcom1('>');
      end;
    if (not done) and (not abort) and (not hangup) then begin
      start:=FALSE;
      error:=FALSE;
      checkkb;
      if (not done) then begin
        bytes_this_line:=0;
        repeat
          getkey(c); b:=ord(c);
          if (b=26) then begin
            start:=TRUE; done:=TRUE;
            nl;
            if (useron) then spstr(407);
          end else begin
            if (b<>10) then begin         (* ignore LF *)
              r1[bytes_this_line]:=b;
              bytes_this_line:=bytes_this_line+1;
            end;
          end;
        until (bytes_this_line>250) or (b=13) or (timeo) or (done);
        if (b<>13) then begin
          r1[bytes_this_line]:=13;
          bytes_this_line:=bytes_this_line+1;
        end;
        r1[bytes_this_line]:=10;
        bytes_this_line:=bytes_this_line+1;
        seek(f,byte_count);
        {$I-} blockwrite(f,r1,bytes_this_line); {$I+}
        if (ioresult<>0) then begin
          if (useron) then spstr(408);
          done:=TRUE; abort:=TRUE;
        end;
        inc(line_count);
        byte_count:=byte_count+bytes_this_line;
      end;
    end;
  end;
  if not badf then close(f);
  kbyte_count:=0;
  while (byte_count>1024) do begin
    inc(kbyte_count);
    byte_count:=byte_count-1024;
  end;
  if (byte_count>512) then inc(kbyte_count,1);
  if (hangup) then abort:=TRUE;
  if (abort) then erase(f)
  else begin
    clearwaves;
    addwave('LN',cstr(line_count),txt);
    addwave('KB',cstr(kbyte_count),txt);
    spstr(409);
    clearwaves;
    if (timer<start_time) then start_time:=start_time-24*60*60;
  end;
  dok:=not abort;
end;

procedure sendascii(fn:astr);
var f:file of char;
    i:integer;
    c,c1:char;
    abort:boolean;

  procedure ckey;
  begin
    checkhangup;
    while (not empty) and (not abort) and (not hangup) do begin
      if (hangup) then abort:=TRUE;
      c1:=inkey;
      if (c1=^X) or (c1=#27) or (c1=' ') then abort:=TRUE;
      if (c1=^S) then getkey(c1);
    end;
  end;

begin
  assign(f,fn);
  SetFileAccess(ReadOnly,DenyNone);
  {$I-} reset(f); {$I+}
  if (ioresult<>0) then spstr(382) else begin
    abort:=FALSE;
    spstr(410);
    repeat getkey(c) until (c=^M) or (hangup);
    while (not hangup) and (not abort) and (not eof(f)) do begin
      read(f,c); if (outcom) then sendcom1(c);
      if (c<>^G) then write(c);
      ckey;
    end;
    close(f);
    prompt(^Z);
    spstr(411);
  end;
end;

end.
