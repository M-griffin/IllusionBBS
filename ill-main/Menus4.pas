(*****************************************************************************)
(* Illusion BBS - Menu routines  [4/4]                                       *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit menus4;

interface

uses
  crt, dos,
  common;

procedure autovalidationcmd(pw:astr);

implementation

procedure autovalidationcmd(pw:astr);
var s:astr;
    ok:boolean;
begin
  nl;
  if (pw='') then begin
    sysoplog('[> Auto-Validation command executed - No PW specified!  Nothing done.');
    print('Sorry; this function is not available at this time.');
    exit;
  end;
  if (thisuser.sl=systat.autosl[1]) and (thisuser.dsl=systat.autodsl[1]) and
     (thisuser.ar=systat.autoar1) then begin
    sysoplog('[> Already validated user executed Auto-Validation command');
    print('You''ve already been validated!  You do not need to use this command.');
    exit;
  end;

  print('Note (or warning, if you prefer):');
  print('The SysOp Log records ALL usage of this command.');
  print('Press <Enter> to abort.');
  nl;
  prt('Password: '); mpl(50); input(s,50);
  if (s='') then sprint('|RFunction aborted.'^G)
  else begin
    ok:=(s=allcaps(pw));
    if (not ok) then begin
      sysoplog('[> User entered wrong password for Auto-Validation: "'+s+'"');
      sprint('|RWrong!'^G);
    end else begin
      sysoplog('[> User correctly entered Auto-Validation password.');
      autovalidate('1',thisuser,usernum);
      topscr; commandline('User Validated (With Profile 1).');
      printf('autoval');
      if (nofile) then begin
        nl;
        print('Correct.  You are now validated.');
      end;
    end;
  end;
end;

end.
