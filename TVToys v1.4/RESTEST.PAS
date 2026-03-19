(***************************************************************************
  ResTest program
  Official playground, odd bits and pieces, resources, config files etc
  PJB October 8, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright 1993, All Rights Reserved
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  Demonstrates video config files, resource fonts and video tests
  configurability. This program doesn't look for VESA and V7 without
  being told to do so, it saves the desktop video state and it gives
  transparent user access to resource fonts. There is also a self
  modifying menu.

  StoreCfg is currently used before ResDemoApp.Done so that no config
  file is saved if the program aborts during initialization. This
  was intended to prevent unnecessary elimination of video checks,
  whether that is any good I don't know.

  Another approach is to save a config file before testing that says
  no testing should be done, and another after the testing with full
  testing enabled. This doesn't leave anything to the user, but the
  program might crash the first time, if the video BIOS is picky.

    if not ConfigOK then    { No config file }
    begin
      StoreCfg;             { VideoTypesToCheck is [] }
      VideoTypesToCheck:=[vtVesa,vtVideo7];
    end;

    inherited Init;

    if not ConfigOK then    { No config file }
      StoreCfg;             { VideoTypesToCheck is [vtVesa,vtVideo7] }


  Be careful about using TV's message box in StoreCfg, though, there
  might not be any application:

    if (S.Status<>stOK) and (Application<>Nil) then
      MessageBox(...)


***************************************************************************)
program ResTest;

{$I toyCfg}

{$B-,X+}

{$IFNDEF ResFonts}
  Psst! Define ResFonts in TOYCFG.PAS, or this demo is gets boring!
{$ENDIF}

  uses
    App, Dialogs, Drivers, Menus, MsgBox, Objects, Views,
    toyPrefs, {$I hcFile}
    ColorBox, ColorSel,         (* Color selection dialog *)
    TVPal, Pal,                 (* Palette changing dialog *)
    FontDlg, FontFiles, HelpFile, ModeDlg, StrmRec, toyApp, toyUtils,
    TVVideo, TVUtils, Vesa, Video;

  type
    TResDemoApp =
      object (TToyApp)
        ResFile   : TResourceFile;
        LinesMenu : PMenu;
        constructor Init;
        procedure InitMenubar; virtual;
        procedure CalcLinesMenu;
        procedure CreateResourceFile;
        procedure HandleEvent(var Event:TEvent); virtual;
        procedure StoreCfg;
        procedure VideoTestsDialog(VT:SpecialVideoTypes);
      end;


  (*******************************************************************
    Demo commands
  *******************************************************************)
  const
    toyStart     = 100;
    cm8p         = toyStart+0;
    cm14p        = toyStart+1;
    cm16p        = toyStart+2;
    cmVideoMode  = toyStart+3;
    cmVideoInfo  = toyStart+4;
    cmSelectFont = toyStart+5;
    cmVideoTests = toyStart+6;
    cm12p        = toyStart+7;
    cmColor      = toyStart+8;
    cmPalette    = toyStart+9;

  const
    CfgName      = 'RESTEST.CFG';
    ResName      = 'RESTEST.REZ';


(***************************************************************************
  Things that belong in a unit
***************************************************************************)

  (*******************************************************************
    Restore a video state from stream
  *******************************************************************)
  procedure LoadVideoState(var S:TStream);
    var
      W : Word;
      TVVideoState : VideoState;
  begin
    LoadVideoModes(S);

    S.Read(TVVideoState, SizeOf(TVVideoState));
    S.Read(LastFontNameLoaded, SizeOf(LastFontNameLoaded));
    PToyApp(Application)^.LoadPalette(S);  (* requires Application <> Nil *)
    VideoPalette.Load(S);
    S.Read(LastFontTypeUsed, SizeOf(LastFontTypeUsed));

    if S.Status=stOK then
      TVVideoState.Restore;
  end;


  (*******************************************************************
    Store current video state on a stream
  *******************************************************************)
  procedure StoreVideoState(var S:TStream);
    var
      TVVideoState : VideoState;
  begin
    StoreVideoModes(S);

    TVVideoState.Save;
    S.Write(TVVideoState, SizeOf(TVVideoState));
    S.Write(LastFontNameLoaded, SizeOf(LastFontNameLoaded));
    PToyApp(Application)^.StorePalette(S);
    VideoPalette.Store(S);
    S.Write(LastFontTypeUsed, SizeOf(LastFontTypeUsed));
  end;


