(***************************************************************************
  TToyApp unit
  Inherit this for easy access to TVToys' Help and Video functions
  PJB November 6, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright PJB 1993, All Rights Reserved.
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  All commands and help contexts used in this file are defined in
  TOYPREFS.PAS, but you can override the help contexts with your own
  HELPCTX.PAS (see HCFILE and TOYPREFS).

  RegisterHelpFile is called automatically.

  Set ExeFileName and HelpFileName to their corresponding values to
  make the Help work. See HELPTEST.PAS for an example.

  ExeFileName is only needed for DOS 1.x and 2.x compatibility, and
  HelpFileName is only needed if you don't define ExeHelp (ExeHelp
  assumes DOS 3+ compatibility).

  If you use this unit, ALL the help code will be linked into your
  application. You need two IFDEFs to avoid that. Most of the video
  code is also linked in.

***************************************************************************)
unit ToyApp;

{$I toyCfg}

{$B-,O+,X+}

interface

  uses
    Dos,
    App, Dialogs, Drivers, Memory, Menus, MsgBox, Objects, Views,
   {$IFDEF UseNewMouse}
    NewMouse,
   {$ENDIF}
   {$IFDEF ExeHelp}
    ExeStrm,
   {$ENDIF}
    toyPrefs, {$I hcFile}
    HelpFile, toyUtils, TVVideo, Video;

  type
    PToyApp = ^TToyApp;
    TToyApp =
      object (TApplication)
        ExeFileName    : PathStr;
        HelpFileName   : PathStr;
        HelpInUse      : Boolean;

        DosVideoState  : VideoState;

        constructor Init;
        destructor  Done; virtual;
        procedure DosShell;
        function  ExeDir:PathStr;
        procedure GetEvent(var Event:TEvent); virtual;
        function  GetPalette:PPalette; virtual;
        procedure HandleEvent(var Event:TEvent); virtual;
        procedure LoadPalette(var S:TStream);
        procedure ShowHelp(aHelpCtx:word);
        procedure StorePalette(var S:TStream);
      end;

