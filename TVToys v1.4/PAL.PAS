(***************************************************************************
  Palette unit
  Change the palette on EGA and VGA video cards
  PJB December 13, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright PJB 1993, All Rights Reserved.
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  Originally written February 91, touched up for the TVToys project.
  Tested on a lot of machines back then.

  þ DON'T meddle with the EGA palette settings on a VGA, you'll be
    sorry. Use VGA or RGB commands.

  The rules:           (EVGA means EGA and VGA)
    You can do Palette.Init on any system, it checks for EVGA
    You cannot use any palette routine except Init on anything but EVGA
    Don't use the EGA commands on a VGA, use RGB or VGA commands
    Use EGA or RGB commands on an EGA

    In other words, SetRGB works on both EGA and VGA.


  Technical info:
  An EGA has 64 fixed palette entries to choose from.
  A VGA has 256 palette entries, the fixed EGA palette entries acting
  like indexes in the VGA's palette. A VGA palette entry consists of
  three bytes, one each for the amount of red, green and blue.
  Only the lower six bits in each byte are used.

  So, you can only have 16 different colors on the screen at any one
  time in text mode, and by changing the palette each of those 16 can
  be chosen from one of 64 on an EGA or one of 262144 on a VGA.


  Changing the video mode resets the palette to a system default.

  If EmulateVGA is true, RGB calls on an EGA system will be recalculated
  to the nearest EGA equivalent which in fact works so well that you can
  get a small fading effect even on an EGA.

  You might want to consider what happens if there is a run-time error
  while the palette is in an undesirable state. There is no ExitProc
  here as it depends on how video modes are handled. (Setting a video
  mode resets the palette)

  Interrupts are off while accessing the palette.

  Any fade delays are usually caused by SmartDrive.

***************************************************************************)
unit Pal;
{$O+}

interface

  uses
    Objects,
    Video;

  type
    PEGAPalette = ^EGAPalette;
    EGAPalette  = array [0..15] of Byte;

    RGBRec =
      record
        R, G, B : Byte;
      end;

    PRGBPalette = ^RGBPalette;
    RGBPalette  = array [0..15] of RGBRec;

    PaletteObject =
      object
        EGA         : EGAPalette;
        RGB         : RGBPalette;
        EmulateVGA  : Boolean;

        procedure Init;
        procedure Load(var S:TStream);
        procedure Store(var S:TStream);

        procedure GetEGA(var   Pal:EGAPalette);
        procedure SetEGA(const Pal:EGAPalette);

        procedure GetVGA(var   Pal:RGBPalette);
        procedure SetVGA(const Pal:RGBPalette);

        procedure GetRGB(var   Pal:RGBPalette);
        procedure SetRGB(const Pal:RGBPalette);

        procedure FadeTo(const Pal:RGBPalette; Delta:Integer);
      end;

  var
    VideoPalette : PaletteObject;


  procedure WaitForRetrace;


