{*****************************************************************************

  OOGrid Library(TM) for Borland/Turbo Pascal (Real Mode/TV)
  Copyright (C) 1994, 1995 by Arturo J. Monge
  Portions Copyright (C) 1989,1990 Borland International, Inc.

  OOGrid Library(TM) Make Demo Resources program:
    Creates the resource file used by DEMO_GL.PAS.  Example of
    how to use the resource functions in GLTVR_US.PAS.

  Last Modification : December 29th, 1994

*****************************************************************************}

program DemoMake;

uses Objects, Drivers, Menus, Views, Dialogs, StdDlg, GLViews, GLEquate,
     GLTVR_US, DemoEqu;

var
  ResFile : TResourceFile;

{** Resource Procedures **}

procedure CreateStrings;
var
  S: PStrListMaker;
begin
  S := New(PStrListMaker, Init(10000, 100));

{ Menu Hints }

  S^.Put(hcYes, 'Perform the action');
  S^.Put(hcNo, 'Do not perform the action');
  S^.Put(hcOk, 'Accept the settings in this dialog');
  S^.Put(hcCancel, 'Close the dialog box without making any changes.');
  S^.Put(hcDeleteWin, 'Delete from the desktop the selected window');
  S^.Put(hcWinList, 'Use the cursor keys to examine the window list');
  S^.Put(hcFileMenu, 'File management commands (New, Open, Save, etc.)');
  S^.Put(hcNewSheet, 'Create an empty spreadsheet in a new window');
  S^.Put(hcOpen, 'Locate and open a saved spreadsheet');
  S^.Put(hcSave, 'Save the current spreadsheet');
  S^.Put(hcSaveAs, 'Save the current spreadsheet under a different name');
  S^.Put(hcPrintSheet, 'Print the current spreadsheet');
  S^.Put(hcClose, 'Close the current spreadsheet');
  S^.Put(hcCloseAll, 'Close all open spreadsheets');
  S^.Put(hcDosShell, 'Temporarily exit to DOS');
  S^.Put(hcQuit, 'Close the application and return to DOS');
  S^.Put(hcEditMenu, 'Edit commands');
  S^.Put(hcGoto, 'Move the cursor to a different cell in the spreadsheet');
  S^.Put(hcEditCell, 'Edit the data in the highlighted cell');
  S^.Put(hcCopy, 'Copy the selected cells to a different position');
  S^.Put(hcMove, 'Move the selected cells to a different position');
  S^.Put(hcClear, 'Erase the data of the selected cells');
  S^.Put(hcPaste, 'Paste the selected cells where indicated by the cursor');
  S^.Put(hcSpreadSheetMenu, 'Spreadsheet managenent commands');
  S^.Put(hcFormatCells, 'Format the selected cells');
  S^.Put(hcRecalc, 'Recalculate the values of all the cells');
  S^.Put(hcToggleAutoCalc, 'Turn on/off the autocalc mode');
  S^.Put(hcToggleFormulas, 'Turn on/off display of formulas');
  S^.Put(hcToggleHeaders, 'Turn on/off display of custom assigned headers');
  S^.Put(hcProtectionMenu, 'Spreadsheet protection commands');
  S^.Put(hcToggleProtection, 'Turn on/off spreadsheet protection');
  S^.Put(hcSetUnlocked, 'Mark the selected cells as unlocked');
  S^.Put(hcSetLocked, 'Mark the selected cells as locked');
  S^.Put(hcColumnMenu, 'Column management commands');
  S^.Put(hcInsertColumns, 'Insert a column in the indicated position');
  S^.Put(hcDeleteColumns, 'Delete the selected columns');
  S^.Put(hcChangeHeaders, 'Custom assign a header to the selected columns');
  S^.Put(hcDeleteHeaders, 'Delete custom assigned headers of the selected columns');
  S^.Put(hcRowMenu, 'Row management commands');
  S^.Put(hcInsertRows, 'Insert a row in the indicated position');
  S^.Put(hcDeleteRows, 'Delete the selected rows');
  S^.Put(hcSortData, 'Sort by columns the data in the spreadsheet');
  S^.Put(hcWindowMenu, 'Window management commands');
  S^.Put(hcTile, 'Arrange windows on desktop by tiling');
  S^.Put(hcCascade, 'Arrange windows on desktop by cascading');
  S^.Put(hcVideoMode, 'Toggle between 25 and 43/50 lines');
  S^.Put(hcList, 'List all open windows on the desktop');
  S^.Put(hcZoom, 'Enlarge or restore the size of the active window');
  S^.Put(hcResize, 'Change the size or position of the active window');
  S^.Put(hcNext, 'Make the next window active');
  S^.Put(hcPrev, 'Make the previous window active');
  S^.Put(hcLoadLicense, 'File containg important information (must read!)');
  S^.Put(hcLoadTypes, 'Examples of the different cell type supported');
  S^.Put(hcLoadFunctions, 'Examples of the different functions supported');
  S^.Put(hcLoadList1, 'File explaining the use of headers and the sort method');
  S^.Put(hcLoadList2, 'Example list (file EX_List2)');
  S^.Put(hcLoadErrors, 'Examples of errors that can be detected');
  S^.Put(hcLoadDataEntry, 'Examples of data entry screens');
  S^.Put(hcLoadOOGL2, 'Information about next releases');
  S^.Put(hcExampleFilesMenu, 'Example files documenting TSpreadSheet''s features');
  S^.Put(hcRefresh, 'Redraw the screen');
  S^.Put(hcInfoMenu, 'Copyrights, how to contact the author, etc.');
  S^.Put(hcAbout, 'Copyright information');
  S^.Put(hcAuthorInfo, 'Information about how to contact the author');
  S^.Put(hcRegister, 'Registration information');
  S^.Put(hcInfoDialog, 'Thanks for using OOGrid Library(TM) v1.0!');
  S^.Put(hcChDir, 'Choose a new default directory...');


