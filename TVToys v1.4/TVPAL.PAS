(***************************************************************************
  TV Palette unit
  Dialog with palette entry sliders and inputlines
  PJB December 14, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright PJB 1993, All Rights Reserved.
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  The general idea is to switch to HSV instead of RGB.

***************************************************************************)
unit TVPal;
{$I toyCfg}

{$O+,X+}

interface

  uses
    ColorSel, Dialogs, Drivers, Objects, Validate, Views,
    toyPrefs, {$I hcFile}
    Pal, Scroll, TVUtils;

  type
    (* What kind of scrollbars do we want for palette selection?
       Defaults to instant updating PScrollingBar *)
    ScrollType = PScrollingBar;

    VideoPaletteDataRec =
      record
        Red   : Longint;
        Green : Longint;
        Blue  : Longint;
      end;

    PVideoPaletteDialog = ^TVideoPaletteDialog;
    TVideoPaletteDialog =
      object (TDialog)
        Color    : Byte;
        Red      : ScrollType;
        Green    : ScrollType;
        Blue     : ScrollType;
        OldPal   : RGBPalette;
        constructor Init(AColor:Integer);
        constructor Load(var S:TStream);
        procedure HandleEvent(var Event:TEvent); virtual;
        procedure Store(var S:TStream);
      end;

  var
    VideoPaletteData : VideoPaletteDataRec;

  procedure ReloadPalette;


(***************************************************************************
***************************************************************************)
implementation


  (*******************************************************************
    Reload the palette
  *******************************************************************)
  procedure ReloadPalette;
  begin
    VideoPalette.SetRGB(VideoPalette.RGB);
  end;


(***************************************************************************
***************************************************************************)

  constructor TVideoPaletteDialog.Init;
    procedure Add(y:Integer; Text:String; var P:ScrollType; hc:Word);
      const
        X = 18;
      var
        R : TRect;
        Control : PView;
    begin
      R.Assign(X+6, y, 57, y+1);
      New(P, Init(R));
      P^.SetRange(0,63);
      Insert(P);

      R.Assign(X, y, X+4, y+1);
      Control:=New(PInputLine, Init(R, 2));
      Control^.HelpCtx:=hc;
      Insert(Control);

      PInputLine(Control)^.Validator:=New(PSliderValidator, Init(0, 63, P));
      PInputLine(Control)^.Validator^.Options:=voTransfer;

      R.Assign(X-1, y-1, X+6, y);
      Insert(New(PLabel, Init(R, Text, Control)));
    end;

    var
      R : TRect;
      Control : PView;
  begin
    R.Assign(10, 4, 70, 18);
    inherited Init(R, 'Video Palette');
    Options:=Options or ofCenterX or ofCenterY;
    Color:=AColor;
    OldPal:=VideoPalette.RGB;

    R.Assign(3, 4, 15, 8);
    Control:=New(PColorSelector, Init(R, csForeground));
    Insert(Control);
    Dec(R.A.Y);
    R.B.Y:=4;
    Insert(New(PLabel, Init(R, '~C~olor', Control)));


    Add(4, '~R~ed', Red, hctoyVPRed);
    Add(6, '~G~reen', Green, hctoyVPGreen);
    Add(8, '~B~lue', Blue, hctoyVPBlue);


    R.Assign(13, 11, 23, 13);
    Control:=New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
    Control^.HelpCtx:=hcOK;
    Insert(Control);

    R.Assign(25, 11, 35, 13);
    Control:=New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
    Control^.HelpCtx:=hcCancel;
    Insert(Control);

    R.Assign(37, 11, 47, 13);
    Control:=New(PButton, Init(R, 'Help', cmHelp, bfGrabFocus));
    Control^.HelpCtx:=hctoyVPDialogHelp;
    Insert(Control);

    Message(@Self, evBroadcast, cmColorForegroundChanged, Pointer(Color));

    SelectNext(False);
  end;


  (*******************************************************************
    Load from stream
  *******************************************************************)
  constructor TVideoPaletteDialog.Load(var S:TStream);
  begin
    inherited Load(S);
    GetSubViewPtr(S, Red);
    GetSubViewPtr(S, Green);
    GetSubViewPtr(S, Blue);
  end;


  (*******************************************************************
    Respond to scrollbar changes
  *******************************************************************)
  var
    (* Well, hrrm, I couldn't solve this one *)
    Flag : Boolean;

  procedure TVideoPaletteDialog.HandleEvent(var Event:TEvent);
    var
      Temp : VideoPaletteDataRec;

    procedure Update;
    begin
      if not IgnoreSliderMessage then
      begin
        Temp.Red:=Red^.Value;
        Temp.Green:=Green^.Value;
        Temp.Blue:=Blue^.Value;

        SetData(Temp);
      end
      else
        GetData(Temp);

      with VideoPalette do
      begin
        RGB[Color].R:=Temp.Red;
        RGB[Color].G:=Temp.Green;
        RGB[Color].B:=Temp.Blue;
        SetRGB(RGB);
      end;
    end;

  begin
    if (Event.What=evCommand) and (Event.Command=cmCancel) then
      VideoPalette.SetRGB(OldPal);

    inherited HandleEvent(Event);

    if (Event.What=evBroadcast) then
      case Event.Command of
        cmScrollbarChanged:     if not Flag then Update;
        cmColorForegroundChanged:
          begin
            Color:=Event.InfoByte;
            with VideoPalette do
            begin
              Flag:=True;
              IgnoreSliderMessage:=True;
              Red^.SetValue(RGB[Color].R);
              Green^.SetValue(RGB[Color].G);
              Blue^.SetValue(RGB[Color].B);
              IgnoreSliderMessage:=False;
              Update;
              Flag:=False;
            end;
          end;
      end;
  end;


  (*******************************************************************
    Store on stream
  *******************************************************************)
  procedure TVideoPaletteDialog.Store(var S:TStream);
  begin
    inherited Store(S);
    PutSubViewPtr(S, Red);
    PutSubViewPtr(S, Green);
    PutSubViewPtr(S, Blue);
  end;


end.