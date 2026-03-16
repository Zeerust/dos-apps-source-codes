{********************************************************************

  OOGrid Library(TM) for Borland/Turbo Pascal (Real Mode/TV)
  Copyright (C) 1994, 1995 by Arturo J. Monge
  Portions Copyright (C) 1989,1990 Borland International, Inc.

  OOGrid Library(TM) Sort Unit:
    This unit implements an object that can sort a block
    of cells in a TCellHashTable object using three different
    sort keys in either ascending or desceding order.

  Copyright (C) 1994 by Arturo J. Monge

  Last Modification : December 29th, 1994

*********************************************************************}

{$O+,F+,N+,E+,X+}

unit GLSort;

{****************************************************************************}
                                 interface
{****************************************************************************}

uses Objects, Views, GLCell, GLSupprt;

type
  SortTypes = (Ascending, Descending);

  KeyPosition = (BeforePivot, SameAsPivot, AfterPivot);
  { Values returned after comparing a key with the pivot according
    to the sort order requested }

  KeyValue = record
  { Used to store the values to be compared }
     Error : Boolean;
     case CellType : CellTypes of
       ClText,
       ClRepeat : (StrValue: String);
       ClValue,
       ClFormula : (Value: Extended);
  end; {...KeyValue }


  PSortObject = ^TSortObject;
  TSortObject = object(TObject)
  { Will sort a block of cells in ascending or descending order,
    given up to three sort keys, using the QuickSort algorithm }
       KeySortOrder : array[1..3] of SortTypes;
       KeyCols : array[1..3] of Word;
       LastKey : Byte;
       SourceHash: PCellHashTable;
       CurrentKey, PivotFirstKey, PivotSecondKey, PivotThirdKey: KeyValue;
       SortBlock : TBlock;
    constructor Init(SourceCellHash: PCellHashTable);
    function CurrentKeyPosition(var ComparedRec, PivotRec: KeyValue;
      SortOrder: SortTypes): KeyPosition;
    function CurrentRowPosition(CurrRow: Word): KeyPosition;
    procedure FillKeyRec(SearchCell: CellPos; var KeyRecord: KeyValue);
    procedure QuickSort(FirstRow, LastRow: Word);
    function SetKeyArray(FirstKey, SecondKey, ThirdKey: Word;
      FirstOrder, SecondOrder, ThirdOrder: SortTypes) : Boolean;
    procedure SetPivot(Row: Word);
    procedure Sort(ASortBlock: TBlock;
      FirstKey: Word; AFirstKeySortOrder: SortTypes; SecondKey: Word;
      ASecondKeySortOrder: SortTypes; ThirdKey: Word;
      AThirdKeySortOrder: SortTypes);
    procedure SplitSortBlock(FirstRow, LastRow : Word; var LowFirstRow,
      LowLastRow, HighFirstRow, HighLastRow : Word);
    procedure SwapRows(Row1, Row2: Word);
  end; {...TSortObject }

var
  StandardSortObject : PSortObject;

{****************************************************************************}
                               implementation
{****************************************************************************}

uses TCUtil, MsgBox;

{****************************************************************************}
{**                              TSortObject                               **}
{****************************************************************************}

constructor TSortObject.Init(SourceCellHash: PCellHashTable);
begin
  TObject.Init;
  SourceHash := SourceCellHash;
end; {...TSortObject.Init }

function TSortObject.CurrentKeyPosition(var ComparedRec, PivotRec: KeyValue;
  SortOrder: SortTypes): KeyPosition;
{ Determines whether the compared record is smaller, equal or bigger than
  reference record }
var
  Smaller, Bigger : KeyPosition;
const
  Value : set of CellTypes = [ClValue, ClFormula];
  Text : set of CellTypes = [ClText, ClRepeat];
