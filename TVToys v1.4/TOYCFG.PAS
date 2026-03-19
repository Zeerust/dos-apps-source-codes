(***************************************************************************
  toyConfig include
  Personal TVToys preferences
  PJB November 3, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright 1993, All Rights Reserved
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  How this works:
    All defines have been moved to one file which is included by all
    units. Any changes here affect all TVToys units, and you don't have
    to worry about using Build, either. Make detects dependencies on
    this file and recompiles the necessary units.

    If you want to undefine a conditional, insert a space between the
    left brace and the dollar sign so BP thinks it is a comment.
    Example:

      {$DEFINE HelpExtensions}         Defined

      {  $DEFINE HelpExtensions}       Not defined

    This means that if you define a conditional in the "Conditional
    Defines" input box in the "Compiler Options" dialog or from the
    command line,
    the conditional will be considered defined, even if it is not
    defined in this file, since there is no {$UNDEF }.

    This is considered a feature, but means you have to check if the
    conditional is already defined elsewhere before you "undefine" it
    here, since that may have no effect. This makes it different from
    UNIX configuration files.

    If you want to use different configurations in different projects,
    copy this file to each project directory.

***************************************************************************)

(*******************************************************************
  If you feel swamped with Debug info, define $D- here. Not all
  units are affected by this, however.
*******************************************************************)
{  $D-}


(*******************************************************************
  NewMouse draws its own mouse cursor on the screen and avoids
  buggy mouse driver code which makes your mouse unusable in many
  video modes.
  Define UseNewMouse to make TToyApp automatically use NewMouse.
  Default: Not defined     Affects: toyApp, VideoTst
*******************************************************************)
{  $DEFINE UseNewMouse}


(*******************************************************************
  Define VesaSupport to make Video recognize Vesa support
  and use Vesa calls to set and get the video mode.
  Default: Defined        Affects: Video, ModeDlg
*******************************************************************)
{$DEFINE VesaSupport}


(*******************************************************************
  Define Video7Support to make Video recognize Video 7 video
  cards and use Video 7 calls to set and get the video mode.
  Default: Defined        Affects: Video
*******************************************************************)
{$DEFINE Video7Support}


(*******************************************************************
  Define StoreModeData to store more video mode information when
  determining available video modes, so that you later can search
  for video modes that matches a certain screen size. A simple
  example of how to do this is FindSimilarVideoMode.
  Default: Not defined     Affects: ModeDlg
*******************************************************************)
{  $DEFINE StoreModeData}


(*******************************************************************
  Define AutoCheckVideoType to automatically run CheckVideoType
  when the Video unit is used. If you define it, you cannot
  overlay the Video unit any more.
  Default: Not defined      Affects: Video
*******************************************************************)
{  $DEFINE AutoCheckVideoType}


(*******************************************************************
  Define V7UniVesaKludge ONLY if you want to use an old version of
  UniVesa (4.2 and older) on a Video 7 card.
  Default: Not defined      Affects: Video
*******************************************************************)
{  $DEFINE V7UniVesaKludge}


(*******************************************************************
  Define DiskFonts if you want FontDlg.SelectFontDialog to
  search on disk for font files. This is defined by default to
  make VideoTst a more interesting demo. I do not recommend
  keeping it defined, it's 3K code.
  Default: Defined          Affects: FontDlg, (VideoTst)
*******************************************************************)
{$DEFINE DiskFonts}


(*******************************************************************
  Define ResFonts if you want FontDlg.SelectFontDialog to
  search in a resource file for font files. This is defined by
  default to make ResDemo a more interesting demo.
  Default: Defined          Affects: FontDlg, (ResDemo)
*******************************************************************)
{$DEFINE ResFonts}


(*******************************************************************
  Define HelpExtensions to enable the back tracking buffer and
  the cmSwitchToTopic command.
  Default: Defined          Affects: HelpFile
*******************************************************************)
{$DEFINE HelpExtensions}


(*******************************************************************
  Define ExeHelp if you want toyApp to use the ExeStrm unit to
  look in the application's EXE file for the help file.
  ExeHelp currently assumes DOS 3+ compatibility.
  This is not very useful during debugging, so you might want to
  add a DEBUG conditional so that ExeHelp is defined only if DEBUG
  is not.
  Default: Not defined      Affects: toyApp
*******************************************************************)
{  $DEFINE ExeHelp}


(*******************************************************************
  Define Color to get a colorful Info dialog in the VideoTst
  demo program. This might not work if substantial changes has
  been made to Turbo Vision's internal GetColor procedure in
  VIEWS.PAS. If you haven't changed the library, define it.
  Default: Defined          Affects: VideoTst
*******************************************************************)
{$DEFINE Color}
