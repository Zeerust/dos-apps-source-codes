{********************************************************************

  OOGrid Library(TM) for Borland/Turbo Pascal (Real Mode/TV)
  Copyright (C) 1994, 1995 by Arturo J. Monge
  Portions Copyright (C) 1989,1990 Borland International, Inc.

  OOGrid Library(TM) Views Unit:
    Implements three TView's descendants used by the TSpreadSheet object
    and also defines the record variables used by the SetData and GetData
    methods of the dialogs used by TSpreadSheet.

  Copyright (C) 1994 by Arturo J. Monge

  Last Modification : December 29th, 1994

*********************************************************************}

unit GLViews;

{****************************************************************************}
                                 interface
{****************************************************************************}

uses Objects, Dialogs, Drivers, Views, GLEquate;

type

  PSheetInputLine = ^TSheetInputLine;
  TSheetInputLine = OBJECT(TInputLine)
  { An input line that can be inserted in a TSpreadSheetWindow object in
    modal state.  It maps to the color palette of the TSpreadsheetWindow
    object and handles kbEnter, kbEsc, kbUp and kbDown by ending the modal
    state of the view }
      EndState : Word;
    constructor Init(AMaxLen: Integer);
    procedure EndModal(Command: Word); virtual;
    function Execute: Word; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
  end; {...TSheetInputLine }

const

{ TSheetInputLine palette }

  CSheetInputLine = #9#9#10#11;

{ CSheetInputLine palette layout }

  { 1 = Passive }
  { 2 = Active }
  { 3 = Arrow }
  { 4 = Selected }

type

  PLimScrollBar = ^TLimScrollBar;
  TLimScrollBar = object(TScrollBar)
  { A TScrollBar's descendant that allows the definition of a display subrange.
    This is particularly useful if the TScroller object that owns the
    scrollbar has a very broad scrolling range (for example, 32767 columns).
    In this case, a normal TScrollBar object would be of no use at all,
    because one click in an arrow would move the scroller more than 1000
    columns. TLimScrollBar lets you define a smaller scrolling range, making
    it more useful than a TScrollBar }
      OldValue     : Word;
      DisplayLimit : Word;
    constructor Init(var Bounds: TRect; ADisplayLimit: Integer);
    function Change: Integer;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    constructor Load(var S: TStream);
    procedure Store(var S: TStream);
  end; {...TLimScrollBar }


  PMessageLine = ^TMessageLine;
  TMessageLine = object(TView)
  { Displays the string stored in the StatusMessage attribute.  This object
    is used to display status line messages }
      StatusMessage : String[79];
    constructor Init (Bounds:TRect; AMessage:String);
    procedure Draw; virtual;
  end; {...TMessageLine }

var
  MessageLine : PMessageLine;
  { Global variable used to display messages at the bottom of the screen }

var