begin
  case SortOrder of
    Ascending :
      begin
        Smaller := BeforePivot;
        Bigger := AfterPivot;
      end; {...case SortOrder of Ascending }
    else
      begin
        Smaller := AfterPivot;
        Bigger := BeforePivot;
      end; {...case else }
  end; {..case SortOrder }
  if ComparedRec.Error and PivotRec.Error then
    CurrentKeyPosition := SameAsPivot
  else if ComparedRec.Error and (not PivotRec.Error) then
    CurrentKeyPosition := Bigger
  else if (not ComparedRec.Error) and PivotRec.Error then
    CurrentKeyPosition := Smaller
  else
    begin
      if ComparedRec.CellType <> PivotRec.CellType then
        begin
          if ((ComparedRec.CellType in Value) and (PivotRec.CellType
             in Text)) or (not (ComparedRec.CellType = ClEmpty) and
             (PivotRec.CellType = ClEmpty)) then
            CurrentKeyPosition := Smaller
          else
            CurrentKeyPosition := Bigger;
        end {...if ComparedRec.CellType <> PivotRec.CellType }
      else
        begin
          case ComparedRec.CellType of
            ClEmpty : CurrentKeyPosition := SameAsPivot;
            ClText, ClRepeat :
              begin
                if ComparedRec.StrValue < PivotRec.StrValue then
                  CurrentKeyPosition := Smaller
                else if ComparedRec.StrValue = PivotRec.StrValue then
                  CurrentKeyPosition := SameAsPivot
                else
                  CurrentKeyPosition := Bigger;
              end; {...case CellType of ClText, ClRepeat }
            else
              begin
                if ComparedRec.Value < PivotRec.Value then
                  CurrentKeyPosition := Smaller
                else if ComparedRec.Value = PivotRec.Value then
                  CurrentKeyPosition := SameAsPivot
                else
                  CurrentKeyPosition := Bigger;
              end; {...case else }
          end; {...case ComparedRec.CellType of }
        end; {...if/else }
    end; {...if/else }
end; {...TSortObject.CurrentKeyPosition }


function TSortObject.CurrentRowPosition(CurrRow: Word): KeyPosition;
{ Compares a row in the spreadsheet with the pivot row }
var
  CurrKey : Byte;
  CurrentPos: CellPos;
  Position : KeyPosition;
begin
  CurrentPos.Row := CurrRow;
  CurrentPos.Col := KeyCols[1];
  FillKeyRec(CurrentPos, CurrentKey);
  Position := CurrentKeyPosition(CurrentKey, PivotFirstKey, KeySortOrder[1]);
  if (Position <> SameAsPivot) or (LastKey = 1) then
    CurrentRowPosition := Position
  else
    begin
      CurrentPos.Col := KeyCols[2];
      FillKeyRec(CurrentPos, CurrentKey);
      Position := CurrentKeyPosition(CurrentKey, PivotSecondKey,
        KeySortOrder[2]);
      if (Position <> SameAsPivot) or (LastKey = 2) then
        CurrentRowPosition := Position
      else
        begin
          CurrentPos.Col := KeyCols[3];
          FillKeyRec(CurrentPos, CurrentKey);
          CurrentRowPosition := CurrentKeyPosition(CurrentKey, PivotThirdKey,
            KeySortOrder[3]);
        end; {...if/else }
    end; {...if/else }
end; {...TSortObject.CurrentRowPosition }


procedure TSortObject.FillKeyRec(SearchCell: CellPos; var KeyRecord: KeyValue);
{ Fills a KeyValue record with the necesary information about a cell }
var
  CellPtr : PCell;
begin
  CellPtr := SourceHash^.Search(SearchCell);
  with KeyRecord do
  begin
    Error := CellPtr^.HasError;
    CellType := CellPtr^.CellType;
    case CellType of
      ClText, ClRepeat : StrValue := UpperCase(CellPtr^.CopyString);
      ClFormula, ClValue : Value := CellPtr^.CurrValue;
    end; {...case CellType of }
  end; {...with KeyRecord }
end; {...TSortObject.FillKeyRec }


procedure TSortObject.QuickSort(FirstRow, LastRow: Word);
{ Sorts the cells between the firstrow and lastrow of a block of cells,
  using the quicksort algorithm }
var
  LowFirstRow, LowLastRow, HighFirstRow, HighLastRow: Word;
begin
  if FirstRow < LastRow then
  begin
    SplitSortBlock(FirstRow, LastRow, LowFirstRow, LowLastRow, HighFirstRow,
      HighLastRow);
    QuickSort(LowFirstRow, LowLastRow);
    QuickSort(HighFirstRow, HighLastRow);
  end; {...if FirstRow < LastRow }
end; {...TSortObject.QuickSort }


function TSortObject.SetKeyArray(FirstKey, SecondKey, ThirdKey: Word;
  FirstOrder, SecondOrder, ThirdOrder: SortTypes) : Boolean;
{ Puts each key column number and sort order in the KeyCols and KeySortOrder
  arrays respectively, and determines the number of valid keys }
var
  CurrKey : Byte;
begin
  CurrKey := 1;
  if FirstKey <> 0 then
  begin
    KeyCols[CurrKey] := FirstKey;
    KeySortOrder[CurrKey] := FirstOrder;
    Inc(CurrKey);
  end; {...if FirstKey <> 0 }
  if SecondKey <> 0 then
  begin
    KeyCols[CurrKey] := SecondKey;
    KeySortOrder[CurrKey] := SecondOrder;
    Inc(CurrKey);
  end; {...if SecondKey <> 0 }
  if ThirdKey <> 0 then
  begin
    KeyCols[CurrKey] := ThirdKey;
    KeySortOrder[CurrKey] := ThirdOrder;
    Inc(CurrKey);
  end; {...if ThirdKey <> 0 }
  LastKey := Pred(CurrKey);
  if LastKey = 0 then
    SetKeyArray := False
  else
    SetKeyArray := True;
