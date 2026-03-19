(***************************************************************************
  NewMouse unit
  Snap-in replacement mouse cursor intended for Turbo Vision.
  PJB September 1, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright 1993, All Rights Reserved
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  Use this unit and strange TEXT video modes will work with the mouse.
  This unit does NOT replace a resident mouse driver.

  þ Preferred usage:
    Define UseNewMouse in TOYCFG if you use TToyApp.

  (only if you don't use TToyApp should you put NewMouse in your uses
  list). For non TV operation, make sure you use this unit before any
  mouse event handling code executes, i.e. you might have to put this
  unit first in the first uses list.

  Use UseNewMouse to toggle operation on/off, default is on.
  Don't switch video mode without hiding the mouse. Preferrably use
  Turbo Vision code to switch modes.
  To use graphics modes, first hide the mouse and then toggle NewMouse
  off with UseNewMouse(False). Don't forget to turn it back on.
  Don't shell to DOS without turning NewMouse off. TToyApp does this
  for you if you define UseNewMouse.

  No hardware cursor support. You cannot change the appearance
  of the mouse cursor without turning NewMouse off.

  You cannot overlay this unit.

  My Microsoft mouse driver v8.20 only works properly in 80x25, it
  skips odd columns in ALL other text modes. This has been worked around
  by using the virtual X coordinates passed to the event handler.

***************************************************************************)
unit NewMouse;

{$O-,R-,S-,X+}
{$C FIXED PRELOAD PERMANENT}

interface

  uses
    Dos,
   {$IFDEF DPMI}
    WinAPI,
   {$ENDIF}
    Drivers;

  procedure UseNewMouse(Yes:Boolean);