{ Global record-type variables used with the GetData and SetData methods
  of TSpreadsheet's dialogs }

  RChangeHeader : record
  { Used by the ChangeHeader dialog }
    NewHeader : String[80]; {Inputline}
  end; {...RChangeHeader }

  RChangeWidth : record
  { Used by the ChangeWidth dialog }
    NewWidth : String[10]; {Inputline}
  end; {...RChangeWidth }

  RFormat : record
  { Used by the FormatCell dialog }
    Justification : Word; {RadioButtons}
    DecimalPlaces : String[1]; {Inputline}
    CurrencyChar : String[1]; {Inputline}
    NumberFormat : Word; {Checkboxes}
  end; {...RFormat }

  RGoToCell : record
  { Used by the GoTo dialog }
    NewCell : String[10]; {Inputline}
  end; {...RGoToCell }

  RCopyFormulas : record
  { Used by the CopyFormulas dialog }
    CopyFormulas : Word; {Checkboxes}
  end; {...RCopyFormulas }

  RPrint : record
  { Used by the Print dialog }
    PrintTo : Word; {RadioButtons}
    PrintSize : Word; {RadioButtons}
    PrintRows : Word; {RadioButtons}
    PrintColumns : Word; {RadioButtons}
    TopMargin : String[3]; {Inputline}
    BottomMargin : String[3]; {Inputline}
    LeftMargin : String[3]; {Inputline}
    RightMargin : String[3]; {Inputline}
    Other : Word; {Checkboxes}
    PageRows : String[3]; {Inputline}
    NormalCols : String[3]; {Inputline}
    CondensedCols : String[3]; {Inputline}
  end; {...RPrint }

  RSortInfo : record
  { Used by the Sort dialog }
    FirstKey : String[80]; {Inputline}
    FirstKeyOrder : Word; {RadioButtons}
    SecondKey : String[80]; {Inputline}
    SecondKeyOrder : Word; {RadioButtons}
    ThirdKey : String[80]; {Inputline}
    ThirdKeyOrder : Word; {RadioButtons}
  end; {...RSortInfo }

function DisplayMessage (AMessage:String): Boolean;
{ Displays a message at the bottom of the screen }
procedure EraseMessage;
{ Erases a message that was displayed using DisplayMessage }
procedure RegisterGLViews;
{ Register the unit's objects }

const
  RLimScrollBar : TStreamRec = (
     ObjType : stRLimScrollBar;
     VmtLink : Ofs(TypeOf(TLimScrollBar)^);
     Load    : @TLimScrollBar.Load;
     Store   : @TLimScrollBar.Store
  );

  RSheetInputLine : TStreamRec = (
     ObjType : stRSheetInputLine;
     VmtLink : Ofs(TypeOf(TSheetInputLine)^);
     Load    : @TSheetInputLine.Load;
     Store   : @TSheetInputLine.Store
  );

{****************************************************************************}
                               implementation
{****************************************************************************}

uses App;

{** Unit's Register procedures **}

procedure RegisterGlViews;
begin
  RegisterType(RLimScrollBar);
  RegisterType(RSheetInputLine);
end; {...RegisterGLViews }


{** DisplayMessage function **}

function DisplayMessage (AMessage:String): Boolean;
var
  R : TRect;
begin
  DisplayMessage := False;
  Application^.GetExtent(R);
  R.A.Y := R.B.Y - 1;
  if MessageLine <> NIL then
    begin
      MessageLine^.StatusMessage := ' ' + AMessage;
      MessageLine^.Draw;
    end {...if MessageLine <> NIL }
  else
    begin
      MessageLine := New(PMessageLine, Init(R, AMessage));
      if MessageLine^.Valid(cmValid) = True then
        begin
          Application^.Insert(MessageLine);
          DisplayMessage := True;
        end {...if MessageLine^.Valid(cmValid) = True }
      else
        MessageLine := NIL;
    end; {...if/else }
end; {...DisplayMessage }


{** EraseMessage procedure **}

procedure EraseMessage;
begin
  if MessageLine <> NIL then
    Dispose(MessageLine , Done);
  MessageLine := NIL;
end; {...EraseMessage }


{** TLimScrollBar **}

constructor TLimScrollBar.Init(var Bounds: TRect; ADisplayLimit: Integer);
begin
  TScrollBar.Init(Bounds);
  DisplayLimit := ADisplayLimit;
end; {...TLimScrollBar.Init }

function TLimScrollBar.Change: Integer;
{ Returns the amount of change in the scrollbar position }
begin
  Change := Value - OldValue;
end; {...TLimScrollBar.Change }

procedure TLimScrollBar.Draw;
{ Draws the scrollbar using a virtual max value }
var
  RealMax   : Integer;
  RealValue : Word;
begin
  RealMax := Max;
  RealValue := Value;
  Max := DisplayLimit;
  If Value > DisplayLimit then
    Value := DisplayLimit;
  TScrollBar.Draw;
  Max := RealMax;
  Value := RealValue;
end; {...TLimScrollBar.Draw }

procedure TLimScrollBar.HandleEvent(var Event: TEvent);
var
  Mouse       : TPoint;
  MousePos    : Byte;
  BarSize     : Byte;
  RealValue   : Word;
  RealMax     : Integer;
  SendChanged : Boolean;

    function GetMouseRelativePos(MousePos, Size: Byte): Integer;
    var
      MousePoint : Real;
    begin
      MousePoint := (DisplayLimit / (Size - 3)) * MousePos;
      GetMouseRelativePos := Trunc(MousePoint);
    end; {...GetMouseRelativePos }

begin
  OldValue := Value;
  if Event.What = evMouseDown then
  begin
    if MouseInView(Event.Where) then
    begin
      MakeLocal(Event.Where, Mouse);
      if ((Mouse.X <> 0) and (Mouse.X < Pred(Size.X))) or
         ((Mouse.Y <> 0) and (Mouse.Y < Pred(Size.Y))) then
        begin
          if Mouse.Y = 0 then
            begin
              MousePos := Mouse.X;
              BarSize := Size.X;
            end {...if Mouse.Y = 0 }
          else
            begin
              MousePos := Mouse.Y;
              BarSize := Size.Y;
            end; {...if/else }
          RealValue := Value;
          RealMax := Max;
          Max := DisplayLimit;
          if (Value > DisplayLimit) and
             (GetMouseRelativePos(MousePos, BarSize) >= DisplayLimit) then
            begin
              Value := DisplayLimit;
              TScrollBar.HandleEvent(Event);
              if (Value = DisplayLimit) and
                 (RealValue > DisplayLimit) then
              begin
                DrawView;
                Message (Owner, evBroadCast, cmScrollBarChanged, @Self);
              end; {...if (Value = DisplayLimit) and ... }
            end {...if (Value > DisplayLimit) and ... }
          else if (Value > DisplayLimit) then
            begin
              repeat
                if Value <= PgStep then
                  Value := 1
                else
                  Value := Value - PgStep;
                DrawView;
                Message (Owner, evBroadCast, cmScrollBarChanged, @Self);
              until (not MouseEvent(Event, evMouseAuto)) or (Value = 1);
            end {...else if (Value > DisplayLimit) }
          else
            TScrollbar.HandleEvent(Event);
            Max := RealMax;
        end {...if ((Mouse.X <> 0) and (Mouse.X < Pred(Size.X))) or ... }
      else
        TScrollBar.HandleEvent(Event);
    end; {...if MouseInView(Event.Where) }
  end; {...if Event.What = evMouseDown }
end; {...TLimScrollBar.HandleEvent }


constructor TLimScrollBar.Load(var S: TStream);
{ Reads the object from a stream }
begin
   TScrollBar.Load(S);
   S.Read(OldValue, SizeOf(OldValue));
   S.Read(DisplayLimit, SizeOf(DisplayLimit));
end; {...TLimScrollBar.Load }


procedure TLimScrollBar.Store(var S: TStream);
{ Writes the object to a stream }
begin
   TScrollBar.Store(S);
   S.Write(OldValue, SizeOf(OldValue));
   S.Write(DisplayLimit, SizeOf(DisplayLimit));
end; {...TLimScrollBar.Store }


{** TMessageLine **}

constructor TMessageLine.Init(Bounds:TRect; AMessage:String);
begin
  TView.Init(Bounds);
  StatusMessage := ' '+AMessage;
end; {...TMessageLine.Init }

procedure TMessageLine.Draw;
{ Displays the message within the bounds of the view using the color in
  the 2nd entry of the application's palette (Normal Text) }
var
  B : TDrawBuffer;
  C : Byte;
begin
  C := GetColor(2);
  MoveChar(B, ' ', C, Size.X);
  MoveStr(B, StatusMessage, C);
  WriteLine(0, 0, Size.X, 1, B);
end; {...TMessageLine.Draw }


{** TSheetInputLine **}

constructor TSheetInputLine.Init(AMaxLen: Integer);
var
  R : TRect;
begin
  R.Assign(0,0,0,0);
  TInputLine.Init(R, AMaxLen);
end; {...TSheetInputLine.Init }

procedure TSheetInputLine.EndModal(Command: Word);
begin
  EndState := Command;
end; {...TSheetInputLine.EndModal }

function TSheetInputLine.Execute: Word;
{ Allows modal execution of the inputline }
var
  E: TEvent;
begin
  EndState := 0;
  repeat
    GetEvent(E);
    HandleEvent(E);
  until EndState <> 0;
  Execute := EndState;
end; {...TSheetInputLine.Execute }

function TSheetInputLine.GetPalette: PPalette;
const
  NewPalette : string[Length(CSheetInputLine)] = CSheetInputLine;
begin
  GetPalette := @NewPalette;
end; {...TSheetInputLine.GetPalette }

procedure TSheetInputLine.HandleEvent(var Event: TEvent);
var
  EmptyString : String;
begin
  TInputLine.HandleEvent(Event);
  case Event.What of
    evKeyDown :
    begin
      case Event.KeyCode of
        kbEnter, kbUp, kbDown : EndModal(cmOk);
        kbEsc   :
          begin
            EmptyString := '';
            SetData(EmptyString);
            EndModal(cmCancel);
          end; {...case Event.KeyCode of kbEsc }
      end; {...case Event.KeyCode }
      ClearEvent(Event);
    end; {...case Event.What of evKeyDown }
  end; {...case Event.What }
end; {...TSheetInputLine.HandleEvent }

procedure TSheetInputLine.SetState(AState: Word; Enable: Boolean);
begin
  TView.SetState(AState, Enable);
  DrawView;
end; {...TSheetInputLine.SetState }

begin
  MessageLine := NIL;
end. {...TSViews unit }
