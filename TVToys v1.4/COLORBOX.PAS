(***************************************************************************
  ColorBox unit
  Color selection dialog with instant updates and color propagation
  PJB December 6, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright PJB 1993, All Rights Reserved.
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  Color propagation is the FAST way to change the color scheme, it
  maintains the same background color for a number of objects in windows
  and dialogs. It is used by default.

  The WindowColorItems and the RegisterColorSel are redefinitions of the
  ColorSel one, so you have to put this unit after ColorSel in the uses
  list or use qualified names.

***************************************************************************)
unit ColorBox;

interface

  uses
    App, ColorSel, Dialogs, Drivers, Memory, Objects, Views,
    toyPrefs, TVUtils;

  type
    PColorBox = ^TColorBox;
    TColorBox =
      object (TColorDialog)
        OldPal      : TPalette;
        Propagation : PCheckBoxes;
        constructor Init(AGroups: PColorGroup);
        procedure HandleEvent(var Event:TEvent); virtual;
        procedure Propagate(Start:Integer);
      end;

  const
    (* Dangerous(?) redefinitions for improved WindowColorItems *)
    wpBlueWindow = 8;
    wpCyanWindow = 16;
    wpGrayWindow = 24;
    wpHelpWindow = 128;

  (* Reusable redefinition *)
  function WindowColorItems(Offset:Word; const Next:PColorItem):PColorItem;
  function HelpColorItems(Next:PColorGroup):PColorGroup;

  procedure RegisterColorSel;


(***************************************************************************
***************************************************************************)
implementation


  (*******************************************************************
    Improved to handle HelpFile as well
  *******************************************************************)
  function WindowColorItems(Offset:Word; const Next:PColorItem):PColorItem;
  begin
    WindowColorItems :=
      ColorItem('Frame passive',     Offset + 0,
      ColorItem('Frame active',      Offset + 1,
      ColorItem('Frame icons',       Offset + 2,
      ColorItem('Scroll bar page',   Offset + 3,
      ColorItem('Scroll bar icons',  Offset + 4,
      ColorItem('Normal text',       Offset + 5,
      Next))))));
  end;


  (*******************************************************************
    Help window color group
  *******************************************************************)
  function HelpColorItems(Next:PColorGroup):PColorGroup;
  begin
    HelpColorItems:=ColorGroup('Help',
      WindowColorItems(wpHelpWindow,
        ColorItem('Keyword', 134,
        ColorItem('Selected', 135,
        Nil))),
      Next);
  end;


