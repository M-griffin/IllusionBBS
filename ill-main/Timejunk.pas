(*****************************************************************************)
(* Illusion BBS - Time routines                                              *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit timejunk;

interface

uses dos;

type
  packdate=array[1..3] of byte;
  packtime=array[1..3] of byte;
  packdatetimepp=^packdatetime;
  packdatetime=array[1..6] of byte;   { packdate + packtime, in that order }
  ldatetimerec=
  record
    year,month,day,hour,min,sec,sec100:word;
  end;

procedure pt2dt(pt:packtime; var dt:ldatetimerec);
procedure dt2pt(dt:ldatetimerec; var pt:packtime);
procedure pd2dt(pd:packdate; var dt:ldatetimerec);
procedure dt2pd(dt:ldatetimerec; var pd:packdate);
procedure pdt2dt(pdt:packdatetime; var dt:ldatetimerec);
procedure dt2pdt(dt:ldatetimerec; var pdt:packdatetime);
procedure getdatetime(var dt:ldatetimerec);
procedure getpackdatetime(pdtpp:packdatetimepp);
procedure getdayofweek(var dow:byte);
procedure s2pd(s:string; var pd:packdate; var errors:byte);
function pdt2dat(pdtpp:packdatetimepp; dow:byte):string;
function pdt2mdyhms(pdtpp:packdatetimepp):string;

implementation

procedure pt2dt(pt:packtime; var dt:ldatetimerec);
begin
  with dt do begin
    hour:=((pt[1] and 248) shr 3);
    min:=((pt[1] and 7) shl 3)+((pt[2] and 224) shr 5);
    sec:=((pt[2] and 31) shl 1)+((pt[3] and 128) shr 7);
    sec100:=(pt[3] and 127);
  end;
end;

procedure dt2pt(dt:ldatetimerec; var pt:packtime);
begin
  with dt do begin
    pt[1]:=((hour and 31) shl 3)+((min and 56) shr 3);
    pt[2]:=((min and 7) shl 5)+((sec and 62) shr 1);
    pt[3]:=((sec and 1) shl 7)+(sec100 and 127);
  end;
end;

procedure pd2dt(pd:packdate; var dt:ldatetimerec);
begin
  with dt do begin
    year:=((pd[1] shl 7)+((pd[2] and 254) shr 1))+1800;
    month:=((pd[2] and 1) shl 3)+((pd[3] and 224) shr 5);
    day:=(pd[3] and 31);
    hour:=0; min:=0; sec:=0;
  end;
end;

procedure dt2pd(dt:ldatetimerec; var pd:packdate);
begin
  with dt do begin
    pd[1]:=(((year-1800) and 32641) shr 7);
    pd[2]:=(((year-1800) and 127) shl 1)+((month and 8) shr 3);
    pd[3]:=((month and 7) shl 5)+(day and 31);
  end;
end;

procedure pdt2dt(pdt:packdatetime; var dt:ldatetimerec);
var pd:packdate;
    pt:packtime;
begin
  pd[1]:=pdt[1]; pd[2]:=pdt[2]; pd[3]:=pdt[3];
  pt[1]:=pdt[4]; pt[2]:=pdt[5]; pt[3]:=pdt[6];
  pd2dt(pd,dt); pt2dt(pt,dt);
end;

procedure dt2pdt(dt:ldatetimerec; var pdt:packdatetime);
var pd:packdate;
    pt:packtime;
begin
  dt2pd(dt,pd); dt2pt(dt,pt);
  pdt[1]:=pd[1]; pdt[2]:=pd[2]; pdt[3]:=pd[3];
  pdt[4]:=pt[1]; pdt[5]:=pt[2]; pdt[6]:=pt[3];
end;

procedure getdatetime(var dt:ldatetimerec);
var dow:word;
begin
  getdate(dt.year,dt.month,dt.day,dow);
  gettime(dt.hour,dt.min,dt.sec,dt.sec100);
end;

procedure getpackdatetime(pdtpp:packdatetimepp);
var dt:ldatetimerec;
begin
  getdatetime(dt);
  dt2pdt(dt,pdtpp^);
end;

procedure getdayofweek(var dow:byte);
var y,m,d,dd:word;
begin
  getdate(y,m,d,dd);
  dow:=dd;
end;

procedure s2pd(s:string; var pd:packdate; var errors:byte);
var dt:ldatetimerec;
    m,d,y:longint;
    y1,m1,d1,dow1:word;
    zz:integer;
begin
  errors:=0;
  while (pos(' ',s)<>0) do delete(s,pos(' ',s),1);
  while (pos('-',s)<>0) do s[pos('-',s)]:='/';
  val(copy(s,1,pos('/',s)-1),m,zz);
  s:=copy(s,pos('/',s)+1,length(s)-pos('/',s));
  val(copy(s,1,pos('/',s)-1),d,zz);
  s:=copy(s,pos('/',s)+1,length(s)-pos('/',s));
  val(s,y,zz);
  if ((m<1) or (m>12)) then begin errors:=1; exit; end;
  if ((d<1) or (d>31)) then begin errors:=1; exit; end;
  if ((y>=0) and (y<100)) then begin
    getdate(y1,m1,d1,dow1);
    y1:=(y1 div 100)*100;
    inc(y,y1);
  end;
  if (y<1800) then begin errors:=1; exit; end;
  with dt do begin
    year:=y; month:=m; day:=d;
    hour:=0; min:=0; sec:=0; sec100:=0;
  end;
  dt2pd(dt,pd);
end;

function pdt2dat(pdtpp:packdatetimepp; dow:byte):string;
var s,x:string;
    pdt:packdatetime;
    dt:ldatetimerec;
    i:integer;
    ispm:boolean;
begin
  pdt:=pdtpp^;
  pdt2dt(pdt,dt);
  with dt do begin
    i:=hour; ispm:=(i>=12);
    if (ispm) then
      if (i>12) then dec(i,12);
    if (not ispm) then
      if (i=0) then i:=12;
    str(i,x); s:=x+':';
    str(min,x); if (min<10) then x:='0'+x; s:=s+x+' ';
    if (ispm) then s:=s+'p' else s:=s+'a';
    s:=s+'m  '+
         copy('SunMonTueWedThuFriSat',dow*3+1,3)+' '+
         copy('JanFebMarAprMayJunJulAugSepOctNovDec',(month-1)*3+1,3)+' ';
    str(day,x); s:=s+x+', ';
    str(year,x); s:=s+x;
  end;
  pdt2dat:=s;
end;

function pdt2mdyhms(pdtpp:packdatetimepp):string;
var pdt:packdatetime;
    dt:ldatetimerec;
    s:string;

  function cstr(i:integer):string;
  var s:string;
  begin
    str(i,s); if (i<10) then s:='0'+s;
    cstr:=s;
  end;

begin
  pdt:=pdtpp^;
  pdt2dt(pdt,dt);
  with dt do
    s:=cstr(month)+'/'+cstr(day)+'/'+cstr(year)+' '+
       cstr(hour)+':'+cstr(min)+':'+cstr(sec)+'.'+cstr(sec100);
  pdt2mdyhms:=s;
end;


(*                      |               |
                        |               |
             Byte #1    |    Byte #2    |    Byte #3
         ===============|===============|===============
         4 3 2 1 0 9 8 7|6 5 4 3 2 1 0 9|8 7 6 5 4 3 2 1
         `---------------------------' `-----' `-------'
                Year    |              Month     Day
               (15 bits)|             (4 bits) (5 bits)
                        |               |
                        |               |
             Byte #1    |    Byte #2    |    Byte #3
         ===============|===============|===============
         4 3 2 1 0 9 8 7|6 5 4 3 2 1 0 9|8 7 6 5 4 3 2 1
         `-------' `---------' `---------' `-----------'
           Hour      Minute      Second |  1/100 Seconds
         (5 bits)   (6 bits)    (6 bits)|    (7 bits)
                        |               |
*)

end.
