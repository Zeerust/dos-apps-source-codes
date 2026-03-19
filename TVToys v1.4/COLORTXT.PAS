(***************************************************************************
  ColorTxt unit
  Static texts of any color
  PJB October 8, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright 1993, All Rights Reserved
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  Originally written by David Baldwin. It worked then.

  Changes:
    Changed style
    Added AddShadowTo, CreateMiniShadow
    Removed Draw method  (don't like TStatictext.Draw copy&paste)
    GetPalette added with a twist: Calls LockPalette to fix color
      Won't work if TView.GetColor has been modified.

  AddShadowTo and AddMiniShadow only work on views inserted in other
  views, ie they must have an owner.

  LockPalette can be used in any view to override default palette
  handling. Just put it in a view's Palette function AFTER any references
  to the view's owner. The colors in the palette will then be considered
  to be attributes, not indexes in the owner's palette.

  A view with a LockPalette in its GetPalette will affect all its
  subviews, since their color indexes will point to the attributes
  in the locked palette.

  The GetPalette function can call Owner^.GetColor to calculate specific
  colors, but only before any call to LockPalette.

  LockPalette temporarily modifies the view's Owner pointer and
  modifies the call stack so that the the Owner pointer will be restored
  on exit from the TView.GetColor function in the Views unit.
  This will not work if the GetColor function has been modified.
  Specifically, GetColor must have a stack frame.

***************************************************************************)
unit ColorTxt;
{$B-,Q-,X+}

interface

  uses
    App, Dialogs, Drivers, Objects, Views,
    toyPrefs;

  type
    PColoredText = ^TColoredText;
    TColoredText =
      object (TStaticText)
        Attr : Byte;
        constructor Init(var Bounds: TRect; AText: String; Attribute: Byte);
        constructor Load(var S: TStream);
        function  GetPalette:PPalette; virtual;
        procedure Store(var S: TStream);
      end;

  procedure LockPalette;

  procedure AddShadowTo(P:PView);
  procedure AddMiniShadow(P:PView; Width, Height:Integer);


(***************************************************************************
***************************************************************************)
implementation


  (*******************************************************************
    Static Text object of any color
  *******************************************************************)
  constructor TColoredText.Init(var Bounds: TRect; AText: String;
                                    Attribute : Byte);
  begin
    TStaticText.Init(Bounds, AText);
    Attr:=Attribute;
  end;

  constructor TColoredText.Load(var S: TStream);
  begin
    TStaticText.Load(S);
    S.Read(Attr, Sizeof(Attr));
  end;

  function TColoredText.GetPalette;
    const
      P : String[1] = ' ';
  begin
    {  Must not use our own GetColor here, since that will call
       GetPalette recursively. Owner^.GetColor is OK, but not inherited }
    if AppPalette=apColor then
    begin
      P[1]:=Chr(Attr);
      GetPalette:=PPalette(@P);
      LockPalette;
    end
    else
      GetPalette:=inherited GetPalette;
  end;

  procedure TColoredText.Store(var S: TStream);
  begin
    TStaticText.Store(S);
    S.Write(Attr, Sizeof(Attr));
  end;


(***************************************************************************
***************************************************************************)

  var
    OldOwner : PView;
    OldRet   : Pointer;

  procedure RestoreOwner; assembler;
  asm
      { Point es:di to Self }
      les  di,ss:[bp+6]

      { Self.Owner:=OldOwner }
      mov  bx,OldOwner.Word
      mov  es:[di].TView.Owner.Word,bx
      mov  bx,OldOwner.Word+2
      mov  es:[di].TView.Owner.Word+2,bx

      jmp  OldRet
  end;


  (*******************************************************************
    Call this in GetPalette to treat the palette colors as absolute
  *******************************************************************)
  procedure LockPalette; assembler;
  asm
      push bp
      mov  dx,bp
      mov  bp,[bp]

      { Save return address }
      mov  ax,[bp+2]
      mov  OldRet.Word,ax
      mov  ax,[bp+4]
      mov  OldRet.Word+2,ax

      { Change return address }
      mov  [bp+2].Word,OFFSET RestoreOwner
      mov  [bp+4].Word,cs

      { Point es:di to Self.Owner }
      mov  bp,dx
      les  di,[bp+6]
      add  di,TView.Owner

      { OldOwner:=Self.Owner }
      mov  ax,es:[di]
      mov  OldOwner.Word,ax
      mov  ax,es:[di+2]
      mov  OldOwner.Word+2,ax

      { Self.Owner:=Nil }
      xor  ax,ax
      cld
      stosw
      stosw

      pop  bp
  end;


(***************************************************************************
***************************************************************************)

  (*******************************************************************
    Add a mini shadow to a view
    This works with any view that has an owner, try it on a list box!
  *******************************************************************)
  procedure AddShadowTo(P:PView);
  begin
    AddMiniShadow(P, P^.Size.X, P^.Size.Y);
  end;

  procedure AddMiniShadow(P:PView; Width, Height:Integer);
    var
      S : String;
      R : TRect;
  begin
    if AppPalette=apColor then
    begin
      (* Horizontal shadow *)
      Byte(S[0]):=Width;
      FillChar(S[1], Length(S), 223);
      P^.GetBounds(R);
      R.A.Y:=R.B.Y-1;
      R.B.X:=R.A.X+Width;
      R.Move(1, 1);
      P^.Owner^.Insert(New(PStaticText, Init(R, S)));

      (* Vertical shadow *)
      Byte(S[0]):=Height;
      S[1]:=Chr(220);
      FillChar(S[2], Length(S)-1, 219);
      R.A.X:=R.B.X-1;
      Dec(R.A.Y, Length(S)-1);
      R.Move(0, -1);
      P^.Owner^.Insert(New(PStaticText, Init(R, S)));
    end;
  end;


    (*******************************************************************
    *******************************************************************)

end.