(***************************************************************************
***************************************************************************)

  (*******************************************************************
    Background color links
  *******************************************************************)
  const
    A = 32;
    B = 64;
    C = 96;

    Links : array [1..135] of Byte = (
      1,                         (* Background 1 *)
      3,4,2,7,6,5,               (* Menu and status line 2-7 *)
      9,10,8,11,12,13,14,15,     (* Blue window 8-15 *)
      17,18,16,19,20,21,22,23,   (* Cyan window 16-23 *)
      25,26,24,27,28,29,30,31,   (* Gray window 24-31 *)

      (* Gray dialog *)
      A+1,A+2,A+5,               (* Frame 1-3 *)
      A+3,A+4,                   (* Scrollbar 4-5 *)
      A+6,                       (* Static text 6 *)
      A+7,A+8,A+14,              (* Label 7-9 *)
      A+10,A+11,A+13,A+12,A+9,   (* Buttons 10-14 *)
      A+22,                      (* Button shadow 15 *)
      A+16,A+17,A+15,            (* Cluster 16-18 *)
      A+18,A+19,A+20,            (* Input line 19-21 *)
      A+21,A+0,A+23,A+24,        (* History 22-25 *)
      A+27,A+26,A+28,A+25,       (* List viewer 26-29 *)
      A+29,A+30,A+31,            (* Info pane 30, reserved 31-32 *)

      (* Blue dialog *)
      B+1,B+2,B+5,               (* Frame 1-3 *)
      B+3,B+4,                   (* Scrollbar 4-5 *)
      B+6,                       (* Static text 6 *)
      B+7,B+8,B+14,              (* Label 7-9 *)
      B+10,B+11,B+13,B+12,B+9,   (* Buttons 10-14 *)
      B+22,                      (* Button shadow 15 *)
      B+16,B+17,B+15,            (* Cluster 16-18 *)
      B+18,B+19,B+20,            (* Input line 19-21 *)
      B+21,B+0,B+23,B+24,        (* History 22-25 *)
      B+27,B+26,B+28,B+25,       (* List viewer 26-29 *)
      B+29,B+30,B+31,            (* Info pane 30, reserved 31-32 *)

      (* Cyan dialog *)
      C+1,C+2,C+5,               (* Frame 1-3 *)
      C+3,C+4,                   (* Scrollbar 4-5 *)
      C+6,                       (* Static text 6 *)
      C+7,C+8,C+14,              (* Label 7-9 *)
      C+10,C+11,C+13,C+12,C+9,   (* Buttons 10-14 *)
      C+22,                      (* Button shadow 15 *)
      C+16,C+17,C+15,            (* Cluster 16-18 *)
      C+18,C+19,C+20,            (* Input line 19-21 *)
      C+21,C+0,C+23,C+24,        (* History 22-25 *)
      C+27,C+26,C+28,C+25,       (* List viewer 26-29 *)
      C+29,C+30,C+31,            (* Info pane 30, reserved 31-32 *)

      (* Help window 128-135 *)
      129,130,133,               (* Frame 128-130 *)
      131,132,                   (* Scrollbar 131-132 *)
      134,128,135                (* Normal, Keyword, Selected 133-135 *)
    );


  (*******************************************************************
    Palette changer
  *******************************************************************)
  procedure SetPalette(const Pal:TPalette);
  begin
    Application^.GetPalette^:=Pal;
    DoneMemory;
    Application^.Redraw;
  end;


  (*******************************************************************
    Initialize
  *******************************************************************)
  constructor TColorBox.Init;
    var
      R : TRect;
  begin
    inherited Init(Application^.GetPalette^, AGroups);
    OldPal:=Pal;

    AddHelpCtx(@Self, PWord(@ColorSelHelpCtxList));

    R.Assign(3, 15, 26, 16);
    New(Propagation, Init(R, NewSItem('~C~olor propagation', Nil)));
    Propagation^.HelpCtx:=hctoyCSPropagation;
    if ColorPropagation then
      Propagation^.Press(0);
    Insert(Propagation);
  end;


  (*******************************************************************
    Capture color updates
  *******************************************************************)
  procedure TColorBox.HandleEvent;
    var
      i    : Integer;
      Save : TPalette;
  begin
    if (Event.What=evBroadcast) and ((Event.Command=cmColorForegroundChanged)
         or (Event.Command=cmColorBackgroundChanged)) then
    begin
      (* Save current state *)
      Save:=Pal;
      inherited HandleEvent(Event);

      if Propagation^.Mark(0) then           (* Propagate *)
        for i:=1 to Length(Save) do          (* Find change *)
          if Save[i]<>Pal[i] then
          begin
            Propagate(i);
            Break;
          end;

      SetPalette(Pal);                       (* Instant update *)
    end
    else
    begin
      (* Revert *)
      if (Event.What=evCommand) and (Event.Command=cmCancel) then
        SetPalette(OldPal);
      inherited HandleEvent(Event);
    end;
  end;


  (*******************************************************************
    Propagate change
  *******************************************************************)
  procedure TColorBox.Propagate;
    var
      i   : Integer;
      Col : Byte;
      P   : array [0..255] of Byte ABSOLUTE Pal;
  begin
    i:=Links[Start];
    Col:=P[Start] and $70;

    (* Take care of history button *)
    case Start of
      53,53+32,53+64:
        P[Start+1]:=P[Start+1] and $F0 or Col shr 4;
      54,54+32,54+64:
        P[Start-1]:=P[Start-1] and $07 or P[Start] and 7 shl 4;
    end;

    while i<>Start do
    begin
      P[i]:=P[i] and $8F or Col;
      i:=Links[i];
    end;
  end;


    (*******************************************************************
    *******************************************************************)

  procedure RegisterColorSel;
  begin
    RegisterType(RColorSelector);
    RegisterType(RMonoSelector);
    RegisterType(RColorDisplay);
    RegisterType(RColorGroupList);
    RegisterType(RColorItemList);
    RegisterType(RColorDialog);
  end;


    (*******************************************************************
    *******************************************************************)

end.