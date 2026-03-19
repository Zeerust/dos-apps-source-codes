(***************************************************************************
  VideoTest program
  Demonstrates the Video, ModeDlg and TVVideo units
  PJB October 8, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright 1993, All Rights Reserved
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  þ This program's functionality can be altered by editing TOYCFG.PAS

  What this demonstration program does:
    The menu bar lets you choose between File, Video and Info.
    The Video menu lets you toggle between 25 and 43/50 lines, select
    a video mode and choose between internal video card fonts.

    If you choose Select video mode, you will see some warnings.
    Read them, press the "Run test" button and wait while the program
    scans for available video modes. Don't be alerted if your screen
    flashes. If you do not see a dialog box within four seconds, the
    computer probably crashed. This is a problem with very old (usually
    EGA) video BIOSes.

    If you have VESA text support you will instantly see the available
    video modes without any flashing. UNIVESA by Kendall Bennett does
    not provide text mode support, so there will be flashing if there is
    no additional VESA support.

    The dialog shows a list of text modes found. Press Enter to preview
    a video mode for two thirds of a second (if your monitor goes
    bonkers, just wait for one second and the screen will be restored.
    This means your monitor cannot cope with that video mode's
    resolution (e.g. displaying 60 lines with a VGA card on a standard
    EGA monitor))

    The following has been known to happen with fixed-sync VGAs:
    (this was an older PS/2 monitor, one user with a fixed-sync VGA
    reports that all is fine, my fixed sync EGA monitor copes, and
    multi-sync monitors have no problems)
    If your monitor emits "cracks" while in this video mode, your screen
    fuse (easily replaced) might melt if the monitor is subjected to
    that video mode for a longer period of time. You can always turn the
    monitor off if you think it is breaking down.

    þ Your mouse driver probably won't manage with extended video modes
    (especially not if it is a Microsoft driver). Check out the NewMouse
    unit supplied, define UseNewMouse in TOYCFG to use it.

    This program has been tested on a variety of machines with different
    hardware and video cards without any problems, but the very nature
    of this program makes it likely that there will be compatibility
    problems.

***************************************************************************)
program VideoTst;

{$I toyCfg}

