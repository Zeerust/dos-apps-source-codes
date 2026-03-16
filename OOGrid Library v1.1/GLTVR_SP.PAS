{********************************************************************

  OOGrid Library(TM) for Borland/Turbo Pascal (Real Mode/TV)
  Copyright (C) 1994, 1995 by Arturo J. Monge
  Portions Copyright (C) 1989,1990 Borland International, Inc.

  OOGrid Library(TM) Resources Unit:
    Implements the functions needed to create the resources used
    by the TSpreadSheet object.

  Copyright (C) 1995 by Arturo J. Monge

  Last Modification : March 17, 1995

*********************************************************************}

unit GLTVR_SP;

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

FUNCTION FormatDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(16,3,63,19);
New(Dlg, Init(R, 'Formato de celdas...'));
Dlg^.Options := $0343;

R.Assign(3,3,25,6);
Control := New(PRadiobuttons, Init(R,
  NewSItem('~I~zquierda',
  NewSItem('~C~entro',
  NewSItem('~D~erecha',Nil)))));
Control^.HelpCtx := hcJustLeft;
Dlg^.Insert(Control);

  R.Assign(2,2,17,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Justificaci¢n:', Control)));

R.Assign(23,7,27,8);
Control := New(PInputLine, Init(R, 1));
Control^.HelpCtx := hcDecimalPlaces;
Dlg^.Insert(Control);

  R.Assign(27,7,30,8);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiDecimalPlaces)));

  R.Assign(2,7,21,8);
  Dlg^.Insert(New(PLabel, Init(R, 'D~¡~gitos decimales:', Control)));

R.Assign(23,9,27,10);
Control := New(PInputLine, Init(R, 1));
Control^.HelpCtx := hcCurrencyChar;
Dlg^.Insert(Control);

  R.Assign(27,9,30,10);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiCurrencyCharacter)));

  R.Assign(2,9,22,10);
  Dlg^.Insert(New(PLabel, Init(R, 'Caract‚r de ~m~oneda:', Control)));

R.Assign(3,12,31,14);
Control := New(PCheckboxes, Init(R,
  NewSItem('~F~ormato de moneda',
  NewSItem('~P~oner comas en numeros',Nil))));
Control^.HelpCtx := hcCurrencyFormat;
Dlg^.Insert(Control);

  R.Assign(2,11,22,12);
  Dlg^.Insert(New(PLabel, Init(R, 'Formato de n£meros:', Control)));

