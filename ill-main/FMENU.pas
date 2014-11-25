(* File Promt Menu System *)
{$A+,B+,F+,I+,L+,O+,R-,S-,V-,T+}

Unit fmenu;

Interface

Uses
  Crt, Dos, Common, Mrec, FMenu2; 




Procedure mainmenuhandle(var cmd:string);
Procedure domenucommand(var done:boolean; cmd:string; var newmenucmd:string);

Implementation


const numenters : byte = 0;


procedure getcmd(var s:string);
var s1,ss,oss,shas0,shas1:string;
    i:integer;
    c2,c,cc:char;
    oldco:byte;
    gotcmd,has0,has1,has2:boolean;
begin
   s:='';
   if (buf<>'') then if (copy(buf,1,1)='`') then begin
      buf:=copy(buf,2,length(buf)-1);
      i:=pos('`',buf);
      if (i<>0) then begin
         s:=AllCaps(copy(buf,1,i-1));
         buf:=copy(buf,i+1,length(buf)-i);
         nl;
         exit;
      end;
   end;
   shas0:='?';
   shas1:='';
   has0:=FALSE;
   has1:=FALSE;
   has2:=FALSE;
   for i:=1 to noc do if (aacs(cmdr2[i].acs)) then if (cmdr2[i].ckeys[0]=#1) then begin
      has0:=TRUE;
      shas0:=shas0+cmdr2[i].ckeys;
   end
   else if ((cmdr2[i].ckeys[1]='/') and (cmdr2[i].ckeys[0]=#2)) then begin
      has1:=TRUE;
      shas1:=shas1+cmdr2[i].ckeys[2];
   end else has2:=TRUE;
   oldco:=curco;
   gotcmd:=FALSE;
   ss:='';
   if (not (onekey in thisuser.ac)) then input(s,60)
   else begin repeat
      getkey(c2);
      c:=upcase(c2);
      oss:=ss;
      if (ss='') then begin
         if (c=#13) then begin
            gotcmd:=TRUE;
            inc(numenters);
            if (numenters >= 5) then chatcall := false;
         end
         else numenters := 0;
         if ((c='/') and ((has1) or (has2) or (thisuser.sl=255))) then ss:='/';
         if ((c='=') and (cso)) then begin gotcmd:=TRUE; ss:=c; end;
         if (((fqarea) or (mqarea)) and (c in ['0'..'9'])) then ss:=c
         else if (pos(c,shas0)<>0) then begin
            gotcmd:=TRUE;
            ss:=c;
         end;
      end
      else if (ss='/') then begin
         if (c=^H) then ss:='';
         if ((c='/') and ((has2) or (thisuser.sl=255))) then ss:=ss+'/';
         if ((pos(c,shas1)<>0) and (has1)) then begin
            gotcmd:=TRUE;
            ss:=ss+c;
         end;
      end
      else if (copy(ss,1,2)='//') then begin
         if (c=#13) then gotcmd:=TRUE
         else if (c=^H) then ss:=copy(ss,1,length(ss)-1)
         else if (c=^X) then begin
            for i:=1 to length(ss)-2 do prompt(^H' '^H);
            ss:='//';
            oss:=ss;
         end
         else if ((length(ss)<62) and (c>=#32) and (c<=#127)) then ss:=ss+c;
      end else if ((length(ss)>=1) and (ss[1] in ['0'..'9']) and ((fqarea) or (mqarea))) then begin
         if (c=^H) then ss:=copy(ss,1,length(ss)-1);
         if (c=#13) then gotcmd:=TRUE;
         if (c in ['0'..'9']) then begin
            ss:=ss+c;
            if (length(ss)=3) then gotcmd:=TRUE;
         end;
      end;
      if ((length(ss)=1) and (length(oss)=2)) then setc(oldco);
      if (oss<>ss) then begin
         if (length(ss)>length(oss)) then prompt(c2);
         if (length(ss)<length(oss)) then prompt(^H' '^H);
      end;
      if ((not (ss[1] in ['0'..'9'])) and ((length(ss)=2) and (length(oss)=1))) then cl(6);
   until ((gotcmd) or (hangup));
   if (copy(ss,1,2)='//') then ss:=copy(ss,3,length(ss)-2);
   s:=ss;
end;

  {nl;}

  if (pos(';',s)<>0) then                 {* "command macros" *}
    if (copy(s,1,2)<>'\\') then begin
      if (onekey in thisuser.ac) then begin
        s1:=copy(s,2,length(s)-1);
         if (copy(s1,1,1)='/') then s:=copy(s1,1,2) else s:=copy(s1,1,1);
         s1:=copy(s1,length(s)+1,length(s1)-length(s));
      end else begin
        s1:=copy(s,pos(';',s)+1,length(s)-pos(';',s));
        s:=copy(s,1,pos(';',s)-1);
      end;
      while (pos(';',s1)<>0) do s1[pos(';',s1)]:=^M;
      dm(' '+s1,c);
    end;
end;




procedure mainmenuhandle(var cmd:string);
var fb:integer;
    fbnum:array [1..maxuboards] of integer;
    count:byte;
    mb:integer;
    mbnum:array [1..maxuboards] of integer;
    ckey, newarea:integer;
    done, wantshow:boolean;
    newcmd, s:string;

begin

   if (not filemnu) then exit;

   menuactiv:=true;
   for ckey:=1 to noc do begin
      if cmdr2[ckey].ckeys='EVERYTIME' then begin
         done:=true;
         newcmd:='';
         domenucommand(done,cmdr2[ckey].cmdkeys+cmdr2[ckey].mstring,newcmd);
      end;
   end;
   
   If (Pulldown in Menur2.Menuflags) then Begin
      cmd := '';
      DoPulls(cmd);
      MenuActiv:=False;
      Exit;
   End
   else begin
     { If not File Pulldown Menu, Exit !! }
     Exit;
     menuactiv:=false;
   End;
end;


procedure domenucommand(var done:boolean; cmd:string; var newmenucmd:string);
var filvar:text;
   { mheader:mheaderrec; }
    tmp,tmp1,tmp2,cms,s,s1,s2:string;
    l,i:integer;
    ws,cnfc,k,br,c1,c2,c:char;
    dn,abort,next,b,nocmd:boolean;

   function semicmd(x:integer):string;
   var s:string;
       i,p:integer;
   begin
      s:=cms;
      i:=1;
      while (i<x) and (s<>'') do begin
         p:=pos(';',s);
         if (p<>0) then s:=copy(s,p+1,length(s)-p) else s:='';
         inc(i);
      end;
      while (pos(';',s)<>0) do s:=copy(s,1,pos(';',s)-1);
      semicmd:=s;
   end;
   
begin
   newmenutoload:=FALSE;
   newmenucmd:='';
   cnfc:=#0;
   c1:=cmd[1];
   c2:=cmd[2];
   cms:=copy(cmd,3,length(cmd)-2);
   nocmd:=FALSE;
   lastcommandovr:=FALSE;
   
   case c1 of
      {filep.men}
      '!':if c2 in ['T','L','F','+','?','J','R','S','U','V','Q','I','U','D','C','N'] then filepmnu := c2
        else nocmd := true;
      else
      nocmd:=TRUE;
  end;
  
  lastcommandgood:=not nocmd;
  if (lastcommandovr) then lastcommandgood:=FALSE;
  if (nocmd) and (cmd <> '!R') then { Receiving !R as ENTER for Next List Ignore!! }
    if (cso) then
    begin
      sysoplog('*** FILEP Menu System *** ');
      sysoplog('Invalid command : Cmdkeys "'+cmd+'"');
      nl; {print('Invalid command : Cmdkeys "'+cmd+'"');}
    end;
   
end;

end.
