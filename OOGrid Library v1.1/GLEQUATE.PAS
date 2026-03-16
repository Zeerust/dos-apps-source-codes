{*****************************************************************************

  OOGrid Library(TM) for Borland/Turbo Pascal (Real Mode/TV)
  Copyright (C) 1994, 1995 by Arturo J. Monge
  Portions Copyright (C) 1989,1990 Borland International, Inc.

  OOGrid Library(TM) Equates Unit:
    This unit defines command and help context constants that are used
    by the TSpreadsheet object and its resources.

  Copyright (C) 1994, 1995 by Arturo J. Monge

  Last Modification : February 4th, 1995

{****************************************************************************}

{$O+,F+}

unit GLEquate;

{****************************************************************************}
                                 interface
{****************************************************************************}

const

  InitStandardContextNumber = 3;
  { Value of the first number for standard help contexts }

  InitHelpContextNumber = 100;
  { Value of the first item in the help context constants list }

  InitCommandNumber = 200;
  { Value of the first item in the command constants list }

  InitHistoryId = 100;
  { Value of the first item if the history id's list }

  InitObjectTypeId = 20000;
  { Value of the first item in the list of type id's of the objects that
    will be registered for stream access }

const

{ Standard help contexts }

  hcYes    = 7;
  hcNo     = 5;
  hcOk     = 6;
  hcCancel = 4;

{ Help Contexts }

  hcBottomMargin       = InitHelpContextNumber;
  hcChangeHeaderInput  = hcBottomMargin + 1;
  hcCondensedCols      = hcChangeHeaderInput + 1;
  hcCurrencyChar       = hcCondensedCols + 1;
  hcDecimalPlaces      = hcCurrencyChar + 1;
  hcFirstKey           = hcDecimalPlaces + 1;
  hcGetWidthInput      = hcFirstKey + 1;
  hcGoToCellInput      = hcGetWidthInput + 1;
  hcInputLine          = hcGoToCellInput + 1;
  hcLeftMargin         = hcInputLine + 1;
  hcNormalCols         = hcLeftMargin + 1;
  hcPageRows           = hcNormalCols + 1;
  hcPleaseWait         = hcPageRows + 1;
  hcRightMargin        = hcPleaseWait +1;
  hcSecondKey          = hcRightMargin + 1;
  hcThirdKey           = hcSecondKey + 1;
  hcTopMargin          = hcThirdKey + 1;

  hcCopyColLiteral     = hcTopMargin + 1;
  hcCopyRowLiteral     = hcCopyColLiteral + 1;

  hcCurrencyFormat     = hcCopyRowLiteral + 1;
  hcPutCommasInNumbers = hcCurrencyFormat + 1;

  hcJustLeft           = hcPutCommasInNumbers + 1;
  hcJustCenter         = hcJustLeft + 1;
  hcJustRight          = hcJustCenter + 1;

  hcPrintToPrinter     = hcJustRight + 1;
  hcPrintToFile        = hcPrintToPrinter + 1;

  hcPrintNormal        = hcPrintToFile + 1;
  hcPrintCondensed     = hcPrintNormal + 1;

  hcPrintRowsNo        = hcPrintCondensed + 1;
  hcPrintRowsLeft      = hcPrintRowsNo + 1;
  hcPrintRowsAlways    = hcPrintRowsLeft + 1;

  hcPrintColsNo        = hcPrintRowsAlways + 1;
  hcPrintColsTop       = hcPrintColsNo + 1;
  hcPrintColsAlways    = hcPrintColsTop + 1;

  hcLineOutline        = hcPrintColsAlways + 1;
  hcBoldBorders        = hcLineOutline + 1;

  hcAscending          = hcBoldBorders + 1;
  hcDescending         = hcAscending + 1;

const

{ Commands }

  cmChangeColHeaders     = InitCommandNumber;
  cmChangeColWidth       = cmChangeColHeaders + 1;
  cmDeleteColHeaders     = cmChangeColWidth + 1;
  cmDeleteColumns        = cmDeleteColHeaders + 1;
  cmDeleteRows           = cmDeleteColumns + 1;
  cmEditCell             = cmDeleteRows + 1;
  cmFormatCells          = cmEditCell + 1;
  cmFormatDefault        = cmFormatCells + 1;
  cmGoToCell             = cmFormatDefault + 1;
  cmInsertColumns        = cmGoToCell + 1;
  cmInsertRows           = cmInsertColumns + 1;
  cmNewSheet             = cmInsertRows + 1;
  cmPrintSheet           = cmNewSheet + 1;
  cmRecalc               = cmPrintSheet + 1;
  cmToggleAutoCalc       = cmRecalc + 1;
  cmToggleFormulas       = cmToggleAutoCalc + 1;
  cmToggleHeaders        = cmToggleFormulas + 1;
  cmToggleProtection     = cmToggleHeaders + 1;
  cmSetLocked            = cmToggleProtection + 1;
  cmSetUnlocked          = cmSetLocked + 1;
  cmSortData             = cmSetUnlocked + 1;

const

{ History id's }

  hiCurrencyCharacter = InitHistoryId;
  hiDecimalPlaces     = hiCurrencyCharacter + 1;
  hiGoToCell          = hiDecimalPlaces + 1;
  hiNewHeader         = hiGoToCell + 1;
  hiNewWidth          = hiNewHeader + 1;
  hiSortFirstKey      = hiNewWidth + 1;
  hiSortSecondKey     = hiSortFirstKey + 1;
  hiSortThirdKey      = hiSortSecondKey + 1;

const

{ Stream registration Object ID's }

  stRValueCell      = InitObjectTypeID;
  stRTextCell       = stRValueCell + 1;
  stRFormulaCell    = stRTextCell + 1;
  stRRepeatCell     = stRFormulaCell + 1;
  stRBlock          = stRRepeatCell + 1;
  stRLimScrollBar   = stRBlock + 1;
  stRSheetInputLine = stRLimScrollBar + 1;
  stRSpreadSheet    = stRSheetInputLine + 1;

{****************************************************************************}
                               implementation
{****************************************************************************}

end. {...TSEquate unit }