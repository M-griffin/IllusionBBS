(*****************************************************************************)
(* Illusion BBS - Miscellaneous [3/3] 																			 *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
	{$D+,L+}
{$ELSE}
	{$D-,L-}
{$ENDIF}

unit misc3;

interface

uses
  crt, dos,
  common, sysop3, miscx, infoform;

procedure mmacro;
procedure sysopstatus;
procedure fadein(d:integer; s:string);
procedure fullscr_verline;
procedure showpcrstat;
procedure whoonline;
procedure nuvvote;
procedure wantlist;
procedure listrumors;
procedure confchange(mstr:astr);

implementation

procedure mmacro;
var macrf:file of macrorec;
		c,mc:char;
		mcn,n,n1,mn:integer;
		done,macchanged:boolean;

	procedure doctrl(c:char);
	begin
		cl(ord('C')); prompt('^'+c); cl(ord('w'));
	end;

	procedure listmac(s:string);
	var i:integer;
	begin
		sprompt('|Y"|w');
		for i:=1 to length(s) do
			if (s[i]>=' ') then prompt(s[i]) else doctrl(chr(ord(s[i])+64));
		sprint('|Y"');
	end;

	procedure listmacs;
	var i:integer;
	begin
		nl;
		sprint('|CCurrent Macros |B:');
		for i:=1 to 4 do begin
			nl; cl(ord('Y'));
			case i of
				1:sprompt('|WCtrl-D |B:|C ');
				2:sprompt('|WCtrl-E |B:|C ');
				3:sprompt('|WCtrl-F |B:|C ');
				4:sprompt('|WCtrl-R |B:|C ');
			end;
			listmac(macros^.macro[i]);
		end;
	end;

	procedure mmacroo(c:char);
	var mc:char;
			n1,n,mcn,mn:integer;
			s:string[255];
	begin
		nl;
		mc:=c;
		sprint('Enter new ^'+mc+' macro now.');
		sprint('Enter ^'+mc+' to end recording.  240 character limit.');
		nl; mcn:=ord(mc)-64;
		n:=1; s:=''; macok:=FALSE;
		mn:=pos(mc,'DEFR');
		repeat
			getkey(c);

			if (c=^H) then begin
				c:=#0;
				if (n>=2) then begin
					prompt(^H' '^H); dec(n);
					if (s[n]<#32) then prompt(^H' '^H);
				end;
			end;

			if ((n<=240) and (c<>#0) and (c<>chr(mcn))) then begin
				if (c in [#32..#255]) then begin
					outkey(c);
					s[n]:=c; inc(n);
				end else
					if (c in [^A,^B,^C,^G,^I,^J,^K,^L,^M,^N,^P,^Q,^S,^T,
										^U,^V,^W,^X,^Y,^Z,#27,#28,#29,#30,#31]) then begin
						if (c=^M) then nl
							else doctrl(chr(ord(c)+64));
						s[n]:=c; inc(n);
					end;
			end;
		until ((c=chr(mcn)) or (hangup));
		s[0]:=chr(n-1);
		nl; nl;
		sprint('|CYour ^'+mc+' macro is now:');
		nl; listmac(s); nl;
		if (not localioonly) then com_flush_rx;
		if pynq('Is this what you want') then begin
			macros^.macro[mn]:=s;
			print('Macro saved.');
			macchanged:=TRUE;
		end else
			print('Macro not saved.');
		macok:=TRUE;
	end;

begin
	macchanged:=FALSE;
	done:=FALSE;
	listmacs;
	repeat
		spstr(61);
		onek(c,'QLDEFR?');
		case c of
			'?':begin
						nl;
						sprint('|WD|w,|WE|w,|WF|w,|WR|w:Modify macro');
						lcmds(12,3,'List macros','Quit');
					end;
			'D','E','F','R':mmacroo(c);
			'L':listmacs;
			'Q':done:=TRUE;
		end;
	until (done) or (hangup);
	if (macchanged) then
		with thisuser do
		begin
			assign(macrf,systat^.datapath+'MACROS.DAT');
			setfileaccess(readwrite,denynone);
			reset(macrf);
			if (mpointer=-1) then mpointer:=filesize(macrf);
			seek(macrf,mpointer); write(macrf,macros^); close(macrf);
		end;
end;

procedure sysopstatus;
begin
	if (sysop) then
		spstr(164)
	else
		spstr(165);
end;

procedure fadein(d:integer; s:string);
var i,x:byte;
begin
	if hangup then exit;
	if (okansi) then begin
		for i:=1 to 3 do begin
			case i of
				1:setc(8); 2:setc(7); 3:setc(15);
			end;
			x:=wherex;
			sprompt(s);
			sleep(d);
			if (i<3) then begin
				gotoxy(x,wherey);
				if (outcom) then begin
					if (okavatar) then
						pr1(^Y+^H+chr(length(s)))
					else
						pr1(#27+'['+cstr(length(s))+'D');
				end;
			end;
		end;
	end else
		sprompt('|W'+s);
end;

procedure fullscr_verline;
{$I ipli.pas}
begin
	cls;
	sprint('|wÚÄÄÄÄÄ¿');
	sprint('|wÀÄ¿   Ù');
	sprompt('|wÚÄÙ  Ä¿'); fadein(100,'  L L U S I O N   B B S   S Y S T E M'); nl;
	sprint('|wÀÄÄ    ');
	sprint('|wÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
	fadein(100,' Illusion Bulletin Board System  ú  Version '+ver); nl;
	fadein(100,' Programmed by Kyle Oppenheim and Billy Ma'); nl;
        fadein(100,' Copyright 1992-1998 by Illusion Development'); nl;
        fadein(100,' Incorporates IPL engine '+cVersion); nl;
	sprint('|wÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
	fadein(100,' Original IPL executor engine written by Mike Fricker'); nl;
	fadein(100,' Earlier versions also programmed by Jeff Christman'); nl;
	fadein(100,' Message system toolkit written by Mark May'); nl;
	fadein(100,' Telegard 2.5i written by Eric Oman and Martin Pollard'); nl;
	fadein(100,' Melody Master written by Alexei A. Efros, Jr.'); nl;
	fadein(100,' Original teleconference written by John Randolph'); nl;
	sprint('|wÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
	nl;

	pausescr;
end;

procedure showpcrstat;
var want,have,need:integer;
		badratio:boolean;
begin
	 figurepcr(badratio,want,have,need);

	 clearwaves;
	 addwave('NC',cstr(systat^.postratio[thisuser.sl]),txt);
	 spstr(454);
	 clearwaves;

	 if (badratio) and (pynq(getstr(99))) then spstr(455);
end;

procedure whoonline;
var i:integer;
	 nodex:noderec;
	 s:string;
	 u:userrec;
	 abort,next:boolean;
begin
	sysoplog('Viewed node listing');
	aborted:=false;
	spstr(456);
	setfileaccess(readwrite,denynone);
	reset(uf);
	setfileaccess(readwrite,denynone);
	reset(nodef);
	i:=0; abort:=false; next:=false;
	while (not aborted) and (i<filesize(nodef)) and (not abort) do
	begin
		seek(nodef,i); read(nodef,nodex);
		inc(i);
		seek(uf,nodex.unum); read(uf,u);
		with nodex do begin
			clearwaves;
			if unum>0 then s:=cstr(unum) else s:='';
			addwave('NN',cstr(i),txt);
			addwave('UN',username,txt);
			addwave('U#',s,txt);
			addwave('UT',username+' #'+s,txt);
			if (whereuser='') then whereuser:=' ';
			addwave('WH',whereuser,txt);
			addwave('UC',u.citystate,txt);
			addwave('NO',u.usernote,txt);
			addwave('SN',u.note,txt);
			spstr(457);
		end;
		clearwaves;
		wkey(abort,next);
	end;
	aborted:=aborted or abort;
	close(uf);
	close(nodef);
	if (not aborted) then spstr(191);
end;



procedure nuvvote;
var nuvdat:file of nuvrec;
		nuvstuff:nuvrec;
		u:userrec;
		i,j,k,ii,iii,yes,no,ob:integer;
		ok,didvote,skipvote,werecomment:boolean;
		c:char; ch:string; cmt:string[65];

	procedure getout;
	begin
		close(nuvdat);
		close(uf);
	end;

	procedure killuservotes;
	var vdata:file of vdatar;
			vd:vdatar;
			i:integer;
	begin
		assign(vdata,systat^.datapath+'VOTING.DAT');
		SetFileAccess(ReadWrite,DenyNone);
		reset(vdata);
		for i:=1 to filesize(vdata) do
			if (u.vote[i]>0) then
			begin
				seek(vdata,i-1); read(vdata,vd);
				dec(vd.choices[u.vote[i]-1].numvoted);
				dec(vd.numvoted);
				seek(vdata,i-1); write(vdata,vd);
				u.vote[i]:=0;
			end;
		close(vdata);
	end;

	procedure delusr;
	var i:integer;
	begin
		if (not u.deleted) then
		begin
			u.deleted:=TRUE;
			dsr(u.name);
			i:=usernum; usernum:=nuvstuff.newusernum;
			rsm(FALSE);
			usernum:=i;
			killuservotes;
		end;
	end;

begin
	if systat^.nuv then
	begin
		didvote:=FALSE;
		spstr(180);
		assign(nuvdat,systat^.datapath+'NUV.DAT');
		SetFileAccess(ReadWrite,DenyNone);
		reset(nuvdat);
		if (filesize(nuvdat)=0) then
		begin
			spstr(185);
			close(nuvdat);
			exit;
		end else
		begin
			sysoplog('Entered new user voting');
			setfileaccess(readonly,denynone);
			reset(uf);

			skipvote:=pynq(getstr(184));

			for i:=1 to filesize(nuvdat) do
			begin
				if i>filesize(nuvdat) then
				begin
					getout;
					exit;
				end;
				seek(nuvdat,i-1);
				read(nuvdat,nuvstuff);

				ok:=TRUE; k:=-1;
				for j:=1 to 20 do
				begin
					if nuvstuff.votes[j].number=usernum then ok:=FALSE;
					if nuvstuff.votes[j].vote=0 then k:=j;
				end;
				if ((k<1) or (k>20)) then ok:=FALSE;

				if not(not ok and skipvote) then
				begin
					nl;

					didvote:=TRUE;
					yes:=0; no:=0; ob:=0;

					for j:=1 to 20 do
						case nuvstuff.votes[j].vote of
							1:inc(yes);
							2:inc(no);
							3:inc(ob);
						end; {case}

					seek(uf,nuvstuff.newusernum);
					read(uf,u);

					repeat

						clearwaves;
						addwave('UN',u.name,txt);
						addwave('U#',cstr(nuvstuff.newusernum),txt);
						addwave('UR',u.realname,txt);
						addwave('US',u.sex,txt);
						addwave('UA',cstr(ageuser(u.bday)),txt);
						addwave('UB',u.bday,txt);
						addwave('BR',u.wherebbs,txt);
						addwave('UC',u.citystate,txt);
						addwave('FC',u.firston,txt);
						addwave('VY',cstr(yes),txt);
						addwave('VN',cstr(no),txt);
						addwave('VA',cstr(ob),txt);

						spstr(458);

						werecomment:=false;
						for ii:=20 downto 1 do
						begin
							if nuvstuff.votes[ii].comment<>'' then
							begin
								clearwaves;
								addwave('UN',caps(nuvstuff.votes[ii].name),txt);
								addwave('CM',nuvstuff.votes[ii].comment,txt);
								spstr(192);
								werecomment:=true;
							end;
						end;
						if werecomment then spstr(459);

						if not ok then
						begin
							spstr(181);
							ch:='VQ';
						end else
							ch:='YNAVQ';
						if (so) then ch:=ch+'DE';

						spstr(183); ch:=ch+'?'^M; onek(c,ch);

						if c=^M then c:='S';
						if (c<>'S') and (not hangup) then
						begin

							repeat { loop so we can val/delete w/o showing info }
								case c of
								 '?':if (cso) then spstr(460) else spstr(461);
								 'Q':begin getout; exit; end;
								 'Y':begin
											 nuvstuff.votes[k].vote:=1;
											 if ((yes+1>=systat^.nuvyes) and (systat^.nuvyes>0)) then
											 begin
												 spstr(188);
												 close(uf);
												 autovalidate(systat^.nuvval,u,nuvstuff.newusernum);
												 setfileaccess(readonly,denynone);
												 reset(uf);
												 sysoplog('Auto-validated '+u.name);
												 c:='X';
											 end;
										 end;
								 'N':begin
											 nuvstuff.votes[k].vote:=2;
											 if (((no+1)>=systat^.nuvno) and (systat^.nuvno>0)) then
											 begin
												 spstr(189);
												 delusr;
												 close(uf);
												 saveurec(u,nuvstuff.newusernum);
												 setfileaccess(readonly,denynone);
												 reset(uf);
												 sysoplog('Auto-deleted '+u.name);
												 c:='X';
											 end;
										 end;
								 'A':nuvstuff.votes[k].vote:=3;
								 'V':begin
											 spstr(182);
											 readasw(nuvstuff.newusernum,systat^.textpath+'NEWUSER');
											 pausescr;
										 end;
								 'E':if (so) then
										 begin
											 close(uf);
											 uedit(nuvstuff.newusernum);
											 setfileaccess(readonly,denynone);
											 reset(uf);
										 end;
						 'X','D':begin
											 if (filesize(nuvdat)>1) then
											 begin
												 ii:=0; iii:=0;
												 while (ii<filesize(nuvdat)) do
												 begin
													 seek(nuvdat,ii); read(nuvdat,nuvstuff);
													 if (ii<>i-1) then if (ii=iii) then
														 inc(iii)
													 else
													 begin
														 seek(nuvdat,iii);
														 write(nuvdat,nuvstuff);
														 inc(iii);
													 end;
													 inc(ii);
												 end;
												 seek(nuvdat,iii);
												 truncate(nuvdat);
											 end else
											 begin
												 rewrite(nuvdat);
												 close(nuvdat);
												 c:='D';
												 spstr(190);
												 close(uf);
												 exit;
											 end;
											 spstr(190);
											 dec(i); c:='D';
										 end;

								end; {case}

								if pos(c,'YNA')<>0 then
								begin
									if pynq(getstr(313)) then
									begin
										spstr(186);
										mpl(65); inputl(cmt,65);
										spstr(462);
									end else cmt:='';
									nuvstuff.votes[k].comment:=cmt;
									nuvstuff.votes[k].name:=thisuser.name;
									nuvstuff.votes[k].number:=usernum;
									seek(nuvdat,i-1);
									write(nuvdat,nuvstuff);
									spstr(187);
								end;

							until (c<>'X') or (hangup);  { Finish "fake" loop }
						end;

						clearwaves;
					until (pos(c,'YNASD')<>0) or (hangup);
				end;
			end;
		end;
		if not(didvote) then spstr(185);
		close(uf);
		close(nuvdat);
	end;
end;



procedure wantlist;
var 
  wl:file of wlrec;
  j:word;
  a,want:wlrec;
  s:wlrec;
  
begin
  spstr(463);
  assign(wl,systat^.datapath+'WANTLIST.DAT');
  setfileaccess(readwrite,denynone);
  reset(wl);
  j:=0;
  while not eof(wl) do
  begin
    read(wl,a);
    sprint(a);
    inc(j);
  end;
  sysoplog('Viewed wantlist');
  if j=0 then spstr(65);
  spstr(464);
  if pynq(getstr(314)) then
  begin
    j:=66-length(nam);
    spstr(315); mpl(j); inputl(want,j);
    if want<>'' then begin
      sysoplog('Added to wantlist: '+want);
      s:=getstr(316);
      s:=substone(s,'~DA',date);
      s:=substone(s,'~WI',want);
      s:=substone(s,'~UN',nam);
      seek(wl,filesize(wl)); write(wl,s);
      spstr(318);
    end else
      spstr(317);
    end;
    if (fso) and (pynq(getstr(319))) then
    begin
      rewrite(wl);
      spstr(320);
      sysoplog('Cleared wantlist');
    end;
    close(wl);
end;



procedure listrumors;
var rumorr:rumorrec;
		rumorf:file of rumorrec;
		whichone:integer;
		I,j:integer;
		abort,next:boolean;
begin
	abort:=false;
	assign(rumorf,systat^.datapath+'RUMOR.DAT');
	setfileaccess(readonly,denynone);
	reset(rumorf);
	if filesize(rumorf)=0 then
		spstr(321)
	else
	begin
		sysoplog('Viewed rumor list');
		aborted:=false; abort:=false; next:=false;
		spstr(465);
		for I:=0 to filesize(rumorf)-1 do
		begin
			if (not aborted) and (not hangup) and (not abort) then
			begin
				clearwaves;
				whichone:=i;
				seek(rumorf,whichone);
				read(rumorf,rumorr);
				addwave('R#',cstr(i+1),txt);
				addwave('RU',rumorr,txt);
				spstr(466);
				wkey(abort,next);
			end;
		end;
		aborted:=aborted or abort;
		if (not aborted) then
		begin
			clearwaves;
			addwave('TR',cstr(filesize(rumorf)),txt);
			addwave('TL',cstr(whichone+1),txt);
			spstr(467);
			clearwaves;
		end;
	end;
	close(rumorf);
end;

procedure confchange(mstr:astr);
var s:astr; c:char;
		i:byte;
		conff:file of confrrec;
		conf:confrrec;
begin
	if (mstr<>'') then
		case mstr[1] of
			'@'..'Z':
					begin
						assign(conff,systat^.datapath+'CONF.DAT');
						setfileaccess(readwrite,denynone);
						reset(conff);
						seek(conff,ord(mstr[1])-64);
						read(conff,conf);
						if (conf.active) and (aacs(conf.acs)) then
						begin
							conference:=conf;
							thisuser.conference:=mstr[1];
						end;
						close(conff);
					end;
		end
	else begin
		assign(conff,systat^.datapath+'CONF.DAT');
		setfileaccess(readwrite,denynone);
		reset(conff);
		s:=^M;
		spstr(656);
		clearwaves;
		for i:=0 to 26 do
		begin
			seek(conff,i);
			read(conff,conf);
			if (conf.active) and (aacs(conf.acs)) then
			begin
				addwave('CC',chr(i+64),txt);
				addwave('CN',conf.name,txt);
				spstr(657);
				s:=s+chr(i+64);
			end;
			clearwaves;
		end;
		spstr(658);
		onek(c,s);
		if (c in ['@'..'Z']) then
		begin
			seek(conff,ord(c)-64);
			read(conff,conf);
			if (conf.active) and (aacs(conf.acs)) then
			begin
				conference:=conf;
				thisuser.conference:=c;
			end;
		end;
		close(conff);
	end;
	if (systat^.compressmsgbases) or (systat^.compressfilebases) then newcomptables;
end;

end.