R.Assign(33,3,45,5);
Control := New(PButton, Init(R, '~O~k', cmOK, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(33,9,45,11);
Control := New(PButton, Init(R, 'Cancelar', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(33,12,45,14);
Control := New(PButton, Init(R, 'Ayuda', cmHelp, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
FormatDialog := Dlg;
end;

FUNCTION PasteDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(18,7,62,16);
New(Dlg, Init(R, 'Copiar formulas...'));
Dlg^.Options := $0343;

R.Assign(3,3,39,5);
Control := New(PCheckboxes, Init(R,
  NewSItem('No cambiar ~c~olumnas',
  NewSItem('No cambiar ~l~¡neas',Nil))));
Control^.HelpCtx := hcCopyColLiteral;
Dlg^.Insert(Control);

  R.Assign(2,2,19,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Copiar f¢rmulas:', Control)));

R.Assign(2,6,14,8);
Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(16,6,28,8);
Control := New(PButton, Init(R, 'Cancelar', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(30,6,42,8);
Control := New(PButton, Init(R, 'Ayuda', cmHelp, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
PasteDialog := Dlg;
end;

FUNCTION GoToDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(18,8,62,15);
New(Dlg, Init(R, 'Ir a...'));
Dlg^.Options := $0343;

R.Assign(16,2,39,3);
Control := New(PInputLine, Init(R, 10));
Control^.HelpCtx := hcGoToCellInput;
Dlg^.Insert(Control);

  R.Assign(39,2,42,3);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiGoToCell)));

  R.Assign(2,2,15,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Nueva celda:', Control)));

R.Assign(2,4,14,6);
Control := New(PButton, Init(R, '~O~k', cmOK, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(16,4,28,6);
Control := New(PButton, Init(R, 'Cancelar', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(30,4,42,6);
Control := New(PButton, Init(R, 'Ayuda', cmHelp, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
GoToDialog := Dlg;
end;

FUNCTION ChangeHeaderDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(18,7,60,15);
New(Dlg, Init(R, 'Nuevo encabezado...'));

R.Assign(3,3,37,4);
Control := New(PInputLine, Init(R, 80));
Control^.HelpCtx := hcChangeHeaderInput;
Dlg^.Insert(Control);

  R.Assign(37,3,40,4);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiNewHeader)));

  R.Assign(2,2,31,3);
  Dlg^.Insert(New(PLabel, Init(R, '~N~uevo encabezado de columna:', Control)));

R.Assign(2,5,14,7);
Control := New(PButton, Init(R, 'O~k~', cmOk, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(15,5,27,7);
Control := New(PButton, Init(R, 'Cancelar', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(28,5,40,7);
Control := New(PButton, Init(R, 'Ayuda', cmHelp, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
ChangeHeaderDialog := Dlg;
end;


FUNCTION PrintDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(1,3,78,20);
New(Dlg, Init(R, 'Imprimir...'));
Dlg^.Options := $0343;

R.Assign(2,3,24,5);
Control := New(PRadiobuttons, Init(R,
  NewSItem('~I~mpresora',
  NewSItem('~A~rchivo',Nil))));
Control^.HelpCtx := hcPrintToPrinter;
Dlg^.Insert(Control);

  R.Assign(1,2,13,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Imprimir a:', Control)));

R.Assign(25,3,47,5);
Control := New(PRadiobuttons, Init(R,
  NewSItem('~N~ormal',
  NewSItem('~C~ondensado',Nil))));
Control^.HelpCtx := hcPrintNormal;
Dlg^.Insert(Control);

  R.Assign(24,2,45,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Tama¤o de impresi¢n:', Control)));

R.Assign(2,7,24,10);
Control := New(PRadiobuttons, Init(R,
  NewSItem('No i~m~primir',
  NewSItem('~P~ gs. izquierdas',
  NewSItem('~T~odas las p ginas',Nil)))));
Control^.HelpCtx := hcPrintRowsNo;
Dlg^.Insert(Control);

  R.Assign(1,6,18,7);
  Dlg^.Insert(New(PLabel, Init(R, 'Imprimir lineas:', Control)));

R.Assign(25,7,47,10);
Control := New(PRadiobuttons, Init(R,
  NewSItem('No imp~r~imir',
  NewSItem('P gs. ~s~uperiores',
  NewSItem('To~d~as las p ginas',Nil)))));
Control^.HelpCtx := hcPrintColsNo;
Dlg^.Insert(Control);

  R.Assign(24,6,43,7);
  Dlg^.Insert(New(PLabel, Init(R, 'Imprimir columnas:', Control)));

R.Assign(19,12,24,13);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcTopMargin;
Dlg^.Insert(Control);

  R.Assign(2,12,19,13);
  Dlg^.Insert(New(PLabel, Init(R, 'Margen s~u~perior:', Control)));

R.Assign(19,14,24,15);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcBottomMargin;
Dlg^.Insert(Control);

  R.Assign(2,14,19,15);
  Dlg^.Insert(New(PLabel, Init(R, 'Margen in~f~erior:', Control)));

R.Assign(43,12,48,13);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcLeftMargin;
Dlg^.Insert(Control);

  R.Assign(25,12,43,13);
  Dlg^.Insert(New(PLabel, Init(R, 'Margen i~z~quierdo:', Control)));

R.Assign(43,14,48,15);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcRightMargin;
Dlg^.Insert(Control);

  R.Assign(25,14,41,15);
  Dlg^.Insert(New(PLabel, Init(R, 'Margen d~e~recho:', Control)));

R.Assign(48,3,71,5);
Control := New(PCheckboxes, Init(R,
  NewSItem('Contorno de ~l~¡nea',
  NewSItem('~B~ordes en negrita',Nil))));
Control^.HelpCtx := hcLineOutline;
Dlg^.Insert(Control);

  R.Assign(47,2,54,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Otros:', Control)));

R.Assign(70,7,75,8);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcPageRows;
Dlg^.Insert(Control);

  R.Assign(49,7,66,8);
  Dlg^.Insert(New(PLabel, Init(R, '~1~. L¡neas p/pag:', Control)));

R.Assign(70,8,75,9);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcNormalCols;
Dlg^.Insert(Control);

  R.Assign(49,8,67,9);
  Dlg^.Insert(New(PLabel, Init(R, '~2~. Cols normales:', Control)));

R.Assign(70,9,75,10);
Control := New(PInputLine, Init(R, 3));
Control^.HelpCtx := hcCondensedCols;
Dlg^.Insert(Control);

  R.Assign(49,9,70,10);
  Dlg^.Insert(New(PLabel, Init(R, '~3~. Cols condensadas:', Control)));

R.Assign(49,12,62,14);
Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(62,12,75,14);
Control := New(PButton, Init(R, 'Cancelar', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(62,14,75,16);
Control := New(PButton, Init(R, 'Ayuda', cmHelp, bfNormal));
Dlg^.Insert(Control);

R.Assign(48,6,72,7);
Control := New(PStaticText, Init(R, 'Configuraci¢n de p gina:'));
Dlg^.Insert(Control);

R.Assign(2,11,11,12);
Control := New(PStaticText, Init(R, 'M rgenes:'));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
PrintDialog := Dlg;
end;


FUNCTION SortDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(15,3,64,20);
New(Dlg, Init(R, 'Ordernar...'));
Dlg^.Options := $0343;

R.Assign(3,3,23,4);
Control := New(PInputLine, Init(R, 80));
Control^.HelpCtx := hcFirstKey;
Dlg^.Insert(Control);

  R.Assign(23,3,26,4);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiSortFirstKey)));

  R.Assign(2,2,17,3);
  Dlg^.Insert(New(PLabel, Init(R, '~P~rimera llave:', Control)));

R.Assign(30,3,47,5);
Control := New(PRadiobuttons, Init(R,
  NewSItem('~A~scendente',
  NewSItem('~D~escendente',Nil))));
Control^.HelpCtx := hcAscending;
Dlg^.Insert(Control);

  R.Assign(29,2,36,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Orden:', Control)));

R.Assign(3,7,23,8);
Control := New(PInputLine, Init(R, 80));
Control^.HelpCtx := hcSecondKey;
Dlg^.Insert(Control);

  R.Assign(23,7,26,8);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiSortSecondKey)));

  R.Assign(2,6,17,7);
  Dlg^.Insert(New(PLabel, Init(R, '~S~egunda llave:', Control)));

R.Assign(30,7,47,9);
Control := New(PRadiobuttons, Init(R,
  NewSItem('As~c~endente',
  NewSItem('D~e~scendente',Nil))));
Control^.HelpCtx := hcAscending;
Dlg^.Insert(Control);

  R.Assign(29,6,36,7);
  Dlg^.Insert(New(PLabel, Init(R, 'Orden:', Control)));

R.Assign(3,11,23,12);
Control := New(PInputLine, Init(R, 80));
Control^.HelpCtx := hcThirdKey;
Dlg^.Insert(Control);

  R.Assign(23,11,26,12);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiSortThirdKey)));

  R.Assign(2,10,17,11);
  Dlg^.Insert(New(PLabel, Init(R, '~T~ercera llave:', Control)));

R.Assign(30,11,47,13);
Control := New(PRadiobuttons, Init(R,
  NewSItem('Ascenden~t~e',
  NewSItem('Desce~n~dente',Nil))));
Control^.HelpCtx := hcAscending;
Dlg^.Insert(Control);

  R.Assign(29,10,36,11);
  Dlg^.Insert(New(PLabel, Init(R, 'Orden:', Control)));

R.Assign(2,14,15,16);
Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(18,14,31,16);
Control := New(PButton, Init(R, 'Cancelar', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(34,14,47,16);
Control := New(PButton, Init(R, 'Ayuda', cmHelp, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
SortDialog := Dlg;
end;

FUNCTION GetWidthDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
R.Assign(18,8,62,15);
New(Dlg, Init(R, 'Nuevo ancho...'));
Dlg^.Options := $0343;

R.Assign(17,2,39,3);
Control := New(PInputLine, Init(R, 10));
Control^.HelpCtx := hcGetWidthInput;
Dlg^.Insert(Control);

  R.Assign(39,2,42,3);
  Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), hiNewWidth)));

  R.Assign(3,2,16,3);
  Dlg^.Insert(New(PLabel, Init(R, 'Nuevo ancho:', Control)));

R.Assign(3,4,15,6);
Control := New(PButton, Init(R, '~O~k', cmOK, bfDefault));
Control^.HelpCtx := hcOk;
Dlg^.Insert(Control);

R.Assign(16,4,28,6);
Control := New(PButton, Init(R, 'Cancelar', cmCancel, bfNormal));
Control^.HelpCtx := hcCancel;
Dlg^.Insert(Control);

R.Assign(29,4,41,6);
Control := New(PButton, Init(R, 'Ayuda', cmHelp, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
GetWidthDialog := Dlg;
end;

function PrintToDialog : PFileDialog;
var
  Dialog : PFileDialog;
begin
  Dialog := New(PFileDialog, Init('*.TXT','Imprimir a...','~I~mprimir a:',
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
New(Dlg, Init(R, 'Informaci¢n'));
Dlg^.HelpCtx := hcPleaseWait;
Dlg^.Options := $034b;
Dlg^.Eventmask := $FC00;

R.Assign(2,2,31,4);
Control := New(PStaticText, Init(R, ^C'Imprimiendo archivo... por favor espere.'^M+
  ^C'(presione ESC para cancelar)'));
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
New(Dlg, Init(R, 'Informaci¢n'));
Dlg^.HelpCtx := hcPleaseWait;
Dlg^.Options := $034b;
Dlg^.Eventmask := $FC00;

R.Assign(2,2,31,4);
Control := New(PStaticText, Init(R, ^C'Ordenando datos...'^M^C'por favor espere.'));
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
New(Dlg, Init(R, 'Informaci¢n'));
Dlg^.HelpCtx := hcPleaseWait;
Dlg^.Options := $034b;
Dlg^.Eventmask := $FC00;

R.Assign(2,2,31,4);
Control := New(PStaticText, Init(R, ^C'Actualizando tablas...'^M^C'por favor espere.'));
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
  S^.Put(sBlockDeleteMsg, 'Borrando celdas seleccionadas... por favor espere.');
  S^.Put(sBlockName, 'Block:');
  S^.Put(sCancelPrintJob, 'Cancelar impresi¢n ?');
  S^.Put(sCellError, 'ERROR');
  S^.Put(sCellLockedInfo, '[Pr]');
  S^.Put(sCellsProtectedMsg, 'Las celdas seleccionadas est n protegidas y no pueden ser modificadas.');
  S^.Put(sCellUnlockedInfo, '[D]');
  S^.Put(sColumnEntryIndicator, 'Columna');
  S^.Put(sCopyCellsMsg, 'Copiar: Indique destino y presione ENTER (o selecctione ''Pegar'' del menu)');
  S^.Put(sDisplayFormulasLetter, 'F');
  S^.Put(sDisplayHeadersLetter, 'N');
  S^.Put(sEmptyCellName, 'Vac¡a');
  S^.Put(sEndKeyPressedLetter, 'E');
  S^.Put(sFilePrintErrorMsg, 'Error imprimiendo documento.  ReIntentar?');
  S^.Put(sFormatErrorMsg, 'Errores de formato:');
  S^.Put(sFormatError1Msg, ^M'ù N£mero de decimales no v lido.');
  S^.Put(sFormatError2Msg, ^M'ù Tipo de moneda no v lido.');
  S^.Put(sFormulaCellName, 'Formula');
  S^.Put(sInvalidCellMsg, 'Celda no v lida.');
  S^.Put(sInvalidWidthMsg, 'Ancho de columna fuera del rango permitido.');
  S^.Put(sMoveCellsMsg, 'Mover: Indique destino y presione ENTER (o seleccioned ''Pegar'' del menu)');
  S^.Put(sParseError1, 'Desbordamiento de pila de an lisis.');
  S^.Put(sParseError2, 'Rango de celdas no v lido.');
  S^.Put(sParseError3, 'Falta expresi¢n.');
  S^.Put(sParseError4, 'Falta operador.');
  S^.Put(sParseError5, 'Falta par‚ntesis abierto.');
  S^.Put(sParseError6, 'Falta direcci¢n de celda.');
  S^.Put(sParseError7, 'Falta operador o par‚ntesis cerrado.');
  S^.Put(sPrinterPrintErrorMsg, 'La impresora no est  respondiendo.  Reintentar?');
  S^.Put(sPrintInitErrorMsg, 'La impresora no pudo ser inicializada.  Reintenter?');
  S^.Put(sPrintToWildCard, '*.TXT');
  S^.Put(sRecalcMsg, 'Recalculando valores de celdas... por favor espere.');
  S^.Put(sRepeatCellName, 'Repetici¢n');
  S^.Put(sTempFileName, 'tstemp.tmp');
  S^.Put(sTextCellName, 'Texto');
  S^.Put(sValueCellName, 'Valor');
  S^.Put(sWidthLetter, 'A');

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