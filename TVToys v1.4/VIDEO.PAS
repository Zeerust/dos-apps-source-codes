(***************************************************************************
  Video unit
  Video mode routines, trial and error legal mode detection
  PJB August 29, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright 1993, All Rights Reserved
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  Intended for Turbo Vision, easily rehacked.

  þ Use CheckVideoType to initialize before you call any
    other procedures or access any variables in this unit.

  þ Use ScanEVGAModes only on EGA and VGA compatible cards, or else
    the results might be misleading. Check this before you use
    ScanEVGAModes.

  If the video card is VERY old, the computer might crash since the
  BIOSes weren't designed to handle "illegal" video modes back then...

  For full VESA, Video7 support, use only SetSpecialVideoMode and
  GetSpecialVideoMode from this unit.

  You can overlay this unit only if AutoCheckVideoType is not defined.
  See CONFIG.PAS for a description of all conditional defines.

***************************************************************************)
unit Video;

{$I toyCfg}

{$B-,Q-,S-,X+}
{$IFDEF DPMI} {$G+} {$ENDIF}

{$IFNDEF AutoCheckVideoType}
  {$O+}
{$ENDIF}


interface

  uses
   {$IFDEF DPMI}
    DPMI,
    WinAPI,
   {$ENDIF}
   {$IFDEF VesaSupport}
    VESA,
   {$ENDIF}
    Drivers;

  type
    AddModeProc = procedure (Mode, Rows, Columns, CharHeight:Word; Color:boolean);


  (*******************************************************************
    Video BIOS stuff
  *******************************************************************)
  const
    CrtWidth   = $4A; (* byte *)
    CrtSize    = $4C; (* word *)
    Addr6845   = $63; (* word *)
    CrtRows    = $84; (* byte EGA/VGA *)
    CrtPoints  = $85; (* byte EGA/VGA *)
    CrtInfo    = $87; (* byte EGA/VGA *)

    (* Use with UseInternalFont *)
    Internal8x8Font  = $12;
    Internal8x14Font = $11;
    Internal8x16Font = $14;


  (*******************************************************************
    Video mode detection stuff
  *******************************************************************)
  type
    VideoTypes = (Other, EGA, VGA);
    SpecialVideoTypes = set of (vtVesa, vtVideo7);

  const
    (* This value can be used to rule out Vesa and V7 tests run-time *)
    VideoTypesToCheck : SpecialVideoTypes = [vtVesa, vtVideo7];

  var
    (* Detected video type *)
    VideoType : VideoTypes;

 {$IFDEF Video7Support}
    Video7 : boolean;

  const
    V7Installed = 1;
    HPInstalled = 2;
 {$ENDIF}

  const
   {$IFDEF VesaSupport}
    DontClearVideoModeFlag : Word = $80;
   {$ELSE}
    DontClearVideoModeFlag = $80;
   {$ENDIF}

  type
    ModeSet = set of 0..127;

  const
    (* 0,1 intentionally left out *)
    StandardTextModes : ModeSet = [2, 3, 7];
    VGAModes          : ModeSet = [2, 3, 7, 8, $14..127];
    VESAModes         : ModeSet = [$8..$C];  (* Corresponds to $108..$10C *)


  (*******************************************************************
    Video state object
  *******************************************************************)
  type
    VideoState =
      object
        Mode       : Word;
        Lines      : Byte;
        CharHeight : Byte;
        procedure Save;
        procedure Restore;
      end;


  procedure SetSpecialVideoMode(Mode:Word);
  function  GetSpecialVideoMode:Word;

 {$IFDEF VesaSupport}
  procedure CheckVesa;
 {$ENDIF}
 {$IFDEF Video7Support}
  procedure CheckVideo7;
 {$ENDIF}
  procedure CheckEVGA;
  procedure CheckVideoType;

  function  GetCurrentScanLines:Integer;
  procedure UseInternalFont(Font:Byte);
  procedure LoadUserFont(Points:Byte; First, Count:Integer; Font:Pointer);   function  IsProbablyTextMode:Boolean;
  function  IsColorMode:Boolean;

  procedure ScanEVGAModes(ModeOffset:Word; const ModesToCheck:ModeSet; AddMode:AddModeProc);