{ TSpreadSheet's Dialogs' Hints }

  S^.Put(hcBottomMargin, 'Lines to be left empty at the bottom of the page');
  S^.Put(hcChangeHeaderInput, 'Enter the new custom header for the columns(s)');
  S^.Put(hcCondensedCols, 'Number columns a page has in condensed size print mode');
  S^.Put(hcCurrencyChar, 'Enter the character of the desired currency');
  S^.Put(hcDecimalPlaces, 'Enter the desired number of decimal places of numbers');
  S^.Put(hcFirstKey, 'The selected list will be sorted with this key first');
  S^.Put(hcFormatDefault, 'Clears any custom assigned format of the selected cells');
  S^.Put(hcGetWidthInput, 'Enter the new width for the column(s)');
  S^.Put(hcGoToCellInput, 'Enter destination cell');
  S^.Put(hcInputLine, 'Enter the data ( use a space before entering text )');
  S^.Put(hcLeftMargin, 'Columns to be left empty at the left of the page');
  S^.Put(hcNormalCols, 'Number of columns a page has in normal size print mode');
  S^.Put(hcPageRows, 'Number of rows a page has');
  S^.Put(hcRightMargin, 'Columns to be left empty at the right of the page');
  S^.Put(hcSecondKey, 'Sort key used if two first keys are indentical');
  S^.Put(hcThirdKey, 'Sort key used if two second keys are identical');
  S^.Put(hcTopMargin, 'Lines to be left empty at the top of the page');
  S^.Put(hcCopyColLiteral, 'Do not modify column references to reflect new position');
  S^.Put(hcCopyRowLiteral, 'Do not modify row references to reflect new position');
  S^.Put(hcCurrencyFormat, 'Show number with the indicated currency character');
  S^.Put(hcPutCommasInNumbers, 'Put commas in the numbers');
  S^.Put(hcJustLeft, 'Place the data at the left of the column');
  S^.Put(hcJustCenter, 'Place the data at the center of the column');
  S^.Put(hcJustRight, 'Place the data at the right of the column');
  S^.Put(hcPrintToPrinter, 'Send output to printer device (PRN)');
  S^.Put(hcPrintToFile, 'Send output to a file');
  S^.Put(hcPrintNormal, 'Print the file in normal size mode');
  S^.Put(hcPrintCondensed, 'Print the file in condensed size mode');
  S^.Put(hcPrintRowsNo, 'Do not print row numbers');
  S^.Put(hcPrintRowsLeft, 'Print row numbers only in pages at the left');
  S^.Put(hcPrintRowsAlways, 'Print row numbers in all pages');
  S^.Put(hcPrintColsNo, 'Do not print column headers');
  S^.Put(hcPrintColsTop, 'Print column headers only in pages at the top');
  S^.Put(hcPrintColsAlways, 'Print column headers in all pages');
  S^.Put(hcLineOutline, 'Draw a row outline');
  S^.Put(hcBoldBorders, 'Print column headers and row numbers in bold characters');
  S^.Put(hcAscending, 'Sort the list in ascending order');
  S^.Put(hcDescending, 'Sort the list in descending order');
  S^.Put(hcPleaseWait, 'This may take some time... please wait');

