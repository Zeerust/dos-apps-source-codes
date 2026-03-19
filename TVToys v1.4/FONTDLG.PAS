(***************************************************************************
  FontDlg unit
  Font selection dialog
  PJB November 3, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright 1993, All Rights Reserved
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

***************************************************************************)
unit FontDlg;

{$I toyCfg}

{$B-,O+,X+}

interface

  uses
    Dos,
    App, Dialogs, Drivers, MsgBox, Objects, StdDlg, Validate, Views,
    toyPrefs, {$I hcFile}
    DblStr, FontFiles, toyUtils, TVVideo, TVUtils, Video;


  type
    PSelFontDialog = ^TSelFontDialog;
    TSelFontDialog =
      object (TDialog)
        constructor Init;
        procedure HandleEvent(var Event:TEvent); virtual;
      end;


  procedure ReloadLastFont;
  (* Where do I put this? *)
  procedure ReloadFontAndPalette;

  procedure LoadResFont(ResFile:PResourceFile; const FontRes:String);
  procedure LoadDiskFont(const FileName:String);

  procedure ScanFontFiles(const Path:String; Proc:ScanProcedure);
  function  SelectFontDialog(const FontPath:String; ResFile:PResourceFile):Boolean;
  function  SelectFont(List:PDblStringCollection; var Name:String):Boolean;

  var
    (* Last disk font loaded or font resource key used *)
    LastFontNameLoaded : PathStr;
    (* Last resource file used, must be open *)
    LastFontResourceFile : PResourceFile;


(***************************************************************************
***************************************************************************)
implementation

  uses
    TVPal;


  (*******************************************************************
    Reloads both the palette and the last font
  *******************************************************************)
  procedure ReloadFontAndPalette;
  begin
    ReloadLastFont;
    ReloadPalette;
  end;


(***************************************************************************
***************************************************************************)

  (*******************************************************************
    Load a disk font
  *******************************************************************)
  procedure LoadDiskFont(const FileName:String);
    var
      Font : TFontFile;
  begin
    if Font.Read(FileName) then
    begin
      Font.Display;
      LastFontNameLoaded:=FExpand(FileName);
      LastFontTypeUsed:=lfDiskFont;
    end;
  end;


  (*******************************************************************
    Load a font from a resource file
  *******************************************************************)
  procedure LoadResFont(ResFile:PResourceFile; const FontRes:String);
    var
      P : PFontFile;
  begin
    P:=PFontFile(ResFile^.Get(FontRes));
    if P<>Nil then
    begin
      P^.Display;
      Dispose(P, Done);
    end;

    LastFontNameLoaded:=FontRes;
    LastFontResourceFile:=ResFile;
    LastFontTypeUsed:=lfResourceFont;
  end;


  (*******************************************************************
    Reload last font loaded from disk
  *******************************************************************)
  procedure ReloadLastDiskFont;
    var
      Font : TFontFile;
  begin
    if LastFontNameLoaded<>'' then
      if Font.DoRead(LastFontNameLoaded) then
        Font.Display;
  end;


  (*******************************************************************
    Reload last font from its source
  *******************************************************************)
  procedure ReloadLastFont;
  begin
    case TVVideo.LastFontTypeUsed of
     {$IFDEF DiskFonts}
      lfDiskFont: ReloadLastDiskFont;
     {$ENDIF}
     {$IFDEF ResFonts}
      lfResourceFont: LoadResFont(LastFontResourceFile, LastFontNameLoaded);
     {$ENDIF}
    end;
  end;


(***************************************************************************
***************************************************************************)

  (*******************************************************************
    Look for font files in a directory
  *******************************************************************)
  procedure ScanFontFiles;
    var
      f : TFontFile;
  begin
    Notice('', ^M^M^C'Searching for font files...');
    f.DiskScan(Path, Proc);
    NoNotice;
  end;


