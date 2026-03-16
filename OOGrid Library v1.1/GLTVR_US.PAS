{********************************************************************

  OOGrid Library(TM) for Borland/Turbo Pascal (Real Mode/TV)
  Copyright (C) 1994, 1995 by Arturo J. Monge
  Portions Copyright (C) 1989,1990 Borland International, Inc.

  OOGrid Library(TM) Resources Unit:
    Implements the functions needed to create the resources used
    by the TSpreadSheet object.

  Copyright (C) 1994, 1995 by Arturo J. Monge

  Last Modification : February 3rd, 1995

*********************************************************************}

unit GLTVR_US;

{****************************************************************************}
                                 interface
{****************************************************************************}

uses Dos, Objects;

{ Register procedures that need to be called before using this unit:

    RegisterDialogs
    RegisterViews
    RegisterGLViews ( registers the inputline and the scrollbar objects )
    RegisterStdDlg
}

{ This unit uses the GLEquate unit to get command and help context
  values. If you need to modify any of those values, modify the
  GLEquate unit }

procedure CreateOOGLDialogs(ResourceFile: PResourceFile);
{ Add to the resource file each of the dialogs used by TSpreadsheet.
  Do not change the keywords used, since the TSpreadSheet object uses
  these keywords to retrieve the dialogs }

procedure CreateOOGLStrings(ResourceFile: PResourceFile);
{ Add to the resource file the string list used by TSpreadSheet. }

{****************************************************************************}
                               implementation
{****************************************************************************}

uses Dialogs, Views, StdDlg, GLSupprt, GLViews, GLEquate, GLTSheet;

function FormatDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(16,3,63,19);
New(Dlg, Init(R, 'Format cells...'));
Dlg^.Options := $0343;

R.Assign(3,3,25,6);
Control := New(PRadiobuttons, Init(R,
  NewSItem('~L~eft',
  NewSItem('~C~enter',
  NewSItem('~R~ight',Nil)))));
Control^.HelpCtx := hcJustLeft;
Dlg^.Insert(Control);

  R.Assign(2,2,17,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Justification:', Control)));

R.Assign(23,7,27,8);
Control := New(PInputLine, Init(R, 1));
Control^.HelpCtx := hcDecimalPlaces;
Dlg^.Insert(Control);

  R.Assign(27,7,30,8);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiDecimalPlaces)));

  R.Assign(2,7,18,8);
  Dlg^.Insert(New(PLabel, Init(R, 'D~e~cimal places:', Control)));

R.Assign(23,9,27,10);
Control := New(PInputLine, Init(R, 1));
Control^.HelpCtx := hcCurrencyChar;
Dlg^.Insert(Control);

  R.Assign(27,9,30,10);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiCurrencyCharacter)));

  R.Assign(2,9,22,10);
  Dlg^.Insert(New(PLabel, Init(R, 'C~u~rrency character:', Control)));

R.Assign(2,12,30,14);
Control := New(PCheckboxes, Init(R,
  NewSItem('~C~urrency format',
  NewSItem('~P~ut commas in numbers',Nil))));
Control^.HelpCtx := hcCurrencyFormat;
Dlg^.Insert(Control);

  R.Assign(2,11,18,12);
  Dlg^.Insert(New(PLabel, Init(R, 'Numbers format:', Control)));