(***************************************************************************
***************************************************************************)
implementation


  (*******************************************************************
    Data segment variables
  *******************************************************************)
  const
    CrtWidth      = $4A;

    OldPos        : Word = 1;
    Visible       : Byte = $FF;
    NewMouseInUse : Boolean = True;

  var
    Attr   : Byte;
    LastX  : Byte;
    LastY  : Byte;

    VirtualLeft        : Word;
    RecalcVirtualLeft  : Boolean;

    OldInt33           : Pointer;
    InstalledMouseProc : Pointer;


  (*******************************************************************
    Called by original mouse driver with new mouse events
    This code trashes DI, but TV doesn't mind
  *******************************************************************)
  procedure MouseProc; far; assembler;
  asm
      mov  di,SEG @Data
      mov  ds,di

      cmp  NewMouseInUse,0              { Not in use, skip code }
      je   @PosOK

      cmp  RecalcVirtualLeft,False      { DOS shell moved mouse? }
      je   @NoRecalc
      mov  RecalcVirtualLeft,False

      { Recalculate virtual left margin }
      push si
      sub  si,cx
      mov  VirtualLeft,si
      pop  si

      { Calculate an X coordinate from virtual X position data }
    @NoRecalc:
      xor  cx,cx
      sub  si,VirtualLeft
      js   @NewVirtualLeft               { Off left }

      mov  es,Seg0040
      mov  di,es:[CrtWidth].Word
      mov  cl,3
      shl  di,cl
      dec  di                            { Max X }

      mov  cx,si
      sub  si,di
      jbe  @PosOK
      mov  cx,di                         { Off right }

    @NewVirtualLeft:
      add  VirtualLeft,si                { Change left margin }

      { Call old mouse handler }
    @PosOK:
      push cx
      push dx
      call DWORD PTR InstalledMouseProc
      pop  dx
      pop  cx

      mov  ax,SEG @Data
      mov  ds,ax

      cmp  NewMouseInUse,0           { Not in use, don't draw }
      je   @Fin2

      { Calculate position }
      mov  bx,cx
      mov  cl,3
      shr  bx,cl
      shr  dx,cl

      mov  LastX,bl
      mov  LastY,dl

      mov  es,Seg0040

      mov  al,es:[CrtWidth].Byte
      mul  dl
      add  bx,ax
      shl  bx,1
      inc  bx

      cli                       { Reentrancy problems on slow machines }

      test Visible,80h
      je   @Show
      mov  OldPos,bx
      jmp  @Fin

      { Draw mouse cursor }
    @Show:
      mov  es,Drivers.ScreenBuffer+2.Word

      mov  di,OldPos
      mov  al,Attr
      mov  es:[di],al

      mov  OldPos,bx

      mov  al,es:[bx]
      mov  Attr,al

      not  al
      and  al,77h
      mov  es:[bx],al

    @Fin:
      sti

    @Fin2:
  end;


  (*******************************************************************
    Snooping mouse INT 33 replacement routines
  *******************************************************************)
  procedure HideMouse; assembler;
  asm
      sub  Visible,1
      jnc  @Fin

      mov  es,Drivers.ScreenBuffer+2.Word

      cli
      mov  bx,OldPos
      mov  al,Attr
      mov  es:[bx],al
      sti

    @Fin:
  end;

  procedure ShowMouse; assembler;
  asm
      cli
      inc  Visible
      jne  @Fin

      mov  es,Seg0040
      mov  al,es:[CrtWidth].Byte
      mul  LastY

      mov  bl,LastX
      mov  bh,0

      add  bx,ax
      shl  bx,1
      inc  bx
      mov  OldPos,bx

      mov  es,Drivers.ScreenBuffer+2.Word

      mov  al,es:[bx]
      mov  Attr,al
      not  al
      and  al,77h
      mov  es:[bx],al

    @Fin:
      sti
  end;

  procedure InstallProc; assembler;
  asm
      mov  ax,es
      or   ax,dx
      je   @Nil

      mov  InstalledMouseProc.Word, dx
      mov  InstalledMouseProc+2.Word, es

      push cs
      pop  es
      mov  dx,OFFSET MouseProc

    @Nil:
      mov  ax,12
      pushf
      call DWORD PTR [OldInt33]
  end;


  (*******************************************************************
    Mouse INT 33 snooping procedure
    Looks for HideMouse, ShowMouse and InstallEventHandler
  *******************************************************************)
  procedure NewInt33; far; assembler;
  asm
      push ds
      mov  ds,@DataSeg.Word

      cmp  NewMouseInUse,0
      je   @Chain

      cmp  ax,1
      je   @Local
      cmp  ax,2
      je   @Local
      cmp  ax,12
      je   @Local

    @Chain:
      push ax                  { Dummy }

      push bp
      mov  bp,sp
      push [bp+4].Word         { Old DS }
      push ax

      mov  ax,OldInt33.Word
      mov  [bp+2],ax
      mov  ax,OldInt33.Word+2
      mov  [bp+4],ax

      pop  ax
      pop  ds
      pop  bp
      retf                      { Chain to old int handler }

    @Local:
      push ax
      push bx
      push dx
      push es

      cmp  ax,2
      je   @Hide
      ja   @Inst
      call ShowMouse
      jmp  @Fin

    @Hide:
      call HideMouse
      jmp  @Fin

    @Inst:
      call InstallProc

    @Fin:
      pop  es
      pop  dx
      pop  bx
      pop  ax
      pop  ds
      iret

    @DataSeg:
      dw   SEG @Data
  end;


  (*******************************************************************
    Toggle NewMouse operation on/off
    Toggle off before you switch to graphics mode
  *******************************************************************)
  procedure UseNewMouse(Yes:Boolean);
  begin
    if ButtonCount<>0 then
    begin
      NewMouseInUse:=Yes;
      RecalcVirtualLeft:=True;

    (*******************************************************************
      Get last mouse position
    *******************************************************************)
      asm
        mov  ax,3
        int  33h                 { Mouse pos in CX/DX }

        mov  bx,cx
        mov  cl,al
        shr  bx,cl
        shr  dx,cl
        mov  LastX,bl
        mov  LastY,dl
      end;
    end;
  end;


    (*******************************************************************
      Make sure we remove our snooping hook
    *******************************************************************)
  var
    SaveExit : Pointer;

  procedure ExitMouse; far;
  begin
    ExitProc:=SaveExit;
    SetIntVec($33, OldInt33);
  end;


(***************************************************************************
  Installation code
***************************************************************************)

begin
  GetIntVec($33, OldInt33);
  if OldInt33<>Nil then
    SetIntVec($33, @NewInt33);

  SaveExit:=ExitProc;
  ExitProc:=@ExitMouse;
end.