(***************************************************************************
***************************************************************************)
implementation


  (*******************************************************************
    Wait for a vertical retrace, used to update the palette when it
    won't disturb the display
  *******************************************************************)
  procedure WaitForRetrace; assembler;
  asm
      mov  es,Seg0040
      mov  dx,es:[Addr6845]
      add  dx,6

    @1:
      in   al,dx
      test al,8
      jne  @1

    @2:
      in   al,dx
      test al,8
      je   @2
  end;


    (*******************************************************************
    *******************************************************************)

  (*******************************************************************
    Init, store the original palette
  *******************************************************************)
  procedure PaletteObject.Init;
  begin
    if VideoType<>Other then
    begin
      EmulateVGA:=VideoType=Video.EGA;
      GetEGA(EGA);
      GetRGB(RGB);
    end;
  end;


  (*******************************************************************
    Read palette from a stream
  *******************************************************************)
  procedure PaletteObject.Load;
    var
      Temp : RGBPalette;
  begin
    S.Read(Temp, SizeOf(Temp));
    if S.Status=stOK then
      RGB:=Temp;
  end;


  (*******************************************************************
    Write palette to a stream
  *******************************************************************)
  procedure PaletteObject.Store;
  begin
    S.Write(RGB, SizeOf(RGB));
  end;


  (*******************************************************************
    Read the EGA's palette registers
  *******************************************************************)
  procedure PaletteObject.GetEGA;
  begin
    asm
      mov      cx,16
      mov      es,Seg0040
      mov      dx,es:[Addr6845]
      add      dx,6
      mov      si,03C0h
      les      di,Pal
      mov      bl,0
      cld
      cli
    @1:
      in       al,dx
      xchg     dx,si

      mov      al,bl
      inc      bl
      out      dx,al

      inc      dx
      in       al,dx
      dec      dx
      stosb

      xchg     dx,si
      in       al,dx
      loop     @1
      sti

      mov      al,20h
      xchg     dx,si
      out      dx,al
    end;
    EGA:=Pal;
  end;


  (*******************************************************************
    Set the EGA's palette registers
  *******************************************************************)
  procedure PaletteObject.SetEGA;
  begin
    asm
      call     WaitForRetrace
      push     ds
      mov      cx,16
      mov      es,Seg0040
      mov      dx,es:[Addr6845]
      add      dx,6
      mov      di,03C0h
      lds      si,Pal
      mov      bl,0
      cld
      cli
    @1:
      in       al,dx
      xchg     dx,di

      mov      al,bl
      inc      bl
      out      dx,al
      lodsb
      out      dx,al

      xchg     dx,di
      in       al,dx
      loop     @1
      sti

      mov      al,20h
      xchg     dx,di
      out      dx,al
      pop      ds
    end;
    EGA:=Pal;
  end;


  (*******************************************************************
    Read DAC palette settings on VGA
  *******************************************************************)
  procedure PaletteObject.GetVGA; assembler;
  asm
      push      ds
      mov       cx,16
      mov       dx,03C7h
      lds       si,Self
      les       di,Pal
      add       si,EGA
      cld
      cli
    @1:
      lodsb
      out       dx,al
      add       dx,2
      in        al,dx
      stosb
      in        al,dx
      stosb
      in        al,dx
      stosb
      sub       dx,2
      loop      @1
      sti
      pop       ds
  end;


  (*******************************************************************
    Set 16 DAC palette entries on VGA
  *******************************************************************)
  procedure PaletteObject.SetVGA; assembler;
  asm
      call    WaitForRetrace

      push    ds
      mov     cx,16
      mov     dx,03C8h
      lds     si,Pal
      les     di,Self
      add     di,EGA
      cld
      cli
    @1:
      mov     al,es:[di]
      inc     di
      out     dx,al
      inc     dx
      lodsb
      out     dx,al
      lodsb
      out     dx,al
      lodsb
      out     dx,al
      dec     dx
      loop    @1
      sti
      pop     ds
  end;


  (*******************************************************************
    Get palette on EGA or VGA, convert RGB on EGA
  *******************************************************************)
  procedure PaletteObject.GetRGB;
    function F(B:Byte):Byte;
    begin
      F:=B and 2 + B shr 4 and 1;
    end;

    var
      i : Integer;
  begin
    if not EmulateVGA then
      GetVGA(Pal)
    else
    begin
      for i:=0 to 15 do
        with Pal[i] do
        begin
          R:=21*F(EGA[i] shr 1);
          G:=21*F(EGA[i]);
          B:=21*F(EGA[i] shl 1);
        end;
    end;

    RGB:=Pal;
  end;


  (*******************************************************************
    Set palette on EGA or VGA, convert RGB on EGA
  *******************************************************************)
  procedure PaletteObject.SetRGB;
    var
      i      : Integer;
      EGAPal : EGAPalette;
  begin
    if not EmulateVGA then
      SetVGA(Pal)
    else
    begin
      for i:=0 to 15 do
        with Pal[i] do
          EGAPal[i]:=(
            (R div 16*42 and $24) or
            (G div 16*21 and $12) or
            ((B div 16*21 and $12) shr 1));

      SetEGA(EGAPal);
    end;

    RGB:=Pal;
  end;


  (*******************************************************************
    Fade the current palette into the palette given
    Use negative Deltas to fade to black, positive to fade from black
    to the new palette.
    A Delta of +/-1 fades in 63 steps, larger Deltas fade faster.
    If the refresh rate is 60 Hz, a delta of 1 takes about one second
    to perform
  *******************************************************************)
  procedure PaletteObject.FadeTo;
    var
      i, j      : Integer;
      NewPal    : RGBPalette;
  begin
    i:=Ord(Delta<0)*63;
    repeat
      for j:=0 to 15 do
        with NewPal[j] do
        begin
          R:=Pal[j].R*i div 63;
          G:=Pal[j].G*i div 63;
          B:=Pal[j].B*i div 63;
        end;
      VideoPalette.SetRGB(NewPal);
      Inc(i, Delta);
      if EmulateVGA then
        Inc(i, Delta*5);
    until (i<0) or (i>63);
  end;

end.