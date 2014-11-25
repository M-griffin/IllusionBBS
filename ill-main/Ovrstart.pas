(*****************************************************************************)
(* Illusion BBS - Overlay initialization routines                            *)
(*****************************************************************************)

{$A+,B-,E-,F+,I+,N-,O-,R-,S-,V-}

{$IFDEF DBUG}
  {$D+,L+}
{$ELSE}
  {$D-,L-}
{$ENDIF}

unit ovrstart;

interface

uses
  crt, dos
  {$IFNDEF OS2} ,overlay {$ENDIF} ;

implementation

uses common;

Const OvrMaxSize = 16384;


{$L OVERXMS.OBJ}
procedure ovrinitxms; external;

begin
  
{$IFNDEF OS2}
  ovrinit('ILLUSION.OVR');
  if (ovrresult<>ovrok) then
  begin
    writeln;
    writeln('Critical error: Overlay manager error.');
    writeln('Check the following:');
    writeln;
    writeln('ú ILLUSION.OVR is in the current directory.');
    writeln('ú The overlay has not been damaged by an external source.');
    writeln;
    if (exiterrors<>-1) then halt(exiterrors) else halt(254);
  end;
  
  ovrinitems;
  if (ovrresult=ovrok) then whereisoverlay:=1;

  ovrsetbuf(ovrgetbuf+ovrmaxsize);
  if ovrresult<>ovrok then ovrsetbuf(ovrgetbuf+(ovrmaxsize div 2));
  
{$ENDIF}
end.
