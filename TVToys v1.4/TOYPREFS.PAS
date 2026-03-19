(***************************************************************************
  Preferences unit
  Different TVToys constants to ease portability
  PJB November 3, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright 1993, All Rights Reserved
  Free source, use at your own risk.
  If modified, please state so if you pass this around.
***************************************************************************)
unit toyPrefs;

interface

{$I toyCfg}

  uses
    App, Drivers, Objects, Menus, Views;


  (*******************************************************************
    Useful for GetData/SetData dialog records
  *******************************************************************)
  type
    TListboxRec =
      record
        List      : PCollection;
        Selection : Word;
      end;


  const
    (*******************************************************************
      Registration numbers are numbers used in stream registration
      records to uniquely identify objects stored on a stream.
    *******************************************************************)
    toyBaseRN            = 7380;
    toyColorTxtRN        = toyBaseRN+0;
    toyFileValidatorRN   = toyBaseRN+1;
    toyFontFileRN        = toyBaseRN+2;
    toyHexValidatorRN    = toyBaseRN+3;
    toyPathValidatorRN   = toyBaseRN+4;
    toyRealValidatorRN   = toyBaseRN+5;
    toySelectFontRN      = toyBaseRN+6;
    toySelectVideoModeRN = toyBaseRN+7;
    toySliderValidatorRN = toyBaseRN+8;
    toyVideoPaletteRN    = toyBaseRN+9;


(***************************************************************************
  toyApp constants
***************************************************************************)
  const
    hcHelpWindow      = 11111;  (* Popup help's HelpCtx (for status line) *)

    toyBaseCommand    = 9100;
    cmHelp            = toyBaseCommand+0;
    cmPreviousTopic   = toyBaseCommand+1;
    cmHelpContents    = toyBaseCommand+2;
    cmHelpOnHelp      = toyBaseCommand+3;

    (* You don't need to edit these values, you can override them with
       your own HELPCTX file, see Help Contexts below *)
    hcContents        = 0;
    hcHelpOnHelp      = 2;


(***************************************************************************
  HelpFile
***************************************************************************)
  const
    (* MAGIC help topic, FF00+ reserved by Borland *)
    PreviousTopic   = $EEEE;

    (* Doesn't have to be unique unless you use modeless help windows *)
    cmSwitchToTopic = toyBaseCommand+9;

    (* Help topic back track depth *)
    MaxOldTopics = 16;


  (* Status line creation aid *)
  function StdStatusHelp(Next:PStatusDef):PStatusDef;


(***************************************************************************
  ModeDlg
***************************************************************************)
  const
    (* Video mode selection preview time *)
    PreviewTime = 12;                (* Two thirds of a second *)

    (* Maximum number of video modes stored *)
    MaxVideoModes = 31;


(***************************************************************************
  FontDlg
***************************************************************************)
  const
    (* The key of a string collection resource containing all the
       resource keys that are fonts (TFontFile) in that same RezFile *)
    toyFontListKey = 'FONTLIST';
    toyFontExt     : String[4] = '.COM';


(***************************************************************************
  ColorBox
***************************************************************************)
  const
    (* "Propagate colors" default setting *)
    ColorPropagation : Boolean = True;


(***************************************************************************
  Help contexts
  These are dummy values so you can get coding quickly, don't change them.
  You should let TVHC generate these help contexts for you and put them
  in a file called HELPCTX.PAS in your local project directory. You can
  change the help context file name by editing HCFILE.PAS.
  Your personal HELPCTX file will override any of the below values.
  HELPTEST.TXT contains a topic list you can copy.
***************************************************************************)

  const
    hcOK                           = 0;
    hcCancel                       = 0;

    { Video Menu }
    hcVideo                        = 0;
    hctoyVVideoLines               = 0;
    hctoyVVideoMode                = 0;
    hctoyVSelectFont               = 0;
    hctoyV14p                      = 0;
    hctoyV16p                      = 0;
    hctoyV8p                       = 0;

    { Video mode selection dialog }
    hctoyVideoDialogHelp           = 0;
    hctoyVideoListBox              = 0;
    hctoyVideoPreview              = 0;
    hctoyVideoRescan               = 0;

    { Otions Menu }
    hctoyOVideoTests               = 0;

    { Video test dialog }
    hctoyVTCheckVesa               = 0;
    hctoyVTCheckV7                 = 0;
    hctoyVTDialogHelp              = 0;

    { Font selection }
    hctoyFontListBox               = 0;
    hctoyFontDialogHelp            = 0;

    { Help Menu }
    hcHelp                         = 0;
    hctoyHHelp                     = 0;
    hctoyHPreviousTopic            = 0;
    hctoyHUsingHelp                = 0;

    { Color selection dialog }
    hctoyCSBackground              = 0;
    hctoyCSForeground              = 0;
    hctoyCSGroup                   = 0;
    hctoyCSItem                    = 0;
    hctoyCSMonoSelector            = 0;
    hctoyCSPropagation             = 0;

    { Video palette dialog }
    hctoyVPBlue                    = 0;
    hctoyVPGreen                   = 0;
    hctoyVPRed                     = 0;
    hctoyVPDialogHelp              = 0;


(***************************************************************************
***************************************************************************)
implementation


  (*******************************************************************
    Convenient status line creator
  *******************************************************************)
  function StdStatusHelp(Next:PStatusDef):PStatusDef;
  begin
    StdStatusHelp:=
      NewStatusDef(hcHelpWindow, hcHelpWindow,
        StdStatusKeys(
        NewStatusKey('~F1~ Help on Help', kbF1,   cmHelpOnHelp,
        NewStatusKey('~Alt+B~ Back',      kbAltB, cmPreviousTopic,
        NewStatusKey('~Alt+C~ Contents',  kbAltC, cmHelpContents,
        NewStatusKey('~F5~ Zoom',         kbF5,   cmZoom,
        NewStatusKey('~Esc~ Close help',  kbEsc,  cmClose,
      Nil)))))),
    Next);
  end;


end.
