{********************************************************************

  OOGrid Library(TM) for Borland/Turbo Pascal (Real Mode/TV)
  Copyright (C) 1994, 1995 by Arturo J. Monge
  Portions Copyright (C) 1989,1990 Borland International, Inc.

  OOGrid Library(TM) Support Unit:
    This unit implements and defines several support objects,
    records and constants used by the TSpreadSheet object.

  Copyright (C) 1994 by Arturo J. Monge

  Last Modification : December 29th, 1994

*********************************************************************}

{$O+,F+}

unit GLSupprt;

{****************************************************************************}
                                 interface
{****************************************************************************}

uses Objects, Dialogs, Drivers, Views, GLEquate;

var
  GLResFile : PResourceFile;
  { Pointer to the resource file to be used by the unit's objects.
    Allways remember to close the resource file associated with
    this pointer }

  GLStringList : PStringList;
  { Pointer to the string list to be used by the unit's objects.
    Allways remember to dispose the associated TStringList object }

const

{ String key constants }

  sAutoCalcLetter        = 1;
  sBlockDeleteMsg        = 2;
  sBlockName             = 3;
  sCancelPrintJob        = 4;
  sCellError             = 5;
  sCellLockedInfo        = 6;
  sCellsProtectedMsg     = 7;
  sCellUnlockedInfo      = 8;
  sColumnEntryIndicator  = 9;
  sCopyCellsMsg          = 10;
  sDisplayFormulasLetter = 11;
  sDisplayHeadersLetter  = 12;
  sEmptyCellName         = 13;
  sEndKeyPressedLetter   = 14;
  sFilePrintErrorMsg     = 15;
  sFormatErrorMsg        = 16;
  sFormatError1Msg       = 17;
  sFormatError2Msg       = 18;
  sFormulaCellName       = 19;
  sInvalidCellMsg        = 20;
  sInvalidWidthMsg       = 21;
  sMoveCellsMsg          = 22;
  sParseError1           = 23;
  sParseError2           = 24;
  sParseError3           = 25;
  sParseError4           = 26;
  sParseError5           = 27;
  sParseError6           = 28;
  sParseError7           = 29;
  sPrinterPrintErrorMsg  = 30;
  sPrintInitErrorMsg     = 31;
  sPrintToWildCard       = 32;
  sRecalcMsg             = 33;
  sRepeatCellName        = 34;
  sTempFileName          = 35;
  sTextCellName          = 36;
  sValueCellName         = 37;
  sWidthLetter           = 38;

const

{ Additional stream status constants }

  stNoMemoryError = -7;
  stInvalidFormatError = -8;

const

{ Default values constants }

  DefaultCurrencyString = ' $ ';
  DefaultDefaultColWidth = 10;
  DefaultDefaultDecimalPlaces = 2;
  DefaultEmptyRowsAtBottom = 0;
  DefaultEmptyRowsAtTop = 0;
  DefaultHScrollBarLimit = 27;
  DefaultVScrollBarLimit = 104;
  DefaultMaxDecimalPlaces = 8;
  DefaultMaxCols = MaxInt;
  DefaultMaxRows = MaxInt;
  DefaultMinColWidth = 1;

type
  CellPos = record
  { Stores the position of a cell in the spreadsheet }
    Col : Word;
    Row : Word;
  end; {...CellPos }

  PBlock = ^TBlock;
  TBlock = object(TObject)
  { Stores the starting and ending position of a block of cells.
    It can extend the block of cells in any direction }
      AnchorColShifted,
      AnchorRowShifted : Boolean;
      Anchor,
      Start,
      Stop : CellPos;
    constructor Init(InitStart : CellPos);
    function CellInBlock(CheckCell : CellPos) : Boolean;
    function ExtendTo(NewLoc : CellPos) : Boolean; virtual;
    constructor Load(var S: TStream);
    procedure Store(var S: TStream);
  end; {...TBlock }

var
  PrinterConfigRec : record
  { When printing a document, TSpreadSheet's print method will make
    reference to this record. It is always initialized with the default
    values }
    PrinterCondensedOnCode : String;
    PrinterCondensedOffCode : String;
    PrinterUnderlineOnCode : String;
    PrinterUnderlineOffCode : String;
    PrinterBoldOnCode : String;
    PrinterBoldOffCode : String;
  end; {...PrinterConfigRec }

const

{ Default printer setup values constants }

  DefaultPrinterName = 'PRN';
  DefaultTopMargin = '0';
  DefaultBottomMargin = '0';
  DefaultLeftMargin = '0';
  DefaultRightMargin = '0';
  DefaultPageRows = '60';
  DefaultNormalCols = '80';
  DefaultCondensedCols = '132';
  DefaultPrinterCondensedOnCode = #15;
  DefaultPrinterCondensedOffCode = #18;
  DefaultPrinterUnderlineOnCode = Chr(27)+Chr(45)+Chr(49);
  DefaultPrinterUnderlineOffCode = Chr(27)+Chr(45)+Chr(48);
  DefaultPrinterBoldOnCode = Chr(27)+Chr(69);
  DefaultPrinterBoldOffCode = Chr(27)+Chr(70);

const
  ScreenCols = 77;
  { Max number of columns that can be used to display the spreadsheet.
    All the 80 columns of the screen cannot be used since the
    spreadsheet is displayed within a window }

  ScreenRows = 46;
  { Max numbers of rows that can be used to display the spreadsheet.
    All the 50 rows of a 43/50 lines display cannot be used since the
    spreadsheet is displayed within a window }