end; {...TSortObject.SetKeyArray }


procedure TSortObject.SetPivot(Row: Word);
{ Fills each of the pivot keyvalue records }
var
  SearchCell: CellPos;
begin
  SearchCell.Row := Row;
  SearchCell.Col := KeyCols[1];
  FillKeyRec(SearchCell, PivotFirstKey);
  SearchCell.Col := KeyCols[2];
  FillKeyRec(SearchCell, PivotSecondKey);
  SearchCell.Col := KeyCols[3];
  FillKeyRec(SearchCell, PivotThirdKey);
end; {...TSortObject.SetPivot }


procedure TSortObject.Sort(ASortBlock: TBlock; FirstKey: Word;
  AFirstKeySortOrder: SortTypes; SecondKey: Word;
  ASecondKeySortOrder: SortTypes; ThirdKey: Word;
  AThirdKeySortOrder: SortTypes);
{ Sorts a list or block of cells in a cell hash table, using the QuickSort
  algorithm }
begin
  if not SetKeyArray(FirstKey, SecondKey, ThirdKey, AFirstKeySortOrder,
     ASecondKeySortOrder, AThirdKeySortOrder) then
    Exit;
  Move(ASortBlock, SortBlock, SizeOf(ASortBlock));
  QuickSort(SortBlock.Start.Row, SortBlock.Stop.Row);
end; {...TSortObject.Sort }



procedure TSortObject.SplitSortBlock(FirstRow, LastRow : Word;
  var LowFirstRow, LowLastRow, HighFirstRow, HighLastRow : Word);
{ Splits the block into two sub-blocks: one with rows that have key
  values smaller than the pivot's value and the other, with rows
  that have key values bigger than the pivot's value.  The block is
  not really divided;  this fuction just returns the values of the
  first and last rows of each virtual sub-block }
var
  i_row, j_row : word;
begin
  SetPivot(((FirstRow + LastRow) div 2));
  i_row := Pred(FirstRow);
  j_row := Succ(LastRow);
  repeat
    repeat
      Inc(i_row);
    until (CurrentRowPosition(i_row) in [AfterPivot, SameAsPivot]);
    repeat
      Dec(j_row);
    until (CurrentRowPosition(j_row) in [BeforePivot, SameAsPivot]);
    if (i_row < j_row) then
      SwapRows(i_row, j_row);
  until (i_row >= j_row);
  LowFirstRow := FirstRow;
  HighLastRow := LastRow;
  if (i_row = j_row) then
    begin
      LowLastRow := Pred(j_row);
      HighFirstRow := Succ(i_row);
    end {...if (i_row = j_row) }
  else
    begin
      LowLastRow := j_row;
      HighFirstRow := i_row;
    end; {...if/else }
end; {...TSortObject.SplitSortBlock }


procedure TSortObject.SwapRows(Row1, Row2 : Word);
{ Swaps the position of two rows in the spreadsheet }
var
  Deleted : Boolean;
  Pos : CellPos;
  DestCell, SrcCell : PCell;
begin
  with SourceHash^ do
  begin
    for Pos.Col := SortBlock.Start.Col to SortBlock.Stop.Col do
    begin
      Pos.Row := Row1;
      Delete(Pos, SrcCell);
      Pos.Row := Row2;
      Delete(Pos, DestCell);
      if SrcCell <> NIL then
      begin
        SrcCell^.Loc.Row := Row2;
        SourceHash^.Add(SrcCell);
      end; {...if SrcCell <> NIL }
      if DestCell <> NIL then
      begin
        DestCell^.Loc.Row := Row1;
        SourceHash^.Add(DestCell);
      end; {...if DestCell <> NIL }
    end; {...for Pos.Col }
  end; {...with SourceHash^ }
end; {...TSortObject.SwapRows }

{****************************************************************************}
{**                            Exit Procedure                              **}
{****************************************************************************}

var
  SavedExitProc : Pointer;

procedure GLSortExit; far;
begin
  Dispose(StandardSortObject, Done);
  ExitProc := SavedExitProc;
end; {...GLSortExit }

{****************************************************************************}
{**                    Unit's initialization Section                       **}
{****************************************************************************}

begin
  SavedExitProc := ExitProc;
  ExitProc := @GLSortExit;
  New(StandardSortObject, Init(NIL));
end. {...GLSort unit }