{$B-,X+}

  uses
    Dos,
    App, Dialogs, Drivers, Memory, Menus, MsgBox, Objects, Views,
   {$IFDEF Color}
    ColorTxt,
   {$ENDIF}
    toyPrefs,                   (* Your preferences! *)
    HelpCtx,                    (* Some help contexts from TVHC *)
    FontDlg,                    (* Font selection dialog *)
    ModeDlg,                    (* Video mode selection dialog *)
    Video,                      (* Video type *)
    toyApp,                     (* App inherits TToyApp *)
    TVVideo;                    (* Toggle video lines *)

  type
    TVideoApp =
      object (TToyApp)
        constructor Init;
        procedure InitMenubar; virtual;
        procedure HandleEvent(var Event:TEvent); virtual;
        function  MakeVideoInfoDialog : PDialog;
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
    cmVideoLines = toyStart+4;
    cmVideoInfo  = toyStart+5;
    cmSelectFont = toyStart+6;


  (*******************************************************************
    Include warnings dialog
  *******************************************************************)
  {$I IMPRTANT.PAS}


  (*******************************************************************
    Init, check video type
  *******************************************************************)
  constructor TVideoApp.Init;
  begin
    (* Detect video type, save DOS video mode, start TV *)
    inherited Init;

    (* Disable some features on non VGA cards *)
    if VideoType=Other then
      DisableCommands([cmVideoMode, cmVideoLines, cmSelectFont, cm14p, cm16p])
    else
      VideoModeChanged:=ReloadLastFont;

    if VideoType=EGA then
      DisableCommands([cm16p]);

    if VideoType=Other then
      MessageBox('This program intended for EGA/VGA', nil, mfInformation+mfOKButton);

    HelpFileName:='HELPTEST.HLP';
    ShowHelp(hcVideoIntro);
  end;


  (*******************************************************************
    Video mode commands
    The HandleEvent inherited from toyApp deals with cmDosShell
  *******************************************************************)
  procedure TVideoApp.HandleEvent;
    const
      InternalArr : array [cm8p..cm16p] of Byte =
        (Internal8x8Font, Internal8x14Font, Internal8x16Font);
  begin
    inherited HandleEvent(Event);

    if Event.What=evCommand then
    begin
      case Event.Command of
        cm8p..cm16p:   TVVideo.SetInternalFont(InternalArr[Event.Command]);

        cmSelectFont:  SelectFontDialog('', Nil);      { ExeDir, maybe? }

        cmVideoMode:
          if not HasToScan or  { Don't warn if modes already known }
             (Application^.ExecuteDialog(MakeImportantDialog, Nil)=cmOK) then
          begin
            SetUpVideoList;
            SelectVideoModeDialog;
          end;
        cmVideoLines:  ToggleVideoLines;
        cmVideoInfo:   ExecuteDialog(MakeVideoInfoDialog, Nil);
        else
          Exit;
      end;
      ClearEvent(Event);
    end;
  end;


  (*******************************************************************
    Menu bar
  *******************************************************************)
  procedure TVideoApp.InitMenubar;
    var
      R : TRect;
  begin
    GetExtent(R);
    R.B.Y:=R.A.Y+1;
    MenuBar:=New(PMenuBar, Init(R, NewMenu(
      NewSubMenu('~F~ile', hcNoContext, NewMenu(
        NewItem('~D~OS shell', '', kbNoKey, cmDosShell, hcDosShell,
        NewItem('E~x~it', 'Alt+X', kbAltX, cmQuit, hcExit,
        nil))),
      NewSubMenu('~V~ideo', hcVideo, NewMenu(
        NewItem('Toggle video ~l~ines', '', kbNoKey, cmVideoLines, hctoyVVideoLines,
        NewItem('Select video ~m~ode...', '', kbNoKey, cmVideoMode, hctoyVVideoMode,
        NewLine(
        NewItem('Select ~f~ont...', '', kbNoKey, cmSelectFont, hctoyVSelectFont,
        NewItem('Internal ~8~p font', '', kbNoKey, cm8p, hctoyV8p,
        NewItem('Internal 1~4~p font', '', kbNoKey, cm14p, hctoyV14p,
        NewItem('Internal 1~6~p font', '', kbNoKey, cm16p, hctoyV16p,
        nil)))))))),
      NewItem('~I~nfo', '', kbNoKey, cmVideoInfo, hcNoContext,
    nil))))));
  end;


  (*******************************************************************
    Create the video information dialog
  *******************************************************************)
  function TVideoApp.MakeVideoInfoDialog : PDialog;
    var
      R       : TRect;
      Dlg     : PDialog;
      Control : PView;
      TempStr : string;
      DataArr : array [0..3] of LongInt;

    procedure AddInfo(const S:String; Color:Byte);
   {$IFDEF Color}
      var
        Text    : PColoredText;
    begin
      New(Text, Init(R, S, Color));
      Dlg^.Insert(Text);
      AddShadowTo(Text);
    end;
   {$ELSE}
      var
        Text    : PStaticText;
    begin
      New(Text, Init(R, S));
      Dlg^.Insert(Text);
    end;
   {$ENDIF}

  begin
    R.Assign(0, 0, 65, 14);
    New(Dlg, Init(R, 'Video Info'));
    Dlg^.Options := Dlg^.Options or ofCentered;

    R.Assign(4, 2, 61, 3);

    case VideoType of
      VGA:   AddInfo(^C'VGA detected', $1F);
      EGA:   AddInfo(^C'EGA detected', $1F);
      Other: AddInfo(^C'EGA/VGA not detected', $1F);
    end;


    R.Move(0, 2);
    DataArr[0]:=GetSpecialVideoMode;
    DataArr[1]:=Mem[Seg0040:CrtWidth];
    DataArr[2]:=Mem[Seg0040:CrtRows]+1;
    DataArr[3]:=Mem[Seg0040:CrtPoints];
    FormatStr(TempStr, '  Mode: %xh   Width: %d   Height: %d   CharHeight: %d', DataArr);
    AddInfo(TempStr, $1F);


    R.Move(0, 2);
   {$IFDEF VesaSupport}
    DataArr[0]:=Hi(VESA.VesaVersion);
    DataArr[1]:=Lo(VESA.VesaVersion);
    FormatStr(TempStr, '  VESA version %d.%d detected', DataArr);

    if VESA.VesaVersion=0 then
      AddInfo('  VESA support not detected', $3F)
    else
      AddInfo(TempStr, $3F);
   {$ELSE}
    AddInfo('  VESA code not compiled', $4F);
   {$ENDIF}


    R.Move(0, 2);
   {$IFDEF Video7Support}
    if Video7 then
      AddInfo('  Video 7 detected', $3F)
    else
      AddInfo('  Video 7 not detected', $3F);
   {$ELSE}
      AddInfo('  Video 7 code not compiled', $4F);
   {$ENDIF}


    R.Assign(27, 11, 37, 13);
    Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
    Dlg^.Insert(Control);

    Dlg^.SelectNext(False);
    MakeVideoInfoDialog := Dlg;
  end;

    (*******************************************************************
    *******************************************************************)

  var
    VideoApp : TVideoApp;

begin
  VideoApp.Init;
  VideoApp.Run;
  VideoApp.Done;
end.
