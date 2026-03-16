{*****************************************************************************

  OOGrid Library(TM) for Borland/Turbo Pascal (Real Mode/TV)
  Copyright (C) 1994, 1995 by Arturo J. Monge
  Portions Copyright (C) 1989,1990 Borland International, Inc.

  OOGrid Library(TM) Demo Program:
    Example program of how to use a TSpreadSheet object in an
    application.  Demonstrates how to create, load and save
    spreadsheets, how to modify the standard application palette
    to support the use of a TSpreadSheet object and how to set up
    the program resources so that they can be used by the
    TSpreadSheet object.

  Copyright (C) 1994, 1995 by Arturo J. Monge

  Last Modification : May 31st, 1994

*****************************************************************************}

program OOGL_DemoProgram;

{$O+,F+,X+}

uses Dos, App, Objects, Views, Drivers, Gadgets, MsgBox, Menus, Memory,
     HelpFile, StdDlg, Dialogs, GLViews, GLEquate, GLWindow, GLTSheet,
     GLSupprt, DemoEqu,
     TCUtil { OOGL_DemoProgram uses TCUtil's UpperCase function };

var
  DemoStrings : PStringList;
  { String list used by OOGL_DemoProgram }

  DemoResource : TResourceFile;
  { Resource file used by OOGL_DemoProgram }

const
  ResourceFileName = 'DEMO_GL.TVR';
  { Filename of the file that contains the resource used by OOGL_DemoProgram }

const
  HelpInUse : Boolean = False;
  { Is set to true when the help window is active }

const
  MaxNumberOfFiles = 255;

type
  FileNumbers = Set of 1..MaxNumberOfFiles;

var
  FilesOpen  : FileNumbers;
  { Keeps track of which FileNumbers are currently in use }

  SaveMem : LongInt;
  { Used to determine if all memory has been properly disposed by the program }

function CalcName(AName: String): PathStr; forward;
function NewNumberAvailable (var NewFileNumber:Integer;
  var FilesOpen:FileNumbers):Boolean; forward;

type
  POOGridLibraryDemo = ^TOOGridLibraryDemo;
  TOOGridLibraryDemo = object(TApplication)
      HelpFile   : PathStr;
      Clock      : PClockView;
      HeapViewer : PHeapView;
    constructor Init(HelpFileName: String);
    procedure AddClock; virtual;
    procedure AddHeapViewer; virtual;
    procedure AddSpreadSheet; virtual;
    function GetPalette:PPalette; virtual;
    procedure GetEvent (var Event:TEvent); virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
    procedure Idle; virtual;
    procedure InitMenuBar; virtual;
    procedure InitStatusLine; virtual;
    procedure LoadSpreadSheet(FileName: PathStr); virtual;
    procedure SaveSpreadSheet(NewName: Boolean); virtual;
    procedure OutofMemory; virtual;
    procedure ShowWindowList; virtual;
    destructor Done; virtual;
  end; {...TOOGridLibraryDemo }


  PHCStatusLine = ^THCStatusLine;
  THCStatusLine = object(TStatusLine)
    function Hint(AHelpCtx: Word): String; virtual;
  end; {...THCStatusLine }


  PMySpreadSheet = ^TMySpreadSheet;
  TMySpreadSheet = object(TSpreadSheetWindow)
  { A descendant of TSpreadSheetWindow that owns a TSpreadSheet object.
    An instance of TSpreadSheet is created and inserted into TMySpreadSheet
    in the Init method.  It also overrides the GetPalette method to map the
    color entries the standard palette entries after the help system's
    palette }
    constructor Init(Bounds : TRect; ATitle : String; ANumber: Byte);
    function GetPalette: PPalette; virtual;
    destructor Done; virtual;
  end; {...TMySpreadSheet }


  PWinTitleCollection = ^TWinTitleCollection;
  TWinTitleCollection = object(TStringCollection)
  { Aa string collection used by TWindowList that doesn't cause a run-time
    error whenever an error ocurrs.  Instead, it set the Status attribute to
    1 when an error ocurrs.  This is to avoid an unwanted run-time error when
    there is not enough memory to list all active windows in a TWindowList
    object }
      Status : Byte; { Status of the collection:
                       0 : OK
                       1 : Error ocurred }
    constructor Init(ALimit, ADelta: Integer);
    procedure Error(Code, Info: Integer); virtual;
  end; {...TWinTitle Collection }



  PWindowListBox = ^TWindowListBox;
  TWindowListBox = object(TSortedListBox)
  { Handles double-clicking by generating a cmOk command. It is used by
    TWindowList to list all open windows. }
    procedure HandleEvent(var Event:TEvent); virtual;
  end; {...TWindowListBox }



  PWindowList = ^TWindowList;
  TWindowList = object(TDialog)
  { A dialog that allows the user to select or delete a window in the desktop
    from a list }
      WinBox : PWindowListBox;
    constructor Init(Bounds:TRect);
    procedure BuildWindowList(var TitleList: PWinTitleCollection);
    procedure DeleteWindow;
    procedure HandleEvent(var Event:TEvent); virtual;
    constructor Load(var S: TStream);
    procedure SelectWindow;
    procedure Store(var S: TStream);
    destructor Done; virtual;
  end; {...TWindowList }


{** THCStatusLine **}

function THCStatusLine.Hint(AHelpCtx: Word): String;
begin
   Hint := DemoStrings^.Get(AHelpCtx);
end; {...THCStatusLine.Hint }


{** TMySpreadSheet **}

constructor TMySpreadSheet.Init(Bounds: TRect; ATitle: String; ANumber: Byte);
var
   R : TRect;
   SpreadSheet : PSpreadSheet;
begin
   TSpreadSheetWindow.Init(Bounds, ATitle, ANumber);
   GetExtent(R);
   R.Grow(-1,-1);
   SpreadSheet := New(PSpreadSheet, Init(R, 0, DefaultEmptyRowsAtTop,
     DefaultEmptyRowsAtBottom, StandardScrollBar(sbHorizontal),
     StandardScrollBar(sbVertical),DefaultMaxCols, DefaultMaxRows,
     DefaultDefaultColWidth, DefaultDefaultDecimalPlaces,
     DefaultMaxDecimalPlaces, DefaultCurrencyString));

   Insert(SpreadSheet);
end; {...TMySpreadSheet.Init }

function TMySpreadSheet.GetPalette: PPalette;
const
  CNewPalette = CBlueWindow + CSpreadSheetWindow2;
  PNewPalette : string[Length(CNewPalette)] = CNewPalette;
begin
  GetPalette := @PNewPalette;
end; {...TMySpradSheet.GetPalette }

destructor TMySpreadSheet.Done;
begin
  { Make available the number used by the instance of TMySpreadSheet
    being closed }
  FilesOpen := FilesOpen - [Number];
  TSpreadSheetWindow.Done;
end; {...TMySpreadSheet.Done }



{** TOOGridLibraryDemo **}

constructor TOOGridLibraryDemo.Init(HelpFileName: String);
begin
  TApplication.Init;
  if HelpFileName = '' then
    HelpFile := ''
  else
    HelpFile := CalcName(HelpFileName);
  FilesOpen := [];
  AddClock;
  AddHeapViewer;
end; {...TOOGridLibraryDemo.Init }


procedure TOOGridLibraryDemo.AddClock;
{ Adds a clock to the application in the upper right corner }
var
  R : TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  R.A.X := R.B.X - 9;
  Clock := New(PClockView, Init(R));
  Insert(Clock);
end; {...TOOGridLibraryDemo.AddClock }


procedure TOOGridLibraryDemo.AddHeapViewer;
{ Insert an indicator of the available memory in the lower left corner }
var
  R : TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  R.A.X := R.B.X - 9;
  HeapViewer := New(PHeapView, Init(R));
  Insert(HeapViewer);
end; {...TOOGridLibraryDemo.AddHeapViewer }


procedure TOOGridLibraryDemo.AddSpreadSheet;
{ Creates a new spreadsheet and inserts it in the desktop }
var
   NewNumber : Integer;
   NumberStr : String;
   SpreadSheet : PMySpreadSheet;
   R, Limits : TRect;
begin
  if not NewNumberAvailable(NewNumber, FilesOpen) then
  begin
    MessageBox(DemoStrings^.Get(sMaxFilesOpenError), NIL,
      mfError + mfOkButton);
    Exit;
  end; {...if not NewNumberAvailable(NewNumber, FilesOpen) }

  { Determine the window's new bounds }

  if Desktop^.Current <> NIL then
    begin
      R.A := Desktop^.Current^.Origin;
      R.B.X := R.A.X + Desktop^.Current^.Size.X;
      R.B.Y := R.A.Y + Desktop^.Current^.Size.Y;
      Inc(R.A.X);
      Inc(R.A.Y);
    end {...if Desktop^.Current <> NIL }
  else
    Desktop^.GetExtent(R);
  Str(NewNumber, NumberStr);
  SpreadSheet := New(PMySpreadSheet, Init(R,
    DemoStrings^.Get(sNoNameFileName)+NumberStr, NewNumber));

  { Verify that the new bounds are not below the allowed limits }
  SpreadSheet^.SizeLimits(Limits.A, Limits.B);
  if ((R.B.Y - R.A.Y) < Limits.A.Y) or ((R.B.X - R.A.X) < Limits.A.X) then
  begin
    Desktop^.GetExtent(R);
    SpreadSheet^.ChangeBounds(R);
  end; {...if ((R.B.Y - R.A.Y) < Limits.A.Y) or ... }

  if Application^.ValidView(Spreadsheet) <> nil then
    begin
      Desktop^.Insert(SpreadSheet);
      EnableCommands([cmSave, cmSaveAs, cmPrintSheet, cmYes, cmNo,
      cmCloseAll]);
    end { if }
  else
    Dispose(Spreadsheet, Done);
end; { TOOGridLibraryDemo.AddSpreadsheet }

function TOOGridLibraryDemo.GetPalette: PPalette;
{ Adds palette items to the standard application palette for the help system
  and for the TSpreadSheet object}
const
  CNewColor = CColor + CHelpColor + CSpreadSheetColor;
  CNewBlackWhite = CBlackWhite + CHelpBlackWhite + CSpreadSheetBlackWhite;
  CNewMonochrome = CMonochrome + CHelpMonochrome + CSpreadSheetMonochrome;
  P: array[apColor..apMonochrome] of string[Length(CNewColor)] =
    (CNewColor, CNewBlackWhite, CNewMonochrome);
begin
  GetPalette := @P[AppPalette];
end; {...TOOGridLibraryDemo.GetPalette }


procedure TOOGridLibraryDemo.GetEvent(var Event: TEvent);
{ Handles the cmHelp command by displaying context sensitive help }
var
  HelpBox    : PWindow;
  HFile      : PHelpFile;
  HelpStrm   : PDosStream;
begin
  TApplication.GetEvent(Event);
  case Event.What of
    evCommand:
      if (Event.Command = cmHelp) and (HelpFile <> '') and
        not HelpInUse then
      begin
        HelpInUse := True;
        HelpStrm := New(PBufStream, Init(HelpFile, stOpenRead, 2048));
        HFile := New(PHelpFile, Init(HelpStrm));
        if HelpStrm^.Status <> stOk then
          begin
            MessageBox(DemoStrings^.Get(sHelpAccessError), NIL,
              mfError + mfCancelButton);
            Dispose(HFile, Done);
            ClearEvent(Event);
          end {...if HelpStrm^.Status <> stOk }
        else
          begin
            HelpBox := New(PHelpWindow,Init(HFile, GetHelpCtx));
            if ValidView(HelpBox) <> nil then
            begin
              ExecView(HelpBox);
              Dispose(HelpBox, Done);
            end; {...if ValidView(HelpBox) <> NIL }
            ClearEvent(Event);
          end; {...else/if }
        HelpInUse := False;
      end; {...if (Event.Command = cmHelp) and not HelpInUse }

    evMouseDown:
      if Event.Buttons <> 1 then
        Event.What := evNothing;
  end; {...case Event.What }
end; {...TOOGridLibraryDemo.GetEvent }


procedure TOOGridLibraryDemo.HandleEvent(VAR Event : TEvent);
{ Handles common commands like cmTile, cmCascade, cmDosShell, cmVideoMode
  and cmList, plus application especific commands }

    procedure ChangeVideo;
    var
      NewMode : Word;
    begin
      Dispose(HeapViewer, Done);
      NewMode := ScreenMode xor smFont8x8;
      if NewMode and smFont8x8 <> 0 then
        ShadowSize.X := 1
      else
        ShadowSize.X := 2;
      SetScreenMode(NewMode);
      AddHeapViewer;
    end; {...ChangeVideo }

{$ifdef ver60}

    procedure DosShell;
    begin
      DoneSysError;
      DoneEvents;
      DoneVideo;
      DoneMemory;
      SetMemTop(HeapPtr);
      PrintStr(DemoStrings^.Get(sShellMsg));
      SwapVectors;
      Exec(GetEnv('COMSPEC'), '');
      SwapVectors;
      SetMemTop(HeapEnd);
      InitMemory;
      InitVideo;
      InitEvents;
      InitSysError;
      Redraw;
    end; {...GoToDos }

    procedure Tile;
    var
      R: TRect;
    begin
      Desktop^.GetExtent(R);
      Desktop^.Tile(R);
    end; {...Tile }

    procedure Cascade;
    var
      R: TRect;
    begin
      Desktop^.GetExtent(R);
      Desktop^.Cascade(R);
    end; {...Cascade }

{$endif}

    procedure CloseAll;
    { Close all open windows in the desktop, by disposing it and
      creating a new instance of TDesktop }
    begin
       Dispose(Desktop, Done);
       InitDesktop;
       Insert(Desktop);
    end; {...CloseAll }

    procedure DisplayDialog(ResourceKey: String);
    var
      Dialog : PDialog;
    begin
      Dialog := PDialog(DemoResource.Get(ResourceKey));
      if Application^.ValidView(Dialog) <> NIL then
        Desktop^.ExecView(Dialog);
      if Dialog <> NIL then
        Dispose(Dialog, Done);
    end; {...DisplayDialog }



begin
  TApplication.HandleEvent(Event);
  if (Event.what = evCommand) then
    case Event.Command of
      cmAbout         : DisplayDialog('AboutDialog');
      cmAuthorInfo    : DisplayDialog('AuthorDialog');
      cmCascade       : Cascade;
      cmChDir         : DisplayDialog('ChDirDialog');
      cmCloseAll      : CloseAll;
      cmDosShell      : DosShell;
      cmList          : ShowWindowList;
      cmLoadTypes     : LoadSpreadSheet(CalcName('EX_TYPES.OGL'));
      cmLoadFunctions : LoadSpreadSheet(CalcName('EX_FUNCT.OGL'));
      cmLoadList1     : LoadSpreadSheet(CalcName('EX_LIST1.OGL'));
      cmLoadList2     : LoadSpreadSheet(CalcName('EX_LIST2.OGL'));
      cmLoadErrors    : LoadSpreadSheet(CalcName('EX_ERROR.OGL'));
      cmLoadDataEntry : LoadSpreadSheet(CalcName('EX_ENTRY.OGL'));
      cmNewSheet      : AddSpreadSheet;
      cmOpen          : LoadSpreadSheet('');
      cmRefresh       : Application^.Redraw;
      cmRegister      : DisplayDialog('RegistrationDialog');
      cmSave          : SaveSpreadSheet(False);
      cmSaveAs        : SaveSpreadSheet(True);
      cmTile          : Tile;
      cmVideoMode     : ChangeVideo;
    end; {...case Event.Command }
end; {...TOOGridLibraryDemo.HandleEvent }


procedure TOOGridLibraryDemo.Idle;
{ Determines if the current view is tileable and enables or disables menu
  commands accordingly.  It also updates the clock and the heap viewer }

    function IsTileable(P: PView): Boolean; far;
    begin
      IsTileable := P^.Options and ofTileable <> 0;
    end; {...IsTileable }

begin
  TApplication.Idle;
  if not (Clock = NIL) then
     Clock^.Update;
  if not (HeapViewer = NIL) then
     HeapViewer^.Update;
  If Desktop^.FirstThat(@IsTileable) <> nil then
    EnableCommands([cmTile, cmCascade])
  else
    DisableCommands([cmTile, cmCascade]);
  if (DeskTop^.Current = NIL) and (HelpInUse = False) then
    SetCommands ([cmNewSheet, cmOpen, cmDosShell, cmQuit, cmList, cmHelp,
      cmChDir, cmAbout, cmAuthorInfo, cmRegister, cmRefresh, cmVideoMode,
      cmOk, cmDeleteWin, cmCancel, cmMenu, cmLoadTypes, cmLoadFunctions,
      cmLoadList1, cmLoadList2, cmLoadErrors, cmLoadDataEntry]);
end; {...TOOGridLibraryDemo.Idle }


procedure TOOGridLibraryDemo.InitMenuBar;
begin
  MenuBar := PMenuBar(DemoResource.Get('MenuBar'));
end; {...TOOGridLibraryDemo.InitMenuBar }

procedure TOOGridLibraryDemo.InitStatusLine;
var
  R : TRect;
begin
  R.Assign(0, 24, 80, 25);
  StatusLine := New(PHCStatusLine, Init(R,
    NewStatusDef(0, 1000,
       NewStatusKey('~Alt-F1~ Info', kbAltF1, cmAbout,
       NewStatusKey('', kbF10, cmMenu,
       NewStatusKey('', kbAltX, cmQuit,
       NewStatusKey('', kbAltF3, cmClose,
       NewStatusKey('', kbF5, cmZoom,
       NewStatusKey('', kbCtrlF5, cmResize,
       NewStatusKey('', kbF6, cmNext,
       NIL))))))),
    NIL)));
end; {...TOOGridLibraryDemo.InitStatusBar }

procedure TOOGridLibraryDemo.LoadSpreadSheet(FileName: PathStr);
{ Loads a spreadsheet from disk }
var
  Stream : PBufStream;
  Dialog : PDialog;
  NewSS : PMySpreadSheet;
  NewNumber : Integer;
  R, Limits : TRect;
begin
  if FileName = '' then
  begin
    Dialog := PDialog(DemoResource.Get('LoadDialog'));
    if Application^.ValidView(Dialog) = NIL then
       Exit
    else
      begin
        if Desktop^.ExecView(Dialog) <> cmCancel then
           Dialog^.GetData(FileName)
        else
           begin
              Dispose(Dialog, Done);
              Exit;
           end; {...if/else }
      end; {...if/else }
    Dispose(Dialog, Done);
  end; {...if FileName = '' }
  Stream := New(PBufStream, Init(FileName, stOpenRead, 1024));
  if Stream^.Status <> 0 then
  begin
    MessageBox(DemoStrings^.Get(sFileNotFound), NIL, mfError + mfOkButton);
    Dispose(Stream, Done);
    Exit;
  end; {...if Stream^.Status <> 0 }
  DisplayMessage(DemoStrings^.Get(sLoadMessage));
  NewSS := PMySpreadSheet(Stream^.Get);
  EraseMessage;
  if Stream^.Status <> 0 then
  begin
    if Stream^.Status = stInvalidFormatError then
    { Two new stream status constants are used by OOGrid Library(TM) v1.0:
      stInvalidFormatError and stNoMemoryError.  They are defined in
      the GLSupprt unit }
      MessageBox(DemoStrings^.Get(sInvalidFormat), NIL, mfError + mfOkButton)
    else if Stream^.Status <> stNoMemoryError then
    { Memory errors are reported by the LowMemory function; there is no
      need to report them again }
      MessageBox(DemoStrings^.Get(sAccessError), NIL, mfError + mfOkButton);
    Dispose(NewSS, Done);
    Dispose(Stream, Done);
    Exit;
  end; {...if Stream^.Status <> 0 }
  Dispose(Stream, Done);
  if not NewNumberAvailable(NewNumber, FilesOpen) then
  begin
    MessageBox(DemoStrings^.Get(sMaxFilesOpenError), NIL,
      mfError + mfOkButton);
    Exit;
  end; {...if not NewNumberAvailable(NewNumber, FilesOpen) }

  { Set the title to the current filename }
  if NewSS^.Title <> NIL then
    DisposeStr(NewSS^.Title);
  NewSS^.Title := NewStr(FileName);

  NewSS^.Number := NewNumber;

  { Determine the window's new bounds }
  if Desktop^.Current <> NIL then
    begin
      R.A := Desktop^.Current^.Origin;
      R.B.X := R.A.X + Desktop^.Current^.Size.X;
      R.B.Y := R.A.Y + Desktop^.Current^.Size.Y;
      Inc(R.A.X);
      Inc(R.A.Y);

      { Verify that the new bounds are not below the allowed limits }
      NewSS^.SizeLimits(Limits.A, Limits.B);
      if ((R.B.Y - R.A.Y) < Limits.A.Y) or ((R.B.X - R.A.X) < Limits.A.X) then
        Desktop^.GetExtent(R);
    end {...if Desktop^.Current <> NIL }
  else
    Desktop^.GetExtent(R);

  NewSS^.ChangeBounds(R);
  Desktop^.Insert(NewSS);
  EnableCommands([cmSave, cmSaveAs, cmPrintSheet, cmYes, cmNo, cmCloseAll]);
end; {..TOOGridLibraryDemo.LoadSpreadSheet }


procedure TOOGridLibraryDemo.OutofMemory;
var
  R : TRect;
begin
  R.Assign(20,8,58,17);
  MessageBox(DemoStrings^.Get(sNoMemError), NIL, mfError + mfCancelButton);
end; {...TOOGridLibraryDemo.OutOfMemory }


procedure TOOGridLibraryDemo.SaveSpreadSheet(NewName: Boolean);
{ Saves a spreadsheet to disk }
var
  Stream : PBufStream;
  Dialog : PDialog;
  CurrSS : PMySpreadSheet;
  FileName : PathStr;
begin
  CurrSS := PMySpreadSheet(Desktop^.Current);

  if NewName or (Copy(CurrSS^.Title^, 1,
    Length(DemoStrings^.Get(sNoNameFileName))) =
    DemoStrings^.Get(sNoNameFileName)) then
  { if the file will be saved under a new name or if the file does not
    have a name, prompt the user for a new name }
    begin
      Dialog := PDialog(DemoResource.Get('SaveDialog'));
      if Application^.ValidView(Dialog) = NIL then
         Exit
      else
        begin
          if Desktop^.ExecView(Dialog) <> cmCancel then
            begin
              Dialog^.GetData(FileName);

              { Change the window's title }
              if CurrSS^.Title <> NIL then
                DisposeStr(CurrSS^.Title);
              CurrSS^.Title := NewStr(FileName);
              CurrSS^.Redraw;
            end {...if Desktop^.ExecView(Dialog) <> cmCancel }
          else
             begin
                Dispose(Dialog, Done);
                Exit;
             end; {...if/else }
          end; {...if else }
      Dispose(Dialog, Done);
    end {...if NewName or ... }
  else
    FileName := CurrSS^.Title^;
  Stream := New(PBufStream, Init(FileName, stCreate, 1024));
  if Stream^.Status <> 0 then
  begin
    MessageBox(DemoStrings^.Get(sCreateStreamError), NIL, mfError +
      mfOkButton);
    Dispose(Stream, Done);
    Exit;
  end; {...if Stream^.Status <> 0 }
  DisplayMessage(DemoStrings^.Get(sSaveMessage));
  Stream^.Put(Desktop^.Current);
  EraseMessage;
  if Stream^.Status <> 0 then
    MessageBox(DemoStrings^.Get(sSaveError), NIL, mfError + mfOkButton);
  Dispose(Stream, Done);

end; {..TOOGridLibraryDemo.SaveSpreadSheet }


procedure TOOGridLibraryDemo.ShowWindowList;
{ Shows a dialog for selecting a window from a list of active windows }

var
  WindowLst    : PWindowList;
  CurrSelected : PWindow;
  R            : TRect;
begin
  R.Assign(0,0,60,15);
  WindowLst := New(PWindowList, Init(R));
  if Application^.ValidView(WindowLst) <> NIL then
  begin
    If (ExecView(WindowLst) <> cmCancel) then
    begin
      CurrSelected := PWindow(DeskTop^.Current);
      If (CurrSelected^.Flags and wfClose <> 0) then
        EnableCommands([cmClose])
      else
        DisableCommands([cmClose]);
      CommandSetChanged := True;
    end; {...if (ExecView(WindowLst) <> cmCancel) }
    Dispose(WindowLst, Done);
  end; {...if (Application^.ValidView(WindowLst) = PView(WindowLst)) }
end; {...ShowWindowList }


destructor TOOGridLibraryDemo.Done;
begin
  if not (Clock = NIL) then
     Dispose(Clock, Done);
  if not (HeapViewer = NIL) then
     Dispose(HeapViewer, Done);
  TApplication.Done;
end; {...TOOGridLibraryDemo.Done }



{** TWindowList **}

constructor TWindowList.Init(Bounds: TRect);
{ The BuildList parameter tells the object if it should or should not
  build the list of open windows. }
var
  SizeX, SizeY : Integer;
  Control : PView;
  TitleList : PWinTitleCollection;
  WinBoxLabel : String;
  R : TRect;
begin
  SizeX := (Bounds.B.X - Bounds.A.X);
  SizeY := (Bounds.B.Y - Bounds.A.Y);
  If ((SizeY MOD 2) = 0) then
  begin
    Inc(Bounds.B.Y);
    Inc(SizeY);
  end; {...if ((SizeY MOD 2) = 0) }
  TDialog.Init(Bounds, 'Window list...');
  HelpCtx := hcWinListDlgHelp;
  Options := Options + ofCentered;

  R.A.X := (SizeX - 14);
  R.A.Y := 3;
  R.B.X := (R.A.X + 12);
  R.B.Y := 5;
  Control := New(PButton, Init(R, '~O~k', cmOk, bfDefault));
  Control^.HelpCtx := hcOk;
  Insert(Control);

  R.A.X := (SizeX - 14);
  R.A.Y := (((SizeY - 5) DIV 3) + 3);
  R.B.X := (R.A.X + 12);
  R.B.Y := R.A.Y + 2;
  Control := New(PButton, Init(R, '~D~elete', cmDeleteWin, bfNormal));
  Control^.HelpCtx := hcDeleteWin;
  Insert(Control);

  R.A.X := (SizeX - 14);
  R.A.Y := (SizeY - 3)-((SizeY - 5) DIV 3);
  R.B.X := (R.A.X + 12);
  R.B.Y := R.A.Y + 2;
  Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
  Control^.HelpCtx := hcCancel;
  Insert(Control);

  R.A.X := (SizeX - 14);
  R.A.Y := (SizeY - 3);
  R.B.X := (R.A.X + 12);
  R.B.Y := R.A.Y + 2;
  Control := New(PButton, Init(R, 'Help', cmHelp, bfNormal));
  Insert(Control);

  R.A.X := (SizeX - 16);
  R.A.Y := 3;
  R.B.X := R.A.X + 1;
  R.B.Y := (SizeY - 2);
  Control := New(PScrollBar, Init(R));
  Insert(Control);

  R.A.X := 3;
  R.A.Y := 3;
  R.B.X := (SizeX - 16);
  R.B.Y := (SizeY - 2);
  WinBox := New(PWindowListBox, Init(R, 1, PScrollBar(Control)));
  TitleList := New(PWinTitleCollection, Init(12,1));
  BuildWindowList(TitleList);
  WinBox^.NewList(TitleList);
  WinBox^.HelpCtx := hcWinList;
  Insert(WinBox);

  WinBoxLabel := '~W~indows';
  R.A.X := 2;
  R.A.Y := 2;
  R.B.X := R.A.X + Length(WinBoxLabel);
  R.B.Y := 3;
  Insert(New(PLabel, Init(R, WinBoxLabel, WinBox)));
end; {...TWindowList.Init }


procedure TWindowList.BuildWindowList(var TitleList: PWinTitleCollection);
{ Builds a list of all selectable active windows in the desktop }
var
  Curr     : PWindow;
  ListText : PString;
begin
  if not(DeskTop^.Current = NIL) then
  begin
    Curr := PWindow(DeskTop^.First);
    repeat
      if (Curr^.Options and ofSelectable <> 0) then
      begin
        ListText := NewStr(UpperCase(Curr^.Title^));
        TitleList^.Insert(ListText);
      end; {...if (Curr^.Options and ofSelectable <> 0) }
      Curr := PWindow(Curr^.Next);
    until (Curr = PWindow(DeskTop^.Last)) or (TitleList^.Status = 1);
    if TitleList^.Status = 1 then
       MessageBox('Not enough memory to list all open windows.', NIL,
                  mfInformation + mfOkButton);
  end; {...if not(DeskTop^.Current = NIL) }
end; {...TWindowList.BuildWindowList }


procedure TWindowList.DeleteWindow;
{ Closes a window in the desktop }

    function SameTitle(CurrWin: PWindow): boolean; Far;
    begin
      if CurrWin^.Title^ = WinBox^.GetText(WinBox^.Focused, 80) then
         SameTitle := True
      else
         SameTitle := False;
    end; {...SameTitle }

var
  DelMessage   : Pointer;
  WinFocused   : Integer;
  ViewToDelete : PWindow;
begin
  ViewToDelete := PWindow(DeskTop^.FirstThat(@SameTitle));
  if not (ViewToDelete = NIL) and
     (ViewToDelete^.Flags and wfClose <> 0) then
  begin
    DelMessage := Message(ViewToDelete, evCommand, cmClose, nil);
    WinFocused := WinBox^.Focused;
    WinBox^.List^.AtFree(WinFocused);
    Dec(WinBox^.Range);
    If (WinFocused > (WinBox^.Range - 1)) and (Winbox^.Range > 1) then
      WinBox^.FocusItem(WinBox^.Range - 1);
    WinBox^.DrawView;
  end; {...if not(ViewToDelete = NIL) and ... }
end; {...TWindowList.DeleteWindow }


procedure TWindowList.HandleEvent(var Event: TEvent);
{ Handles the events for selecting and deleting windows in the desktop }
begin
  if (Event.what = evCommand) then
    case Event.Command of
      cmOk         : SelectWindow;
      cmDeleteWin  : DeleteWindow;
    end; {...case Event.Command }
  TDialog.HandleEvent(Event);
end; {...TWindowList.HandleEvent }

constructor TWindowList.Load(var S: TStream);
{ Loads the dialog from a stream }
var
   TitleList : PWinTitleCollection;
begin
  TDialog.Load(S);
  GetSubViewPtr(S, WinBox);
  TitleList := New(PWinTitleCollection, Init(12,1));
  BuildWindowList(TitleList);
  WinBox^.NewList(TitleList);
end; {...TWindowList.Load }


procedure TWindowList.SelectWindow;
{ Selects a window in the desktop }

    function SameTitle(CurrWin: PWindow): boolean; Far;
    begin
      if CurrWin^.Title^ = WinBox^.GetText(WinBox^.Focused, 256) then
         SameTitle := True
      else
         SameTitle := False;
    end; {...SameTitle }

begin
  PWindow(DeskTop^.FirstThat(@SameTitle))^.Select;
end; {...TWindowList.SelectWindow }

procedure TWindowList.Store(var S: TStream);
begin
  TDialog.Store(S);
  PutSubViewPtr(S, WinBox);
end; {...TWindowList.Store }


destructor TWindowList.Done;
begin
   if NOT(WinBox^.List = NIL) then
     Dispose (WinBox^.List, Done);
   TDialog.Done;
end; {...TWindowList.Done }



{** TWindowListbox **}

procedure TWindowListBox.HandleEvent(var Event:TEvent);
{ Handles double-clicking by generating a cmOk event }
begin
  if (Event.What = evMouseDown) and (Event.Double) then
    begin
      Event.What := evCommand;
      Event.Command := cmOK;
      PutEvent(Event);
      ClearEvent(Event);
    end {...if (Event.What = evMouseDown) and (Event.Double) }
  else
    TSortedListBox.HandleEvent(Event);
end; {...TWindowListBox.HandleEvent }



{** TWinTitleCollection **}

constructor TWinTitleCollection.Init(ALimit, ADelta: Integer);
begin
   TStringCollection.Init(ALimit, ADelta);
   Status := 0;
end; {...TWinTitleCollection.Init }


procedure TWinTitleCollection.Error(Code, Info: Integer);
{ Sets the status attribute to 1 so that any external method or procedure
  knows when an error has ocurred }
begin
   Status := 1;
end; {...TWinTitleCollection.Error }


{** CalcName function **}

function CalcName(AName: String): PathStr;
{ Calculates the path name of the given file, by searching the directory
  of the .EXE file and the DOS Path}
var
  PathName : PathStr;
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
begin
  FSplit(ParamStr(0), Dir, Name, Ext);
  if Dir[Length(Dir)] = '\' then Dec(Dir[0]);
  PathName := FSearch(AName, Dir);
  if PathName = '' then
    PathName := FSearch(AName, GetEnv('PATH'));
  CalcName := PathName;
end; {...CalcName }


{** NewNumberAvailable function **}

function NewNumberAvailable (var NewFileNumber:Integer;
  var FilesOpen:FileNumbers):Boolean;
{ Keeps track of which FileNumbers have been used and returns the lowest
  available number }
var
  Number : Integer;
begin
  NewNumberAvailable := False;
  for Number := 1 to MaxNumberofFiles do
    if not (Number in FilesOpen) then
    begin
      NewFileNumber := Number;
      FilesOpen := FilesOpen + [NewFileNumber];
      NewNumberAvailable := True;
      Exit;
    end; {...if not (Number in FilesOpen ) }
end; {...NewNumberAvailable }


{** Registration records **}

const
   RMySpreadSheet : TStreamRec = (
      ObjType : 1100;
      VmtLink : Ofs(TypeOf(TMySpreadSheet)^);
      Load    : @TMySpreadSheet.Load;
      Store   : @TMySpreadSheet.Store
   );

{** RegisterAll procedure **}

procedure RegisterAll;
begin
  RegisterType(RStringList);
  RegisterDialogs;
  RegisterViews;
  RegisterStdDlg;
  RegisterMenus;
  RegisterHelpFile;
  RegisterSpreadSheet;
  RegisterType(RMySpreadSheet);
end; {...RegisterAll }

{****************************************************************************}
{                               MAIN PROGRAM                                 }
{****************************************************************************}

var
  Demo : TOOGridLibraryDemo;

begin
  RegisterAll;
  SaveMem := MemAvail;

  DemoResource.Init(New(PBufStream, Init(ResourceFileName, stOpenRead, 1024)));
  if DemoResource.Stream^.Status <> stOk then
  begin
    writeln('Resource not found...program aborted');
    halt(1);
  end; {...if DemoResource.Stream^.Status <> stOk }

  DemoStrings := PStringList(DemoResource.Get('Strings'));

  { Assign values to the GLResFile and GLStringList pointers in the
    GLSupprt unit, so that the spreadsheet object knows where to
    find the resources it needs }

  GLResFile := @DemoResource;
  GLStringList := PStringList(DemoResource.Get('SheetStrings'));

  if DemoResource.Stream^.Status <> stOk then
  begin
    writeln('Problems accesing resource file...program aborted');
    halt(1);
  end; {...if DemoResource.Stream^.Status <> stOk }
  Demo.Init('');
  Demo.Run;
  Demo.Done;

  Dispose(GLStringList, Done);
  Dispose(DemoStrings, Done);
  DemoResource.Done;

  if MemAvail <> SaveMem then
  begin
    writeln('Memory not de-allocated: ', MemAvail-SaveMem);
    writeln;
  end; {...if MemAvail <> SaveMem }
end. {...Program OOGL_DemoProgram }