(***************************************************************************
  The application
***************************************************************************)

  (*******************************************************************
    Init app, load a config file with video info if there (this is
    what messes it up), create resource file if necessary
    This code includes TToyApp's Init, so we call TApplication.Init
    directly.
    Ideally we don't call TApplication.Init at all, but rather init
    the app first (without calling InitVideo) and then decide what
    kind of video initalizing we want...
  *******************************************************************)
  constructor TResDemoApp.Init;
    var
      S         : TDosStream;
      ConfigOK  : Boolean;
      InitState : VideoState;
  begin
    Application:=@Self;         (* Cheat, cheat, cheat... (for LoadVideoState) *)

    RegisterObjects;
    RegisterFontFile;
    RegisterHelpFile;

    (*******************************************************************
      Open and read config file if there is one
    *******************************************************************)
    { Do we have a config file? }
    S.Init(ExeDir+CfgName, stOpenRead);
    { This zeros VideoTypesToCheck if no cfg file, so checks only EVGA }
    S.Read(VideoTypesToCheck, SizeOf(VideoTypesToCheck));

    CheckVideoType;             (* Determine video type *)
    InitState.Save;             (* Use temporary variable... *)

    VideoPalette.Init;          (* Initialize palette *)

    LoadVideoState(S);          (* Load previously saved video state *)
    S.Done;
    ConfigOK:=S.Status=stOK;

    (*******************************************************************
      Init app, TToyApp replacement code
    *******************************************************************)
    if ConfigOK then
    begin
      PreventModeSwitch;        (* We loaded a new video mode *)
      VideoPalette.SetRGB(VideoPalette.RGB);
    end;

    TApplication.Init;          (* We don't want to call TToyApp.Init *)
    DosVideoState:=InitState;   (* Save startup video mode *)

    (* Get ScreenMode (if there is no cfg file) *)
    ScreenMode:=GetSpecialVideoMode;

    (*******************************************************************
      Introductory text
    *******************************************************************)
    HelpFileName:='HELPTEST.HLP';
    ShowHelp(hcRezIntro);

    (*******************************************************************
      Is there a resource file?  No? Create it!
    *******************************************************************)
    S.Init(ExeDir+ResName, stOpenRead);
    S.Done;
    if S.Status<>stOK then
      CreateResourceFile;        { No, create it }

    (*******************************************************************
      Open the resource file
    *******************************************************************)
    ResFile.Init(New(PBufStream, Init(ExeDir+ResName, stOpenRead, 1024)));

    if ResFile.Stream^.Status<>stOK then      (* OOPS! *)
    begin
      MessageBox(^C'Resource file not readable', Nil, mfError+mfOKButton);
      Done;
      Halt;
    end;

    (*******************************************************************
      Reload last font, might need resource file
    *******************************************************************)
    LastFontResourceFile:=@ResFile;
    VideoModeChanged:=ReloadFontAndPalette;    (* This is important! *)
    VideoModeChanged;

    (*******************************************************************
      Disable some features on non VGA cards
    *******************************************************************)
    if VideoType=Other then
      DisableCommands([cmVideoMode, cmSelectFont, cm8p, cm12p, cm14p, cm16p]);
    if VideoType=EGA then
      DisableCommands([cm16p]);

    if VideoType=Other then
      MessageBox('This program intended for EGA/VGA', Nil, mfInformation+mfOKButton);

    (*******************************************************************
      No config file, ask user for action
    *******************************************************************)
    if not ConfigOK then
      VideoTestsDialog([vtVesa,vtVideo7]);
  end;


  (*******************************************************************
    Create a Video menu with whatever lines settings available.
    Notice that menus are created bottom-to-top.
    It's impossible to make accurate predictions about the number
    of lines after a font change, the hardware might change the
    number of scanlines...
  *******************************************************************)
  procedure TResDemoApp.CalcLinesMenu;
    var
      P         : PMenuItem;

    (* Add "## lines" to menu list *)
    procedure Add(Points:Integer; Command, HelpCtx:Word);
      function Check:String;
      begin
        if Points=Mem[Seg0040:CrtPoints] then
          Check:='û '
        else
          Check:='  ';
      end;
    begin
      P:=NewItem(Check+ToStr(VideoScanLines div Points)+' lines', '',
                 kbNoKey, Command, HelpCtx, P);
    end;

  begin
    DisposeMenuItems(LinesMenu^.Items);

    P:=
      NewLine(
      NewItem('Select ~f~ont...', '', kbNoKey, cmSelectFont, hctoyVSelectFont,
      NewLine(
      NewItem('Select video ~m~ode...', '', kbNoKey, cmVideoMode, hctoyVVideoMode,
      Nil))));

    Add(8,  cm8p,  hctoyV8p);
    Add(12, cm12p, hcNoContext);
    Add(14, cm14p, hctoyV14p);
    if VideoType=VGA then
      Add(16, cm16p, hctoyV16p);

    LinesMenu^.Items:=P;
    LinesMenu^.Default:=P;
  end;


  (*******************************************************************
    There was an error writing the resource
  *******************************************************************)
  procedure ErrorInStream; far;
  begin
    MessageBox(^C'Failed to create resource file', Nil, mfError+mfOKButton);
    Application^.Done;
    Halt;
  end;


  (*******************************************************************
    Create a resource file with one font and the corresponding
    list of font resource keys
  *******************************************************************)
  procedure TResDemoApp.CreateResourceFile;
    var
      C : TStringCollection;
    procedure AddFont(Name:String);
      var
        Font : TFontFile;
    begin
      C.Insert(NewStr(Name));            (* Save the resource key *)
      Font.Init;
      if Font.DoRead(Name+'.COM') then
      begin
        Font.Desc:=Name+', this is a font resource!';
        ResFile.Put(@Font, Name)
      end
      else
      begin
        MessageBox(^C'Failed to read font '+Name, Nil, mfError+mfOKButton);
        ResFile.Stream^.Error(stWriteError, 0);
      end;
    end;
  begin
    Notice('', ^M^M^C'Creating resource file...');

    StreamError:=@ErrorInStream;
    ResFile.Init(New(PBufStream, Init(ExeDir+ResName, stCreate, 1024)));

    C.Init(10,10);

    AddFont('CHIC12');

    ResFile.Put(@C, toyFontListKey);    (* FontDlg needs this *)
    ResFile.Done;
    StreamError:=Nil;

    NoNotice;
    MessageBox(^C'Resource file created.', Nil, mfInformation+mfOKButton);
  end;


  (*******************************************************************
    Commands
  *******************************************************************)
  procedure TResDemoApp.HandleEvent;

    (*******************************************************************
      This is the Color selection dialog
    *******************************************************************)
    procedure Colors;
      var
        D : PColorBox;
    begin
      D:=New(PColorBox, Init(
        ColorGroup('Desktop',
          DeskTopColorItems(nil),
        ColorGroup('Menus',
          MenuColorItems(nil),
        ColorGroup('Dialogs',
          DialogColorItems(dpGrayDialog, nil),
        HelpColorItems(
        nil))))));

      ExecuteDialog(D, GetPalette);
    end;

    const
      InternalArr : array [cm8p..cm16p] of Byte =
        (Internal8x8Font, Internal8x14Font, Internal8x16Font);
  begin
    inherited HandleEvent(Event);

    if Event.What=evCommand then
    begin
      case Event.Command of
        cm8p..cm16p:   TVVideo.SetInternalFont(InternalArr[Event.Command]);
        cm12p:         LoadResFont(@ResFile, 'CHIC12');

        cmColor:       Colors;
        cmPalette:
          ExecuteDialog(New(PVideoPaletteDialog, Init(0)), @VideoPaletteData);

        cmSelectFont:  SelectFontDialog(ExeDir, @ResFile);
        cmVideoMode:
          if not HasToScan or               (* Already scanned *)
             VesaScanningPossible or        (* VESA handles it *)
             (MessageBox(^C'Have to do some tests. There is'+
                         ^M^C'no guarantee that it works...', Nil,
                         mfWarning+mfOkCancel)=cmOK) then
          begin
            SetUpVideoList;
            SelectVideoModeDialog;
          end;
        cmVideoTests: VideoTestsDialog(VideoTypesToCheck);
        else
          Exit;
      end;
      ClearEvent(Event);
      CalcLinesMenu;
    end;
  end;


  (*******************************************************************
    Menu bar
  *******************************************************************)
  procedure TResDemoApp.InitMenubar;
    var
      R : TRect;
  begin
    GetExtent(R);
    R.B.Y:=R.A.Y+1;
    MenuBar:=New(PMenuBar, Init(R, NewMenu(
      NewSubMenu('~F~ile', hcNoContext, NewMenu(
        NewItem('~D~OS shell', '', kbNoKey, cmDosShell, hcDosShell,
        NewItem('E~x~it', 'Alt+X', kbAltX, cmQuit, hcExit,
        Nil))),
      NewSubMenu('~V~ideo', hcVideo,
        StorePointer(LinesMenu, NewMenu(          (* Create it later *)
        Nil)),
      NewSubMenu('~O~ptions', hcNoContext, NewMenu(
        NewItem('~C~olors...', '', kbNoKey, cmColor, hcNoContext,
        NewItem('~P~alette...', '', kbNoKey, cmPalette, hctoyVPDialogHelp,
        NewItem('~V~ideo detection...', '', kbNoKey, cmVideoTests, hctoyOVideoTests,
        Nil)))),
    Nil))))));
    CheckScanLines;
    CalcLinesMenu;
  end;


  (*******************************************************************
    Store CFG file
  *******************************************************************)
  procedure TResDemoApp.StoreCfg;
    var
      S:TDosStream;
  begin
    S.Init(ExeDir+CfgName, stCreate);
    S.Write(VideoTypesToCheck, SizeOf(VideoTypesToCheck));
    StoreVideoState(S);
    S.Done;

    if (S.Status<>stOK) and (Application<>Nil) then
      MessageBox(^C'Could not create comfiguration file', Nil, mfError+mfOKButton);
  end;


  (*******************************************************************
    Ask user what video detection we want

    You might feel inclined to add this:

      VESAVersion:=0;
      Video7:=False;
      CheckVideoType;
      ScreenMode:=GetScreenMode;      { This one is important }

    This might break the VideoState code: if V7 and VESA was enabled
    at start-up and later denied, the wrong video call will be
    made. If the program started in an extended video mode,
    returning to DOS won't set the right video mode.
    The above requires a complete application restart, video wise.
  *******************************************************************)
  procedure TResDemoApp.VideoTestsDialog(VT:SpecialVideoTypes);
    {$I CheckVT}
  begin
    if ExecuteDialog(MakeVideoTestDialog, @VT)=cmOK then
    begin
      VideoTypesToCheck:=VT;
      CheckVideoType;
    end;
  end;


    (*******************************************************************
    *******************************************************************)

  var
    ResDemoApp : TResDemoApp;

begin
  ResDemoApp.Init;
  ResDemoApp.Run;
  ResDemoApp.StoreCfg;
  ResDemoApp.Done;
end.