(*****************************************************************************)
(* Illusion BBS - SysOp routines  [2k/11] (archive config)                   *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop2k;

interface

uses
  crt, dos,
  common;

procedure poarcconfig;

implementation

function nt(s:string):string;
begin
  if s<>'' then nt:=s else nt:='*None*';
  if copy(s,1,1)='/' then begin
    s:='"'+s+'" - ';
    case s[3] of
      '1':nt:=s+'*Internal* ZIP viewer';
      '2':nt:=s+'*Internal* ARJ viewer';
      '3':nt:=s+'*Internal* ARC/PAK viewer';
      '4':nt:=s+'*Internal* ZOO viewer';
      '5':nt:=s+'*Internal* LZH viewer';
      '6':nt:=s+'*Internal* RAR viewer';
    end;
  end;
end;

function nt2(i:integer):string;
begin
  if i<>-1 then nt2:=cstr(i) else nt2:='-1 (ignores)';
end;

procedure poarcconfig;
const sepr2:string[5]='|B:|C';
var ii,i2,numarcs:integer;
    c:char;
    s:astr;
    bb:byte;
    abort,next,changed:boolean;
begin
  numarcs:=1;
  while (systat^.filearcinfo[numarcs].ext<>'') and (numarcs<9) do
    inc(numarcs);
  dec(numarcs);
  c:=' ';
  while (c<>'Q') and (not hangup) do begin
    repeat
      if c<>'?' then begin
        cls;
        sprint('|WArchive Configuration');
        nl;
        abort:=FALSE; next:=FALSE;
        printacr('|C NN'+sepr2+'Ext'+sepr2+'Compression cmdline      '+
                 sepr2+'Decompression cmdline    '+sepr2+'Success Code',abort,next);
        printacr('|B 컴:컴�:컴컴컴컴컴컴컴컴컴컴컴컴�:컴컴컴컴컴컴컴컴컴컴컴컴�:컴컴컴컴컴컴',abort,next);
        ii:=1;
        while (ii<=numarcs) and (not abort) and (not hangup) do begin
          with systat^.filearcinfo[ii] do begin
            if (active) then s:='|Y+' else s:='|w-';
            s:=s+'|W'+mn(ii,2)+' |C'+mln(ext,3)+' '+
                 '|Y'+mln(arcline,25)+' '+mln(unarcline,25)+' '+
                 nt2(succlevel);
            spromptt(s,FALSE,TRUE); nl; wkey(abort,next);
          end;
          inc(ii);
        end;
        nl;
        for bb:=1 to 3 do begin
          s:=systat^.filearccomment[bb]; if s='' then s:='*None*';
          printacr(cstr(bb)+'. Archive comment: '+s,abort,next);
        end;
      end;
      nl;
      prt('Archive edit (Q:uit,?=help): ');
      onek(c,'Q?DIM123'^M);
      nl;
      case c of
        '?':begin
              sprint('|w<|WCR|w>Redisplay screen');
              sprint('|W1-3|w:Archive comments');
              lcmds(16,3,'Insert archive','Delete archive');
              lcmds(16,3,'Modify archive','Quit and save');
            end;
        'M':begin
              prt('Begin editing at: '); mpl(3); ini(bb);
              if (not badini) and (bb>=1) and (bb<=numarcs) then begin
                i2:=bb;
                while (c<>'Q') and (not hangup) do begin
                  repeat
                    if c<>'?' then begin
                      cls;
                      sprint('|WArchive ['+cstr(i2)+'/'+cstr(numarcs)+']');
                      nl;
                      with systat^.filearcinfo[i2] do begin
                        Sprint('1. Active                 : |C'+syn(active));
                        Sprint('2. Extension name         : |C'+ext);
                        Sprint('3. Interior list method   : |C'+nt(listline));
                        Sprint('4. Compression cmdline    : |C'+nt(arcline));
                        Sprint('5. Decompression cmdline  : |C'+nt(unarcline));
                        Sprint('6. Integrity check cmdline: |C'+nt(testline));
                        Sprint('7. Add comment cmdline    : |C'+nt(cmtline));
                        Sprint('8. Errorlevel for success : |C'+nt2(succlevel));
                      end;
                    end;
                    nl;
                    prt('Edit menu: (1-8,[,],Q:uit): ');
                    onek(c,'Q12345678[]?'^M);
                    nl;
                    case c of
                      '?':begin
                            sprint(' |W#|w:Modify item  <|WCR|w>Redisplay screen');
                            lcmds(14,3,'[Back archive',']Forward archive');
                            lcmds(14,3,'Quit and save','');
                          end;
                      '1'..'8':
                          with systat^.filearcinfo[i2] do
                            case c of
                              '1':active:=not active;
                              '2':begin
                                    prt('New extension: '); mpl(3); input(s,3);
                                    if s<>'' then ext:=s;
                                  end;
                              '3'..'7':
                                  begin
                                    prt('New commandline: '); mpl(25);
                                    inputl(s,25);
                                    if s<>'' then begin
                                      if s=' ' then
                                        if pynq('Set to NULL string') then
                                          s:='';
                                      if s<>' ' then
                                        case c of
                                          '3':listline:=s;
                                          '4':arcline:=s;
                                          '5':unarcline:=s;
                                          '6':testline:=s;
                                          '7':cmtline:=s;
                                        end;
                                    end;
                                  end;
                              '8':begin
                                    prt('New errorlevel: '); mpl(5); inu(ii);
                                    if not badini then
                                      systat^.filearcinfo[i2].succlevel:=ii;
                                  end;
                            end;
                      '[':if i2>1 then dec(i2) else i2:=numarcs;
                      ']':if i2<numarcs then inc(i2) else i2:=1;
                    end;
                  until (c in ['Q','[',']']) or (hangup);
                end;
              end;
              c:=' ';
            end;
        'D':begin
              prt('Delete which: '); mpl(3); ini(bb);
              if (not badini) and (bb in [1..numarcs]) then begin
                nl;
                sprompt('|C'+systat^.filearcinfo[bb].ext);
                if pynq('   Delete it') then begin
                  for i2:=bb to numarcs-1 do
                    systat^.filearcinfo[i2]:=systat^.filearcinfo[i2+1];
                  systat^.filearcinfo[numarcs].ext:='';
                  dec(numarcs);
                end;
              end;
            end;
        'I':if numarcs<>maxarcs then begin
              prt('Insert before which (1-'+cstr(numarcs+1)+'): ');
              mpl(3); ini(bb);
              if (not badini) and (bb in [1..numarcs+1]) then begin
                if bb<>numarcs+1 then
                  for i2:=numarcs+1 downto bb+1 do
                    systat^.filearcinfo[i2]:=systat^.filearcinfo[i2-1];
                with systat^.filearcinfo[bb] do begin
                  active:=FALSE;
                  ext:='AAA';
                  listline:=''; arcline:=''; unarcline:='';
                  testline:=''; cmtline:=''; succlevel:=-1;
                end;
                inc(numarcs);
              end;
            end;
        '1'..'3':
            begin
              bb:=ord(c)-48;
              prt('New comment #'+c+': '); mpl(32);
              inputwnwc(systat^.filearccomment[bb],32,changed);
            end;
      end;
    until (c='Q') or (hangup);
  end;
end;

end.
