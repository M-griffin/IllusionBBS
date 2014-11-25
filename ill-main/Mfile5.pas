(*****************************************************************************)
(* Illusion BBS - File routines [5/15] (minidos, browse, upload all)				 *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
	{$D+,L+}
{$ELSE}
	{$D-,L-}
{$ENDIF}

unit Mfile5;

interface

uses
  crt, dos,
  common, sysop4, Mfile0, Mfile1, Mfile2, Mfile4, Mfile6, Mfile8, Mfile9, Mfile11,
  execbat, common2;

procedure minidos;
procedure uploadall;

implementation

uses MsgF;

procedure minidos;
var curdir,s,s1:astr;
		abort,next,done,restr,nocmd,nospace:boolean;
		xword:array[1..9] of astr;

	procedure parse(s:astr);
	var i,j,k:integer;
	begin
		for i:=1 to 9 do xword[i]:='';
		i:=1; j:=1; k:=1;
		if (length(s)=1) then xword[1]:=s;
		while (i<length(s)) do begin
			inc(i);
			if ((s[i]=' ') or (length(s)=i)) then begin
				if (length(s)=i) then inc(i);
				xword[k]:=copy(s,j,(i-j));
				j:=i+1;
				inc(k);
			end;
		end;
	end;

	procedure versioninfo;
	begin
		nl;
		sprint('Illusion Mini-DOS Version '+ver);
    sprint('  (C)Copyright 1992-1998 Illusion Development Team');
		nl;
	end;

	procedure docmd(cmd:astr);
	var fi:file of byte;
			f:file;
			ps,ns,es,op,np:astr;
			s1,s2,s3:astr;
			numfiles,tsiz:longint;
			p,retlevel,i,j:integer;
			done1,b,dok,ok,wasrestr:boolean;

		function restr1:boolean;
		begin
			restr1:=restr;
			if (restr) then wasrestr:=TRUE;
		end;

	begin
		wasrestr:=FALSE;
		abort:=FALSE; next:=FALSE; nocmd:=FALSE;

		s:=allcaps(cmd);
		while (s<>'') and (s[1]=' ') do delete(s,1,1);
		while (s<>'') and (s[length(s)]=' ') do delete(s,length(s),1);
		if (copy(s,1,3)='CD.') then insert(' ',s,3);
		if (copy(s,1,3)='CD\') then insert(' ',s,3);
		if (pos('/',s)<>0) then
		begin
			i:=1;
			while (i<=length(s)) do
			begin
				if (s[i]='/') and (s[i-1]<>' ') and (i>1) then insert(' ',s,i);
				inc(i);
			end;
		end;
		parse(s);

		s:=xword[1];
		if ((pos('\',xword[2])<>0) or (pos('..',xword[2])<>0)) and (restr) then exit;

		if (s='?') or (s='HELP') then printf('minidos') else

		if (s='EDIT') then begin
			if ((exist(xword[2])) and (xword[2]<>'')) then
				tedit(xword[2])
			else
				if (xword[2]='') then tedit1 else tedit(xword[2]);
			nl;
		end else

		if (s='EXIT') or (s='QUIT') then done:=TRUE else

		if ((s='DEL') or (s='DELETE') or (s='ERASE')) and (not restr1) then begin
			if ((not exist(xword[2])) and (not iswildcard(xword[2]))) or (xword[2]='') then
				print('File not found')
			else begin
				xword[2]:=fexpand(xword[2]);
				ffile(xword[2]);
				if (not found) then
					print('File not found')
				else
					repeat
						if not ((dirinfo.attr and VolumeID=VolumeID) or
										(dirinfo.attr and Directory=Directory)) then begin
							assign(f,dirinfo.name);
							{$I-} erase(f); {$I+}
							if (ioresult<>0) then print('Cannot delete '+dirinfo.name);
						end;
						nfile;
					until (not found) or (hangup);
			end;
			nl;
		end else

		if (s='TYPE') then begin
			printf(fexpand(xword[2]));
			if (nofile) then sprint('File not found|LF') else nl;
		end else

		if ((s='FIND') or (s='WHEREIS')) then begin
			nl; sprint('Find files on the PATH.');
			sprint('Enter filename to search for');
			pchar; input(s1,40);
			while(copy(s1,1,1)=' ') do s1:=copy(s1,2,length(s1)-1);
			fsplit(s1,ps,ns,es); b:=FALSE;
			s1:=ns+es; s2:=fsearch(s1,getenv('PATH'));
			if (s2='') then b:=TRUE; nl;
			if (not b) then s2:=fexpand(s2);
			if b then sprint('File not found') else sprint('Found '+s2);
			nl;
		end else

		if ((s='REN') or (s='RENAME')) then begin
			if ((not exist(xword[2])) and (xword[2]<>'')) then
				print('File not found')
			else begin
				xword[2]:=fexpand(xword[2]);
				assign(f,xword[2]);
				{$I-} rename(f,xword[3]); {$I+}
				if (ioresult<>0) then print('File not found');
				nl;
			end;
		end else

		if (s='DIR') then begin
			b:=TRUE;
			for i:=2 to 9 do if (xword[i]='/W') then begin
				b:=FALSE;
				xword[i]:='';
			end;
			if (xword[2]='') then xword[2]:='*.*';
			s1:=curdir;
			xword[2]:=fexpand(xword[2]);
			fsplit(xword[2],ps,ns,es);
			s1:=ps; s2:=ns+es;
			if (s2='') then s2:='*.*';
			if (not iswildcard(xword[2])) then begin
				ffile(xword[2]);
				if ((found) and (dirinfo.attr=directory)) or
					 ((length(s1)=3) and (s1[3]='\')) then begin   {* root directory *}
					s1:=bslash(TRUE,xword[2]);
					s2:='*.*';
				end;
			end;
			nl; dir(s1,s2,b); nl;
		end else

		if ((s='CD') or (s='CHDIR')) and (not restr1) then begin
			xword[2]:=fexpand(xword[2]);
			if (xword[2]<>'') then {$I-} chdir(xword[2]); {$I+}
			if (xword[2]='') or (ioresult<>0) then print('Invalid directory');
			nl;
		end else

		if ((s='MD') or (s='MKDIR')) and (not restr1) then begin
			if (xword[2]<>'') then {$I-} mkdir(xword[2]); {$I+}
			if (xword[2]='') or (ioresult<>0) then print('Unable to create directory');
			nl;
		end else

		if ((s='RD') or (s='RMDIR')) and (not restr1) then begin
			if (xword[2]<>'') then {$I-} rmdir(xword[2]); {$I+}
			if (xword[2]='') or (ioresult<>0) then print('Unable to remove directory');
			nl;
		end else

		if (s='COPY') and (not restr1) then begin
			if (xword[2]<>'') then begin
				if (iswildcard(xword[3])) then
					print('Wildcards not allowed in destination parameter!')
				else begin
					if (xword[3]='') then xword[3]:=curdir;
					xword[2]:=bslash(FALSE,fexpand(xword[2]));
					xword[3]:=fexpand(xword[3]);
					ffile(xword[3]);
					b:=((found) and (dirinfo.attr and directory=directory));
					if ((not b) and (copy(xword[3],2,2)=':\') and (length(xword[3])=3)) then b:=TRUE;
					fsplit(xword[2],op,ns,es);
					op:=bslash(TRUE,op);
					if (b) then
						np:=bslash(TRUE,xword[3])
					else begin
						fsplit(xword[3],np,ns,es);
						np:=bslash(TRUE,np);
					end;
					j:=0;
					abort:=FALSE; next:=FALSE;
					ffile(xword[2]);
					while (found) and (not abort) and (not hangup) do begin
						if (not ((dirinfo.attr=directory) or (dirinfo.attr=volumeid))) then
						begin
							s1:=op+dirinfo.name;
							if (b) then s2:=np+dirinfo.name else s2:=np+ns+es;
							print(s1+' -> '+s2+' :');
							copyfile(ok,nospace,TRUE,s1,s2);
							if (ok) then begin
								inc(j);
								nl;
							end else
								if (nospace) then sprompt('|R - Insufficient space')
								else sprompt('|R - Copy failed');
							nl;
						end;
						if (not empty) then wkey(abort,next);
						nfile;
					end;
					if (j<>0) then begin
						prompt('  '+cstr(j)+' file');
						if (j<>1) then prompt('s');
						print(' copied');
					end;
				end;
			end;
			nl;
		end else

		if (s='MOVE') and (not restr1) then begin
			if (xword[2]<>'') then begin
				if (iswildcard(xword[3])) then
					print('Wildcards not allowed in destination parameter')
				else begin
					if (xword[3]='') then xword[3]:=curdir;
					xword[2]:=bslash(FALSE,fexpand(xword[2]));
					xword[3]:=fexpand(xword[3]);
					ffile(xword[3]);
					b:=((found) and (dirinfo.attr and directory=directory));
					if ((not b) and (copy(xword[3],2,2)=':\') and (length(xword[3])=3)) then b:=TRUE;
					fsplit(xword[2],op,ns,es);
					op:=bslash(TRUE,op);
					if (b) then
						np:=bslash(TRUE,xword[3])
					else begin
						fsplit(xword[3],np,ns,es);
						np:=bslash(TRUE,np);
					end;
					j:=0;
					abort:=FALSE; next:=FALSE;
					ffile(xword[2]);
					while (found) and (not abort) and (not hangup) do begin
						if (not ((dirinfo.attr=directory) or (dirinfo.attr=volumeid))) then
						begin
							s1:=op+dirinfo.name;
							if (b) then s2:=np+dirinfo.name else s2:=np+ns+es;
							print(s1+' -> '+s2+' :');
							movefile(ok,nospace,TRUE,s1,s2);
							if (ok) then begin
								inc(j);
								nl;
							end else
								if (nospace) then sprompt('|R - Insufficient space')
								else sprompt('|R - Move failed');
							nl;
						end;
						if (not empty) then wkey(abort,next);
						nfile;
					end;
					if (j<>0) then begin
						prompt('  '+cstr(j)+' file');
						if (j<>1) then prompt('s');
						print(' moved');
					end;
				end;
			end;
			nl;
		end else

		if (s='CLS') then cls else

		if (length(s)=2) and (s[1]>='A') and (s[1]<='Z') and (s[2]=':') and (not restr1) then begin
			{$I-} getdir(ord(s[1])-64,s1); {$I+}
			if (ioresult<>0) then print('Invalid drive.')
			else begin
				{$I-} chdir(s1); {$I+}
				if (ioresult<>0) then begin
					sprint('Invalid drive|LF');
					chdir(curdir);
				end;
			end;
		end else

		if (s='IFL') then begin
			if (xword[2]='') then begin
				sprint('Syntax: "IFL filename"');
				nl;
			end else begin
				s1:=xword[2];
				if (pos('.',s1)=0) then s1:=s1+'*.*';
				lfi(s1,abort,next);
			end;
		end else

		if (s='SEND') then begin
			if exist(xword[2]) then
				unlisted_download(fexpand(xword[2]))
			else
				sprint('File not found|LF');
		end else

		if (s='RECEIVE') and (not restr1) then
		begin
			SetFileAccess(ReadOnly,DenyNone);
			reset(xf);
			done1:=false;
			repeat
				spstr(117); mpkey(s2);
				if (s2='?') then
				begin
					nl;
					showprots(true,false,true,false);
				end else
				begin
					p:=findprot(s2,true,false,true,false);
					if (p=-99) then print('Wrong!') else done1:=true;
				end;
			until (done1) or (hangup);
			if (p<>-10) then
			begin
				seek(xf,p);
				read(xf,protocol);
				close(xf);
				dok:=true;
				lil:=0;
				nl; nl;
				if (useron) then star('Ready to receive batch queue!');
				lil:=0;
				shel(caps(thisuser.name)+' is uploading through MiniDOS');
				systat^.swapshell:=systat^.swapshell and systat^.swapxfer;
				execbatch(dok,FALSE,'IRCV'+cstr(nodenum)+'.bat','i_test',curdir+'\',
									bproline1(systat^.protpath+protocol.ulcmd),-1);
				readsystat;
				shel2;
			end else
				close(xf);
		end else

		if (s='VER') then versioninfo else

		if (s='EXT') and (xword[2]='FORMAT') then begin
			nl;
			print('Unauthorized FORMAT call!  Sysop has been notified.');
			sl1('|RUser tried to execute FORMAT through Mini-DOS (Using EXT)!!');
			nl;
		end else

		if (s='DIRSIZE') then begin
			if (xword[2]='') then print('Needs a parameter')
			else begin
				numfiles:=0; tsiz:=0;
				ffile(xword[2]);
				while (found) do begin
					inc(tsiz,dirinfo.size);
					inc(numfiles);
					nfile;
				end;
				if (numfiles=0) then sprint('No files found')
					else print('"'+allcaps(xword[2])+'": '+cstrl(numfiles)+' files, '+
										 cstrl(tsiz)+' bytes.');
			end;
			nl;
		end else

		if (s='DISKFREE') then begin
			if (xword[2]='') then j:=exdrv(curdir) else j:=exdrv(xword[2]);
			print(cstrl(freek(j)*1024)+' bytes free on '+chr(j+64)+':');
			nl;
		end else

		if (s='EXT') and (not restr1) and (copy(s,1,10)<>'EXT FORMAT') then begin
			s1:=cmd;
			j:=pos('EXT',allcaps(s1))+3; s1:=copy(s1,j,length(s1)-(j-1));
			while (copy(s1,1,1)=' ') do s1:=copy(s1,2,length(s1)-1);
			if ((incom) or (outcom)) then
				s1:=s1+' >'+systat^.remdevice+' <'+systat^.remdevice;
			if (length(s1)>127) then begin print('Command too long'); nl; end
			else
				shelldos(TRUE,s1,retlevel);
		end else

		if ((s='CONVERT') or (s='CVT')) and (not restr1) then begin
			if (xword[2]='') then begin
				nl;
				print(s+' - Illusion Archive Conversion Command -');
				nl;
				print('Syntax is:   "'+s+' <Old Archive-name> <New Archive-extension>"');
				nl;
				print('Illusion will convert from the one archive format to the other.');
				print('You only need to specify the 3-letter extension of the new format.');
				nl;
			end else begin
				if (not exist(xword[2])) or (xword[2]='') then sprint('File not found|LF')
				else begin
					i:=arctype(xword[2]);
					if (i=0) then invarc
					else begin
						s3:=xword[3]; s3:=copy(s3,length(s3)-2,3);
						j:=arctype('FILENAME.'+s3);
						fsplit(xword[2],ps,ns,es);
						if (length(xword[3])<=3) and (j<>0) then
							s3:=ps+ns+'.'+systat^.filearcinfo[j].ext
						else
							s3:=xword[3];
						if (j=0) then invarc
						else begin
							ok:=TRUE;
							conva(ok,i,j,modemr.temppath+'ARCHIVE\',sqoutsp(fexpand(xword[2])),
										sqoutsp(fexpand(s3)));
							if (ok) then begin
								assign(fi,sqoutsp(fexpand(xword[2])));
								{$I-} erase(fi); {$I+}
								if (ioresult<>0) then
									star('Unable to delete original: "'+
											 sqoutsp(fexpand(xword[2]))+'"');
							end else
								star('Conversion unsuccessful');
						end;
					end;
				end;
			end;
		end else

		if ((s='UNZIP') or (s='PKUNZIP')) and (not restr1) then begin
			if (xword[2]='') then begin
				nl;
				print(s+' - Illusion Archive Decompression Command.');
				nl;
				print('Syntax: "'+s+' <Archive-name> Archive filespecs..."');
				nl;
				print('The archive type can be ANY archive format which has been');
				print('configured into Illusion via System Configuration.');
				nl;
			end else begin
				i:=arctype(xword[2]);
				if (not exist(xword[2])) then sprint('File not found|LF') else
					if (i=0) then invarc
					else begin
						s3:='';
						if (xword[3]='') then s3:=' *.*'
						else
							for j:=3 to 9 do
								if (xword[j]<>'') then s3:=s3+' '+fexpand(xword[j]);
						s3:=copy(s3,2,length(s3)-1);
						shel1;
						systat^.swapshell:=systat^.swapshell and systat^.swapxfer;
						pexecbatch(TRUE,'iuzp'+cstr(nodenum)+'.bat','',bslash(TRUE,curdir),
											 arcmci(systat^.filearcinfo[i].unarcline,fexpand(xword[2]),s3,''),
											 retlevel);
						shel2;
					end;
			end;
		end else

		if ((s='ZIP') or (s='PKZIP')) and (not restr1) then begin
			if (xword[2]='') then begin
				nl;
				print(s+' - Illusion Archive Compression Command.');
				nl;
				print('Syntax: "'+s+' <Archive-name> Archive filespecs..."');
				nl;
				print('The archive type can be ANY archive format which has been');
				print('configured into Illusion via System Configuration.');
				nl;
			end else begin
				i:=arctype(xword[2]);
				if (i=0) then invarc
				else begin
					s3:='';
					if (xword[3]='') then s3:=' *.*'
					else
						for j:=3 to 9 do
							if (xword[j]<>'') then s3:=s3+' '+fexpand(xword[j]);
					s3:=copy(s3,2,length(s3)-1);
					shel1;
					systat^.swapshell:=systat^.swapshell and systat^.swapxfer;
					pexecbatch(TRUE,'izip'+cstr(nodenum)+'.bat','',bslash(TRUE,curdir),
										 arcmci(systat^.filearcinfo[i].arcline,fexpand(xword[2]),s3,''),
										 retlevel);
					shel2;
				end;
			end;
		end else

		begin
			nocmd:=TRUE;
			if (s<>'') then
				if (not wasrestr) then begin
					print('Bad command or file name');
					nl;
				end else begin
					print('Restricted command');
					nl;
				end;
		end;
	end;

begin
	chdir(bslash(FALSE,systat^.textpath));
	restr:=(not cso);
	done:=FALSE;
	nl;
	sprint('|CType EXIT to return to Illusion');
	nl;
	versioninfo;
	if (restr) then begin
		print('Only *.MSG, *.ANS, *.40C and *.TXT files may be modified.');
		print('Activity restricted to "'+systat^.textpath+'" path only.');
		nl;
	end;
	repeat
		getdir(0,curdir);
		sprompt('|c'+curdir+'> |C'); inputl(s1,128);
		docmd(s1);
		if (not nocmd) then sysoplog('[MiniDOS] > '+s1);
	until (done) or (hangup);
	chdir(start_dir);
end;

procedure uploadall;
var bn:integer;
		abort,next,sall:boolean;
    oldconf:char;

	procedure uploadfiles(b:integer; var abort,next:boolean);
	var fi:file of byte;
			f:ulfrec;
			v:verbrec;
			fn:astr;
			convtime:real;
			oldboard,pl,rn,gotpts,i:integer;
			c:char;
			ok,convt,firstone:boolean;
	begin
		oldboard:=fileboard;
		firstone:=TRUE;
		if (fileboard<>b) then changefileboard(b);
		if (fileboard=b) then begin
			loaduboard(fileboard);
			nl;
			sprint('Scanning '+memuboard.name+'|w ('+memuboard.dlpath+')');
			ffile(memuboard.dlpath+'*.*');
			while (found) do begin
				if not ((dirinfo.attr and VolumeID=VolumeID) or
								(dirinfo.attr and Directory=Directory)) then begin
					fn:=align(dirinfo.name);
					recno(fn,pl,rn); { loads memuboard again .. }
					if (rn=-1) then begin
						assign(fi,memuboard.dlpath+fn);
						SetFileAccess(Readonly,DenyNone);
						{$I-} reset(fi); {$I+}
						if (ioresult=0) then begin
							f.blocks:=trunc((filesize(fi)+127.0)/128.0);
							close(fi);
							if (firstone) then pbn(abort,next);
							firstone:=FALSE;
							sprompt(' |C'+fn+' |B'+mln(cstr(f.blocks div 8)+'k',6)+' New:');
							mpl(50); inputl(f.description,50);
							ok:=TRUE;
							if (copy(f.description,1,1)='.') then begin
								if (length(f.description)=1) then begin
									abort:=TRUE;
									exit;
								end;
								c:=upcase(f.description[2]);
								case c of
									'D':begin
												{$I-} erase(fi); {$I+} i:=ioresult;
												ok:=FALSE;
											end;
									'N':begin
												next:=TRUE;
												exit;
											end;
									'S':ok:=FALSE;
								end;
							end;
							if (ok) then begin
								v.descr[1]:='';
								if (f.description<>'') then begin
									i:=1;
									repeat
										prompt(mln(' ',25));
										mpl(50);
										inputl(v.descr[i],50);
										if (v.descr[i]='') then i:=9;
										inc(i);
									until ((i=10) or (hangup));
									if (v.descr[1]<>'') then f.vpointer:=nfvpointer;
								end;
								if (v.descr[1]='') then f.vpointer:=-1;
								convt:=TRUE;
								arcstuff(ok,convt,f.blocks,convtime,FALSE,memuboard.dlpath,fn,f,v);
								doffstuff(f,fn,gotpts);
								if (ok) then begin
									newff(f,v);
									sysoplog('|CUpload "'+sqoutsp(fn)+'" on '+memuboard.name);
								end;
							end;
						end;
					end;
				end;
				nfile;
			end;
		end;
		fileboard:=oldboard;
	end;

begin
	nl; sprint('|WUpload files into directories|B -'); nl;
  abort:=FALSE; next:=FALSE; oldconf:=thisuser.conference;
	sall:=pynq('Search all directories');
  if sall then if pynq('Ignore conferences') then thisuser.conference:='@';
	nl;
	print('Enter "." to stop uploading, ".S" to skip this file, ".N" to skip');
	print('to the next directory, and ".D" to delete the file.');
	if (sall) then begin
		bn:=0;
		while (not abort) and (bn<=maxulb) and (not hangup) do begin
			if (fbaseac(bn)) then uploadfiles(bn,abort,next);
			inc(bn);
			wkey(abort,next);
			if (next) then abort:=FALSE;
		end;
	end else
		uploadfiles(fileboard,abort,next);
  thisuser.conference:=oldconf;
end;

end.
