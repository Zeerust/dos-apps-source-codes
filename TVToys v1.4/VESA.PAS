(***************************************************************************
  VESA unit
  VESA video mode routines
  PJB October 6, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright PJB 1993, All Rights Reserved.
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  This unit has been tested in protected mode with a PD VESA TSR.
  UNIVESA.EXE does not implement text mode support, so can't be used
  to test with.

  You can overlay this unit if you want to.

***************************************************************************)
unit VESA;
{$B-,O+,T-,X+}
{$IFDEF DPMI} {$G+} {$ENDIF}

interface

  uses
   {$IFDEF DPMI}
    DPMI, WinAPI,
   {$ENDIF}
    Objects;

  type
    Signature = array [0..3] of Char;
    ModeAttr = (Supported, OptionalInfo, BIOSOutput, Color, Graphics);
    AddModeProc = procedure (Mode, Rows, Columns, CharHeight:Word; Color:boolean);

    PVesaInfoBlock = ^VesaInfoBlock;
    VesaInfoBlock =
      record
        VesaSignature : Signature;
        VesaVersion   : Word;
        OEMStringPtr  : Pointer;
        Capabilities  : array [0..3] of Byte;
        VideoModePtr  : Pointer;
        Fill          : array [18..255+10] of Byte;
      end;

    PVesaModeInfo = ^VesaModeInfo;
    VesaModeInfo =
      record
        Attr       : set of ModeAttr;
        Fill1      : array [1..$11] of Byte;
        Width      : Word;
        Height     : Word;
        CharWidth  : Byte;
        CharHeight : Byte;
        Fill2      : array [$18..$FF+10] of Byte;
      end;

  var
    VesaVersion           : Word;
    VesaScanningSupported : Boolean;
    StandardInfoAvailable : Boolean;


  function  GetVesaInfo(VesaInfo:PVesaInfoBlock):Boolean;
  function  GetVesaModeInfo(Mode:Word; Buffer:PVesaModeInfo):Boolean;
  procedure SetVesaMode(Mode:Word);
  function  GetVesaMode:Word;
  procedure DetectVesaVersion;
  procedure ScanVesaModes(AddMode:AddModeProc);
  function  VesaScanningPossible:Boolean;