{ Message Strings }

  S^.Put(sHelpAccessError, 'Could not open help file.');
  S^.Put(sNoMemError, 'There is not enough memory to continue operation.');
  S^.Put(sShellMsg, 'Type EXIT to return to application...');
  S^.Put(sNoNameFileName, 'NONAME');
  S^.Put(sMaxFilesOpenError, 'Cannot open more files!');
  S^.Put(sFileNotFound, 'File not found.');
  S^.Put(sInvalidFormat, 'The file does not have a valid format.');
  S^.Put(sAccessError, 'An error ocurred while accessing the file.');
  S^.Put(sCreateStreamError, 'Could not create file.');
  S^.Put(sSaveError, 'Error while saving file.');
  S^.Put(sLoadMessage, 'Loading file... please wait.');
  S^.Put(sSaveMessage, 'Saving file... please wait.');

  ResFile.Put(S, 'Strings');
  Dispose(S, Done);
end; {...CreateStrings }

procedure MakeMenuBar;
var
  R: TRect;
  M: PMenuBar;
begin
  R.Assign(0,0,80,1);
  M := New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~F~ile', hcFileMenu, NewMenu(
      NewItem('~N~ew', 'Alt-N', kbAltN, cmNewSheet, hcNewSheet,
      NewItem('~O~pen', 'F3', kbF3, cmOpen, hcOpen,
      NewItem('~S~ave', 'F2', kbF2, cmSave, hcSave,
      NewItem('Save ~a~s', '', kbNoKey, cmSaveAs, hcSaveAs,
      NewLine(
      NewItem('~C~hange dir...', '', kbNoKey, cmChDir, hcChDir,
      NewItem('~P~rint', 'Shift-F7', kbShiftF7, cmPrintSheet, hcPrintSheet,
      NewLine(
      NewItem('~D~os Shell...', '', kbNoKey, cmDosShell, hcDosShell,
      NewItem('E~x~it', 'Alt-X', kbAltX, cmQuit, hcQuit,
      NIL))))))))))),
    NewSubMenu('~E~dit', hcEditMenu, NewMenu(
      NewItem('~G~o to', 'Ctrl-Home', kbCtrlHome, cmGoToCell, hcGoTo,
      NewItem('~E~dit cell', 'F1', kbF1, cmEditCell, hcEditCell,
      NewLine(
      NewItem('~C~opy', 'Ctrl-Ins', kbCtrlIns, cmCopy, hcCopy,
      NewItem('~M~ove', 'Shift-Del', kbShiftDel, cmCut, hcMove,
      NewItem('C~l~ear', 'Ctrl-Del', kbCtrlDel, cmClear, hcClear,
      NewItem('~P~aste', 'Shift-Ins', kbShiftIns, cmPaste, hcPaste,
      NIL)))))))),
    NewSubMenu('~S~preadsheet', hcSpreadSheetMenu, NewMenu(
      NewItem('~C~ell format', 'Shift-F1', kbShiftF1, cmFormatCells, hcFormatCells,
      NewItem('~F~ormat default', '', kbNoKey, cmFormatDefault, hcFormatDefault,
      NewLine(
      NewItem('~R~ecalc', 'F9', kbF9, cmRecalc, hcRecalc,
      NewItem('Toggle ~a~utocalc', 'Shift-F9', kbShiftF9, cmToggleAutocalc, hcToggleAutocalc,
      NewItem('Toggle ~f~ormulas', 'Ctrl-F10', kbCtrlF10, cmToggleFormulas, hcToggleFormulas,
      NewItem('Toggle ~h~eaders', 'Shift-F10', kbShiftF10, cmToggleHeaders, hcToggleHeaders,
      NewSubMenu('~P~rotection', hcProtectionMenu, NewMenu(
        NewItem('Toggle ~p~rotection', 'Alt-P', kbAltP, cmToggleProtection, hcToggleProtection,
        NewItem('Set ~u~nlocked', 'Alt-U', kbAltU, cmSetUnlocked, hcSetUnlocked,
        NewItem('Set ~l~ocked', 'Alt-L', kbAltL, cmSetLocked, hcSetLocked,
        NIL)))),
      NewLine(
      NewSubMenu('C~o~lumn', hcColumnMenu, NewMenu(
        NewItem('~I~nsert', 'Ctrl-F4', kbCtrlF4, cmInsertColumns, hcInsertColumns,
        NewItem('~D~elete', 'Alt-F4', kbAltF4, cmDeleteColumns, hcDeleteColumns,
        NewItem('~C~hange width', 'F7', kbF7, cmChangeColWidth, hcChangeColWidth,
        NewItem('C~h~ange header', 'Ctrl-F7', kbCtrlF7, cmChangeColHeaders, hcChangeHeaders,
        NewItem('~D~elete header', '', kbNoKey, cmDeleteColHeaders, hcDeleteHeaders,
        NIL)))))),
      NewSubMenu('Ro~w~', hcRowMenu, NewMenu(
        NewItem('~I~nsert', 'Ctrl-F8', kbCtrlF8, cmInsertRows, hcInsertRows,
        Newitem('~D~elete', 'Alt-F8', kbAltF8, cmDeleteRows, hcDeleteRows,
        NIL))),
      NewLine(
      NewItem('~S~ort data', 'F4', kbF4, cmSortData, hcSortData,
      NIL)))))))))))))),
    NewSubMenu('Ex~a~mple Files', hcExampleFilesMenu, NewMenu(
      NewItem('~C~ell Types', '', kbNoKey, cmLoadTypes, hcLoadTypes,
      NewItem('~F~unctions', '', kbNoKey, cmLoadFunctions, hcLoadFunctions,
      NewItem('L~i~st', '', kbNoKey, cmLoadList1, hcLoadList1,
      NewItem('List ~e~xample', '', kbNoKey, cmLoadList2, hcLoadList2,
      NewItem('E~r~rors', '', kbNoKey, cmLoadErrors, hcLoadErrors,
      NewItem('~D~ata entry', '', kbNoKey, cmLoadDataEntry, hcLoadDataEntry,
      NIL))))))),
    NewSubMenu('~W~indow', hcWindowMenu, NewMenu(
      NewItem('~T~ile', '', kbNoKey, cmTile, hcTile,
      NewItem('C~a~scade', '', kbNoKey, cmCascade, hcCascade,
      NewItem('~C~lose', 'Alt-F3', kbAltF3, cmClose, hcClose,
      NewItem('Cl~o~se all', '', kbNoKey, cmCloseAll, hcCloseAll,
      NewItem('~R~efresh display', '', kbNoKey, cmRefresh, hcRefresh,
      NewLine(
      NewItem('~S~ize/Move', 'Ctrl-F5', kbCtrlF5, cmResize, hcResize,
      NewItem('~Z~oom', 'F5', kbF5, cmZoom, hcZoom,
      NewItem('~N~ext', 'F6', kbF6, cmNext, hcNext,
      NewItem('~P~revious', 'Shift-F6', kbShiftF6, cmPrev, hcPrev,
      NewLine(
      NewItem('~V~ideo Mode', '', kbNoKey, cmVideoMode, hcVideoMode,
      NewItem('~L~ist', 'Alt-0', kbAlt0, cmList, hcList,
      NIL)))))))))))))),
    NewSubMenu('~I~nfo', hcInfoMenu, NewMenu(
      NewItem('~A~bout...', 'Alt-F1', kbAltF1, cmAbout, hcAbout,
      NewItem('A~u~thor...', '', kbNoKey, cmAuthorInfo, hcAuthorInfo,
      NewItem('~R~egistration', '', kbNoKey, cmRegister, hcRegister,
      NIL)))),
    NIL)))))))));

  ResFile.Put(M, 'MenuBar');
  Dispose(M, Done);
