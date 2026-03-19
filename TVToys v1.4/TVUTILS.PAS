(***************************************************************************
  TVUtils unit
  Validators, odd utilities, TV stuff
  PJB December 14, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright PJB 1993, All Rights Reserved.
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

***************************************************************************)
unit TVUtils;
{$X+}

interface

  uses
    Dos,
    App, Dialogs, Menus, MsgBox, Objects, Validate, Views,
    toyPrefs, {$I hcFile}
    toyUtils;

  const
    kbCtrlA = $1E01;
    kbCtrlB = $3002;
    kbCtrlC = $2E03;
    kbCtrlD = $2004;
    kbCtrlE = $1205;
    kbCtrlF = $2106;
    kbCtrlG = $2207;
    kbCtrlH = $2308;
    kbCtrlI = $1709;
    kbCtrlJ = $240A;
    kbCtrlK = $250B;
    kbCtrlL = $260C;
    kbCtrlM = $320D;
    kbCtrlN = $310E;
    kbCtrlO = $180F;
    kbCtrlP = $1910;
    kbCtrlQ = $1011;
    kbCtrlR = $1312;
    kbCtrlS = $1F13;
    kbCtrlT = $1414;
    kbCtrlU = $1615;
    kbCtrlV = $2F16;
    kbCtrlW = $1117;
    kbCtrlX = $2D18;
    kbCtrlY = $1519;
    kbCtrlZ = $2C1A;

  type
    PByte      = ^Byte;
    PWord      = ^Word;
    PByteArray = ^TByteArray;
    PWordArray = ^TWordArray;


    (* Validate a path *)
    PPathValidator = ^TPathValidator;
    TPathValidator =
      object (TValidator)
        procedure Error; virtual;
        function  IsValid(const S: String): Boolean; virtual;
      end;

    (* Validate file name *)
    PFileValidator = ^TFileValidator;
    TFileValidator =
      object (TPathValidator)
        BadName : Boolean;
        procedure Error; virtual;
        function  IsValid(const S: String): Boolean; virtual;
      end;

    (* Validate real number *)
    PRealValidator = ^TRealValidator;
    TRealValidator = object(TFilterValidator)
      Min, Max: Real;
      Width, Decimals : Integer;
      constructor Init(AMin, AMax: Real);
      constructor Load(var S: TStream);
      procedure Error; virtual;
      function  IsValid(const S: String): Boolean; virtual;
      procedure Store(var S: TStream);
      function  Transfer(var S:String; Buffer:Pointer; Flag:TVTransfer):Word; virtual;
    end;

    (* Validate hex number, four hex digits *)
    PHexValidator = ^THexValidator;
    THexValidator = object(TFilterValidator)
      Min, Max: Word;
      constructor Init(AMin, AMax:Word);
      constructor Load(var S: TStream);
      procedure Error; virtual;
      function  IsValid(const S: String): Boolean; virtual;
      procedure Store(var S: TStream);
      function  Transfer(var S:String; Buffer:Pointer; Flag:TVTransfer):Word; virtual;
    end;

    (* A Longint validator that updates a scrollbar *)
    PSliderValidator = ^TSliderValidator;
    TSliderValidator =
      object (TRangeValidator)
        Slider : PScrollbar;
        constructor Init(AMin, AMax:Longint; ASlider:PScrollbar);
        function IsValidInput(var S:String; SuppressFill:Boolean):Boolean; virtual;
      end;


  const
    (* Help contexts for Borland's ColorSel dialog *)
    ColorSelHelpCtxList : array [1..7] of Word =
      (hcCancel, hcOK, hctoyCSMonoSelector,
       hctoyCSBackground, hctoyCSForeground,
       hctoyCSItem, hctoyCSGroup);

  var
    (* True if the Validator is updating the slider, rather than vice versa *)
    IgnoreSliderMessage : Boolean;


  (* Display a notice in a box *)
  procedure Notice(const Title, Text:String);
  procedure NoNotice;

  (* Add help contexts to existing dialogs without builtin contexts *)
  procedure AddHelpCtx(P:PGroup; HelpCtxList:PWord);

  procedure DisposeMenuItems(Items:PMenuItem);
  function  StorePointer(var Save; Ref:Pointer):Pointer;


(***************************************************************************
***************************************************************************)
implementation

  procedure TPathValidator.Error;
  begin
    MessageBox(^M^C'Invalid path', Nil, mfError+mfOkButton);
  end;


  (*******************************************************************
    Try to validate a path
  *******************************************************************)
  function TPathValidator.IsValid;
    var
      SR : SearchRec;
  begin
    FindFirst(AddBackslash(S)+'*.*', AnyFile, SR);
    IsValid:=DosError<>3;
  end;


    (*******************************************************************
    *******************************************************************)

  procedure TFileValidator.Error;
  begin
    if BadName then
      MessageBox(^M^C'Invalid file name', Nil, mfError+mfOkButton)
    else
      inherited Error;
  end;


  (*******************************************************************
    Try to see if it is a valid file name, difficult and not
    quite reliable
  *******************************************************************)
  function TFileValidator.IsValid;
    var
      SR : SearchRec;
  begin
    BadName:=False;
    FindFirst(S, AnyFile-Directory, SR);
    if (DosError=18) or (S[Length(S)]='\') then
    begin
      BadName:=True;
      FindFirst(S+'\*.*', AnyFile, SR);
      IsValid:=DosError=3;
    end
    else
      IsValid:=DosError<>3;
  end;


    (*******************************************************************
    *******************************************************************)

  (*******************************************************************
    Simple real validator
  *******************************************************************)
  constructor TRealValidator.Init;
  begin
    inherited Init(['0'..'9','+','-','.']);
    if AMin >= 0 then ValidChars:=ValidChars - ['-'];
    Min:=AMin;
    Max:=AMax;
  end;

  constructor TRealValidator.Load(var S: TStream);
  begin
    inherited Load(S);
    S.Read(Min, SizeOf(Max) + SizeOf(Min));
  end;

  procedure TRealValidator.Error;
  var
    Params: array [0..1] of Longint;
  begin
    Params[0]:=Round(Min);
    Params[1]:=Round(Max);
    MessageBox('Value not in the range %d to %d', @Params,
      mfError + mfOKButton);
  end;

  function TRealValidator.IsValid(const S: String): Boolean;
  var
    Value: Real;
    Code: Integer;
  begin
    IsValid:=False;
    if inherited IsValid(S) then
    begin
      Val(S, Value, Code);
      if (Code = 0) and (Value >= Min) and (Value <= Max) then
        IsValid:=True;
    end;
  end;

  procedure TRealValidator.Store(var S: TStream);
  begin
    inherited Store(S);
    S.Write(Min, SizeOf(Max) + SizeOf(Min));
  end;


  (*******************************************************************
    Transfer a real
  *******************************************************************)
  function TRealValidator.Transfer(var S: String; Buffer: Pointer; Flag: TVTransfer): Word;
  var
    Value: Real;
    Code: Integer;
  begin
    if Options and voTransfer <> 0 then
    begin
      Transfer:=SizeOf(Value);
      case Flag of
       vtGetData:
         begin
           Val(S, Value, Code);
           Real(Buffer^):=Value;
         end;
       vtSetData:
         Str(Real(Buffer^):Width:Decimals, S);
      end;
    end
    else
      Transfer:=0;
  end;


    (*******************************************************************
    *******************************************************************)

  (*******************************************************************
    Simple hex validator, four hex digits
  *******************************************************************)
  constructor THexValidator.Init;
  begin
    inherited Init(['0'..'9','A'..'F','a'..'f']);
    Options:=Options or voTransfer;
    Min:=AMin;
    Max:=AMax;
  end;

  constructor THexValidator.Load(var S: TStream);
  begin
    inherited Load(S);
    S.Read(Min, SizeOf(Max) + SizeOf(Min));
  end;

  procedure THexValidator.Error;
  var
    Params: array [0..1] of Longint;
  begin
    Params[0]:=Min;
    Params[1]:=Max;
    MessageBox('Value not in the range %d to %d', @Params,
      mfError + mfOKButton);
  end;

  function THexValidator.IsValid(const S: String): Boolean;
    var
      Value: Real;
  begin
    IsValid:=False;
    if inherited IsValid(S) and (S<>'') then
    begin
      Value:=HexStrValue(S);
      IsValid:=(Value >= Min) and (Value <= Max);
    end;
  end;

  procedure THexValidator.Store(var S: TStream);
  begin
    inherited Store(S);
    S.Write(Min, SizeOf(Max) + SizeOf(Min));
  end;


  (*******************************************************************
    Transfer a hex Word
  *******************************************************************)
  function THexValidator.Transfer(var S:String; Buffer:Pointer; Flag:TVTransfer):Word;
  begin
    if Options and voTransfer <> 0 then
    begin
      Transfer:=SizeOf(Word);
      case Flag of
       vtGetData:  Word(Buffer^):=HexStrValue(S);
       vtSetData:  S:=HexStr(Word(Buffer^));
      end;
    end
    else
      Transfer:=0;
  end;


    (*******************************************************************
    *******************************************************************)

  (*******************************************************************
    Slider init
  *******************************************************************)
  constructor TSliderValidator.Init;
  begin
    inherited Init(AMin, AMax);
    Slider:=ASlider;
  end;


  (*******************************************************************
    Update the slider when the input line changes
  *******************************************************************)
  function TSliderValidator.IsValidInput;
    var
      n : Longint;
  begin
    IsValidInput:=inherited IsValidInput(S, SuppressFill);

    if Transfer(S, @n, vtGetData)>0 then
    begin
      if n>Max then
        n:=Max
      else
        if n<Min then
          n:=Min;

      IgnoreSliderMessage:=True;
      Slider^.SetValue(n);
      IgnoreSliderMessage:=False;
    end;
  end;


(***************************************************************************
***************************************************************************)

  var
    NoticeBox : PDialog;

  (*******************************************************************
    Post a notice on screen
  *******************************************************************)
  procedure Notice(const Title, Text:String);
    var
      R : TRect;
  begin
    R.Assign(0, 0, 14+Length(Text), 7);
    New(NoticeBox, Init(R, Title));
    R.Grow(-1,-1);
    NoticeBox^.Insert(New(PStaticText, Init(R, Text)));
    NoticeBox^.Options:=NoticeBox^.Options or ofCentered;
    NoticeBox^.Flags:=0;
    Application^.InsertWindow(NoticeBox);
  end;


  (*******************************************************************
    Remove the notice box
  *******************************************************************)
  procedure NoNotice;
  begin
    if NoticeBox<>Nil then
    begin
      Dispose(NoticeBox, Done);
      NoticeBox:=Nil;
    end;
  end;


(***************************************************************************
***************************************************************************)

  (*******************************************************************
    Add help contexts to a dialog
  *******************************************************************)
  procedure AddHelpCtx(P:PGroup; HelpCtxList:PWord);
    procedure Addhc(P:PView); far;
    begin
      if (P^.Options and ofSelectable)<>0 then
      begin
        P^.HelpCtx:=HelpCtxList^;
        Inc(HelpCtxList);
      end;
    end;
  begin
    P^.ForEach(@Addhc);
  end;


  (*******************************************************************
    Disposes of a linked list of Menu items
  *******************************************************************)
  procedure DisposeMenuItems(Items:PMenuItem);
  begin
    DisposeMenu(NewMenu(Items));
  end;


  (*******************************************************************
    Filter that saves a pointer
    Useful for catching a specific menu item during menu construction
  *******************************************************************)
  function StorePointer(var Save; Ref:Pointer):Pointer;
  begin
    Pointer(Save):=Ref;
    StorePointer:=Ref;
  end;


end.