implementation


  (*******************************************************************
    Init
  *******************************************************************)
  constructor TToyApp.Init;
    var
      InitState : VideoState;
  begin
    (* Always start with this command *)
    CheckVideoType;

    InitState.Save;             (* Use temporary variable since... *)
    inherited Init;             (* ... this zeros the whole object *)
    DosVideoState:=InitState;

    (* Set ScreenMode to a value closer to reality (for V7,VESA) *)
    ScreenMode:=GetSpecialVideoMode;

    RegisterHelpFile;           (* Save us some trouble *)
  end;


  (*******************************************************************
    Restore initial video mode
  *******************************************************************)
  destructor TToyApp.Done;
  begin
    TVVideo.PreventModeSwitch;
    inherited Done;
    DosVideoState.Restore;
  end;


  (*******************************************************************
    New DosShell procedure
  *******************************************************************)
  procedure TToyApp.DosShell;
    var
      TVVideoState : VideoState;
  begin
    DoneSysError;
    DoneEvents;
   {$IFDEF UseNewMouse}
    UseNewMouse(False);
   {$ENDIF}

    TVVideoState.Save;
    DosVideoState.Restore;

    DoneDosMem;
    WriteShellMsg;
    SwapVectors;
    Exec(GetEnv('COMSPEC'), '');
    SwapVectors;
    InitDosMem;

    DosVideoState.Save;
    TVVideoState.Restore;
    VideoModeChanged;

   {$IFDEF UseNewMouse}
    UseNewMouse(True);
   {$ENDIF}

    InitEvents;
    InitSysError;

    HideMouse;
    InitTVVideo;
  end;


  (*******************************************************************
    Return the directory of the main executable file
    Always ends with a slash or colon...
  *******************************************************************)
  function TToyApp.ExeDir;
    var
      EXEName : PathStr;
      Dir     : DirStr;
      Name    : NameStr;
      Ext     : ExtStr;
  begin
    if Lo(DosVersion)>=3 then
      EXEName:=ParamStr(0)
    else
      EXEName:=FSearch(ExeFileName, GetEnv('PATH'));
    FSplit(EXEName, Dir, Name, Ext);
    ExeDir:=AddBackslash(Dir);
  end;


  (*******************************************************************
    Help popping and Status line support
  *******************************************************************)
  procedure TToyApp.GetEvent;
  begin
    inherited GetEvent(Event);

    if Event.What=evCommand then
    begin
      case Event.Command of
        (* The usual TV help command *)
        cmHelp:          ShowHelp(GetHelpCtx);
        (* These are status line commands and must reside in GetEvent,
           else won't work inside (modal) Help *)
        cmPreviousTopic: ShowHelp(PreviousTopic);
        cmHelpContents:  ShowHelp(hcContents);
        cmHelpOnHelp:    ShowHelp(hcHelpOnHelp);
        else
          Exit;
      end;
      ClearEvent(Event);
    end;
  end;


  (*******************************************************************
    Standard Help palette
  *******************************************************************)
  function TToyApp.GetPalette;
    const
      CNewColor      = CAppColor      + CHelpColor;
      CNewBlackWhite = CAppBlackWhite + CHelpBlackWhite;
      CNewMonochrome = CAppMonochrome + CHelpMonochrome;
      P : array [apColor..apMonochrome] of String[Length(CNewColor)] =
        (CNewColor, CNewBlackWhite, CNewMonochrome);
  begin
    GetPalette := PPalette(@P[AppPalette]);
  end;


  (*******************************************************************
    Dos shell must be handled properly:
    CANNOT call inherited HandleEvent first
    To add more default processing, create a new application object
    that inherits TToyApp, add commands, and inherit that instead.
    This eases future upgrades.
  *******************************************************************)
  procedure TToyApp.HandleEvent;
  begin
    if (Event.What=evCommand) and (Event.Command=cmDosShell) then
    begin
      DosShell;                   (* MUST be overridden *)
      ClearEvent(Event);
    end
    else
      inherited HandleEvent(Event);
  end;


  (*******************************************************************
    Load application palette from stream
  *******************************************************************)
  procedure TToyApp.LoadPalette(var S:TStream);
    var
      P      : TPalette;
      Pal    : Integer;
      OldPal : Integer;
  begin
    OldPal:=AppPalette;

    for Pal:=apColor to apMonochrome do
    begin
      S.Read(P[0], 1);
      S.Read(P[1], Length(P));

      if S.Status=stOK then
      begin
        AppPalette:=Pal;
        GetPalette^:=P;
      end;
    end;

    AppPalette:=OldPal;
  end;


  (*******************************************************************
    Pop up a (modal) help window, standard TVDEMO style, or
    send message to existing help window
  *******************************************************************)
  procedure TToyApp.ShowHelp;
    var
      W        : PWindow;
      HFile    : PHelpFile;
      HelpStrm : PDosStream;
      Event    : TEvent;
  begin
    (* HelpInUse moved into the Application object *)
    if HelpInUse then
    begin
      Event.What:=evCommand;
      Event.Command:=cmSwitchToTopic;
      Event.InfoWord:=aHelpCtx;
      PutEvent(Event);
    end
    else
    begin
      HelpInUse:=True;
     {$IFDEF ExeHelp}
      HelpStrm:=New(PExeScanningStream, Init(ParamStr(0), stOpenRead, magicHelpFile));
     {$ELSE}
      New(HelpStrm, Init(FSearch(HelpFileName, ExeDir), stOpenRead));
     {$ENDIF}

      New(HFile, Init(HelpStrm));
      if HelpStrm^.Status<>stOk then
      begin
        MessageBox(^C'Could not open help file', Nil, mfError+mfOkButton);
        Dispose(HFile, Done);
      end
      else
      begin
        W:=New(PHelpWindow, Init(HFile, aHelpCtx));
        if ValidView(W)<>Nil then
        begin
          W^.HelpCtx:=hcHelpWindow;
          Application^.ExecView(W);
          Dispose(W, Done);
        end;
      end;
      HelpInUse:=False;
    end;
  end;


  (*******************************************************************
    Store application palette on stream
  *******************************************************************)
  procedure TToyApp.StorePalette(var S:TStream);
    var
      P      : PPalette;
      Pal    : Integer;
      OldPal : Integer;
  begin
    OldPal:=AppPalette;

    for Pal:=apColor to apMonochrome do
    begin
      AppPalette:=Pal;
      P:=GetPalette;
      S.Write(P^, Length(P^)+1);
    end;

    AppPalette:=OldPal;
  end;


    (*******************************************************************
    *******************************************************************)

end.
