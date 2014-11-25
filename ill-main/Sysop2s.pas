(*****************************************************************************)
(* Illusion BBS - SysOp functions [2s/11] (rumor editor)                     *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2s;

interface

uses
  crt, dos,
  common;

procedure porumoredit;

implementation

procedure porumoredit;
var f:file of rumorrec;
    r:rumorrec;
    current,ii:integer; c:char;
begin
  assign(f,systat^.datapath+'RUMOR.DAT');
  setfileaccess(readwrite,denynone);
  reset(f);
  if (filesize(f)<1) then current:=0 else current:=1;
  c:=#0;
  repeat
    if current<1 then
    begin
      nl;
      sprint('No rumors found to edit.');
      pausescr;
      close(f);
      exit;
    end;
    if (c in [#0,^M]) then cls;
    ansig(1,1);
    sprint('|WRumor Editor ['+cstr(current)+'/'+cstr(filesize(f))+']|LC'); nl;
    seek(f,current-1);
    read(f,r);
    spromptt('|cTranslated    |w'+r,false,true); sprint('|w|LC');
    sprompt('|cUntranslated  |w'); spromptt(r,false,false); sprint('|w|LC');
    nl;
    sprompt('|wRumor Editor |K[|C[|K/|C]|K/|CD|c:elete|K/|CE|c:dit|K/|CQ|c:uit|K] |W');
    ansig(40,6);
    sprompt(#32+^H+'|W');
    onek(c,'Q[]DE'^M);
    case c of
      '[':begin
            dec(current);
            if current<1 then current:=filesize(f);
          end;
      ']':begin
            inc(current);
            if current>filesize(f) then current:=1;
          end;
      'D':begin
            sysoplog('* Deleted: '+r);
            for ii:=current-1 to filesize(f)-2 do
            begin
              seek(f,ii+1); read(f,r);
              seek(f,ii); write(f,r);
            end;
            seek(f,filesize(f)-1); truncate(f);
            if current>filesize(f) then current:=filesize(f);
          end;
      'E':begin
            inputxy(15,4,r,65);
            if (r<>'') and (r<>' ') then
            begin
              seek(f,current-1);
              write(f,r);
            end;
          end;
    end;
  until (c='Q') or (hangup);
  close(f);
end;

end.
