(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2l/11] (Conference config)                *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2l;

interface

uses
  crt, dos,
  common;

procedure poconf;

implementation

procedure poconf;
var c,c1:char;
    conf:confrrec;
    conff:file of confrrec;
    abort,next:boolean;
    ii:word;
begin
  assign(conff,systat^.datapath+'CONF.DAT');
  setfileaccess(readwrite,denynone);
  reset(conff);
  repeat
    cls;
    abort:=false; next:=false;
    sprint('|wChar Name                                     ACS');
    sprint('|K|LI');
    seek(conff,0);
    ii:=64;
    while (not eof(conff)) and (not abort) do
    begin
      read(conff,conf);
      if (conf.active) then
        sprint('|W'+mln(chr(ii),5)+mln(conf.name,40)+' |w'+conf.acs);
      wkey(abort,next);
      inc(ii);
    end;
    sprint('|K|LI');
    sprompt('|wConference Editor |K[|CD|c:elete|K/|CI|c:nsert|K/|CE|c:dit|K/|CQ|c:uit|K] |W');
    onek(c,'QIDE'^M);
    nl;
    case c of
      'D':begin
            sprompt('|wDelete conference |K[|CA-Z|K] |W');
            onek(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
            if (c<>^M) then
            begin
              seek(conff,ord(c)-64);
              read(conff,conf);
              if (conf.active) then
              begin
                fillchar(conf,sizeof(conf),#0);
                seek(conff,ord(c)-64);
                write(conff,conf);
              end else
                sprint('|RConference does not exist!|LF|PA');
            end;
            c:=#0;
          end;
      'I':begin
            sprompt('|wInsert conference |K[|CA-Z|K] |W');
            onek(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
            if (c<>^M) then
            begin
              seek(conff,ord(c)-64);
              read(conff,conf);
              if (not conf.active) then
              begin
                conf.active:=true;
                conf.name:='New conference';
                seek(conff,ord(c)-64);
                write(conff,conf);
              end else
                sprint('|RConference already exists!|LF|PA');
            end;
            c:=#0;
          end;
      'E':begin
            sprompt('|wEdit conference |K[|C@|c,|CA-Z|K] |W');
            onek(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ@'^M);
            if (c<>^M) then
            begin
              c1:=c;
              seek(conff,ord(c1)-64);
              read(conff,conf);
              if (conf.active) then
              begin
                c:=#0;
                repeat
                  if (c in [#0,^M,'[',']']) then
                  begin
                    cls;
                    sprint('|WConference Editor ['+c1+'/Z]');
                    nl;
                    sprint('|K[|CA|K] |cConference name  |w'+conf.name);
                    sprint('|K[|CB|K] |cRequired access  |w'+conf.acs);
                    nl;
                    sprompt('|wCommand |K[|C[|K/|C]|K/|CQ|c:uit|K] |W');
                  end;
                  ansig(21,6);
                  sprompt(#32+^H+'|W');
                  onek(c,'QAB[]'^M);
                  case c of
                    'A':inputxy(22,3,conf.name,40);
                    'B':if (c1='@') then
                        begin
                          sprint('|LF|RCannot edit global conference!|LF|PA');
                          c:=#0;
                        end else
                          inputxy(22,4,conf.acs,20);
                    '[':begin
                          if (c1='@') then
                            c1:='Z'
                          else
                            c1:=chr(ord(c1)-1);
                          seek(conff,ord(c1)-64);
                          read(conff,conf);
                          while (not conf.active) do
                          begin
                            if (c1='@') then
                              c1:='Z'
                            else
                              c1:=chr(ord(c1)-1);
                            seek(conff,ord(c1)-64);
                            read(conff,conf);
                          end;
                        end;
                    ']':begin
                          if (c1='Z') then
                            c1:='@'
                          else
                            c1:=chr(ord(c1)+1);
                          seek(conff,ord(c1)-64);
                          read(conff,conf);
                          while (not conf.active) do
                          begin
                            if (c1='Z') then
                              c1:='@'
                            else
                              c1:=chr(ord(c1)+1);
                            seek(conff,ord(c1)-64);
                            read(conff,conf);
                          end;
                        end;
                  end;
                  if (c in ['A'..'B']) then
                  begin
                    seek(conff,ord(c1)-64);
                    write(conff,conf);
                  end;
                until (c='Q') or (hangup);
              end else
                sprint('|RConference does not exist!|LF|PA');
            end;
            c:=#0;
          end;
    end;
  until ((c='Q') or (hangup));
  close(conff);
end;

end.
