(***************************************************************************
  DPMI unit
  DPMI simplification routines
  PJB October 6, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright PJB 1993, All Rights Reserved.
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  This unit will not compile if DPMI is not defined, must set
  Compile³Target to Protected.

***************************************************************************)
unit DPMI;
{$R-,S-,X+}

interface

  type
    TRealRegs =
      record
        RealEDI:   Longint;
        RealESI:   Longint;
        RealEBP:   Longint;
        Reserved:  Longint;
        RealEBX:   Longint;
        RealEDX:   Longint;
        RealECX:   Longint;
        RealEAX:   Longint;
        RealFlags: Word;
        RealES:    Word;
        RealDS:    Word;
        RealFS:    Word;
        RealGS:    Word;
        RealIP:    Word;
        RealCS:    Word;
        RealSP:    Word;
        RealSS:    Word;
      end;

    SelectorRec =
      record
        Selector : Word;
        Segment  : Word;
      end;

  var
    RealRegs : TRealRegs ABSOLUTE System.RealModeRegs;

  function  RealToLinear(RealAdr:Pointer):Longint;
  function  CreateRealModeSelector(RealAdr:Pointer; Size:Word):Pointer;
  function  GetDosMem(var RealModePtr, ProtectedModePtr:Pointer; Size:Word):boolean;
  procedure RealModeInterrupt(Int:Word);

(***************************************************************************
***************************************************************************)
implementation

    uses
      WinAPI;


  (*******************************************************************
    Calculate real address' linear address
  *******************************************************************)
  function RealToLinear; assembler;
  asm
    mov  ax,RealAdr.Word+2

    mov  cl,4
    rol  ax,cl

    mov  dx,ax
    and  dx,0000Fh
    and  ax,0FFF0h

    add  ax,RealAdr.Word
    adc  dx,0
  end;


  (*******************************************************************
    Create a real mode memory area selector
  *******************************************************************)
  function CreateRealModeSelector;
    var
      NewSel : word;
  begin
    NewSel:=AllocSelector(0);
    SetSelectorBase(NewSel, RealToLinear(RealAdr));
    SetSelectorLimit(NewSel, Size);
    CreateRealModeSelector:=Ptr(NewSel, 0);
  end;


  (*******************************************************************
    Allocate real mode memory
  *******************************************************************)
  function GetDosMem;
    var
      DosBlock      : SelectorRec;
  begin
    LongInt(DosBlock):=GlobalDosAlloc(Size);
    ProtectedModePtr:=Ptr(DosBlock.Selector, 0);
    RealModePtr:=Ptr(DosBlock.Segment, 0);
    GetDosMem:=LongInt(DosBlock)<>0;
  end;


  (*******************************************************************
    Call a real mode interrupt
  *******************************************************************)
  procedure RealModeInterrupt; assembler;
  asm
      mov  RealRegs.RealEDI.Word,di
      mov  di,OFFSET RealModeRegs

      mov  word ptr [di].TRealRegs.RealSP,0
      mov  word ptr [di].TRealRegs.RealSS,0

      mov  word ptr [di].TRealRegs.RealEAX.Word,ax
      mov  word ptr [di].TRealRegs.RealEBX.Word,bx
      mov  word ptr [di].TRealRegs.RealECX.Word,cx
      mov  word ptr [di].TRealRegs.RealEDX.Word,dx

      push ds
      pop  es
      mov  ax,0300h
      mov  bx,Int
      xor  cx,cx
      int  31h

      mov  di,OFFSET RealModeRegs

      mov  ax,word ptr [di].TRealRegs.RealEAX.Word
      mov  bx,word ptr [di].TRealRegs.RealEBX.Word
      mov  cx,word ptr [di].TRealRegs.RealECX.Word
      mov  dx,word ptr [di].TRealRegs.RealEDX.Word

      mov  di,word ptr [di].TRealRegs.RealEDI.Word
  end;


    (*******************************************************************
    *******************************************************************)

end.
