{********************************************************************

  OOGrid Library(TM) for Borland/Turbo Pascal (Real Mode/TV)
  Copyright (C) 1994 by Arturo J. Monge
  Portions Copyright (C) 1989,1990 Borland International, Inc.

  OOGrid Library(TM) Window Unit:
    Implementation of a TWindow's descendant that can own
    a TSpreadSheet.

  Copyright (C) 1994 by Arturo J. Monge

  Last Modification : December 29th, 1994

*********************************************************************}

{$O+,F+}

unit GLWindow;

{****************************************************************************}
                                 interface
{****************************************************************************}

uses Objects, Views, GLViews;

const

{ Color Palettes }

{ Application palettes - must be added to the standard application palette - }

CSpreadSheetColor      = #$1F#$1F#$1F#$1F#$1E#$3F#$3F#$17#$1F#$7F#$7F#$7F#$2F+
                         #$3F#$70#$7F#$2F#$4F#$74#$7F#$2F#$BF#$F0#$FF#$AF;
CSpreadSheetBlackWhite = #$0F#$0F#$0F#$0F#$07#$0F#$0F#$07#$0F#$7F#$7F#$7F#$0F+
                         #$0F#$70#$7F#$0F#$7F#$7F#$7F#$0F#$8F#$F0#$FF#$8F;
CSpreadSheetMonochrome = #$0F#$0F#$0F#$0F#$07#$0F#$0F#$07#$0F#$70#$70#$70#$0F+
                         #$0F#$07#$70#$0F#$70#$0F#$80#$0F#$8F#$8F#$F0#$8F;

{ TSpreadSheetWindow palette for use without the help file }
{ This is the one used in the TSpreadSheetWindow object }

CSpreadSheetWindow1 = #50#51#52#64#65#66#67#68#69#70#71#72#73#74#75#76+
                      #77#78#79#80#81#82#83#84#85#86#87#88;

{ TSpreadSheetWindow palette for use with the help file }

CSpreadSheetWindow2 = #50#51#52#72#73#74#75#76#77#78#79#80#81#82#83#84+
                      #85#86#87#88#89#90#91#92#93#94#95#96;

{ TSpreadSheetWindow palette layout }

  { 1..8 = Blue Window palette }
  { 9 = Inputline Normal }
  { 10 = Inputline Selected }
  { 11 = Inputline Arrows }
  { 12 = Empty Cell }
  { 13 = Value Cell }
  { 14 = Text Cell }
  { 15 = Repeat Cell }
  { 16 = Formula Cell }
  { 17 = Column headers }
  { 18 = Row numbers }
  { 19 = Cell Data Area }
  { 20 = Cell Contents Area }
  { 21 = Spreadsheet Info Area }
  { 22 = Cell in Block }
  { 23 = Cell Highlighted }
  { 24 = Cell Highlighted in Block }
  { 25 = Unlocked Cell }
  { 26 = Unlocked Cell in Block }
  { 27 = Unlocked Cell Highlighted }
  { 28 = Unlocked Cell Highlighted in Block }
  { 29 = Cell Error }
  { 30 = Cell Error in Block }
  { 31 = Cell Error Highlighted }
  { 32 = Cell Error Highlighted in Block }
  { 33 = Unlocked Cell Error }
  { 34 = Unlocked Cell Error in Block }
  { 35 = Unlocked Cell Error Highlighted }
  { 36 = Unlocked Cell Error Highlighted in Block }



type

  PSpreadSheetWindow = ^TSpreadSheetWindow;
  TSpreadSheetWindow = object(TWindow)
  { A TWindow's descendant that can own a TSpreadSheet object }
    constructor Init(Bounds: TRect; ATitle: String; ANumber: Integer);
    function GetPalette: PPalette; virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    function StandardScrollBar(AOptions : Word): PLimScrollBar;
  end; {...TSpreadSheetWindow }

{****************************************************************************}
                               implementation
{****************************************************************************}

uses App, Drivers, GLSupprt;

{** TSpreadSheet Window **}

constructor TSpreadSheetWindow.Init(Bounds: TRect; ATitle: String;
            ANumber: Integer);
begin
  TWindow.Init(Bounds, ATitle, ANumber);
  Options := Options or ofTileable;
end; {...TSpreadSheetWindow.Init }


function TSpreadSheetWindow.GetPalette: PPalette;
{ Extends the palette for a blue window to include the entries used by
  the TSpreadSheet object }
const
  CNewPalette = CBlueWindow + CSpreadSheetWindow1;
  PNewPalette : string[Length(CNewPalette)] = CNewPalette;
begin
  GetPalette := @PNewPalette;
end; {...TSpreadSheetWindow.GetPalette }


procedure TSpreadSheetWindow.SizeLimits(var Min, Max: TPoint);
{ Returns the size limits of the window taking into account the size limits
  of a spreadsheet }
begin
  Min.X := 18;
  Min.Y := 7;
  Max := Owner^.Size;
end; {...TSpreadSheetWindow.SizeLimits }


function TSpreadSheetWindow.StandardScrollBar(AOptions : Word): PLimScrollBar;
{ Returns a pointer to a limited scrolling scrollbar }
var
  Bounds, R : TRect;
  ScrollBar : PLimScrollBar;
begin
  GetExtent(Bounds);
  if (AOptions and sbVertical) <> 0 then
    begin
      Move(Bounds, R, Sizeof(Bounds));
      R.A.X := R.B.X - 1;
      Inc(R.A.Y);
      Dec(R.B.Y);
      ScrollBar := New(PLimScrollBar, Init(R, DefaultVScrollBarLimit));
      ScrollBar^.EventMask := evMouseDown;
      StandardScrollBar := ScrollBar;
      Insert(ScrollBar);
    end {...if (AOptions and sbVertical) <> 0 }
  else if (AOptions and sbHorizontal) = 0 then
    begin
      Move(Bounds, R, Sizeof(Bounds));
      R.A.Y := R.B.Y - 1;
      Inc(R.A.X, 2);
      Dec(R.B.X, 2);
      ScrollBar := New(PLimScrollBar, Init(R, DefaultHScrollBarLimit));
      ScrollBar^.EventMask := evMouseDown;
      StandardScrollBar := ScrollBar;
      Insert(ScrollBar);
    end; {...else if (AOptions and sbHorizontal) = 0 }
end; {...TSpreadSheetWindow.StandardScrollBars }

end.