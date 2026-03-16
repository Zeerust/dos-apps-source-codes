{********************************************************************

  OOGrid Library(TM) for Borland/Turbo Pascal (Real Mode/TV)
  Copyright (C) 1994, 1995 by Arturo J. Monge
  Portions Copyright (C) 1989,1990 Borland International, Inc.

  OOGrid Library(TM) Main Unit:
    Implementation of a spreadsheet.

  Copyright (C) 1994, 1995 by Arturo J. Monge

  Last Modification : June 1st, 1995

*********************************************************************}

{$F+,O+,N+,E+,X+,V-}

unit GLTSheet;

{****************************************************************************}
                                 interface
{****************************************************************************}

uses Crt, Dialogs, Dos, Objects, Views, Drivers, TCHash, GLSort, GLParser, GLSupprt,
     GLCell, GLViews, GLEquate;

const

{ Constants used by TSpreadSheet's methods }

  RedrawYes = True;
  RedrawNo  = False;
  EditYes = True;
  EditNo = False;
  DisplayYes = True;
  DisplayNo = False;
  ModifiedYes = True;
  ModifiedNo = False;
  RemoveBlock = True;
  RemoveSingleCell = False;
  ChangeYes = True;
  ChangeNo = False;

const

{ TSpreadSheet palette }

 CSpreadSheet = #12#13#14#15#16#17#18#19#20#21#22#23#24#25#26#27#28#29#30+
                #31#32#33#34#35#36;

{ CSpreadSheet palette layout }

  { 1 = Empty Cell }
  { 2 = Value Cell }
  { 3 = Text Cell }
  { 4 = Repeat Cell }
  { 5 = Formula Cell }
  { 6 = Column headers }
  { 7 = Row numbers }
  { 8 = Cell Data Area }
  { 9 = Cell Contents Area }
  { 10 = Spreadsheet Info Area }
  { 11 = Cell In Block }
  { 12 = Cell Highlighted }
  { 13 = Cell Highlighted in Block }
  { 14 = Unlocked Cell }
  { 15 = Unlocked Cell in Block }
  { 16 = Unlocked Cell Highlighted }
  { 17 = Unlocked Cell Highlighted in Block }
  { 18 = Cell Error }
  { 19 = Cell Error in Block }
  { 20 = Cell Error Highlighted }
  { 21 = Cell Error Highlighted in Block }
  { 22 = Unlocked Cell Error }
  { 23 = Unlocked Cell Error in Block }
  { 24 = Unlocked Cell Error Highlighted }
  { 25 = Unlocked Cell Error Highlighted in Block }

const
  DisplayEnabled : Boolean = True;
  { Used by TSpreadSheet's SetChanged method.  When DisplayEnabled is True,
    SetChanged will display the information area of the spreadsheet
    to indicate a change in the Modified state.  This global constant
    was added to be able to store TSpreadSheet objects in a resource
    file, without having to insert them in the application first.  This
    field is always set to False when using the GLTVR_US or GLTVR_SP
    units. }
  {#X TSpreadSheet.DisplayInfo TSpreadSheet.SetChanged TSpreadSheet.Modified }

type
   PColStart = ^ColStartArray;
   ColStartArray = array[0..ScreenCols] of Byte;
   { Array used to store the screen positions where displayed columns start }

   PSpreadSheet = ^TSpreadSheet;
   TSpreadSheet = object(TScroller)
         Modified             : Boolean;
         MaxDecimalPlaces     : Byte;
         DefaultColWidth      : Byte;
         DefaultDecimalPlaces : Byte;
         DefaultCurrency      : CurrencyStr;
         MaxRows              : Integer;
         MaxCols              : Integer;
         MaxColWidth          : Byte;
         MaxScreenCols        : Byte;
         TotalRows            : ScreenRowRange;
         RowNumberSpace       : Byte;
         OldCurrPos           : CellPos;
         CurrPos              : CellPos;
         LastPos              : CellPos;
         ScreenBlock          : PBlock;
         CurrBlock            : PBlock;
         BlockOn              : Boolean;
         ColArea              : TScreenArea;
         RowArea              : TScreenArea;
         InfoArea             : TScreenArea;
         DataArea             : TScreenArea;
         DisplayArea          : TScreenArea;
         ContentsArea         : TScreenArea;
         BlankArea            : TScreenArea;
         NoBlankArea          : Boolean;
         ColStart             : PColStart;
         CellHash             : TCellHashTable;
         WidthHash            : TWidthHashTable;
         OverwriteHash        : TOverwriteHashTable;
         FormatHash           : TFormatHashTable;
         DisplayFormulas      : Boolean;
         AutoCalc             : Boolean;
         GoToEnd              : Boolean;
         KeyPressed           : Boolean;
         EmptyRowsAtTop       : Byte;
         EmptyRowsAtBottom    : Byte;
         SheetProtected       : Boolean;
         DisplayHeaders       : Boolean;
         UnlockedHash         : TUnlockedHashTable;
         ColHeadersHash       : THeadersHashTable;
         MessageDialog : PDialog;
         { This field is used as a pointer the currently active message
           dialog.  If no message dialogs are active, TempDialog is set
           to nil.

           Message dialogs are modeless dialogs, with no buttons, which
           only purpose is giving the user a message while TSpreadSheet
           is working on a given operation.  For example, }
         {#F+}
         {}
         {   'Updating data tables... please wait.' }
         {#F-}
      constructor Init(var Bounds: TRect; InitCells: LongInt;
                           AEmptyRowsAtTop, AEmptyRowsAtBottom: Byte;
                           AHScrollBar, AVScrollBar: PScrollBar;
                           AInitMaxCols, AInitMaxRows: Integer;
                           InitDefaultColWidth,
                           InitDefaultDecimalPlaces,
                           InitMaxDecimalPlaces: Byte;
                           InitDefaultCurrency: CurrencyStr);
      function  AddCell(CellType: CellTypes; Pos: CellPos; Error: Boolean;
                  Value: Extended; Input: String): Boolean; virtual;
      function  CellHashStart(TotalCells: LongInt): BucketRange; virtual;
      function  CellsProtected(Block: TBlock): Boolean; virtual;
      function  CellToFString(P: CellPos; var AColor: Byte): String; virtual;
      procedure ChangeBounds(var Bounds: TRect); virtual;
      procedure ChangeColHeaders; virtual;
      procedure ChangeColWidth; virtual;
      procedure ChangeHeader(Block: PBlock; AColumn: Word; NewHeader: String);
        virtual;
      { Changes the header of a column or block of columns.

        The Block and AColumn parameters are mutually exclusive.  If Block
        is not nil, the AColumn parameter will be ignored; otherwise, the
        Block parameter is ignored and the AColumn parameter is used instead.

        Use Block if you want to change the header of a block of
        columns.  Use AColumn if you want to change the header of a single
        column. }
      procedure ChangeWidth(Block: PBlock; AColumn: Word; NewWidth: Byte);
        virtual;
      { Changes the width of a column or block of columns.

        The Block and AColumn parameters are mutually exclusive.  If Block
        is not nil, the AColumn parameter will be ignored; otherwise, the
        Block parameter is ignored and the AColumn parameter is used instead.

        Use Block if you want to change the width of a block of
        columns.  Use AColumn if you want to change the width of a single
        column. }
      procedure CheckForDragging; virtual;
      procedure ClearCurrBlock; virtual;
      procedure ClearScreenArea(AreaToClear: PScreenArea); virtual;
      function  ColHeadersHashStart : BucketRange; virtual;
      function  ColumnToString(Column: Word): String; virtual;
      function  ColToX(Col: Integer): Byte; virtual;
      function  ColWidth(Col: Integer): Byte; virtual;
      procedure CopyCellBlock; virtual;
      procedure DeleteBlock(Block: TBlock; var Deleted: Boolean); virtual;
      procedure DeleteCell(Pos: CellPos; var Deleted: Boolean); virtual;
      procedure DeleteColFromHash(Block: TBlock; Columns, EndDelCol: Word);
        virtual;
      procedure DeleteColHeaders(Block: PBlock); virtual;
      procedure DeleteColumns; virtual;
      procedure DeleteRowFromHash(Block: TBlock; Rows, EndDelRow: Word);
        virtual;
      procedure DeleteRows; virtual;
      procedure DisplayAllCells; virtual;
      procedure DisplayBlock(B: TBlock); virtual;
      procedure DisplayBlockDiff(B1, B2: TBlock); virtual;
      procedure DisplayCell(P: CellPos); virtual;
      procedure DisplayCellBlock(C1, R1, C2, R2: Word); virtual;
      procedure DisplayCellData; virtual;
      procedure DisplayCols; virtual;
      procedure DisplayInfo; virtual;
      procedure DisplayRows; virtual;
      procedure DoAfterAddingCell; virtual;
      function  DoBeforeAddingCell: Boolean; virtual;
      { This function is called immediatly after an input string has been
        parsed in the #HandleInput# method, and before actually adding the
        corresponding cell.  If DoBeforeAddingCell returns TRUE the cell is
        added; if it returns FALSE, the cell won't be added and the user
        will be returned to the input line.

        If there is an error in the input string, this function will not
        be called.

        You should override this function if you want, for example, to
        validate the data that is entered in each column.  If the data
        entered by the user cannot be added to the current column,
        DoBeforeAddingCell can display an error message and return false.
        By default, DoBeforeAddingCell returns true. }
      procedure DragCursorWithMouse(Event: TEvent); virtual;
      procedure Draw; virtual;
      procedure EraseCellBlock(EraseBlock: Boolean); virtual;
      procedure ExtendCurrBlock(Redraw : Boolean); virtual;
      procedure FindLastPos(DPos: CellPos); virtual;
      procedure FindScreenColStart; virtual;
      procedure FindScreenColStop; virtual;
      procedure FindScreenRowStart; virtual;
      procedure FindScreenRowStop; virtual;
      procedure FixBlockOverWrite(Block: TBlock); virtual;
      function  FixOverWrite: Boolean; virtual;
      procedure FormatDefault; virtual;
      function  FStringSituationColor(P: CellPos; var CP: PCell;
                  var HasError, ColorFound: Boolean): Byte; virtual;
      procedure FormatCells; virtual;
      function GetNumber: Integer;
      { Returns the number of the window that owns the object }
      function  GetPalette: PPalette; virtual;
      procedure GoToCell; virtual;
      procedure GoToPos(Pos: CellPos); virtual;
      { Moves the cursor to the given position and redraws the screen if
        necessary. }
      procedure HandleEvent(var Event: TEvent); virtual;
      procedure HandleInput(FirstChar: String; Editing: Boolean); virtual;
      procedure InitCurrPos; virtual;
      procedure InsertColToHash(Block: TBlock; Columns, StartInsCol: Word);
        virtual;
      procedure InsertColumns; virtual;
      procedure InsertRowToHash(Block: TBlock; Rows, StartInsRow: Word);
        virtual;
      procedure InsertRows; virtual;
      constructor Load(var S: TStream);
      procedure LoadDelimited(FileName: PathStr); virtual;
      { This method imports a comma delimited file of a certain format and
        is intended only as an example of how to import comma delimited files.
        This method must be overridden if you wish to import delimited files
        of different formats }
      procedure LoadHashTables(var S: TStream; AdjustAfter: CellPos;
                  RowAdjustment, ColAdjustment: Integer); virtual;
      procedure LoadTablesFromTempFile(AdjustAfter: CellPos;
                  RowAdjustment, ColAdjustment: Integer); virtual;
      procedure LocateCursorWithMouse(Event: TEvent); virtual;
      procedure MoveCell(OldPos: CellPos); virtual;
      procedure MoveCellBlock; virtual;
      procedure MoveDown; virtual;
      procedure MoveHome; virtual;
      procedure MoveLeft; virtual;
      procedure MovePgDown; virtual;
      procedure MovePgLeft; virtual;
      procedure MovePgRight; virtual;
      procedure MovePgUp; virtual;
      procedure MoveRight; virtual;
      procedure MoveUp; virtual;
      function  OverwriteHashStart: BucketRange; virtual;
      function  Parser: PParserObject; virtual;
      procedure PasteBlock(DestBlock: TBlock; Formulas: Word); virtual;
      procedure PasteCellBlock; virtual;
      procedure Print; virtual;
      procedure Recalc(Display: Boolean); virtual;
      function  RowToY(Row: Integer): Byte; virtual;
      function  SameCellPos(P1, P2 : CellPos) : Boolean; virtual;
      procedure ScrollDraw; virtual;
      function  SelectColumn(var Event: TEvent): Boolean; virtual;
      procedure SetAreas(ScrollArea: TRect); virtual;
      procedure SetAvailableCommands; virtual;
      { Enables all commands handled by TSpreadSheet.  Some commands
        may not be enabled if the spreadsheet is protected. }
      {#X SheetProtected }
      procedure SetBlankArea; virtual;
      procedure SetChanged(IsChanged: Boolean); virtual;
      procedure SetFormat(Block: TBlock; DecimalPlaces: Byte; Justification,
        NumberFormat: Word; CurrencyChar: Char); virtual;
      { Formats a block of cells using the given format information.

        Possible values of the Justification parameter and their meanings:}
      {#F+}
      {}
      { Value  ณ  Meaning                }
      { อออออออุออออออออออออออออออออออออ }
      {   0    ณ  Left justification     }
      {   1    ณ  Center justification   }
      {   2    ณ  Right justification    }
      {#F-}
      { Possible values of the NumberFormat parameter and their meainigs:}
      {#F+}
      {}
      { Value  ณ Meaning                                         }
      { อออออออุออออออออออออออออออออออออออออออออออออออออออออออออ }
      {  0     ณ Do not format numbers                           }
      {  1     ณ Add a currency character to numbers             }
      {  2     ณ Add commas to numbers                           }
      {  3     ณ Add commans and a currency character to numbers }
      {#F-}
      procedure SetLimit(X, Y: Integer); virtual;
      procedure SetLocked; virtual;
      procedure SetNameWithMouse(var Event: TEvent); virtual;
      procedure SetProtection(Enable, Display: Boolean); virtual;
      procedure SetScreenColStart(NewCol: Integer); virtual;
      procedure SetScreenColStop(NewCol: Integer); virtual;
      procedure SetScreenRowStart(NewRow: Integer); virtual;
      procedure SetScreenRowStop(NewRow: Integer); virtual;
      procedure SetState(AState: Word; Enable: Boolean); virtual;
      procedure SetUnlocked; virtual;
      procedure SortData; virtual;
      function  SortObject : PSortObject; virtual;
      procedure Store(var S: TStream);
      procedure StoreHashTables(var S: TStream); virtual;
      procedure StoreTablesToTempFile; virtual;
      procedure ToggleAutoCalc; virtual;
      procedure ToggleBlockOn; virtual;
      procedure ToggleDisplayHeaders; virtual;
      procedure ToggleEnd; virtual;
      procedure ToggleFormulaDisplay; virtual;
      function  TrackCursor: Boolean; virtual;
      procedure UpdateScreenBlockDisplay; virtual;
      function  WidthHashStart:BucketRange; virtual;
      function  XToCol(X: Byte): Integer; virtual;
      function  YToRow(Y: Byte): Integer; virtual;
      procedure DoneHashTables; virtual;
      destructor Done; virtual;
   end; {...TSpreadSheet }

type
  BlockOperation = (opCopy, opMove);
  { Used by the clipboard record to indicate what kind of operation
    was requested }

  ClipBoardRecord = RECORD
  { This record is used to store information necessary for copy and move
    operations }
    Active            : Boolean;
    SourceSpreadSheet : PSpreadSheet;
    SourceCellHash    : PCellHashTable;
    BlockToCopy       : PBlock;
    CopyBlock         : Boolean;
    Operation         : BlockOperation;
  end; {...ClipBoardRecord }

var
  Clipboard : ClipBoardRecord;

procedure RegisterSpreadSheet;
{ Register all the units in OOGrid Library(TM) v1.0 }

procedure RegisterGLTSheet;
{ Register this unit's objects }

const
   RSpreadSheet : TStreamRec = (
      ObjType : stRSpreadSheet;
      VmtLink : Ofs(TypeOf(TSpreadSheet)^);
      Load    : @TSpreadSheet.Load;
      Store   : @TSpreadSheet.Store
   );

{****************************************************************************}
                               implementation
{****************************************************************************}

uses App, Memory, TCUtil, MsgBox, StdDlg, GLWindow;

const
  OOGridFileHeader = 'OOGridLv1.00';
  { All TSpreadSheet objects stored in a stream will be identified by
    this file header.

    Version 1.00 refers to the stream version, not to the library's
    version (i.e. it refers to the version of the load and store
    methods). }

{****************************************************************************}
{**             Clipboard variables, procedures and functions              **}
{****************************************************************************}

procedure InitClipBoard;
{ Resets the ClipBoard fields }
begin
  with ClipBoard do
  begin
    Active := False;
    SourceSpreadSheet := nil;
    SourceCellHash := nil;
    if BlockToCopy <> nil then
    begin
      Dispose(BlockToCopy);
      BlockToCopy := nil;
    end; {...if BlockToCopy <> nil }
    Operation := opCopy;
    CopyBlock := False;
  end; {...with ClipBoard }
end; {...InitClipBoard }

procedure ToggleClipBoardOn(SpreadSheet: PSpreadSheet; Block: PBlock;
  ABlockOn: Boolean; Op: BlockOperation);
{ Sets the Clipboard fields for a copy or move operation }
begin
  with Clipboard do
  begin
    Active := True;
    SourceSpreadSheet := SpreadSheet;
    SourceCellHash := @SpreadSheet^.CellHash;
    BlockToCopy := Block;
    CopyBlock := ABlockOn;
    Operation := Op;
  end; {...with ClipBoard }
  if Op = opCopy then
    begin
      if not DisplayMessage(GLStringList^.Get(sCopyCellsMsg)) then
      begin
        Application^.OutOfMemory;
        InitClipBoard;
      end; {...if not DisplayMessage(GLStringList^.Get(sCopyCellsMsg)) }
    end {...if Op = opCopy }
  else
    begin
      if not DisplayMessage(GLStringList^.Get(sMoveCellsMsg)) then
      begin
        Application^.OutOfMemory;
        InitClipBoard;
      end; {...if not DisplayMessage(GLStringList^.Get(sMoveCellsMsg)) }
    end; {...if/else }
end; {...ToggleClipBoardOn }


procedure ToggleClipBoardOff;
{ Clears the ClipBoard }
begin
  InitClipBoard;
  EraseMessage;
end; {...ToggleClipBoardOff }


{****************************************************************************}
{**                         GetColWidth function                           **}
{****************************************************************************}

function GetColWidth(var WHash : TWidthHashTable; C : Word) : Byte;
{ Gets the width of a column }
var
  W : Word;
begin
  W := WHash.Search(C);
  if W = 0 then
    GetColWidth := WHash.GetDefaultColWidth
  else
    GetColWidth := W;
end; {...GetColWidth }

{****************************************************************************}
{**                        Unit's Register procedures                      **}
{****************************************************************************}

procedure RegisterSpreadSheet;
{ Register all streamable objects of the spreadsheet }
begin
   RegisterGLTSheet;
   RegisterGLSupprt;
   RegisterGLCell;
   RegisterGLViews;
end; {...RegisterSpreadSheet }

procedure RegisterGLTSheet;
begin
  RegisterType(RSpreadSheet);
end; {...RegisterGLTSheet }

{****************************************************************************}
{**                          TSpreadSheet Object                           **}
{****************************************************************************}

constructor TSpreadSheet.Init(var Bounds: TRect;
  InitCells: LongInt; AEmptyRowsAtTop, AEmptyRowsAtBottom: Byte;
  AHScrollBar, AVScrollBar: PScrollBar; AInitMaxCols,
  AInitMaxRows: Integer; InitDefaultColWidth, InitDefaultDecimalPlaces,
  InitMaxDecimalPlaces: Byte; InitDefaultCurrency: CurrencyStr);
const
  MinRowsToDisplay = 2;
var
  CellPosition : CellPos;
  R : TRect;
begin
  if not TScroller.Init(Bounds, AHScrollBar, AVScrollBar) then
    Fail;
  Delta.X := 1;
  Delta.Y := 1;
  EventMask := evMouseDown + evKeyDown + evCommand + evBroadCast;
  Options := Options and not ofBuffered;
  GrowMode := gfGrowHiX + gfGrowHiY;
  if HScrollBar <> nil then
  begin
    HScrollBar^.EventMask := HScrollBar^.EventMask and not evKeyDown;
    with PLimScrollBar(HScrollBar)^ do
    begin
      DisplayLimit := TCUtil.Min(DisplayLimit, AInitMaxCols);
    end; { with }
  end; { if }
  if VScrollBar <> nil then
  begin
    VScrollBar^.EventMask := VScrollBar^.EventMask and not evKeyDown;
    with PLimScrollBar(VScrollBar)^ do
    begin
      DisplayLimit := TCUtil.Min(DisplayLimit, AInitMaxRows);
    end; { with }
  end; { if }
  if not CellHash.Init(CellHashStart(InitCells)) then
    Fail;
  if not WidthHash.Init(WidthHashStart, InitDefaultColWidth) then
  begin
    CellHash.Done;
    Fail;
  end; {...if not WidthHash.Init }
  if not OverwriteHash.Init(OverwriteHashStart) then
  begin
    CellHash.Done;
    WidthHash.Done;
    Fail;
  end; {...if not OverWriteHash.Init }
  if not FormatHash.Init then
  begin
    CellHash.Done;
    WidthHash.Done;
    OverwriteHash.Done;
    Fail;
  end; {...if not FormatHash.Init }
  if not ColHeadersHash.Init(ColHeadersHashStart) then
  begin
    CellHash.Done;
    WidthHash.Done;
    OverWriteHash.Done;
    FormatHash.Done;
    Fail;
  end; {...if not ColHeadersHash.Init }
  if not UnlockedHash.Init then
  begin
    CellHash.Done;
    WidthHash.Done;
    OverWriteHash.Done;
    FormatHash.Done;
    ColHeadersHash.Done;
    Fail;
  end; {...if not UnlockedHash.Init }
  EmptyRowsAtTop := AEmptyRowsAtTop;
  EmptyRowsAtBottom := AEmptyRowsAtBottom;
  RowNumberSpace := 6;
  MaxColWidth := Succ(ScreenCols - RowNumberSpace);
  MaxScreenCols := MaxColWidth div DefaultMinColWidth;
  GetMem(ColStart, MaxScreenCols);
  if ColStart = nil then
  begin
    CellHash.Done;
    WidthHash.Done;
    OverWriteHash.Done;
    FormatHash.Done;
    ColHeadersHash.Done;
    UnlockedHash.Done;
    Fail;
  end; {...if ColStart = nil }
  InitCurrPos;
  OldCurrPos := CurrPos;
  LastPos := CurrPos;
  BlockOn := False;
  AutoCalc := False;
  DisplayFormulas := False;
  GoToEnd := False;
  ScreenBlock := New(PBlock, Init(CurrPos));
  CurrBlock := New(PBlock, Init(CurrPos));
  DefaultColWidth := InitDefaultColWidth;
  DefaultDecimalPlaces := InitDefaultDecimalPlaces;
  DefaultCurrency := InitDefaultCurrency;
  MaxDecimalPlaces := InitMaxDecimalPlaces;
  MaxCols := AInitMaxCols;
  MaxRows := AInitMaxRows;
  GetExtent(R);
  Inc(R.A.Y, EmptyRowsAtTop);
  Dec(R.B.Y, EmptyRowsAtBottom);
  SetAreas(R);
  SetLimit(MaxCols, MaxRows);
  DisplayHeaders := True;
  SetProtection(False, False);
  SetAvailableCommands;
  MessageDialog := nil;
end; {...TSpreadSheet.Init }


function TSpreadSheet.AddCell(CellType: CellTypes; Pos: CellPos;
  Error: Boolean; Value: Extended; Input: String): Boolean;
{ Adds a cell to the cell hash }
var
  OldLastPos : CellPos;
  CellPtr, CP : PCell;
begin
  AddCell := False;
  case CellType of
    ClValue   : CellPtr := New(PValueCell, Init(Pos, Error, Value));
    ClFormula : CellPtr := New(PFormulaCell, Init(Pos, Error, Value, Input));
    ClText    : CellPtr := New(PTextCell, Init(Pos, Input));
    ClRepeat  : CellPtr := New(PRepeatCell, Init(Pos, Input[2]));
  end; {...case CellType }
  if CellPtr = nil then
    Exit;
  if not CellHash.Add(CellPtr) then
  begin
    Dispose(CellPtr, Done);
    Exit;
  end; {...if not CellHash.Add(CellPtr) }
  OldLastPos := LastPos;
  FindLastPos(Pos);
  if not OverWriteHash.Add(CellPtr, CellHash, FormatHash, WidthHash, LastPos,
    MaxCols, GetColWidth, DisplayFormulas, ChangeYes) then
  begin
    LastPos := OldLastPos;
    CellHash.Delete(CellPtr^.Loc, CP);
    Dispose(CellPtr, Done);
    Exit;
  end; {...if not OverWriteHash.Add }
  AddCell := True;
end; {...TSpreadSheet.AddCell }


function TSpreadSheet.CellHashStart(TotalCells: LongInt): BucketRange;
{ Returns the initial number of buckets for the Cell hash table }
begin
  CellHashStart := Max(100, Min(MaxBuckets, TotalCells div 10));
end; {...TSpreadSheet.CellHashStart}


function TSpreadSheet.CellsProtected(Block: TBlock): Boolean;
var
  P : CellPos;
begin
  CellsProtected := False;
  if SheetProtected then
  begin
    for P.Row := Block.Start.Row to Block.Stop.Row do
      for P.Col := Block.Start.Col to Block.Stop.Col do
        if not UnlockedHash.Search(P) then
        begin
          CellsProtected := True;
          Exit;
        end; {...if not UnlockedHash.Search(P) }
  end; {...if SheetProtected }
end; {...TSpreadSheet.CellsProtected }


function TSpreadSheet.CellToFString(P: CellPos; var AColor: Byte): String;
{ Returns the formatted contents of a cell to be displayed in the screen }
var
  ColorFound, HasError : Boolean;
  S1 : CurrencyStr;
  F  : FormatType;
  CP : PCell;
  S  : String;
  ClType : CellTypes;
begin
  AColor := FStringSituationColor(P, CP, HasError, ColorFound);
  if HasError and not (DisplayFormulas and (CP^.CellType = ClFormula)) then
    begin
      S := GLStringList^.Get(sCellError);
      S1 := '';
      F := Ord(JCenter) shl JustShift;
    end {...if HasError and ... }
  else
    begin
      S := CP^.FormattedString(OverwriteHash, FormatHash, WidthHash,
        GetColWidth, P, DisplayFormulas, 1, ColWidth(P.Col), S1, ClType);
      if not ColorFound then
        case ClType of
          ClEmpty : AColor := GetColor(1);
          ClText : AColor := GetColor(3);
          ClValue : AColor := GetColor(2);
          ClFormula : if DisplayFormulas then
                        AColor := GetColor(5)
                      else
                        AColor := GetColor(2);
          ClRepeat : AColor := GetColor(4);
        end; {...case ClType }
      F := CP^.Format(FormatHash, DisplayFormulas);
    end; {...if/else }
  if (Length(S1) + Length(S)) <= ColWidth(P.Col) then
    case Justification((F shr JustShift) and JustPart) of
      JLeft : CellToFString := S1 + LeftJustStr(S, ColWidth(P.Col) -
                Length(S1));
      JCenter : CellToFString := S1 + CenterStr(S, ColWidth(P.Col) -
                  Length(S1));
      JRight : CellToFString := S1 + RightJustStr(S, ColWidth(P.Col) -
                 Length(S1));
    end {...case Justification((F shr JustShift) and JustPart) }
  else
    CellToFString := Copy(S1 + S, 1, ColWidth(P.Col));
end; {...TSpreadSheet.CellToFString }


procedure TSpreadSheet.ChangeBounds(var Bounds: TRect);
{ Changes the size of the spreadsheet and resets the limits of the scroller }
begin
  TScroller.ChangeBounds(Bounds);
  SetLimit(MaxCols, MaxRows);
end; {...TSpreadSheet.ChangeBounds }


{****************************************************************************}
{ TSpreadSheet.ChangeColHeaders                                              }
{****************************************************************************}
procedure TSpreadSheet.ChangeColHeaders;
{ Changes the header of a column or group of columns }
var
  Cancel, HeaderEntered : Boolean;
  Dialog : PDialog;
  CellPtr : PCell;
  Column : Word;

    procedure GetValidHeader;
    { Returns WidthEntered as true if a valid width was entered }
    var
      Code : Integer;
    begin
      if Desktop^.ExecView(Dialog) <> cmCancel then
        begin
          Dialog^.GetData(RChangeHeader);
          HeaderEntered := True;
        end {...if Desktop^.ExecView(Dialog) <> cmCancel }
      else
        Cancel := True;
    end; {...GetValidHeader }

begin
  Cancel := False;
  HeaderEntered := False;
  Dialog := PDialog(GLResFile^.Get('ChangeHeaderDialog'));
  if not BlockOn or (BlockOn and (CurrBlock^.Start.Col = CurrBlock^.Stop.Col)) then
    begin
      if not ColHeadersHash.Search(CurrPos.Col, RChangeHeader.NewHeader) then
        RChangeHeader.NewHeader := GLStringList^.Get(sColumnEntryIndicator) +
        ' '+ColumnToString(CurrPos.Col)
    end {...if not BlockOn or ... }
  else
    RChangeHeader.NewHeader := '';
  Dialog^.SetData(RChangeHeader);
  repeat
    if (Application^.ValidView(Dialog) <> nil) then
      GetValidHeader
    else
      Exit;
  until HeaderEntered or Cancel;
  if not Cancel then
  begin
    with RChangeHeader do
    begin
      if Copy(NewHeader, 1, Length(GLStringList^.Get(sColumnEntryIndicator)))
         = GLStringList^.Get(sColumnEntryIndicator) then
        NewHeader := Copy(NewHeader, Length(GLStringList^.
          Get(sColumnEntryIndicator))+2, Length(NewHeader) -
          Length(GLStringList^.Get(sColumnEntryIndicator))+1);
      if not BlockOn then
      begin
        CurrBlock^.Start := CurrPos;
        CurrBlock^.Stop := CurrPos;
      end; { if }
      ChangeHeader(CurrBlock, 0, NewHeader);
      SetChanged(ModifiedYes);
    end; { with }
    DrawView;
  end; {...if not Cancel }
  Dispose(Dialog, Done);
end; {...TSpreadSheet.ChangeColHeaders }


{****************************************************************************}
{ TSpreadSheet.ChangeColWidth                                                }
{****************************************************************************}
procedure TSpreadSheet.ChangeColWidth;
{ Changes the width of a column or group of columns }
var
  Cancel, WidthEntered : Boolean;
  NewWidth : Byte;
  Dialog : PDialog;
  CellPtr : PCell;
  CurrWidth : String[10];
  CellsOverWritten : Word;

    procedure GetValidWidth(Dialog: PDialog; var Cancel,
      WidthEntered: Boolean; var NewWidth: Byte);
      { Returns WidthEntered as true if a valid width was entered }
    var
      Code : Integer;
    begin
      if Desktop^.ExecView(Dialog) <> cmCancel then
        begin
          Dialog^.GetData(RChangeWidth);
          Val(RChangeWidth.NewWidth, NewWidth, Code);
          if not ((NewWidth >= DefaultMinColWidth) and
             (NewWidth <= MaxColWidth) or (NewWidth = 0)) then
            MessageBox(GLStringList^.Get(sInvalidWidthMsg), nil, mfError +
              mfOKButton)
          else
            begin
              WidthEntered := True;
              if NewWidth = 0 then NewWidth := DefaultColWidth;
            end; {...if/else }
        end {...if Desktop^.ExecView(Dialog) <> cmCancel }
      else
        Cancel := True;
   end; {...GetValidWidth }

begin
  Cancel := False;
  WidthEntered := False;
  Dialog := PDialog(GLResFile^.Get('GetWidthDialog'));
  if (not BlockOn) or (BlockOn and
     (CurrBlock^.Start.Col = CurrBlock^.Stop.Col)) then
    Str(ColWidth(CurrPos.Col), CurrWidth)
  else
    Str(DefaultColWidth, CurrWidth);
  Dialog^.SetData(CurrWidth);
  repeat
    if (Application^.ValidView(Dialog) <> nil) then
      GetValidWidth(Dialog, Cancel, WidthEntered, NewWidth)
    else
      Exit;
  until WidthEntered or Cancel;
  if not Cancel then
  begin
    if not BlockOn then
    begin
      CurrBlock^.Start := CurrPos;
      CurrBlock^.Stop := CurrPos;
    end; { if }
    ChangeWidth(CurrBlock, 0, NewWidth);
    SetChanged(ModifiedYes);
    SetScreenColStart(ScreenBlock^.Start.Col);
    if CurrPos.Col > ScreenBlock^.Stop.Col then
      HScrollBar^.SetValue(CurrPos.Col);
    DrawView;
  end; {...if not Cancel }
  Dispose(Dialog, Done);
end; {...TSpreadSheet.ChangeColWidth }


{****************************************************************************}
{ TSpreadSheet.ChangeHeader                                                  }
{****************************************************************************}
procedure TSpreadSheet.ChangeHeader(Block: PBlock; AColumn: Word; NewHeader:
  String);
var
  Column : Word;
  Pos: CellPos;
  SingleCol: Boolean;
begin
  if Block = nil then
    begin
      Pos.Col := AColumn;
      Pos.Row := 0;
      Block := New(PBlock, Init(Pos));
      SingleCol := True;
    end { if }
  else
    SingleCol := False;
  with ColHeadersHash, Block^ do
  begin
    for Column := Start.Col to Stop.Col do
    begin
      if NewHeader <> ColToString(Column) then
      begin
        Delete(Column);
        if (NewHeader <> '') then
        begin
          if not Add(Column, NewHeader) then
            Exit;
        end; {...if NewHeader <> '' }
      end; {...if NewHeader <> ColToString(Column) }
      Delete(Column);
      if (NewHeader <> '') and (NewHeader <> ColToString(Column)) then
      begin
        if not Add(Column, NewHeader) then
          Exit;
      end; {...if (NewHeader <> '') and ... }
    end; {...for Column }
  end; {...with ColHeadersHash, CurrBlock^ }
  if SingleCol then
    Dispose(Block, Done);
end;

{****************************************************************************}
{ TSpreadSheet.ChangeWidth                                                   }
{****************************************************************************}
procedure TSpreadSheet.ChangeWidth(Block: PBlock; AColumn: Word; NewWidth:
  Byte);
var
  Column : Word;
  Pos: CellPos;
  SingleCol: Boolean;
begin
  if Block = nil then
    begin
      Pos.Col := AColumn;
      Pos.Row := 0;
      Block := New(PBlock, Init(Pos));
      SingleCol := True;
    end { if }
  else
    SingleCol := False;
  with WidthHash, Block^ do
  begin
    for Column := Start.Col to Stop.Col do
    begin
      Delete(Column);
      if NewWidth <> DefaultColWidth then
      begin
        if not Add(Column, NewWidth) then
          Exit;
      end; {...if NewWidth <> DefaultColWidth }
    end; {...for Column }
  end; { with }
  with OverWriteHash do
  begin
    Done;
    Init(OverWriteHashStart);
  end; {with OverWriteHash }
  FixOverWrite;
  if SingleCol then
    Dispose(Block, Done);
end;

procedure TSpreadSheet.CheckForDragging;
var
  ShiftState : Byte absolute $40:$17;
begin
  if (ShiftState and (kbRightShift + kbLeftShift)) <> 0 then
    begin
      if not BlockOn then
        ToggleBlockOn;
    end {...if ShiftState and (kbRightShift + kbLeftShift) }
  else
    ClearCurrBlock;
end; {...TSpreadSheet.CheckForDragging }


procedure TSpreadSheet.ClearCurrBlock;
{ Turns off the block mode and redisplays the affected cells }
begin
  if BlockOn then
  begin
    BlockOn := False;
    DisplayBlock(CurrBlock^);
  end; {...if BlockOn }
  DisplayInfo;
end; {...TSpreadSheet.ClearCurrBlock }


procedure TSpreadSheet.ClearScreenArea(AreaToClear: PScreenArea);
{ Clears a given area of the screen }
var
  W, H : Byte;
  B : TDrawBuffer;
begin
  with AreaToClear^ do
  begin
    W := Succ(LowerRight.Col - UpperLeft.Col);
    H := Succ(LowerRight.Row - UpperLeft.Row);
    MoveChar(B, ' ', Attrib, W);
    WriteLine(UpperLeft.Col, UpperLeft.Row, W, H, B);
  end; {...with AreaToClear^ }
end; {...TSpreadSheet.ClearScreenArea }


function TSpreadSheet.ColHeadersHashStart: BucketRange;
{ Returns the initial number of buckets for the Column Names hash table }
begin
  ColHeadersHashStart := 10;
end; {...TSpreadSheet.ColHeadersHashStart }


function TSpreadSheet.ColumnToString(Column: Word): String;
{ Converts a column to a string }
var
  HasName : Boolean;
  S : String[4];
  Name : String;
  W : Word;
begin
  HasName := ColHeadersHash.Search(Column, Name);
  if DisplayHeaders and HasName then
    ColumnToString := Name
  else
    begin
      if Column > 18278 then                     { Column is 4 letters }
        S := Chr(Ord('A') + ((Column - 18279) div 17576))
      else
        S := '';
      if Column > 702 then                { Column is at least 3 letters }
        S := S + Chr(Ord('A') + (((Column - 703) mod 17576) div 676));
      if Column > 26 then                 { Column is at least 2 letters }
        S := S + Chr(Ord('A') + (((Column - 27) mod 676) div 26));
      S := S + Chr(Ord('A') + (Pred(Column) mod 26));
      ColumnToString := S;
   end; {...if/else }
end; {...TSpreadSheet.ColumnToString }


function TSpreadsheet.ColToX(Col : Integer): Byte;
{ Returns the screen position of a given column }
begin
  ColToX := ColStart^[Col - ScreenBlock^.Start.Col];
end; {...TSpreadSheet.ColToX }


function TSpreadSheet.ColWidth(Col: Integer): Byte;
{ Returns the width of a certain column }
var
  Width : Integer;
begin
  Width := WidthHash.Search(Col);
  if Width = 0 then
    ColWidth := DefaultColWidth
  else
    ColWidth := Width;
end; {...TSpreadSheet.ColWidth }


procedure TSpreadSheet.CopyCellBlock;
{ Activates the clipboard and sets it to indicate the block to be copied }
var
  Block : PBlock;
begin
  if BlockOn then
    begin
      New(Block, Init(CurrBlock^.Start));
      if Block = nil then
        Exit;
      Block^.Stop := CurrBlock^.Stop;
    end {...if BlockOn }
  else
    begin
      New(Block, Init(CurrPos));
      if Block = nil then
        Exit;
      Block^.Stop := CurrPos;
    end; {...if/else }
  ToggleClipBoardOn(@Self, Block, BlockOn, opCopy);
end; {...TSpreadSheet.CopyCellBlock }


procedure TSpreadSheet.DeleteBlock(Block: TBlock; var Deleted: Boolean);
{ Deletes a block of cells }
var
  H, D : HashItemPtr;
  CellPtr : PCell;
  Counter : Word;
begin
  Deleted := False;
  with CellHash, Block do
  begin
    for Counter := 1 to Buckets do
    begin
      H := HashData^[Counter];
      while H <> nil do
      begin
        D := H;
        H := H^.Next;
        Move(D^.Data, CellPtr, Sizeof(CellPtr));
        with CellPtr^ do
        begin
          if CellInBlock(Loc) then
            DeleteCell(Loc, Deleted);
        end; {...with CellPtr^ }
      end; {...while H <> nil }
    end; {...for Counter }
  end; {...with CellHash, Block }
end; {...TSpreadSheet.DeleteBlock }


procedure TSpreadSheet.DeleteCell(Pos: CellPos; var Deleted: Boolean);
{ Deletes a single cell }
var
  CellPtr : PCell;
begin
  CellHash.Delete(Pos, CellPtr);
  if CellPtr <> nil then
    begin
      OverWriteHash.Delete(Pos, CellHash, FormatHash, WidthHash, LastPos,
        MaxCols, GetColWidth, DisplayFormulas, ChangeYes);
      Dispose(CellPtr, Done);
      Deleted := True;
    end {...if CellPtr <> nil }
  else
    Deleted := False;
end; {...TSpreadSheet.DeleteCell}


procedure TSpreadSheet.DeleteColFromHash(Block: TBlock; Columns, EndDelCol:
  Word);
{ Deletes a column or block of columns from the hash tables }
var
  Pos, Start, Stop : CellPos;
  H : HashItemPtr;
  CellPtr : PCell;
  Col : Word;
  F : File;
  Deleted : Boolean;
const
  CopyFormulasLiteral = $03;
begin
  SetChanged(ModifiedYes);
  DeleteBlock(Block, Deleted);
  with CellHash do
  begin
    CellPtr := FirstItem;
    while CellPtr <> nil do
    begin
      with CellPtr^ do
      begin
        if CellPtr^.ShouldUpdate then
           FixFormulaCol(CellPtr, opDelete, EndDelCol, Columns, MaxCols,
             MaxRows);
      end; {...with CellPtr^ }
      CellPtr := NextItem;
    end; {...while CellPtr <> nil }
  end; {...with CellHash }

  for Col := Block.Start.Col to Block.Stop.Col do
    WidthHash.Delete(Col);
  with WidthHash do
  begin
    H := FirstItem;
    while H <> nil do
    begin
      if WordPTr(@H^.Data)^ > EndDelCol then
        Dec(WordPtr(@H^.Data)^, Columns);
      H := NextItem;
    end; {...with H <> nil }
  end; {...with WidthHash }

  Stop.Col := Block.Stop.Col;
  Stop.Row := MaxInt;
  FormatHash.Delete(Block.Start, Stop);
  with FormatHash do
  begin
    H := FirstItem;
    while H <> nil do
    begin
      Move(H^.Data, Start, SizeOf(Start));
      Move(H^.Data[SizeOf(CellPos)], Stop, SizeOf(Stop));
      if (Start.Col > (EndDelCol - Columns)) and (Stop.Col <= EndDelCol) then
        Delete(Start, Stop)
      else
        begin
          if Start.Col > EndDelCol then
          begin
            Dec(Start.Col, Columns);
            Move(Start, H^.Data, Sizeof(Start));
          end; {...if Start.Col > EndDelCol }
          if Stop.Col > EndDelCol then
          begin
            Dec(Stop.Col, Columns);
            Move(Stop, H^.Data[Sizeof(CellPos)], Sizeof(Stop));
          end; {...if Stop.Col > EndDelCol }
        end; {...if/else }
      H := NextItem;
    end; {...while H <> nil }
  end; {...with FormatHash }

  DeleteColHeaders(@Block);
  with ColHeadersHash do
  begin
    H := FirstItem;
    while H <> nil do
    begin
      if WordPTr(@H^.Data)^ > EndDelCol then
        Dec(WordPtr(@H^.Data)^, Columns);
      H := NextItem;
    end; {...with H <> nil }
  end; {...with ColHeadersHash }

  Stop.Col := Block.Stop.Col;
  Stop.Row := MaxInt;
  UnlockedHash.Delete(Block.Start, Stop);
  with UnlockedHash do
  begin
    H := FirstItem;
    while (H <> nil) do
    begin
      Move(H^.Data, Start, SizeOf(Start));
      Move(H^.Data[SizeOf(CellPos)], Stop, SizeOf(Stop));
      if (Start.Col > (EndDelCol - Columns)) and (Stop.Col <= EndDelCol) then
        Delete(Start, Stop)
      else
        begin
          if Start.Col > EndDelCol then
          begin
            Dec(Start.Col, Columns);
            Move(Start, H^.Data, Sizeof(Start));
          end; {...if Start.Col > EndDelCol }
          if Stop.Col > EndDelCol then
          begin
            Dec(Stop.Col, Columns);
            Move(Stop, H^.Data[Sizeof(CellPos)], Sizeof(Stop));
          end; {...if Stop.Col > EndDelCol }
        end; {...if/else }
      H := NextItem;
    end; {...while H <> nil }
  end; {...with UnlockedHash }

  StoreTablesToTempFile;
  DoneHashTables;
  Pos.Col := Succ(EndDelCol);
  Pos.Row := 0;
  LoadTablesFromTempFile(Pos, 0, -Columns);
  Assign(F, GLStringList^.Get(sTempFileName));
  Erase(F);
  if LastPos.Col > 1 then
    Dec(LastPos.Col, Columns);
  Pos.Col := EndDelCol - Columns;
  if Deleted then
    Pos.Row := LastPos.Row
  else
    Pos.Row := 1;
  FindLastPos(Pos);
  FixOverWrite;
end; {...TSpreadSheet.DeleteColFromHash }


procedure TSpreadSheet.DeleteColHeaders(Block: PBlock);
{ Deletes from the column headers hash table the headers of the selected
  columns }
var
  C : Word;
begin
  SetChanged(ModifiedYes);
  with Block^ do
  begin
    if Start.Col = Stop.Col then
      ColHeadersHash.Delete(Start.Col)
    else
      for C := Start.Col to Stop.Col do
        ColHeadersHash.Delete(C);
  end; {...with Block^ }
end; {...TSpreadSheet.DeleteColHeaders }


procedure TSpreadSheet.DeleteColumns;
{ Deletes a column or group of columns }
var
  Start, Stop : CellPos;
  H : HashItemPtr;
  CellPtr : PCell;
  Block : TBlock;
  Columns, EndDelCol : Word;
  S : TBufStream;
  Items: LongInt;
begin
  Block.Start.Col := 0;
  Block.Start.Row := 0;
  Block.Stop.Col := 0;
  Block.Stop.Row := 0;
  if BlockOn then
    begin
      if CurrBlock^.Start.Col <= LastPos.Col then
      begin
        with Block do
        begin
          Start.Col := CurrBlock^.Start.Col;
          Start.Row := 1;
          if CurrBlock^.Stop.Col > LastPos.Col then
            Stop.Col := LastPos.Col
          else
            Stop.Col := CurrBlock^.Stop.Col;
          Stop.Row := LastPos.Row;
        end; {...with Block }
      end; {...if CurrBlock^.Start.Col <= LastPos.Col }
      Columns := Succ(CurrBlock^.Stop.Col - CurrBlock^.Start.Col);
      EndDelCol := CurrBlock^.Stop.Col;
    end {...if BlockOn }
  else
    begin
      if CurrPos.Col <= LastPos.Col then
      begin
        with Block do
        begin
          Start.Col := CurrPos.Col;
          Start.Row := 1;
          Stop.Col := CurrPos.Col;
          Stop.Row := LastPos.Row;
        end; {...with Block }
      end; {...if CurrPos.Col <= LastPos.Col }
      Columns := 1;
      EndDelCol := CurrPos.Col;
    end; {...if/else }
  MessageDialog := PDialog(GLResFile^.Get('UpdatingTablesDialog'));
  if Application^.ValidView(MessageDialog) <> nil then
    Desktop^.Insert(MessageDialog)
  else
    begin
      MessageDialog := nil;
      Exit;
    end; { else }
  DeleteColFromHash(Block, Columns, EndDelCol);
  SetScreenColStart(ScreenBlock^.Start.Col);
  if AutoCalc then
    Recalc(DisplayNo);
  if MessageDialog <> nil then
  begin
    Desktop^.Delete(MessageDialog);
    Dispose(MessageDialog, Done);
    MessageDialog := nil;
  end; { if }
  DrawView;
end; {...TSpreadSheet.DeleteColumns }


procedure TSpreadSheet.DeleteRowFromHash(Block: TBlock; Rows, EndDelRow:
  Word);
{ Deletes a row or block of rows from the hash tables }
var
  Pos, Start, Stop : CellPos;
  H : HashItemPtr;
  CellPtr : PCell;
  Deleted : Boolean;
  F : File;
begin
  SetChanged(ModifiedYes);
  DeleteBlock(Block, Deleted);
  with CellHash do
  begin
    CellPtr := FirstItem;
    while CellPtr <> nil do
    begin
      with CellPtr^ do
      begin
        if CellPtr^.ShouldUpdate then
          FixFormulaRow(CellPtr, opDelete, EndDelRow, Rows, MaxCols, MaxRows);
      end; {...with CellPtr^ }
      CellPtr := NextItem;
    end; {...while CellPtr <> nil }
  end; {...with CellHash }

  Stop.Col := MaxInt;
  Stop.Row := Block.Stop.Row;
  FormatHash.Delete(Block.Start, Stop);
  with FormatHash do
  begin
    H := FirstItem;
    while H <> nil do
    begin
      Move(H^.Data, Start, SizeOf(Start));
      Move(H^.Data[SizeOf(CellPos)], Stop, SizeOf(Stop));
      if (Start.Row > (EndDelRow - Rows)) and (Stop.Row <= EndDelRow) then
        Delete(Start, Stop)
      else
        begin
          if Start.Row > EndDelRow then
          begin
            Dec(Start.Row, Rows);
            Move(Start, H^.Data, Sizeof(Start));
          end; {...if Start.Row > EndDelRow }
          if Stop.Row > EndDelRow then
          begin
            Dec(Stop.Row, Rows);
            Move(Stop, H^.Data[Sizeof(CellPos)], Sizeof(Stop));
          end; {...if Stop.Row > EndDelRow }
        end; {...if/else }
      H := NextItem;
    end; {...while H <> nil }
  end; {...with FormatHash }

  Stop.Col := MaxInt;
  Stop.Row := Block.Stop.Row;
  UnlockedHash.Delete(Block.Start, Stop);
  with UnlockedHash do
  begin
    H := FirstItem;
    while H <> nil do
    begin
      Move(H^.Data, Start, SizeOf(Start));
      Move(H^.Data[SizeOf(CellPos)], Stop, SizeOf(Stop));
      if (Start.Row > (EndDelRow - Rows)) and (Stop.Row <= EndDelRow) then
        Delete(Start, Stop)
      else
        begin
          if Start.Row > EndDelRow then
          begin
            Dec(Start.Row, Rows);
            Move(Start, H^.Data, Sizeof(Start));
          end; {...if Start.Row > EndDelRow }
          if Stop.Row > EndDelRow then
          begin
            Dec(Stop.Row, Rows);
            Move(Stop, H^.Data[Sizeof(CellPos)], Sizeof(Stop));
          end; {...if Stop.Row > EndDelRow }
        end; {...if/else }
      H := NextItem;
    end; {...while H <> nil }
  end; {...with UnlockedHash }

  StoreTablesToTempFile;
  DoneHashTables;
  Pos.Col := 0;
  Pos.Row := Succ(EndDelRow);
  LoadTablesFromTempFile(Pos, -Rows, 0);
  Assign(F, GLStringList^.Get(sTempFileName));
  Erase(F);
  if LastPos.Row > 1 then
    Dec(LastPos.Row, Rows);
  Pos.Row := EndDelRow - Rows;
  if Deleted then
    Pos.Col := LastPos.Col
  else
    Pos.Col := 1;
  FindLastPos(Pos);
  SetChanged(ModifiedYes);
  FixOverWrite;
end; {...TSpreadSheet.DeleteRowFromHash }


procedure TSpreadSheet.DeleteRows;
{ Deletes a row or a group of rows }
var
  Start, Stop : CellPos;
  H : HashItemPtr;
  CellPtr : PCell;
  Block : TBlock;
  EndDelRow, Rows : Word;
begin
  Block.Start.Col := 0;
  Block.Start.Row := 0;
  Block.Stop.Col := 0;
  Block.Stop.Row := 0;
  if BlockOn then
    begin
      if CurrBlock^.Start.Row <= LastPos.Row then
      begin
        with Block do
        begin
          Start.Col := 1;
          Start.Row := CurrBlock^.Start.Row;
          Stop.Col := LastPos.Col;
          if CurrBlock^.Stop.Row > LastPos.Row then
            Stop.Row := LastPos.Row
          else
            Stop.Row := CurrBlock^.Stop.Row;
        end; {...with Block }
      end; {...if CurrBlock^.Start.Row <= LastPos.Row }
      Rows := Succ(CurrBlock^.Stop.Row - CurrBlock^.Start.Row);
      EndDelRow := CurrBlock^.Stop.Row;
    end {...if BlockOn }
  else
    begin
      if CurrPos.Row <= LastPos.Row then
      begin
        with Block do
        begin
          Start.Col := 1;
          Start.Row := CurrPos.Row;
          Stop.Col := LastPos.Col;
          Stop.Row := CurrPos.Row;
        end; {...with Block }
      end; {if CurrPos.Row <= LastPos.Row }
      Rows := 1;
      EndDelRow := CurrPos.Row;
    end; {...if/else }
  MessageDialog := PDialog(GLResFile^.Get('UpdatingTablesDialog'));
  if Application^.ValidView(MessageDialog) <> nil then
    Desktop^.Insert(MessageDialog)
  else
    begin
      MessageDialog := nil;
      Exit;
    end; { else }
  DeleteRowFromHash(Block, Rows, EndDelRow);
  if AutoCalc then
    Recalc(DisplayNo);
  if MessageDialog <> nil then
  begin
    Desktop^.Delete(MessageDialog);
    Dispose(MessageDialog, Done);
    MessageDialog := nil;
  end; { if }
  DrawView;
end; {...TSpreadSheet.DeleteRows }


procedure TSpreadSheet.DisplayAllCells;
{ Displays all the cells in the current screen block }
begin
  ClearScreenArea(@DisplayArea);
  DisplayBlock(ScreenBlock^);
end; {...TSpreadSheet.DisplayAllCells }


procedure TSpreadSheet.DisplayBlock(B: TBlock);
{ Displays a block of cells }
begin
  with B do
    DisplayCellBlock(Start.Col, Start.Row, Succ(Stop.Col), Stop.Row);
end; {...TSpreadSheet.DisplayBlock }


procedure TSpreadsheet.DisplayBlockDiff(B1, B2 : TBlock);
{ Displays the cells present in one block, not present in the another block }
var
  Pass : Byte;
  B : TBlock;
  RefBlock, Block2, TempBlock : PBlock;
begin
  if Compare(B1, B2, SizeOf(TBlock)) then
    Exit;
  Pass := 0;
  RefBlock := @B1;
  Block2 := @B2;
  repeat
    Inc(Pass);
    if Block2^.Start.Col < RefBlock^.Start.Col then
    begin
      if Block2^.Start.Row < RefBlock^.Start.Row then
      begin
        B.Start := Block2^.Start;
        B.Stop.Col := Pred(RefBlock^.Start.Col);
        B.Stop.Row := Pred(RefBlock^.Start.Row);
        DisplayBlock(B);
      end; {...if Block2^.Start.Row < RefBlock^.Start.Row }
      if (Block2^.Start.Row >= RefBlock^.Start.Row) and
         (Block2^.Start.Row <= RefBlock^.Stop.Row) then
        begin
          B.Start.Col := Block2^.Start.Col;
          B.Start.Row := Block2^.Start.Row;
          B.Stop.Col := Pred(RefBlock^.Start.Col);
          B.Stop.Row := RefBlock^.Stop.Row;
          DisplayBlock(B);
        end {...if (Block2^.Start.Row >= RefBlock^.Start.Row) and ... }
      else if Block2^.Stop.Row <= RefBlock^.Stop.Row then
        begin
          B.Start.Col := Block2^.Start.Col;
          B.Start.Row := RefBlock^.Start.Row;
          B.Stop.Col := Pred(RefBlock^.Start.Col);
          B.Stop.Row := Min(RefBlock^.Stop.Row, Block2^.Stop.Row);
          DisplayBlock(B);
        end; {...else if Block2^.Stop.Row <= RefBlock^.Stop.Row }
      if Block2^.Stop.Row > RefBlock^.Stop.Row then
      begin
        B.Start.Col := Block2^.Start.Col;
        B.Start.Row := Succ(RefBlock^.Stop.Row);
        B.Stop.Col := Pred(RefBlock^.Start.Col);
        B.Stop.Row := Block2^.Stop.Row;
        DisplayBlock(B);
      end; {...if Block2^.Stop.Row > RefBlock^.Stop.Row }
    end; {...if Block2^.Start.Col < RefBlock^.Start.Col }

    if Block2^.Start.Row < RefBlock^.Start.Row then
    begin
      if (Block2^.Start.Col >= RefBlock^.Start.Col) and
         (Block2^.Start.Col <= RefBlock^.Stop.Col) then
        begin
          B.Start.Col := Block2^.Start.Col;
          B.Start.Row := Block2^.Start.Row;
          B.Stop.Col := RefBlock^.Stop.Col;
          B.Stop.Row := Pred(RefBlock^.Start.Row);
          DisplayBlock(B);
        end {...if (Block2^.Start.Col >= RefBlock^.Start.Col) and ... }
      else if Block2^.Stop.Col <= RefBlock^.Stop.Col then
        begin
          B.Start.Col := RefBlock^.Start.Col;
          B.Start.Row := Block2^.Start.Row;
          B.Stop.Col := Min(RefBlock^.Stop.Col, Block2^.Stop.Col);
          B.Stop.Row := Pred(RefBlock^.Start.Row);
          DisplayBlock(B);
        end; {...else if Block2^.Stop.Col <= RefBlock^.Stop.Col }
    end; {...if Block2^.Start.Row < RefBlock^.Start.Row }

    if Block2^.Stop.Row > RefBlock^.Stop.Row then
    begin
      if (Block2^.Start.Col >= RefBlock^.Start.Col) and
         (Block2^.Start.Col <= RefBlock^.Stop.Col) then
        begin
          B.Start.Col := Block2^.Start.Col;
          B.Start.Row := Succ(RefBlock^.Stop.Row);
          B.Stop.Col := RefBlock^.Stop.Col;
          B.Stop.Row := Block2^.Stop.Row;
          DisplayBlock(B);
        end {...if (Block2^.Start.Col >= RefBlock^.Start.Col) and ... }
      else if Block2^.Stop.Col <= RefBlock^.Stop.Col then
        begin
          B.Start.Col := RefBlock^.Start.Col;
          B.Start.Row := Succ(RefBlock^.Stop.Row);
          B.Stop.Col := Min(RefBlock^.Stop.Row, Block2^.Stop.Row);
          B.Stop.Row := Block2^.Stop.Row;
          DisplayBlock(B);
        end; {...else if Block2^.Stop.Col <= RefBlock^.Stop.Col }
    end; {...if Block2^.Stop.Row > RefBlock^.Stop.Row }

    if Block2^.Stop.Col > RefBlock^.Stop.Col then
    begin
      if Block2^.Start.Row < RefBlock^.Start.Row then
      begin
        B.Start.Col := Succ(RefBlock^.Stop.Col);
        B.Start.Row := Block2^.Start.Row;
        B.Stop.Col := Block2^.Stop.Col;
        B.Stop.Row := Pred(RefBlock^.Start.Row);
        DisplayBlock(B);
      end; {...if Block2^.Start.Row < RefBlock^.Start.Row }
      if (Block2^.Start.Row >= RefBlock^.Start.Row) and
         (Block2^.Start.Row <= RefBlock^.Stop.Row) then
        begin
          B.Start.Col := Succ(RefBlock^.Stop.Col);
          B.Start.Row := Block2^.Start.Row;
          B.Stop.Col := Block2^.Stop.Col;
          B.Stop.Row := RefBlock^.Stop.Row;
          DisplayBlock(B);
        end {...if (Block2^.Start.Row >= RefBlock^.Start.Row) and ... }
      else if Block2^.Stop.Row <= RefBlock^.Stop.Row then
        begin
          B.Start.Col := Succ(RefBlock^.Stop.Col);
          B.Start.Row := RefBlock^.Start.Row;
          B.Stop.Col := Block2^.Stop.Col;
          B.Stop.Row := Min(RefBlock^.Stop.Row, Block2^.Stop.Row);
          DisplayBlock(B);
        end; {...else if Block2^.Stop.Row <= RefBlock^.Stop.Row }
      if Block2^.Stop.Row > RefBlock^.Stop.Row then
      begin
        B.Start.Col := Succ(RefBlock^.Stop.Col);
        B.Start.Row := Succ(RefBlock^.Stop.Row);
        B.Stop := Block2^.Stop;
        DisplayBlock(B);
      end; {...if Block2^.Stop.Row > RefBlock^.Stop.Row }
    end; {...if Block2^.Stop.Col > RefBlock^.Stop.Col }

    TempBlock := RefBlock;
    RefBlock := Block2;
    Block2 := TempBlock;
  until (Pass = 2);
end; {...TSpreadSheet.DisplayBlockDiff }


procedure TSpreadsheet.DisplayCell(P : CellPos);
{ Displays a single cell }
var
  Color : Byte;
  S     : String[ScreenCols];
  B     : TDrawBuffer;
  Col   : Byte;
begin
  S := CellToFString(P, Color);
  MoveStr(B, S, Color);
  Col := ColToX(P.Col);
  WriteLine(Col, RowToY(P.Row), Min(Length(S), (Size.X - Col)), 1, B);
end; {...TSpreadSheet.DisplayCell }


procedure TSpreadSheet.DisplayCellBlock(C1, R1, C2, R2: Word);
{ Displays a block of cells }
var
  P : CellPos;
begin
  with ScreenBlock^ do
  begin
    for P.Row := Max(R1, Start.Row) to Min(R2, Stop.Row) do
      for P.Col := Max(C1, Start.Col) to Min(C2, Succ(Stop.Col)) do
         DisplayCell(P);
  end; {...with ScreenBlock^ }
end; {...TSpreadSheet.DisplayCellBlock }


procedure TSpreadSheet.DisplayCellData;
var
  InfoStringLength, W  : Byte;
  CP : PCell;
  CurrWidth, LockedState, S  : String;
  B  : TDrawBuffer;
  Pos : CellPos;
const
  BlockInfoSize = 30;
  CellInfoSize = 28;
begin
  if (State and sfActive <> 0) then
    Pos := CurrPos
  else
    Pos := OldCurrPos;
  CP := CellHash.Search(Pos);
  ClearScreenArea(@DataArea);
  Str(ColWidth(Pos.Col), CurrWidth);
  LockedState := '';
  if UnlockedHash.Search(Pos) then
    LockedState := GLStringList^.Get(sCellUnLockedInfo)
  else
    if SheetProtected then
      LockedState := GLStringList^.Get(sCellLockedInfo);
  with DataArea do
  begin
    S := LeftJustStr(ColToString(Pos.Col) + RowToString(Pos.Row) +
      ' [' + GLStringList^.Get(sWidthLetter) + CurrWidth + '] ' + CP^.Name +
      ' ' + LockedState, CellInfoSize);
    InfoStringLength := CellInfoSize;
    if BlockOn then
    begin
      with CurrBlock^ do
      begin
        S := S + LeftJustStr(GLStringList^.Get(sBlockName) +
          ColToString(Start.Col) + RowToString(Start.Row) + '..' +
          ColToString(Stop.Col) + RowToString(Stop.Row), BlockInfoSize);
        InfoStringLength := InfoStringLength + BlockInfoSize
      end; {...with CurrBlock^ }
    end; {...if BlockOn }
    MoveStr(B, S, GetColor(8));
    WriteLine(UpperLeft.Col, UpperLeft.Row, InfoStringLength, 1, B);
  end; {...with DataArea }
  with ContentsArea do
  begin
    S := LeftJustStr(CP^.DisplayString(DisplayFormulas, MaxDecimalPlaces),
      Succ(LowerRight.Col-UpperLeft.Col));
    MoveStr(B, S, GetColor(9));
    WriteLine(UpperLeft.Col, UpperLeft.Row, Length(S), 1, B);
  end; {...with ContenstArea }
end; {...TSpreadSheet.DisplayCellData }


procedure TSpreadSheet.DisplayCols;
{ Displays the column headers }
var
  W, X : Byte;
  C : Integer;
  B : TDrawBuffer;
begin
  with ScreenBlock^ do
  begin
    if not NoBlankArea then
    begin
      X := ColStart^[Stop.Col - Start.Col]+ColWidth(Stop.Col);
      W := Max(Size.X - X, Size.X);
      MoveChar(B, ' ', ColArea.Attrib, W);
      WriteLine(X, ColArea.UpperLeft.Row, W, 1, B);
    end; {...if not NoBlankArea }
    for C := Start.Col to Min(Succ(Stop.Col), MaxCols) do
    begin
      W := ColWidth(C);
      MoveStr(B, CenterStr(ColumnToString(C), W), ColArea.Attrib);
      WriteLine (ColStart^[C - Start.Col], ColArea.UpperLeft.Row, W, 1, B);
    end; {...for C }
  end; {...with ScreenBlock^ }
end; {...TSpreadSheet.DisplayCols }


procedure TSpreadSheet.DisplayInfo;
{ Displays the spreadsheet's info characters }
var
  Width     : Byte;
  Info      : String;
  B         : TDrawBuffer;
begin
  ClearScreenArea(@InfoArea);
  with InfoArea do
  begin
    Width := Succ(LowerRight.Col - UpperLeft.Col);
    Info := ColToString(GetNumber);
    if Modified then
      Info := Copy(Info, 1, 1) + '*';{Chr(4);}
    if Length(Info) = 1 then
      Info := Info + ' ';
    if GoToEnd then
      Info := Info + GLStringList^.Get(sEndKeyPressedLetter)
    else
      Info := Info + ' ';
    if DisplayHeaders then
      Info := Info + GLStringList^.Get(sDisplayHeadersLetter)
    else
      Info := Info + ' ';
    if AutoCalc then
      Info := Info + GLStringList^.Get(sAutoCalcLetter)
    else
      Info := Info + ' ';
    if DisplayFormulas then
      Info := Info + GLStringList^.Get(sDisplayFormulasLetter)
    else
      Info := Info + ' ';
    MoveStr(B, Info, Attrib);
    Writeline (UpperLeft.Col, UpperLeft.Row, Min(Width, Length(Info)), 1, B);
  end; {...with InfoArea }
end; {...TSpreadSheet.DisplayInfo }


procedure TSpreadSheet.DisplayRows;
{ Displays row numbers }
var
  R : Integer;
  B : TDrawBuffer;
begin
  with ScreenBlock^ do
  begin
    for R := Start.Row to Stop.Row do
      with RowArea do
      begin
        MoveStr(B, LeftJustStr(RowToString(R), RowNumberSpace),
          RowArea.Attrib);
        WriteLine(UpperLeft.Col, R - Start.Row + UpperLeft.Row,
          RowNumberSpace, 1, B);
      end; {...with RowArea }
  end; {...with ScreenBlock^ }
end; {...TSpreadSheet.DisplayRows }


{****************************************************************************}
{ TSpreadSheet.DoAfterAddingCell                                             }
{****************************************************************************}
procedure TSpreadSheet.DoAfterAddingCell;
{ This procedure is called after a cell is added or modified }
begin
  MoveDown;
end;

{****************************************************************************}
{ TSpreadsheet.DoBeforeAddingCell                                            }
{****************************************************************************}
function TSpreadsheet.DoBeforeAddingCell;
begin
  DoBeforeAddingCell := True;
end;

{****************************************************************************}
{ TSpreadSheet.DragCursorWithMouse                                           }
{****************************************************************************}
procedure TSpreadSheet.DragCursorWithMouse(Event: TEvent);
{ Sets block mode on and extends the block to wherever the mouse is pointing }
var
   ColScrPos : Byte;
   OldPos : CellPos;
   Counter : Integer;
   Mouse : TPoint;
begin
  MakeLocal(Event.Where, Mouse);
  with ScreenBlock^ do
  begin
    KeyPressed := True;
    if not BlockOn then ToggleBlockOn;
    OldPos := CurrPos;
    if Mouse.Y < DisplayArea.UpperLeft.Row then
      begin
        CurrPos.Row := Max(1, Pred(Start.Row));
        SetScreenRowStart(CurrPos.Row);
        VScrollBar^.SetValue(ScreenBlock^.Start.Row);
      end {...if Mouse.Y < DisplayArea.UpperLeft.Row }
    else if Mouse.Y > DisplayArea.LowerRight.Row then
      begin
        CurrPos.Row := Min(MaxRows, Succ(Stop.Row));
        SetScreenRowStop(CurrPos.Row);
        VScrollBar^.SetValue(ScreenBlock^.Start.Row);
      end {...if Mouse.Y > DisplayArea.LowerRight.Row }
    else
      CurrPos.Row := YToRow(Mouse.Y);
    if (Mouse.X >= Size.X) then
      begin
        CurrPos.Col := Min(MaxCols, Succ(Stop.Col));
        SetScreenColStop(CurrPos.Col);
        HScrollBar^.SetValue(ScreenBlock^.Start.Col);
      end {...if (Mouse.X >= Size.X) or... }
    else if Mouse.X < RowNumberSpace then
      begin
        CurrPos.Col := Max(1, Pred(Start.Col));
        SetScreenColStart(CurrPos.Col);
        HScrollBar^.SetValue(ScreenBlock^.Start.Col);
      end {...else if Mouse.X < RowNumberSpace }
    else
      CurrPos.Col := XToCol(Mouse.X);
    MoveCell(OldPos);
    KeyPressed := False;
  end; {...with ScreenBlock^ }
end; {...TSpreadSheet.DragCursorWithMouse }


procedure TSpreadSheet.Draw;
{ Sets the spreadsheet areas and displays all the spreadsheet's components }
var
  R : TRect;
begin
  GetExtent(R);
  Inc(R.A.Y, EmptyRowsAtTop);
  Dec(R.B.Y, EmptyRowsAtBottom);
  SetAreas(R);
  DisplayCols;
  DisplayRows;
  DisplayInfo;
  DisplayAllCells;
  DisplayCellData;
end; {...TSpreadSheet.Draw }


procedure TSpreadSheet.EraseCellBlock(EraseBlock: Boolean);
{ Deletes a cell or block of cells }
var
  Deleted: Boolean;
  Pos : CellPos;
begin
  Deleted := False;
  if not BlockOn or not EraseBlock then
    begin
      if not SheetProtected or (SheetProtected and
         UnlockedHash.Search(CurrPos)) then
        begin
          DeleteCell(CurrPos, Deleted);
          Pos := CurrPos;
        end {...if not SheetProtected or ... }
      else
        MessageBox(GLStringList^.Get(sCellsProtectedMsg), nil, mfInformation +
          mfOKButton);
    end {...if not BlockOn or not EraseBlock }
  else
    begin
      if not CellsProtected(CurrBlock^) then
        begin
          DisplayMessage(GLStringList^.Get(sBlockDeleteMsg));
          DeleteBlock(CurrBlock^, Deleted);
          EraseMessage;
          Pos := CurrBlock^.Stop;
          if Deleted then
            ClearCurrBlock;
        end {...if not CellsProtected(CurrBlock^) }
      else
        MessageBox(GLStringList^.Get(sCellsProtectedMsg), nil, mfInformation +
          mfOKButton);
    end; {...if/else }
  if Deleted then
  begin
    Desktop^.Lock;
    FindLastPos(Pos);
    SetChanged(ModifiedYes);
    if AutoCalc then
      Recalc(DisplayYes);
    DisplayAllCells;
    DisplayCellData;
    Desktop^.Unlock;
  end; {...if Deleted }
end; {...TSpreadSheet.EraseCellBlock }


procedure TSpreadSheet.ExtendCurrBlock(Redraw : Boolean);
{ Resizes the current block if active }
var
  OldBlock : TBlock;
begin
  if BlockOn then
  begin
    Move(CurrBlock^, OldBlock, SizeOf(CurrBlock^));
    if CurrBlock^.ExtendTo(CurrPos) then
      begin
        if Redraw then
          DisplayBlockDiff(OldBlock, CurrBlock^);
      end {...if CurrBlock^.ExtendTo(CurrPos) }
    else
      ClearCurrBlock;
  end; {...if BlockOn }
end; {...TSpreadSheet.ExtendCurrBlock }


procedure TSpreadsheet.FindLastPos(DPos : CellPos);
{ Finds the lower left corner of smallest block containing used cells }
var
  ColFound, RowFound : Boolean;
  CellPtr : PCell;
  Counter : Word;
begin
  with CellHash do
  begin
    ColFound := DPos.Col < LastPos.Col;
    RowFound := DPos.Row < LastPos.Row;
    if (not ColFound) or (not RowFound) then
    begin
      if not ColFound then
        LastPos.Col := 1;
      if not RowFound then
        LastPos.Row := 1;
      CellPtr := FirstItem;
      while CellPtr <> nil do
      begin
        if not ColFound then
        begin
          if CellPtr^.Loc.Col > LastPos.Col then
          begin
            LastPos.Col := CellPtr^.Loc.Col;
            if HScrollBar <> nil then
              PLimScrollBar(HScrollBar)^.DisplayLimit :=
                Max(DefaultHScrollBarLimit, LastPos.Col);
            ColFound := LastPos.Col = DPos.Col;
            if ColFound and RowFound then
              Exit;
          end; {...if CellPtr^.Loc.Col > LastPos.Col }
        end; {...if not ColFound }
        if not RowFound then
        begin
          if CellPtr^.Loc.Row > LastPos.Row then
          begin
            LastPos.Row := CellPtr^.Loc.Row;
            if VScrollBar <> nil then
              PLimScrollBar(VScrollBar)^.DisplayLimit :=
                Max(DefaultVScrollBarLimit, LastPos.Row);
            RowFound := LastPos.Row = DPos.Row;
            if ColFound and RowFound then
              Exit;
          end; {...if CellPtr^.Loc.Row > LastPos.Row }
        end; {...if not RowFound }
        CellPtr := NextItem;
      end; {...while CellPtr <> nil }
    end; {...if (not ColFound) or (not RowFound) }
  end; {...with CellHash }
end; {...TSpreadSheet.FindLastPos }



procedure TSpreadSheet.FindScreenColStart;
{ Find the starting screen column when the ending column is known}
var
  Temp, Width : Byte;
  Index, Place : Integer;
begin
  with ScreenBlock^ do
  begin
    Index := 0;
    Place := Succ(DisplayArea.LowerRight.Col);
    Width := ColWidth(Stop.Col);
    repeat
      ColStart^[Index] := Max(DisplayArea.UpperLeft.Col, Place - Width);
      Dec(Place, Width);
      Inc(Index);
      if (Stop.Col - Index = 0) then
        Width := 0
      else
        Width := ColWidth(Stop.Col - Index);
    until (Width = 0) or (Place - Width < DisplayArea.UpperLeft.Col);
    Start.Col := Succ(Stop.Col - Index);
    Dec(Index);
    if ColStart^[Index] > DisplayArea.UpperLeft.Col then
    begin
      Temp := ColStart^[Index] - DisplayArea.UpperLeft.Col;
      for Place := 0 to Index do
        Dec(ColStart^[Place], Temp);
    end; {...if ColStart^[Index] > DisplayArea.UpperLeft.Col }
    if Index > 0 then
    begin
      for Place := 0 to (Pred(Index) shr 1) do
        begin
          Temp := ColStart^[Index - Place];
          ColStart^[Index - Place] := ColStart^[Place];
          ColStart^[Place] := Temp;
        end; {...for Place }
    end; {...if Index > 0 }
    ColStart^[Succ(Index)] := ColStart^[Index] + ColWidth(Stop.Col);
  end; {...with ScreenBlock^ }
end; {...TSpreadSheet.FindScreenColStart }



procedure TSpreadSheet.FindScreenColStop;
{ Finds then ending screen column when the starting column is known }
var
  Index, Place, Width : Byte;
begin
  with ScreenBlock^ do
  begin
    for Index := 1 to 10 do
      ColStart^[Index] := 0;
    Index := 0;
    Place := DisplayArea.UpperLeft.Col;
    Width := ColWidth(Start.Col);
    repeat
      ColStart^[Index] := Place;
      Inc(Place, Width);
      Inc(Index);
      if (Integer(Index) + Start.Col > MaxCols) then
        Width := 0
      else
        Width := ColWidth(Index + Start.Col);
    until (Width = 0) or
    (Place + Width > Succ(DisplayArea.LowerRight.Col));
    ColStart^[Index] := Place;
    Stop.Col := Pred(Start.Col + Index);
  end; {...with ScreenBlock^ }
end; {...TSpreadSheet.FindScreenColStop }


procedure TSpreadSheet.FindScreenRowStart;
{ Finds the starting screen row when the ending row is know }
begin
  with ScreenBlock^ do
  begin
    if LongInt(Stop.Row) - TotalRows < 0 then
      begin
        Start.Row := 1;
        FindScreenRowStop;
      end {if LongInt(Stop.Row) - TotalRows < 0 }
    else
      Start.Row := Succ(Stop.Row - TotalRows);
  end; {...with ScreenBlock^ }
end; {...TSpreadSheet.FindScreenRowStart }


procedure TSpreadSheet.FindScreenRowStop;
{ Finds the ending screen row when the starting row is know }
begin
  with ScreenBlock^ do
  begin
    if LongInt(Start.Row) + TotalRows > Succ(LongInt(MaxRows)) then
      begin
        Stop.Row := MaxRows;
        FindScreenRowStart;
      end {if (LongInt(Start.Row) + TotalRows) > Succ(MaxRows) }
    else
      Stop.Row := Pred(Start.Row + TotalRows);
  end; {...with ScreenBlock^ }
end; {...TSpreadSheet.FindScreenRowStop }


procedure TSpreadSheet.FixBlockOverWrite(Block: TBlock);
{ Updates the overwrite information of a block of cells
  IMPORTANT: No memory checking is done since it is assumed that no
             cells were added to the block being updated }
var
  CP, D : PCell;
begin
  with CellHash do
  begin
    CP := FirstItem;
    while CP <> nil do
    begin
      if Block.CellInBlock(CP^.Loc) then
      begin
        OverWriteHash.Delete(CP^.Loc, CellHash, FormatHash, WidthHash,
          LastPos, MaxCols, GetColWidth, DisplayFormulas, ChangeNo);
        OverwriteHash.Add(CP, CellHash, FormatHash, WidthHash, LastPos,
          MaxCols, GetColWidth, DisplayFormulas, ChangeNo);
      end; {...if Block.CellInBlock(CP^.Loc) }
      CP := NextItem;
    end; {...while CP <> nil}
  end; {...with CellHash }
end; {...TSpreadSheet.FixBlockOverWrite }


function TSpreadsheet.FixOverWrite: Boolean;
{ Updates the overwrite information for each cell in the spreadsheet }
var
  CP, D : PCell;
begin
  FixOverWrite := False;
  with CellHash do
  begin
    CP := FirstItem;
    while CP <> nil do
    begin
      if not OverwriteHash.Add(CP, CellHash, FormatHash, WidthHash, LastPos,
         MaxCols, GetColWidth, DisplayFormulas, ChangeYes) then
      begin
        CellHash.Delete(CP^.Loc, D);
        Dispose(D, Done);
        Exit;
      end; {...if not OverwriteHash.Add }
      CP := NextItem;
    end; {...while CP <> nil }
  end; {...with CellHash }
  FixOverWrite := True;
end; {...TSpreadSheet.FixOverWrite }


procedure TSpreadSheet.FormatDefault;
{ Clears the custom assigned formats of a block of cells }
var
  Block : TBlock;
begin
  with Block do
  begin
    if BlockOn then
      begin
        Start := CurrBlock^.Start;
        Stop := CurrBlock^.Stop;
      end {...if BlockOn }
    else
      begin
        Start := CurrPos;
        Stop := CurrPos;
      end; {...if/else }
  end; {...with Block }
  if not FormatHash.Delete(Block.Start, Block.Stop) then
    Exit;
  SetChanged(ModifiedYes);
  FixBlockOverWrite(Block);
  Block.Stop.Col := ScreenBlock^.Stop.Col;
  DisplayBlock(Block);
end; {...TSpreadSheet.FormatDefault }


function TSpreadSheet.FStringSituationColor(P: CellPos; var CP: PCell;
                      var HasError, ColorFound: Boolean): Byte;
{ Returns situation especific colors of the string to be displayed in the
  screen (for example: highlighted cell color, cell in block color, etc). }

  function DisplayErrorColor: Boolean;
  { This function determines if the cell must be displayed in error color.
    When the cell is a formula cell and DisplayFormulas mode is on, even
    though HasError may return true, the cell should not be displayed
    in error color }
  begin
    DisplayErrorColor := HasError and not (DisplayFormulas
                         and (CP^.CellType = ClFormula));
  end; {...DisplayErrorColor }

begin
  ColorFound := True;
  CP := CellHash.Search(P);
  HasError := CP^.HasError;
  if not SheetProtected or (SheetProtected and not UnlockedHash.Search(P)) then
    begin
      if BlockOn and (SameCellPos(P, CurrPos)) then
        begin
          if not DisplayErrorColor then
            FStringSituationColor := GetColor(13)
          else
            FStringSituationColor := GetColor(21);
        end {...if BlockOn and (SameCellPos(P, CurrPos)) }
      else if SameCellPos(P, CurrPos) then
        begin
          if not DisplayErrorColor then
            FStringSituationColor := GetColor(12)
          else
            FStringSituationColor := GetColor(20);
        end {...else if SameCellPos(P, CurrPos) }
      else if BlockOn and (CurrBlock^.CellInBlock(P)) then
        begin
          if not DisplayErrorColor then
            FStringSituationColor := GetColor(11)
          else
            FStringSituationColor := GetColor(19);
        end {...else if BlockOn and (CurrBlock^.CellInBlock(P)) }
      else
        if not DisplayErrorColor then
          ColorFound := False
        else
          FStringSituationColor := GetColor(18);
    end {...if not SheetProtected or ... }
  else
    begin
      if BlockOn and (SameCellPos(P, CurrPos)) then
        begin
          if not DisplayErrorColor then
            FStringSituationColor := GetColor(17)
          else
            FStringSituationColor := GetColor(25);
        end {...if BlockOn and (SameCellPos(P, CurrPos)) }
      else if SameCellPos(P, CurrPos) then
        begin
          if not DisplayErrorColor then
            FStringSituationColor := GetColor(16)
          else
            FStringSituationColor := GetColor(24);
        end {...else if SameCellPos(P, CurrPos) }
      else if BlockOn and (CurrBlock^.CellInBlock(P)) then
        begin
          if not DisplayErrorColor then
            FStringSituationColor := GetColor(15)
          else
            FStringSituationColor := GetColor(23);
        end {...else if BlockOn and (CurrBlock^.CellInBlock(P)) }
      else
         if not DisplayErrorColor then
           FStringSituationColor := GetColor(14)
         else
           FStringSituationColor := GetColor(22);
    end; {...if/else }
end; {...TSpreadSheet.FStringSituationColor }


procedure TSpreadSheet.FormatCells;
var
  Cancel, ValidFormat : Boolean;
  NewDecimalPlaces : Byte;
  Start, Stop : CellPos;
  NewCurrency: Char;
  F : FormatType;
  Code : Integer;
  Dialog : PDialog;
  ErrorString : String;
  Block: TBlock;
const
  CurrencyBit = $01;
  CommasBit = $02;

    procedure SetDialogFormatRec;
    { Determines the initial values for the format dialog's fields }
    var
      CellPtr : PCell;
    begin
      CellPtr := CellHash.Search(CurrPos);
      if CellPtr <> Empty then
        begin
          F := CellPtr^.Format(FormatHash, DisplayFormulas);
          with RFormat do
          begin
            NumberFormat := 0;
            Justification := (F shr JustShift) and JustPart;
            if (F and CurrencyPart) <> 0 then
              NumberFormat := NumberFormat or CurrencyBit;
            if (F and CommasPart) <> 0 then
              NumberFormat := NumberFormat or CommasBit;
            if ((F and DecPlacesPart) = 0) and
               not ((CellPtr^.CellType = ClValue) or ((CellPtr^.CellType =
               ClFormula)) and DisplayFormulas = True) then
              Str(DefaultDecimalPlaces, DecimalPlaces)
            else
              Str(F and DecPlacesPart, DecimalPlaces);
            if (F and CurrencyCharPart) <> 0 then
              CurrencyChar := Char((F and CurrencyCharPart) shr CurrencyShift)
            else
              CurrencyChar := Copy(DefaultCurrency, 2, 1);
          end; {...with RFormat }
        end {...if CellPtr <> Empty }
      else
        begin
          with RFormat do
          begin
            Justification := Ord(JLeft);
            NumberFormat := 0;
            Str(DefaultDecimalPlaces, DecimalPlaces);
            CurrencyChar := Copy(DefaultCurrency, 2, 1);
          end; {...with RFormat }
        end; {...if/else }
    end; {...SetDialogFormatRec }

    procedure GetValidFormat(Dialog: PDialog; var ValidFormat, Cancel: Boolean);
    { Returns ValidFormat as true is a valid format was entered }
    var
      SelectedCommand : Word;
    begin
      SelectedCommand := Desktop^.ExecView(Dialog);
      if SelectedCommand <> cmCancel then
        begin
          Dialog^.GetData(RFormat);
          val(RFormat.DecimalPlaces, NewDecimalPlaces, Code);
          if (NewDecimalPlaces > MaxDecimalPlaces) then
            ErrorString := ErrorString + GLStringList^.Get(sFormatError1Msg)
          else
            ValidFormat := True;
          if ((RFormat.NumberFormat and CurrencyBit) <> 0) then
          begin
            if not ((RFormat.CurrencyChar <> '') and
               (RFormat.CurrencyChar <> ' ')) then
            begin
              ErrorString := ErrorString +
                GLStringList^.Get(sFormatError2Msg);
              ValidFormat := False;
            end; {...if not ((RFormat.CurrencyChar<>'') and... }
          end; {...if (RFormat.NumberFormat and CurrencyBit) <> 0) }
        end {...if SelectedCommand <> cmCancel }
      else
        begin
          Cancel := True;
          ValidFormat := True;
        end; {...if/else }
    end; {...GetValidFormat }

begin
  Cancel := False;
  ValidFormat := False;
  if BlockOn then
    begin
      Block.Start := CurrBlock^.Start;
      Block.Stop := CurrBlock^.Stop;
    end {...if BlockOn }
  else
    Block.Init(CurrPos);
  Dialog := PDialog(GLResFile^.Get('FormatDialog'));
  SetDialogFormatRec;
  Dialog^.SetData(RFormat);
  repeat
    ErrorString := GLStringList^.Get(sFormatErrorMsg);
    if (Application^.ValidView(Dialog) <> nil) then
      GetValidFormat(Dialog, ValidFormat, Cancel)
    else
      Exit;
    if not ValidFormat then
      MessageBox(ErrorString, nil, mfError+mfOkButton);
  until Cancel or ValidFormat;
  if not Cancel then
  begin
    Dialog^.GetData(RFormat);
    with RFormat do
    begin
      NewCurrency := CurrencyChar[1];
      SetFormat(Block, NewDecimalPlaces, Justification, NumberFormat, NewCurrency);
    end; { with }
    SetChanged(ModifiedYes);
    Block.Stop := ScreenBlock^.Stop;
    DisplayBlock(Block);
  end; {...else if not Cancel }
  Dispose(Dialog, Done);
end; {...TSpreadSheet.FormatCells }


{****************************************************************************}
{ TSpreadSheet.GetNumber                                                     }
{****************************************************************************}
function TSpreadSheet.GetNumber: Integer;
begin
  GetNumber := PWindow(Owner)^.Number;
end;

{****************************************************************************}
{ TSpreadSheet.GetPalette                                                    }
{****************************************************************************}
function TSpreadSheet.GetPalette: PPalette;
const
  CPalette : string[Length(CSpreadSheet)] = CSpreadSheet;
begin
  GetPalette := @CPalette;
end;

{****************************************************************************}
{ TSpreadSheet.GoToCell                                                      }
{****************************************************************************}
procedure TSpreadSheet.GoToCell;
{ Moves the highlight cursor to a user defined cell }
var
  Cancel, CellEntered : Boolean;
  OldPos, Pos : CellPos;
  Dialog : PDialog;
  FormLen : Word;
begin
  Cancel := False;
  CellEntered := False;
  Dialog := PDialog(GLResFile^.Get('GoToDialog'));
  repeat
    if (Application^.ValidView(Dialog) <> nil) then
      begin
        if Desktop^.ExecView(Dialog) <> cmCancel then
          begin
            Dialog^.GetData(RGoToCell);
            if not FormulaStart(RGoToCell.NewCell, 1, MaxCols, MaxRows, Pos,
               FormLen) then
              MessageBox(GLStringList^.Get(sInvalidCellMsg), nil, mfError +
                mfOKButton)
            else
              CellEntered := True;
          end {...if Desktop^.ExecView(Dialog) <> cmCancel }
        else
          Cancel := True;
      end {...if Application^.ValidView(Dialog) <> nil }
    else
      Exit;
  until CellEntered or Cancel;
  if not Cancel then
    GoToPos(Pos);
  Dispose(Dialog, Done);
end;

{****************************************************************************}
{ TSpreadSheet.GoToPos                                                       }
{****************************************************************************}
procedure TSpreadSheet.GoToPos(Pos: CellPos);
var
  OldPos : CellPos;
begin
  if not ScreenBlock^.CellInBlock(Pos) then
    begin
      CurrPos := Pos;
      ExtendCurrBlock(RedrawYes);
      SetScreenColStart(CurrPos.Col);
      SetScreenRowStart(CurrPos.Row);
      HScrollBar^.Value := ScreenBlock^.Start.Col;
      VScrollBar^.Value := ScreenBlock^.Start.Row;
      HScrollBar^.DrawView;
      VScrollBar^.DrawView;
      DrawView;
    end { if }
  else
    begin
      OldPos := CurrPos;
      CurrPos := Pos;
      MoveCell(OldPos);
    end; { else }
end;

{****************************************************************************}
{ TSpreadSheet.HandleEvent                                                   }
{****************************************************************************}
procedure TSpreadSheet.HandleEvent(var Event: TEvent);
{ Handles all spreadsheet related events }

  procedure CheckforClipBoardClose;
  { if the spreadsheet being closed is @self, it resets the clipboard }
  begin
    if ClipBoard.Active and (ClipBoard.SourceSpreadSheet = @Self) then
      ToggleClipBoardOff;
  end; {...CheckforClipBoardClose }

  procedure EscPressed;
  begin
    if BlockOn then
    begin
      ClearCurrBlock;
      DisplayCellData;
    end; {...if BlockOn }
    if ClipBoard.Active then
      ToggleClipBoardOff;
  end; {...EscPressed }

begin
  case Event.What of
    evKeyDown :
      begin
        if ClipBoard.Active and ((Event.KeyCode = kbDel) or
           (Event.CharCode in [Chr(32)..Chr(255)])) then
          ToggleClipBoardOff;
        KeyPressed := True;
        case Event.KeyCode of
          kbCtrlLeft  : MovePgLeft;
          kbCtrlRight : MovePgRight;
          kbDel       : EraseCellBlock(RemoveSingleCell);
          kbDown      : MoveDown;
          kbEnd       : ToggleEnd;
          kbEnter     : if Clipboard.Active then
                          PasteCellBlock;
          kbEsc       : EscPressed;
          kbHome      : MoveHome;
          KbLeft      : MoveLeft;
          kbPgDn      : MovePgDown;
          kbPgUp      : MovePgUp;
          kbRight     : MoveRight;
          kbUp        : MoveUp;
        end; {...case Event.KeyCode }
        KeyPressed := False;
        if Event.CharCode in [Chr(32)..Chr(255)] then
           HandleInput(Event.CharCode, EditNo);
      end; {...case Event.What of evKeyDown }
    evMouseDown :
      begin
        if Event.Double then
          SetNameWithMouse(Event)
        else if not SelectColumn(Event) then
          begin
            LocateCursorWithMouse(Event);
            while MouseEvent(Event, evMouseMove + evMouseAuto) do
            begin
              Desktop^.Lock;
              DragCursorWithMouse(Event);
              Desktop^.Unlock;
            end; {...while MouseEvent(Event, evMouseMove + evMouseAuto) }
          end; {...else if not SelectColumn(Event) }
      end; {...case Event.What of evMouseDown }

    evCommand:
      begin
        if ClipBoard.Active and not (Event.Command in [cmNewSheet, cmPaste,
           cmNext, cmPrev, cmZoom, cmResize, cmClose]) then
          ToggleClipBoardOff;
        case Event.Command of
          cmCut              : MoveCellBlock;
          cmPaste            : PasteCellBlock;
          cmClose            : CheckforClipBoardClose;
          cmCopy             : CopyCellBlock;
          cmClear            : EraseCellBlock(RemoveBlock);
          cmPrintSheet       : Print;
          cmChangeColWidth   : ChangeColWidth;
          cmDeleteColumns    : DeleteColumns;
          cmDeleteRows       : DeleteRows;
          cmInsertColumns    : InsertColumns;
          cmInsertRows       : InsertRows;
          cmEditCell         : HandleInput('', EditYes);
          cmFormatCells      : FormatCells;
          cmFormatDefault    : FormatDefault;
          cmGoToCell         : GoToCell;
          cmRecalc           : Recalc(DisplayYes);
          cmToggleAutoCalc   : ToggleAutoCalc;
          cmToggleFormulas   : ToggleFormulaDisplay;
          cmChangeColHeaders : ChangeColHeaders;
          cmDeleteColHeaders :
            begin
              DeleteColHeaders(CurrBlock);
              DisplayCols;
            end; {...case Event.Command of cmDeleteColHeaders }
          cmToggleHeaders    : ToggleDisplayHeaders;
          cmToggleProtection :
            begin
              SetProtection(not SheetProtected, True);
              SetChanged(ModifiedYes);
            end;
          cmSetLocked        : SetLocked;
          cmSetUnlocked      : SetUnlocked;
          cmSortData         : SortData;
        end; {...case Event.Command }
    end; {...case Event.What of evCommand }
  end; {...case Event.What }
  TScroller.HandleEvent(Event);
end; {...TSpreadSheet.HandleEvent }


procedure TSpreadSheet.HandleInput(FirstChar: String; Editing: Boolean);
{ Gets data from the user, validates it and creates the corresponding cell }
var
  Deleted, FirstEdit, Good : Boolean;
  CurrentPos  : CellPos;
  CellValue : Extended;
  Code : Integer;
  InputLine   : PSheetInputLine;
  StringInput : PString;
  R : TRect;

    procedure DisplayEnteredString;
    var
      B : TDrawBuffer;
    begin
      with ContentsArea do
      begin
        MoveChar(B, ' ', Attrib, ScreenCols);
        Writeline(UpperLeft.Col, UpperLeft.Row, ScreenCols, 1, B);
        MoveStr(B, Copy(StringInput^, Succ(InputLine^.FirstPos),
          Min((Length(StringInput^) - InputLine^.FirstPos), ScreenCols)),
          Attrib);
        Writeline (Succ(UpperLeft.Col), UpperLeft.Row,
          Min((Length(StringInput^) - InputLine^.FirstPos), ScreenCols), 1, B);
      end; {...with ContenstArea }
    end; {...DisplayEnteredString }

begin
  if not SheetProtected or (SheetProtected and
     UnlockedHash.Search(CurrPos)) then
    begin
      Good := True;
      if TrackCursor then
        UpdateScreenBlockDisplay;
      GetMem(StringInput, 255);
      if StringInput = nil then
      begin
        Application^.OutofMemory;
        Exit;
      end; {...if StringInput = nil }
      GoToEnd := True;
      ToggleEnd;
      with ContentsArea do
      begin
        R.Assign(Succ(UpperLeft.Col), Succ(UpperLeft.Row),
          Succ(LowerRight.Col), Succ(LowerRight.Row));
        Inc(R.B.X);
        Inc(R.B.Y);
        if Editing then
        begin
          CellHash.Search(CurrPos)^.EditString(MaxDecimalPlaces, StringInput^);
          FirstChar := StringInput^;
        end; {...if Editing }
        InputLine := PSheetInputLine(GLResFile^.Get('InputLine'));
        InputLine^.SetBounds(R);
        if Editing then
          InputLine^.SetData(FirstChar)
        else
          begin
            InputLine^.Data^ := FirstChar;
            Inc(InputLine^.CurPos);
          end; {...if/else }
        FirstEdit := True;
        Parser^.Init(@CellHash, StringInput, MaxCols, MaxRows);
        repeat
          if FirstEdit then
            Owner^.ExecView(InputLine)
          else
            begin
              InputLine^.CurPos := Pred(Parser^.Position);
              if InputLine^.CurPos < (InputLine^.Size.X - 2) then
                InputLine^.FirstPos := 0
              else
                InputLine^.FirstPos := Succ(InputLine^.CurPos -
                  (InputLine^.Size.X - 2));
              Owner^.ExecView(InputLine);
            end; {...if/else }
          InputLine^.GetData(StringInput^);
          if Length(StringInput^) > 0 then
          begin
            DisplayEnteredString;
            Parser^.Parse;
            if Parser^.TokenError = 0 then
            begin
              if DoBeforeAddingCell then
                begin
                  DeleteCell(CurrPos, Deleted);
                  if Parser^.CType = ClFormula then
                    Parser^.Inp^ := UpperCase(Parser^.Inp^);
                  Good := AddCell (Parser^.CType, CurrPos, Parser^.ParseError,
                    Parser^.ParseValue, Parser^.Inp^);
                end { if }
              else
                  Parser^.TokenError := 1;
            end; {...if Parser^.TokenError = 0 }
          end; {...if Length(StringInput^) > 0 }
          FirstEdit := False;
        until (Length(StringInput^) = 0) or (Parser^.TokenError = 0) or
          not Good;
        if (Length(StringInput^) > 0) and Good then
        begin
          SetChanged(ModifiedYes);
          if AutoCalc then
            Recalc(DisplayYes);
          CurrentPos := CurrPos;
          DoAfterAddingCell;
          for CurrentPos.Col := CurrPos.Col to ScreenBlock^.Stop.Col do
            DisplayCell(CurrentPos);
        end; {...if (Length(StringInput^) > 0) and Good }
      end; {...with ContentsArea }
      Dispose(InputLine, Done);
      FreeMem(StringInput, 255);
      DisplayCellData;
    end {...if not SheetProtected or ... }
  else
    MessageBox(GLStringList^.Get(sCellsProtectedMsg), nil, mfInformation +
      mfOKButton);
end; {...TSpreadSheet.HandleInput }


procedure TSpreadSheet.InitCurrPos;
{ Locates the cursor in the first column and in the first row }
begin
  CurrPos.Col := 1;
  CurrPos.Row := 1;
end; {...InitCurrPos }


{****************************************************************************}
{ TSpreadSheet.InsertColToHash                                               }
{****************************************************************************}
procedure TSpreadSheet.InsertColToHash(Block: TBlock; Columns, StartInsCol:
  Word);
{ Updates all the hash tables after a column or group of columns is inserted }
var
  Pos, Start, Stop : CellPos;
  Deleted : Boolean;
  F : File;
  H : HashItemPtr;
  CellPtr : PCell;
  Col : Word;
begin
  SetChanged(ModifiedYes);
  DeleteBlock(Block, Deleted);
  with CellHash do
  begin
    CellPtr := FirstItem;
    while CellPtr <> nil do
    begin
      with CellPtr^ do
      begin
        if (CellPtr^.ShouldUpdate) then
          FixFormulaCol(CellPtr, opInsert, StartInsCol, Columns, MaxCols,
            MaxRows);
      end; {...with CellPtr^ }
      CellPtr := NextItem;
    end; {...while CellPtr <> nil }
  end; {...with CellHash }

  for Col := (MaxCols - Pred(Columns)) to MaxCols do
    WidthHash.Delete(Col);
  with WidthHash do
  begin
    H := FirstItem;
    while H <> nil do
    begin
      if WordPTr(@H^.Data)^ >= StartInsCol then
        Inc(WordPtr(@H^.Data)^, Columns);
      H := NextItem;
    end; {...with H <> nil }
  end; {...with WidthHash }

  Stop.Col := Block.Stop.Col;
  Stop.Row := MaxInt;
  FormatHash.Delete(Block.Start, Stop);
  with FormatHash do
  begin
    H := FirstItem;
    while H <> nil do
    begin
      Move(H^.Data, Start, SizeOf(Start));
      Move(H^.Data[SizeOf(CellPos)], Stop, SizeOf(Stop));
      if Start.Col >= StartInsCol then
      begin
        Inc(Start.Col, Columns);
        Move(Start, H^.Data, Sizeof(Start));
      end; {...if Start.Col >= StartInsCol }
      if Stop.Col >= StartInsCol then
      begin
        Inc(Stop.Col, Columns);
        Move(Stop, H^.Data[Sizeof(CellPos)], Sizeof(Stop));
      end; {...if Stop.Col >= StartInsCol }
      H := NextItem;
    end; {...while H <> nil }
  end; {...with FormatHash }

  DeleteColHeaders(@Block);
  with ColHeadersHash do
  begin
    for Col := (MaxCols - Pred(Columns)) to MaxCols do
      Delete(Col);
    H := FirstItem;
    while H <> nil do
    begin
      if WordPTr(@H^.Data)^ >= StartInsCol then
        Inc(WordPtr(@H^.Data)^, Columns);
       H := NextItem;
    end; {...with H <> nil }
  end; {...with ColHeadersHash }

  Stop.Col := Block.Stop.Col;
  Stop.Row := MaxInt;
  UnlockedHash.Delete(Block.Start, Stop);
  with UnlockedHash do
  begin
    H := FirstItem;
    while H <> nil do
    begin
      Move(H^.Data, Start, SizeOf(Start));
      Move(H^.Data[SizeOf(CellPos)], Stop, SizeOf(Stop));
      if Start.Col >= StartInsCol then
      begin
        Inc(Start.Col, Columns);
        Move(Start, H^.Data, Sizeof(Start));
      end; {...if Start.Col >= StartInsCol }
      if Stop.Col >= StartInsCol then
      begin
        Inc(Stop.Col, Columns);
        Move(Stop, H^.Data[Sizeof(CellPos)], Sizeof(Stop));
      end; {...if Stop.Col >= StartInsCol }
      H := NextItem;
    end; {...while H <> nil }
  end; {...with UnlockedHash }

  StoreTablesToTempFile;
  DoneHashTables;
  Pos.Col := StartInsCol;
  Pos.Row := 0;
  LoadTablesFromTempFile(Pos, 0, Columns);
  Assign(F, GLStringList^.Get(sTempFileName));
  Erase(F);
  LastPos.Col := Min(LastPos.Col + Columns, MaxCols);
  if LastPos.Col = MaxCols then
    Pos.Col := MaxCols
  else
    begin
      if BlockOn then
        Pos.Col := Pred(StartInsCol + Columns) + Columns
      else
        Pos.Col := StartInsCol + Columns;
    end; {...if/else }
  if Deleted then
    Pos.Row := LastPos.Row
  else
    Pos.Row := 1;
  FindLastPos(Pos);
  FixOverWrite;
end; {...TSpreadSheet.InsertColToHash }


procedure TSpreadSheet.InsertColumns;
{ Inserts one or more columns at the current position }
var
  Start, Stop: CellPos;
  H : HashItemPtr;
  CellPtr : PCell;
  Block : TBlock;
  Column, Columns, StartInsCol : Word;
begin
  Block.Start.Col := 0;
  Block.Start.Row := 0;
  Block.Stop.Col := 0;
  Block.Stop.Row := 0;
  if BlockOn then
    begin
      Columns := Succ(CurrBlock^.Stop.Col - CurrBlock^.Start.Col);
      StartInsCol := CurrBlock^.Start.Col;
      if Pred(LastPos.Col + Columns) >= MaxCols then
      begin
        with Block do
        begin
          Start.Col := MaxCols - Pred(Columns);
          Start.Row := 1;
          Stop.Col := MaxCols;
          Stop.Row := LastPos.Row;
        end; {...with Block }
        LastPos.Col := MaxCols;
      end {...if Pred(LastPos.Col + Columns) >= MaxCols }
    end {...if BlockOn }
  else
    begin
      Columns := 1;
      StartInsCol := CurrPos.Col;
      if LastPos.Col = MaxCols then
      begin
        with Block do
        begin
          Start.Col := MaxCols;
          Start.Row := 1;
          Stop.Col := MaxCols;
          Stop.Row := LastPos.Row;
        end; {...with Block do }
      end {...if LastPos.Col = MaxCols }
    end; {...if/else }
  MessageDialog := PDialog(GLResFile^.Get('UpdatingTablesDialog'));
  if Application^.ValidView(MessageDialog) <> nil then
    Desktop^.Insert(MessageDialog)
  else
    begin
      MessageDialog := nil;
      Exit;
    end; { else }
  InsertColToHash(Block, Columns, StartInsCol);
  SetScreenColStart(ScreenBlock^.Start.Col);
  if AutoCalc then
    Recalc(DisplayNo);
  if MessageDialog <> nil then
  begin
    Desktop^.Delete(MessageDialog);
    Dispose(MessageDialog, Done);
    MessageDialog := nil;
  end; { if }
  DrawView;
end; {...TSpreadSheet.InsertColumns }


{****************************************************************************}
{ TSpreadSheet.InsertRowToHash                                               }
{****************************************************************************}
procedure TSpreadSheet.InsertRowToHash(Block: TBlock; Rows, StartInsRow:
  Word);
{ Updates all the hash tables after a row or group of rows is deleted }
var
  Pos, Start, Stop : CellPos;
  Deleted : Boolean;
  F : File;
  H : HashItemPtr;
  CellPtr : PCell;
begin
  SetChanged(ModifiedYes);
  DeleteBlock(Block, Deleted);
  with CellHash do
  begin
    CellPtr := FirstItem;
    while CellPtr <> nil do
    begin
      with CellPtr^ do
      begin
        if (CellPtr^.ShouldUpdate) then
          FixFormulaRow(CellPtr, opInsert, StartInsRow, Rows, MaxCols,
            MaxRows);
      end; {...with CellPtr^ }
      CellPtr := NextItem;
    end; {...while CellPtr <> nil }
  end; {...with CellHash }

  Stop.Col := MaxInt;
  Stop.Row := Block.Stop.Row;
  FormatHash.Delete(Block.Start, Stop);;
  with FormatHash do
  begin
    H := FirstItem;
    while H <> nil do
    begin
      Move(H^.Data, Start, SizeOf(Start));
      Move(H^.Data[SizeOf(CellPos)], Stop, SizeOf(Stop));
      if Start.Row >= StartInsRow then
      begin
        Inc(Start.Row, Rows);
        Move(Start, H^.Data, Sizeof(Start));
      end; {...if Start.Row >= StartInsRow }
      if Stop.Row >= StartInsRow then
      begin
        Inc(Stop.Row, Rows);
        Move(Stop, H^.Data[Sizeof(CellPos)], Sizeof(Stop));
      end; {...if Stop.Row >= StartInsRow }
      H := NextItem;
    end; {...while H <> nil }
  end; {...with FormatHash }

  Stop.Col := MaxInt;
  Stop.Row := Block.Stop.Row;
  UnlockedHash.Delete(Block.Start, Stop);
  with UnlockedHash do
  begin
    H := FirstItem;
    while H <> nil do
    begin
      Move(H^.Data, Start, SizeOf(Start));
      Move(H^.Data[SizeOf(CellPos)], Stop, SizeOf(Stop));
      if Start.Row >= StartInsRow then
      begin
        Inc(Start.Row, Rows);
        Move(Start, H^.Data, Sizeof(Start));
      end; {...if Start.Row >= StartInsRow }
      if Stop.Row >= StartInsRow then
      begin
        Inc(Stop.Row, Rows);
        Move(Stop, H^.Data[Sizeof(CellPos)], Sizeof(Stop));
      end; {...if Stop.Row >= StartInsRow }
      H := NextItem;
    end; {...while H <> nil }
  end; {...with UnlockedHash }

  StoreTablesToTempFile;
  DoneHashTables;
  Pos.Col := 0;
  Pos.Row := StartInsRow;
  LoadTablesFromTempFile(Pos, Rows, 0);
  Assign(F, GLStringList^.Get(sTempFileName));
  Erase(F);
  if Pred(LastPos.Row+Rows) < MaxRows then
     LastPos.Row := Min(LastPos.Row + Rows, MaxRows);
  if LastPos.Row = MaxRows then
     Pos.Row := MaxRows
  else
    begin
      if BlockOn then
        Pos.Row := Pred(StartInsRow + Rows) + Rows
      else
        Pos.Row := StartInsRow + Rows;
    end; {...if/else }
  if Deleted then
    Pos.Col := LastPos.Col
  else
    Pos.Col := 1;
  FindLastPos(Pos);
  FixOverWrite;
end; {...TSpreadSheet.InsertRowToHash }


procedure TSpreadSheet.InsertRows;
{ Inserts one or more rows at the current position }
var
  Start, Stop: CellPos;
  H : HashItemPtr;
  CellPtr : PCell;
  Block : TBlock;
  Rows, StartInsRow : Word;
begin
  Block.Start.Col := 0;
  Block.Start.Row := 0;
  Block.Stop.Col := 0;
  Block.Stop.Row := 0;
  if BlockOn then
    begin
      Rows := Succ(CurrBlock^.Stop.Row - CurrBlock^.Start.Row);
      StartInsRow := CurrBlock^.Start.Row;
      if Pred(LastPos.Row + Rows) >= MaxRows then
        begin
          with Block do
          begin
            Start.Col := 1;
            Start.Row := MaxRows - Pred(Rows);
            Stop.Col := LastPos.Col;
            Stop.Row := MaxRows;
          end; {...with Block }
          LastPos.Row := MaxRows;
        end {...if Pred(LastPos.Row + Rows) >= MaxRows }
    end {...if BlockOn }
  else
    begin
      Rows := 1;
      StartInsRow := CurrPos.Row;
      if LastPos.Row = MaxRows then
      begin
        with Block do
        begin
          Start.Col := 1;
          Start.Row := MaxRows;
          Stop.Col := LastPos.Col;
          Stop.Row := MaxRows;
        end; {...with Block }
      end {...if LastPos.Row = MaxRows }
    end; {...if/else }
  MessageDialog := PDialog(GLResFile^.Get('UpdatingTablesDialog'));
  if Application^.ValidView(MessageDialog) <> nil then
    Desktop^.Insert(MessageDialog)
  else
    begin
      MessageDialog := nil;
      Exit;
    end; { else }
  InsertRowToHash(Block, Rows, StartInsRow);
  if AutoCalc then
    Recalc(DisplayNo);
  if MessageDialog <> nil then
  begin
    Desktop^.Delete(MessageDialog);
    Dispose(MessageDialog, Done);
    MessageDialog := nil;
  end; { if }
  DrawView;
end; {...TSpreadSheet.InsertRows }


constructor TSpreadSheet.Load(var S: TStream);
{ Loads the spreadsheet object from a stream }
var
  R : TRect;
  AdjustPos : CellPos;
  FileHeader : String[Length(OOGridFileHeader)];
const
  MinRowsToDisplay = 2;
begin
  AdjustPos.Col := 0;
  AdjustPos.Row := 0;
  TScroller.Load(S);
  S.Read(FileHeader, SizeOf(FileHeader));
  if FileHeader <> OOGridFileHeader then
  begin
    S.Error(stInvalidFormatError, 0);
    Exit;
  end; {...if FileHeader <> OOGridFileHeader }
  S.Read(EmptyRowsAtTop, SizeOf(EmptyRowsAtTop));
  S.Read(EmptyRowsAtBottom ,SizeOf(EmptyRowsAtBottom));
  S.Read(MaxCols, SizeOf(MaxCols));
  S.Read(MaxRows, SizeOf(MaxRows));
  S.Read(DefaultColWidth, SizeOf(DefaultColWidth));
  S.Read(DefaultDecimalPlaces, SizeOf(DefaultDecimalPlaces));
  S.Read(MaxDecimalPlaces, SizeOf(MaxDecimalPlaces));
  S.Read(DefaultCurrency, SizeOf(DefaultCurrency));
  S.Read(LastPos, SizeOf(LastPos));
  LoadHashTables(S, AdjustPos, 0, 0);
  if S.Status <> 0 then
    Exit;
  if not FixOverWrite then
  begin
    S.Error(stNoMemoryError, 0);
    Exit;
  end; {...if not FixOverWrite }
  ScreenBlock := PBlock(S.Get);
  S.Read(CurrPos, SizeOf(CurrPos));
  S.Read(BlockOn, SizeOf(BlockOn));
  CurrBlock := PBlock(S.Get);
  if S.Status <> 0 then
    Exit;
  S.Read(DisplayFormulas, SizeOf(DisplayFormulas));
  S.Read(AutoCalc, SizeOf(AutoCalc));
  S.Read(DisplayHeaders, SizeOf(DisplayHeaders));
  S.Read(SheetProtected, SizeOf(SheetProtected));
  if S.Status <> 0 then
    Exit;
  SetProtection(SheetProtected, False);
  RowNumberSpace := 6;
  MaxColWidth := ScreenCols - RowNumberSpace;
  MaxScreenCols := MaxColWidth div DefaultMinColWidth;
  GetMem(ColStart, MaxScreenCols);
  if ColStart = nil then
  begin
    S.Error(stNoMemoryError, 0);
    Exit;
  end; {...if ColStart = nil }
  OldCurrPos := CurrPos;
  GetExtent(R);
  Inc(R.A.Y, EmptyRowsAtTop);
  Dec(R.B.Y, EmptyRowsAtBottom);
  SetAreas(R);
  Recalc(DisplayNo);
end; {...TSpreadSheet.Load }


procedure TSpreadSheet.LoadDelimited(FileName: PathStr);
var
  F : Text;
  S, SAdd : String;
  V : Extended;
  Counter, Code : Integer;
  Pos : CellPos;
  NotString : Boolean;
  TempStream : TBufStream;

const
  CR = CHR(13);
  AL = CHR(10);

  procedure CloseAndUpdateHash;
  begin
    Close(F);
    FixOverWrite;
    FindLastPos(LastPos);
    DrawView;
    LowMemSize := 4096 div 16;
    TempStream.Done;
  end; {...CloseAndUpdateHash }

begin
  LowMemSize := 5088 div 16;
  TempStream.Init(GLStringList^.Get(sTempFileName), stCreate, 1024);
  Assign(F, FileName);
  Reset(F);
  Pos.Row := 0;
  NotString := True;
  while not Eof(F) do
  begin
    Readln(F, S);
    Pos.Col := 1;
    Inc(Pos.Row);
    SAdd := '';
    for Counter := 1 to Length(S) do
    begin
      if ( S[Counter] in [','] ) and NotString then
      begin
        if SAdd <> '' then
        begin
          case Pos.Col of
            2..10,15 :
              begin
                if not AddCell(ClText, Pos, False, 0, ' '+SAdd) then
                begin
                  CloseAndUpdateHash;
                  Exit;
                end; {...if not AddCell }
              end; {...case Pos.Col of 2..10, 15] }

            1, 11..14, 16 :
              begin
                if SAdd[Length(SAdd)] = ' ' then
                  SAdd := Copy(SAdd, 1, Length(SAdd)-1);
                val(SAdd, V, Code);
                if not AddCell(ClValue, Pos, False, V, '') then
                begin
                  CloseAndUpdateHash;
                  Exit;
                end; {...if not AddCell }
              end; {...case Pos.Col of 1, 11..14, 16 }
          end; {...case Pos.Col }
          SAdd := '';
        end; {...if SAdd <> '' }
        Inc(Pos.Col);
      end; {...if ( S[Counter] in ',' ) and NotString }
      if S[Counter] = '"' then
        NotString := not NotString;
      if not (S[Counter] in ['"','$',',']) then
        SAdd := SAdd + S[Counter];
    end; {...for Counter }
    if SAdd <> '' then
    begin
      val(SAdd, V, Code);
      if not AddCell(ClValue, Pos, False, V, '') then
      begin
        CloseAndUpdateHash;
        Exit;
      end; {...if not AddCell }
      SAdd := '';
    end; {...if SAdd <> '' }
  end; {...while not Eof(F) }
  CloseAndUpdateHash;
end; {...TSpreadSheet.LoadDelimited }


procedure TSpreadSheet.LoadHashTables(var S: TStream; AdjustAfter: CellPos;
  RowAdjustment, ColAdjustment: Integer);
{ Loads all the hash tables from a stream }
var
  TotalC, TotalF : LongInt;
  TotalW : Word;
  TotalHeaders : Word;
  TotalUnlocked : LongInt;
begin
  S.Read(TotalC, SizeOf(TotalC));
  S.Read(TotalW, SizeOf(TotalW));
  S.Read(TotalF, SizeOf(TotalF));
  S.Read(TotalHeaders, 2);
  S.Read(TotalUnlocked, SizeOf(TotalUnlocked));
  if not CellHash.Init(CellHashStart(TotalC)) then
  begin
    S.Error(stNoMemoryError, 0);
    Exit;
  end; {...if not CellHash.Init(CellHashStart(TotalC)) }
  if not WidthHash.Init(WidthHashStart, DefaultColWidth) then
  begin
    S.Error(stNoMemoryError, 0);
    Exit;
  end; {...if not WidthHash.Init(WidthHashStart, DefaultColWidth) }
  if not FormatHash.Init then
  begin
    S.Error(stNoMemoryError, 0);
    Exit;
  end; {...if not FormatHash.Init }
  if not OverWriteHash.Init(OverWriteHashStart) then
  begin
    S.Error(stNoMemoryError, 0);
    Exit;
  end; {...if not OverwriteHash.Init(OverwriteHashStart) }
  if not ColHeadersHash.Init(ColHeadersHashStart) then
  begin
    S.Error(stNoMemoryError, 0);
    Exit;
  end; {...if not ColHeadersHash.Init(ColHeadersHashStart) }
  if not UnlockedHash.Init then
  begin
    S.Error(stNoMemoryError, 0);
    Exit;
  end; {...if not UnlockedHash.Init }
  CellHash.Load(S, TotalC, AdjustAfter, RowAdjustment, ColAdjustment);
  if S.Status <> 0 then
    Exit;
  WidthHash.Load(S, TotalW);
  if S.Status <> 0 then
    Exit;
  FormatHash.Load(S, TotalF);
  if S.Status <> 0 then
    Exit;
  ColHeadersHash.Load(S, TotalHeaders);
  if S.Status <> 0 then
    Exit;
  UnlockedHash.Load(S, TotalUnlocked);
end; {...TSpreadSheet.LoadHashTables }


procedure TSpreadSheet.LoadTablesFromTempFile(AdjustAfter: CellPos;
  RowAdjustment, ColAdjustment: Integer);
{ Loads the hash tables from the temporal file in disk }
var
  S : TDosStream;
begin
  S.Init(GLStringList^.Get(sTempFileName), stOpenRead);
  LoadHashTables(S, AdjustAfter, RowAdjustment, ColAdjustment);
  S.Done;
end; {...TSpreadSheet.LoadTablesFromTempFile }


procedure TSpreadSheet.LocateCursorWithMouse(Event: TEvent);
{ Positions the highlight cursor in the position where the mouse was clicked }
var
  ColScrPos : Byte;
  OldPos : CellPos;
  Counter : Integer;
  Mouse : TPoint;
begin
  MakeLocal(Event.Where, Mouse);
  with ScreenBlock^ do
  begin
    if DisplayArea.PointInArea(Mouse.X, Mouse.Y) then
    begin
      CheckforDragging;
      OldPos := CurrPos;
      CurrPos.Row := YToRow(Mouse.Y);
      if (not NoBlankArea) and (BlankArea.PointInArea(Mouse.X, Mouse.Y)) then
        begin
          CurrPos.Col := Min(Succ(Stop.Col), MaxCols);
          DisplayAllCells;
          DisplayCellData;
        end { if }
      else
        begin
          CurrPos.Col := XToCol(Mouse.X);
          MoveCell(OldPos);
        end; { else }
    end; {...if DisplayArea.PointInArea(Mouse.X, Mouse.Y) }
  end; {...with ScreenBlock^ }
end; {...TSpreadSheet.LocateCursorWithMouse }


procedure TSpreadSheet.MoveCell(OldPos: CellPos);
{ Moves the cursor from one place to another and extends the block if active }
begin
  Desktop^.Lock;
  ExtendCurrBlock(RedrawYes);
  if ScreenBlock^.CellInBlock(OldPos) or
    (OldPos.Col = Succ(ScreenBlock^.Stop.Col)) then
    DisplayCell(OldPos);
  DisplayCell(CurrPos);
  DisplayCellData;
  Desktop^.Unlock;
end; {...TSpreadSheet.MoveCell}


procedure TSpreadSheet.MoveCellBlock;
{ Activates the clipboard and sets it to indicate the block to be moved }
var
  Block : PBlock;
begin
  if BlockOn then
    begin
      if not CellsProtected(CurrBlock^) then
        begin
          New(Block, Init(CurrBlock^.Start));
          Block^.Stop := CurrBlock^.Stop;
          ToggleClipBoardOn(@Self, Block, BlockOn, opMove);
        end {...if not CellsProtected(CurrBlock^) }
      else
        MessageBox(GLStringList^.Get(sCellsProtectedMsg), nil, mfInformation +
          mfOKButton);
    end {...if BlockOn}
  else
    begin
      if not SheetProtected or (SheetProtected and
         UnlockedHash.Search(CurrPos)) then
        begin
          New(Block, Init(CurrPos));
          Block^.Stop := CurrPos;
          ToggleClipBoardOn(@Self, Block, BlockOn, opMove);
        end {...if not SheetProtected or ... }
      else
        MessageBox(GLStringList^.Get(sCellsProtectedMsg), nil, mfInformation +
          mfOKButton);
    end; {...if/else }
end;  {...TSpreadSheet.MoveCellBlock}


{****************************************************************************}
{ TSpreadSheet.MoveDown                                                      }
{****************************************************************************}
procedure TSpreadSheet.MoveDown;
{ Moves the cursor one row down }
var
  OldPos : CellPos;
begin
  if CurrPos.Row < MaxRows then
  begin
    CheckForDragging;
    Desktop^.Lock;
    OldPos := CurrPos;
    if GoToEnd then
      CurrPos.Row := MaxRows
    else
      Inc(CurrPos.Row);
    if TrackCursor then
      UpdateScreenBlockDisplay
    else
      MoveCell(OldPos);
    Desktop^.Unlock;
  end; { if }
  GoToEnd := True;
  ToggleEnd;
end;

{****************************************************************************}
{ TSpreadSheet.MoveHome                                                      }
{****************************************************************************}
procedure TSpreadSheet.MoveHome;
{ Moves the cursor to the upper left corner of the spreadsheet }
var
  OldPos : CellPos;
begin
  Desktop^.Lock;
  CheckforDragging;
  OldPos := CurrPos;
  InitCurrPos;
  if TrackCursor then
    UpdateScreenBlockDisplay
  else
    MoveCell(OldPos);
  GoToEnd := True;
  ToggleEnd;
  Desktop^.Unlock;
end;


{****************************************************************************}
{ TSpreadSheet.MoveLeft                                                      }
{****************************************************************************}
procedure TSpreadSheet.MoveLeft;
{ Moves the cursor one column left }
var
  OldPos : CellPos;
begin
  if CurrPos.Col > 1 then
  begin
    CheckForDragging;
    Desktop^.Lock;
    OldPos := CurrPos;
    if GoToEnd then
      CurrPos.Col := 1
    else
      Dec(CurrPos.Col);
    if TrackCursor then
      UpdateScreenBlockDisplay
    else
      MoveCell(OldPos);
    Desktop^.Unlock;
  end; { if }
  GoToEnd := True;
  ToggleEnd;
end;


procedure TSpreadSheet.MovePgDown;
{ Moves the cursor one full page down }
var
  OldPos : CellPos;
begin
  if CurrPos.Row < MaxRows then
  begin
    CheckForDragging;
    Desktop^.Lock;
    OldPos := CurrPos;
    TrackCursor;
    CurrPos.Row := Min(MaxRows, CurrPos.Row + TotalRows);
    SetScreenRowStart(Min(MaxRows, Succ(ScreenBlock^.Stop.Row)));
    UpdateScreenBlockDisplay;
    Desktop^.Unlock;
  end; {...if CurrPos.Row < MaxRows }
end; {...TSpreadSheet.MovePgDown }


procedure TSpreadSheet.MovePgLeft;
{ Moves the cursor one full page left }
var
  OldPos : CellPos;
  TotalCols : Byte;
begin
  if CurrPos.Col > 1 then
  begin
    CheckForDragging;
    Desktop^.Lock;
    OldPos := CurrPos;
    TotalCols := Succ(ScreenBlock^.Stop.Col - ScreenBlock^.Start.Col);
    SetScreenColStop(Max(1, Pred(ScreenBlock^.Start.Col)));
    CurrPos.Col := Max(ScreenBlock^.Start.Col, LongInt(CurrPos.Col) -
      TotalCols);
    UpdateScreenBlockDisplay;
    Desktop^.Unlock;
  end; {...if CurrPos.Col > 1 }
end; {...TSpreadSheet.MovePgLeft }


procedure TSpreadSheet.MovePgRight;
{ Moves the cursor one full page right }
var
  OldPos : CellPos;
  TotalCols : Byte;
begin
  if CurrPos.Col < MaxCols then
  begin
    CheckForDragging;
    Desktop^.Lock;
    OldPos := CurrPos;
    TotalCols := Succ(ScreenBlock^.Stop.Col - ScreenBlock^.Start.Col);
    SetScreenColStart(Min(MaxCols, Succ(ScreenBlock^.Stop.Col)));
    CurrPos.Col := Min(ScreenBlock^.Stop.Col, LongInt(CurrPos.Col) +
      TotalCols);
    UpdateScreenBlockDisplay;
    Desktop^.Unlock;
  end; {...if CurrPos.Col < MaxCols }
end; {...TSpreadSheet.MovePgRight }


procedure TSpreadSheet.MovePgUp;
var
  OldPos, NewPos : CellPos;
begin
  if CurrPos.Row > 1 then
  begin
    CheckForDragging;
    Desktop^.Lock;
    OldPos := CurrPos;
    TrackCursor;
    CurrPos.Row := Max(1, LongInt(CurrPos.Row) - TotalRows);
    SetScreenRowStop(Max(1, Pred(ScreenBlock^.Start.Row)));
    UpdateScreenBlockDisplay;
    Desktop^.Unlock;
  end; {...if CurrPos.Row > 1 }
end; {...TSpreadSheet.MovePgUp }


{****************************************************************************}
{ TSpreadSheet.MoveRight                                                     }
{****************************************************************************}
procedure TSpreadSheet.MoveRight;
{ Moves the cursor one column to the right }
var
  OldPos : CellPos;
begin
  if CurrPos.Col < MaxCols then
  begin
    CheckForDragging;
    Desktop^.Lock;
    OldPos := CurrPos;
    if GoToEnd then
      CurrPos.Col := MaxCols
    else
      Inc(CurrPos.Col);
    if TrackCursor then
      UpdateScreenBlockDisplay
    else
      MoveCell(OldPos);
    Desktop^.Unlock;
  end; { if }
  GoToEnd := True;
  ToggleEnd;
end;

{****************************************************************************}
{ TSpreadSheet.MoveUp                                                        }
{****************************************************************************}
procedure TSpreadSheet.MoveUp;
{ Moves the cursor one row up }
var
  OldPos : CellPos;
begin
  if CurrPos.Row > 1 then
  begin
    CheckForDragging;
    Desktop^.Lock;
    OldPos := CurrPos;
    if GoToEnd then
      CurrPos.Row := 1
    else
      Dec(CurrPos.Row);
    if TrackCursor then
      UpdateScreenBlockDisplay
    else
      MoveCell(OldPos);
    Desktop^.Unlock;
  end; { if }
  GoToEnd := True;
  ToggleEnd;
end;

function TSpreadSheet.OverwriteHashStart: BucketRange;
{ Returns the initial number of buckest for the OverwriteHash }
begin
  OverwriteHashStart := 10;
end; {...TSpreadSheet.OverwriteHashStart}


function TSpreadSheet.Parser: PParserObject;
{ Returns a pointer to the parser to be used }
begin
  Parser := StandardParser;
end; {...TSpreadSheet.Parser }


procedure TSpreadSheet.PasteBlock(DestBlock: TBlock; Formulas: Word);
{ Moves or copies a block of cells to a new position }
var
  Deleted, Good : Boolean;
  DestPos, SrcPos : CellPos;
  FormOp : FormulaOps;
  CellPtr, CP : PCell;
  ColChange, RowChange : ShortInt;
  SrcStartCol, DestStartCol : Word;
const
  CopyColLitBit = $01;
  CopyRowLitBit = $02;
begin
  Good := True;
  with ClipBoard do
  begin
    if SameCellPos(BlockToCopy^.Start, BlockToCopy^.Stop) then
      { A single cell will be copied to a block of cells }
      begin
        SrcPos := BlockToCopy^.Start;
        DestPos := DestBlock.Start;

        if DestBlock.CellInBlock(SrcPos) and
           (SourceSpreadSheet = @Self) then
          { if the source cell is in the destination block then
            delete it from the cell hash to avoid storing the same
            cell twice at the same position }
          CellHash.Delete(SrcPos, CellPtr)
        else
          CellPtr := SourceCellHash^.Search(SrcPos);
        if CellPtr <> Empty then
        begin
          SetChanged(ModifiedYes);
          while Good and (DestPos.Row <= DestBlock.Stop.Row) do
          begin
            DestPos.Col := DestBlock.Start.Col;
            while Good and (DestPos.Col <= DestBlock.Stop.Col) do
            begin
              with CellPtr^ do
              begin
                { Delete the current cell in the destination position }
                DeleteCell(DestPos, Deleted);

                { Add a copy of the source cell in the new position }
                Good := AddCell(CellType, DestPos, HasError, CurrValue,
                  CopyString);
                if not Good then
                begin
                  if DestBlock.CellInBlock(SrcPos) and
                     (SourceSpreadSheet = @Self) then
                  { if the cell was not added to the cell hash table
                    because of a low memory error, and the source cell was
                    in the destination block, then add the source cell
                    to the table at the destination position.  This can be
                    done because the source cell already has memory
                    allocated and it does not use more memory when added to
                    the hash table }
                  begin
                    CellPtr^.Loc := DestPos;
                    CellHash.Add(CellPtr)
                  end; { if }
                end; { if }

                { Determine if cell addresses in formulas should be modified }
                CP := CellHash.Search(DestPos);
                if (CP <> nil) and CP^.ShouldUpdate then
                begin
                  if (Formulas and CopyColLitBit) = 0 then
                  { Formula column addresses must be modified }
                  begin
                    if DestPos.Col >= SrcPos.Col then
                      { The column addresses must be increased }
                      FormOp := opInsert
                    else
                      { The column addresses must be decreased }
                      FormOp := opDelete;
                    FixFormulaCol(CP, FormOp, 0, Abs(LongInt(DestPos.Col) -
                      LongInt(SrcPos.Col)), MaxCols, MaxRows);
                  end; {...if (Formulas and CopyColLitBit) = 0 }
                  if (Formulas and CopyRowLitBit) = 0 then
                  { Formula row addresses must be modified }
                  begin
                    if DestPos.Row >= SrcPos.Row then
                      { The row addresses must be increased }
                      FormOp := opInsert
                    else
                      { The row addresses must be decreased }
                      FormOp := opDelete;
                    FixFormulaRow(CP, FormOp, 0, Abs(LongInt(DestPos.Row) -
                      LongInt(SrcPos.Row)), MaxCols, MaxRows);
                  end; {...if (Formulas and CopyRowLitBit) = 0 }
                end; {...if (CP <> nil) and CP^.ShouldUpdate }
              end; {...with CellPtr^}
              Inc(DestPos.Col);
            end; {...while Good and (DestPos.Col <= DestBlock.Stop.Col) }
            Inc(DestPos.Row);
          end; {...while Good and (DestPos.Row <= DestBlock.Stop.Row) }

          if DestBlock.CellInBlock(SrcPos) and (SourceSpreadSheet = @Self) then
          { Discard the original cell, since a new copy of it was added in
            the same position }
            Dispose(CellPtr, Done)
          else if (Operation = opMove) and Good then
          { if the source cell was in the destination block, and it was
            a move operation, then delete the source cell }
            SourceSpreadSheet^.DeleteCell(SrcPos, Deleted);
        end; {...if CellPtr <> Empty }
      end {...if SameCellPos(BlockToCopy^.Start, BlockToCopy^.Stop) }
    else
      begin
        if not (SameCellPos(BlockToCopy^.Start, DestBlock.Start) and
           (SourceSpreadSheet = @Self)) then
        { Continue only after verifying that a block is not going to be
          copied into itself }
        begin
          SetChanged(ModifiedYes);
          if (BlockToCopy^.Start.Col < DestBlock.Start.Col) and
             (SourceSpreadSheet = @Self) then
            { if the possibility exists that the blocks may overlap in such
              a way that cells of the source block are overwritten by the
              cells in the destination block before they are copied, then
              copy the blocks backwards }
            begin
              ColChange := -1;
              SrcPos.Col := BlockToCopy^.Stop.Col;
              DestPos.Col := DestBlock.Stop.Col;
            end {...if (BlockToCopy^.Start.Col < DestBlock.Start.Col) }
          else
            begin
              ColChange := 1;
              SrcPos.Col := BlockToCopy^.Start.Col;
              DestPos.Col := DestBlock.Start.Col;
            end; {...if/else }
          if (BlockToCopy^.Start.Row < DestBlock.Start.Row) and
             (SourceSpreadSheet = @Self) then
            { if the possibility exists that the blocks may overlap in such
              a way that cells of the source block are overwritten by the
              cells in the destination block before they are copied, then
              copy the blocks backwards }
            begin
              RowChange := -1;
              SrcPos.Row := BlockToCopy^.Stop.Row;
              DestPos.Row := DestBlock.Stop.Row;
            end {...if (BlockToCopy^.Start.Row < DestBlock.Start.Row) }
          else
            begin
              RowChange := 1;
              SrcPos.Row := BlockToCopy^.Start.Row;
              DestPos.Row := DestBlock.Start.Row;
            end; {...if/else }

          { Assign values to the SrcStartCol and DestStartCol which indicate
            the column of the first cell that has to be copied everytime a
            new row is selected for copying }
          SrcStartCol := SrcPos.Col;
          DestStartCol := DestPos.Col;

          with BlockToCopy^ do
          begin
            while Good and ((SrcPos.Row <= Stop.Row) and
               (SrcPos.Row >= Start.Row)) and (DestPos.Row <= MaxRows) do
            begin
              SrcPos.Col := SrcStartCol;
              DestPos.Col := DestStartCol;
              while Good and ((SrcPos.Col <= Stop.Col) and
                (SrcPos.Col >= Start.Col)) and (DestPos.Col <= MaxCols) do
              begin
                CellPtr := SourceCellHash^.Search(SrcPos);
                CellHash.Delete(DestPos, CP);
                if CP <> nil then
                  Dispose(CP, Done);
                if (CellPtr <> Empty) and (CellPtr <> nil) then
                begin
                  with CellPtr^ do
                  begin
                    Good := AddCell(CellType, DestPos, HasError, CurrValue,
                      CopyString);
                    if Good then
                    begin
                      CellPtr := CellHash.Search(DestPos);
                      if CellPtr^.ShouldUpdate then
                      begin
                        if (Formulas and CopyColLitBit) = 0 then
                        begin
                          if DestPos.Col >= SrcPos.Col then
                            FormOp := opInsert
                          else
                            FormOp := opDelete;
                          FixFormulaCol(CellPtr,FormOp, 0,
                            Abs(LongInt(DestPos.Col) - LongInt(SrcPos.Col)),
                            MaxCols, MaxRows);
                        end; {...if (Fomulas and CopyColLitBit) = 0 }
                        if (Formulas and CopyRowLitBit) = 0 then
                        begin
                          if DestPos.Row >= SrcPos.Row then
                            FormOp := opInsert
                          else
                            FormOp := opDelete;
                          FixFormulaRow(CellPtr, FormOp, 0,
                            Abs(LongInt(DestPos.Row) - LongInt(SrcPos.Row)),
                            MaxCols, MaxRows);
                        end; {...if (Formulas and CopyRowLitBit) = 0 }
                      end; {...if CellPtr^.ShouldUpdate }
                    end; {...if Good }
                  end; {...with CellPtr^ }
                end; {...if (CellPtr <> Empty) and (CellPtr <> nil) }
                if (Operation = opMove) and Good then
                begin
                  SourceCellHash^.Delete(SrcPos, CP);
                  if CP <> nil then
                    Dispose(CP, Done);
                end; {...if (Operation = opMove) and Good }
                Inc(DestPos.Col, ColChange);
                Inc(SrcPos.Col, ColChange);
              end; {...while Good and ((SrcPos.Col <= Stop.Col) and ... }
              Inc(DestPos.Row, RowChange);
              Inc(SrcPos.Row, RowChange);
            end; {...while Good and ((SrcPos.Row <= Stop.Row) and ... }
          end; {...with BlockToCopy^ }
        end; {...if not SameCellPos(BlockToCopy^.Start, DestBlock.Start) ... }
      end; {...if/else }
  end; {...with ClipBoard }
end; {...TSpreadSheet.PasteBlock }


procedure TSpreadSheet.PasteCellBlock;
{ Copies a block from the source location to the current position }
var
  Dialog : PDialog;
  Block : TBlock;
begin
  with ClipBoard do
  begin
    { if the clipboard is active, then continue with the paste operation }
    if Active then
    begin
      { Determine the destination block }
      if BlockOn then
        Block.Init(CurrBlock^.Start)
      else
        Block.Init(CurrPos);
      if SameCellPos(BlockToCopy^.Start, BlockToCopy^.Stop) then
        { if its only one cell that will be copied in a block of cells then
          the destination block will be the currently selected block (if
          there is no block selected, the destination block will be the
          current cell }
        begin
          if BlockOn then
            Block.Stop := CurrBlock^.Stop
        end {...if SameCellPos(BlockToCopy^.Start, BlockToCopy^.Stop) }
      else
        { if a block of cells will be copied, then the destination block will
          have the same dimensions as the original block of cells }
        begin
          Inc(Block.Stop.Col, BlockToCopy^.Stop.Col - BlockToCopy^.Start.Col);
          Inc(Block.Stop.Row, BlockToCopy^.Stop.Row - BlockToCopy^.Start.Row);
        end; {...if/else }

      { Verifies that no protected cells are being deleted or overwritten }
      if SheetProtected then
      begin
        { Verifies that there are no protected cells in the destination
          block that could be overwritten }
        if CellsProtected(Block) then
        begin
          MessageBox(GLStringList^.Get(sCellsProtectedMsg), nil,
            mfInformation + mfOKButton);
          Exit;
        end ; {...if CellsProtected(Block) }
      end; {...if SheetProtected }

      { Execute the dialog requesting instructions on whether to update or
        not the formulas (if any) in the block to be copied or moved }
      Dialog := PDialog(GLResFile^.Get('FormulasDialog'));
      if Application^.ValidView(Dialog) <> nil then
      begin
        EraseMessage;
        if Desktop^.ExecView(Dialog) <> cmCancel then
        begin
          Dialog^.GetData(RCopyFormulas);
          MessageDialog := PDialog(GLResFile^.Get('UpdatingTablesDialog'));
          if Application^.ValidView(MessageDialog) <> nil then
            Desktop^.Insert(MessageDialog)
          else
            begin
              MessageDialog := nil;
              Exit;
            end; { else }
          PasteBlock(Block, RCopyFormulas.CopyFormulas);
          if MessageDialog <> nil then
          begin
            Desktop^.Delete(Dialog);
            Dispose(MessageDialog, Done);
            MessageDialog := nil;
          end; { if }
          if (SourceSpreadSheet <> @Self) and (SourceSpreadSheet <> nil) then
            SourceSpreadSheet^.DisplayAllCells;
          DisplayAllCells;
          ToggleClipBoardOff;
        end; {...if Desktop^.ExecView(Dialog) <> cmCancel }
        Dispose(Dialog, Done);
      end; {...if Application^.ValidView(Dialog) <> nil }
    end; {...if Active }
  end; {...with ClipBoard }
end; {...TSpreadSheet.PasteCellBlock }


procedure TSpreadSheet.Print;
{ Prints the spreadsheet }
var
  Dialog : PDialog;
  Error,                   { Is set to true whenever an error ocurrs }
  Finished : Boolean;      { Is set to true when the print job is finished }
  FileString : PathStr;
  OutputFile : Text;       { File used for output }
  PageH,                   { Horizontal position of the page being printed }
  PageV,                   { Vertical position of the page being printed }
  SelectedCommand,         { Stores the result from the message box dialogs }

  StartCol,                { Starting column of the page being printed }
  StartRow : Word;         { Starting row of the page being printed }

  TopM, BottomM, LeftM,    {    Used to store the     }
  RightM, PageR, PageCols, {     values entered       }
  ColsN, ColsC : Byte;     {    in the Print Dialog   }

  Code : Integer;          { Return code of the val function }


    function CheckForEscape: Boolean;
    { Checks the event buffer to see if ESC has been pressed to
    cancel the print job }
    var
      Event : TEvent;
    begin
      CheckForEscape := False;
      GetEvent(Event);
      if Event.What = evKeyDown then
        if Event.KeyCode = kbEsc then
        begin
          { if ESC was pressed, delete the 'Printing...' dialog
            and prompt the user for confirmation }
          Desktop^.Delete(Dialog);
          if MessageBox(GLStringList^.Get(sCancelPrintJob), nil,
             mfError + mfYesButton + mfNoButton) = cmYes then
            CheckForEscape := True
          else
            Desktop^.Insert(Dialog);
        end {...if Event.KeyCode = kbEsc }
    end; {...CheckForEscape }

    function PrintChar(C: String): Boolean;
    { Prints a code to the assigned device without a sending a CR }
    begin
      PrintChar := True;
      repeat
        if CheckForEscape then
        begin
          PrintChar := False;
          Exit;
        end; {...if CheckForEscape }
        Error := False;
        {$I-}
        Write(OutputFile, C);
        {$I+}
        if IOResult <> 0 then
        begin
          Error := True;
          if FileString = DefaultPrinterName then
            begin
              Desktop^.Delete(Dialog);
              SelectedCommand := MessageBox(
                GLStringList^.Get(sPrinterPrintErrorMsg), nil, mfError +
                mfYesButton + mfNoButton);
              if SelectedCommand = cmNo then
                PrintChar := False
              else
                { Since the print job will continue, display again
                  the 'Printing...' dialog }
                Desktop^.Insert(Dialog);
            end {...if FileString = DefaultPrinterName }
          else
            begin
              SelectedCommand := MessageBox(
                GLStringList^.Get(sFilePrintErrorMsg), nil, mfError +
                mfYesButton + mfNoButton);
              if SelectedCommand = cmNo then
                PrintChar := False
              else
                Desktop^.Insert(Dialog);
            end; {...if/else }
        end; {...if IOResult <> 0 }
      until not Error or (SelectedCommand = cmNo);
    end; {...PrintChar }

    function PrintString(S: String): Boolean;
    { Prints a string to the assigned device }
    begin
      PrintString := True;
      repeat
        if CheckForEscape then
        begin
          PrintString := False;
          Exit;
        end; {...if CheckForEscape }
        Error := False;
        {$I-}
        Writeln(OutputFile, S);
        {$I+}
        if IOResult <> 0 then
        begin
          Error := True;
          if FileString = DefaultPrinterName then
            begin
              SelectedCommand := MessageBox(
                GLStringList^.Get(sPrinterPrintErrorMsg), nil, mfError +
                mfYesButton + mfNoButton);
              if SelectedCommand = cmNo then
                PrintString := False
              else
                Desktop^.Insert(Dialog);
            end {...if FileString = DefaultPrinterName }
          else
            begin
              SelectedCommand := MessageBox(
                GLStringList^.Get(sFilePrintErrorMsg), nil, mfError +
                mfYesButton + mfNoButton);
              if SelectedCommand = cmNo then
                PrintString := False
              else
                Desktop^.Insert(Dialog);
            end; {...if/else }
        end; {...if IOResult <> 0}
      until not Error or (SelectedCommand = cmNo);
    end; {...PrintString }

    function RowStartString(Row: Word): String;
    { Returns the row string to be printed at the beginning of a line }
    begin
      RowStartString := '';
      with RPrint do
      begin
        if PrintRows <> 0 then
        begin
          if ((PrintRows = 1) and (PageH = 1)) or (PrintRows = 2) then
          begin
            RowStartString := LeftJustStr(RowToString(Row), RowNumberSpace);
            RowStartString[RowNumberSpace] := 'ณ';
          end; {...if ((PrintRows = 1) and (PageH = 1)) or... }
        end; {...if PrintRows <> 0 }
      end; {...with RPrint }
    end; {...RowStartString }

    function PrintPage: Boolean;
    { Prints one page of the spreadsheet }
    var
      Color : Byte; { Simply used to fill the list of parameters for
                     the CellToFString method }
      Cols, Counter, Rows : Byte;
      Pos : CellPos;
      S : String;
    const
      OutlineBit = $01;
      BoldBit = $02;
    begin
      PrintPage := False;
      with RPrint, PrinterConfigRec do
      begin

        { Top margin }
        for Counter := 1 to TopM do
          if not PrintString('') then
            Exit;

        { Determine the number of rows that will fit in the page }
        Rows := Min((PageR - TopM - BottomM), Succ(MaxRows - StartRow));

        { One row will be used if the column headers will be printed }
        if PrintColumns in [1,2] then
          Dec(Rows);

        { Determine the number of columns that can fit in a page }
        Cols := 0;
        Counter := Length(RowStartString(StartRow));
        while Counter <= PageCols do
        begin
          Inc(Counter, ColWidth(Cols + StartCol));
          Inc(Cols);
        end; {...while Counter <= PageCols }
        Dec(Cols);
        Cols := Min(Cols, Succ(MaxCols - StartCol));

        if ((PrintColumns = 1) and (PageV = 1)) or (PrintColumns = 2) then
        { Print the column headers if requested }
        begin
          S := FillString(Length(RowStartString(StartRow)), ' ');
          for Counter := StartCol to Pred(StartCol + Cols) do
            S := S + CenterStr(ColumnToString(Counter), ColWidth(Counter));
          if not PrintChar(PrinterUnderlineOnCode) then
            Exit;
          if (Other and BoldBit) <> 0 then
            if not PrintChar(PrinterBoldOnCode) then
              Exit;
          if not PrintString(S) then
            Exit;
          if (Other and BoldBit) <> 0 then
            if not PrintChar(PrinterBoldOffCode) then
              Exit;
          if not PrintChar(PrinterUnderlineOffCode) then
            Exit;
        end; {...if ((PrintColumns = 1) and (PageV = 1))... }

        { Print the data }
        for Pos.Row := StartRow to Pred(StartRow + Rows) do
        begin
          S := RowStartString(Pos.Row);
          if S <> '' then
          { Print the row numbers }
          begin
            if (Other and BoldBit) <> 0 then
              if not PrintChar(PrinterBoldOnCode) then
                Exit;
            if not PrintChar(S) then
              Exit;
            if (Other and BoldBit) <> 0 then
              if not PrintChar(PrinterBoldOffCode) then
                Exit;
            S := '';
          end; {...if S <> '' }
          for Pos.Col := StartCol to Pred(StartCol + Cols) do
            S := S + CellToFString(Pos, Color);
          if not PrintString(S) then
            Exit;
        end; {...for Pos.Row }

        Inc(StartCol, Cols);
        if (StartCol > LastPos.Col) or (StartCol = 0) then
          begin
            Inc(StartRow, Rows);
            if (StartRow > LastPos.Row) or (StartRow = 0) then
              Finished := True
            else
              begin
                Inc(PageV);
                PageH := 1;
                StartCol := 1;
              end; {...if/else }
          end {...if (StartCol > LastPos.Col) or (StartCol = 0) }
        else
          Inc(PageH);
        if not PrintChar(Chr(FF)) then
          Exit;
      end; {...with RPrint, PrinterConfigRec }
      PrintPage := True;
    end; {...PrintPage }

    procedure EndPrintJob;
    { Does all the necessary clean up when finishing a print job }
    begin
      Close(OutputFile);
      InitSysError;
    end; {...EndPrintJob }

begin
  Dialog := PDialog(GLResFile^.Get('PrintDialog'));
  Dialog^.SetData(RPrint);
  if Application^.ValidView(Dialog) <> nil then
    begin
      if Desktop^.ExecView(Dialog) <> cmCancel then
        Dialog^.GetData(RPrint)
      else
        begin
          Dispose(Dialog, Done);
          Exit;
        end; {...if/else }
    end {...if Application^.ValidView(Dialog) <> nil }
  else
    Exit;
  Dispose(Dialog, Done);
  with RPrint, PrinterConfigRec do
  begin
    if PrintTo = 0 then
      FileString := DefaultPrinterName
    else
      begin
        Dialog := PFileDialog(GLResFile^.Get('PrintToDialog'));
        if Application^.ValidView(Dialog) <> nil then
          begin
            if Desktop^.ExecView(Dialog) <> cmCancel then
              Dialog^.GetData(FileString)
            else
              begin
                Dispose(Dialog, Done);
                Exit;
              end; {...if/else }
          end {...if Application^.ValidView(Dialog) <> nil }
        else
          Exit;
        Dispose(Dialog, Done);
      end; {...if/else }

    { Disables Turbo Vision's system error handler to be able to handle
      print errors differently }
    DoneSysError;

    repeat
      Error := False;
      {$I-}
      Assign(OutputFile, FileString);
      Rewrite(OutputFile);
      {$I+}
      if IOResult <> 0 then
      { if the file could not be opened, prompt the user wether to
        continue with or cancel the print job }
      begin
        Error := True;
        SelectedCommand := MessageBox(GLStringList^.Get(sPrintInitErrorMsg),
          nil, mfYesButton + mfNoButton);
        if SelectedCommand = cmNo then
        begin
          EndPrintJob;
          Exit;
        end; {...if SelectedCommand = cmNo }
      end; {...if IOResult <> 0 }
    until not Error;

    { Convert to numbers the values entered in the 'Print Dialog' }
    val(TopMargin, TopM, Code);
    val(BottomMargin, BottomM, Code);
    val(LeftMargin, LeftM, Code);
    val(RightMargin, RightM, Code);
    val(PageRows, PageR, Code);
    val(NormalCols, ColsN, Code);
    val(CondensedCols, ColsC, Code);

    { Determine the number of columns available for printing }
    if PrintSize = 1 then
      begin
        if not PrintChar(PrinterCondensedOnCode) then
        begin
          EndPrintJob;
          Exit;
        end; {...if not PrintChar(PrinterCondensedOnCode) }
        PageCols := ColsC;
      end {...if PrintSize = 1}
    else
      PageCols := ColsN;
    PageV := 1;
    PageH := 1;
    StartCol := 1;
    StartRow := 1;
    Finished := False;

    { Display a dialog to indicate the file is being printed }
    Dialog := PDialog(GLResFile^.Get('PrintingDialog'));
    if Application^.ValidView(Dialog) <> nil then
      Desktop^.Insert(Dialog)
    else
      begin
        if Dialog <> nil then
          Dispose(Dialog, Done);
        EndPrintJob;
        Exit;
      end; {...if/else }
    repeat
      if not PrintPage then
      begin
        EndPrintJob;
        { It is not necessary to delete the dialog from the desktop
          since the dialog is deleted before prompting the user
          for cancelation }
        Dispose(Dialog, Done);
        Exit;
      end; {...if not PrintPage }
    until Finished;
    if not PrintChar(PrinterCondensedOffCode) or
       not PrintChar(PrinterUnderlineOffCode) then
    begin
      EndPrintJob;
      Desktop^.Delete(Dialog);
      Dispose(Dialog, Done);
      Exit;
    end; {...if not PrintChar(PrinterCondensedOffCode) or ... }
    EndPrintJob;
    Desktop^.Delete(Dialog);
    Dispose(Dialog, Done);
  end; {...with RPrint, PrinterConfigRec }
end; {...TSpreadSheet.Print }


procedure TSpreadSheet.Recalc(Display: Boolean);
{ Recalculates all the values that need to be recalculated }
var
  Pos : CellPos;

    procedure DoUpdate;
    var
      NewPos : CellPos;
      CellPtr : PCell;
      CellsOverWritten : Word;
      FormulaStr : PString;
    begin
      with CellHash do
      begin
        CellPtr := Search(Pos);
        if CellPtr^.ShouldUpdate then
        begin
          with PFormulaCell(CellPtr)^ do
          begin
            FormulaStr := NewStr(Formula.ToString);
            Parser^.Init(@CellHash, FormulaStr, MaxCols, MaxRows);
            Parser^.Parse;
            DisposeStr(FormulaStr);
            Value := Parser^.ParseValue;
            Error := Parser^.ParseError;
            SetChanged(ModifiedYes);
            CellsOverWritten := CellPtr^.OverWritten(CellHash, FormatHash,
              WidthHash, LastPos, MaxCols, GetColWidth, DisplayFormulas);
            if OverWriteHash.Change(CellPtr, CellsOverWritten) and Display and
               (CellPtr^.Loc.Col + CellsOverWritten >=
               ScreenBlock^.Start.Col) then
            begin
              NewPos := CellPtr^.Loc;
              for NewPos.Col := CellPtr^.Loc.Col to ScreenBlock^.Stop.Col do
              begin
                if ScreenBlock^.CellInBlock(NewPos) then
                  DisplayCell(NewPos);
              end; {...for NewPos.Col }
            end; {...if OverWriteHash.Change(CellPtr, CellsOverWritten) ... }
          end; {...with PFormulaCell(CellPtr)^ }
        end; {...if CellPtr^.ShouldUpdate }
      end; {...with CellHash }
    end; {...DoUpdate }

begin
  DisplayMessage(GLStringList^.Get(sRecalcMsg));
  for Pos.Row := 1 to LastPos.Row do
    for Pos.Col := 1 to LastPos.Col do
      DoUpdate;
  for Pos.Row := LastPos.Row downto 1 do
    for Pos.Col := LastPos.Col downto 1 do
      DoUpdate;
  EraseMessage;
end; {...TSpreadSheet.Recalc }


function TSpreadsheet.RowToY(Row : Integer) : Byte;
{ Returns the screen position of a particular row }
begin
  RowToY := (Row - ScreenBlock^.Start.Row) + DisplayArea.UpperLeft.Row ;
end; {...TSpreadSheet.RowToY }


function TSpreadSheet.SameCellPos(P1, P2 : CellPos) : Boolean;
{ Returns true if two positions are the same }
begin
  SameCellPos := Compare(P1, P2, SizeOf(CellPos));
end; {...TSpreadSheet.SameCellPos }


{****************************************************************************}
{ TSpreadSheet.SetFormat                                                     }
{****************************************************************************}
procedure TSpreadSheet.SetFormat(Block: TBlock; DecimalPlaces: Byte;
  Justification, NumberFormat: Word; CurrencyChar: Char);
var
  Format: FormatType;
begin
  Format := DecimalPlaces + (Justification shl JustShift) + (NumberFormat
    shl NumberFormatShift) + (Ord(CurrencyChar) shl CurrencyShift);
  if not FormatHash.Add(Block.Start, Block.Stop, Format) then
    Exit;
  FixBlockOverwrite(Block);
end;


function TSpreadSheet.SelectColumn(var Event: TEvent): Boolean;
{ Marks a complete column as selected }
var
  Pos : CellPos;
  SelectedCol : Integer;
  Block : TBlock;
  Mouse : TPoint;
begin
   MakeLocal(Event.Where, Mouse);
   if ColArea.PointInArea(Mouse.X, Mouse.Y) then
     begin
       ClearCurrBlock;
       SelectedCol := XToCol(Mouse.X);
       if SelectedCol = 0 then
         Exit;
       Pos := CurrPos;
       CurrPos.Row := 1;
       CurrPos.Col := SelectedCol;
       ToggleBlockOn;
       CurrPos.Row := ScreenBlock^.Start.Row;
       if ScreenBlock^.CellInBlock(Pos) then
         MoveCell(Pos);
       Pos.Row := MaxRows;
       Pos.Col := SelectedCol;
       CurrBlock^.Stop := Pos;
       Block.Start := CurrBlock^.Start;
       Pos.Row := ScreenBlock^.Stop.Row;
       Block.Stop := Pos;
       DisplayBlock(Block);
       DisplayCellData;
       ClearEvent(Event);
       SelectColumn := True;
     end {...if ColArea.PointInArea(Mouse.X, Mouse.Y) }
   else
     SelectColumn := False;
end; {...TSpreadSheet.SelectColumn }


procedure TSpreadSheet.ScrollDraw;
{ Redraws the spreadsheet whenever the scrollbar changes }
var
  Redraw : Boolean;
  D : TPoint;
begin
  Desktop^.Lock;
  if HScrollBar <> nil then
    D.X := HScrollBar^.Value
  else
    D.X := 0;
  if VScrollBar <> nil then
    D.Y := VScrollBar^.Value
  else
    D.Y := 0;
  if D.X <> Delta.X then
  begin
    with PlimScrollBar(HScrollBar)^, ScreenBlock^ do
    begin
      if (Abs(Change) = 1) and not KeyPressed then
        begin
          if Abs(Change) = Change then
            begin
              if Stop.Col < MaxCols then
                begin
                  Inc(Stop.Col);
                  SetScreenColStop(Stop.Col);
                  Redraw := True;
                end {...if Stop.Col < MaxCols }
              else
                SetValue(Delta.X);
            end {...if Abs(Change) = Change }
          else
            begin
              if Start.Col > 1 then
                begin
                  Dec(Start.Col);
                  SetScreenColStart(Start.Col);
                  Redraw := True;
                end {...if Start.Col > 1 }
              else
                SetValue(Delta.X);
            end; {...if/else }
          if Redraw then
          begin
            SetBlankArea;
            DisplayCols;
            DisplayAllCells;
            DisplayCellData;
            if Value <> Start.Col then
            begin
              Value := Start.Col;
              HScrollBar^.DrawView;
            end; {...if Value <> Start.Col }
            Delta.X := Value;
          end; {...if Redraw }
        end {...if (Abs(Change) = 1) and not KeyPressed }
      else if (Abs(Change) = PgStep) and not KeyPressed then
        begin
          if Abs(Change) = Change then
            begin
              if Stop.Col < MaxCols then
                begin
                  Start.Col := Succ(Stop.Col);
                  SetScreenColStart(Start.Col);
                  Redraw := True;
                end {...if Stop.Col < MaxCols }
              else
                SetValue(Delta.X);
            end {...if Abs(Change) = Change }
          else
            begin
              if Start.Col > 1 then
                begin
                  Stop.Col := Pred(Start.Col);
                  SetScreenColStop(Stop.Col);
                  Redraw := True;
                end {...if Start.Col > 1 }
              else
                SetValue(Delta.X);
            end; {...if/else }
          if Redraw then
          begin
            SetBlankArea;
            DisplayCols;
            DisplayAllCells;
            DisplayCellData;
            if Value <> Start.Col then
              begin
                Value := Start.Col;
                HScrollBar^.DrawView;
              end; {...if Value <> Start.Col }
            Delta.X := Value;
          end; {...if Redraw }
        end {...else if (Abs(Change) = PgStep) and not KeyPressed }
      else
        begin
          if (Value <= MaxCols) and (Value >= 1) then
            begin
              Start.Col := Value;
              if KeyPressed then
                ExtendCurrBlock(RedrawNo);
              SetScreenColStart(Start.Col);
              SetBlankArea;
              DisplayCols;
              DisplayAllCells;
              DisplayCellData;
              Delta.X := Value;
            end {...if (Value <= MaxCols) and (Value >= 1) }
          else
            SetValue(Delta.X);
        end; {...if/else }
    end; {...with PLimScrollBar(HScrollBar^), ScreenBlock^ }
  end; {...if D.X <> Delta.X }
  if D.Y <> Delta.Y then
  begin
    with PLimScrollBar(VScrollBar)^, ScreenBlock^ do
    begin
      if (Abs(Change) = 1) and not KeyPressed then
        begin
          if Abs(Change) = Change then
            begin
              if Stop.Row < MaxRows then
                begin
                  Inc(Stop.Row);
                  SetScreenRowStop(Stop.Row);
                  Redraw := True;
                end {...if Stop.Row < MaxRows }
              else
                SetValue(Delta.Y);
            end {...if Abs(Change) = Change }
          else
            begin
              if Start.Row > 1 then
                begin
                  Dec(Start.Row);
                  SetScreenRowStart(Start.Row);
                  Redraw := True;
                end {...if Start.Row > 1 }
              else
                SetValue(Delta.Y);
            end; {...if/else }
          if Redraw then
          begin
            DisplayRows;
            DisplayAllCells;
            DisplayCellData;
            if Value <> Start.Row then
            begin
              Value := Start.Row;
              VScrollBar^.DrawView;
            end; {...if Value <> Start.Row }
            Delta.Y := Value;
          end; {...if Redraw }
        end {...if (Abs(Change) = 1) and not KeyPressed }
      else if (Abs(Change) = PgStep) and not KeyPressed then
        begin
          if Abs(Change) = Change then
            begin
              if Stop.Row < MaxRows then
                begin
                  Start.Row := Start.Row + TotalRows;
                  if Start.Row > MaxRows then
                    Start.Row := MaxRows;
                  SetScreenRowStart(Start.Row);
                  Redraw := True;
                end {...if Stop.Row < MaxRows }
              else
                SetValue(Delta.Y);
           end {...if Abs(Change) = Change }
         else
           begin
             if Start.Row > 1 then
               begin
                 Start.Row := Start.Row - TotalRows;
                 if Start.Row < 1 then
                   Start.Row := 1;
                 SetScreenRowStart(Start.Row);
                 Redraw := True;
               end {...if Start.Row > 1 }
             else
               SetValue(Delta.Y);
           end; {...if/else }
         if Redraw then
         begin
           DisplayRows;
           DisplayAllCells;
           DisplayCellData;
           if Value <> Start.Row then
           begin
             Value := Start.Row;
             VScrollBar^.DrawView;
           end; {...if Value <> Start.Row }
           Delta.Y := Value;
         end; {...if Redraw }
       end {...else if (Abs(Change) = PgStep) and not KeyPressed }
     else
       begin
         if (Value <= MaxRows) and (Value >= 1) then
           begin
             Start.Row := Value;
             if KeyPressed then
               ExtendCurrBlock(RedrawNo);
             SetScreenRowStart(Start.Row);
             DisplayRows;
             DisplayAllCells;
             DisplayCellData;
             Delta.Y := Value;
           end {...if (Value <= MaxRows) and (Value >= 1) }
         else
           SetValue(Delta.Y);
       end; {...if/else }
    end; {...with PLimScrollBar(VScrollBar)^, ScreenBlock^ }
  end; {...if D.Y <> Delta.Y }
  Desktop^.Unlock;
end; {...TSpreadSheet.ScrollDraw }


procedure TSpreadSheet.SetAreas(ScrollArea:TRect);
{ Sets the locations of the different areas of the spreadsheet }
var
  x1, x2, y1, y2 : Byte;
begin
  x1 := ScrollArea.A.X;
  y1 := ScrollArea.A.Y;
  x2 := Pred(ScrollArea.B.X);
  y2 := Pred(ScrollArea.B.Y);
  TotalRows := Pred(y2 - Succ(y1));
  ColArea.Init(x1 + RowNumberSpace, y1, x2, y1, GetColor(6));
  RowArea.Init(x1, Succ(Y1), Pred(x1 + RowNumberSpace), Pred(Pred(y2)),
    GetColor(7));
  InfoArea.Init(x1, y1, Pred(x1 + RowNumberSpace), y1, GetColor(10));
  DisplayArea.Init(x1 + RowNumberSpace, Succ(y1), x2, Pred(Pred(y2)),
    GetColor(1));
  DataArea.Init (x1, Pred(y2), x2, Pred(y2), GetColor(1));
  ContentsArea.Init (x1, y2, x2, y2, GetColor(9));
  SetScreenColStart(ScreenBlock^.Start.Col);
  SetScreenRowStart(ScreenBlock^.Start.Row);
  SetBlankArea;
end; {...TSpreadSheet.SetAreas }

{****************************************************************************}
{ TSpreadSheet.SetAvailableCommands                                          }
{****************************************************************************}
procedure TSpreadSheet.SetAvailableCommands;
{ Enables all commands handled by TSpreadSheet.  The commands enabled will
  depend on whether the spreadsheet is protected or not. }
begin
  if not SheetProtected then
    EnableCommands([cmRecalc, cmToggleAutoCalc, cmToggleFormulas, cmEditCell,
      cmGoToCell, cmChangeColWidth, cmDeleteColumns, cmInsertColumns,
      cmDeleteRows, cmInsertRows, cmFormatCells, cmFormatDefault, cmClear,
      cmCopy, cmPaste, cmCut, cmChangeColHeaders, cmDeleteColHeaders,
      cmToggleHeaders, cmToggleProtection, cmSetUnlocked, cmSetLocked,
      cmSortData, cmPrintSheet])
  else
    begin
      EnableCommands([cmRecalc, cmToggleAutoCalc, cmEditCell,
        cmGoToCell, cmClear, cmCopy, cmPaste, cmCut, cmToggleProtection,
        cmPrintSheet]);
      DisableCommands([cmChangeColHeaders, cmDeleteColHeaders,
        cmToggleHeaders, cmToggleFormulas, cmChangeColWidth, cmDeleteColumns,
        cmInsertColumns, cmDeleteRows, cmInsertRows, cmFormatCells,
        cmFormatDefault, cmSetUnlocked, cmSetLocked, cmSortData])
    end;
end;

procedure TSpreadSheet.SetBlankArea;
{ Determines if there is a blank area and its location }
var
  C : Integer;
begin
  Move(DisplayArea, BlankArea, SizeOf(DisplayArea));
  with BlankArea do
  begin
    with ScreenBlock^ do
      C := ColStart^[Stop.Col - Start.Col] + ColWidth(Stop.Col);
    if C > DisplayArea.LowerRight.Col then
      NoBlankArea := True
    else
      begin
        NoBlankArea := False;
        UpperLeft.Col := C;
      end; {...if/else }
  end; {...with BlankArea }
end; {...TSpreadSheet.SetBlankArea }



procedure TSpreadSheet.SetChanged(IsChanged: Boolean);
{ Changes the Modified state of the spreadsheet }
begin
  Modified := IsChanged;
  if DisplayEnabled then
    DisplayInfo;
end; {...TSpreadSheet.SetChanged }


procedure TSpreadSheet.SetLimit(X, Y: Integer);
{ Sets the limits of the spreadsheet and adjusts the scrollbars accordingly }
var
  R : TRect;
begin
  Limit.X := X;
  Limit.Y := Y;
  if HScrollBar <> nil then
    with HScrollBar^ do
      SetParams (Value, 1, X, Succ(ScreenBlock^.Stop.Col -
        ScreenBlock^.Start.Col), 1);
  if VScrollBar <> nil then
    with VScrollBar^ do
      SetParams (Value, 1, Y, TotalRows, 1);
end; {...TSpreadSheet.SetLimit }


procedure TSpreadSheet.SetLocked;
{ Restores the cells to the locked state, preventing the modification of the
  cells' contents when the sheet is protected }
begin
  if BlockOn then
    UnlockedHash.Delete(CurrBlock^.Start, CurrBlock^.Stop)
  else
    UnlockedHash.Delete(CurrPos, CurrPos);
  DisplayCellData;
  SetChanged(ModifiedYes);
end; {...TSpreadSheet.SetLocked }


procedure TSpreadSheet.SetNameWithMouse(var Event: TEvent);
{ Checks to see if the mouse was DoubleClicked in the col area, and if so,
  it calls the ChangeColNames method }
var
  Mouse : TPoint;
  RealCurrPosCol : Word;
  SelectedCol : Word;
begin
  MakeLocal(Event.Where, Mouse);
  if ColArea.PointInArea(Mouse.X, Mouse.Y) then
  begin
    RealCurrPosCol := CurrPos.Col;
    SelectedCol := XToCol(Mouse.X);
    if SelectedCol = 0 then
      Exit
    else
      CurrPos.Col := SelectedCol;
    ChangeColHeaders;
    CurrPos.Col := RealCurrPosCol;
    ClearEvent(Event);
  end; {...if ColArea.PointInArea(Mouse.X, Mouse.Y) }
end; {...TSpreadSheet.SetNameWithMouse }


procedure TSpreadSheet.SetProtection(Enable, Display: Boolean);
{ Protects or unprotects the sheet from unauthorized changes }
begin
  if Enable then
    SheetProtected := True
  else
    SheetProtected := False;
  SetAvailableCommands;
  if Display then
  begin
    DisplayAllCells;
    DisplayCellData;
  end; {...if Display }
end; {...TSpreadSheet.SetProtection }


procedure TSpreadSheet.SetScreenColStart(NewCol:Integer);
{ Determines the starting and ending columns when the starting column is known }
begin
  ScreenBlock^.Start.Col := NewCol;
  FindScreenColStop;
  FindScreenColStart;
end; {...TSpreadSheet.SetScreenColStart }


procedure TSpreadSheet.SetScreenColStop(NewCol:Integer);
{ Determines the starting and ending columns when the ending column is known }
begin
  ScreenBlock^.Stop.Col := NewCol;
  FindScreenColStart;
  FindScreenColStop;
end; {...TSpreadSheet.SetScreenColStop }


procedure TSpreadSheet.SetScreenRowStart(NewRow:Integer);
{ Determines the starting and ending rows when the starting row is known }
begin
  ScreenBlock^.Start.Row := NewRow;
  FindScreenRowStop;
end; {...TSpreadSheet.SetScreenRowStart }


procedure TSpreadSheet.SetScreenRowStop(NewRow:Integer);
{ Determines the starting and ending rows when the ending row is known }
begin
  ScreenBlock^.Stop.Row := NewRow;
  FindScreenRowStart;
end; {...TSpreadSheet.SetScreenRowStop }


procedure TSpreadSheet.SetState(AState: Word; Enable: Boolean);
{ Changes the state of the spreadsheet and displays or hides the cursor
  depending on whether the spreadsheet is activated or deactivated }
begin
  if AState = sfActive then
  begin
    SetProtection(SheetProtected, False);
    if Enable then
      begin
        CurrPos := OldCurrPos;
        if ScreenBlock^.CellInBlock(CurrPos) or
           (CurrPos.Col = Succ(ScreenBlock^.Stop.Col)) then
          DisplayCell(CurrPos);
      end {...if Enable }
    else
      begin
        OldCurrPos := CurrPos;
        CurrPos.Col := Succ(ScreenBlock^.Stop.Col);
        CurrPos.Row := Succ(ScreenBlock^.Stop.Row);
        if ScreenBlock^.CellInBlock(OldCurrPos) or
           (OldCurrPos.Col = Succ(ScreenBlock^.Stop.Col)) then
          DisplayCell(OldCurrPos);
      end; {...if/else }
  end; {...if AState = sfActive }
  TScroller.SetState(AState, Enable);
end; {...TSpreadSheet.SetState }


procedure TSpreadSheet.SetUnlocked;
{ Mark the cell or group of cells as unlocked, allowing the modification of
  the cells' contents even when the sheet is protected }
begin
  if BlockOn then
    UnlockedHash.Add(CurrBlock^.Start, CurrBlock^.Stop)
  else
    UnlockedHash.Add(CurrPos, CurrPos);
  DisplayCellData;
  SetChanged(ModifiedYes);
end; {...TSpreadSheet.SetUnlocked }


procedure TSpreadSheet.SortData;
{ Sorts the data in the current block using up to three different keys }
var
  Dialog : PDialog;
  Block : TBlock;   { Block of data that will be sorted }
  Pos : CellPos;    { Used only to complete parameter list }
  F : File;

    function SortOrder(CheckBoxItem: Byte): SortTypes;
    { Returns the sort type value corresponding to the checkbox item selected }
    begin
      if CheckBoxItem = 0 then
        SortOrder := Ascending
      else
        SortOrder := Descending;
    end; {...SortOrder }

    function KeyColumn(KeyValue: String): Word;
    { Returns the corresponding column for the given string }
    var
      IndicatorLength: Byte;
      Pos : CellPos;
      Indicator : String;
      Col, FormLen : Word;
    begin
      Col := 0;
      IndicatorLength := Length(GLStringList^.Get(sColumnEntryIndicator)+' ');
      Indicator := Copy(KeyValue, 1, IndicatorLength);
      if Indicator = (GLStringList^.Get(sColumnEntryIndicator)+' ') then
      begin
        Indicator := Copy(KeyValue, Succ(IndicatorLength), (Length(KeyValue) -
          IndicatorLength));
        Col := StringToCol(Indicator, MaxCols);
      end; {...if Indicator = (GLStringList^.Get(sColumnEntryIndicator)+' ') }
      if Col = 0 then
        ColHeadersHash.SearchName(KeyValue, Col);
      KeyColumn := Col;
    end; {...KeyColumn }

begin
  if not BlockOn then
  begin
    CurrBlock^.Start.Col := 1;
    CurrBlock^.Start.Row := 1;
    CurrBlock^.Stop := LastPos;
  end; {...if not BlockOn }
  Move(CurrBlock^, Block, SizeOf(CurrBlock^));
  Dialog := PDialog(GLResFile^.Get('SortDialog'));
  if Application^.ValidView(Dialog) <> nil then
  begin
    if Desktop^.ExecView(Dialog) <> cmCancel then
    begin
      Dialog^.GetData(RSortInfo);
      MessageDialog := PDialog(GLResFile^.Get('SortingDialog'));
      if Application^.ValidView(MessageDialog) <> nil then
      begin
        Desktop^.Insert(MessageDialog);
        StatusLine^.Update;
        with RSortInfo do
        begin
          SetChanged(ModifiedYes);
          SortObject^.Init(@CellHash);
          SortObject^.Sort(Block,
          KeyColumn(FirstKey), SortOrder(FirstKeyOrder),
          KeyColumn(SecondKey), SortOrder(SecondKeyOrder),
          KeyColumn(ThirdKey), SortOrder(ThirdKeyOrder));
        end; {...with RSortInfo }
        Desktop^.Delete(MessageDialog);
        Dispose(MessageDialog, Done);
        MessageDialog := PDialog(GLResFile^.Get('UpdatingTablesDialog'));
        Desktop^.Insert(MessageDialog);
        StoreTablesToTempFile;
        DoneHashTables;
        Pos.Col := 0;
        Pos.Row := 0;
        LoadTablesFromTempFile(Pos, 0, 0);
        Assign(F, GLStringList^.Get(sTempFileName));
        Erase(F);
        FixOverwrite;
        DisplayAllCells;
        DisplayCellData;
        Desktop^.Delete(MessageDialog);
        if MessageDialog <> nil then
          Dispose(MessageDialog, Done);
      end; {...if Application^.ValidView(MessageDialog) <> nil }
      MessageDialog := nil;
    end; {...if ExecView(Dialog) <> cmCancel }
    Dispose(Dialog, Done);
  end; {...if Application^.ValidView(Dialog) <> nil }
end; {...TSpreadSheet.SortData }


function TSpreadSheet.SortObject : PSortObject;
{ Returns a pointer to the sort object to be used }
begin
  SortObject := StandardSortObject;
end; {...TSpreadSheet.SortObject }


procedure TSpreadSheet.Store(var S: TStream);
{ Writes the spreadsheet object to a stream }
const
  FileHeader : String[Length(OOGridFileHeader)] = OOGridFileHeader;
begin
  TScroller.Store(S);
  S.Write(FileHeader, SizeOf(FileHeader));
  S.Write(EmptyRowsAtTop, SizeOf(EmptyRowsAtTop));
  S.Write(EmptyRowsAtBottom, SizeOf(EmptyRowsAtBottom));
  S.Write(MaxCols, Sizeof(MaxCols));
  S.Write(MaxRows, SizeOf(MaxRows));
  S.Write(DefaultColWidth, SizeOf(DefaultColWidth));
  S.Write(DefaultDecimalPlaces, SizeOf(DefaultDecimalPlaces));
  S.Write(MaxDecimalPlaces, SizeOf(MaxDecimalPlaces));
  S.Write(DefaultCurrency, SizeOf(DefaultCurrency));
  S.Write(LastPos, SizeOf(LastPos));
  StoreHashTables(S);
  S.Put(ScreenBlock);
  S.Write(CurrPos, SizeOf(CurrPos));
  S.Write(BlockOn, SizeOf(BlockOn));
  S.Put(CurrBlock);
  S.Write(DisplayFormulas, SizeOf(DisplayFormulas));
  S.Write(AutoCalc, SizeOf(AutoCalc));
  S.Write(DisplayHeaders, SizeOf(DisplayHeaders));
  S.Write(SheetProtected, SizeOf(SheetProtected));
  SetChanged(ModifiedNo);
end; {...TSpreadSheet.Store }


procedure TSpreadSheet.StoreHashTables(var S: TStream);
{ Stores the hash tables in a stream }
begin
  S.Write(CellHash.Items, SizeOf(CellHash.Items));
  S.Write(WidthHash.Items, 2);
  S.Write(FormatHash.Items, SizeOf(FormatHash.Items));
  S.Write(ColHeadersHash.Items, 2);
  S.Write(UnlockedHash.Items, SizeOf(UnlockedHash.Items));
  CellHash.Store(S);
  WidthHash.Store(S);
  FormatHash.Store(S);
  ColHeadersHash.Store(S);
  UnlockedHash.Store(S);
end; {...TSpreadSheet.StoreHashTables }


procedure TSpreadSheet.StoreTablesToTempFile;
{ Stores the hash tables in a temporary file in disk }
var
  S : TBufStream;
begin
  S.Init(GLStringList^.Get(sTempFileName), stCreate, 1024);
  StoreHashTables(S);
  S.Done;
end; {...TSpreadSheet.StoreTablesToTempFile }


procedure TSpreadSheet.ToggleAutoCalc;
{ Turns the autocalc mode on and off }
begin
  AutoCalc := not AutoCalc;
  SetChanged(ModifiedYes);
  if AutoCalc then
    Recalc(DisplayYes);
end; {...TSpreadSheet.ToggleAutoCalc }


procedure TSpreadSheet.ToggleBlockOn;
{ Turns the block state on }
begin
  if not BlockOn then
  begin
    BlockOn := True;
    CurrBlock^.Init(CurrPos);
    DisplayInfo;
  end {...if not BlockOn }
end; {...TSpreadSheet.ToggleBlockOn }


procedure TSpreadSheet.ToggleDisplayHeaders;
{ Toggles between displaying and not displaying the column names }
begin
  DisplayHeaders := not DisplayHeaders;
  DisplayCols;
  SetChanged(ModifiedYes);
end; {...TSpreadSheet.ToggleDisplayHeaders }


procedure TSpreadSheet.ToggleEnd;
{ Toggles on and off the Go_To_End status (the END key was pressed) }
begin
  GoToEnd := Not GoToEnd;
  DisplayInfo;
end; {...TSpreadSheet.ToggleEnd }


procedure TSpreadSheet.ToggleFormulaDisplay;
{ Toggles between displaying the cell formulas or their values }
var
  OChanged : Boolean;
  CP : PCell;
begin
  Desktop^.Lock;
  DisplayFormulas := not DisplayFormulas;
  SetChanged(ModifiedYes);
  OChanged := True;
  with CellHash do
  begin
    CP := FirstItem;
    while (CP <> nil) and OChanged do
    begin
      if CP^.ShouldUpdate then
        OChanged := OverwriteHash.Change(CP, CP^.Overwritten(CellHash,
          FormatHash, WidthHash, LastPos, MaxCols, GetColWidth,
          DisplayFormulas));
        CP := NextItem;
    end; {...while (CP <> nil) and OChanged }
  end; {...with CellHash }
  DisplayAllCells;
  DisplayCellData;
  Desktop^.Unlock;
end; {...TSpreadSheet.ToggleFormulaDisplay }


function TSpreadSheet.TrackCursor: Boolean;
{ Checks if the cursor is within the limits of the currently displayed
  screen block.  If not, it adjust the screen block to include
  the position of the cursor. }
begin
  TrackCursor := False;
  if CurrPos.Col < ScreenBlock^.Start.Col then
    begin
      SetScreenColStart(CurrPos.Col);
      TrackCursor := True;
    end {...if CurrPos.Col < ScreenBlock^.Start.Col }
  else if CurrPos.Col > ScreenBlock^.Stop.Col then
    begin
      SetScreenColStop(CurrPos.Col);
      TrackCursor := True;
    end; {...else if CurrPos.Col > ScreenBlock^.Stop.Col }
  if CurrPos.Row < ScreenBlock^.Start.Row then
    begin
      SetScreenRowStart(CurrPos.Row);
      TrackCursor := True;
    end {...if CurrPos.Row < ScreenBlock^.Start.Row }
  else if CurrPos.Row > ScreenBlock^.Stop.Row then
    begin
      SetScreenRowStop(CurrPos.Row);
      TrackCursor := True;
    end; {...else if CurrPos.Row > ScreenBlock^.Stop.Row }
end; {...TSpreadSheet.TrackCursor }


procedure TSpreadSheet.UpdateScreenBlockDisplay;
{ Displays the screen and changes the scrollbars' values whenever the
  screen block was changed }
begin
  ExtendCurrBlock(RedrawNo);
  HScrollBar^.Value := ScreenBlock^.Start.Col;
  HScrollBar^.Drawview;
  VScrollBar^.Value := ScreenBlock^.Start.Row;
  VScrollBar^.Drawview;
  DrawView;
end; {...TSpreadSheet.UpdateScreenBlockDisplay }


function TSpreadSheet.WidthHashStart:BucketRange;
{ Returns the number of initial buckets of the Width hash table }
begin
  WidthHashStart := 10;
end; {...TSpreadSheet.WidthHashStart }


function TSpreadSheet.XToCol(X: Byte): Integer;
{ Returns the spreadsheet column a particular screen column position is in }
var
  ColScrPos : Byte;
  Counter   : Integer;
  Col       : Word;
begin
  Col := 0;
  with ScreenBlock^ do
  begin
    for Counter := Start.Col to Min(Succ(Stop.Col), MaxCols) do
    begin
      ColScrPos := ColToX(Counter);
      if (X < (ColScrPos + ColWidth(Counter))) and (X >= ColScrPos) then
        Col := Counter;
    end; {...for Counter }
    if (Col = 0) and (Stop.Col = MaxCols) then
      XToCol := MaxCols
    else
      XToCol := Col;
  end; {...with ScreenBlock^ }
end; {...TSpreadSheet.XToCol }


function TSpreadSheet.YToRow(Y: Byte): Integer;
{ Returns the spreadsheet row a particular screen row position is in }
begin
  YToRow := ((Y - DisplayArea.UpperLeft.Row) + ScreenBlock^.Start.Row);
end; {...TSpreadSheet.YToRow }


procedure TSpreadSheet.DoneHashTables;
{ Disposes all the hash tables }
var
  Block : TBlock;
  Deleted : Boolean;
begin
  Block.Init(LastPos);
  Block.Start.Col := 1;
  Block.Start.Row := 1;
  DeleteBlock(Block, Deleted);
  CellHash.Done;
  WidthHash.Done;
  FormatHash.Done;
  OverWriteHash.Done;
  ColHeadersHash.Done;
  UnlockedHash.Done;
end; {...TSpreadSheet.DoneHashTables }

destructor TSpreadSheet.Done;
{ Disposes the spreadsheet }
begin
  if ColStart <> nil then
    FreeMem(ColStart, MaxScreenCols);
  if ScreenBlock <> nil then
    Dispose(ScreenBlock, Done);
  if CurrBlock <> nil then
    Dispose(CurrBlock, Done);
  DoneHashTables;
  TScroller.Done;
end; {...TSpreadSheet.Done }

begin
  ClipBoard.BlockToCopy := nil;
  InitClipBoard;
  with PrinterConfigRec do
  begin
    PrinterCondensedOnCode := DefaultPrinterCondensedOnCode;
    PrinterCondensedOffCode := DefaultPrinterCondensedOffCode;
    PrinterUnderlineOnCode := DefaultPrinterUnderlineOnCode;
    PrinterUnderlineOffCode := DefaultPrinterUnderlineOffCode;
    PrinterBoldOnCode := DefaultPrinterBoldOnCode;
    PrinterBoldOffCode := DefaultPrinterBoldOffCode;
  end; {...with PrinterConfigRec }
  with RPrint do
  begin
    PrintTo := 0;
    PrintSize := 0;
    PrintRows := 0;
    PrintColumns := 0;
    TopMargin := DefaultTopMargin;
    BottomMargin := DefaultBottomMargin;
    LeftMargin := DefaultLeftMargin;
    RightMargin := DefaultRightMargin;
    Other := 0;
    PageRows := DefaultPageRows;
    NormalCols := DefaultNormalCols;
    CondensedCols := DefaultCondensedCols;
  end; {...with RPrint }
end. {...GLTSheet unit }