(***************************************************************************
***************************************************************************)
implementation

  uses
    Video;

  const
    VesaSig = 'VESA';



  (*******************************************************************
    Get VESA information (signature, version, video modes)
  *******************************************************************)
  function GetVesaInfo(VesaInfo:PVesaInfoBlock):Boolean; assembler;
  asm
      push bp
      mov  ax,4F00H

     {$IFDEF DPMI}
      mov  bx,VesaInfo.Word+2
      mov  RealModeRegs.TRealRegs.RealES,bx
      mov  di,VesaInfo.Word
      push 10h
      call DPMI.RealModeInterrupt
     {$ELSE}
      les  di,VesaInfo
      int  10h
     {$ENDIF}

      cmp  ax,004FH
      mov  al,0
      jnz  @Fin
      inc  al

    @Fin:
      pop  bp
  end;


  (*******************************************************************
    Retrieve VESA video mode information
  *******************************************************************)
  function GetVesaModeInfo(Mode:Word; Buffer:PVesaModeInfo):Boolean; assembler;
  asm
      mov  ax,4F01h
      mov  cx,Mode

     {$IFDEF DPMI}
      mov  bx,Buffer.Word+2
      mov  RealModeRegs.TRealRegs.RealES,bx
      mov  di,Buffer.Word
      push 10h
      call DPMI.RealModeInterrupt
     {$ELSE}
      les  di,Buffer
      int  10h
     {$ENDIF}

      cmp  ax,004FH
      mov  al,0
      jnz  @Fin
      inc  ax

    @Fin:
  end;


  (*******************************************************************
    Set VESA video mode
  *******************************************************************)
  procedure SetVesaMode(Mode:Word); assembler;
  asm
      mov  ax,4F02h
      mov  bx,Mode
      int  10h
  end;


  (*******************************************************************
    Retrieve current VESA video mode
  *******************************************************************)
  function GetVesaMode:Word; assembler;
  asm
      mov  ax,4F03h
      int  10h
      xchg ax,bx
  end;


  (*******************************************************************
    Get VESA version
  *******************************************************************)
  procedure DetectVesaVersion;
    var
     {$IFDEF DPMI}
      VesaInfo      : PVesaInfoBlock;
      RealBufferPtr : PVesaInfoBlock;
     {$ELSE}
      VesaInfo      : VesaInfoBlock;
     {$ENDIF}
  begin
   {$IFDEF DPMI}
    if not GetDosMem(Pointer(RealBufferPtr), Pointer(VesaInfo),
           SizeOf(VesaInfoBlock)) then
      Exit;
    if GetVesaInfo(RealBufferPtr) and (VesaInfo^.VesaSignature=VesaSig) then
      VesaVersion:=VesaInfo^.VesaVersion;
    GlobalDosFree(Seg(VesaInfo^));
   {$ELSE}
    if GetVesaInfo(@VesaInfo) and (VesaInfo.VesaSignature=VesaSig) then
      VesaVersion:=VesaInfo.VesaVersion;
   {$ENDIF}
  end;


  (*******************************************************************
    Determine available VESA text video modes
  *******************************************************************)
  procedure ScanVesaModes;
    var
      Modes         : ^Word;
     {$IFDEF DPMI}
      BufferPtr     : PVesaModeInfo;
      RealBufferPtr : PVesaModeInfo;
      VesaInfo      : PVesaInfoBlock ABSOLUTE BufferPtr;
     {$ELSE}
      Buffer        : VesaModeInfo;
      VesaInfo      : VesaInfoBlock ABSOLUTE Buffer;
     {$ENDIF}
  begin
   {$IFDEF DPMI}
    if not GetDosMem(Pointer(RealBufferPtr), Pointer(BufferPtr),
           SizeOf(VesaInfoBlock)) then
      Exit;
    GetVesaInfo(PVesaInfoBlock(RealBufferPtr));
    Modes:=DPMI.CreateRealModeSelector(VesaInfo^.VideoModePtr, $FFFF);
   {$ELSE}
    GetVesaInfo(@Buffer);
    Modes:=VesaInfo.VideoModePtr;
   {$ENDIF}

    while Modes^<>$FFFF do
    begin
     {$IFDEF DPMI}
      if GetVesaModeInfo(Modes^, RealBufferPtr) then
        with BufferPtr^ do
     {$ELSE}
      if GetVesaModeInfo(Modes^, @Buffer) then
        with Buffer do
     {$ENDIF}
          if (Attr * [Supported, Graphics]) = [Supported] then
            if OptionalInfo in Attr then
              AddMode(Modes^, Height, Width, CharHeight, Color in Attr)
            else
              if Modes^ in [2,3,7] then
                AddMode(Modes^, 25, 80, 16, Modes^=3);

      Inc(Modes);
    end;

   {$IFDEF DPMI}
    FreeSelector(Seg(Modes^));
    GlobalDosFree(Seg(BufferPtr^));
   {$ENDIF}
  end;


  (*******************************************************************
    Used to test if VESA Get Video Mode Info function supported
  *******************************************************************)
  procedure CheckScanSupport(Mode, Rows, Columns, CharHeight:Word; Color:boolean); far;
  begin
    if Mode>7 then
      VesaScanningSupported:=True
    else
      StandardInfoAvailable:=False;
  end;

  (*******************************************************************
    Test the hard way if VESA get video mode info function supported
  *******************************************************************)
  function VesaScanningPossible:Boolean;
  begin
    StandardInfoAvailable:=True;
    if VesaVersion<>0 then
      ScanVesaModes(CheckScanSupport);
    StandardInfoAvailable:=not StandardInfoAvailable;

    VesaScanningPossible:=VesaScanningSupported;
  end;

    (*******************************************************************
    *******************************************************************)

end.
