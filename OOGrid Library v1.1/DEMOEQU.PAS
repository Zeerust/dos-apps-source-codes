{*****************************************************************************

  OOGrid Library(TM) for Borland/Turbo Pascal (Real Mode/TV)
  Copyright (C) 1994, 1995 by Arturo J. Monge
  Portions Copyright (C) 1989,1990 Borland International, Inc.

  OOGrid Library(TM) Demo Equates Unit:
    Definition of command, help context, and string indexes constants.
    Used by DEMO_GL.PAS.

  Last Modification : December 29th, 1994

*****************************************************************************}

unit DemoEqu;

{****************************************************************************}
                                 interface
{****************************************************************************}

{ Remember that commands used by the TSpreadSheet object are initially
  set to have values starting at 200 and that help contexts used by the
  TSpreadSheet object are initially set to have values starting at 100.
  To modify this values for use in you application, you must modify
  the GLEquate unit (see GLEQUATE.PAS). }

const

{ Commands }

  cmOpen          = 100;
  cmSave          = 101;
  cmSaveAs        = 102;
  cmCloseAll      = 103;
  cmRefresh       = 104;
  cmDosShell      = 105;
  cmList          = 106;
  cmVideoMode     = 107;
  cmDeleteWin     = 108; { Used by TWindowList internally }
  cmLoadTypes     = 109;
  cmLoadFunctions = 110;
  cmLoadList1     = 111;
  cmLoadList2     = 112;
  cmLoadErrors    = 113;
  cmLoadDataEntry = 114;
  cmAbout         = 115;
  cmAuthorInfo    = 116;
  cmRegister      = 117;
  cmChDir         = 118;

const

{ Help contexts }

  hcDeleteWin        = 6; { hc of the window list's Delete button }
  hcWinList          = 7; { hc of the window list's list box }
  hcWinListDlgHelp   = 8; { hc of the window list dialog }
  hcFileMenu         = 9;
  hcNewSheet         = 10;
  hcOpen             = 11;
  hcSave             = 12;
  hcSaveAs           = 13;
  hcPrintSheet       = 14;
  hcClose            = 15;
  hcCloseAll         = 16;
  hcDosShell         = 17;
  hcQuit             = 18;
  hcEditMenu         = 19;
  hcGoto             = 20;
  hcEditCell         = 21;
  hcCopy             = 22;
  hcMove             = 23;
  hcClear            = 24;
  hcPaste            = 25;
  hcSpreadSheetMenu  = 26;
  hcFormatCells      = 27;
  hcRecalc           = 28;
  hcToggleAutocalc   = 29;
  hcToggleFormulas   = 30;
  hcToggleHeaders    = 31;
  hcProtectionMenu   = 32;
  hcToggleProtection = 33;
  hcSetUnlocked      = 34;
  hcSetLocked        = 35;
  hcColumnMenu       = 36;
  hcInsertColumns    = 37;
  hcDeleteColumns    = 38;
  hcChangeColWidth   = 39;
  hcChangeHeaders    = 40;
  hcDeleteHeaders    = 41;
  hcRowMenu          = 42;
  hcInsertRows       = 43;
  hcDeleteRows       = 44;
  hcSortData         = 45;
  hcWindowMenu       = 46;
  hcTile             = 47;
  hcCascade          = 48;
  hcVideoMode        = 49;
  hcList             = 50;
  hcZoom             = 51;
  hcResize           = 52;
  hcNext             = 53;
  hcPrev             = 54;
  hcLoadLicense      = 55;
  hcLoadTypes        = 56;
  hcLoadFunctions    = 57;
  hcLoadList1        = 58;
  hcLoadList2        = 59;
  hcLoadErrors       = 60;
  hcLoadDataEntry    = 61;
  hcLoadOOGL2        = 62;
  hcExampleFilesMenu = 63;
  hcRefresh          = 64;
  hcInfoMenu         = 65;
  hcAbout            = 66;
  hcAuthorInfo       = 67;
  hcRegister         = 68;
  hcInfoDialog       = 69;
  hcChDir            = 70;
  hcFormatDefault    = 71;

const

{ String list key ID's }

  sHelpAccessError   = 72; { 'Could not open help file.' }
  sNoMemError        = 73; { 'There is not enough memory to continue operation.' }
  sShellMsg          = 74; { 'Type EXIT to return to application...' }
  sNoNameFileName    = 75; { 'NONAME' }
  sMaxFilesOpenError = 76; { 'Cannot open more files!' }
  sFileNotFound      = 77; { 'File not found.' }
  sInvalidFormat     = 78; { 'The file does not have a valid format.' }
  sAccessError       = 79; { 'An error ocurred while accessing the file.' }
  sCreateStreamError = 80; { 'Could not create file.' }
  sSaveError         = 81; { 'Error while saving file.' }
  sLoadMessage       = 82; { 'Loading file... please wait.' }
  sSaveMessage       = 83; { 'Saving file... please wait.' }

{****************************************************************************}
                               implementation
{****************************************************************************}

end. {...DemoEqu unit }