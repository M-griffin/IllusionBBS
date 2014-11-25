(*****************************************************************************)
(* Illusion BBS - SysOp routines  [6/11] (event editor)                      *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit sysop6;

interface

uses
  crt, dos,
  common;

procedure eventedit;

implementation

procedure ee_help;
begin
  sprint(' |W#|w:Modify item   <|WCR|w>Redisplay screen');
  lcmds(15,3,'[Back entry',']Forward entry');
  lcmds(15,3,'Jump to entry','First entry in list');
  lcmds(15,3,'Quit and save','Last entry in list');
end;

procedure eventedit;
const sepr2:string[5]='|B:|C';
var evf:file of eventrec;
    i1,i2,ii:integer;
    c:char;
    abort,next:boolean;
    s:astr;

  function onoff(b:boolean):astr;
  begin
    if b then onoff:='On ' else onoff:='Off';
  end;

  function dactiv(l:boolean; days:byte; b:boolean):astr;
  const dayss:string[7]='SMTWTFS';
  var s:astr;
      i:integer;
  begin
    if b then begin
      s:=cstr(days);
      if l then s:=s+' (monthly)' else s:=s+' mthly';
    end else begin
      s:='';
      for i:=6 downto 0 do
        if (days and (1 shl i)<>0) then
          s:=s+dayss[7-i] else s:=s+'-';
    end;
    if not l then s:=mln(s,7);
    dactiv:=s;
  end;

  function schedt(l:boolean; c:char):astr;
  begin
    case c of
      'A':if (l) then schedt:='ACS users' else schedt:='ACS';
      'C':if (l) then schedt:='Chat event' else schedt:='Cht';
      'D':if (l) then schedt:='DOS shell' else schedt:='DOS';
      'E':if (l) then schedt:='External' else schedt:='Ext';
      'P':if (l) then schedt:='Pack bases' else schedt:='Pak';
    end;
  end;

  procedure eed(i:integer);
  var x:integer;
  begin
    if (i>=1) and (i<=numevents) then begin
      dec(numevents);
      for x:=i to numevents do events[x]^:=events[x+1]^;
      rewrite(evf);
      for x:=1 to numevents do write(evf,events[x]^);
      close(evf);
      dispose(events[numevents+1]);
    end;
  end;

  procedure eei(i:integer);
  var x:integer;
  begin
    if (i>=1) and (i<=numevents+1) and (numevents<maxevents) then begin
      inc(numevents);
      new(events[numevents]);
      for x:=numevents downto i do events[x]^:=events[x-1]^;
      with events[i]^ do begin
        active:=FALSE;
        description:='[ Unnamed Event ]';
        etype:='D';
        execdata:='event.bat';
        busytime:=5;
        exectime:=0;
        busyduring:=TRUE;
        duration:=1;
        execdays:=0;
        monthly:=FALSE;
      end;
      rewrite(evf);
      for x:=0 to numevents do write(evf,events[x]^);
      close(evf);
    end;
  end;

  procedure eem;
  var ii,i,j,k:integer;
      c:char;
      s:astr;
      bb:byte;
      changed,abort,next:boolean;
  begin
    prt('Begin editing at which? (0-'+cstr(numevents)+'): '); mpl(5); inu(ii);
    c:=' ';
    if (ii>=0) and (ii<=numevents) then begin
      while (c<>'Q') and (not hangup) do begin
        with events[ii]^ do
          repeat
            if (c<>'?') then begin
              cls; abort:=FALSE; k:=1;
              sprint('|WEvent ['+cstr(ii)+'/'+cstr(numevents)+']'); nl;
              while (not abort) and (k<=9) do begin
              case k of
              1:sprint('!. Active      : |C'+syn(active));
              2:sprint('1. Description : |C'+description);
              3:sprint('2. Event type  : |C'+schedt(TRUE,etype));
              4:sprint('3. Event data  : |C'+execdata);
              5:sprint('4. Busy time   : |C'+
                    aonoff((busytime<>0),cstr(busytime)+' minutes','None.'));
              6:sprint('5. Exec. time  : |C'+copy(ctim(exectime),4,5));
              7:sprint('6. Busy during : |C'+syn(busyduring));
              8:sprint('7. Duration    : |C'+cstr(duration));
              9:sprint('8. Days active : |C'+dactiv(TRUE,execdays,monthly));
            end;
            wkey(abort,next); inc(k);
            end;
            end;
            nl;
            prt('Edit menu (?=help): ');
            onek(c,'Q!12345678[]FJL?'^M);
            nl;
            case c of
              '!':active:=not active;
              '1':begin
                    prt('New description: ');
                    mpl(30); inputwn(description,30,changed);
                  end;
              '2':begin
                    prt('New schedule type (?=list): ');
                    onek(c,'QACDEP?'^M);
                    if c='?' then begin
                      nl;
                      lcmds(11,3,'ACS Event','Chat Event');
                      lcmds(11,3,'Dos Shell','External Event');
                      lcmds(11,3,'PMsg Pack','');
                    end;
                    if (pos(c,'ACDEP')<>0) then etype:=c;
                  end;
              '3':begin
                    sprint('ACS: |CACS string');
                    sprint('Cht: |C"0" if off, "1" if on');
                    sprint('DOS: |CDos commandline');
                    sprint('Ext: |CErrorlevel to exit BBS with');
                    sprint('Pak: |CPack The Message Bases');
                    nl;
                    prt('New event data: ');
                    mpl(20); inputwn(execdata,20,changed);
                  end;
              '4':begin
                    prt('New busy time (0=none): '); mpl(5);
                    inu(i);
                    if not badini then busytime:=i;
                  end;
              '5':begin
                    sprint('All entries in 24 hour time.  Hour: (0-23), Minute: (0-59)');
                    nl;
                    sprompt('New event time: ');
                    prt('  Hour   : '); mpl(5); inu(i);
                    if not badini then begin
                      if (i<0) or (i>23) then i:=0;
                      prt('                   Minute : '); mpl(5); inu(j);
                      if not badini then begin
                        if (j<0) or (j>59) then j:=0;
                        exectime:=i*60+j;
                      end;
                    end;
                  end;
              '6':busyduring:=not busyduring;
              '7':begin
                    prt('New duration: '); mpl(5); inu(i);
                    if not badini then duration:=i;
                  end;
              '8':begin
                    if monthly then c:='M' else c:='W';
                    prt('Days active (W:eekly,M:onthly) ['+c+']: ');
                    onek(c,'QWM'^M);
                    if c in ['M','W'] then monthly:=(c='M');
                    if c='M' then execdays:=1;
                    if monthly then begin
                      nl;
                      prt('What day of the month? (1-31) ['+cstr(execdays)+']: ');
                      mpl(3); ini(bb);
                      if not badini then
                        if bb in [1..31] then execdays:=bb;
                    end else begin
                      nl;
                      sprint('Current: '+dactiv(TRUE,execdays,FALSE));
                      nl;
                      sprint('Modify by entering an "X" under days active.');
                      prt('[SMTWTFS]');
                      nl; pchar; mpl(7); input(s,7);
                      if s<>'' then begin
                        bb:=0;
                        for i:=1 to length(s) do
                          if s[i]='X' then
                            inc(bb,1 shl (7-i));
                        execdays:=bb;
                      end;
                    end;
                  end;
              '[':if (ii>0) then dec(ii) else ii:=numevents;
              ']':if (ii<numevents) then inc(ii) else ii:=0;
              'F':if (ii<>0) then ii:=0 else c:=' ';
              'J':begin
                    prt('Jump to entry: '); mpl(3);
                    input(s,3);
                    if (value(s)>=0) and (value(s)<=numevents) then ii:=value(s) else c:=' ';
                  end;
              'L':if (ii<>numevents) then ii:=numevents else c:=' ';
              '?':ee_help;
            end;
          until ((c in ['Q','[',']','F','J','L']) or (hangup));
      end;
      SetFileAccess(ReadWrite,DenyNone);
      reset(evf);
      for ii:=0 to numevents do write(evf,events[ii]^);
      close(evf);
    end;
  end;

  procedure eep;
  var i,j,k:integer;
  begin
    prt('Move which event? (0-'+cstr(numevents)+'): '); mpl(5); inu(i);
    if ((not badini) and (i>=0) and (i<=numevents)) then begin
      prt('Move before which event? (0-'+cstr(numevents+1)+'): '); mpl(5); inu(j);
      if ((not badini) and (j>=0) and (j<=numevents+1) and
          (j<>i) and (j<>i+1)) then begin
        eei(j);
        if (j>i) then k:=i else k:=i+1;
        events[j]^:=events[k]^;
        if (j>i) then eed(i) else eed(i+1);
      end;
    end;
  end;

begin
  assign(evf,systat^.datapath+'events.dat');
  c:=#0;
  repeat
    if c<>'?' then begin
      cls; abort:=FALSE;
      printacr('|C NN'+sepr2+'Description                   '+
               sepr2+'Typ'+sepr2+'Bsy'+sepr2+'Time '+sepr2+'Len'+sepr2+'Days   '+
               sepr2+'ExecData',abort,next);
      printacr('|B 컴:컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴:컴�:컴�:컴컴�:컴�:컴컴컴�:컴컴컴컴컴컴',abort,next);
      ii:=0;
      while (ii<=numevents) and (not abort) do
        with events[ii]^ do begin
          if (active) then s:='|Y+' else s:='|w-';
          s:=s+'|w'+mn(ii,2)+' |C'+mln(description,30)+' '+
              schedt(FALSE,etype)+' |Y'+
              mn(busytime,3)+' '+copy(ctim(exectime),4,5)+' '+
              mn(duration,3)+' '+dactiv(FALSE,execdays,monthly)+' |C'+
              mln(execdata,9);
          printacr(s,abort,next);
          inc(ii);
        end;
    end;
    nl;
    prt('Event editor (?=help): ');
    onek(c,'QDIMP?'^M); nl;
    case c of
      '?':begin
            sprint('|w<|WCR|w>Redisplay screen');
            lcmds(14,3,'Delete event','Insert event');
            lcmds(14,3,'Modify event','Position event');
            lcmds(14,3,'Quit','');
          end;
      'D':begin
            prt('Event to delete? (0-'+cstr(numevents)+'): '); mpl(5); inu(ii);
            if (ii>=0) and (ii<=numevents) then begin
              nl; sprint('Event: |B'+events[ii]^.description);
              if pynq('Delete this') then begin
                sysoplog('* Deleted event: '+events[ii]^.description);
                eed(ii);
              end;
            end;
          end;
      'I':begin
            prt('Event to insert before? (0-'+cstr(numevents+1)+'): '); mpl(5); inu(ii);
            if (ii>=0) and (ii<=numevents+1) then begin
              sysoplog('* Inserted new event');
              eei(ii);
            end;
          end;
      'M':eem;
      'P':eep;
    end;
  until (c='Q') or (hangup);
end;

end.
