(***************************************************************************
  ScrollingBar, a Scrollbar that updates its owner while dragging
  PJB October 26, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright 1993, All Rights Reserved. Portions Copyright Borland.
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  AAARGH! Lots of duplicated code due to Borland's use of the
  private keyword.

***************************************************************************)
unit Scroll;
{$B-,X+}

interface

  uses
    App, Dialogs, Drivers, Objects, Views;

  type
    PScrollingBar = ^TScrollingBar;
    TScrollingBar =
      object (TScrollbar)
        procedure HandleEvent(var Event: TEvent); virtual;
        function  GetPos: Integer;
        function  GetSize: Integer;
      end;

  procedure OnlyScrollingBars;


(***************************************************************************
***************************************************************************)
implementation


  (*******************************************************************
    Make all scrollbars work like scrolling bars
    Modifies the VMT in the data segment
  *******************************************************************)
  procedure OnlyScrollingBars;
    const
      idxHev = 14;
    type
      LongArr = array [0..20] of Longint;
  begin
    LongArr(TypeOf(TScrollBar)^)[idxHev]:=LongArr(TypeOf(TScrollingBar)^)[idxHev];
  end;


    (*******************************************************************
    *******************************************************************)

  (*******************************************************************
    Thumb position
  *******************************************************************)
  function TScrollingBar.GetPos: Integer;
    var
      R: Integer;
  begin
    R := Max - Min;
    if R = 0 then
      GetPos := 1
    else
      GetPos := LongDiv(LongMul(Value-Min, GetSize-3)+R shr 1, R)+1;
  end;


  (*******************************************************************
    Size of scrollbar
  *******************************************************************)
  function TScrollingBar.GetSize: Integer;
    var
      S: Integer;
  begin
    if Size.X = 1 then S := Size.Y else S := Size.X;
    if S < 3 then GetSize := 3 else GetSize := S;
  end;


  (*******************************************************************
    Handle mouse events differently
  *******************************************************************)
  procedure TScrollingBar.HandleEvent(var Event: TEvent);
    var
      Mouse    : TPoint;
      Extent   : TRect;
      I, S     : Integer;
      OldValue : Integer;

    function GetPartCode:Integer;
      var
        Mark : Integer;
    begin
      GetPartCode := -1;
      if Extent.Contains(Mouse) then
      begin
        if Size.X = 1 then
          Mark := Mouse.Y
        else
          Mark := Mouse.X;

        if Mark = GetPos then
          GetPartCode := sbIndicator;
      end;
    end;

  begin
    if Event.What=evMouseDown then
    begin
      MakeLocal(Event.Where, Mouse);
      GetExtent(Extent);
      Extent.Grow(1, 1);
      S := GetSize - 1;

      if GetPartCode = sbIndicator then
      begin
        Message(Owner, evBroadcast, cmScrollBarClicked, @Self);
        OldValue:=Value;
        repeat
          MakeLocal(Event.Where, Mouse);

          if Extent.Contains(Mouse) then
          begin
            if Size.X = 1 then
              I := Mouse.Y
            else
              I := Mouse.X;
            if I <= 0 then I := 1;
            if I >= S then I := S - 1;
            SetValue(LongDiv(LongMul(I-1, Max-Min)+(S-2) shr 1, S-2)+Min);
          end
          else
            SetValue(OldValue);
        until not MouseEvent(Event, evMouseMove);
        ClearEvent(Event);
        Exit;
      end;
    end;

    inherited HandleEvent(Event);
  end;


end.