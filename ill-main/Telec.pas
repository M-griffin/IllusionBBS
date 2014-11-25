(*****************************************************************************)
(* Illusion BBS - Teleconference                                             *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit telec;

interface

uses
  crt, dos,
  common, misc3, mtask;

procedure telec_maintenance;
procedure telec_run;

implementation

type tempstrg=array [0..255] of string[36];
     tempstrgptr=^tempstrg;

var enF:File of eachnoderec;        { teleconf.usr }
    cen,en :eachnoderec;
    cdf2,cdf:File of eachline;      { teledata.### }
    l,k:eachline;
    yes:boolean;
    temps:tempstrgptr;
    tempn:byte;
    anf:File of actionrec;          { action.dat   }
    an :actionrec;
    chan:string;                    { channel (ie: "Main") }
    tmps:string;

procedure telec_maintenance;
var n:byte;
begin
  setfileaccess(readwrite,denyall);
  rewrite(enf);
  with en do begin
    name:='<n/a>';
    channel:='<none>';
    cbchannel:=0;
    invisible:=FALSE;
    showall:=FALSE;
  end;
  setfileaccess(readwrite,denynone);
  reset(nodef);
  for n:=0 to filesize(nodef)-1 do write(enf,en);
  close(nodef);
end;

procedure telec_showcbchan(chan:word);
var n:byte; s:string;
begin
  if chan=0 then
  begin
    spstr(493);
    exit;
  end;
  new(temps); tempn:=0;
  str(chan,s);
  clearwaves;
  addwave('CB',s,txt);
  spstr(494);
  clearwaves;
  seek(enf,0);

  for n:=0 to filesize(nodef)-1 do begin
    read(enf,en);
    if (not en.invisible) and (en.name <> '<n/a>') and
    (en.cbchannel=chan) and (n+1<>nodenum) then begin
      temps^[tempn]:=caps(en.name);
      inc(tempn);
    end;
  end;

  clearwaves;
  if tempn=0 then
    spstr(495)
  else
  if tempn=1 then
  begin
    addwave('01',temps^[0],txt);
    spstr(496);
  end else
  if tempn=2 then
  begin
    addwave('01',temps^[0],txt);
    addwave('02',temps^[1],txt);
    spstr(497);
  end else
  begin
    for n:=0 to tempn-2 do
    begin
      addwave('01',temps^[n],txt);
      spstr(498);
      clearwaves;
    end;
    addwave('01',temps^[tempn-1],txt);
    spstr(499);
  end;
  clearwaves;

  dispose(temps);
end;

procedure telec_whoshere;
var n:byte;
begin
  seek(enf,0);
  tempn:=0;
  for n:=0 to filesize(nodef)-1 do begin
    read(enf,en);
    if (en.name<>'<n/a>') and (en.channel=chan) and (not en.invisible) and ((n+1)<>nodenum) then begin
      temps^[tempn]:=caps(en.name);
      inc(tempn);
    end;
  end;

  clearwaves;
  if tempn=0 then
    spstr(500)
  else
  if tempn=1 then
  begin
    addwave('01',temps^[0],txt);
    spstr(501);
  end else
  if tempn=2 then
  begin
    addwave('01',temps^[0],txt);
    addwave('02',temps^[1],txt);
    spstr(502);
  end else
  begin
    for n:=0 to tempn-2 do
    begin
      addwave('01',temps^[n],txt);
      spstr(503);
    end;
    addwave('01',temps^[tempn-1],txt);
    spstr(504);
  end;
  clearwaves;

  dispose(temps);
end;

procedure telec_globalmsg(s:string; node:integer; ChanOnly:boolean);

   function ok:boolean;
   begin
     if node=0 then begin
       ok:=(filepos(enf)<>nodenum);
     end else if node<0 then begin
       ok:=((filepos(enf)<>nodenum) and (filepos(enf)<>abs(node)));
     end else if node>0 then begin
       ok:=(filepos(enf)=node);
     end;
   end;

begin
  seek(enf,0);
  while not eof(enf) do begin
    read(enf,en);
    if (en.name<>'<n/a>') and
       (((node=0) and (filepos(enf)=node)) or (ok)) and
       ((not chanonly) or (en.channel=chan))
    then begin
      l.data:=s;
      if node=nodenum then l.datafor:=sent else l.datafor:=channel;
      assign(cdf2,systat^.multpath+'teledata.'+cstr(filepos(enf)));
      setfileaccess(readwrite,denyall);
      {$I-} reset(cdf2); {$I+}
      setfileaccess(readwrite,denyall);
      if ioresult<>0 then rewrite(cdf2);
      seek(cdf2,filesize(cdf2));
      write(cdf2,l);
      close(cdf2);
    end;
  end;
end; { PROC telec_globalmsg }

procedure listactions;
var i:integer; s:string;
    abort,next:boolean;

    function dc(act:astr):astr;
    var p:byte;
    begin
      if pos('@OBJ@',allcaps(act))>0 then begin
        if allcaps(an.noobject)='N/A' then
          act:='|W*|c'+caps(act)
        else
          act:='|w*|c'+caps(act);
      end else
        act:='|K*|C'+caps(act);
      p:=pos(' ',act); if (p>0) then act:=copy(act,1,p-1);
      dc:=act;
    end;

begin

  setfileaccess(readwrite,denynone);
  {$I-} reset(anf); {$I+}
  if (ioresult=0) and (filesize(anf)>0) then
  begin
    spstr(593);
    abort:=FALSE; next:=FALSE; i:=1; s:='|c';
    while (not abort) and (i<=filesize(anf)) do begin
      seek(anf,i-1); read(anf,an);
      case (i mod 5) of
        0:begin
            s:=s+dc(an.act);
            printacr(s,abort,next);
            s:='|c';
          end;
        else s:=s+mln(dc(an.act)+',',15);
      end;
      inc(i);
    end;
    if ((i-1) mod 5)<>0 then printacr(s,abort,next);
    nl;
    close(anf);
  end else
    spstr(505);
end;

procedure doaction(var s:astr);
label gotuser;
var i:integer; p,obj:byte;
    notfound:boolean;
    x1,x2,tmp:astr;
    n:byte; o:integer;
    objectname:astr;

    function dc(act:astr):astr;
    var p:byte;
    begin
      p:=pos(' ',act); if (p>0) then act:=copy(act,1,p-1);
      dc:=allcaps(act);
    end;

begin
  setfileaccess(readwrite,denynone);
  {$I-} reset(anf); {$I+}
  if (ioresult=0) and (filesize(anf)>0) then begin
    i:=0; notfound:=TRUE; s:=copy(allcaps(s),2,length(s)-1);
    p:=pos(' ',s);
    if p>0 then begin
      x1:=copy(s,1,p-1); x2:=copy(s,p+1,length(s)-p);
    end else begin
      x1:=s; x2:='';
    end;

    while ((i<=filesize(anf)-1) and (notfound)) do begin
      seek(anf,i); read(anf,an);
      if x1=dc(an.act) then notfound:=FALSE;
      inc(i);
    end;
    close(anf);

    if (not notfound) then begin
       if (pos('@OBJ@',allcaps(an.act))>0) then begin
         if (an.noobject='n/a') then obj:=3 else obj:=2;
       end else obj:=1;
       n:=0;

       if ((obj=3) and (x2='')) then begin
         spstr(515);
         spstr(587); exit;
       end else
         if (obj>1) and (x2<>'') then begin
           seek(enf,0);
           for p:=0 to filesize(nodef)-1 do begin
             read(enf,en);
             if (not en.invisible) and (en.name <> '<n/a>') and
             (en.channel=chan) {and (p+1<>nodenum)} then begin
               if x2=allcaps(en.name) then begin
                 n:=p+1; goto gotuser;
               end else if (pos(x2,allcaps(en.name))=1) then
                 if n=0 then n:=p+1 else begin
                   spstr(514);
                   n:=0; spstr(587); exit;
                 end;
             end; { if valid node }
           end; { read file loop }
           if n=0 then begin
             spstr(516);
             spstr(587); exit;
           end;
         end; { if obj }

         gotuser:
         if n>0 then begin
           seek(enf,n-1); read(enf,en);
           objectname:=caps(en.name);
         end;

         for p:=1 to 3 do begin
           case p of
             1:begin tmp:=an.objectmsg; o:=n;       end;
             2:begin
                 if n=0 then tmp:=an.noobject else tmp:=an.globalmsg;
                 if tmp='n/a' then tmp:='';
                 if n>0 then o:=0-n else o:=0;
               end;
             3:begin tmp:=an.yourmsg; o:=nodenum; end;
           end;

           if not ((p=1) and (n=0)) then begin
             while (pos('@OBJ@',allcaps(tmp))>0) do tmp:=substone(tmp,'@OBJ@',objectname);
             while (pos('@USER@',allcaps(tmp))>0) do tmp:=substone(tmp,'@USER@',caps(thisuser.name));
             while (pos('@SEX@',allcaps(tmp))>0) do
               tmp:=substone(tmp,'@SEX@',aonoff(thisuser.sex='F','her','his'));

             if (tmp<>'') then telec_globalmsg(tmp,o,TRUE);
           end;

         end; { for p }

    end else begin
      clearwaves;
      addwave('AC',x1,txt);
      spstr(517);
      clearwaves;
      spstr(587);
    end; { if not notfound }

  end else begin
    spstr(518);
    spstr(587);
  end; { if ioresult<>0 or file empty }
end;

function tele_input:string;
var ch:char; s:string; len,i:byte; done:boolean;
begin
  if not empty then begin
    s:=''; done:=false;
    ch:=inkey; len:=0;
    if (ch<>#0) and (ch in [#32..#255]) then begin
      s[1]:=ch; s[0]:=chr(1);
      len:=length(s); prompt(ch);
      repeat
        repeat
          ch:=inkey;
          timeslice;
        until (ch<>#0) or (hangup);
        case ch of
          ^X : if len>0 then begin
                 for i:=1 to len do prompt(^H+' '+^H);
                 s[0]:=chr(0); len:=0;
               end;
          ^H : if len>0 then begin
                 dec(len);
                 s[0]:=chr(len);
                 prompt(^H+' '+^H);
                 if len=0 then done:=true;
               end;
          ^M : done:=true;
          #32..#255 : if len<78 then begin
                        inc(len);
                        s[len]:=ch;
                        s[0]:=chr(len);
                        prompt(ch);
                      end;
        end;
        len:=length(s);
        checkhangup;
      until (len=0) or (done) or (hangup);
      if len=0 then
        tele_input:=' '
      else begin
        tele_input:=s; nl;
        yes:=true;
      end;
    end else
      if (ch<>#0) and (ch=^M) then begin
        nl; tele_input:=' ';
        yes:=true;
      end;
  end;
end;

procedure telec_run;
label didjoin,notfound;
var n:byte;
    s,s1:string;
    cbchan:word;
    update,done:boolean;
    w:word;
    i:integer;
    showall,invisi,waspause:boolean;

    procedure updateENF;
    begin
      en.name:=thisuser.name;
      en.channel:=chan;
      en.cbchannel:=cbchan;
      en.invisible:=invisi;
      en.showall:=showall;
      seek(enf,nodenum-1);
      write(enf,en);
    end;

begin
  spstr(506);
  if (pause in thisuser.ac) then
  begin
    waspause:=true;
    exclude(thisuser.ac,pause);
  end else
    waspause:=false;

  setfileaccess(readwrite,denynone);
  reset(nodef);
  assign(anf,systat^.datapath+'ACTION.DAT');
  assign(enf,systat^.multpath+'TELECONF.USR');
  setfileaccess(readwrite,denynone);
  {$I-} reset(enf); {$I+}
  if (ioresult<>0) or (filesize(enf)<>filesize(nodef)) then
  begin
    telec_maintenance;
    setfileaccess(readwrite,denynone);
    reset(enf);
  end;

  assign(cdf,systat^.multpath+'TELEDATA.'+cstr(nodenum));
  setfileaccess(readwrite,denynone);
  rewrite(cdf);
  close(cdf);

  seek(enf,nodenum-1);
  read(enf,en);

  sysoplog('Entered teleconference');
  en.name:=caps(thisuser.name);
  en.channel:='Main';
  en.cbchannel:=0;
  en.invisible:=FALSE;
  en.showall:=FALSE;

  chan:='Main';
  cbchan:=0;

  seek(enf,nodenum-1);
  write(enf,en);

  done:=FALSE;
  showall:=FALSE;
  invisi:=FALSE;
  yes:=false;

  s:=substone(getstr(519),'~UN',caps(thisuser.name));
  telec_globalmsg(s,0,true);
  repeat
    if filerec(nodef).mode=fmclosed then begin
      setfileaccess(readwrite,denynone);
      reset(nodef);
    end;
    update:=FALSE;
    new(temps);
    tempn:=0;
    if chan='Main' then
      spstr(507)
    else if chan=caps(thisuser.name) then
      spstr(508)
    else
    begin
      clearwaves;
      addwave('CN',chan,txt);
      spstr(509);
      clearwaves;
    end;

    telec_whoshere;

    spstr(510);

    spstr(587);
    repeat
      if (filerec(cdf).mode=fmClosed) then
      begin
        setfileaccess(readwrite,denyall);
        {$I-} reset(cdf); {$I+}
        if (ioresult=0) and (filesize(cdf)>0) then
        begin
          while not eof(cdf) do
          begin
            read(cdf,l);
            if l.datafor=channel then
            begin
              tmps:=substone(getstr(597),'~MS',l.data);
{             spromptt(tmps,FALSE,TRUE); } sprompt(tmps);
            end else
            if l.datafor=cbchannel then
            begin
              tmps:=substone(getstr(598),'~MS',l.data);
              tmps:=substone(tmps,'~C#',cstr(cbchan));
{             spromptt(tmps,FALSE,TRUE); } sprompt(tmps);
            end else
            if l.datafor=sent then
            begin
              tmps:=substone(getstr(599),'~MS',l.data);
{             spromptt(tmps,FALSE,TRUE); } sprompt(tmps);
            end;
          end;
          close(cdf);
          setfileaccess(readwrite,denynone);
          rewrite(cdf);
          close(cdf);
          spstr(587);
        end else
          if filerec(cdf).mode<>fmClosed then close(cdf);
      end;

      if (systype>0) then timeslice;

      s:=tele_input;
      if yes then begin
        yes:=false;
        if s=' ' then s:='';
        while (s[1]=' ') and (s<>'') do delete(s,1,1);
        while (s[length(s)]=' ') and (s<>'') do delete(s,length(s),1);
        if (s[1]='/') and (length(s)>=1) then begin
          s[2]:=upcase(s[2]);
          case s[2] of
            '?':begin
                  spstr(511);
                  spstr(587);
                end;
            'X':begin end;
            'T':begin
                  seek(enf,0); cl(ord('w')); nl;
                  for i:=0 to filesize(nodef)-1 do begin
                    read(enf,en);
                    if (not en.invisible) and (en.name<>'<n/a>') then begin
                      sprompt('|C'+mrn(cstr(filepos(enf)),3)+'. |Y'
                             +mln(caps(en.name),36)+'  '+en.channel);
                      if (en.channel<>'Main') then print('''s') else nl;
                    end;
                  end;
                  nl; spstr(587);
                end;
            'I':begin
                  if (cso) then
                  begin
                    invisi:=NOT invisi;
                    if invisi then spstr(595) else spstr(596);
                    updateENF;
                    spstr(587);
                  end else
                  begin
                    spstr(523);
                    spstr(587);
                  end;
                end;
            '#':begin
                  whoonline;
                  setfileaccess(readwrite,denynone);
                  reset(nodef);
                  spstr(587);
                end;
            'J':if (s[3]=' ') and (length(s)>=4) then begin
                  delete(s,1,3);
                  seek(enf,0);
                  for i:=0 to filesize(nodef)-1 do begin
                    read(enf,cen);
                    if (filepos(enf)<>nodenum) and (not cen.invisible) then begin
                      if allcaps(s)=allcaps(cen.channel) then begin
                        if (not invisi) then
                          telec_globalmsg(substone(getstr(590),'~UN',caps(thisuser.name)),0,TRUE);
                        chan:=cen.channel; goto didjoin;
                      end else
                      if (pos(allcaps(s),allcaps(cen.channel))=1) then
                        if pynq(substone(getstr(594),'~CN',cen.channel)) then
                        begin
                          if (not invisi) then
                            telec_globalmsg(substone(getstr(590),'~UN',caps(thisuser.name)),0,TRUE);
                          chan:=cen.channel;
                          goto didjoin;
                        end;
                    end;
                  end;
                  spstr(592);
                  spstr(587);
                  goto notfound;

                  didjoin:
                  updateenf;
                  if (not invisi) then
                    telec_globalmsg(substone(getstr(591),'~UN',caps(thisuser.name)),0,TRUE);
                  update:=TRUE;
                  s:='';

                  notfound:
                end else begin
                  if (not invisi) then
                    telec_globalmsg(substone(getstr(590),'~UN',caps(thisuser.name)),0,TRUE);
                  if chan='Main' then
                    chan:=caps(thisuser.name)
                  else
                    chan:='Main';
                  updateenf;
                  if (not invisi) then
                    telec_globalmsg(substone(getstr(591),'~UN',caps(thisuser.name)),0,TRUE);
                  s:='';
                  update:=TRUE;
                end;
            'C':if (s[3]=' ') and (length(s)>=4) then begin
                  delete(s,1,3);
                  val(s,w,i);
                  if (w>=1) and (w<=50000) then begin
                    cbchan:=w;
                    str(cbchan,s);
                    clearwaves;
                    addwave('CB',s,txt);
                    spstr(494);
                    clearwaves;
                    updateenf;
                  end else if (w=0) then begin
                    cbchan:=w;
                    spstr(521);
                    updateenf;
                  end else
                    spstr(522);
                  spstr(587);
                end else begin
                  spstr(520);
                  spstr(587);
                end;
            else begin
              spstr(523);
              spstr(587);
            end;
          end;
        end else
        if (upcase(s[1])='G') and (upcase(s[2])='A') and ((s[3]=' ') or (length(s)=2)) then begin
          if (length(s)>3) then begin
            delete(s,1,3);
            tmps:=substone(getstr(526),'~UN',caps(thisuser.name));
            tmps:=substone(tmps,'~GA',s);
            telec_globalmsg(tmps,0,TRUE);
            spstr(525);
          end else
            spstr(524);
          spstr(587);
        end else
        if (s[1]='.') then begin
          if length(s)>1 then begin
            if (allcaps(s)='.LIST') then
            begin
              lil:=0;
              if (waspause) then include(thisuser.ac,pause);
              listactions;
              spstr(587);
              if (pause in thisuser.ac) then exclude(thisuser.ac,pause);
            end else
              doaction(s);
          end else begin
            spstr(530);
            spstr(587);
          end;
        end else begin
          if s<>'' then begin
            if s='''' then begin
              telec_showcbchan(cbchan);
              spstr(587);
            end else begin
              if (s[1]='''') and (cbchan>0) then
              begin
                l.datafor:=cbchannel;
                delete(s,1,1);
                while (s[1]=' ') and (s<>'') do delete(s,1,1);
                tmps:=substone(getstr(588),'~UN',caps(thisuser.name));
                l.data:=substone(tmps,'~MS',s);
              end else
              begin
                l.datafor:=channel;
                tmps:=substone(getstr(589),'~UN',caps(thisuser.name));
                l.data:=substone(tmps,'~MS',s);
              end;
              SetFileAccess(readwrite,denynone);
              reset(enf);
              seek(enf,0);
              for i:=0 to filesize(nodef)-1 do
              begin
                if (filerec(enf).mode=fmClosed) then reset(enf);
                seek(enf,i);
                read(enf,en);
                if (((l.datafor=channel) and (en.channel=chan)) or
                   ((l.datafor=cbchannel) and (en.cbchannel=cbchan))) and
                   (filepos(enf)<>nodenum) then
                begin
                  assign(cdf2,systat^.multpath+'TELEDATA.'+cstr(filepos(enf)));
                  setfileaccess(readwrite,denyall);
                  {$I-} reset(cdf2); {$I+}
                  setfileaccess(readwrite,denyall);
                  if ioresult<>0 then rewrite(cdf2);
                  seek(cdf2,filesize(cdf2));
                  write(cdf2,l);
                  close(cdf2);
                end else if (filepos(enf)=nodenum) then begin
                  k.datafor:=sent;
                  if (l.datafor=channel) then
                    k.data:=getstr(527)
                  else if (l.datafor=cbchannel) then
                    k.data:=getstr(528);
                  assign(cdf2,systat^.multpath+'TELEDATA.'+cstr(filepos(enf)));
                  setfileaccess(readwrite,denyall);
                  {$I-} reset(cdf2); {$I+}
                  setfileaccess(readwrite,denyall);
                  if ioresult <> 0 then rewrite(cdf2);
                  seek(cdf2,filesize(cdf2));
                  write(cdf2,k);
                  close(cdf2);
                end;
              end; { EOF }
            end; { check if they typed ' }
          end { nul check } else update:=true;
        end; { / check }
      end; { key pressed? }
    until (s='/X') or (s='/x') or (s='') or (update) or (hangup);
    if (s='/X') or (s='/x') then done:=true;

  until (done) or (hangup);
  s:=substone(getstr(529),'~UN',caps(thisuser.name));
  telec_globalmsg(s,0,TRUE);
  seek(enf,nodenum-1);
  en.name:='<n/a>';
  write(enf,en);
  close(enf);
  erase(cdf);
  if waspause then include(thisuser.ac,pause);
  lil:=0;
end;

end.
