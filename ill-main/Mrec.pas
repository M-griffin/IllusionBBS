
(* Menu Struct of Impulse Menu System for File Listing Prompt *)

Unit Mrec;

Interface


Const
    menuactiv:boolean=false;      { menus are active at the moment        }
    scanfilemsg:boolean=false;    { is user at a Newscan Prompt/Menu?     }
    sepr2=#3#9+'\'+#3#0;

Type

    acstring=string[20];            { Access Condition String }
      

    mnuflags2=
     (clrscrbefore,                 { C: clear screen before menu display }
      dontcenter,                   { D: don't center the menu titles! }
      nomenuprompt,                 { N: no menu prompt whatsoever? }
      forcepause,                   { F: force a pause before menu display? }
      pulldown,                     { P: pulldown flag. }
      autotime);                    { T: is time displayed automatically? }
  
  
    menurec2=                        { *.MNU : Menu records }
    record
      menuname:array[1..3] of string[40];  { menu name }
      directive,                           { help file displayed }
      tutorial:string[12];                 { tutorial help file }
      menuprompt:string[120];              { menu prompt }
      acs:acstring;                        { access requirements }
      password:string[15];                 { password required }
      fallback:string[8];                  { fallback menu }
      forcehelplevel:byte;                 { forced help level for menu }
      gencols:byte;                        { generic menus: # of columns }
      gcol:array[1..3] of byte;            { generic menus: colors }
      menuflags:set of mnuflags2;          { menu status variables }
    end;
  
    cmdflags2=
     (hidden,                       { H: is command ALWAYS hidden? }
      pull,                         { P: is command flagged as Pulldown Active? }
      unhidden);                    { U: is command ALWAYS visible? }
  
    commandrec2=                      { *.MNU : Command records }
    record
      ldesc:string[70];               { long/Normal Text command description }
      sdesc:string[70];               { short/Highlighted command description }
      xpoint,                         { the command's X position }
      ypoint:string[3];               { the command's Y position }
      ckeys:string[14];               { command-execution keys }
      acs:acstring;                   { access requirements }
      cmdkeys:string[2];              { command keys: type of command }
      mstring:string[50];             { MString: command data }
      commandflags:set of cmdflags2;   { command status variables }
  end;


var
  menur2:menurec2;                   { menu information    }
  cmdr2:array[1..50] of commandrec2; { command information }




Implementation
End.