end; {...MakeMenuBar }

procedure MakeLoadDialog;
var
  Dialog : PFileDialog;
begin
  Dialog := New(PFileDialog, Init('*.OGL', 'Open a file...', '~N~ame',
    fdOkButton + fdHelpButton + fdNoLoadDir, 1));

  ResFile.Put(Dialog, 'LoadDialog');
  Dispose(Dialog, Done);
end; {...MakeLoadDialog }

procedure MakeChDirDialog;
var
  Dialog : PChDirDialog;
begin
  Dialog := New(PChDirDialog, Init(cdHelpButton + cdNoLoadDir, 3));

  ResFile.Put(Dialog, 'ChDirDialog');
  Dispose(Dialog, Done);
end; {...MakeChDirDialog }

procedure MakeSaveDialog;
var
  Dialog : PFileDialog;
begin
  Dialog := New(PFileDialog, Init('*.OGL', 'Save as...', '~S~ave as',
    fdOkButton + fdHelpButton + fdNoLoadDir, 2));

  ResFile.Put(Dialog, 'SaveDialog');
  Dispose(Dialog, Done);
end; {...MakeLoadDialog }


procedure MakeAboutDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
  R.Assign(17,4,62,19);
  New(Dlg, Init(R, 'About...'));
  Dlg^.HelpCtx := hcInfoDialog;
  Dlg^.Options := $0343;

  R.Assign(2,2,43,12);
  Control := New(PStaticText, Init(R, ^C'OOGrid Library(TM) v1.1'^M+
     ^C'for Borland/Turbo Pascal (Real Mode/TV)'^M+
     ^C''^M+
     ^C'Copyright (C) 1994, 1995'^M+
     ^C'by Arturo J. Monge'^M+
     ^C''^M+
     ^C'Portions Copyright (C) 1989,1990'^M+
     ^C'by Borland International, Inc.'^M+
     ^C''));
  Dlg^.Insert(Control);

  R.Assign(16,12,28,14);
  Control := New(PButton, Init(R, 'O~k~', cmOk, bfNormal));
  Dlg^.Insert(Control);

  Dlg^.SelectNext(False);

  ResFile.Put(Dlg, 'AboutDialog');
  Dispose(Dlg, Done);
