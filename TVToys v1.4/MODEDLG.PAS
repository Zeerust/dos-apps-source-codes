(***************************************************************************
  ModeDialog unit
  A dialog displaying available video modes, supporting routines
  PJB August 30, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright PJB 1993, All Rights Reserved.
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  If you want to omit certain video modes from the list, change the
  AddMode procedure to include a test (e.g. if Columns<80 then Exit...)

  Turbo Vision works in 40 columns, but the SelectVideoMode dialog does
  not (it is too wide, selecting Preview will shrink the dialog).

  You can overlay this unit and put TSelectVideoModeDialog in a
  resource file. Here is what to do with a resource file:

    SetupVideoList;
    SelectVideoMode(PSelectVideoModeDialog(RezFile.Get('VideoModeDialog')));


  See VIDEOTST.PAS for a demonstration of this unit.

***************************************************************************)
unit ModeDlg;

{$I toyCfg}

{$B-,O+,Q-,T-,X+}

interface

  uses
    App, Dialogs, Drivers, Objects, Memory, MsgBox, Views,
    toyPrefs, {$I hcFile}
    TVVideo, Video;

  type
    PSelectVideoModeDialog = ^TSelectVideoModeDialog;
    TSelectVideoModeDialog =
      object (TDialog)
        VideoListBox : PListBox;
        constructor Init;
        constructor Load(var S:TStream);
        procedure HandleEvent(var Event:TEvent); virtual;
        procedure Store(var S:TStream);
      end;

  procedure StoreVideoModes(var S:TStream);
  procedure LoadVideoModes(var S:TStream);

  procedure Delay(Ticks:word);

  procedure SetupVideoList;
  function  HasToScan:Boolean;
  procedure SelectVideoModeDialog;
  procedure SelectVideoMode(P:PSelectVideoModeDialog);

  var
    (* SelectVideoModeDialog GetData/SetData operates on this *)
    VideoModeDataRec :
      record
        VideoListBox : TListboxRec;
      end;

    (* The ModeList array contains the actual video modes
       corresponding to the entries in the VideoList listbox *)
    ModeList  : array [0..MaxVideoModes] of Word;


 {$IFDEF StoreModeData}
  type
    ModeDataRec =
      record
        Columns    : Byte;
        Rows       : Byte;
        CharHeight : Byte;
        Color      : Boolean;
      end;

  var
    (* The ModeDataList array contains each video mode's
       width, height and character size for matching purposes *)
    ModeDataList : array [0..MaxVideoModes] of ModeDataRec;

  function FindSimilarVideoMode(Columns, Rows:Byte; Color:Boolean):Word;
 {$ENDIF}