type
  ScreenColRange = 0..ScreenCols;
  ScreenRowRange = 0..ScreenRows;

  ScreenPos = record
  { Stores the position of a point in the screen }
    Col : ScreenColRange;
    Row : ScreenRowRange;
  end; {...ScreenPos }

  PScreenArea = ^TScreenArea;
  TScreenArea = object(TObject)
  { Stores the position of an area in the screen and the value of the
    attribute that should be used to display the the text in the area }
       UpperLeft,
       LowerRight : ScreenPos;
       Attrib     : Byte;
    constructor Init(InitX1 : ScreenColRange; InitY1 : ScreenRowRange;
      InitX2 : ScreenColRange; InitY2 : ScreenRowRange; InitAttrib : Word);
    function PointInArea(X, Y: Byte): Boolean;
  end; {...TScreenArea }


procedure RegisterGLSupprt;
{ Register the unit's objects }

const
  RBlock : TStreamRec = (
     ObjType : stRBlock;
     VmtLink : Ofs(TypeOf(TBlock)^);
     Load    : @TBlock.Load;
     Store   : @TBlock.Store
  );

{****************************************************************************}
                               implementation
{****************************************************************************}

uses App;

{****************************************************************************}
{**                        Unit's Register procedures                      **}
{****************************************************************************}

procedure RegisterGLSupprt;
begin
  RegisterType(RBlock);
end; {...RegisterGLSupprt }

{****************************************************************************}
{**                             TBlock Object                              **}
{****************************************************************************}

constructor TBlock.Init(InitStart : CellPos);
{ Initializes a the starting and ending position of a block of cells }
begin
  Anchor := InitStart;
  Start := Anchor;
  Stop := Anchor;
  AnchorColShifted := False;
  AnchorRowShifted := False;
end; {...TBlock.Init }

function TBlock.CellInBlock(CheckCell : CellPos) : Boolean;
{ Checks to see if a cell is inside a particular block }
begin
  CellInBlock := (CheckCell.Col >= Start.Col) and
    (CheckCell.Col <= Stop.Col) and (CheckCell.Row >= Start.Row) and
    (CheckCell.Row <= Stop.Row);
end; {...TBlock.CellInBlock }

function TBlock.ExtendTo(NewLoc : CellPos) : Boolean;
{ Extends a block to the given position }
begin
  ExtendTo := True;
  if (NewLoc.Col >= Anchor.Col) and (NewLoc.Row >= Anchor.Row) then
    begin
      Stop := NewLoc;
      if AnchorColShifted or AnchorRowShifted then
      begin
        Start := Anchor;
        AnchorColShifted := False;
        AnchorRowShifted := False;
      end; {...if AnchorColShifted or AnchorRowShifted }
    end {...if (NewLoc.Col >= Anchor.Col) and (NewLoc.Row >= Anchor.Row) }
  else
    begin
      if NewLoc.Row < Anchor.Row then
        begin
          if not AnchorRowShifted then
            begin
              Start.Row := NewLoc.Row;
              Stop.Row := Anchor.Row;
              AnchorRowShifted := True;
            end {...if not AnchorRowShifted }
          else
            Start.Row := NewLoc.Row;
        end {...if NewLoc.Row < Anchor.Row }
      else
        begin
          if AnchorRowShifted then
          begin
            Start.Row := Anchor.Row;
            AnchorRowShifted := False;
          end; {...if AnchorRowShifted }
          Stop.Row := NewLoc.Row;
        end; {...if/else }
      if NewLoc.Col < Anchor.Col then
        begin
          if not AnchorColShifted then
            begin
              Start.Col := NewLoc.Col;
              Stop.Col := Anchor.Col;
              AnchorColShifted := True;
            end {...if not AnchorColShifted }
          else
            Start.Col := NewLoc.Col;
        end {...if NewLoc.Col < Anchor.Col }
      else
        begin
          if AnchorColShifted then
          begin
            Start.Col := Anchor.Col;
            AnchorColShifted := False;
          end; {...if AnchorColShifted }
          Stop.Col := NewLoc.Col;
        end; {...if/else }
    end; {...if/else }
end; {...TBlock.ExtendTo }

constructor TBlock.Load(var S: TStream);
begin
  S.Read(Start, SizeOf(Start));
  Init(Start);
  S.Read(Stop, SizeOf(Stop));
end; {...TBlock.Load }

procedure TBlock.Store(var S: TStream);
begin
  S.Write(Start, SizeOf(Start));
  S.Write(Stop, SizeOf(Stop));
end; {...TBlock.Store }


{****************************************************************************}
{**                          TScreenArea Object                            **}
{****************************************************************************}

constructor TScreenArea.Init (InitX1: ScreenColRange; InitY1: ScreenRowRange;
  InitX2: ScreenColRange; InitY2: ScreenRowRange; InitAttrib: Word);
begin
  UpperLeft.Col := InitX1;
  UpperLeft.Row := InitY1;
  LowerRight.Col := InitX2;
  LowerRight.Row := InitY2;
  Attrib := InitAttrib;
end; {...TScreenArea.Init }

function TScreenArea.PointInArea(X, Y: Byte): Boolean;
{ Determines if the given point is in the area defined by the object }
begin
  if (X >= UpperLeft.Col) and (X <= LowerRight.Col) and (Y >= UpperLeft.Row)
     and (Y <= LowerRight.Row) then
    PointInArea := True
  else
    PointInArea := False;
end; {...TScreenArea.PointInArea }

end. {...GLSupprt unit }