(***************************************************************************
***************************************************************************)

  (*******************************************************************
    Here we store the font files found
  *******************************************************************)
  var
    FontList  : PDblStringCollection;

  (*******************************************************************
    Called by ScanFontFiles
  *******************************************************************)
  procedure SelectFiles(Points:Integer; const Desc, FileName:String); far;
  begin
    if (VideoType=VGA) or (Points<=14) then
      FontList^.Insert(NewDoubleStr(Desc, FileName));
  end;


  (*******************************************************************
    Let user select a font
    Define DiskFonts to search for disk fonts
    Define ResFonts to search in the resource file parameter
    You can define both to search in both...

    The resource file must contain a StringCollection resource saved
    under the key FONTLIST (see TOYPREFS) with the keys to the
    TFontFiles available in the stream. RESTEST contains an example.
  *******************************************************************)
  function SelectFontDialog(const FontPath:String; ResFile:PResourceFile):Boolean;
    var
      FontChosen : String;
      ResFonts   : PStringCollection;

    procedure AddFont(const FontRes:PString); far;
      var
        P : PFontFile;
    begin
      P:=PFontFile(ResFile^.Get(FontRes^));
      if P<>Nil then
      begin
        FontList^.Insert(NewDoubleStr(P^.Desc, FontRes^));
        Dispose(P, Done);
      end;
    end;

    procedure Load;
    begin
      LoadDiskFont(AddBackslash(FontPath)+FontChosen);
    end;

  begin
    SelectFontDialog:=False;
    New(FontList, Init(20, 10));

   {$IFDEF DiskFonts}
    ScanFontFiles(FontPath, SelectFiles);
   {$ENDIF}

   {$IFDEF ResFonts}
    if ResFile<>Nil then
    begin
      ResFonts:=PStringCollection(ResFile^.Get(toyFontListKey));
      ResFonts^.ForEach(@AddFont);
      Dispose(ResFonts, Done);
    end;
   {$ENDIF}

    if FontList^.Count=0 then
      MessageBox(^C'No font files found!', Nil, mfError+mfOKButton)
    else
      if SelectFont(FontList, FontChosen) then
      begin
       {$IFDEF DiskFonts}
         {$IFDEF ResFonts}
          if (Length(FontChosen)>3) and
             MemComp(FontChosen[Length(FontChosen)-3],
                     toyFontExt[1], Length(toyFontExt)) then
            Load
          else
         {$ELSE}
          Load;
         {$ENDIF}
       {$ENDIF}
       {$IFDEF ResFonts}
        LoadResFont(ResFile, FontChosen);
       {$ENDIF}

        SelectFontDialog:=True;
      end;

    Dispose(FontList, Done);
  end;


(***************************************************************************
***************************************************************************)

  (*******************************************************************
    This code generated by Dialog Design 4.0
  *******************************************************************)
  constructor TSelFontDialog.Init;
    var
      R : TRect;
      Control : PView;
  begin
    R.Assign(15, 2, 64, 21);
    inherited Init(R, 'Select a Font');
    Options := Options or ofCentered;

    R.Assign(44, 3, 45, 15);
    Control := New(PScrollBar, Init(R));
    Insert(Control);

    R.Assign(4, 3, 44, 15);
    Control := New(PSortedListBox, Init(R, 1, PScrollbar(Control)));
    Control^.HelpCtx := hctoyFontListbox;
    Insert(Control);

    R.Assign(3, 2, 8, 3);
    Insert(New(PLabel, Init(R, '~F~onts', Control)));

    R.Assign(7, 16, 17, 18);
    Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
    Control^.HelpCtx := hcOK;
    Insert(Control);

    R.Assign(19, 16, 29, 18);
    Control := New(PButton, Init(R, 'Cancel', cmCancel, bfLeftJust));
    Control^.HelpCtx := hcCancel;
    Insert(Control);

    R.Assign(31, 16, 41, 18);
    Control := New(PButton, Init(R, 'Help', cmHelp, bfNormal));
    Control^.HelpCtx := hctoyFontDialogHelp;
    Insert(Control);

    SelectNext(False);
  end;


  (*******************************************************************
    Double click in list box acts like Enter key
  *******************************************************************)
  procedure TSelFontDialog.HandleEvent;
  begin
    inherited HandleEvent(Event);
    if (Event.What=evBroadcast) and (Event.Command=cmListItemSelected) then
      EndModal(cmOK);
  end;


(***************************************************************************
***************************************************************************)

  var
    ListRec :
      record
        List      : PDblStringCollection;
        Selection : Word;
      end;

  (*******************************************************************
    Execute font selection dialog
  *******************************************************************)
  function SelectFont(List:PDblStringCollection; var Name:String):Boolean;
  begin
    SelectFont:=False;
    ListRec.List:=List;
    if Application^.ExecuteDialog(New(PSelFontDialog, Init), @ListRec)<>cmCancel then
    begin
      Name:=PString(ListRec.List^.At2nd(ListRec.Selection))^;
      SelectFont:=True;
    end;
  end;


    (*******************************************************************
    *******************************************************************)

end.
