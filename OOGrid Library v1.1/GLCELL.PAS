{*****************************************************************************

  OOGrid Library(TM) for Borland/Turbo Pascal (Real Mode/TV)
  Copyright (C) 1994, 1995 by Arturo J. Monge
  Portions Copyright (C) 1989,1990 Borland International, Inc.

  OOGrid Library(TM) Cell Unit:
    This unit implements the different types of cells and hash tables
    used by the TSpreadSheet object. The hash tables are descendants of
    Borland's HashTable object. For more information, see TCHASH.PAS (in
    Turbo Pascal 6.0).

    Basically, this unit is the same as Borland's TCCELL.PAS but
    with a large amount of modifications which were necessary
    for adapting the unit's objects for use by the TSpreadSheet
    object.

  Copyright (C) 1989, 1990 Borland international, Inc.
  Portions Copyright (C) 1994 by Arturo J. Monge

  Last Modification : December 29th, 1994

*****************************************************************************}

{$O+,F+,N+,E+,X+}

unit GLCell;

{****************************************************************************}
                                 interface
{****************************************************************************}

uses Objects, TCUtil, TCHash, GLLStr, GLSupprt, GLEquate;

const
  { Characters that are used to indicate a certain type of cell }
  RepeatFirstChar = '\';
  TextFirstChar = ' ';

  { Bits used to determine a cell's format }
  CommasPart = $80;
  CurrencyCharPart = $FF00;
  CurrencyPart = $40;
  DecPlacesPart = $0F;
  JustPart = $03;

  { Used in the determination of a cell's format }
  CurrencyShift = 8;
  JustShift = 4;
  NumberFormatShift = 6;

type
  CellTypes = (ClEmpty, ClValue, ClText, ClFormula, ClRepeat);
  CurrencyStr = String[3];
  FormatType = Word;
  Justification = (JLeft, JCenter, JRight);

  PCell = ^TCell;

  PHashTable = ^THashTable;
  THashTable = OBJECT(HashTable)
  { A HashTable descendant that won't allow the addition of a new cell
    if LowMemory is true }
     function Add: Boolean;
  end; {...THashTable }

  PCellHashTable = ^TCellHashTable;
  TCellHashTable = OBJECT(THashTable)
  { A THashTable's descendant that stores pointers to cells in a spreadsheet
    and the associated cells' contents }
        CurrCell : PCell;
        CurrLoc : CellPos;
     constructor Init(InitBuckets : BucketRange);
     destructor Done;
     function Add(ACell : PCell) : Boolean;
     procedure Delete(DelLoc : CellPos; var DeletedCell : PCell);
     function Search(SPos : CellPos) : PCell;
     function HashValue : LongInt; virtual;
     function Found(Item : HashItemPtr) : Boolean; virtual;
     procedure CreateItem(var Item : HashItemPtr); virtual;
     function ItemSize : HashItemSizeRange; virtual;
     procedure Load(var S : TStream; Total : Longint;
       AdjustAfter: CellPos; RowAdjustment, ColAdjustment: Integer);
     procedure Store(var S : TStream);
     function FirstItem : PCell;
     function NextItem : PCell;
  end; {...TCellHashTable }

  PFormatHashTable = ^TFormatHashTable;
  TFormatHashTable = OBJECT(THashTable)
  { A THashTable's descendant that stores the format values assigned to
    blocks of cells in a spreadsheet }
       CurrStart,
       CurrStop : CellPos;
       CurrFormat : FormatType;
    constructor Init;
    destructor Done;
    function Overwrite(NewStart, NewStop : CellPos) : Boolean;
    function Add(NewStart, NewStop : CellPos;
      NewFormat : FormatType) : Boolean;
    function Delete(DStart, DStop : CellPos) : Boolean;
    function Search(SPos : CellPos; var F : FormatType) : Boolean;
    function HashValue : LongInt; virtual;
    function Found(Item : HashItemPtr) : Boolean; virtual;
    procedure CreateItem(var Item : HashItemPtr); virtual;
    function ItemSize : HashItemSizeRange; virtual;
    procedure Load(var S : TStream; Total : Longint);
    procedure Store(var S : TStream);
  end; {...TFormatHashTable }

  PWidthHashTable = ^TWidthHashTable;
  TWidthHashTable = OBJECT(THashTable)
  { A THashTable's descendant that stores the widths of the columns in
    a spreadsheet }
       CurrCol : Word;
       CurrWidth : Byte;
       DefaultColWidth : Byte;
    constructor Init(InitBuckets : BucketRange; InitDefaultColWidth : Byte);
    destructor Done;
    function Add(SCol : Word; NewWidth : Byte) : Boolean;
    procedure Delete(Col : Word);
    function Search(Col : Word) : Byte;
    function HashValue : LongInt; virtual;
    function Found(Item : HashItemPtr) : Boolean; virtual;
    procedure CreateItem(var Item : HashItemPtr); virtual;
    function ItemSize : HashItemSizeRange; virtual;
    function GetDefaultColWidth : Byte;
    procedure Load(var S : TStream; Total : Longint);
    procedure Store(var S : TStream);
  end; {...TWidthHashTable }

  GetColWidthFunc = function(var WHash : TWidthHashTable;
                             C : Word) : Byte;
  { Used by the cell objects to get the width of the column they
    are located in; also used by the TOverwriteHashTable object }

  POverwriteHashTable = ^TOverwriteHashTable;
  TOverwriteHashTable = OBJECT(THashTable)
  { A THashTable's descendant that keeps track of which cells are overwriten
    by other cells }
      CurrCell : PCell;
      CurrPos : CellPos;
      EndCol : Word;
    constructor Init(InitBuckets : BucketRange);
    destructor Done;
    function Add(SCell : PCell; var CHash: TCellHashTable;
                 var FHash: TFormatHashTable; var WHash: TWidthHashTable;
                 LastPos: CellPos; MaxCols: Word;
                 GetColWidth: GetColWidthFunc; FormulasDisplayed,
                 ChangeYes: Boolean) : Boolean;
    procedure Delete(SPos : CellPos; var CHash: TCellHashTable;
                     var FHash: TFormatHashTable; var WHash: TWidthHashTable;
                     LastPos: CellPos; MaxCols: Word;
                     GetColWidth: GetColWidthFunc;
                     FormulasDisplayed, ChangeYes: Boolean);
    function Change(SCell : PCell; Overwritten : Word) : Boolean;
    function Search(SPos : CellPos) : PCell;
    function HashValue : LongInt; virtual;
    function Found(Item : HashItemPtr) : Boolean; virtual;
    procedure CreateItem(var Item : HashItemPtr); virtual;
    function ItemSize : HashItemSizeRange; virtual;
  end; {...TOverwriteHashTable }

   PUnLockedCellHashTable = ^TUnlockedHashTable;
   TUnlockedHashTable = OBJECT(THashTable)
   { A THashTable's descendant that keeps track of unlocked areas }
         CurrStart,
         CurrStop : CellPos;
      constructor Init;
      function Add(NewStart, NewStop: CellPos): Boolean;
      procedure CreateItem(var Item: HashItemPtr); virtual;
      function Delete(DStart, DStop: CellPos): Boolean;
      function Found(Item: HashItemPtr): Boolean; virtual;
      function HashValue : LongInt; virtual;
      function ItemSize : HashItemSizeRange; virtual;
      constructor Load(var S: TStream; Total: Longint);
      function Overwrite(NewStart, NewStop: CellPos): Boolean;
      function Search(SPos: CellPos): Boolean;
      procedure Store(var S: TStream);
      destructor Done;
   end; {...TUnlockedHashTable }


   PColumnHeadersHashTable = ^THeadersHashTable;
   THeadersHashTable = OBJECT(THashTable)
   { A THashTable's descendant that stores custom assigned column headers }
        CurrCol : Word;
        CurrName : String[80];
     constructor Init(InitBuckets : BucketRange);
     function Add(SCol : Word; NewName: String) : Boolean;
     procedure CreateItem(var Item : HashItemPtr); virtual;
     procedure Delete(Col : Word);
     function Found(Item : HashItemPtr) : Boolean; virtual;
     function HashValue : LongInt; virtual;
     function ItemSize : HashItemSizeRange; virtual;
     procedure Load(var S : TStream; Total : Longint);
     function Search(Col : Word; var Name: String) : Boolean;
     function SearchName(Name: String; var Col: Word) : Boolean;
     procedure Store(var S : TStream);
     destructor Done;
   end; {...THeadersHashTable }


  TCell = OBJECT(TObject)
  { This is the main cell object.  You'll never construct an instance of
    TCell object itself; rather you'll use one or more of TCell's derived
    object types: TEmptyCell, TTextCell, TValueCell, TFormulaCell,
    TRepeatCell or create new derived object types }
       Loc : CellPos;
    constructor Init(InitLoc : CellPos);
    destructor Done; virtual;
    function CellType : CellTypes; virtual;
    function LegalValue : Boolean; virtual;
    function Name : String; virtual;
    function Format(var FHash : TFormatHashTable;
                    FormulasDisplayed : Boolean) : FormatType; virtual;
    function Width(var FHash : TFormatHashTable;
                   FormulasDisplayed : Boolean) : Word; virtual;
    function Overwritten(var CHash : TCellHashTable;
                         var FHash : TFormatHashTable;
                         var WHash : TWidthHashTable; var LastPos : CellPos;
                         MaxCols : Word; GetColWidth : GetColWidthFunc;
                         FormulasDisplayed : Boolean) : Word; virtual;
    function ShouldUpdate : Boolean; virtual;
    function HasError : Boolean; virtual;
    function CurrValue : Extended; virtual;
    function OverwriteStart(var FHash : TFormatHashTable;
                            var WHash : TWidthHashTable;
                            GetColWidth : GetColWidthFunc; EndCol : Word;
                            DisplayFormulas : Boolean) : Word; virtual;
    procedure EditString(MaxDecPlaces : Byte; var Input : String); virtual;
    function DisplayString(FormulasDisplayed : Boolean;
                           MaxDecPlaces : Byte) : String; virtual;
    function FormattedString(var OHash : TOverWriteHashTable;
                             var FHash : TFormatHashTable;
                             var WHash : TWidthHashTable;
                             GetColWidth : GetColWidthFunc;
                             CPos : CellPos; FormulasDisplayed : Boolean;
                             Start : Word; ColWidth : Byte;
                             var CurrencyString : CurrencyStr;
                             var ClType: CellTypes): String; virtual;
    function CopyString : String; virtual;
  end; {...TCell }

  PEmptyCell = ^TEmptyCell;
  TEmptyCell = OBJECT(TCell)
  { A TCell's descendant that is used to display all empty and/or overwritten
    cells.  Only one instance is TEmptyCell is constructed for use by the
    TSpreadSheet object }
    constructor Init;
    function CellType : CellTypes; virtual;
    function LegalValue : Boolean; virtual;
    function Name : String; virtual;
    function Format(var FHash : TFormatHashTable;
                    FormulasDisplayed : Boolean) : FormatType; virtual;
    function Width(var FHash : TFormatHashTable;
                   FormulasDisplayed : Boolean) : Word; virtual;
    function Overwritten(var CHash : TCellHashTable;
                         var FHash : TFormatHashTable;
                         var WHash : TWidthHashTable; var LastPos : CellPos;
                         MaxCols : Word; GetColWidth : GetColWidthFunc;
                         FormulasDisplayed : Boolean) : Word; virtual;
    function ShouldUpdate : Boolean; virtual;
    function HasError : Boolean; virtual;
    function CurrValue : Extended; virtual;
    function OverwriteStart(var FHash : TFormatHashTable;
                            var WHash : TWidthHashTable;
                            GetColWidth : GetColWidthFunc; EndCol : Word;
                            DisplayFormulas : Boolean) : Word; virtual;
    procedure EditString(MaxDecPlaces : Byte; var Input : String); virtual;
    function DisplayString(FormulasDisplayed : Boolean;
                           MaxDecPlaces : Byte) : String; virtual;
    function FormattedString(var OHash : TOverWriteHashTable;
                             var FHash : TFormatHashTable;
                             var WHash : TWidthHashTable;
                             GetColWidth : GetColWidthFunc;
                             CPos : CellPos; FormulasDisplayed : Boolean;
                             Start : Word; ColWidth : Byte;
                             var CurrencyString : CurrencyStr;
                             var ClType: CellTypes): String; virtual;
    function CopyString : String; virtual;
  end; {..TEmptyCell }

  PValueCell = ^TValueCell;
  TValueCell = OBJECT(TCell)
  { A TCell's descendant that stores a number }
       Error : Boolean;
       Value : Extended;
    constructor Init(InitLoc : CellPos; InitError : Boolean;
                     InitValue : Extended);
    function CellType : CellTypes; virtual;
    function LegalValue : Boolean; virtual;
    function Name : String; virtual;
    function Format(var FHash : TFormatHashTable;
                    FormulasDisplayed : Boolean) : FormatType; virtual;
    function Width(var FHash : TFormatHashTable;
                   FormulasDisplayed : Boolean) : Word; virtual;
    function Overwritten(var CHash : TCellHashTable;
                         var FHash : TFormatHashTable;
                         var WHash : TWidthHashTable; var LastPos : CellPos;
                         MaxCols : Word; GetColWidth : GetColWidthFunc;
                         FormulasDisplayed : Boolean) : Word; virtual;
    function ShouldUpdate : Boolean; virtual;
    function HasError : Boolean; virtual;
    function CurrValue : Extended; virtual;
    function OverwriteStart(var FHash : TFormatHashTable;
                            var WHash : TWidthHashTable;
                            GetColWidth : GetColWidthFunc; EndCol : Word;
                            DisplayFormulas : Boolean) : Word; virtual;
    procedure EditString(MaxDecPlaces : Byte; var Input : String); virtual;
    function DisplayString(FormulasDisplayed : Boolean;
                           MaxDecPlaces : Byte) : String; virtual;
    function FormattedString(var OHash : TOverWriteHashTable;
                             var FHash : TFormatHashTable;
                             var WHash : TWidthHashTable;
                             GetColWidth : GetColWidthFunc;
                             CPos : CellPos; FormulasDisplayed : Boolean;
                             Start : Word; ColWidth : Byte;
                             var CurrencyString : CurrencyStr;
                             var ClType: CellTypes): String; virtual;
    function CopyString : String; virtual;
    constructor Load(var S : TStream);
    procedure Store(var S : TStream);
  end; {...TValueCell }

  PTextCell = ^TTextCell;
  TTextCell = OBJECT(TCell)
  { A TCell's descendant that stores strings }
      Txt : LString;
    constructor Init(InitLoc : CellPos; InitTxt : String);
    function CellType : CellTypes; virtual;
    function LegalValue : Boolean; virtual;
    function Name : String; virtual;
    function Format(var FHash : TFormatHashTable;
                    FormulasDisplayed : Boolean) : FormatType; virtual;
    function Width(var FHash : TFormatHashTable;
                   FormulasDisplayed : Boolean) : Word; virtual;
    function Overwritten(var CHash : TCellHashTable;
                         var FHash : TFormatHashTable;
                         var WHash : TWidthHashTable; var LastPos : CellPos;
                         MaxCols : Word; GetColWidth : GetColWidthFunc;
                         FormulasDisplayed : Boolean) : Word; virtual;
    function ShouldUpdate : Boolean; virtual;
    function HasError : Boolean; virtual;
    function CurrValue : Extended; virtual;
    function OverwriteStart(var FHash : TFormatHashTable;
                            var WHash : TWidthHashTable;
                            GetColWidth : GetColWidthFunc; EndCol : Word;
                            DisplayFormulas : Boolean) : Word; virtual;
    procedure EditString(MaxDecPlaces : Byte; var Input : String); virtual;
    function DisplayString(FormulasDisplayed : Boolean;
                           MaxDecPlaces : Byte) : String; virtual;
    function FormattedString(var OHash : TOverWriteHashTable;
                             var FHash : TFormatHashTable;
                             var WHash : TWidthHashTable;
                             GetColWidth : GetColWidthFunc;
                             CPos : CellPos; FormulasDisplayed : Boolean;
                             Start : Word; ColWidth : Byte;
                             var CurrencyString : CurrencyStr;
                             var ClType: CellTypes): String; virtual;
    function CopyString : String; virtual;
    constructor Load(var S : TStream);
    procedure Store(var S : TStream);
    destructor Done; virtual;
  end; {...TTextCell }

  PFormulaCell = ^TFormulaCell;
  TFormulaCell = OBJECT(TCell)
  { A TCell's descendant that stores a formula and its result.  Since the
    result is a number, TFormulaCell also has all the functionality of a
    TValueCell object }
      Error : Boolean;
      Value : Extended;
      Formula : LString;
    constructor Init(InitLoc : CellPos; InitError : Boolean;
                     InitValue : Extended; InitFormula : String);
    function CellType : CellTypes; virtual;
    function LegalValue : Boolean; virtual;
    function Name : String; virtual;
    function Format(var FHash : TFormatHashTable;
                    FormulasDisplayed : Boolean) : FormatType; virtual;
    function Width(var FHash : TFormatHashTable;
                   FormulasDisplayed : Boolean) : Word; virtual;
    function Overwritten(var CHash : TCellHashTable;
                         var FHash : TFormatHashTable;
                         var WHash : TWidthHashTable; var LastPos : CellPos;
                         MaxCols : Word; GetColWidth : GetColWidthFunc;
                         FormulasDisplayed : Boolean) : Word; virtual;
    function ShouldUpdate : Boolean; virtual;
    function HasError : Boolean; virtual;
    function CurrValue : Extended; virtual;
    function OverwriteStart(var FHash : TFormatHashTable;
                            var WHash : TWidthHashTable;
                            GetColWidth : GetColWidthFunc; EndCol : Word;
                            DisplayFormulas : Boolean) : Word; virtual;
    procedure EditString(MaxDecPlaces : Byte; var Input : String); virtual;
    function DisplayString(FormulasDisplayed : Boolean;
                           MaxDecPlaces : Byte) : String; virtual;
    function FormattedString(var OHash : TOverWriteHashTable;
                             var FHash : TFormatHashTable;
                             var WHash : TWidthHashTable;
                             GetColWidth : GetColWidthFunc;
                             CPos : CellPos; FormulasDisplayed : Boolean;
                             Start : Word; ColWidth : Byte;
                             var CurrencyString : CurrencyStr;
                             var ClType: CellTypes): String; virtual;
    function CopyString : String; virtual;
    constructor Load(var S : TStream);
    procedure Store(var S : TStream);
    function GetFormula : String;
    destructor Done; virtual;
  end; {...TFormulaCell }

  PRepeatCell = ^TRepeatCell;
  TRepeatCell = OBJECT(TCell)
  { A TCell's descendant that stores a character that will be repeated
    in all the cell when displayed }
      RepeatChar : Char;
    constructor Init(InitLoc : CellPos; InitChar : Char);
    function CellType : CellTypes; virtual;
    function LegalValue : Boolean; virtual;
    function Name : String; virtual;
    function Format(var FHash : TFormatHashTable;
                    FormulasDisplayed : Boolean) : FormatType; virtual;
    function Width(var FHash : TFormatHashTable;
                   FormulasDisplayed : Boolean) : Word; virtual;
    function Overwritten(var CHash : TCellHashTable;
                         var FHash : TFormatHashTable;
                         var WHash : TWidthHashTable; var LastPos : CellPos;
                         MaxCols : Word; GetColWidth : GetColWidthFunc;
                         FormulasDisplayed : Boolean) : Word; virtual;
    function ShouldUpdate : Boolean; virtual;
    function HasError : Boolean; virtual;
    function CurrValue : Extended; virtual;
    function OverwriteStart(var FHash : TFormatHashTable;
                            var WHash : TWidthHashTable;
                            GetColWidth : GetColWidthFunc; EndCol : Word;
                            DisplayFormulas : Boolean) : Word; virtual;
    procedure EditString(MaxDecPlaces : Byte; var Input : String); virtual;
    function DisplayString(FormulasDisplayed : Boolean;
                           MaxDecPlaces : Byte) : String; virtual;
    function FormattedString(var OHash : TOverWriteHashTable;
                             var FHash : TFormatHashTable;
                             var WHash : TWidthHashTable;
                             GetColWidth : GetColWidthFunc;
                             CPos : CellPos; FormulasDisplayed : Boolean;
                             Start : Word; ColWidth : Byte;
                             var CurrencyString : CurrencyStr;
                             var ClType: CellTypes): String; virtual;
    function CopyString : String; virtual;
    constructor Load(var S : TStream);
    procedure Store(var S : TStream);
  end; {...TRepeatCell }

type
  FormulaOps = (opInsert, opDelete);
  { Used to indicate the operation that caused a cell address in a
    formula to change.  If a column or a row was inserted then
    the column or row values in affected cell addresses must be
    increased to reflect the change; if a column or a row was
    deleted then the column or row values in affected cell addresses
    must be decreased to reflect the change }

var
  Empty : PCell;
  { This is a special cell.  It is used as the return value if a cell
    cannot be found so that the TEmptyCell methods can be executed instead
    of having special routines that act differently depending on whether a
    cell is found ot not. }

const

  { Stream registration records for the object types that will be written
    to and read from the stream.  }

  RValueCell: TStreamRec = (
    ObjType: stRValueCell;
    VmtLink: Ofs(TypeOf(TValueCell)^);
    Load: @TValueCell.Load;
    Store: @TValueCell.Store
  );

  RTextCell: TStreamRec = (
    ObjType: stRTextCell;
    VmtLink: Ofs(TypeOf(TTextCell)^);
    Load: @TTextCell.Load;
    Store: @TTextCell.Store
  );

  RFormulaCell: TStreamRec = (
    ObjType: stRFormulaCell;
    VmtLink: Ofs(TypeOf(TFormulaCell)^);
    Load: @TFormulaCell.Load;
    Store: @TFormulaCell.Store
  );

  RRepeatCell: TStreamRec = (
    ObjType: stRRepeatCell;
    VmtLink: Ofs(TypeOf(TRepeatCell)^);
    Load: @TRepeatCell.Load;
    Store: @TRepeatCell.Store
  );

function FormulaStart(Inp : String; Start, MaxCols, MaxRows : Word;
                      var P : CellPos; var FormLen : Word) : Boolean;
{ Checks to see if a place in a string is the beginning of a formula }

procedure FixFormulaCol(CP : PCell; Operation: FormulaOps; After: Word;
                        Diff : Longint; MaxCols, MaxRows : Word);
{ Modify the column references of cell addresses in a formula, to reflect a
  change in position }

procedure FixFormulaRow(CP : PCell; Operation: FormulaOps; After: Word;
                        Diff : Longint; MaxCols, MaxRows : Word);
{ Modify the row references of cell addresses in a formula, to reflect a
  change in position }

procedure RegisterGLCell;
{ Register the unit's objects }


{****************************************************************************}
                               implementation
{****************************************************************************}

uses App, Memory;

var
  SavedExitProc : Pointer;


{** Unit's Register Procedures **}

procedure RegisterGLCell;
{ Registers the different cell types so that they will be written out
  correctly to disk }
begin
  RegisterType(RValueCell);
  RegisterType(RTextCell);
  RegisterType(RFormulaCell);
  RegisterType(RRepeatCell);
end; { RegisterGLCell }


{** FormulaStart function **}

function FormulaStart(Inp : String; Start, MaxCols, MaxRows : Word;
                      var P : CellPos; var FormLen : Word) : Boolean;
{ Checks to see if a place in a string is the beginning of a formula }
var
  Col, Row : Word;
  CS : String[10];
  RS : String[10];
begin
   FormulaStart := False;
   FormLen := 0;
   FillChar(P, SizeOf(P), 0);
   CS := '';
   while (Start <= Length(Inp)) and (Inp[Start] in Letters) do
   begin
     CS := CS + Inp[Start];
     Inc(Start);
   end;
   Col := StringToCol(CS, MaxCols);
   if Col = 0 then
     Exit;
   RS := '';
   while (Start <= Length(Inp)) and (Inp[Start] in Numbers) do
   begin
     RS := RS + Inp[Start];
     Inc(Start);
   end;
   Row := StringToRow(RS, MaxRows);
   if Row = 0 then
     Exit;
   P.Col := Col;
   P.Row := Row;
   FormLen := System.Length(CS) + System.Length(RS);
   FormulaStart := True;
end; {...FormulaStart }


{** FixFormulaCol procedure **}

procedure FixFormulaCol(CP : PCell; Operation: FormulaOps; After: Word;
                        Diff : Longint; MaxCols, MaxRows : Word);
var
  FormLen, Place, OldLen, NewLen : Word;
  P : CellPos;
  S : String[10];
  Good : Boolean;
  FormulaStr: String;
begin
  with PFormulaCell(CP)^ do
  begin
    FormulaStr := GetFormula;
    Place := 1;
    while (Place <= Length(FormulaStr)) do
    begin
      if FormulaStart(FormulaStr, Place, MaxCols, MaxRows, P, FormLen) then
      begin
        if (Operation = opInsert) then
           begin
              if (P.Col + Diff) > MaxCols then
                 S := '!REF'
              else if (P.Col >= After) then
                 S := ColToString(LongInt(P.Col) + Diff)
              else
                 S := ColToString(LongInt(P.Col));
           end
        else
           begin
              if (P.Col >= Succ(After - Diff)) and (P.Col <= After) then
                 S := '!REF'
              else if (P.Col > After) then
                 S := ColToString(LongInt(P.Col) - Diff)
              else
                 S := ColToString(LongInt(P.Col));
        end;
        OldLen := Length(ColToString(P.Col));
        NewLen := Length(S);
        if S = '!REF' then
           begin
              Delete(FormulaStr, Place, FormLen);
              Insert(S, FormulaStr, Place);
              Inc(Place, FormLen);
              Good := False;
           end
        else if NewLen > OldLen then
           Insert(FillString(NewLen - OldLen, ' '), FormulaStr, Place)
        else if NewLen < OldLen then
           Delete(FormulaStr, Place, OldLen - NewLen);
        if Good then
        begin
           Move(S[1], FormulaStr[Place], Length(S));
           Inc(Place, FormLen + NewLen - OldLen);
        end;
        Good := True;
      end
      else
        Inc(Place);
    end;
    Formula.Done;
    Formula.Init;
    Formula.FromString(FormulaStr);
  end;
end;


{** FixFormulaRow procedure **}

procedure FixFormulaRow(CP : PCell; Operation: FormulaOps; After: Word;
                        Diff : Longint; MaxCols, MaxRows : Word);
var
  ColLen,FormLen, Place, OldLen, NewLen : Word;
  P : CellPos;
  S : String[10];
  Good : Boolean;
  FormulaStr: String;
begin
  with PFormulaCell(CP)^ do
  begin
    FormulaStr := GetFormula;
    Place := 1;
    while (Place <= Length(FormulaStr)) do
    begin
      if FormulaStart(FormulaStr, Place, MaxCols, MaxRows, P, FormLen) then
      begin
        if (Operation = opInsert) then
           begin
              if (P.Row + Diff) > MaxRows then
                 S := '!REF'
              else if (P.Row >= After) then
                 S := RowToString(LongInt(P.Row) + Diff)
              else
                 S := RowToString(LongInt(P.Row));
           end
        else
           begin
              if ((P.Row >= Succ(After - Diff)) and (P.Row <= After)) then
                 S := '!REF'
              else if (P.Row > After) then
                 S := RowToString(LongInt(P.Row) - Diff)
              else
                 S := RowToString(LongInt(P.Row));
        end;
        OldLen := Length(RowToString(P.Row));
        NewLen := Length(S);
        ColLen := Length(ColToString(P.Col));
        if S = '!REF' then
           begin
              Delete(FormulaStr, Place, FormLen);
              Insert(S, FormulaStr, Place);
              Inc(Place, FormLen);
              Good := False;
           end
        else if NewLen > OldLen then
           Insert(FillString(NewLen - OldLen, ' '), FormulaStr, Place + ColLen)
        else if NewLen < OldLen then
           Delete(FormulaStr, Place + ColLen, OldLen - NewLen);
        if Good then
        begin
           Move(S[1], FormulaStr[Place+ColLen], Length(S));
           Inc(Place, FormLen + NewLen - OldLen);
        end;
        Good := True;
      end
      else
        Inc(Place);
    end;
    Formula.Done;
    Formula.Init;
    Formula.FromString(FormulaStr);
  end;
end;


{** THashTable **}

function THashTable.Add: Boolean;
begin
   if not LowMemory then
      begin
         if not HashTable.Add then
            begin
               Application^.OutOfMemory;
               Add := False;
            end {...if not HashTable.Add }
         else
            Add := True;
      end {...if MemAvail > LowMemoryAddLimit }
   else
      begin
         Application^.OutOfMemory;
         Add := False;
      end; {...else/if MemAvail > LowMemoryAddLimit }
end; {...THashTable.Add }



{** TCellHashTable **}

constructor TCellHashTable.Init(InitBuckets : BucketRange);
{ Initializes a cell hash table, which stores pointers to the cells in a
  spreadsheet }
begin
  if not THashTable.Init(InitBuckets) then
    Fail;
end; { TCellHashTable.Init }

destructor TCellHashTable.Done;
{ Removes a cell hash table from memory }
var
  CP : PCell;
begin
  CP := FirstItem;
  while CP <> nil do
  begin
    Dispose(CP, Done);
    CP := NextItem;
  end;
  THashTable.Done;
end; { TCellHashTable.Done }

function TCellHashTable.Add(ACell : PCell) : Boolean;
{ Adds a cell to a cell hash table }
begin
  CurrCell := ACell;
  CurrLoc := CurrCell^.Loc;
  Add := THashTable.Add;
end; { TCellHashTable.Add }

procedure TCellHashTable.Delete(DelLoc : CellPos; var DeletedCell : PCell);
{ Deletes a cell from a cell hash table }
begin
  CurrLoc := DelLoc;
  THashTable.Delete(@DeletedCell);
end; { TCellHashTable.Delete }

function TCellHashTable.Search(SPos : CellPos) : PCell;
{ Searches for a cell in a cell hash table, returning the cell if found, or
  returning the Empty cell if not found }
var
  I : HashItemPtr;
  C : PCell;
begin
  CurrLoc := SPos;
  I := THashTable.Search;
  if I = nil then
    Search := Empty
  else begin
    Move(I^.Data, C, SizeOf(C));
    Search := C;
  end;
end; { TCellHashTable.Search }

function TCellHashTable.HashValue : LongInt;
{ Calculates the hash value of a cell }
begin
  HashValue := CurrLoc.Col + CurrLoc.Row;
end; { TCellHashTable.HashValue }

function TCellHashTable.Found(Item : HashItemPtr) : Boolean;
{ Checks to see if a hash item is the one searched for by comparing the
  location information in both }
var
  C : PCell;
begin
  Move(Item^.Data, C, SizeOf(C));
  Found := Compare(C^.Loc, CurrLoc, SizeOf(CurrLoc));
end; { TCellHashTable.Found }

procedure TCellHashTable.CreateItem(var Item : HashItemPtr);
{ Writes the cell pointer information out to the hash item }
begin
  Move(CurrCell, Item^.Data, SizeOf(CurrCell));
end; { TCellHashTable.CreateItem }

function TCellHashTable.ItemSize : HashItemSizeRange;
{ The hash item size is current - just cell pointers are stored }
begin
  ItemSize := SizeOf(CurrCell);
end; { TCellHashTable.ItemSize }

procedure TCellHashTable.Load(var S : TStream; Total : Longint;
  AdjustAfter: CellPos; RowAdjustment, ColAdjustment: Integer);
{ Loads a cell hash table from disk }
var
  Counter : Longint;
  LoadedCell : PCell;
begin
  if AdjustAfter.Col = 0 then
    AdjustAfter.Col := 65535;
  if AdjustAfter.Row = 0 then
    AdjustAfter.Row := 65535;
  for Counter := 1 to Total do
  begin
    LoadedCell := PCell(S.Get);
    if LoadedCell^.Loc.Col >= AdjustAfter.Col then
      Inc(LoadedCell^.Loc.Col, ColAdjustment);
    if LoadedCell^.Loc.Row >= AdjustAfter.Row then
      Inc(LoadedCell^.Loc.Row, RowAdjustment);
    if not Add(LoadedCell) then
    begin
      if CurrCell <> NIL then
         Dispose(CurrCell, Done);
      S.Error(stNoMemoryError, 0);
      Exit;
    end;
  end;
end; { TCellHashTable.Load }

procedure TCellHashTable.Store(var S : TStream);
{ Writes a cell hash table to disk }
var
  CP : PCell;
begin
  CP := FirstItem;
  while CP <> nil do
  begin
    S.Put(CP);
    CP := NextItem;
  end;
end; { TCellHashTable.Store }

function HashItemPtrToCellPtr(H : HashItemPtr) : PCell;
{ Converts a hash item pointer to a cell pointer }
var
  CP : PCell;
begin
  if H = nil then
    HashItemPtrToCellPtr := nil
  else begin
    Move(H^.Data, CP, SizeOf(CP));
    HashItemPtrToCellPtr := CP;
  end;
end; { HashItemPtrToCellPtr }

function TCellHashTable.FirstItem : PCell;
{ Returns the first hash item in a cell hash table }
begin
  FirstItem := HashItemPtrToCellPtr(THashTable.FirstItem);
end; { TCellHashTable.FirstItem }

function TCellHashTable.NextItem : PCell;
{ Returns the second and subsequent hash items in a cell hash table }
begin
  NextItem := HashItemPtrToCellPtr(THashTable.NextItem);
end; { TCellHashTable.NextItem }



{** TWidthHashTable **}

constructor TWidthHashTable.Init(InitBuckets : BucketRange;
                                InitDefaultColWidth : Byte);
{ Initializes the width hash table, which stores column widths that are
  different than the default.  It stores the column and the width in the
  hash table }
begin
  if not THashTable.Init(InitBuckets) then
    Fail;
  DefaultColWidth := InitDefaultColWidth;
end; { TWidthHashTable.Init }

destructor TWidthHashTable.Done;
begin
  THashTable.Done;
end; { TWidthHashTable.Done }

function TWidthHashTable.Add(SCol : Word; NewWidth : Byte) : Boolean;
begin
  CurrCol := SCol;
  CurrWidth := NewWidth;
  Add := THashTable.Add;
end; { TWidthHashTable }

procedure TWidthHashTable.Delete(Col : Word);
begin
  CurrCol := Col;
  THashTable.Delete(nil);
end; { TWidthHashTable.Delete }

function TWidthHashTable.Search(Col : Word) : Byte;
var
  I : HashItemPtr;
  W : Byte;
begin
  CurrCol := Col;
  I := THashTable.Search;
  if I = nil then
    Search := 0
  else begin
    Move(I^.Data[SizeOf(CurrCol)], W, SizeOf(W));
    Search := W;
  end;
end; { TWidthHashTable.Search }

function TWidthHashTable.HashValue : LongInt;
begin
  HashValue := CurrCol;
end; { TWidthHashTable.HashValue }

function TWidthHashTable.Found(Item : HashItemPtr) : Boolean;
var
  C : Word;
begin
  Move(Item^.Data, C, SizeOf(C));
  Found := CurrCol = C;
end; { TWidthHashTable.Found }

procedure TWidthHashTable.CreateItem(var Item : HashItemPtr);
begin
  Move(CurrCol, Item^.Data, SizeOf(CurrCol));
  Move(CurrWidth, Item^.Data[SizeOf(CurrCol)], SizeOf(CurrWidth));
end; { TWidthHashTable.CreateItem }

function TWidthHashTable.ItemSize : HashItemSizeRange;
begin
  ItemSize := SizeOf(CurrCol) + SizeOf(CurrWidth);
end; { TWidthHashTable.ItemSize }

function TWidthHashTable.GetDefaultColWidth : Byte;
begin
  GetDefaultColWidth := DefaultColWidth;
end; { TWidthHashTable.GetDefaultColWidth }

procedure TWidthHashTable.Load(var S : TStream; Total : Longint);
var
  Counter : Longint;
  Col : Word;
  Width : Byte;
begin
  for Counter := 1 to Total do
  begin
    S.Read(Col, SizeOf(Col));
    S.Read(Width, SizeOf(Width));
    if not Add(Col, Width) then
    begin
      S.Error(stNoMemoryError, 0);
      Exit;
    end;
  end;
end; { TWidthHashTable.Load }

procedure TWidthHashTable.Store(var S : TStream);
var
  H : HashItemPtr;
  Col : Word;
  Width : Byte;
begin
  H := FirstItem;
  while H <> nil do
  begin
    Move(H^.Data, Col, SizeOf(Col));
    S.Write(Col, SizeOf(Col));
    Move(H^.Data[SizeOf(Col)], Width, SizeOf(Width));
    S.Write(Width, SizeOf(Width));
    H := NextItem;
  end;
end; { TWidthHashTable.Store }



{** TFormatHashTable **}

constructor TFormatHashTable.Init;
{ Initializes a format hash table, which is used to store formatted areas
  that differ from the default.  The area and the format are stored in the
  hash table }
begin
  if not THashTable.Init(1) then   { Use a single bucket so that a search }
    Fail;                          { will be possible }
end; { TFormatHashTable.Init }

destructor TFormatHashTable.Done;
begin
  THashTable.Done;
end; { TFormatHashTable.Done }

function TFormatHashTable.Overwrite(NewStart, NewStop : CellPos) : Boolean;
{ Checks to see if a new format area has overwritten an old one, requiring
  the old area to be overwritten or broken into parts }
var
  H, Next : HashItemPtr;
  AStart, AStop, BStart, BStop : CellPos;
  F : FormatType;
  P : CellPos;
  Added : Boolean;
begin
  Overwrite := False;
  H := HashData^[1];
  while H <> nil do
  begin
    Next := H^.Next;
    Move(H^.Data, BStart, SizeOf(CellPos));
    Move(H^.Data[SizeOf(CellPos)], BStop, SizeOf(CellPos));
    if ((((NewStart.Col >= BStart.Col) and (NewStart.Col <= BStop.Col)) or
         ((NewStop.Col >= BStart.Col) and (NewStop.Col <= BStop.Col))) and
        (((NewStart.Row >= BStart.Row) and (NewStart.Row <= BStop.Row)) or
         ((NewStop.Row >= BStart.Row) and (NewStop.Row <= BStop.Row)))) or
       ((((BStart.Col >= NewStart.Col) and (BStart.Col <= NewStop.Col)) or
         ((BStop.Col >= NewStart.Col) and (BStop.Col <= NewStop.Col))) and
        (((BStart.Row >= NewStart.Row) and (BStart.Row <= NewStop.Row)) or
         ((BStop.Row >= NewStart.Row) and (BStop.Row <= NewStop.Row)))) then
    begin
      Move(H^.Data[SizeOf(CellPos) shl 1], F, SizeOf(F));
      CurrStart := BStart;
      CurrStop := BStop;
      THashTable.Delete(nil);
      if BStart.Row < NewStart.Row then
      begin
        AStart := BStart;
        AStop.Col := BStop.Col;
        AStop.Row := Pred(NewStart.Row);
        if not Add(AStart, AStop, F) then
          Exit;
      end;
      if BStop.Row > NewStop.Row then
      begin
        AStart.Col := BStart.Col;
        AStart.Row := Succ(NewStop.Row);
        AStop.Col := BStop.Col;
        AStop.Row := BStop.Row;
        if not Add(AStart, AStop, F) then
          Exit;
      end;
      if BStart.Col < NewStart.Col then
      begin
        AStart.Col := BStart.Col;
        AStart.Row := Max(BStart.Row, NewStart.Row);
        AStop.Col := Pred(NewStart.Col);
        AStop.Row := Min(BStop.Row, NewStop.Row);
        if not Add(AStart, AStop, F) then
          Exit;
      end;
      if BStop.Col > NewStop.Col then
      begin
        AStart.Col := Succ(NewStop.Col);
        AStart.Row := Max(BStart.Row, NewStart.Row);
        AStop.Col := BStop.Col;
        AStop.Row := Min(BStop.Row, NewStop.Row);
        if not Add(AStart, AStop, F) then
          Exit;
      end;
    end;
    H := Next;
  end;
  Overwrite := True;
end; { TFormatHashTable.Overwrite }

function TFormatHashTable.Add(NewStart, NewStop : CellPos;
                             NewFormat : FormatType) : Boolean;
begin
  if not Overwrite(NewStart, NewStop) then
  begin
    Add := False;
    Exit;
  end;
  CurrStart := NewStart;
  CurrStop := NewStop;
  CurrFormat := NewFormat;
  Add := THashTable.Add;
end; { TFormatHashTable.Add }

function TFormatHashTable.Delete(DStart, DStop : CellPos) : Boolean;
begin
  Delete := Overwrite(DStart, DStop);
end; { TFormatHashTable.Delete }

function TFormatHashTable.Search(SPos : CellPos; var F : FormatType) :
                                 Boolean;
var
  H : HashItemPtr;
begin
  CurrStart := SPos;
  H := THashTable.Search;
  if H = nil then
    Search := False
  else begin
    Move(H^.Data[SizeOf(CellPos) shl 1], F, SizeOf(F));
    Search := True;
  end;
end; { TFormatHashTable.Search }

function TFormatHashTable.HashValue : LongInt;
{ Since the hash table has only one bucket, the hash value is always 1 }
begin
  HashValue := 1;
end; { TFormatHashTable.HashValue }

function TFormatHashTable.Found(Item : HashItemPtr) : Boolean;
var
  P : CellPos;
  B : TBlock;
  Start, Stop : CellPos;
  Good : Boolean;
begin
  Move(Item^.Data, Start, SizeOf(CellPos));
  Move(Item^.Data[SizeOf(CellPos)], Stop, SizeOf(CellPos));
  B.Init(Start);
  B.Stop := Stop;
  Found := B.CellInBlock(CurrStart);
end; { TFormatHashTable.Found }

procedure TFormatHashTable.CreateItem(var Item : HashItemPtr);
begin
  with Item^ do
  begin
    Move(CurrStart, Data, SizeOf(CellPos));
    Move(CurrStop, Data[SizeOf(CellPos)], SizeOf(CellPos));
    Move(CurrFormat, Data[SizeOf(CellPos) shl 1], SizeOf(CurrFormat));
  end; { with }
end; { TFormatHashTable.CreateItem }

function TFormatHashTable.ItemSize : HashItemSizeRange;
begin
  ItemSize := (SizeOf(CellPos) shl 1) + SizeOf(FormatType);
end; { TFormatHashTable.ItemSize }

procedure TFormatHashTable.Load(var S : TStream; Total : Longint);
var
  Counter : Longint;
  C1, C2 : CellPos;
  Format : FormatType;
begin
  for Counter := 1 to Total do
  begin
    S.Read(C1, SizeOf(C1));
    S.Read(C2, SizeOf(C2));
    S.Read(Format, 2);
    if not Add(C1, C2, Format) then
    begin
      S.Error(stNoMemoryError, 0);
      Exit;
    end;
  end;
end; { TFormatHashTable.Load }

procedure TFormatHashTable.Store(var S : TStream);
var
  H : HashItemPtr;
  C : CellPos;
  Format : Byte;
begin
  H := FirstItem;
  while H <> nil do
  begin
    Move(H^.Data, C, SizeOf(C));
    S.Write(C, SizeOf(C));
    Move(H^.Data[SizeOf(CellPos)], C, SizeOf(C));
    S.Write(C, SizeOf(C));
    Move(H^.Data[SizeOf(CellPos) shl 1], Format, 2);
    S.Write(Format, 2);
    H := NextItem;
  end;
end; { TFormatHashTable.Store }



{** TOverWriteHashTable **}

constructor TOverWriteHashTable.Init(InitBuckets : BucketRange);
{ Initializes an overwrite hash table, which keeps track of which cells are
  overwritten by other cells }
begin
  if not THashTable.Init(InitBuckets) then
    Fail;
end; { TOverWriteHashTable.Init }

destructor TOverWriteHashTable.Done;
begin
  THashTable.Done;
end; { TOverWriteHashTable.Done }

function TOverWriteHashTable.Add(SCell : PCell;
                                 var CHash: TCellHashTable;
                                 var FHash: TFormatHashTable;
                                 var WHash: TWidthHashTable; LastPos: CellPos;
                                 MaxCols: Word; GetColWidth: GetColWidthFunc;
                                 FormulasDisplayed, ChangeYes: Boolean)
                                 : Boolean;
var
  CP : PCell;
  NewOverWritten, OverWritten : Word;

const
  ChangeNo = False;

begin
  if ChangeYes then
  begin
     CP := Search(SCell^.Loc);
     if CP <> Empty then
     begin
       NewOverWritten := CP^.OverWritten(CHash, FHash, WHash, LastPos,
                             MaxCols, GetColWidth, FormulasDisplayed);
       if NewOverWritten = 0 then
             Delete(CP^.Loc, CHash, FHash, WHash, LastPos, MaxCols,
                    GetColWidth, FormulasDisplayed, ChangeNo)
       else if (not Change(CP, NewOverWritten)) then
       begin
         Add := False;
         Exit;
       end; {...else if not Change(CP, CP^.OverWritten) }
     end; {...if CP <> Empty }
  end; {...if ChangeYes}
  OverWritten := SCell^.Overwritten(CHash, FHash, WHash, LastPos, MaxCols, GetColWidth,
                        FormulasDisplayed);
  if OverWritten = 0 then
     Add := True
  else
     begin
        CurrCell := SCell;
        CurrPos := SCell^.Loc;
        EndCol := CurrPos.Col + Overwritten;
        Add := THashTable.Add;
     end; {...else/if OverWritten = 0 }
end; {...TOverWriteHashTable.Add }

procedure TOverWriteHashTable.Delete(SPos : CellPos;
                                 var CHash: TCellHashTable;
                                 var FHash: TFormatHashTable;
                                 var WHash: TWidthHashTable; LastPos: CellPos;
                                 MaxCols: Word; GetColWidth: GetColWidthFunc;
                                 FormulasDisplayed, ChangeYes: Boolean);
var
   CellPtr : PCell;
   OverWritten : Word;
begin
   CurrPos := SPos;
   THashTable.Delete(NIL);
   if ChangeYes and (SPos.Col > 1) then
   begin
      Dec(SPos.Col);
      CellPtr := Search(SPos);
      if CellPtr = Empty then
         CellPtr := CHash.Search(SPos);
      if CellPtr <> Empty then
      begin
         OverWritten := CellPtr^.OverWritten(CHash, FHash, WHash, LastPos,
                                  MaxCols, GetColWidth, FormulasDisplayed);
         if OverWritten <> 0 then
            Change(CellPtr, OverWritten);
      end; {...if CellPtr <> Empty }
   end; {...if SPos.Col > 1 }
end; {...TOverWriteHashTable.Delete }

function TOverWriteHashTable.Change(SCell : PCell;
                                   Overwritten : Word) : Boolean;
begin
   CurrCell := SCell;
   CurrPos := CurrCell^.Loc;
   EndCol := SCell^.Loc.Col + Overwritten;
   Change := THashTable.Change;
end; {...TOverWriteHashTable.Change }

function TOverWriteHashTable.Search(SPos : CellPos) : PCell;
var
  I : HashItemPtr;
  C : PCell;
begin
  CurrPos := SPos;
  I := THashTable.Search;
  if I = nil then
    Search := Empty
  else begin
    Move(I^.Data, C, SizeOf(C));
    Search := C;
  end;
end; { TOverWriteHashTable.Search }

function TOverWriteHashTable.HashValue : LongInt;
begin
  HashValue := CurrPos.Row;
end; { TOverWriteHashTable.HashValue }

function TOverWriteHashTable.Found(Item : HashItemPtr) : Boolean;
var
  C : PCell;
  E : Word;
begin
  Move(Item^.Data, C, SizeOf(C));
  Move(Item^.Data[SizeOf(C)], E, SizeOf(E));
  with CurrPos do
    Found := (Row = C^.Loc.Row) and (Col >= C^.Loc.Col) and
             (Col <= E);
end; { TOverWriteHashTable.Found }

procedure TOverWriteHashTable.CreateItem(var Item : HashItemPtr);
begin
  Move(CurrCell, Item^.Data, SizeOf(CurrCell));
  Move(EndCol, Item^.Data[SizeOf(CurrCell)], SizeOf(EndCol));
end; { TOverWriteHashTable.CreateItem }

function TOverWriteHashTable.ItemSize : HashItemSizeRange;
begin
  ItemSize := SizeOf(CurrCell) + SizeOf(EndCol);
end; { TOverWriteHashTable.ItemSize }



{** TCell **}

constructor TCell.Init(InitLoc : CellPos);
{ Initializes a cell's location }
begin
  Loc := InitLoc;
end; { TCell.Init }

destructor TCell.Done;
{ Frees memory used by the cell }
begin
end; { TCell.Done }

function TCell.CellType : CellTypes;
{ Returns the type of a cell - used in copying cells }
begin
  Abstract('TCell.CellType');
end; { TCell.CellType }

function TCell.LegalValue : Boolean;
{ Returns True if the cell has a legal numeric value }
begin
  Abstract('TCell.LegalValue');
end; { TCell.LegalValue }

function TCell.Name : String;
{ Returns the name of the cell type }
begin
  Abstract('TCell.Name');
end; { TCell.Name }

function TCell.Format(var FHash : TFormatHashTable; FormulasDisplayed : Boolean) :
                         FormatType;
{ Returns the format of a cell }
begin
  Abstract('TCell.Format');
end; { TCell.Format }

function TCell.Width(var FHash : TFormatHashTable; FormulasDisplayed : Boolean) :
                        Word;
{ Returns the width of a cell (including the cells that it will overwrite) }
begin
  Abstract('TCell.Width');
end; { TCell.Width }

function TCell.Overwritten(var CHash : TCellHashTable;
                               var FHash : TFormatHashTable;
                               var WHash : TWidthHashTable;
                               var LastPos : CellPos;
                               MaxCols : Word;
                               GetColWidth : GetColWidthFunc;
                               FormulasDisplayed : Boolean) : Word;
{ Calculates how many cells a cell will overwrite }
begin
  Abstract('TCell.Overwritten');
end; { TCell.Overwritten }

function TCell.ShouldUpdate : Boolean;
{ Returns True if the cell needs to be updated when the spreadsheet changes }
begin
  Abstract('TCell.ShouldUpdate');
end; { TCell.ShouldUpdate }

function TCell.HasError : Boolean;
{ Returns True if the cell has a numeric error in it }
begin
  Abstract('TCell.HasError');
end; { TCell.HasError }

function TCell.CurrValue : Extended;
{ Returns the current numeric value of a cell }
begin
  Abstract('TCell.CurrValue');
end; { TCell.CurrValue }

function TCell.OverwriteStart(var FHash : TFormatHashTable;
                             var WHash : TWidthHashTable;
                             GetColWidth : GetColWidthFunc; EndCol : Word;
                             DisplayFormulas : Boolean) : Word;
{ Determines, for overwritten cells, where in the overwriting data they will
  Start to display a value }
begin
  Abstract('TCell.OverwriteStart');
end; { TCell.OverwriteStart }

procedure TCell.EditString(MaxDecPlaces : Byte;
                           var Input : String);
{ Sets up a long string with the cell's value that can be edited }
begin
  Abstract('TCell.EditString');
end; { TCell.EditString }

function TCell.DisplayString(FormulasDisplayed : Boolean;
                            MaxDecPlaces : Byte) : String;
{ Returns the string that will be displayed just above the input line }
begin
  Abstract('TCell.DisplayString');
end; { TCell.DisplayString }

function TCell.FormattedString(var OHash : TOverWriteHashTable;
                              var FHash : TFormatHashTable;
                              var WHash : TWidthHashTable;
                              GetColWidth : GetColWidthFunc;
                              CPos : CellPos; FormulasDisplayed : Boolean;
                              Start : Word; ColWidth : Byte;
                              var CurrencyString : CurrencyStr;
                              var ClType: CellTypes): String;
{ Returns the string that will be printed in a cell }
begin
  Abstract('TCell.FormattedString');
end; { TCell.FormattedString }

function TCell.CopyString : String;
{ Copies a cell's string information to another cell's }
begin
  Abstract('TCell.CopyString');
end; { TCell.CopyString }



{** TEmptyCell **}

constructor TEmptyCell.Init;
var
  NewLoc : CellPos;
begin
  NewLoc.Col := 0;
  NewLoc.Row := 0;
  TCell.Init(NewLoc);
end; { TEmptyCell.Init }

function TEmptyCell.CellType : CellTypes;
begin
  CellType := ClEmpty;
end; { TEmptyCell.CellType }

function TEmptyCell.LegalValue : Boolean;
begin
  LegalValue := True;
end; { TEmptyCell.LegalValue }

function TEmptyCell.Name : String;
begin
  Name := GLStringList^.Get(sEmptyCellName);
end; { TEmptyCell.Name }

function TEmptyCell.Format(var FHash : TFormatHashTable;
                              FormulasDisplayed : Boolean) : FormatType;
begin
  Format := 0;
end; { TEmptyCell.Format }

function TEmptyCell.Width(var FHash : TFormatHashTable;
                             FormulasDisplayed : Boolean) : Word;
begin
  Width := 0;
end; { TEmptyCell.Width }

function TEmptyCell.Overwritten(var CHash : TCellHashTable;
                                    var FHash : TFormatHashTable;
                                    var WHash : TWidthHashTable;
                                    var LastPos : CellPos;
                                    MaxCols : Word;
                                    GetColWidth : GetColWidthFunc;
                                    FormulasDisplayed : Boolean) : Word;
begin
  Overwritten := 0;
end; { TEmptyCell.Overwritten }

function TEmptyCell.ShouldUpdate : Boolean;
begin
  ShouldUpdate := False;
end; { TEmptyCell.ShouldUpdate }

function TEmptyCell.HasError : Boolean;
begin
  HasError := False;
end; { TCell.HasError }

function TEmptyCell.CurrValue : Extended;
begin
  CurrValue := 0;
end; { TEmptyCell.CurrValue }

function TEmptyCell.OverwriteStart(var FHash : TFormatHashTable;
                                  var WHash : TWidthHashTable;
                                  GetColWidth : GetColWidthFunc;
                                  EndCol : Word;
                                  DisplayFormulas : Boolean) : Word;
begin
  OverwriteStart := 1;
end; { TEmptyCell.OverwriteStart }

procedure TEmptyCell.EditString(MaxDecPlaces : Byte;
                                     var Input : String);
begin
  Input := '';
end; { TEmptyCell.EditString }

function TEmptyCell.DisplayString(FormulasDisplayed : Boolean;
                                       MaxDecPlaces : Byte) : String;
begin
  DisplayString := '';
end; { TEmptyCell.DisplayString }

function TEmptyCell.FormattedString(var OHash : TOverWriteHashTable;
                                   var FHash : TFormatHashTable;
                                   var WHash : TWidthHashTable;
                                   GetColWidth : GetColWidthFunc;
                                   CPos : CellPos;
                                   FormulasDisplayed : Boolean;
                                   Start : Word; ColWidth : Byte;
                                   var CurrencyString : CurrencyStr;
                                   var ClType: CellTypes) : String;
var
  CP : PCell;
begin
  CP := OHash.Search(CPos);
  if CP <> Empty then
    FormattedString := CP^.FormattedString(OHash, FHash, WHash, GetColWidth,
                                           Loc, FormulasDisplayed,
                                           CP^.OverWriteStart(FHash, WHash,
                                           GetColWidth, CPos.Col,
                                           FormulasDisplayed), ColWidth,
                                           CurrencyString, ClType)
  else begin
    ClType := CellType;
    FormattedString := '';
    CurrencyString := '';
  end;
end; { TEmptyCell.FormattedString }

function TEmptyCell.CopyString : String;
begin
  CopyString := '';
end; { TEmptyCell.CopyString }



{** TValueCell **}

constructor TValueCell.Init(InitLoc : CellPos; InitError : Boolean;
                           InitValue : Extended);
begin
  TCell.Init(InitLoc);
  Error := InitError;
  Value := InitValue;
end; { TValueCell.Init }

function TValueCell.CellType : CellTypes;
begin
  CellType := ClValue;
end; { TValueCell.CellType }

function TValueCell.LegalValue : Boolean;
begin
  LegalValue := True;
end; { TValueCell.LegalValue }

function TValueCell.Name : String;
begin
  Name := GLStringList^.Get(sValueCellName);
end; { TValueCell.Name }

function TValueCell.Format(var FHash : TFormatHashTable;
                              FormulasDisplayed : Boolean) : FormatType;
var
  F : FormatType;
begin
  if FHash.Search(Loc, F) then
    Format := F
  else
    Format := (Ord(JRight) shl 4) + DefaultDefaultDecimalPlaces;
end; { TValueCell.Format }

function TValueCell.Width(var FHash : TFormatHashTable;
                             FormulasDisplayed : Boolean) : Word;
var
  S : String;
  F : FormatType;
  P, W : Integer;
begin
  F := Format(FHash, FormulasDisplayed);
  Str(Value:1:(F and DecPlacesPart), S);
  W := Length(S);
  if (F and CurrencyPart) <> 0 then
    Inc(W, Length(DefaultCurrencyString));
  if (F and CommasPart) <> 0 then
  begin
    P := Pos('.', S);
    if P = 0 then
      P := Length(S);
    inc(W, (P - 2) div 3);
  end;
  Width := W;
end; { TValueCell.Width }

function TValueCell.Overwritten(var CHash : TCellHashTable;
                               var FHash : TFormatHashTable;
                               var WHash : TWidthHashTable;
                               var LastPos : CellPos;
                               MaxCols : Word;
                               GetColWidth : GetColWidthFunc;
                               FormulasDisplayed : Boolean) : Word;
var
  CellWidth : Longint;
  Total : Word;
  P : CellPos;
begin
  P := Loc;
  CellWidth := Width(FHash, FormulasDisplayed);
  Total := 0;
  repeat
    Inc(Total);
    Dec(CellWidth, GetColWidth(WHash, P.Col));
    Inc(P.Col);
  until (CellWidth <= 0) or (P.Col > MaxCols) or (CHash.Search(P) <> Empty);
  Dec(Total);
  Overwritten := Total;
end; { TValueCell.Overwritten }

function TValueCell.ShouldUpdate : Boolean;
begin
  ShouldUpdate := False;
end; { TValueCell.ShouldUpdate }

function TValueCell.HasError : Boolean;
begin
  HasError := Error;
end; { TValueCell.HasError }

function TValueCell.CurrValue : Extended;
begin
  CurrValue := Value;
end; { TValueCell.CurrValue }

function TValueCell.OverwriteStart(var FHash : TFormatHashTable;
                                  var WHash : TWidthHashTable;
                                  GetColWidth : GetColWidthFunc;
                                  EndCol : Word;
                                  DisplayFormulas : Boolean) : Word;
var
  F : FormatType;
  C, Place : Word;
begin
  F := Format(FHash, DisplayFormulas);
  Place := 1;
  C := Loc.Col;
  repeat
    Inc(Place, GetColWidth(WHash, C));
    Inc(C);
  until C = EndCol;
  if (F and CurrencyPart) <> 0 then
    Dec(Place, Length(DefaultCurrencyString));
  OverwriteStart := Place;
end; { TValueCell.OverwriteStart }

procedure TValueCell.EditString(MaxDecPlaces : Byte;
                                     var Input : String);
var
  S : String;
begin
  Str(Value:1:MaxDecPlaces, S);
  Input := S;
end; { TValueCell.EditString }

function TValueCell.DisplayString(FormulasDisplayed : Boolean;
                                       MaxDecPlaces : Byte) : String;
var
  S : String;
begin
  Str(Value:1:MaxDecPlaces, S);
  DisplayString := S;
end; { TValueCell.DisplayString }

function TValueCell.FormattedString(var OHash : TOverWriteHashTable;
                                   var FHash : TFormatHashTable;
                                   var WHash : TWidthHashTable;
                                   GetColWidth : GetColWidthFunc;
                                   CPos : CellPos;
                                   FormulasDisplayed : Boolean;
                                   Start : Word; ColWidth : Byte;
                                   var CurrencyString : CurrencyStr;
                                   var ClType: CellTypes): String;
var
  Counter : Word;
  S : String;
  F : FormatType;
begin
  ClType := CellType;
  F := Format(FHash, FormulasDisplayed);
  Str(Value:1:F and DecPlacesPart, S);
  if (Start = 1) and ((F and CurrencyPart) <> 0) then
    CurrencyString := ' '+Char((F and CurrencyCharPart) shr 8)+' '
  else
    CurrencyString := '';
  if (F and CommasPart) <> 0 then
  begin
    Counter := Pos('.', S);
    if Counter = 0 then
      Counter := System.Length(S);
    while Counter > 4 do
    begin
      System.Insert(',', S, Counter - 3);
      Dec(Counter, 3);
    end;
  end;
  S := Copy(S, Start, ColWidth);
  if Length(S) <= (ColWidth - 1) then
    FormattedString := S + ' '
  else
    FormattedString := S;

end; { TValueCell.FormattedString }

function TValueCell.CopyString : String;
begin
  CopyString := '';
end; { TValueCell.CopyString }

constructor TValueCell.Load(var S : TStream);
begin
  S.Read(Loc, SizeOf(Loc));
  S.Read(Error, SizeOf(Error));
  S.Read(Value, SizeOf(Value));
end; { TValueCell.Load }

procedure TValueCell.Store(var S : TStream);
begin
  S.Write(Loc, SizeOf(Loc));
  S.Write(Error, SizeOf(Error));
  S.Write(Value, SizeOf(Value));
end; { TValueCell.Store }


{** TTextCell **}

constructor TTextCell.Init(InitLoc : CellPos; InitTxt : String);
begin
  TCell.Init(InitLoc);
  Txt.Init;
  Txt.FromString(InitTxt);
end; { TTextCell.Init }

function TTextCell.CellType : CellTypes;
begin
  CellType := ClText;
end; { TTextCell.CellType }

function TTextCell.LegalValue : Boolean;
begin
  LegalValue := False;
end; { TTextCell.LegalValue }

function TTextCell.Name : String;
begin
  Name := GLStringList^.Get(sTextCellName);
end; { TTextCell.Name }

function TTextCell.Format(var FHash : TFormatHashTable;
                             FormulasDisplayed : Boolean) : FormatType;
var
  F : FormatType;
begin
  if FHash.Search(Loc, F) then
    Format := F
  else
    Format := 0;
end; { TTextCell.Format }

function TTextCell.Width(var FHash : TFormatHashTable;
                            FormulasDisplayed : Boolean) : Word;
begin
  Width := Txt.Length;
end; { TTextCell.Width }

function TTextCell.Overwritten(var CHash : TCellHashTable;
                                   var FHash : TFormatHashTable;
                                   var WHash : TWidthHashTable;
                                   var LastPos : CellPos;
                                   MaxCols : Word;
                                   GetColWidth : GetColWidthFunc;
                                   FormulasDisplayed : Boolean) : Word;
var
  CellWidth : Longint;
  Total : Word;
  P : CellPos;
begin
  P := Loc;
  CellWidth := Width(FHash, FormulasDisplayed);
  Total := 0;
  repeat
    Inc(Total);
    Dec(CellWidth, GetColWidth(WHash, P.Col));
    Inc(P.Col);
  until (CellWidth <= 0) or (P.Col > MaxCols) or (CHash.Search(P) <> Empty);
  Dec(Total);
  Overwritten := Total;
end; { TTextCell.Overwritten }

function TTextCell.ShouldUpdate : Boolean;
begin
  ShouldUpdate := False;
end; { TTextCell.ShouldUpdate }

function TTextCell.HasError : Boolean;
begin
  HasError := False;
end; { TTextCell.HasError }

function TTextCell.CurrValue : Extended;
begin
  CurrValue := 0;
end; { TTextCell.CurrValue }

function TTextCell.OverwriteStart(var FHash : TFormatHashTable;
                                 var WHash : TWidthHashTable;
                                 GetColWidth : GetColWidthFunc;
                                 EndCol : Word;
                                 DisplayFormulas : Boolean) : Word;
var
  F : FormatType;
  C, Place : Word;
begin
  F := Format(FHash, DisplayFormulas);
  Place := 1;
  C := Loc.Col;
  repeat
    Inc(Place, GetColWidth(WHash, C));
    Inc(C);
  until C = EndCol;
  OverwriteStart := Place;
end; { TTextCell.OverwriteStart }

procedure TTextCell.EditString(MaxDecPlaces : Byte;
                              var Input : String);
begin
   Input := Txt.ToString;
end; { TTextCell.EditString }

function TTextCell.DisplayString(FormulasDisplayed : Boolean;
                                      MaxDecPlaces : Byte) : String;
begin
  DisplayString := Txt.Copy(2, (Txt.Length)-1);
end; { TTextCell.DisplayString }

function TTextCell.FormattedString(var OHash : TOverWriteHashTable;
                                  var FHash : TFormatHashTable;
                                  var WHash : TWidthHashTable;
                                  GetColWidth : GetColWidthFunc;
                                  CPos : CellPos;
                                  FormulasDisplayed : Boolean;
                                  Start : Word; ColWidth : Byte;
                                  var CurrencyString : CurrencyStr;
                                  var ClType: CellTypes): String;
begin
  ClType := CellType;
  CurrencyString := '';
  FormattedString := Txt.Copy(Succ(Start), ColWidth);
end; { TTextCell.FormattedString }

function TTextCell.CopyString : String;
begin
  CopyString := Txt.ToString;
end; { TTextCell.CopyString }

constructor TTextCell.Load(var S : TStream);
begin
  S.Read(Loc, SizeOf(Loc));
  Txt.Load(S);
end; { TTextCell.Load }

procedure TTextCell.Store(var S : TStream);
begin
  S.Write(Loc, SizeOf(Loc));
  Txt.Store(S);
end; { TTextCell.Store }

destructor TTextCell.Done;
begin
   Txt.Done;
end;



{** TFormulaCell **}

constructor TFormulaCell.Init(InitLoc : CellPos; InitError : Boolean;
                             InitValue : Extended; InitFormula : String);
begin
  TCell.Init(InitLoc);
  Formula.Init;
  Formula.FromString(InitFormula);
  Error := InitError;
  Value := InitValue;
end; { TFormulaCell.Init }

function TFormulaCell.CellType : CellTypes;
begin
  CellType := ClFormula;
end; { TFormulaCell.CellType }

function TFormulaCell.LegalValue : Boolean;
begin
  LegalValue := True;
end; { TFormulaCell.LegalValue }

function TFormulaCell.Name : String;
begin
  Name := GLStringList^.Get(sFormulaCellName);
end; { TFormulaCell.Name }

function TFormulaCell.Format(var FHash : TFormatHashTable;
                                FormulasDisplayed : Boolean) : FormatType;
var
  F : FormatType;
begin
  if FHash.Search(Loc, F) then
    Format := F
  else if FormulasDisplayed then
    Format := 0
  else
    Format := (Ord(JRight) shl 4) + DefaultDefaultDecimalPlaces;
end; { TFormulaCell.Format }

function TFormulaCell.Width(var FHash : TFormatHashTable;
                               FormulasDisplayed : Boolean) : Word;
var
  S : String;
  F : FormatType;
  P, W : Word;
begin
  if FormulasDisplayed then
    Width := Formula.Length
  else begin
    F := Format(FHash, FormulasDisplayed);
    Str(Value:1:(F and DecPlacesPart), S);
    W := Length(S);
    if (F and CurrencyPart) <> 0 then
      Inc(W, Length(DefaultCurrencyString));
    if (F and CommasPart) <> 0 then
    begin
      P := Pos('.', S);
      if P = 0 then
        P := Length(S);
      Inc(W, (P - 2) div 3);
    end;
    Width := W;
  end;
end; { TFormulaCell.Width }

function TFormulaCell.Overwritten(var CHash : TCellHashTable;
                                      var FHash : TFormatHashTable;
                                      var WHash : TWidthHashTable;
                                      var LastPos : CellPos;
                                      MaxCols : Word;
                                      GetColWidth : GetColWidthFunc;
                                      FormulasDisplayed : Boolean) : Word;
var
  CellWidth : Longint;
  Total : Word;
  P : CellPos;
begin
  P := Loc;
  CellWidth := Width(FHash, FormulasDisplayed);
  Total := 0;
  repeat
    Inc(Total);
    Dec(CellWidth, GetColWidth(WHash, P.Col));
    Inc(P.Col);
  until (CellWidth <= 0) or (P.Col > MaxCols) or (CHash.Search(P) <> Empty);
  Dec(Total);
  Overwritten := Total;
end; { TFormulaCell.Overwritten }

function TFormulaCell.ShouldUpdate : Boolean;
begin
  ShouldUpdate := True;
end; { TFormulaCell.ShouldUpdate }

function TFormulaCell.HasError : Boolean;
begin
  HasError := Error;
end; { TFormulaCell.HasError }

function TFormulaCell.CurrValue : Extended;
begin
  CurrValue := Value;
end; { TFormulaCell.CurrValue }

function TFormulaCell.OverwriteStart(var FHash : TFormatHashTable;
                                    var WHash : TWidthHashTable;
                                    GetColWidth : GetColWidthFunc;
                                    EndCol : Word;
                                    DisplayFormulas : Boolean) : Word;
var
  F : FormatType;
  C, Place : Word;
begin
  F := Format(FHash, DisplayFormulas);
  Place := 1;
  C := Loc.Col;
  repeat
    Inc(Place, GetColWidth(WHash, C));
    Inc(C);
  until C = EndCol;
  if (not DisplayFormulas) and ((F and CurrencyPart) <> 0) then
    Dec(Place, Length(DefaultCurrencyString));
  OverwriteStart := Place;
end; { TFormulaCell.OverwriteStart }

procedure TFormulaCell.EditString(MaxDecPlaces : Byte;
                                  var Input : String);
begin
   Input := Formula.ToString;
end; { TFormulaCell.EditString }

function TFormulaCell.DisplayString(FormulasDisplayed : Boolean;
                                         MaxDecPlaces : Byte) : String;
var
  S : String;
begin
  if not FormulasDisplayed then
    DisplayString := Formula.ToString
  else begin
    Str(Value:1:MaxDecPlaces, S);
    DisplayString := S;
  end;
end; { TFormulaCell.DisplayString }

function TFormulaCell.FormattedString(var OHash : TOverWriteHashTable;
                                     var FHash : TFormatHashTable;
                                     var WHash : TWidthHashTable;
                                     GetColWidth : GetColWidthFunc;
                                     CPos : CellPos;
                                     FormulasDisplayed : Boolean;
                                     Start : Word; ColWidth : Byte;
                                     var CurrencyString : CurrencyStr;
                                     var ClType: CellTypes): String;
var
  S : String;
  Counter : Word;
  F : FormatType;
begin
  ClType := CellType;
  if FormulasDisplayed then
  begin
    CurrencyString := '';
    FormattedString := Formula.Copy(Start, ColWidth);
  end
  else begin
    F := Format(FHash, FormulasDisplayed);
    Str(Value:1:F and DecPlacesPart, S);
    if (Start = 1) and ((F and CurrencyPart) <> 0) then
      CurrencyString := ' '+Char((F and CurrencyCharPart) shr 8)+' '
    else
      CurrencyString := '';
    if (F and CommasPart) <> 0 then
    begin
      Counter := Pos('.', S);
      if Counter = 0 then
        Counter := Length(S);
      while Counter > 4 do
      begin
        Insert(',', S, Counter - 3);
        Dec(Counter, 3);
      end;
    end;
    FormattedString := Copy(S, Start, ColWidth);
  end;
end; { TFormulaCell.FormattedString }

function TFormulaCell.CopyString : String;
begin
  CopyString := Formula.ToString;
end; { TFormulaCell.CopyString }

constructor TFormulaCell.Load(var S : TStream);
begin
  S.Read(Loc, SizeOf(Loc));
  Formula.Load(S);
end; { TFormulaCell.Load }

procedure TFormulaCell.Store(var S : TStream);
begin
  S.Write(Loc, SizeOf(Loc));
  Formula.Store(S);
end; { TFormulaCell.Store }

function TFormulaCell.GetFormula : String;
begin
  GetFormula := Formula.ToString;
end; { TFormulaCell.GetFormula }

destructor TFormulaCell.Done;
begin
   Formula.Done;
end;



{** TRepeatCell **}

constructor TRepeatCell.Init(InitLoc : CellPos; InitChar : Char);
begin
  TCell.Init(InitLoc);
  RepeatChar := InitChar;
end; { TRepeatCell.Init }

function TRepeatCell.CellType : CellTypes;
begin
  CellType := ClRepeat;
end; { TRepeatCell.CellType }

function TRepeatCell.LegalValue : Boolean;
begin
  LegalValue := False;
end; { TRepeatCell.LegalValue }

function TRepeatCell.Name : String;
begin
  Name := GLStringList^.Get(sRepeatCellName);
end; { TRepeatCell.Name }

function TRepeatCell.Format(var FHash : TFormatHashTable;
                               FormulasDisplayed : Boolean) : FormatType;
begin
  Format := 0;
end; { TRepeatCell.Format }

function TRepeatCell.Width(var FHash : TFormatHashTable;
                              FormulasDisplayed : Boolean) : Word;
begin
  Width := 2;
end; { TRepeatCell.Width }

function TRepeatCell.Overwritten(var CHash : TCellHashTable;
                                var FHash : TFormatHashTable;
                                var WHash : TWidthHashTable;
                                var LastPos : CellPos;
                                MaxCols : Word;
                                GetColWidth : GetColWidthFunc;
                                FormulasDisplayed : Boolean) : Word;
var
  Total : Word;
  P : CellPos;
begin
  P := Loc;
  Total := 0;
  repeat
    Inc(Total);
    Inc(P.Col);
  until (P.Col > LastPos.Col) or (CHash.Search(P) <> Empty) or
        (P.Col = 0);
  Dec(Total);
  if (P.Col > LastPos.Col) or (P.Col = 0) then
    Total := MaxCols - Loc.Col;
  Overwritten := Total;
end; { TRepeatCell.Overwritten }

function TRepeatCell.ShouldUpdate : Boolean;
begin
  ShouldUpdate := False;
end; { TRepeatCell.ShouldUpdate }

function TRepeatCell.HasError : Boolean;
begin
  HasError := False;
end; { TRepeatCell.HasError }

function TRepeatCell.CurrValue : Extended;
begin
  CurrValue := 0;
end; { TRepeatCell.CurrValue }

function TRepeatCell.OverwriteStart(var FHash : TFormatHashTable;
                                   var WHash : TWidthHashTable;
                                   GetColWidth : GetColWidthFunc;
                                   EndCol : Word;
                                   DisplayFormulas : Boolean) : Word;
begin
  OverwriteStart := 1;
end; { TRepeatCell.OverwriteStart }

procedure TRepeatCell.EditString(MaxDecPlaces : Byte;
                                var Input : String);
var
  Good : Boolean;
begin
  Input := RepeatFirstChar + RepeatChar;
end; { TRepeatCell.EditString }

function TRepeatCell.DisplayString(FormulasDisplayed : Boolean;
                                        MaxDecPlaces : Byte) : String;
begin
  DisplayString := FillString(ScreenCols, RepeatChar);
end; { TRepeatCell.DisplayString }

function TRepeatCell.FormattedString(var OHash : TOverWriteHashTable;
                                    var FHash : TFormatHashTable;
                                    var WHash : TWidthHashTable;
                                    GetColWidth : GetColWidthFunc;
                                    CPos : CellPos;
                                    FormulasDisplayed : Boolean;
                                    Start : Word; ColWidth : Byte;
                                    var CurrencyString : CurrencyStr;
                                    var ClType: CellTypes): String;
begin
  ClType := CellType;
  CurrencyString := '';
  FormattedString := PadChar('', RepeatChar, ColWidth);
end; { TRepeatCell.FormattedString }

function TRepeatCell.CopyString : String;
var
   Input : String;
begin
  EditString(0, Input);
  CopyString := Input;
end; { TRepeatCell.CopyString }

constructor TRepeatCell.Load(var S : TStream);
begin
  S.Read(Loc, SizeOf(Loc));
  S.Read(RepeatChar, SizeOf(RepeatChar));
end; { TRepeatCell.Load }

procedure TRepeatCell.Store(var S : TStream);
begin
  S.Write(Loc, SizeOf(Loc));
  S.Write(RepeatChar, SizeOf(RepeatChar));
end; { TRepeatCell.Store }


{** THeadersHashTable **}

constructor THeadersHashTable.Init(InitBuckets : BucketRange);
{ Initializes the column names hash table, which stores specific
  column namess, different to the normal letter headings }
begin
  if not THashTable.Init(InitBuckets) then
    Fail;
end; {...THeadersHashTable.Init }



function THeadersHashTable.Add(SCol : Word; NewName: String) : Boolean;
begin
  CurrCol := SCol;
  CurrName := NewName;
  Add := THashTable.Add;
end; {...THeadersHashTable.Add }



procedure THeadersHashTable.CreateItem(var Item : HashItemPtr);
begin
  Move(CurrCol, Item^.Data, SizeOf(CurrCol));
  Move(CurrName, Item^.Data[SizeOf(CurrCol)], SizeOf(CurrName));
end; {...THeadersHashTable.CreateItem }


procedure THeadersHashTable.Delete(Col : Word);
begin
  CurrCol := Col;
  THashTable.Delete(nil);
end; {...THeadersHashTable.Delete }



function THeadersHashTable.Found(Item : HashItemPtr) : Boolean;
var
  C : Word;
begin
  Move(Item^.Data, C, SizeOf(C));
  Found := CurrCol = C
end; {...THeadersHashTable.Found }



function THeadersHashTable.HashValue : LongInt;
begin
  HashValue := CurrCol;
end; {...THeadersHashTable.HashValue }



function THeadersHashTable.ItemSize : HashItemSizeRange;
begin
  ItemSize := SizeOf(CurrCol) + SizeOf(CurrName);
end; { THeadersHashTable.ItemSize }



procedure THeadersHashTable.Load(var S : TStream; Total : Longint);
var
  Counter : Longint;
  Col : Word;
  Header : String[80];
begin
  for Counter := 1 to Total do
  begin
    S.Read(Col, SizeOf(Col));
    S.Read(Header, SizeOf(Header));
    if not Add(Col, Header) then
    begin
      S.Error(stNoMemoryError, 0);
      Exit;
    end; {...if not Add(Col, Name) }
  end; {...for Counter }
end; {...THeadersHashTable.Load }



function THeadersHashTable.Search(Col : Word;
                               var Name: String) : Boolean;
var
  I : HashItemPtr;
begin
  CurrCol := Col;
  I := THashTable.Search;
  if I = NIL then
     Search := False
  else
     begin
        Search := True;
        Move(I^.Data[SizeOf(CurrCol)], Name, SizeOf(Name))
     end; {...else/if I = NIL }
end; {...THeadersHashTable.Search }



function THeadersHashTable.SearchName(Name: String;
                               var Col: Word): Boolean;
var
   H : HashItemPtr;
begin
   SearchName := False;
   Col := 0;
   H := FirstItem;
   while H <> NIL do
   begin
      Move(H^.Data[SizeOf(CurrCol)], CurrName, SizeOf(CurrName));
      if UpperCase(CurrName) = UpperCase(Name) then
         begin
            Move(H^.Data, CurrCol, SizeOf(CurrCol));
            Col := CurrCol;
            SearchName := True;
            H := NIL;
         end {...if UpperCase(CurrName) = UpperCase(Name) }
      else
         H := NextItem;
   end; {...while H <> NIL }
end; {...THeadersHashTable.SearchName }

procedure THeadersHashTable.Store(var S : TStream);
var
  H : HashItemPtr;
  Col : Word;
  Header : String[80];
begin
  H := FirstItem;
  while H <> nil do
  begin
    Move(H^.Data, Col, SizeOf(Col));
    S.Write(Col, SizeOf(Col));
    Move(H^.Data[SizeOf(Col)], Header, SizeOf(Header));
    S.Write(Header, SizeOf(Header));
    H := NextItem;
  end;
end; {...THeadersHashTable.Store }



destructor THeadersHashTable.Done;
begin
  THashTable.Done;
end; {...THeadersHashTable.Done }



{** TUnlockedHashTable **}

constructor TUnlockedHashTable.Init;
{ Inits a TBlockedCellHashTable that keeps track of which cells are
  marked as LOCKED }
begin
   if not HashTable.Init(1) then
      Fail;
end; {...TUnlockedHashTable.Init }



function TUnlockedHashTable.Add(NewStart, NewStop: CellPos): Boolean;
{ Adds a group of cells to the hash table.  If it is found in this
  hash table, then the cell is considered locked }
begin
   if (not Search(NewStart)) or (not Search(NewStop)) then
   begin
      if not Overwrite(NewStart, NewStop) then
      begin
         Add := False;
         Exit;
      end; {...if not Overwrite(NewStart, NewStop) }
      CurrStart := NewStart;
      CurrStop := NewStop;
      Add := HashTable.Add;
   end; {...if (not Search(NewStart) or (not Search(NewStop)) }
end; {...TUnlockedHashTable.Add }



procedure TUnlockedHashTable.CreateItem(var Item: HashItemPtr);
begin
  with Item^ do
  begin
    Move(CurrStart, Data, SizeOf(CellPos));
    Move(CurrStop, Data[SizeOf(CellPos)], SizeOf(CellPos));
  end; {...with Item^ }
end; {...TUnlockedHashTable.CreateItem }



function TUnlockedHashTable.Delete(DStart, DStop: CellPos): Boolean;
begin
   Delete := Overwrite(DStart, DStop);
end; {...TUnlockedHashTable.Delete }



function TUnlockedHashTable.Found(Item: HashItemPtr): Boolean;
var
  P : CellPos;
  B : TBlock;
  Start, Stop : CellPos;
  Good : Boolean;
begin
  Move(Item^.Data, Start, SizeOf(CellPos));
  Move(Item^.Data[SizeOf(CellPos)], Stop, SizeOf(CellPos));
  B.Init(Start);
  B.Stop := Stop;
  Found := B.CellInBlock(CurrStart);
end; {...TUnlockedHashTable.Found }



function TUnlockedHashTable.HashValue : LongInt;
begin
   HashValue := 1;
end; {...TUnlockedHashTable.HashValue }



function TUnlockedHashTable.ItemSize : HashItemSizeRange;
begin
   ItemSize := (SizeOf(CellPos) shl 1);
end; {...TUnlockedHashTable.ItemSize }


constructor TUnlockedHashTable.Load(var S: TStream; Total: Longint);
var
   Counter : LongInt;
   C1, C2 : CellPos;
begin
   for Counter := 1 to Total do
   begin
      S.Read(C1, SizeOf(C1));
      S.Read(C2, SizeOf(C2));
      if not Add(C1, C2) then
      begin
         S.Error(stNoMemoryError, 0);
         Exit;
      end; {...if not Add(C1, C2) }
   end; {...for Counter }
end; {...TUnlockedHashTable.Load }




function TUnlockedHashTable.Overwrite(NewStart, NewStop : CellPos) : Boolean;
{ Checks to see if a new locked area has overwritten an old one, requiring
  the old area to be overwritten or broken into parts }
var
  H, Next : HashItemPtr;
  AStart, AStop, BStart, BStop : CellPos;
  F : FormatType;
  P : CellPos;
  Added : Boolean;
begin
  Overwrite := False;
  H := HashData^[1];
  while H <> nil do
  begin
    Next := H^.Next;
    Move(H^.Data, BStart, SizeOf(CellPos));
    Move(H^.Data[SizeOf(CellPos)], BStop, SizeOf(CellPos));
    if ((((NewStart.Col >= BStart.Col) and (NewStart.Col <= BStop.Col)) or
         ((NewStop.Col >= BStart.Col) and (NewStop.Col <= BStop.Col))) and
        (((NewStart.Row >= BStart.Row) and (NewStart.Row <= BStop.Row)) or
         ((NewStop.Row >= BStart.Row) and (NewStop.Row <= BStop.Row)))) or
       ((((BStart.Col >= NewStart.Col) and (BStart.Col <= NewStop.Col)) or
         ((BStop.Col >= NewStart.Col) and (BStop.Col <= NewStop.Col))) and
        (((BStart.Row >= NewStart.Row) and (BStart.Row <= NewStop.Row)) or
         ((BStop.Row >= NewStart.Row) and (BStop.Row <= NewStop.Row)))) then
    begin
      Move(H^.Data[SizeOf(CellPos) shl 1], F, SizeOf(F));
      CurrStart := BStart;
      CurrStop := BStop;
      THashTable.Delete(nil);
      if BStart.Row < NewStart.Row then
      begin
        AStart := BStart;
        AStop.Col := BStop.Col;
        AStop.Row := Pred(NewStart.Row);
        if not Add(AStart, AStop) then
          Exit;
      end;
      if BStop.Row > NewStop.Row then
      begin
        AStart.Col := BStart.Col;
        AStart.Row := Succ(NewStop.Row);
        AStop.Col := BStop.Col;
        AStop.Row := BStop.Row;
        if not Add(AStart, AStop) then
          Exit;
      end;
      if BStart.Col < NewStart.Col then
      begin
        AStart.Col := BStart.Col;
        AStart.Row := Max(BStart.Row, NewStart.Row);
        AStop.Col := Pred(NewStart.Col);
        AStop.Row := Min(BStop.Row, NewStop.Row);
        if not Add(AStart, AStop) then
          Exit;
      end;
      if BStop.Col > NewStop.Col then
      begin
        AStart.Col := Succ(NewStop.Col);
        AStart.Row := Max(BStart.Row, NewStart.Row);
        AStop.Col := BStop.Col;
        AStop.Row := Min(BStop.Row, NewStop.Row);
        if not Add(AStart, AStop) then
          Exit;
      end;
    end;
    H := Next;
  end;
  Overwrite := True;
end; {...TUnlockedHashTable.Overwrite }



function TUnlockedHashTable.Search(SPos: CellPos): Boolean;
var
   H : HashItemPtr;
begin
   CurrStart := SPos;
   H := HashTable.Search;
   if H = NIL then
      Search := False
   else
      Search := True;
end; {...TUnlockedHashTable.Search }



procedure TUnlockedHashTable.Store(var S: TStream);
var
   H : HashItemPtr;
   C : CellPos;
begin
   H := FirstItem;
   while H <> NIL do
   begin
      Move(H^.Data, C, SizeOf(C));
      S.Write(C, SizeOf(C));
      Move(H^.Data[SizeOf(CellPos)], C, SizeOf(C));
      S.Write(C, SizeOf(C));
      H := NextItem;
   end; {...while H <> NIL }
end; {...TUnlockedHashTable.Store }

destructor TUnlockedHashTable.Done;
begin
   HashTable.Done;
end; {...TUnlockedHashTable.Done }


{****************************************************************************}
{**                            Exit Procedure                              **}
{****************************************************************************}

procedure CellExit;
{ Removes Empty cell from memory, restores ExitProc }
begin
  Dispose(Empty, Done);
  ExitProc := SavedExitProc;
end; { CellExit }

{****************************************************************************}
{**                    Unit's initialization Section                       **}
{****************************************************************************}

begin
  SavedExitProc := ExitProc;
  ExitProc := @CellExit;
  Empty := New(PEmptyCell, Init);
end.