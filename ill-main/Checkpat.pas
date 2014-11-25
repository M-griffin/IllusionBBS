(*****************************************************************************)
(* Illusion BBS - Exec swap wrapper                                          *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O-,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit checkpat;

interface

const

  INF_NODIR       =  1;

  ERR_DRIVE       = -1;  { Invalid drive }
  ERR_PATH        = -2;  { Invalid path }
  ERR_FNAME       = -3;  { Malformed filename }
  ERR_DRIVECHAR   = -4;  { Illegal drive letter }
  ERR_PATHLEN     = -5;  { Path too long }
  ERR_CRITICAL    = -6;  { Critical error (invalid drive) }

  HAS_WILD     =     1;  { Filename/ext has wildcard characters }
  HAS_EXT      =     2;  { Extension specified }
  HAS_FNAME    =     4;  { Filename specified }
  HAS_PATH     =     8;  { Path specified }
  HAS_DRIVE    =   $10;  { Drive specified }
  FILE_EXISTS  =   $20;  { File exists, upper byte has attributes }
  IS_DIR       = $1000;  { Directory, upper byte has attributes }

  IS_READ_ONLY = $0100;
  IS_HIDDEN    = $0200;
  IS_SYSTEM    = $0400;
  IS_ARCHIVED  = $2000;
  IS_DEVICE    = $4000;

function checkpath(var name;inflags:integer;var drive;var dir;
                   var fname;var ext;var fullpath):integer;
function exists(var fname):boolean;

implementation

{$L checkpap}

function checkpath(var name;inflags:integer;var drive;var dir;
                   var fname;var ext;var fullpath):integer; external;
function exists(var fname):boolean; external;

end.