(***************************************************************************
***************************************************************************)
implementation


  var
    (* AddMode adds new lines of video mode information to VideoList *)
    VideoList : PStringCollection;


  (*******************************************************************
    These routines save mode information on a stream. They are meant
    to be used with an init or configuration file
  *******************************************************************)
  procedure StoreVideoModes;
  begin
    S.Put(VideoList);
    S.Write(ModeList, SizeOf(ModeList));
   {$IFDEF StoreModeData}
    S.Write(ModeDataList, SizeOf(ModeDataList));
   {$ENDIF}
  end;

  procedure LoadVideoModes;
  begin
    VideoList:=PStringCollection(S.Get);
    S.Read(ModeList, SizeOf(ModeList));
   {$IFDEF StoreModeData}
    S.Read(ModeDataList, SizeOf(ModeDataList));
   {$ENDIF}
  end;



  (*******************************************************************
    Delay for Ticks 18ths of a second, calling Idle
  *******************************************************************)
  procedure Delay(Ticks:word);
    var
      Finish : Word;
  begin
    Finish:=MemW[Seg0040:$6C]+Ticks;
    while Finish-MemW[Seg0040:$6C]<=Ticks do
      Application^.Idle;
  end;


 {$IFDEF StoreModeData}
  (*******************************************************************
    Simple example of how to find a reasonably similar video mode
    Tries to weigh Width and Height differently.
  *******************************************************************)
  function FindSimilarVideoMode(Columns, Rows:Byte; Color:Boolean):Word;
    var
      Diff    : Word;
      OldDiff : Word;
      i       : Integer;
  begin
    FindSimilarVideoMode:=ScreenMode;
    OldDiff:=999;

    for i:=0 to VideoList^.Count-1 do
    begin
      Diff:=Abs(ModeDataList[i].Rows-Rows)+
            Abs(ModeDataList[i].Columns-Columns) div 2+
            20*Ord(ModeDataList[i].Color<>Color);
      if Diff<OldDiff then
      begin
        OldDiff:=Diff;
        FindSimilarVideoMode:=ModeList[i];
      end;
    end;
  end;
 {$ENDIF}


  (*******************************************************************
    This procedure will be called by Video.ScanEVGAModes with
    new mode information.
  *******************************************************************)
  procedure AddMode(Mode, Rows, Columns, CharHeight:Word; Color:boolean); far;
    const
      ColorStr : string[5] = 'color';
      MonoStr  : string[4] = 'mono';
      BWStr    : string[3] = 'b/w';
    var
      Params : array [0..4] of Longint;
      Line   : String;
      i      : Integer;
  begin
    if (Columns>=80) and (VideoList^.Count<=MaxVideoModes) then
    begin
      Params[0]:=Mode;
      Params[1]:=Columns;
      Params[2]:=Rows;
      Params[3]:=CharHeight;

      if Mode=smBW80 then
        Params[4]:=LongInt(@BWStr)
      else
        if Color then
          Params[4]:=LongInt(@ColorStr)
        else
          Params[4]:=LongInt(@MonoStr);

      FormatStr(Line, '%3xh  %3dx%-2d  %2dp  %s', Params);

      i:=VideoList^.Count;
      ModeList[i]:=Mode;

     {$IFDEF StoreModeData}
      ModeDataList[i].Columns:=Columns;
      ModeDataList[i].Rows:=Rows;
      ModeDataList[i].CharHeight:=CharHeight;
      ModeDataList[i].Color:=Color;
     {$ENDIF}

      VideoList^.Insert(NewStr(Line));
    end;
  end;


  (*******************************************************************
    Scan for video modes and add to VideoList
  *******************************************************************)
  procedure SetupVideoList;
  begin
    if VideoList=Nil then    (* Check for previous list... *)
    begin
      New(VideoList, Init(20,10));

     {$IFDEF VesaSupport}
      if VESA.VesaScanningPossible then
      begin
        (************************************************************
          Add standard modes if necessary, Marek Bojarski's idea
        ************************************************************)
        if not VESA.StandardInfoAvailable then
        begin
          HideMouse;
          ScanEVGAModes(0, StandardTextModes, AddMode);
          SetSpecialScreenMode(ScreenMode);
          ShowMouse;
        end;
        VESA.ScanVesaModes(AddMode)
      end
      else
     {$ENDIF}
      begin
        HideMouse;

        ScanEVGAModes(0, VGAModes, AddMode);

       {$IFDEF VesaSupport}   (* If not VesaScanningPossible *)
        if VESA.VesaVersion<>0 then
          ScanEVGAModes($100, VESAModes, AddMode);
       {$ENDIF}

        (* Restore Turbo Vision screen *)
        SetSpecialScreenMode(ScreenMode);
        ShowMouse;
      end;
    end;
    VideoModeDataRec.VideoListBox.List:=VideoList;
  end;


  (*******************************************************************
    Return True if there is no previous list of video modes
  *******************************************************************)
  function HasToScan:Boolean;
  begin
    HasToScan:=VideoList=Nil;
  end;


  (*******************************************************************
    Let the user select a video mode
  *******************************************************************)
  procedure SelectVideoModeDialog;
  begin
    SelectVideoMode(New(PSelectVideoModeDialog, Init));
  end;


  (*******************************************************************
    Dialog already created, now execute it
  *******************************************************************)
  procedure SelectVideoMode(P:PSelectVideoModeDialog);
    var
      i : Integer;
  begin
    for i:=0 to VideoList^.Count-1 do
      if ModeList[i]=ScreenMode then
        VideoModeDataRec.VideoListbox.Selection:=i;

    if Application^.ExecuteDialog(P, @VideoModeDataRec)=cmOK then
      if VideoList^.Count>0 then
        SetSpecialScreenMode(ModeList[VideoModeDataRec.VideoListBox.Selection]);
  end;



