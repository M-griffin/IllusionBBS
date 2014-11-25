(*****************************************************************************)
(* Illusion Main File System BBS 				             *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O+,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit NewFile2;

interface

uses
  crt, 
  dos, 
  myio, 
  common, 
  misc2, 
  execbat, 
  common2, 
  sysop4, 
  mmodem, 
  miscx;
  
  
  (* File 5 Functions ------------------------------------------- *)
  
  procedure minidos;
  procedure uploadall;
  
  
  (* File 4 Functions ------------------------------------------- *)
  
  function substall(src,old,new:astr):astr;
  function getbyte(var fp:file):char;
  procedure abend(var abort,next:boolean; b:word);
  procedure details(var abort,next:boolean);
  procedure lfi(fn:astr; var abort,next:boolean);
  procedure lfin(rn:integer; var abort,next:boolean);
  procedure lfii;
  
  const
    L_SIG=$04034b50;   {* ZIP local file header signature *}
    C_SIG=$02014b50;   {* ZIP central dir file header signature *}
    E_SIG=$06054b50;   {* ZIP end of central dir signature *}
    Z_TAG=$fdc4a7dc;   {* ZOO entry identifier *}
  
    EXTS=7;     {* number of default extensions *}
  
    filext:array[0..EXTS-1] of string[4] = (
      '.ZIP',   {* ZIP format archive *}
      '.ARJ',   {* ARJ format archive *}
      '.ARC',   {* ARC format archive *}
      '.PAK',   {* ARC format archive (PAK.EXE) *}
      '.ZOO',   {* ZOO format archive *}
      '.LZH',   {* LZH format archive *}
      '.RAR');  {* RAR format archive *}
  
  type
    zipfilerec=record   {* structure of ZIP archive file header *}
                 version:integer;    {* version needed to extract *}
                 bit_flag:integer;   {* general purpose bit flag *}
                 method:integer;     {* compression method *}
                 mod_time:integer;   {* last mod file time *}
                 mod_date:integer;   {* last mod file date *}
                 crc:longint;        {* CRC-32 *}
                 c_size:longint;     {* compressed size *}
                 u_size:longint;     {* uncompressed size *}
                 f_length:integer;   {* filename length *}
                 e_length:integer;   {* extra field length *}
               end;
  
    arjfilerec=record  {* structure of an ARJ archive file header *}
                 FHeadSize:Byte;     {* *}
                 ArcVer1:byte;       {* *}
                 ArcVer2:Byte;       {* *}
                 HostOS:byte;        {* *}
                 ARJFlags:Byte;      {* *}
                 Method:Byte;        {* compression method *}
                 R1:byte;            {* *}
                 R2:Byte;            {* *}
                 mod_time:word;      {* modification time (DOS format) *}
                 mod_date:word;      {* modification date (DOS format) *}
                 C_size:LongInt;     {* compressed size *}
                 U_Size:Longint;     {* uncompressed size *}
                 CRC:LongInt;        {* CRC *}
                 ENP:word;           {* *}
                 FM:word;            {* *}
                 HostData:Word;      {* *}
               end;
  
    arcfilerec=record   {* structure of ARC archive file header *}
                 filename:array[0..12] of char; {* filename *}
                 c_size:longint;     {* compressed size *}
                 mod_date:integer;   {* last mod file date *}
                 mod_time:integer;   {* last mod file time *}
                 crc:integer;        {* CRC *}
                 u_size:longint;     {* uncompressed size *}
               end;
  
    zoofilerec=record   {* structure of ZOO archive file header *}
                 tag:longint;     {* tag -- redundancy check *}
                 typ:byte;        {* type of directory entry (always 1 for now) *}
                 method:byte;     {* 0 = Stored, 1 = Crunched *}
                 next:longint;    {* position of next directory entry *}
                 offset:longint;  {* position of this file *}
                 mod_date:word;   {* modification date (DOS format) *}
                 mod_time:word;   {* modification time (DOS format) *}
                 crc:word;        {* CRC *}
                 u_size:longint;  {* uncompressed size *}
                 c_size:longint;  {* compressed size *}
                 major_v:char;    {* major version number *}
                 minor_v:char;    {* minor version number *}
                 deleted:byte;    {* 0 = active, 1 = deleted *}
                 struc:char;      {* file structure if any *}
                 comment:longint; {* location of file comment (0 = none) *}
                 cmt_size:word;   {* length of comment (0 = none) *}
                 fname:array[0..12] of char; {* filename *}
                 var_dirlen:integer; {* length of variable part of dir entry *}
                 tz:char;         {* timezone where file was archived *}
                 dir_crc:word;    {* CRC of directory entry *}
               end;
  
    lzhfilerec=record   {* structure of LZH archive file header *}
                 h_length:byte;   {* length of header *}
                 h_cksum:byte;    {* checksum of header bytes *}
                 method:array[1..5] of char; {* compression type "-lh#-" *}
                 c_size:longint;  {* compressed size *}
                 u_size:longint;  {* uncompressed size *}
                 mod_time:integer;{* last mod file time *}
                 mod_date:integer;{* last mod file date *}
                 attrib:integer;  {* file attributes *}
                 f_length:byte;   {* length of filename *}
                 crc:integer;     {* crc *}
               end;
  
     rarheaderrec=record
                 b:array[1..7] of byte;
               end;
     rarfilerec=record
                  packsize:longint;
                  unpacksize:longint;
                  hostos:byte; { 0 dos 1 os/2 }
                  filecrc:longint;
                  mod_time:integer;
                  mod_date:integer;
                  rarver:byte;
                  method:byte;
                  fnamesize:integer;
                  attr:longint;
                end;
  
    outrec=record   {* output information structure *}
             filename:string[255];             {* output filename *}
             date:integer;                     {* output date *}
             time:integer;                     {* output time *}
             typ:integer;                      {* output storage type *}
             csize:longint;                    {* output compressed size *}
             usize:longint;                    {* output uncompressed size *}
           end;
  
  var
    accum_csize:longint;    {* compressed size accumulator *}
    accum_usize:longint;    {* uncompressed size accumulator *}
    files:integer;          {* number of files *}
    level:integer;          {* output directory level *}
    filetype:integer;       {* file type (1=ZIP, 2=ARJ, 3=ARC, 4=LZH, 5=ZOO) *}
    out:^outrec;
    aborted:boolean;  
    
    
  const 
    ulffopen1:boolean=TRUE;   { whether ulff has been opened before }
  var 
    dirinfo:searchrec; found:boolean;
    
    var locbatup:boolean;
  
  
  
  (* File 2 Functions ------------------------------------------- *)
  
  procedure copyfile(var ok,nospace:boolean; showprog:boolean;
                     srcname,destname:astr);
  procedure movefile(var ok,nospace:boolean; showprog:boolean;
                     srcname,destname:astr);
  
  
  (* File 1 Functions ------------------------------------------- *)
  

(*
var
    locbatup:boolean;
*)
  
  
  procedure dodl(fpneed:integer);
  procedure doul(pts:integer);
  procedure showuserfileinfo;
  function okdl(f:ulfrec):boolean;
  procedure dlx(f1:ulfrec; rn:integer; var abort:boolean);
  procedure dl(fn:astr);
  procedure dodescrs(var f:ulfrec; var v:verbrec; var pl:integer; var tosysop:boolean);
  procedure writefv(rn:integer; f:ulfrec; v:verbrec);
  procedure newff(f:ulfrec; v:verbrec);
  procedure doffstuff(var f:ulfrec; fn:astr; var gotpts:integer);
  procedure arcstuff(var ok,convt:boolean; var blks:longint; var convtime:real;
                     itest:boolean; fpath:astr; var fn:astr; var f:ulfrec;
                     var v:verbrec);
  procedure idl;
  procedure iul;
  
  procedure fbaselist;
  procedure unlisted_download(s:astr);
  procedure do_unlisted_download;
  function nfvpointer:longint;
  
  
  
  (* File 0 Functions ------------------------------------------- *)
(*

  const
    ulffopen1:boolean=TRUE;   { whether ulff has been opened before }

  var
    dirinfo:searchrec; found:boolean;

  var
    found:boolean;
*)
  
  function align(fn:astr):astr;
  function baddlpath:boolean;
  function bslash(b:boolean; s:astr):astr;
  function existdir(s:astr):boolean;
  procedure ffile(fn:astr);
  procedure fileinfo(f:ulfrec; editinfo:boolean; var abort,next:boolean);
  procedure fiscan(var pl:integer);
  function fit(f1,f2:astr):boolean;
  procedure gfn(var fn:astr);
  function isgifdesc(d:astr):boolean;
  function isgifext(fn:astr):boolean;
  function isul(s:astr):boolean;
  function iswildcard(s:astr):boolean;
  procedure nfile;
  procedure nrecno(fn:astr; var pl,rn:integer);
  procedure recno(fn:astr; var pl,rn:integer);
  function rte:real;
  procedure star(s:astr);
  function stripname(i:astr):astr;
  function tcheck(s:real; i:integer):boolean;
  function tchk(s:real; i:real):boolean;


implementation


(* File 5 Functions ------------------------------------------- *)

uses
  newfile;



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
							conva(ok,i,j,modemr^.temppath+'ARCHIVE\',sqoutsp(fexpand(xword[2])),
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



(* File 4 Functions ------------------------------------------- *)


function substall(src,old,new:astr):astr;
var p:integer;
begin
  p:=1;
  while p>0 do begin
    p:=pos(old,src);
    if p>0 then begin
      insert(new,src,p+length(old));
      delete(src,p,length(old));
    end;
  end;
  substall:=src;
end;

procedure lbrl(fn:astr; var abort,next:boolean);
var f:file;
    c,n,n1:integer;
    x:record
        st:byte;
        name:array[1..8] of char;
        ext:array[1..3] of char;
        index,len:integer;
        fil:array[1..16] of byte;
      end;
    i:astr;
begin
  nl;
  assign(f,fn);
  SetFileAccess(ReadOnly,DenyNone);
  reset(f,32);
  blockread(f,x,1);
  c:=x.len*4-1;
  for n:=1 to c do begin
    blockread(f,x,1); i:='';
    if (x.st=0) and not abort then begin
      for n1:=1 to 8 do i:=i+x.name[n1];
      i:=i+'.';
      for n1:=1 to 3 do i:=i+x.ext[n1];
      i:=align(i)+' '+mrn(cstrr(x.len*128.0,10),7);
      printacr(i,abort,next);
    end;
  end;
  close(f);
end;

function mnz(l:longint; w:integer):astr;
var s:astr;
begin
  s:=cstrl(l);
  while length(s)<w do s:='0'+s;
  mnz:=s;
end;

function mnr(l:longint; w:integer):astr;
begin
  mnr:=mrn(cstrl(l),w);
end;

{*------------------------------------------------------------------------*}

procedure abend(var abort,next:boolean; b:word);
begin
  spstr(b);
  aborted:=TRUE;
  abort:=TRUE;
  next:=TRUE;
end;

{*------------------------------------------------------------------------*}

procedure details(var abort,next:boolean);
var i,month,day,year,hour,minute,typ:integer;
    ampm:string[2];
    ratio:longint;
begin
  {*  details - Calculate and display details line.
   *}

  typ:=out^.typ;
  for i:=1 to length(out^.filename) do
    out^.filename[i]:=upcase(out^.filename[i]);
  day:=out^.date and $1f;                {* day = bits 4-0 *}
  month:=(out^.date shr 5) and $0f;      {* month = bits 8-5 *}
  year:=((out^.date shr 9) and $7f)+80;  {* year = bits 15-9 *}
  minute:=(out^.time shr 5) and $3f;     {* minute = bits 10-5 *}
  hour:=(out^.time shr 11) and $1f;      {* hour = bits 15-11 *}

  if (month>12) then dec(month,12);     {* adjust for month > 12 *}
  if (year>99) then dec(year,100);      {* adjust for year > 1999 *}
  if (hour>23) then dec(hour,24);       {* adjust for hour > 23 *}
  if (minute>59) then dec(minute,60);   {* adjust for minute > 59 *}

  if (hour<12) then ampm:='am' else ampm:='pm'; {* determine AM/PM *}
  if (hour=0) then hour:=12;                    {* convert 24-hour to 12-hour *}
  if (hour>12) then dec(hour,12);

  if (out^.usize=0) then ratio:=0 else   {* ratio is 0% for null-length file *}
    ratio:=100-((out^.csize*100) div out^.usize);
  if ratio>99 then ratio:=99;

  clearwaves;
  addwave('MT',getstr(typ+550),txt);
  addwave('DM',mnz(month,2),txt);
  addwave('DD',mnz(day,2),txt);
  addwave('DY',mnz(year,2),txt);
  addwave('TH',mnz(hour,2),txt);
  addwave('TM',mnz(minute,2),txt);
  addwave('AP',ampm,txt);
  addwave('US',cstrl(out^.usize),txt);
  addwave('CS',cstrl(out^.csize),txt);
  addwave('CR',cstrl(ratio),txt);
  addwave('FN',out^.filename,txt);
  spstr(583);
  wkey(abort,next);
  clearwaves;

  inc(accum_csize,out^.csize);  {* adjust accumulators and counter *}
  inc(accum_usize,out^.usize);
  inc(files);
end;

{*------------------------------------------------------------------------*}

procedure final(var abort,next:boolean);
var ratio:longint;
begin
  {*  final - Display final totals and information.
   *}

  if accum_usize=0 then ratio:=0    {* ratio is 0% if null total length *}
  else
    ratio:=100-((accum_csize*100) div accum_usize);
  if ratio>99 then ratio:=99;

  clearwaves;
  addwave('US',cstrl(accum_usize),txt);
  addwave('CS',cstrl(accum_csize),txt);
  addwave('CR',cstrl(ratio),txt);
  addwave('TF',cstr(files),txt);
  addwave('FS',aonoff(files<>1,'s',''),txt);
  spstr(584);
  clearwaves;
end;

{*------------------------------------------------------------------------*}

function getbyte(var fp:file):char;
var buf:array[0..0] of char;
    numread:word;
    c:char;
    abort,next:boolean;
begin
  {*  getbyte - Obtains character from file pointed to by fp.
   *            Aborts to DOS on error.
   *}

  if (not aborted) then begin
    blockread(fp,c,1,numread);
    if numread=0 then begin
      close(fp);
      abend(abort,next,577);
    end;
    getbyte:=c;
  end;
end;

{*------------------------------------------------------------------------*}

procedure zip_proc(var fp:file; var abort,next:boolean);
var zip:zipfilerec;
    buf:array[0..25] of byte;
    signature:longint;
    numread:word;
    i,stat:integer;
    c:char;
begin
  {* zip_proc - Process entry in ZIP archive.
  *}

  while (not aborted) do begin {* set up infinite loop (exit is within loop) *}
    blockread(fp,signature,4,numread); if numread<>4 then abend(abort,next,578);
    if abort then exit;
    if (signature=C_SIG) or (signature=E_SIG) or (aborted) then
      exit;
    if signature<>L_SIG then
      abend(abort,next,579);
    if abort then exit;
    blockread(fp,zip,26,numread); if numread<>26 then abend(abort,next,578);
    if abort then exit;
    out^.filename:='';
    for i:=1 to zip.f_length do    {* get filename *}
      out^.filename[i]:=getbyte(fp);
    out^.filename[0]:=chr(zip.f_length);
    if (zip.e_length>0) then         {* skip comment if present *}
      for i:=1 to zip.e_length do
        c:=getbyte(fp);
    out^.date:=zip.mod_date;
    out^.time:=zip.mod_time;
    out^.csize:=zip.c_size;
    out^.usize:=zip.u_size;
    case zip.method of
      0:out^.typ:=2;    {* Stored *}
      1:out^.typ:=9;    {* Shrunk *}
      2,3,4,5:
        out^.typ:=zip.method+8;  {* Reduced *}
      6:out^.typ:=15;   {* Imploded *}
      7,8:out^.typ:=16;   {* Deflated *}
    else
      out^.typ:=1;    {* Unknown! *}
    end;
    details(abort,next); if abort then exit;
    {$I-} seek(fp,filepos(fp)+zip.c_size); {$I+}  {* seek to next entry *}
    if (ioresult<>0) then abend(abort,next,580);
    if (abort) then exit;
  end;
end;

{*------------------------------------------------------------------------*}

procedure arj_proc(var fp:file; var abort,next:boolean);
Var arj:arjfilerec;
    ARJId:word;
    Hsize:word;
    numread:word;
    c:char;
    i:integer;
    firstone:boolean;
    nextone:longint;

begin
  {* arj_proc - Process entry in ARJ archive.
  *}

  firstone:=TRUE; nextone:=0;
  while (not aborted) do begin
    blockread(fp,ARJId,2,numread); if numread<>2 then abend(abort,next,578);
    if (abort) then exit;
    blockread(fp,Hsize,2,numread); if numread<>2 then abend(abort,next,578);
    if (abort) then exit;
    nextone:=filepos(fp);
    if (hsize<=0) or (aborted) then exit;
    blockread(fp,arj,30,numread); if (numread<>30) then abend(abort,next,578);
    if abort then exit;

    out^.filename:='';
    i:=0;
    repeat
      inc(i);
      c:=getbyte(fp);
      out^.filename[i]:=c;
    until c<=#0;
    out^.filename[0]:=chr(i-1);

    if (firstone) then nextone:=nextone+hsize+6
     else nextone:=nextone+hsize+arj.c_size+6; {* Where do we seek next? *}

    out^.date:=arj.mod_date;
    out^.time:=arj.mod_time;
    out^.csize:=arj.c_size;
    out^.usize:=arj.u_size;
    if arj.method=0 then
      out^.typ:=2
    else
      out^.typ:=arj.method+16;

    if (not firstone) then details(abort,next);
    firstone:=FALSE;
    if abort then exit;
    {$I-} seek(fp,nextone); {$I+} {* seek to next entry *}
    if (ioresult<>0) then abend(abort,next,580);
    if (abort) then exit;
  end;
end;

{*------------------------------------------------------------------------*}

procedure arc_proc(var fp:file; var abort,next:boolean);
var arc:arcfilerec;
    numread:word;
    i,typ,stat:integer;
    c:char;
begin
  {*  arc_proc - Process entry in ARC archive.
  *}

  repeat
    c:=getbyte(fp);
    typ:=ord(getbyte(fp));   {* get storage method *}
    case typ of
      0:exit;                {* end of archive file *}
      1,2:out^.typ:=2;        {* Stored *}
      3,4:out^.typ:=typ;      {* Packed & Squeezed *}
      5,6,7:out^.typ:=typ;    {* crunched *}
      8,9,10:out^.typ:=typ-2; {* Crunched, Squashed & Crushed *}
      30:out^.typ:=0;         {* Directory *}
      31:dec(level);         {* end of dir (not displayed) *}
    else
         out^.typ:=1;         {* Unknown! *}
    end;
    if typ<>31 then begin    {* get data from header *}
      blockread(fp,arc,23,numread); if numread<>23 then abend(abort,next,578);
      if abort then exit;
      if typ=1 then          {* type 1 didn't have c_size field *}
        arc.u_size:=arc.c_size
      else begin
        blockread(fp,arc.u_size,4,numread);
        if numread<>4 then abend(abort,next,578);
        if abort then exit;
      end;
      i:=0;
      repeat
        inc(i);
        out^.filename[i]:=arc.filename[i-1];
      until (arc.filename[i]=#0) or (i=13);
      out^.filename[0]:=chr(i);
      out^.date:=arc.mod_date;
      out^.time:=arc.mod_time;
      if typ=30 then begin
        arc.c_size:=0;            {* set file size entries *}
        arc.u_size:=0;            {* to 0 for directories *}
      end;
      out^.csize:=arc.c_size;   {* set file size entries *}
      out^.usize:=arc.u_size;   {* for normal files *}
      details(abort,next); if abort then exit;
      if typ<>30 then begin
        {$I-} seek(fp,filepos(fp)+arc.c_size); {$I+} {* seek to next entry *}
        if ioresult<>0 then abend(abort,next,580);
        if abort then exit;
      end;
    end;
  until (c<>#$1a) or (aborted);
  if not aborted then abend(abort,next,579);
end;

{*------------------------------------------------------------------------*}

procedure zoo_proc(var fp:file; var abort,next:boolean);
var zoo:zoofilerec;
    zoo_longname,zoo_dirname:string[255];
    numread:word;
    i,method:integer;
    namlen,dirlen:byte;
begin
  {*  zoo_proc - Process entry in ZOO archive.
   *}

  while (not aborted) do begin {* set up infinite loop (exit is within loop) *}
    blockread(fp,zoo,56,numread); if numread<>56 then abend(abort,next,578);
    if abort then exit;
    if zoo.tag<>Z_TAG then abend(abort,next,579);   {* abort if invalid tag *}
    if (abort) or (zoo.next=0) then exit;

    namlen:=ord(getbyte(fp)); dirlen:=ord(getbyte(fp));
    zoo_longname:=''; zoo_dirname:='';
    if namlen>0 then
      for i:=1 to namlen do   {* get long filename *}
        zoo_longname:=zoo_longname+getbyte(fp);
    if dirlen>0 then begin
      for i:=1 to dirlen do   {* get directory name *}
        zoo_dirname:=zoo_dirname+getbyte(fp);
      if copy(zoo_dirname,length(zoo_dirname),1)<>'/' then
        zoo_dirname:=zoo_dirname+'/';
    end;
    if zoo_longname<>'' then out^.filename:=zoo_longname
    else begin
      i:=0;
      repeat
        inc(i);
        out^.filename[i]:=zoo.fname[i-1];
      until (zoo.fname[i]=#0) or (i=13);
      out^.filename[0]:=chr(i);
      out^.filename:=zoo_dirname+out^.filename;
    end;
    out^.date:=zoo.mod_date;  {* set up fields *}
    out^.time:=zoo.mod_time;
    out^.csize:=zoo.c_size;
    out^.usize:=zoo.u_size;
    method:=zoo.method;
    case method of
      0:out^.typ:=2;      {* Stored *}
      1:out^.typ:=6;      {* Crunched *}
    else
        out^.typ:=1;      {* Unknown! *}
    end;
    if not (zoo.deleted=1) then details(abort,next);
    if abort then exit;

    {$I-} seek(fp,zoo.next); {$I+}  {* seek to next entry *}
    if ioresult<>0 then abend(abort,next,580);
    if abort then exit;
  end;
end;

{*------------------------------------------------------------------------*}

procedure lzh_proc(var fp:file; var abort,next:boolean);
var lzh:lzhfilerec;
    numread:word;
    i:integer;
    c:char;
begin
  {*  lzh_proc - Process entry in LZH archive.
   *}

  while (not aborted) do begin {* set up infinite loop (exit is within loop) *}
    c:=getbyte(fp);
    if (c=#0) then exit else lzh.h_length:=ord(c);
    c:=getbyte(fp);
    lzh.h_cksum:=ord(c);
    blockread(fp,lzh.method,5,numread); if (numread<>5) then abend(abort,next,578);
    if (abort) then exit;
    if ((lzh.method[1]<>'-') or
        (lzh.method[2]<>'l') or
        (lzh.method[3]<>'h')) then abend(abort,next,579);
    if (abort) then exit;
    blockread(fp,lzh.c_size,15,numread); if (numread<>15) then abend(abort,next,578);
    if (abort) then exit;
    for i:=1 to lzh.f_length do out^.filename[i]:=getbyte(fp);
    out^.filename[0]:=chr(lzh.f_length);
    if (lzh.h_length-lzh.f_length=22) then begin
      blockread(fp,lzh.crc,2,numread); if (numread<>2) then abend(abort,next,578);
      if (abort) then exit;
    end;
    out^.date:=lzh.mod_date;  {* set up fields *}
    out^.time:=lzh.mod_time;
    out^.csize:=lzh.c_size;
    out^.usize:=lzh.u_size;
    c:=lzh.method[4];
    case c of
      '0':out^.typ:=2;       {* Stored *}
      '1'..'5':out^.typ:=14; {* Frozen *}
    else
      out^.typ:=1;           {* Unknown! *}
    end;
    details(abort,next);

    {$I-} seek(fp,filepos(fp)+lzh.c_size); {$I+}  {* seek to next entry *}
    if (ioresult<>0) then abend(abort,next,580);
    if (abort) then exit;
  end;
end;

{*------------------------------------------------------------------------*}

procedure rar_proc(var fp:file; var abort,next:boolean);
var rar:rarfilerec;
    rh:rarheaderrec;
    h:integer;
    numread:word;
    i:integer;
begin
  {*  rar_proc - Process entry in RAR archive.
   *}

  while (not aborted) do {* set up infinite loop (exit is within loop) *}
  begin
    if (eof(fp)) then exit;

    blockread(fp,rh.b[1],5,numread);
    if numread<>5 then abend(abort,next,578);
    if (abort) then exit;
    if not(rh.b[3]=$74) then exit;
    blockread(fp,h,2,numread);
    if numread<>2 then abend(abort,next,578);
    if (abort) then exit;
    blockread(fp,rar,sizeof(rar),numread);
    if numread<>sizeof(rar) then abend(abort,next,578);
    if (abort) then exit;

    out^.filename:='';
    for i:=1 to rar.fnamesize do    {* get filename *}
      out^.filename[i]:=getbyte(fp);
    out^.filename[0]:=chr(rar.fnamesize);
    out^.date:=rar.mod_date;
    out^.time:=rar.mod_time;
    out^.csize:=rar.packsize;
    out^.usize:=rar.unpacksize;

    case rar.method of
      $30:out^.typ:=2;   {* Stored *}
      $31..$35:out^.typ:=ord(rar.method)-$30+20;
      else out^.typ:=1;    {* Unknown! *}
    end;

    details(abort,next);

    {$I-} seek(fp,filepos(fp)+(h-(sizeof(rar)+7+length(out^.filename)))); {$I+}
    if (ioresult<>0) then abend(abort,next,580);
    if (abort) then exit;
    {$I-} seek(fp,filepos(fp)+(rar.packsize)); {$I+}
    if (ioresult<>0) then abend(abort,next,580);
    if (abort) then exit;
  end;
end;

{*------------------------------------------------------------------------*}

procedure lfi(fn:astr; var abort,next:boolean);
var fp:file;
    dirinfo1:searchrec;
    lzh:lzhfilerec;
    i1,i2,temp,infile,filename:astr;
    zoo_temp,zoo_tag:longint;
    h,numread:word;
    i,p,arctype,rcode:integer;
    c:char;
    rha:array[1..15] of byte;
begin
  fn:=sqoutsp(fn);
  if (pos('*',fn)<>0) or (pos('?',fn)<>0) then begin
    findfirst(fn,anyfile-directory-volumeid,dirinfo1);
    if (doserror=0) then fn:=dirinfo1.name;
  end;
  if ((exist(fn)) and (not abort)) then begin
    arctype:=1;
    while (systat^.filearcinfo[arctype].ext<>'') and
          (systat^.filearcinfo[arctype].ext<>copy(fn,length(fn)-2,3)) and
          (arctype<9) do
      inc(arctype);
    if not ((systat^.filearcinfo[arctype].ext='') or (arctype=9)) then begin
      temp:=systat^.filearcinfo[arctype].listline;
      if (temp[1]='/') and (temp[2] in ['1'..'6']) and (length(temp)=2) then begin
        aborted:=FALSE;
        if (not abort) then begin
          infile:=fn;
          assign(fp,infile);
          SetFileAccess(ReadOnly,DenyNone);
          reset(fp,1);

          c:=getbyte(fp);  {* determine type of archive *}
          case c of
            'P':begin
                  if getbyte(fp)<>'K' then abend(abort,next,581);
                  filetype:=1;
                  SetFileAccess(ReadOnly,DenyNone);
                  reset(fp,1);                      {* back to start of file *}
                end;
            #96:begin
                  if getbyte(fp)<>#234 then abend(abort,next,581);
                  filetype:=2;
                  SetFileAccess(ReadOnly,DenyNone);
                  reset(fp,1);                      {* back to start of file *}
                end;
            #$1a:begin
                  filetype:=3;
                  SetFileAccess(ReadOnly,DenyNone);
                  reset(fp,1);                      {* back to start of file *}
                end;
            'Z':begin
                  for i:=0 to 1 do
                    if getbyte(fp)<>'O' then abend(abort,next,581);
                  SetFileAccess(ReadOnly,DenyNone);
                  reset(fp,1);                      {* back to start of file *}
                  filetype:=4;
                end;
            #$52:begin
                  if (ord(getbyte(fp))<>$61) then abend(abort,next,581);
                  if (ord(getbyte(fp))<>$72) then abend(abort,next,581);
                  if (ord(getbyte(fp))<>$21) then abend(abort,next,581);
                  if (ord(getbyte(fp))<>$1a) then abend(abort,next,581);
                  c:=getbyte(fp); c:=getbyte(fp);
                  blockread(fp,rha[1],5,numread);
                  if numread<>5 then abend(abort,next,578);
                  if rha[3]<>$73 then abend(abort,next,578);
                  blockread(fp,h,2,numread);
                  if numread<>2 then abend(abort,next,578);
                  blockread(fp,rha[1],6,numread);
                  if numread<>6 then abend(abort,next,578);
                  {$I-} seek(fp,filepos(fp)+(h-13)); {$I+}
                  if (ioresult<>0) then abend(abort,next,580);
                  filetype:=6;
                end;
              else
                begin       {* assume LZH format *}
                  lzh.h_length:=ord(c);
                  c:=getbyte(fp);
                  for i:=1 to 5 do lzh.method[i]:=getbyte(fp);
                  if ((lzh.method[1]='-') and
                      (lzh.method[2]='l') and
                      (lzh.method[3]='h')) then
                    filetype:=5
                  else
                    abend(abort,next,581);
                  SetFileAccess(ReadOnly,DenyNone);
                  reset(fp,1);                      {* back to start of file *}
                end;
          end;

          p:=0;                             {* drop drive and pathname *}
          for i:=1 to length(infile) do
            if infile[i] in [':','\'] then p:=i;
          filename:=copy(infile,p+1,length(infile)-p);

          if filetype=4 then begin    {* process initial ZOO file header *}
            for i:=0 to 19 do      {* skip header text *}
              c:=getbyte(fp);
             {* get tag value *}
            blockread(fp,zoo_tag,4,numread);
            if numread<>4 then abend(abort,next,578);
            if zoo_tag<>Z_TAG then abend(abort,next,581);
             {* get data start *}
            blockread(fp,zoo_temp,4,numread); if numread<>4 then abend(abort,next,578);
            {$I-} seek(fp,zoo_temp); {$I+}
            if ioresult<>0 then abend(abort,next,580);
          end;

          accum_csize:=0; accum_usize:=0;   {* set accumulators to 0 *}
          level:=0; files:=0;               {* ditto with counters *}

          clearwaves;
          addwave('FN',stripname(fn),txt);
          spstr(582);
          clearwaves;;
          new(out);
          case filetype of
            1:zip_proc(fp,abort,next);  {* process ZIP entry *}
            2:arj_proc(fp,abort,next);  {* process ARJ entry *}
            3:arc_proc(fp,abort,next);  {* process ARC entry *}
            4:zoo_proc(fp,abort,next);  {* process ZOO entry *}
            5:lzh_proc(fp,abort,next);  {* process LZH entry *}
            6:rar_proc(fp,abort,next);  {* process RAR entry *}
          end;
          final(abort,next);      {* clean things up *}
          close(fp);              {* close file *}
          dispose(out);
        end;
      end else
      begin
        spstr(585);
        temp:=substall(systat^.arcpath+systat^.filearcinfo[arctype].listline,'@F',fn);
        shelldos(FALSE,temp+' >SHELL.'+cstr(nodenum),rcode);
        for i:=1 to 15 do prompt(^H' '^H);
        nl;
        pfl('shell.'+cstr(nodenum),abort,next,TRUE);
        assign(fp,'SHELL.'+cstr(nodenum));
        {$I-} erase(fp); {$I+}
        if (ioresult<>0) then spstr(586);
      end;
    end;
  end;
end;

procedure lfin(rn:integer; var abort,next:boolean);
var f:ulfrec;
begin
  seek(ulff,rn); read(ulff,f);
  lfi(memuboard.dlpath+f.filename,abort,next);
end;

procedure lfii;
const sepr2:string[5]='|B:|C';
var f:ulfrec;
    fn:astr;
    pl,rn:integer;
    abort,next,lastarc,lastgif,isgif:boolean;
begin
  spstr(107);
  gfn(fn); abort:=FALSE; next:=FALSE;
  nl;
  recno(fn,pl,rn);
  if (baddlpath) then exit;
  abort:=FALSE; next:=FALSE; lastarc:=fALSE; lastgif:=FALSE;
  while ((rn<>-1) and (not abort)) do begin
    seek(ulff,rn); read(ulff,f);
    isgif:=isgifext(f.filename);
    if (isgif) then begin
      lastarc:=FALSE;
      if (not lastgif) then begin
        lastgif:=TRUE;
        nl; nl;
        printacr('|CFilename.Ext '+sepr2+' Resolution '+sepr2+
                 ' Num Colors '+sepr2+' Signat.',abort,next);
        printacr('|BÄÄÄÄÄÄÄÄÄÄÄÄÄ:ÄÄÄÄÄÄÄÄÄÄÄÄ:ÄÄÄÄÄÄÄÄÄÄÄÄ:ÄÄÄÄÄÄÄÄÄ',abort,next);
      end;
      dogifspecs(sqoutsp(memuboard.dlpath+f.filename),abort,next);
    end else begin
      lastgif:=FALSE;
      if (not lastarc) then begin
        lastarc:=TRUE;
        nl;
      end;
      lfin(rn,abort,next);
    end;
    nrecno(fn,pl,rn);
    if (next) then abort:=FALSE;
    next:=FALSE;
  end;
  close(ulff);
end;



(* File 2 Functions ------------------------------------------- *)

procedure copyfile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);
var buffer:array[1..16384] of byte;
    fs,dfs:longint;
    nrec,i,pass:integer;
    src,dest:file;

  procedure dodate;
  var r:registers;
      od,ot,ha:integer;
  begin
    srcname:=srcname+#0;
    destname:=destname+#0;
    with r do begin
      ax:=$3d00; ds:=seg(srcname[1]); dx:=ofs(srcname[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5700; msdos(dos.registers(r));
      od:=dx; ot:=cx; bx:=ha; ax:=$3e00; msdos(dos.registers(r));
      ax:=$3d02; ds:=seg(destname[1]); dx:=ofs(destname[1]); msdos(dos.registers(r));
      ha:=ax; bx:=ha; ax:=$5701; cx:=ot; dx:=od; msdos(dos.registers(r));
      ax:=$3e00; bx:=ha; msdos(dos.registers(r));
    end;
  end;

begin
  ok:=TRUE; nospace:=FALSE;
  assign(src,srcname);
  SetFileAccess(ReadWrite,DenyALL);
  {$I-} reset(src,1); {$I+}
  if (ioresult<>0) then begin ok:=FALSE; exit; end;
  dfs:=freek(exdrv(destname));
  fs:=trunc(filesize(src)/1024.0)+1;
  if (fs>=dfs) then begin
    close(src);
    nospace:=TRUE; ok:=FALSE;
    exit;
  end else begin
    assign(dest,destname);
    {$I-} rewrite(dest,1); {$I+}
    if (ioresult<>0) then begin ok:=FALSE; exit; end;
    Close(dest);
    SetFileAccess(ReadWrite,DenyALL);
    Reset(Dest,1);

    if (showprog) then
    begin
      cl(ord('w'));
      prompt('0%');
    end;
    pass:=0; i:=fs div 16; if (fs mod 16<>0) then inc(i);
    repeat
      blockread(src,buffer,16384,nrec);
      blockwrite(dest,buffer,nrec); inc(pass);
      if (showprog) then prompt(^H^H^H^H+cstr(round(pass/i*100))+'%');
    until (nrec<16384);
    prompt(^H^H^H^H+'100%');
    close(dest); close(src);
    dodate;
  end;
end;

(*
function substall(src,old,new:astr):astr;
var p:integer;
begin
  p:=1;
  while p>0 do begin
    p:=pos(old,src);
    if p>0 then begin
      insert(new,src,p+length(old));
      delete(src,p,length(old));
    end;
  end;
  substall:=src;
end;
*)

procedure movline(var src:astr; s1,s2:astr);
begin
  src:=substall(src,'@F',s1);
  src:=substall(src,'@I',s2);
end;

procedure movefile(var ok,nospace:boolean; showprog:boolean;
                   srcname,destname:astr);
var f:file;
    s,opath:astr;
    c1,c2:char;
begin
  ok:=TRUE; nospace:=FALSE;

  getdir(0,opath);

  s:=fexpand(srcname); c1:=s[1];
  s:=fexpand(destname); c2:=s[1];
  if c1=c2 then begin
    assign(f,srcname);
    {$I-} rename(f,destname); {$I+}
    if ioresult=0 then begin
      if showprog then prompt('100%');
      chdir(opath);
      exit;
    end;
  end;

  copyfile(ok,nospace,showprog,srcname,destname);
  if ((ok) and (not nospace)) then begin
    assign(f,srcname);
    {$I-} erase(f); {$I+}
  end;
  chdir(opath);
end;



(* File 1 Functions ------------------------------------------- *)


procedure dodl(fpneed:integer);
begin
  nl;
  nl;
  
  (* Removing File point system
  
  if (not aacs(systat^.nofilepts)) or
     (not (fnofilepts in thisuser.ac)) then begin
    if (fpneed>0) then dec(thisuser.filepoints,fpneed);
    if (thisuser.filepoints<0) then thisuser.filepoints:=0;
    if (fpneed<>0) then begin spstr(120); end;
  end;
  *)
end;

procedure doul(pts:integer);
begin
  if (not aacs(systat^.ulvalreq)) then begin
    spstr(121);
    if (systat^.uldlratio) then
      spstr(122)
    else
      spstr(123);
  end else
    if ((not systat^.uldlratio) and (not systat^.fileptratio) and (pts=0)) then begin
      spstr(121);
    end else
      inc(thisuser.filepoints,pts);
end;

procedure showuserfileinfo;
begin
  with thisuser do
    commandline('U/L: '+cstr(uploads)+'/'+cstr(trunc(uk))+'k  ³ D/L: '+cstr(downloads)+'/'+cstr(trunc(dk))+'k');
end;

function okdl(f:ulfrec):boolean;
var s:astr;
    b:boolean;

  procedure nope(s:word);
  begin
    if (b) then spstr(s);
    b:=FALSE;
  end;

begin
  b:=TRUE;
  if (isrequest in f.filestat) then begin
    spstr(124);
    if (pynq(getstr(479))) then begin
      s:=sqoutsp(f.filename);
      sysoplog('|R!!!!!|Y File Requested: '+sqoutsp(f.filename)+'|R !!!!!');
      {-M-}
{     ssz(1,'File Request: '+s+' from base #'+cstr(ccuboards[1][fileboard])); }
      spstr(326);
    end;
    b:=FALSE;
  end;
  if ((resumelater in f.filestat) and (not fso)) then nope(125);
  if ((notval in f.filestat) and (not aacs(systat^.dlunval))) then nope(126);
  
  (* Removed file point bug
  
  if (thisuser.filepoints<f.filepoints) and (f.filepoints>0) and
     (not aacs(systat^.nofilepts)) and
     (not (fnofilepts in thisuser.ac)) and
     (not (fbnoratio in memuboard.fbstat)) then
    nope(108);
  *)  
    
  if (nsl<rte*f.blocks) then
    nope(127);
  if (not exist(memuboard.dlpath+f.filename)) then begin
    nope(128);
    sysoplog('File missing: '+sqoutsp(memuboard.dlpath+f.filename));
  end;
  okdl:=b;
end;

procedure dlx(f1:ulfrec; rn:integer; var abort:boolean);
var u:userrec;
    tooktime,xferstart,xferend:datetimerec;
    i,ii,tt,bar,s:astr;
    rl,tooktime1:real;
    cps,lng:longint;
    inte,pl,z:integer;
    c:char;
    next,ps,ok,tl:boolean;
    oldwhereuser:string[20];
begin
  abort:=FALSE; next:=FALSE;
  nl;
  fileinfo(f1,false,abort,next);

  ps:=TRUE;
  abort:=FALSE;
  if (not okdl(f1)) then ps:=TRUE
  else begin
    ps:=FALSE;
    showuserfileinfo;

    oldwhereuser:=thisnode.whereuser;
    thisnode.whereuser:=getstr(388);
    savenode;

    getdatetime(xferstart);
    send1(memuboard.dlpath+f1.filename,ok,abort);
    getdatetime(xferend);
    timediff(tooktime,xferstart,xferend);

    thisnode.whereuser:=oldwhereuser;
    savenode;

    if (not (-lastprot in [10,11,12])) then
      if (not abort) then
        if (not ok) then begin
          spstr(129);
          sysoplog('|CUnsuccessful Download: "'+sqoutsp(f1.filename)+
                   '" from '+memuboard.name);
          ps:=TRUE;
        end else begin
          if (not (fbnoratio in memuboard.fbstat)) then begin
            inc(thisuser.downloads);
            thisuser.dk:=thisuser.dk+(f1.blocks div 8);
          end;

          readsystat;
          inc(systat^.todayzlog.downloads);
          inc(systat^.todayzlog.dk,(f1.blocks div 8));
          savesystat;

          lng:=f1.blocks; lng:=lng*128;

          clearwaves;
          addwave('TI',longtim(tooktime),txt);
          spstr(327);
          clearwaves;
          addwave('BY',cstrl(lng),txt);
          addwave('NR',aonoff(fbnoratio in memuboard.fbstat,getstr(329),''),txt);
          spstr(328);
          clearwaves;

          s:='|CDownload "'+sqoutsp(f1.filename)+'" from '+memuboard.name;

          tooktime1:=dt2r(tooktime);
          if (tooktime1>=1.0) then begin
            cps:=f1.blocks; cps:=cps*128;
            cps:=trunc(cps/tooktime1);
          end else
            cps:=0;

          s:=s+'|C ('+cstr(f1.blocks div 8)+'k, '+ctim(dt2r(tooktime))+
               ', '+cstr(cps)+' cps)';
          sysoplog(s);
          
          (*
          if ((not (fbnoratio in memuboard.fbstat)) and
             (f1.filepoints>0)) then dodl(f1.filepoints);
          *)   
             
          showuserfileinfo;

          if (rn<>-1) then begin
            inc(f1.nacc);
            seek(ulff,rn); write(ulff,f1);
          end;
        end;
  end;
  if (ps) then begin
    spstr(110);
    onek(c,'Q '^M);
    abort:=(c='Q');
  end;
end;

procedure dl(fn:astr);
var pl,rn:integer;
    f:ulfrec;
    abort:boolean;
begin
  abort:=FALSE;
  recno(fn,pl,rn);
  if (baddlpath) then exit;
  if (rn=-1) then spstr(330)
  else
    while (rn<>-1) and (not abort) and (not hangup) do begin
      SetFileAccess(ReadWrite,DenyNone);
      reset(ulff);
      seek(ulff,rn); read(ulff,f);
      nl;
      dlx(f,rn,abort);
      nrecno(fn,pl,rn);
    end;
  SetFileAccess(ReadOnly,DenyNone); reset(uf); close(uf);
  close(ulff);
end;

procedure idl;
var s,xxz:astr; xxy:byte; I:integer;

  function ok_to_dl(s:astr):boolean;
  var ss:astr;
  begin
    ok_to_dl:=TRUE;
    I:=pos('.',s);
    if i=0 then ss:=copy(s,1,8) else ss:=copy(s,1,i-1);
    if (ss='CON') or (ss='AUX') or (ss='COM1') or (ss='COM2') or (ss='COM3') or
      (ss='COM4') or (ss='LPT1') or (ss='LPT2') or (ss='COM') or (ss='LPT') or
      (ss='PRN') or (ss='NUL') or (ss='LPT3') then begin
        ok_to_dl:=FALSE;
        sysoplog('|RTried to transfer a device!!');
        spstr(331);
      end;
  end;

begin
  spstr(105);
  mpl(12);
  input(s,12);
  if not(ok_to_dl(s)) then hangup:=TRUE;
  if (s<>'') then dl(s);
end;

procedure dodescrs(var f:ulfrec;              {* file record      *}
                   var v:verbrec;             {* verbose description record *}
                   var pl:integer;            {* # files in dir   *}
                   var tosysop:boolean);      {* whether to-SysOp *}
var i,maxlen:integer;
    isgif:boolean;
begin
  if ((tosysop) and (systat^.tosysopdir<>255) and
      (systat^.tosysopdir>=0) and (systat^.tosysopdir<=maxulb)) then begin
    spstr(130);
  end else
    tosysop:=FALSE;

  loaduboard(fileboard);
  isgif:=isgifext(f.filename);
  maxlen:=54;
  if ((fbusegifspecs in memuboard.fbstat) and (isgif)) then dec(maxlen,14);

  if (maxlen>50) then maxlen:=50;
  spstr(131);
  pchar;
  mpl(maxlen); inputl(f.description,maxlen);
  if (((f.description[1]='\') or (rvalidate in thisuser.ac))
     and (tosysop)) then begin
    fileboard:=systat^.tosysopdir;
    close(ulff);
    fiscan(pl);
    tosysop:=TRUE;
  end else
    tosysop:=FALSE;
  if (f.description[1]='\') then f.description:=copy(f.description,2,80);
  v.descr[1]:='';
  i:=1;
  repeat
    mpl(50);
    inputl(v.descr[i],50);
    if (v.descr[i]='') then i:=9;
    inc(i);
  until ((i=10) or (hangup));
  if (v.descr[1]<>'') then f.vpointer:=nfvpointer else f.vpointer:=-1;
end;

procedure writefv(rn:integer; f:ulfrec; v:verbrec);
begin
  seek(ulff,rn);
  write(ulff,f);

  if (v.descr[1]<>#1#1#0#1#1) and (f.vpointer<>-1) then begin
    SetFileAccess(ReadWrite,DenyNone);
    reset(verbf);
    seek(verbf,f.vpointer);
    write(verbf,v);
    close(verbf);
  end;
end;

procedure newff(f:ulfrec; v:verbrec); {* ulff needs to be open before calling *}
var i,pl:integer;
    f1:ulfrec;
begin
  pl:=filesize(ulff)-1;
  for i:=pl downto 0 do begin
    seek(ulff,i); read(ulff,f1);
    seek(ulff,i+1); write(ulff,f1);
  end;
  writefv(0,f,v);
  inc(pl);
end;

procedure doffstuff(var f:ulfrec; fn:astr; var gotpts:integer);
var rfpts:real;
begin
  f.filename:=align(fn);
  f.owner:=usernum;
  f.stowner:=allcaps(thisuser.name);
  f.date:=date;
  f.daten:=daynum(date);
  f.nacc:=0;

  if (not systat^.fileptratio) then begin
    f.filepoints:=0;
    gotpts:=0;
  end else begin
    rfpts:=(f.blocks/8)/systat^.fileptcompbasesize;
    f.filepoints:=round(rfpts);
    gotpts:=round(rfpts*systat^.fileptcomp);
    if (gotpts<1) then gotpts:=1;
  end;

  f.filestat:=[];
  if (not fso) and (not systat^.validateallfiles) then
    include(f.filestat,notval);
  f.ft:=255; {* ft; *}
end;

procedure arcstuff(var ok,convt:boolean;    { if ok - if converted }
                   var blks:longint;        { # blocks     }
                   var convtime:real;       { convert time }
                   itest:boolean;           { whether to test integrity }
                   fpath:astr;              { filepath     }
                   var fn:astr;             { filename     }
                   var f:ulfrec;            { filerec      }
                   var v:verbrec);          { verbose      }
var fi:file of byte;
    convtook,convstart,convend:datetimerec;
    oldnam,newnam,s,sig:astr;
    sttime:real;
    x,y,c:word;
    oldarc,newarc:integer;
    t:text;
begin
  {*  oldarc: current archive format, 0 if none
   *  newarc: desired archive format, 0 if none
   *  oldnam: current filename
   *  newnam: desired archive format filename
   *}

  convtime:=0.0;
  ok:=TRUE;

  assign(fi,fpath+fn);
  SetFileAccess(ReadOnly,DenyNone);
  {$I-} reset(fi); {$I+}
  if (ioresult<>0) then blks:=0
  else begin
    blks:=trunc((filesize(fi)+127.0)/128.0);
    close(fi);
  end;

  newarc:=memuboard.arctype;
  oldnam:=sqoutsp(fpath+fn);
  oldarc:=arctype(fn);

  if (not systat^.filearcinfo[oldarc].active) then oldarc:=0;
  if (not systat^.filearcinfo[newarc].active) then newarc:=0;
  if (newarc=0) then newarc:=oldarc;

  {* if both archive formats supported ... *}
  if ((oldarc<>0) and (newarc<>0)) then begin
  {* archive extension supported *}
    newnam:=fn;
    if (pos('.',newnam)<>0) then newnam:=copy(newnam,1,pos('.',newnam)-1);
    newnam:=sqoutsp(fpath+newnam+'.'+systat^.filearcinfo[newarc].ext);
    {* if integrity tests supported ... *}
    if ((itest) and (systat^.filearcinfo[oldarc].testline<>'')) then begin
      spstr(332);
      arcintegritytest(ok,oldarc,oldnam,'Testing file integrity...');
      if (not ok) then begin
        sysoplog(oldnam+' on #'+cstr(fileboard)+': Errors in integrity test');
        spstr(333);
      end else
        spstr(334);
    end;

    {* if conversion required ... *}
    if ((ok) and (oldarc<>newarc) and (newarc<>0)) then begin
      s:=systat^.filearcinfo[newarc].ext;
      if (fso) then begin
        dyny:=TRUE;
        clearwaves;
        addwave('AF',s,txt);
        convt:=pynq(getstr(335));
        clearwaves;
      end;
      if (convt) then begin
        getdatetime(convstart);
        conva(ok,oldarc,newarc,'I_temp5.'+cstr(nodenum),oldnam,newnam);
        getdatetime(convend);
        timediff(convtook,convstart,convend);
        convtime:=dt2r(convtook);

        if (ok) then begin
          assign(fi,fpath+fn);
          rewrite(fi); close(fi); erase(fi);
          assign(fi,newnam);
          SetFileAccess(readonly,denynone);
          {$I-} reset(fi); {$I+}
          if (ioresult<>0) then ok:=FALSE
          else begin
            blks:=trunc((filesize(fi)+127.0)/128.0);
            close(fi);
            if (blks=0) then ok:=FALSE;
          end;
          fn:=align(stripname(newnam));
          spstr(336);
        end else begin
          assign(fi,newnam);
          rewrite(fi); close(fi); erase(fi);
          sysoplog('|R>>>>|Y "'+oldnam+'" on #'+
                   cstr(fileboard)+': Conversion unsuccessful');
          spstr(337);
          newarc:=oldarc;
        end;
        ok:=TRUE;
      end else
        newarc:=oldarc;
    end;

    {* if comment fields supported/desired ... *}
    if (ok) and (systat^.filearcinfo[newarc].cmtline<>'') then begin
      spstr(338);
      s:=sqoutsp(fpath+fn);
      arccomment(ok,newarc,memuboard.cmttype,s,'Adding comment...');
      ok:=TRUE;
    end;

    {* get file_id.diz *}
    if (ok) and (systat^.descimport<>0) then begin
      s:=sqoutsp(fpath+fn);
      spstr(339);
      arcdecomp(ok,newarc,s,'FILE_ID.DIZ DESC.SDI','Looking for internal file description...');
      if (ok) then begin
        if exist(modemr^.temppath+'ARCHIVE\FILE_ID.DIZ') then begin
          spstr(637);
          assign(t,modemr^.temppath+'ARCHIVE\FILE_ID.DIZ');
        end else
        if exist(modemr^.temppath+'ARCHIVE\DESC.SDI') then begin
          spstr(638);
          assign(t,modemr^.temppath+'ARCHIVE\DESC.SDI');
        end else ok:=FALSE;

        if ok and (((systat^.descimport=1) and (pynq(getstr(385)))) or (systat^.descimport=2)) then begin
          reset(t);
          nl;
          x:=1;
          while (not(eof(t))) and (x<=10) do begin
            readln(t,s);
            sprint(s);
            if s='' then s:=' ';
            if x=1 then
              if (length(s)>60) then f.description:=copy(s,1,60)
                else f.description:=s
            else
              if length(s)>50 then v.descr[x-1]:=copy(s,1,50)
                else v.descr[x-1]:=s;
            inc(x);
          end;
          if x<=10 then v.descr[x-1]:='';
          close(t);
          if (f.vpointer=-1) and (v.descr[1]<>'') then f.vpointer:=nfvpointer;
        end;
        ok:=TRUE;
        purgedir(modemr^.temppath+'ARCHIVE\');
      end else ok:=TRUE;
    end;
  end;
  fn:=sqoutsp(fn);

  if ((isgifext(fn)) and (fbusegifspecs in memuboard.fbstat)) then begin
    getgifspecs(memuboard.dlpath+fn,sig,x,y,c);
    s:='('+cstrl(x)+'x'+cstrl(y)+','+cstr(c)+'c) ';
    f.description:=s+f.description;
    if (length(f.description)>60) then f.description:=copy(f.description,1,60);
  end;
end;

function searchfordups(completefn:astr):boolean;
var wildfn,nearfn,s:astr;
    i:integer;
    fcompleteacc,fcompletenoacc,fnearacc,fnearnoacc,
    hadacc,b1,b2:boolean;

  procedure searchb(b:integer; fn:astr; var hadacc,fcl,fnr:boolean);
  var f:ulfrec;
      oldboard,pl,rn:integer;
  begin
    oldboard:=fileboard;
    hadacc:=fbaseac(b); { loads in memuboard }
    fileboard:=b;

    recno(fn,pl,rn);
    if (badfpath) then exit;
    while (rn<=pl) and (rn<>-1) do begin
      seek(ulff,rn); read(ulff,f);
      if (align(f.filename)=align(completefn)) then fcl:=TRUE
      else begin
        nearfn:=align(f.filename);
        fnr:=TRUE;
      end;
      nrecno(fn,pl,rn);
    end;
    close(ulff);
    fileboard:=oldboard;
    fiscan(pl);
  end;

begin
  spstr(132);

  searchfordups:=TRUE;

  wildfn:=copy(align(completefn),1,9)+'???';
  fcompleteacc:=FALSE; fcompletenoacc:=FALSE;
  fnearacc:=FALSE; fnearnoacc:=FALSE;
  b1:=FALSE; b2:=FALSE;

  i:=0;
  while (i<=maxulb) do begin
    searchb(i,wildfn,hadacc,b1,b2); { fbaseac loads in memuboard ... }
    loaduboard(i);
    if (b1) then begin
      s:='User tried upload "'+sqoutsp(completefn)+'" to #'+cstr(fileboard)+
         '; existed in #'+cstr(i);
      if (not hadacc) then s:=s+' - no access to';
      sysoplog(s);
      spstr(134);
      clearwaves;
      addwave('FN',sqoutsp(completefn),txt);
      if (hadacc) then
      begin
        addwave('BN',memuboard.name,txt);
        addwave('B#',cstr(i),txt);
        spstr(340);
      end else
        spstr(341);
      clearwaves;
      exit;
    end;
    if (b2) then begin
      s:='User entered upload filename "'+sqoutsp(completefn)+'" in #'+
         cstr(fileboard)+'; was warned that "'+sqoutsp(nearfn)+
         '" existed in #'+cstr(i)+'.';
      if (not hadacc) then s:=s+' - no access to';
      sysoplog(s);
      addwave('FN',sqoutsp(completefn),txt);
      if (hadacc) then
      begin
        addwave('BN',memuboard.name,txt);
        addwave('B#',cstr(i),txt);
        spstr(342);
      end else
        spstr(343);
      clearwaves;
      searchfordups:=not pynq(getstr(344));
      exit;
    end;
    inc(i);
  end;

  spstr(133);
  searchfordups:=FALSE;
end;

procedure ul(var abort:boolean; fn:astr; var addbatch:boolean);
var baf:text;
    fi:file of byte;
    f,f1:ulfrec;
    wind:windowrec;
    v:verbrec;
    s:astr;
    xferstart,xferend,tooktime,ulrefundgot1,convtime1:datetimerec;
    ulrefundgot,convtime,rfpts,tooktime1:real;
    cps,lng,origblocks:longint;
    x,rn,pl,cc,oldboard,np,sx,sy,gotpts:integer;
    c:char;
    uls,ok,kabort,convt,aexists,resumefile,wenttosysop,offline:boolean;
    oldwhereuser:string[20];
begin
  oldboard:=fileboard;
  fiscan(pl);
  if (baddlpath) then exit;

  uls:=incom; ok:=TRUE; fn:=align(fn); rn:=0; ok:=TRUE;
  for x:=1 to length(fn) do
    if (pos(fn[x],'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ. !-@#$%^&()_{}''~`')=0) then ok:=FALSE;
  if (fn[1]=' ') or (fn[10]=' ') then ok:=FALSE;
  np:=0;
  for x:=1 to length(fn) do if (fn[x]='.') then inc(np);
  if (np>1) then ok:=FALSE;
  if (not ok) then begin
    spstr(134);
    exit;
  end;

  {* aexists:    if file already EXISTS in dir
     rn:         rec-num of file if already EXISTS in file listing
     resumefile: if user is going to RESUME THE UPLOAD
     uls:        whether file is to be actually UPLOADED
     offline:    if uploaded a file to be offline automatically..
  *}

  resumefile:=FALSE; uls:=TRUE; offline:=FALSE; abort:=FALSE;
  aexists:=exist(memuboard.dlpath+fn);

  recno(fn,pl,rn);
  if (baddlpath) then exit;
  nl;
  if (rn<>-1) then begin
    seek(ulff,rn); read(ulff,f);
    resumefile:=(resumelater in f.filestat);
    if (resumefile) then begin
      spstr(345);
      resumefile:=((f.owner=usernum) or (fso));
      if (resumefile) then begin
        if (not incom) then begin
          spstr(346);
          exit;
        end;
        dyny:=TRUE;
        clearwaves;
        addwave('FN',sqoutsp(fn),txt);
        resumefile:=pynq(getstr(347));
        clearwaves;
        if (not resumefile) then exit;
      end else begin
        spstr(348);
        exit;
      end;
    end;
  end;
  if ((not aexists) and (not incom)) then begin
    uls:=FALSE;
    offline:=TRUE;
    spstr(349);
    if not pynq(getstr(350)) then exit;
  end;
  if (not resumefile) then begin
    if (((aexists) or (rn<>-1)) and (not fso)) then begin
      spstr(351);
      exit;
    end;
    if (pl>=memuboard.maxfiles) then begin
      spstr(352);
      exit;
    end;
    if (not aexists) and (not offline) and
       (freek(exdrv(memuboard.dlpath))<=systat^.minspaceforupload)
    then begin
      spstr(353);
      c:=chr(exdrv(memuboard.dlpath)+64);
      if c='@' then
        sysoplog('|R>>|w Main BBS drive full!  Insufficient space to upload a file!')
      else
        sysoplog('|R>>|w '+c+': drive full!  Insufficient space to upload a file!');
      exit;
    end;
    if (aexists) then begin
      uls:=FALSE;
      clearwaves;
      addwave('FN',sqoutsp(memuboard.dlpath+fn),txt);
      spstr(354);
      clearwaves;
      if (rn<>-1) then spstr(355);
      dyny:=(rn=-1);
      if (locbatup) then begin
        spstr(356);
        onekcr:=FALSE; onekda:=FALSE;
        onek(c,'QYN'^M);
        if (rn<>-1) then ok:=(c='Y') else ok:=(c in ['Y',^M]);
        abort:=(c='Q');
        if (abort) then spstr(357) else
          if (not ok) then spstr(359) else spstr(358);
      end else
        ok:=pynq(getstr(360));
      rn:=-1;
    end;

    if ((systat^.searchdup) and (ok) and (not abort) and (incom)) then
      if (searchfordups(fn)) then exit;

    if (uls) then begin
      dyny:=TRUE;
      clearwaves;
      addwave('FN',sqoutsp(fn),txt);
      ok:=pynq(getstr(361));
      clearwaves;
    end;
    if ((ok) and (uls) and (not resumefile)) then begin
      assign(fi,memuboard.dlpath+fn);
      {$I-} rewrite(fi); {$I+}
      if ioresult<>0 then begin
        {$I-} close(fi); {$I+}
        cc:=ioresult;
        ok:=FALSE;
      end else begin
        close(fi);
        erase(fi);
        ok:=TRUE;
      end;
      if (not ok) then begin
        spstr(362);
        exit;
      end;
    end;
  end;

  if (not ok) then exit;
  wenttosysop:=TRUE;
  if (not resumefile) then begin
    f.filename:=align(fn);
    dodescrs(f,v,pl,wenttosysop);
  end;
  ok:=TRUE;
  if (uls) then begin
    showuserfileinfo;

    oldwhereuser:=thisnode.whereuser;
    thisnode.whereuser:=getstr(363);
    savenode;

    getdatetime(xferstart);
    receive1(memuboard.dlpath+fn,resumefile,ok,kabort,addbatch);

    if (addbatch) then begin
      inc(numubatchfiles);
      ubatch[numubatchfiles].fn:=sqoutsp(fn);
      with ubatch[numubatchfiles] do begin
        section:=fileboard;
        description:=f.description;
        if (v.descr[1]<>'') then begin
          inc(hiubatchv);
          new(ubatchv[hiubatchv]);    {* define dynamic memory *}
          ubatchv[hiubatchv]^:=v;
          vr:=hiubatchv;
        end else
          vr:=0;
      end;
      clearwaves;
      addwave('B#',cstr(numubatchfiles),txt);
      spstr(364);
      spstr(365);
      fileboard:=oldboard;
      thisnode.whereuser:=oldwhereuser;
      savenode;
      exit;
    end else begin
      getdatetime(xferend);
      timediff(tooktime,xferstart,xferend);
      thisnode.whereuser:=oldwhereuser;
      savenode;
    end;

    if (kabort) then begin
      fileboard:=oldboard;
      exit;
   end;

    ulrefundgot:=(dt2r(tooktime))*(systat^.ulrefund/100.0);
    freetime:=freetime+ulrefundgot;
    clearwaves;
    addwave('TR',ctim(ulrefundgot),txt);
    spstr(366);
    clearwaves;

    showuserfileinfo;

    if (not kabort) then spstr(367);
  end;
  nl;

  if (not offline) then begin
    assign(fi,memuboard.dlpath+fn);
    SetFileaccess(readonly,denynone);
    {$I-} reset(fi); {$I+}
    if (ioresult<>0) then ok:=FALSE
    else begin
      f.blocks:=trunc((filesize(fi)+127.0)/128.0);
      close(fi);
      if (f.blocks=0) then ok:=FALSE;
      origblocks:=f.blocks;
    end;
  end;

  if ((ok) and (not offline)) then begin
    convt:=TRUE;
    arcstuff(ok,convt,f.blocks,convtime,uls,memuboard.dlpath,fn,f,v);
    doffstuff(f,fn,gotpts);

    if (ok) then begin
      if ((not resumefile) or (rn=-1)) then newff(f,v) else writefv(rn,f,v);

      if (uls) then begin
        if (aacs(systat^.ulvalreq)) then begin
          inc(thisuser.uploads);
          inc(thisuser.uk,f.blocks div 8);
        end;
        readsystat;
        inc(systat^.todayzlog.uploads);
        inc(systat^.todayzlog.uk,f.blocks div 8);
        savesystat;
      end;

      s:='|CUpload "'+sqoutsp(fn)+'" on '+memuboard.name;
      if (uls) then begin
        tooktime1:=dt2r(tooktime);
        if (tooktime1>=1.0) then begin
          cps:=f.blocks; cps:=cps*128;
          cps:=trunc(cps/tooktime1);
        end else
          cps:=0;
        s:=s+'|C ('+cstr(f.blocks div 8)+'k, '+ctim(tooktime1)+
             ', '+cstr(cps)+' cps)';
      end;
      sysoplog(s);
      if ((incom) and (uls)) then begin
        if (convt) then begin
          lng:=origblocks*128;
          clearwaves;
          addwave('FS',cstrl(lng),txt);
          spstr(368);
        end;
        lng:=f.blocks; lng:=lng*128;
        clearwaves;
        addwave('FS',cstrl(lng),txt);
        if (convt) then spstr(369) else spstr(370);
        clearwaves;
        addwave('UT',longtim(tooktime),txt);
        spstr(371);
        r2dt(convtime,convtime1);
        if (convt) then
        begin
          clearwaves;
          addwave('CT',longtim(convtime1),txt);
          spstr(372);
        end;
        clearwaves;
        addwave('CS',cstr(cps),txt);
        spstr(373);
        r2dt(ulrefundgot,ulrefundgot1);
        clearwaves;
        addwave('TR',longtim(ulrefundgot1),txt);
        spstr(374);
        if (gotpts<>0) then
        begin
          clearwaves;
          addwave('FP',cstr(gotpts),txt);
          spstr(375);
        end;
        if (choptime<>0.0) then begin
          choptime:=choptime+ulrefundgot;
          freetime:=freetime-ulrefundgot;
          spstr(549);
        end;
        doul(gotpts);
      end
      else spstr(376);
      clearwaves;
    end;
  end;
  if (not ok) and (not offline) then begin
    if (exist(memuboard.dlpath+fn)) then begin
      spstr(377);
      s:='file deleted';
      if ((thisuser.sl>0 {systat^.minresumelatersl} ) and
          (f.blocks div 8>systat^.minresume)) then begin
        dyny:=TRUE;
        if pynq(getstr(378)) then begin
          doffstuff(f,fn,gotpts);
          include(f.filestat,resumelater);
          if (not aexists) or (rn=-1) then newff(f,v) else writefv(rn,f,v);
          s:='file saved for later resume';
        end;
      end;
      if (not (resumelater in f.filestat)) then begin
        if (exist(memuboard.dlpath+fn)) then begin
          assign(fi,memuboard.dlpath+fn);
          {$I-} erase(fi); {$I+}
        end;
      end;
      sysoplog('|CError uploading "'+sqoutsp(fn)+'" - '+s);
    end;
    clearwaves;
    addwave('TR',ctim(ulrefundgot),txt);
    spstr(379);
    clearwaves;
    freetime:=freetime-ulrefundgot;
  end;
  if (offline) then begin
    f.blocks:=10;
    doffstuff(f,fn,gotpts);
    include(f.filestat,isrequest);
    newff(f,v);
  end;
  close(ulff);
  fileboard:=oldboard;
  fiscan(pl); close(ulff);
end;

procedure iul;
var s,xxz:astr;
    pl:integer;
    c:char;
    xxy:byte;
    abort,done,addbatch:boolean;
    I:integer;

function ok_to_ul(s:astr):boolean;
var ss:astr;
begin
ok_to_ul:=TRUE; I:=pos('.',s); if i=0 then ss:=copy(s,1,8) else ss:=copy(s,1,i-1);
if (ss='CON') or (ss='AUX') or (ss='COM1') or (ss='COM2') or (ss='COM3') or
   (ss='COM4') or (ss='LPT1') or (ss='LPT2') or (ss='COM') or (ss='LPT') or
   (ss='PRN') or (ss='NUL') or (ss='LPT3') then begin
   ok_to_ul:=FALSE;
   sysoplog('|RTried to transfer a device!!');
   spstr(331);
   end;
   end;

begin
  fiscan(pl);
  if (baddlpath) then exit;
  if (not aacs(memuboard.ulacs)) then begin
    spstr(380);
    exit;
  end;
  locbatup:=FALSE;
  repeat
    spstr(106);
    done:=TRUE; addbatch:=FALSE;
    mpl(12); input(s,12); s:=sqoutsp(s);
    if not(ok_to_ul(s)) then hangup:=TRUE;

    if ((s<>'') and (ok_to_ul(s))) then
      if (not fso) then ul(abort,s,addbatch)
      else begin
        if (not iswildcard(s)) then ul(abort,s,addbatch)
        else begin
          locbatup:=TRUE;
          ffile(memuboard.dlpath+s);
          if (not found) then spstr(111) else
            repeat
              if not ((dirinfo.attr and VolumeID=VolumeID) or
                      (dirinfo.attr and Directory=Directory)) then
                ul(abort,dirinfo.name,addbatch);
              nfile;
            until (not found) or (abort);
        end;
      end;
    done:=(not addbatch);
  until (done) or (hangup);
end;



(*
procedure fBaseList;
var b,b2,pl,rn,oldboard,oldboard2 : integer;
begin
  b:=1;
  printf('filebase.top');
  oldboard2:=fileboard;
  while (b <= maxUlB) and (not hangup) do begin
    if (fbUnHidden in memuboard.fbstat) or (fBaseAc(b)) then begin
      b2:=ccuboards[1][b];
      oldboard:=fileboard;
      clearwaves;
        if (fileboard<>b) then changefileboard(b);
        if (fileboard=b) then begin
          fiscan(pl);
          seek(ulff,pl+1);
	  pl:=pl+1;
	  addwave('FI',cstr(pl),txt);     { # of Files }
	  close(ulff);
        end;
        addwave('F#',cstr(b2),txt);       { Area # }
	addwave('FN',memuboard.name,txt); { Area Name }
        if (b in zscanr.fzscan) then addwave('FS','Yes',txt) { Area is Newscan }
        else addwave('FS','No',txt);
        printf('filebase.mid');
        clearwaves;
      end;
      inc(b);
    end;
  fileboard:=oldboard2;
  changefileboard(fileboard);
  printf('filebase.bot');
end;
*)


{ New }
procedure fBaseList;
var b,b2,pl,rn,oldboard,oldboard2 : integer;
begin
  b:=1;
  printf('filebase.top');
  oldboard2:=fileboard;
  while (b <= maxUlB) and (not hangup) do begin
  
    clearwaves;
    
    { First Row }
    if (fbUnHidden in memuboard.fbstat) or (fBaseAc(b)) then begin
      b2:=ccuboards[1][b];
      oldboard:=fileboard;
    
      if (fileboard<>b) then changefileboard(b);
      if (fileboard=b) then begin
        fiscan(pl);
        seek(ulff,pl+1);
	pl:=pl+1;
	addwave('FI',cstr(pl),txt);     { # of Files }
	close(ulff);
      end;
      addwave('F#',cstr(b2),txt);       { Area # }
      addwave('FN',memuboard.name,txt); { Area Name }
      if (b in zscanr.fzscan) then addwave('FS','+',txt) { Area is Newscan }
      else addwave('FS',' ',txt);
    end;
    inc(b);
    
    { Second Row }    
    if (fbUnHidden in memuboard.fbstat) or (fBaseAc(b)) then begin
      b2:=ccuboards[1][b];
      oldboard:=fileboard;
      
      if (fileboard<>b) then changefileboard(b);
      if (fileboard=b) then begin
        fiscan(pl);
        seek(ulff,pl+1);
        pl:=pl+1;
    	addwave('SI',cstr(pl),txt);     { # of Files }
    	close(ulff);
      end;
      addwave('S#',cstr(b2),txt);       { Area # }
      addwave('SN',memuboard.name,txt); { Area Name }
      if (b in zscanr.fzscan) then addwave('SS','+',txt) { Area is Newscan }
      else addwave('SS',' ',txt);            
    end;
    
    printf('filebase.mid');
    clearwaves;
    inc(b);  
  end;
    
  fileboard:=oldboard2;
  changefileboard(fileboard);
  printf('filebase.bot');
end;




procedure unlisted_download(s:astr);
var dok,kabort:boolean;
    pl,oldnumbatchfiles,oldfileboard:integer;
begin
  if (s<>'') then begin
    if (not exist(s)) then spstr(382)
    else if (iswildcard(s)) then spstr(383)
      else begin
        oldnumbatchfiles:=numbatchfiles;
        oldfileboard:=fileboard; fileboard:=-1;
        send1(s,dok,kabort);
        if (numbatchfiles=oldnumbatchfiles) and (dok) and (not kabort) then
          dodl(systat^.unlistfp);
        fileboard:=oldfileboard;
      end;
  end;
end;

procedure do_unlisted_download;
var s:astr;
begin
  spstr(384);
  mpl(78); input(s,78);
  unlisted_download(s);
end;

function nfvpointer:longint;
var i,x:integer;
    v:verbrec;
    vfo:boolean;
begin
  vfo:=(filerec(verbf).mode<>fmclosed);
  if (not vfo) then begin
    SetFileaccess(readonly,denynone);
    reset(verbf);
  end;
  x:=filesize(verbf);
  for i:=0 to filesize(verbf)-1 do begin
    seek(verbf,i); read(verbf,v);
    if (v.descr[1]='') then x:=i;
  end;
  if (not vfo) then close(verbf);
  nfvpointer:=x;
end;




(* File 0 Functions ------------------------------------------- *)

function align(fn:astr):astr;
var f,e,t:astr; c,c1:integer;
begin
  c:=pos('.',fn);
  if (c=0) then begin
    f:=fn; e:='   ';
  end else begin
    f:=copy(fn,1,c-1); e:=copy(fn,c+1,3);
  end;
  f:=mln(f,8);
  e:=mln(e,3);
  c:=pos('*',f); if (c<>0) then for c1:=c to 8 do f[c1]:='?';
  c:=pos('*',e); if (c<>0) then for c1:=c to 3 do e[c1]:='?';
  c:=pos(' ',f); if (c<>0) then for c1:=c to 8 do f[c1]:=' ';
  c:=pos(' ',e); if (c<>0) then for c1:=c to 3 do e[c1]:=' ';
  align:=f+'.'+e;
end;

function baddlpath:boolean;
var s:string;
begin
  if (badfpath) then begin
    nl;
    sprint('|RFile base #'+cstr(fileboard)+': Unable to perform command.');
    sprint('|YBad DL file path:');
    if (fso) then sprint('"'+memuboard.dlpath+'".');
    sysoplog('|RInvalid DL path (file base #'+cstr(fileboard)+'): "'+
             memuboard.dlpath+'"');
  end;
  baddlpath:=badfpath;
end;

function bslash(b:boolean; s:astr):astr;
begin
  if (b) then begin
    while (copy(s,length(s)-1,2)='\\') do s:=copy(s,1,length(s)-2);
    if (copy(s,length(s),1)<>'\') then s:=s+'\';
  end else
    while (copy(s,length(s),1)='\') do s:=copy(s,1,length(s)-1);
  bslash:=s;
end;

function existdir(s:astr):boolean;
var savedir:astr;
    okd:boolean;
begin
  okd:=TRUE;
  s:=bslash(FALSE,fexpand(s));

  if ((length(s)=2) and (copy(s,2,1)=':')) then begin
    getdir(0,savedir);
    {$I-} chdir(s); {$I+}
    if (ioresult<>0) then okd:=FALSE;
    chdir(savedir);
    exit;
  end;

  okd:=(exist(s));

  if (okd) then begin
    findfirst(s,anyfile,dirinfo);
    if (dirinfo.attr and directory<>directory) or
       (doserror<>0) then okd:=FALSE;
  end;

  existdir:=okd;
end;

procedure fiscan(var pl:integer); { loads in memuboard ... }
var dirinfo:searchrec;
    s:astr;
begin
  s:=memuboard.dlpath; s:=copy(s,1,length(s)-1);
  if ((length(s)=2) and (s[2]=':')) then badfpath:=FALSE
  else begin
    findfirst(s,dos.directory,dirinfo);
    badfpath:=(doserror<>0);
  end;

  if (not ulffopen1) then
  begin
    if (filerec(ulff).mode<>fmclosed) then close(ulff);
  end else
    ulffopen1:=FALSE;
  loaduboard(fileboard);
  if (fbdirdlpath in memuboard.fbstat) then
    assign(ulff,memuboard.dlpath+memuboard.filename+'.DIR')
  else
    assign(ulff,systat^.datapath+memuboard.filename+'.DIR');
  SetFileAccess(ReadWrite,DenyNone);
  {$I-} reset(ulff); {$I+}
  if (ioresult<>0) then
  begin
    rewrite(ulff);
    Close(ulff);
    SetFileAccess(ReadWrite,DenyNone);
    reset(ulff);
  end;
  pl:=filesize(ulff)-1;
  bnp:=FALSE;
end;

procedure ffile(fn:astr);
begin
  findfirst(fn,anyfile,dirinfo);
  found:=(doserror=0);
end;

procedure fileinfo(f:ulfrec; editinfo:boolean; var abort,next:boolean);
var dt:datetimerec;
    s:str2;
    r:real;
    v:verbrec;
    i,j:byte;
    vfo:boolean;
    li:longint;
begin
  with f do begin
    clearwaves;
    addwave('FN',filename,txt);
    addwave('01',description,txt);
    li:=blocks; li:=li*128;
    addwave('FS',cstr(li),txt);
    r:=rte*blocks; r2dt(r,dt);
    addwave('TN',ctim(r),txt);
    addwave('TE',longtim(dt),txt);
    addwave('UN',aonoff(aacs(memuboard.nameacs),caps(stowner),'Unknown'),txt);
    addwave('DU',date,txt);
    addwave('TD',cstr(nacc),txt);
    addwave('FP',cstr(filepoints),txt);
  end;
  v.descr[1]:='';
  if f.vpointer<>-1 then begin
    SetFileAccess(ReadOnly,DenyNone);
    {$I-} reset(verbf); {$I+}
    if ioresult=0 then
    begin
      {$I-} seek(verbf,f.vpointer);
      read(verbf,v); {$I+}
      if ioresult=0 then
        with v do
          for i:=1 to 9 do
            if descr[i]='' then
            begin
              for j:=i to 9 do
                addwave(aonoff(j<9,'0','1')+chr(j+49),'',txt);
              i:=9;
            end else
              addwave(aonoff(i<9,'0','1')+chr(i+49),descr[i],txt);
    end else
      for i:=1 to 9 do
        addwave(aonoff(i<9,'0','1')+chr(i+49),'',txt);
  end else
    for i:=1 to 9 do
      addwave(aonoff(i<9,'0','1')+chr(i+49),'',txt);
  if (editinfo) then spstr(624) else spstr(548);
  clearwaves;
end;

function fit(f1,f2:astr):boolean;
var tf:boolean; c:integer;
begin
  tf:=TRUE;
  for c:=1 to 12 do
    if (f1[c]<>f2[c]) and (f1[c]<>'?') then tf:=FALSE;
  fit:=tf;
end;

procedure gfn(var fn:astr);
begin
  spstr(113);
  spstr(114); input(fn,12);
  if (pos('.',fn)=0) then fn:=fn+'*.*';
  fn:=align(fn);
end;

function isgifdesc(d:astr):boolean;
begin
  isgifdesc:=((copy(d,1,1)='(') and (pos('x',d) in [1..7]) and
              (pos('c)',d)<>0));
end;

function isgifext(fn:astr):boolean;
begin
  fn:=align(stripname(sqoutsp(fn)));
  fn:=allcaps(copy(fn,length(fn)-2,3));
  isgifext:=((fn='GIF') or (fn='GYF'));
end;

function isul(s:astr):boolean;
begin
  isul:=((pos('\',s)<>0) or (pos(':',s)<>0) or (pos('|',s)<>0));
end;

function iswildcard(s:astr):boolean;
begin
  iswildcard:=((pos('*',s)<>0) or (pos('?',s)<>0));
end;

procedure nfile;
begin
  findnext(dirinfo);
  found:=(doserror=0);
end;

procedure nrecno(fn:astr; var pl,rn:integer);
var c:integer;
    f:ulfrec;
begin
  rn:=-1;
  if (lrn<pl) and (lrn>=0) then begin
    c:=lrn+1;
    while (c<=pl) and (rn=-1) do begin
      seek(ulff,c); read(ulff,f);
      if pos('.',f.filename)<>9 then
      begin
        f.filename:=align(f.filename);
        seek(ulff,c); write(ulff,f);
      end;
      if fit(lfn,f.filename) then rn:=c;
      inc(c);
    end;
    lrn:=rn;
  end;
end;

procedure recno(fn:astr; var pl,rn:integer);
var f:ulfrec;
    c:integer;
begin
  fn:=align(fn);
  fiscan(pl);
  rn:=-1; c:=0;
  while (c<=pl) and (rn=-1) do
  begin
    seek(ulff,c); read(ulff,f);
    if pos('.',f.filename)<>9 then
    begin
      f.filename:=align(f.filename);
      seek(ulff,c); write(ulff,f);
    end;
    if fit(fn,f.filename) then rn:=c;
    inc(c);
  end;
  lrn:=rn;
  lfn:=fn;
end;

function rte:real;
var i:word;
begin
  i:=value(realspd); if (i=0) then i:=modemr^.waitbaud;
  rte:=1241.6/i;
end;

procedure star(s:astr);
begin
  sprint('|Bþ |C'+s);
end;

function stripname(i:astr):astr;
var i1:astr;
    n:integer;

  function nextn:integer;
  var n:integer;
  begin
    n:=pos(':',i1);
    if (n=0) then n:=pos('\',i1);
    if (n=0) then n:=pos('/',i1);
    nextn:=n;
  end;

begin
  i1:=i;
  while (nextn<>0) do i1:=copy(i1,nextn+1,80);
  stripname:=i1;
end;

function tcheck(s:real; i:integer):boolean;
var r:real;
begin
  r:=timer-s;
  if r<0.0 then r:=r+86400.0;
  if (r<0.0) or (r>32760.0) then r:=32766.0;
  if trunc(r)>i then tcheck:=FALSE else tcheck:=TRUE;
end;

function tchk(s:real; i:real):boolean;
var r:real;
begin
  r:=timer;
  if r<s then r:=r+86400.0;
  if (r-s)>i then tchk:=FALSE else tchk:=TRUE;
end;

end.