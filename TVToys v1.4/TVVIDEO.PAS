(***************************************************************************
  TVVideo unit
  Turbo Vision extended video modes support routines
  PJB August 30, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright PJB 1993, All Rights Reserved. Portions Copyright Borland.
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

    þ TVVIDEO NO LONGER SUPPORTS smFont8x8 or smSpecialFont8x8

      Use ToggleVideoLines instead, or SetInternalFont.

    þ PLEASE remember (I didn't) to use

      SetSpecialVideoMode instead of SetVideoMode

***************************************************************************)
unit TVVideo;
{$I toyCfg}

{$B-,O+,Q-,X+}

interface

  uses
    App, Drivers, Objects, Memory, Views,
    Dos,
    Video;

  type
    LastFontType = (lfInternalFont, lfDiskFont, lfResourceFont);

  const
    (* TVToys doesn't support smFont8x8, this might avoid disasters *)
    smFont8x8 = 0;

  var
    (* INEXACT value, used for screen lines calculations *)
    VideoScanLines : Integer;
    (* Tpye of font last loaded *)
    LastFontTypeUsed : LastFontType;


  procedure PreventModeSwitch;
  procedure CheckScanLines;
  procedure SetSpecialScreenMode(Mode:Word);
  procedure SetInternalFont(Font:Byte);
  procedure SetUserFont(Points:Byte; Font:Pointer);
  procedure ToggleVideoLines;
  procedure InitTVVideo;

  procedure DoNothing;

  const
    (* Called when video mode changed *)
    VideoModeChanged : Procedure = DoNothing;


(***************************************************************************
***************************************************************************)
implementation


  (*******************************************************************
    This is the normal ReloadLastFont procedure
  *******************************************************************)
  procedure DoNothing; assembler; asm end;


  (*******************************************************************
    From Borlands DRIVERS unit
  *******************************************************************)
  function GetCrtMode:Word; assembler;
  asm
      PUSH      BP

      MOV	AH,0FH
      INT       10H

      PUSH	AX
      MOV	AX,1130H
      MOV	BH,0
      MOV	DL,0
      INT       10H
      POP	AX

      MOV	DH,AH
      CMP	DL,25
      SBB	AH,AH
      INC	AH

      POP       BP
  end;

  (*******************************************************************
    Call this before InitVideo or DoneVideo to stop them from
    changing the video mode. This procedure *destroys* StartUpMode.
    Save StartUpMode (MyApp.Init; Save:=StartUpMode;) if you want to
    restore the video mode (StartUpMode:=Save; MyApp.Done;) on exit.

    Try this to keep the startup video mode (132-cols etc) active:
      begin
        if IsProbablyTextMode then PreventModeSwitch;
        MyApp.Init; MyApp.Run; MyApp.Done;
      end.
  *******************************************************************)
  procedure PreventModeSwitch;
  begin
    StartUpMode:=GetCrtMode;
    ScreenMode:=StartUpMode;
  end;


  (*******************************************************************
    Try to make VideoScanLines reflect maximum number of scan lines
    in this video mode
  *******************************************************************)
  procedure CheckScanLines;
    var
      ScanLines : Integer;
  begin
    ScanLines:=GetCurrentScanLines;
    if (Abs(ScanLines-VideoScanLines)>16) or (ScanLines>VideoScanLines) then
      VideoScanLines:=ScanLines;       (* Screen size has changed! *)

    case VideoScanLines of             (* Screen could probably be higher *)
      340..349:  VideoScanLines:=350;
      390..399:  VideoScanLines:=400;
      470..479:  VideoScanLines:=480;
      590..599:  VideoScanLines:=600;
    end;
  end;


  (*******************************************************************
    Center all views on the desktop
  *******************************************************************)
  procedure ReCenterDesktop;
    procedure ReCenter(P:PView); far;
      var
        X,Y : integer;
    begin
      X:=P^.Origin.X;
      Y:=P^.Origin.Y;

      if P^.Options and ofCenterX <> 0 then
        X:=(Desktop^.Size.X - P^.Size.X) div 2;
      if P^.Options and ofCenterY <> 0 then
        Y:=(Desktop^.Size.Y - P^.Size.Y) div 2;

      P^.MoveTo(X, Y);
    end;
  begin
    Desktop^.ForEach(@ReCenter);
    Application^.ForEach(@ReCenter);
  end;


  (*******************************************************************
    Initialize TV video stuff
    This is separate procedure so we can use it for font changes etc
  *******************************************************************)
  procedure InitTVVideo;
    var
      R    : TRect;
  begin
    PreventModeSwitch;         (* Disable InitVideo mode switch *)
    InitVideo;                 (* Recalc CRT data *)

    if VideoType=EGA then      (* This is Borland's idea *)
    asm
      push bp
      mov  es,Seg0040
      or   es:[CrtInfo].Byte,1 (* Disable CGA cursor emulation *)

      mov  ah,1
      mov  cx,0600h            (* Set cursor size: Start 6, End 0 *)
      int  10h
      pop  bp
    end;

    DoneMemory;                (* Dispose of cache buffers *)
    InitMemory;
    Application^.InitScreen;   (* Calculate shadow sizes (debatable) *)

    Application^.Buffer:=Nil;  (* Disable all screen writing *)

    R.Assign(0, 0, ScreenWidth, ScreenHeight);
    Application^.ChangeBounds(R);    (* Resize application *)
    ReCenterDesktop;                 (* Center desktop items *)

    if IsColorMode then         (* Let's hope this works *)
      PtrRec(ScreenBuffer).Seg:=SegB800
    else
    begin
      ShadowSize.X := 0;
      ShadowSize.Y := 0;
      ShowMarkers := True;
      AppPalette := apMonochrome;
      PtrRec(ScreenBuffer).Seg:=SegB000;
    end;
    Application^.Buffer:=ScreenBuffer;

    Application^.Redraw;        (* Draw menubar, desktop and statusline *)
    ShowMouse;

    CheckScanLines;
    ScreenMode:=GetSpecialVideoMode;

    if Mem[Seg0040:CrtRows]<>24 then
    asm                         (* This is Borland's idea *)
      mov  ah,12h               (* Use alternate PrtScr handler *)
      mov  bl,20h
      push bp
      int  10h
      pop  bp
    end;
  end;


  (*******************************************************************
    Use this procedure to change video mode instead of SetScreenMode
    which will not set modes other than 2,3 and 7.

    DON'T use SetScreenMode if you use SetSpecialVideoMode.
    The display wont be redrawn if the screen size doesn't change.
    This is a design flaw at the heart of Turbo Vision
  *******************************************************************)
  procedure SetSpecialScreenMode(Mode:Word);
  begin
    HideMouse;

    SetSpecialVideoMode(Mode);
    VideoScanLines:=GetCurrentScanLines;
    VideoModeChanged;

    InitTVVideo;
  end;


  (*******************************************************************
    TV wrapper for Video.UseInternalFont
  *******************************************************************)
  procedure SetInternalFont(Font:Byte);
  begin
    HideMouse;
    UseInternalFont(Font);
    InitTVVideo;
  end;


  (*******************************************************************
    Load a character definition table
    Points is the character height
    Font points to an array of character bitmaps for all 256 chars,
    ASCII 0 first, occupying Points bytes per char, top to bottom.
    Character array must contain at least 256*Points bytes.
  *******************************************************************)
  procedure SetUserFont(Points:Byte; Font:Pointer);
  begin
    HideMouse;
    LoadUserFont(Points, 0, 256, Font);
    InitTVVideo;
  end;


  (*******************************************************************
    Replacement code to toggle the number of video lines
  *******************************************************************)
  procedure ToggleVideoLines;
  begin
    if Mem[Seg0040:CrtPoints]<>8 then
      SetInternalFont(Internal8x8Font)
    else
      if VideoType=EGA then
        SetInternalFont(Internal8x14Font)
      else
        SetInternalFont(Internal8x16Font);
  end;


    (*******************************************************************
    *******************************************************************)

end.