(***************************************************************************
  Here comes the dialog object
***************************************************************************)

  const                  (* Command number irrelevant since local *)
    cmPreview = 1000;
    cmRescan  = 1001;


  (*******************************************************************
    This procedure generated by Dialog Design 4.0 available by anonymous
    ftp to garbo.uwasa.fi  /pc/turbovis. Thanks to David Baldwin
  *******************************************************************)
  constructor TSelectVideoModeDialog.Init;
    var
      R : TRect;
      Control : PView;
  begin
    R.Assign(14, 3, 66, 20);
    inherited Init(R, 'Select Video Mode');
    Options := Options or ofCentered;

    R.Assign(32, 3, 33, 15);
    Control := New(PScrollBar, Init(R));
    Insert(Control);

    R.Assign(5, 3, 32, 15);
    VideoListBox := New(PListBox, Init(R, 1, PScrollbar(Control)));
    VideoListBox^.HelpCtx := hctoyVideoListBox;
    Insert(VideoListBox);

    R.Assign(4, 2, 16, 3);
    Insert(New(PLabel, Init(R, '~V~ideo modes', VideoListBox)));

    R.Assign(37, 3, 48, 5);
    Control := New(PButton, Init(R, '~P~review', cmPreview, bfDefault));
    Control^.HelpCtx := hctoyVideoPreview;
    Insert(Control);

    R.Assign(37, 6, 48, 8);
    Control := New(PButton, Init(R, 'O~K~', cmOK, bfNormal));
    Control^.HelpCtx := hcOK;
    Insert(Control);

    R.Assign(37, 8, 48, 10);
    Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
    Control^.HelpCtx := hcCancel;
    Insert(Control);

    R.Assign(37, 11, 48, 13);
    Control := New(PButton, Init(R, '~R~escan', cmRescan, bfNormal));
    Control^.HelpCtx := hctoyVideoRescan;
    Insert(Control);

    R.Assign(37, 14, 48, 16);
    Control := New(PButton, Init(R, 'Help', cmHelp, bfNormal));
    Control^.HelpCtx := hctoyVideoDialogHelp;
    Insert(Control);

    SelectNext(False);
  end;

  constructor TSelectVideoModeDialog.Load;
  begin
    inherited Load(S);
    GetSubViewPtr(S, VideoListBox);
  end;

  procedure TSelectVideoModeDialog.HandleEvent;
    var
      OldMode : Word;
  begin
    inherited HandleEvent(Event);
    if (Event.What and evMessage<>0) then
    begin
      case Event.Command of
        cmListItemSelected,      (* Mouse double clicked in list *)
        cmPreview:
          begin
            OldMode:=ScreenMode;
            SetSpecialScreenMode(ModeList[VideoListBox^.Focused]);
            Delay(PreviewTime);
            SetSpecialScreenMode(OldMode);
          end;
        cmRescan:
          begin
            VideoList:=Nil;
            SetupVideoList;
            VideoListBox^.NewList(VideoList);
          end;
        else
          Exit;
      end;
      ClearEvent(Event);
    end;
  end;

  procedure TSelectVideoModeDialog.Store;
  begin
    inherited Store(S);
    PutSubViewPtr(S, VideoListBox);
  end;


    (*******************************************************************
    *******************************************************************)

end.
