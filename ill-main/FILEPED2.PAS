{ FILEP Menu Editor }
{$A+,B+,D-,F+,I+,L+,O+,R-,S-,V-}
unit FilePEd2;

interface

uses
  Crt,   Dos,
  common, common3,
  MRec,
  Fmenu2;

Function Ninput(x,y:byte; s:string; len:integer):String;
procedure memm(scurmenu:astr; var menuchanged:boolean);

implementation


procedure infield1(x,y:byte; var s:string; len:integer);
Var InputStat:Byte;
Begin
  s:=NInput(X,Y,S,len);
End;

procedure infielde(var s:string; len:byte);
begin
  infield1(wherex,wherey,s,len);
end;

Function Ninput(x,y:byte; s:string; len:integer):String;
Begin
   ninput:='';
   ansig(x,y);
   infielde(s,len);
   if (s=' ') then if pynq('Set string to Null?') then s:='';
   ninput:=s;
end;

procedure instring(var v:astr; len:integer);
var changed:boolean;
begin
   if (incom) then inputwnwc(v,len,changed)
   else v:=NInput(WhereX,WhereY,v,len);
end;

procedure memm(scurmenu:astr; var menuchanged:boolean);
var xpnt,ypnt,i1,i2,ii,z:integer;
    c:char;
    s:astr;
    b:byte;
    redraw,bb:boolean;

begin
   prompt('Begin editing at which? (1-'+cstr(noc)+') : '); inu(ii);
   c:=' ';
   if (ii>=1) and (ii<=noc) then begin
      while (c<>'Q') and (not hangup) do begin
         repeat
            with cmdr2[ii] do begin
               if (c<>'?') then begin
                  cls;
                  sprint('|cþ |09'+scurmenu); nl;
                  sprint('|WC|wommand '+cstr(ii)+' of '+cstr(noc)+'|LF');
                  if (pulldown in menur2.menuflags) then begin
                     sprint('|W[|c1|W] N|wormal Text   :'+ldesc);
                     sprint('|W[|c2|W] H|wighlighted   :'+sdesc);
                     sprint('|W[|cX|W] X|w Coordinate  :'+xpoint);
                     sprint('|W[|cY|W] Y|w Coordinate  :'+ypoint);
                  end
                  else begin
                     sprint('|W[|c1|W] L|wong descript :'+ldesc);
                     sprint('|W[|c2|W] S|whort descript:'+sdesc);
                  end;
                  sprint('|W[|c3|W] C|wmd letters   :'+ckeys);
                  sprint('|W[|c4|W] A|wCS required  :"'+acs+'"');
                  sprint('|W[|c5|W] C|wmdkeys       :'+cmdkeys);
                  sprint('|W[|c6|W] C|wString       :'+mstring);
                  s:='';
                  if (pull in commandflags) then s:='(P)ulldown';
                  if (hidden in commandflags) then begin
                     if (s<>'') then s:=s+', ';
                     s:=s+'(H)idden';
                  end;
                  if (unhidden in commandflags) then begin
                     if (s<>'') then s:=s+', ';
                     s:=s+'(U)nhidden';
                  end;
                  if (s='') then s:='None';
                  sprint('|W[|c7|W] F|wlags         :'+s);
                  sprint('|W[|cQ|W] Q|wuit');
               end;
               sprompt('|LF|WMe|wnu Editing |W[|w?/Help|W]|w ');
               onek(c,'Q1234567[]FJL?XY'^M);
               redraw := true;
               nl;
               case c of
                  '1':begin
                     if (pulldown in menur2.menuflags) then print('Normal Text Line:')
                     else print('New long description:');
                     instring(ldesc,70);
                     menuchanged:=true;
                  end;
                  '2':begin
                     if (pulldown in menur2.menuflags) then print('Highlighted Text Line:')
                     else print('New short description: ');
                     instring(sdesc,70);
                     menuchanged:=true;
                  end;
                  'X':if (pulldown in menur2.menuflags) then begin
                     prompt('Command X Point: ');
                     inu(xpnt);
                     cmdr2[ii].xpoint:=cstr(xpnt);
                     menuchanged:=true;
                  end;
                  'Y':if (pulldown in menur2.menuflags) then begin
                     prompt('Command Y Point: ');
                     inu(ypnt);
                     cmdr2[ii].ypoint:=cstr(ypnt);
                     menuchanged:=true;
                  end;
                  '3':begin
                     prompt('New command letters: ');
                     input(s,14);
                     if (s<>'') then begin
                        ckeys:=s;
                        menuchanged:=TRUE;
                     end;
                  end;
                  '4':begin
                     prompt('New ACS: ');
                     inputwn(acs,20,menuchanged);
                  end;
                  '5':begin
                     prompt('New command type: ');
                     input(s,2);
                     if (length(s)=2) then begin
                        cmdkeys:=s;
                        menuchanged:=TRUE;
                     end;
                  end;
                  '6':begin
                     prompt('New CString: ');
                     inputwnwc(mstring,50,menuchanged);
                  end;
                  '7':begin
                     print('(P)ulldown - (H)idden command  -  (U)nhidden command');
                     sprompt('|LF|WC|whoose|W:|w ');
                     onek(c,'QHUP'^M);
                     bb:=menuchanged;
                     menuchanged:=TRUE;
                     case c of
                        'P':if (pull in commandflags) then commandflags:=commandflags-[pull]
                           else commandflags:=commandflags+[pull];
                        'H':if (hidden in commandflags) then commandflags:=commandflags-[hidden]
                           else commandflags:=commandflags+[hidden];
                        'U':if (unhidden in commandflags) then commandflags:=commandflags-[unhidden]
                           else commandflags:=commandflags+[unhidden];
                        else menuchanged:=bb;
                     end;
                     c:=#0;
                  end;
                  '[': if (ii>1) then dec(ii)
                     else c:=' ';
                  ']': if (ii<noc) then inc(ii)
                     else c:=' ';
                  'F': if (ii<>1) then ii:=1
                     else c:=' ';
                  'J':begin
                     prompt('Jump to entry: ');
                     input(s,3);
                     if (value(s)>=1) and (value(s)<=noc) then ii:=value(s)
                     else c:=' ';
                  end;
                  'L':if (ii<>noc) then ii:=noc
                     else c:=' ';
                  '?':;{ee_help;}
               end;
            end;
         until (c in ['Q','[',']','F','J','L']) or (hangup);
      end;
   end;
end;

end.