end;

procedure MakeAuthorDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(3,2,76,20);
New(Dlg, Init(R, 'How to contact the author...'));
Dlg^.HelpCtx := hcInfoDialog;
Dlg^.Options := $0343;

R.Assign(2,2,71,6);
Control := New(PStaticText, Init(R, 'Please feel free to contact the author '+
     'at any time to share your comments about this software and/or licensin'+
     'g policies, to ask any questions about the use of this library and (pl'+
     'ease!) to report any bugs you may find.'));
Dlg^.Insert(Control);

R.Assign(2,7,28,8);
Control := New(PStaticText, Init(R, 'HOW TO CONTACT THE AUTHOR:'));
Dlg^.Insert(Control);

R.Assign(2,9,42,12);
Control := New(PStaticText, Init(R, 'E-Mail:'^M+
     '  INTERNET: mongev@ns.fing.ucr.ac.cr '^M+
     '  FREENET:  fh441@cleveland.freenet.edu'));
Dlg^.Insert(Control);

R.Assign(44,9,71,13);
Control := New(PStaticText, Init(R, 'Mail:'^M+
     '  Arturo J. Monge'^M+
     '  SJO 1684; POB 025216'^M+
     '  Miami, FL 33102-5216'));
Dlg^.Insert(Control);

R.Assign(2,14,42,16);
Control := New(PStaticText, Init(R, 'Sending correspondence via electronic m'+
     'ail is strongly preferred.'));
