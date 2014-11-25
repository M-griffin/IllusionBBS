(****************************************************************************)
(* Illusion BBS - Mail functions [5/?]                                      *)
(****************************************************************************)

Unit Mail5;

{$I MKB.Def}

Interface

uses CRT, Dos, common,
     MiscX,
     Mail1, Mail2, Mail3, Mail4;

procedure quickmail;

Implementation

procedure quickmail;
var s:astr;
    i:integer;
    c:char;
    b:boolean;
begin
  b:=FALSE;
  repeat
    cls;
    sprint('|WQuickMail Menu');
    nl;
    sprint('Current Base: |C%MN |C#%MA');
    nl;
    lcmds(24,3,'[Previous Base',']Next Base');
    lcmds(24,3,'Area Change','KPack Bases');
    lcmds(24,3,'NewScan Messages','Post Message');
    lcmds(24,3,'Read User''s Mail','Scan Messages');
    lcmds(24,3,'WSend Mail','ZSet NewScan');
    nl;
    prt('Command (Q:uit): ');
    onek(c,'[]ASKRWNZPQ');
    writeln; tc(7);
    case c of
      'N':begin macok:=TRUE; nscan(''); macok:=FALSE; end;
      'A':mbasechange(b,'');
      '[':mbasechange(b,'-');
      ']':mbasechange(b,'+');
      'S':begin macok:=TRUE; scanmessages('T'); macok:=FALSE; end;
      'R':begin
            SetFileAccess(ReadWrite,DenyNone);
            reset(uf); seek(uf,1); write(uf,thisuser); close(uf);
            tc(7); write('Enter which user you want to read mail from: '); finduser(s,i);
            usernum:=i;
            SetFileAccess(ReadOnly,DenyNone);
            reset(uf); seek(uf,i); read(uf,thisuser); close(uf);
            readinmacros; readinzscan;
            clrscr;
            macok:=TRUE; ScanForYourMail; macok:=FALSE;
            SetFileAccess(ReadWrite,DenyNone);
            reset(uf); seek(uf,i); write(uf,thisuser); close(uf);
            usernum:=1;
            SetFileAccess(ReadOnly,DenyNone);
            reset(uf); seek(uf,1); read(uf,thisuser); close(uf);
            readinmacros; readinzscan;
          end;
      'W':begin
            SetFileAccess(ReadWrite,DenyNone);
            reset(uf); seek(uf,1); write(uf,thisuser); close(uf);
            sprompt('|wEnter user who is sending mail: '); finduser(s,i);
            writeln;
            if (i<1) then pausescr
            else begin
              usernum:=i;
              SetFileAccess(ReadOnly,DenyNone);
              reset(uf); seek(uf,i); read(uf,thisuser); close(uf);
              readinmacros; readinzscan;
              macok:=TRUE; SendMail(0,''); macok:=FALSE;
              nl; pausescr;
              usernum:=1;
              SetFileaccess(ReadOnly,DenyNone);
              reset(uf); seek(uf,1); read(uf,thisuser); close(uf);
              readinmacros; readinzscan;
            end;
          end;
      'P':begin
            macok:=TRUE; post(0,'','',0); macok:=FALSE;
          end;
      'K':{packmessagebases};
      'Z':ConfigZScan;
    end;
    if c in ['N','S','M','P','K','!'] then pausescr;
  until (c='Q') or (hangup);
  reset(uf); seek(uf,1); write(uf,thisuser); close(uf);
end;

end.