R.Assign(33,3,45,5);
Control := New(PButton, Init(R, '~O~k', cmOK, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(33,9,45,11);
Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(33,12,45,14);
Control := New(PButton, Init(R, 'Help', cmHelp, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
FormatDialog := Dlg;
end;


function PasteDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(18,7,62,16);
New(Dlg, Init(R, 'Copy formulas...'));
Dlg^.Options := $0343;

R.Assign(3,3,39,5);
Control := New(PCheckboxes, Init(R,
  NewSItem('Copy ~c~olumns literally',
  NewSItem('Copy ~r~ows literally',Nil))));
Control^.HelpCtx := hcCopyColLiteral;
Dlg^.Insert(Control);

  R.Assign(2,2,17,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Copy formulas:', Control)));

R.Assign(2,6,14,8);
Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(16,6,28,8);
Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(30,6,42,8);
Control := New(PButton, Init(R, 'Help', cmHelp, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
PasteDialog := Dlg;
end;


function GoToDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(18,8,62,15);
New(Dlg, Init(R, 'Go to...'));
Dlg^.Options := $0343;

R.Assign(14,2,39,3);
Control := New(PInputLine, Init(R, 10));
Control^.HelpCtx := hcGoToCellInput;
Dlg^.Insert(Control);

  R.Assign(39,2,42,3);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiGoToCell)));

  R.Assign(2,2,12,3);
  Dlg^.Insert(New(PLabel, Init(R, 'New cell:', Control)));

R.Assign(2,4,14,6);
Control := New(PButton, Init(R, '~O~k', cmOK, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(16,4,28,6);
Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(30,4,42,6);
Control := New(PButton, Init(R, 'Help', cmHelp, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
GoToDialog := Dlg;
end;


function ChangeHeaderDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(18,7,60,15);
New(Dlg, Init(R, 'New header...'));

R.Assign(3,3,37,4);
Control := New(PInputLine, Init(R, 80));
Control^.HelpCtx := hcChangeHeaderInput;
Dlg^.Insert(Control);

  R.Assign(37,3,40,4);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiNewHeader)));

  R.Assign(2,2,21,3);
  Dlg^.Insert(New(PLabel, Init(R, '~N~ew column header:', Control)));

R.Assign(2,5,14,7);
Control := New(PButton, Init(R, 'O~k~', cmOk, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(15,5,27,7);
Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(28,5,40,7);
Control := New(PButton, Init(R, 'Help', cmHelp, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
ChangeHeaderDialog := Dlg;
end;


function PrintDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(2,3,78,20);
New(Dlg, Init(R, 'Print...'));
Dlg^.Options := $0343;

R.Assign(2,3,22,5);
Control := New(PRadiobuttons, Init(R,
  NewSItem('P~r~inter',
  NewSItem('F~i~le',Nil))));
Control^.HelpCtx := hcPrintToPrinter;
Dlg^.Insert(Control);

  R.Assign(1,2,11,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Print to:', Control)));

R.Assign(24,3,44,5);
Control := New(PRadiobuttons, Init(R,
  NewSItem('Nor~m~al',
  NewSItem('~C~ondensed',Nil))));
Control^.HelpCtx := hcPrintNormal;
Dlg^.Insert(Control);

  R.Assign(23,2,35,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Print size:', Control)));

R.Assign(2,7,22,10);
Control := New(PRadiobuttons, Init(R,
  NewSItem('~D~on''t print',
  NewSItem('Le~f~t pages',
  NewSItem('~A~lways',Nil)))));
Control^.HelpCtx := hcPrintRowsNo;
Dlg^.Insert(Control);

  R.Assign(1,6,13,7);
  Dlg^.Insert(New(PLabel, Init(R, 'Print rows:', Control)));

R.Assign(24,7,44,10);
Control := New(PRadiobuttons, Init(R,
  NewSItem('Do~n~''t print',
  NewSItem('To~p~ pages',
  NewSItem('Al~w~ays',Nil)))));
Control^.HelpCtx := hcPrintColsNo;
Dlg^.Insert(Control);

  R.Assign(23,6,38,7);
  Dlg^.Insert(New(PLabel, Init(R, 'Print columns:', Control)));

R.Assign(17,12,22,13);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcTopMargin;
Dlg^.Insert(Control);

  R.Assign(2,12,14,13);
  Dlg^.Insert(New(PLabel, Init(R, '~T~op margin:', Control)));

R.Assign(17,14,22,15);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcBottomMargin;
Dlg^.Insert(Control);

  R.Assign(2,14,17,15);
  Dlg^.Insert(New(PLabel, Init(R, '~B~ottom margin:', Control)));

R.Assign(38,12,43,13);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcLeftMargin;
Dlg^.Insert(Control);

  R.Assign(24,12,37,13);
  Dlg^.Insert(New(PLabel, Init(R, 'L~e~ft margin:', Control)));

R.Assign(38,14,43,15);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcRightMargin;
Dlg^.Insert(Control);

  R.Assign(24,14,38,15);
  Dlg^.Insert(New(PLabel, Init(R, 'Ri~g~ht margin:', Control)));

R.Assign(45,3,68,5);
Control := New(PCheckboxes, Init(R,
  NewSItem('Row o~u~tline',
  NewSItem('Bo~l~d borders',Nil))));
Control^.HelpCtx := hcLineOutline;
Dlg^.Insert(Control);

  R.Assign(45,2,53,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Others:', Control)));

R.Assign(68,7,73,8);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcPageRows;
Dlg^.Insert(Control);

  R.Assign(46,7,60,8);
  Dlg^.Insert(New(PLabel, Init(R, '~1~. Page rows:', Control)));

R.Assign(68,8,73,9);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcNormalCols;
Dlg^.Insert(Control);

  R.Assign(46,8,65,9);
  Dlg^.Insert(New(PLabel, Init(R, '~2~. Normal columns:', Control)));

R.Assign(68,9,73,10);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcCondensedCols;
Dlg^.Insert(Control);

  R.Assign(46,9,68,10);
  Dlg^.Insert(New(PLabel, Init(R, '~3~. Condensed columns:', Control)));

R.Assign(47,12,59,14);
Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(62,12,74,14);
Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(62,14,74,16);
Control := New(PButton, Init(R, 'Help', cmHelp, bfNormal));
Dlg^.Insert(Control);

R.Assign(2,11,10,12);
Control := New(PStaticText, Init(R, 'Margins:'));
Dlg^.Insert(Control);

R.Assign(46,6,57,7);
Control := New(PStaticText, Init(R, 'Page setup:'));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
PrintDialog := Dlg;
end;


function SortDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(15,3,64,20);
New(Dlg, Init(R, 'Sort...'));
Dlg^.Options := $0343;

R.Assign(3,3,23,4);
Control := New(PInputLine, Init(R, 80));
Control^.HelpCtx := hcFirstKey;
Dlg^.Insert(Control);

  R.Assign(23,3,26,4);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiSortFirstKey)));

  R.Assign(2,2,13,3);
  Dlg^.Insert(New(PLabel, Init(R, '~F~irst key:', Control)));

R.Assign(30,3,47,5);
Control := New(PRadiobuttons, Init(R,
  NewSItem('~A~scendent',
  NewSItem('~D~escendent',Nil))));
Control^.HelpCtx := hcAscending;
Dlg^.Insert(Control);

  R.Assign(29,2,36,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Order:', Control)));

R.Assign(3,7,23,8);
Control := New(PInputLine, Init(R, 80));
Control^.HelpCtx := hcSecondKey;
Dlg^.Insert(Control);

  R.Assign(23,7,26,8);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiSortSecondKey)));

  R.Assign(2,6,14,7);
  Dlg^.Insert(New(PLabel, Init(R, '~S~econd key:', Control)));

R.Assign(30,7,47,9);
Control := New(PRadiobuttons, Init(R,
  NewSItem('As~c~endent',
  NewSItem('D~e~scendent',Nil))));
Control^.HelpCtx := hcAscending;
Dlg^.Insert(Control);

  R.Assign(29,6,36,7);
  Dlg^.Insert(New(PLabel, Init(R, 'Order:', Control)));

R.Assign(3,11,23,12);
Control := New(PInputLine, Init(R, 80));
Control^.HelpCtx := hcThirdKey;
Dlg^.Insert(Control);

  R.Assign(23,11,26,12);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiSortThirdKey)));

  R.Assign(2,10,13,11);
  Dlg^.Insert(New(PLabel, Init(R, '~T~hird key:', Control)));

R.Assign(30,11,47,13);
Control := New(PRadiobuttons, Init(R,
  NewSItem('Ascenden~t~',
  NewSItem('Desce~n~dent',Nil))));
Control^.HelpCtx := hcAscending;
Dlg^.Insert(Control);

  R.Assign(29,10,36,11);
  Dlg^.Insert(New(PLabel, Init(R, 'Order:', Control)));

R.Assign(2,14,15,16);
Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(18,14,31,16);
Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(34,14,47,16);
Control := New(PButton, Init(R, 'Help', cmHelp, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
SortDialog := Dlg;
end;


function GetWidthDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(18,8,62,15);
New(Dlg, Init(R, 'New width...'));
Dlg^.Flags := Dlg^.Flags - wfClose;
Dlg^.Options := $0343;

R.Assign(17,2,39,3);
Control := New(PInputLine, Init(R, 10));
Control^.HelpCtx := hcGetWidthInput;
Dlg^.Insert(Control);

  R.Assign(39,2,42,3);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiNewWidth)));

  R.Assign(3,2,14,3);
  Dlg^.Insert(New(PLabel, Init(R, 'New width:', Control)));

R.Assign(3,4,15,6);
Control := New(PButton, Init(R, '~O~k', cmOK, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(16,4,28,6);
Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(29,4,41,6);
Control := New(PButton, Init(R, 'Help', cmHelp, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
GetWidthDialog := Dlg;
end;

function PrintToDialog : PFileDialog;
var
  Dialog : PFileDialog;
begin
  Dialog := New(PFileDialog, Init('*.TXT','Print to...','~P~rint to:',
    fdOkButton + fdHelpButton, 108));
  PrintToDialog := Dialog;
end; {...PrintToDialog }

function InputLine: PSheetInputLine;
{ Returns a pointer to a TSheetInputLine that will be used in a
  TInputDialog object, in TSpreadSheet's HandleInput method.  It
  is stored in the resource file to allow the use of a customizable
  help context value (stored in the hcInputLine constant) }
var
  Input : PSheetInputLine;
begin
  New(Input, Init(255));
  Input^.HelpCtx := hcInputLine;
  InputLine := Input;
end;

function PrintingDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(23,9,56,15);
New(Dlg, Init(R, 'Information'));
Dlg^.HelpCtx := hcPleaseWait;
Dlg^.Options := $034b;
Dlg^.Eventmask := $FC00;

R.Assign(2,2,31,4);
Control := New(PStaticText, Init(R, ^C'Printing file... please wait.'^M+
  ^C'(press ESC to cancel)'));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
PrintingDialog := Dlg;
end;

function SortingDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(23,9,56,15);
New(Dlg, Init(R, 'Information'));
Dlg^.HelpCtx := hcPleaseWait;
Dlg^.Options := $034b;
Dlg^.Eventmask := $FC00;

R.Assign(2,2,31,4);
Control := New(PStaticText, Init(R, ^C'Sorting data...'^M^C'please wait.'));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
SortingDialog := Dlg;
end;

function UpdatingTablesDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(23,9,56,15);
New(Dlg, Init(R, 'Information'));
Dlg^.HelpCtx := hcPleaseWait;
Dlg^.Options := $034b;
Dlg^.Eventmask := $FC00;

R.Assign(2,2,31,4);
Control := New(PStaticText, Init(R, ^C'Updating data tables...'^M^C'please wait.'));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
UpdatingTablesDialog := Dlg;
end;

{****************************************************************************}
{**                       CreateOOGLDialogs procedure                      **}
{****************************************************************************}

procedure CreateOOGLDialogs(ResourceFile: PResourceFile);
begin
  ResourceFile^.Put(FormatDialog, 'FormatDialog');
  ResourceFile^.Put(PasteDialog, 'FormulasDialog');
  ResourceFile^.Put(GoToDialog, 'GoToDialog');
  ResourceFile^.Put(ChangeHeaderDialog, 'ChangeHeaderDialog');
  ResourceFile^.Put(PrintDialog, 'PrintDialog');
  ResourceFile^.Put(SortDialog, 'SortDialog');
  ResourceFile^.Put(GetWidthDialog, 'GetWidthDialog');
  ResourceFile^.Put(InputLine, 'InputLine');
  ResourceFile^.Put(PrintToDialog, 'PrintToDialog');
  ResourceFile^.Put(PrintingDialog, 'PrintingDialog');
  ResourceFile^.Put(SortingDialog, 'SortingDialog');
  ResourceFile^.Put(UpdatingTablesDialog, 'UpdatingTablesDialog');
end; {...CreateOOGLDialogs }

{****************************************************************************}
{**                       CreateOOGLStrings procedure                      **}
{****************************************************************************}

procedure CreateOOGLStrings(ResourceFile: PResourceFile);
var
  S: PStrListMaker;
begin
  S := New(PStrListMaker, Init(10000, 100));

  S^.Put(sAutoCalcLetter, 'C');
  S^.Put(sBlockDeleteMsg, 'Deleting selected cells... please wait.');
  S^.Put(sBlockName, 'Block:');
  S^.Put(sCancelPrintJob, 'Cancel print job ?');
  S^.Put(sCellError, 'ERROR');
  S^.Put(sCellLockedInfo, '[Pr]');
  S^.Put(sCellsProtectedMsg, 'The selected cells are protected and can not be modified.');
  S^.Put(sCellUnlockedInfo, '[U]');
  S^.Put(sColumnEntryIndicator, 'Column');
  S^.Put(sCopyCellsMsg, 'Copy: Select destination cell & press ENTER (or select ''Paste'' from the menu)');
  S^.Put(sDisplayFormulasLetter, 'F');
  S^.Put(sDisplayHeadersLetter, 'N');
  S^.Put(sEmptyCellName, 'Empty');
  S^.Put(sEndKeyPressedLetter, 'E');
  S^.Put(sFilePrintErrorMsg, 'Error while printing document. Retry ?');
  S^.Put(sFormatErrorMsg, 'Format errors:');
  S^.Put(sFormatError1Msg, ^M'ù Number of decimals out of range');
  S^.Put(sFormatError2Msg, ^M'ù Invalid currency');
  S^.Put(sFormulaCellName, 'Formula');
  S^.Put(sInvalidCellMsg, 'Invalid cell.');
  S^.Put(sInvalidWidthMsg, 'Width is not within the allowed range.');
  S^.Put(sMoveCellsMsg, 'Move: Select destination cell & press ENTER (or select ''Paste'' from the menu)');
  S^.Put(sParseError1, 'Parser stack overflow.');
  S^.Put(sParseError2, 'Bad cell range.');
  S^.Put(sParseError3, 'Expected expression.');
  S^.Put(sParseError4, 'Expected operator.');
  S^.Put(sParseError5, 'Expected opening parenthesis.');
  S^.Put(sParseError6, 'Expected cell.');
  S^.Put(sParseError7, 'Expected operator or closing parenthesis.');
  S^.Put(sPrinterPrintErrorMsg, 'Printer is not answering. Retry ?');
  S^.Put(sPrintInitErrorMsg, 'Printer could not be initiated. Retry ?');
  S^.Put(sPrintToWildCard, '*.TXT');
  S^.Put(sRecalcMsg, 'Recalculating cell values... please wait.');
  S^.Put(sRepeatCellName, 'Repeat');
  S^.Put(sTempFileName, 'tstemp.tmp');
  S^.Put(sTextCellName, 'Text');
  S^.Put(sValueCellName, 'Value');
  S^.Put(sWidthLetter, 'W');

  ResourceFile^.Put(S, 'SheetStrings');
  Dispose(S, Done);
end; {...CreateOOGLStrings }

{****************************************************************************}
{**                                                                        **}
{**                       Unit's initialization Section                    **}
{**                                                                        **}
{****************************************************************************}
begin
  DisplayEnabled := False;
end. {...GLTVR_US unit }