Dlg^.Insert(Control);

R.Assign(53,15,66,17);
Control := New(PButton, Init(R, 'O~k~', cmOk, bfDefault));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);

ResFile.Put(Dlg, 'AuthorDialog');
Dispose(Dlg, Done);
end;

procedure MakeRegistrationDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(3,1,77,21);
New(Dlg, Init(R, 'Registration Information...'));
Dlg^.Options := $0343;

R.Assign(2,2,72,4);
Control := New(PStaticText, Init(R, 'OOGrid Library(TM) v1.1 is being distri'+
     'buted as freeware.  However, if you like OOGrid Library(TM) v1.1 and c'+
     'ontinue to use it, or if you'^M+
     ''));
Dlg^.Insert(Control);

R.Assign(2,4,72,7);
Control := New(PStaticText, Init(R, 'don''t like it for some reason but are '+
     'interested in using an improved version, the author would greatly appr'+
     'eciate it you registering as a user of this software.'));
Dlg^.Insert(Control);

R.Assign(2,8,70,12);
Control := New(PStaticText, Init(R, 'To register, simply send the author a l'+
     'etter or an e-mail message with the following information:'^M+
     ' a. Name, Company Name, mail address and e-mail address (if any)'^M+
     ' b. OOGrid Library(TM) and pascal compiler versions being used'^M+
     '  '));
Dlg^.Insert(Control);

R.Assign(2,12,70,15);
Control := New(PStaticText, Init(R, ' c. What you like about OOGrid Library('+
     'TM)'^M+
     ' d. What you dislike about OOGrid Library(TM)'^M+
     ' e. What would you like to see in OOGrid Library(TM) v2.0 '));
Dlg^.Insert(Control);

R.Assign(2,15,70,16);
Control := New(PStaticText, Init(R, '    (for Turbo Vision and for Windows)'));
Dlg^.Insert(Control);

R.Assign(57,17,70,19);
Control := New(PButton, Init(R, 'O~k~', cmOk, bfDefault));
Dlg^.Insert(Control);

R.Assign(2,17,30,18);
Control := New(PStaticText, Init(R, 'Thank you for your support!'));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);

ResFile.Put(Dlg, 'RegistrationDialog');
Dispose(Dlg, Done);
end; { MakeRegistrationDialog }

const
  ResourceFileName = 'DEMO_GL.TVR';

{****************************************************************************}
{                               MAIN PROGRAM                                 }
{****************************************************************************}

begin
  RegisterDialogs;
  RegisterViews;
  RegisterGLViews;
  RegisterStdDlg;
  RegisterMenus;
  RegisterType(RStrListMaker);

  write('Creating resource file...');
  ResFile.Init(New(PBufStream, Init(ResourceFileName, stCreate, 1024)));
  if ResFile.Stream^.Status <> stOk then
  begin
    writeln;
    writeln ('Error creating the resource file... program aborted.');
    halt(1);
  end; {...if ResFile.Stream^.Status <> stOk }

  CreateStrings;
  MakeMenuBar;
  MakeLoadDialog;
  MakeSaveDialog;
  MakeAboutDialog;
  MakeAuthorDialog;
  MakeChDirDialog;
  MakeRegistrationDialog;
  CreateOOGLDialogs(@ResFile);
  CreateOOGLStrings(@ResFile);

  if ResFile.Stream^.Status <> stOk then
  begin
    writeln;
    writeln ('Error adding the resources... program aborted.');
    halt(1);
  end; {...if ResFile.Stream^.Status <> stOk }

  ResFile.Done;
  writeln('done');
end. {...Program DemoMake }