(***************************************************************************
***************************************************************************)
implementation


 {$IFDEF Video7Support}
  (*******************************************************************
    Test for the presence of a Video7 or HP video card
  *******************************************************************)
  function V7orHPInstalled:Byte; assembler;
  asm
      mov  ax,6F00h
      xor  bx,bx
      int  10h

      mov  al,V7Installed
      cmp  bx,'V7'
      je   @Fin

      mov  al,HPInstalled
      cmp  bx,'HP'
      je   @Fin

      mov  al,0
    @Fin:
  end;
 {$ENDIF}


  (*******************************************************************
    Set video mode using VESA, Video7 or BIOS, if supported and present
  *******************************************************************)
  procedure SetSpecialVideoMode(Mode:Word); assembler;
  asm
      mov  ax,Mode

     {$IFDEF VesaSupport}
      cmp  VESA.VesaVersion,0
      je   @NoVesa
      push ax
      call VESA.SetVesaMode
      cmp  al,4Fh                (* Supported? *)
      je   @Fin

      mov  bx,Mode
      test bh,7Fh
      jne  @Fin

      mov  al,bh
      and  al,80h
      or   al,bl
    @NoVesa:
     {$ENDIF}

     {$IFDEF Video7Support}
      cmp  Video7,False
      je   @Go
      mov  bl,al
      mov  ax,6F05h
     {$ENDIF}

    @Go:
      int  10h

    @Fin:
  end;


  (*******************************************************************
    Retrieve current video from VESA, Video7 or plain BIOS
  *******************************************************************)
  function GetSpecialVideoMode:Word; assembler;
  asm
     {$IFDEF VesaSupport}
      cmp  VESA.VesaVersion,0
      je   @NoVesa
      call VESA.GetVesaMode
      and  ah,7Fh

      {$IFDEF V7UniVesaKludge}
       {$IFDEF Video7Support}
        cmp  Video7,False
        je   @NoV7Test
       {$ENDIF}
       cmp  ax,1         (* Boring bad VESA driver returns this on V7 *)
       je   @NoVesa
     @NoV7Test:
      {$ENDIF}

      cmp  bx,4Fh                 (* Success? *)
      je   @Fin
    @NoVesa:
     {$ENDIF}

     {$IFDEF Video7Support}
      cmp  Video7,False
      je   @NoV7

      mov  ax,6F04h
      int  10h

      jmp  @ClearAH
     {$ENDIF}

    @NoV7:
      mov  ah,0Fh
      int  10h

    @ClearAH:
      and  ax,7Fh

    @Fin:
  end;


  (*******************************************************************
    Vesa present?
  *******************************************************************)
 {$IFDEF VesaSupport}
  procedure CheckVesa; assembler;
  asm
      call DetectVesaVersion
      cmp  VesaVersion,0
      je   @NoVesa
      mov  DontClearVideoModeFlag,8000h
    @NoVesa:
  end;
 {$ENDIF}


  (*******************************************************************
    Video 7 card?
  *******************************************************************)
 {$IFDEF Video7Support}
  procedure CheckVideo7; assembler;
  asm
      call V7orHPInstalled
      cmp  al,0
      je   @NoV7
      mov  al,1
    @NoV7:
      mov  Video7,al
  end;
 {$ENDIF}


  (*******************************************************************
    EGA, VGA or Other?
  *******************************************************************)
  procedure CheckEVGA; assembler;
  asm
      push bp

      mov  VideoType,Other
      mov  ax,1200h
      mov  bx,10h
      mov  cx,0FFFFh
      int  10h

      inc  cx
      je   @Fin               (* No EGA support *)

      mov  VideoType,EGA

      mov  ax,1A00h
      int  10h
      cmp  al,1Ah
      jne  @Fin               (* Not a VGA or PS/2 type card *)

      cmp  bl,7
      jae  @VGA               (* VGA, MCGA *)

      cmp  bl,4               (* EGA *)
      jae  @Fin

      mov  VideoType,Other    (* Something else *)
      jmp  @Fin

    @VGA:
      mov  VideoType,VGA

    @Fin:
      pop  bp
  end;


  (*******************************************************************
    Check which of VESA, Video7, VGA and EGA are present
  *******************************************************************)
  procedure CheckVideoType;
  begin
   {$IFDEF VesaSupport}
    if vtVesa in VideoTypesToCheck then
      CheckVesa;
   {$ENDIF}
   {$IFDEF Video7Support}
    if vtVideo7 in VideoTypesToCheck then
      CheckVideo7;
   {$ENDIF}
    CheckEVGA;
  end;


  (*******************************************************************
    Calculate the video mode's number of scan lines
  *******************************************************************)
  function GetCurrentScanLines:Integer; assembler;
  asm
      mov  es,Seg0040

      mov  al,es:[CrtPoints]
      mov  ah,es:[CrtRows]
      inc  ah

      mul  ah
  end;


  (*******************************************************************
     Change to another font on the video card
     Available fonts are:
       8x8:  EGA, VGA         (Internal8x8Font)
       8x14: EGA, VGA         (Internal8x14Font)
       8x16:      VGA         (Internal8x16Font)
  *******************************************************************)
  procedure UseInternalFont(Font:Byte); assembler;
  asm
      push bp
      mov  ah,11h
      mov  al,Font
      mov  bl,0
      int  10h
      pop  bp
  end;


  (*******************************************************************
    Define your own characters
    Points: Character height
    First: First char to define
    Count: Chars to define
    Font points to an array of character bitmaps,
    ASCII <First> first, <Points> bytes per char, top to bottom.
  *******************************************************************)
  procedure LoadUserFont(Points:Byte; First, Count:Integer; Font:Pointer);
 {$IFNDEF DPMI}
   assembler;
 {$ELSE}
    var
      Real, Protected : Pointer;
  begin
    if GetDosMem(Real, Protected, Points*Count) then
    begin
      Move(Font^, Protected^, Points*Count);
 {$ENDIF}
      asm
        push bp
        mov  ax,1110h
        mov  bl,0                 { First definition block }
        mov  bh,Points
        mov  cx,Count
        mov  dx,First
       {$IFDEF DPMI}
        mov  RealRegs.RealEBP.Word,0

        mov  si,Real.Word+2
        mov  RealRegs.RealES.Word,si

        push 10h
        call RealModeInterrupt
       {$ELSE}
        les  bp,Font
        int  10h
       {$ENDIF}
        pop  bp
      end;
 {$IFDEF DPMI}
      GlobalDOSFree(Seg(Protected^));
    end;
  end;
 {$ENDIF}


  (*******************************************************************
    Turn the display OFF
  *******************************************************************)
  procedure NoRefresh; assembler;
  asm
      cli
      mov    es,Seg0040
      mov    dx,es:[Addr6845]
      add    dx,0006h

      in     al,dx
      mov    bx,dx
      mov    dx,03C0h
      mov    al,12h
      out    dx,al
      jmp    @1
    @1:
      xor    al,al
      out    dx,al
      xchg   dx,bx
      in     al,dx
      xchg   dx,bx

      mov    al,20h
      out    dx,al
      sti
  end;

    
  (*******************************************************************
    Test to see if we're in text mode.
    NB: Turbo Vision supports a maximum of 132 columns (see the
    definitions of TDrawBuffer/MaxViewWidth)
  *******************************************************************)
  function IsProbablyTextMode:Boolean;
  begin
    IsProbablyTextMode:=
      (Mem[Seg0040:CrtWidth]>=40) and (Mem[Seg0040:CrtWidth]<=132) and
      (Mem[Seg0040:CrtRows]>20) and (Mem[Seg0040:CrtRows]<100) and
      (MemW[Seg0040:CrtSize]<>0) and
      (Mem[Seg0040:CrtWidth]*Mem[Seg0040:CrtRows]*4>MemW[Seg0040:CrtSize]);
  end;


  (*******************************************************************
    This function is used to determine if the video memory segment
    starts at B000 (mono) or B800 (color).
  *******************************************************************)
  function IsColorMode:Boolean;
  begin
    IsColorMode:=MemW[Seg0040:Addr6845]=$03D4;
  end;


  (*******************************************************************
    procedure ScanEVGAModes(First:byte; AddMode:AddModeProc);
      First:   First video mode to try
      AddMode: Procedure to call for each valid text video mode.

      ScanEVGAModes attempts to find out what video modes are available.
      It tries to set every video mode possible, checking to see if
      the BIOS put valid data for a text mode in the BIOS data segment.
      ScanVideoModes starts at mode First and works its way up to mode
      127. Every time a valid Text video mode is found, AddMode is called.

      þ AddMode must be a FAR procedure of the type AddModeProc.

  *******************************************************************)
  procedure ScanEVGAModes(ModeOffset:Word; const ModesToCheck:ModeSet; AddMode:AddModeProc);
    var
      Mode : Word;
      Rows, Columns : Word;
  begin
    for Mode:=0 to 127 do
      if Mode in ModesToCheck then
      begin
        SetSpecialVideoMode(ModeOffset+Mode or DontClearVideoModeFlag);
        NoRefresh;

        Rows:=Mem[Seg0040:CrtRows]+1;
        Columns:=Mem[Seg0040:CrtWidth];
        if IsProbablyTextMode and (ModeOffset+Mode=GetSpecialVideoMode) then
          AddMode(ModeOffset+Mode, Rows, Columns,
                  Mem[Seg0040:CrtPoints], IsColorMode);
      end;
    end;


(***************************************************************************
  Video state object
***************************************************************************)

  (*******************************************************************
    Attempt to save current video state
  *******************************************************************)
  procedure VideoState.Save;
  begin
    Mode:=GetSpecialVideoMode;
    Lines:=Mem[Seg0040:CrtRows];
    CharHeight:=Mem[Seg0040:CrtPoints];
  end;


  (*******************************************************************
    Attempt to restore previous video state
  *******************************************************************)
  procedure VideoState.Restore;
  begin
    SetSpecialVideoMode(Mode);

    if Lines<>Mem[Seg0040:CrtRows] then
      case CharHeight of
        14: UseInternalFont(Internal8x14Font);
        16: UseInternalFont(Internal8x16Font);
        else
          UseInternalFont(Internal8x8Font);
      end;
  end;


    (*******************************************************************
    *******************************************************************)

{$IFDEF AutoCheckVideoType}
begin
  CheckVideoType;
{$ENDIF}
end.
