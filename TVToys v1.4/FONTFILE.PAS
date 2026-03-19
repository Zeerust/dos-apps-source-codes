(***************************************************************************
  FontFiles unit
  Font file loading and scanning
  PJB November 3, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright 1993, All Rights Reserved
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  Load and save font files to/from disk. A font can be up to 32 scanlines
  high on a VGA, 14 on an EGA.

  WARNING! A font object is 8 Kb large, if you have two local variable
  fonts, you should get a stack overflow error. Make sure you set stack
  overflow checking to true before you fiddle with font objects, or
  allocate them on the heap instead.

  Bug: You can't use DoWrite in protected mode, but why should you?

***************************************************************************)
unit FontFiles;
{$B-,O+,V-,X+}

interface

  uses
    MsgBox, Objects,
    Dos,
    toyPrefs, toyUtils, TVVideo;

  const
    MaxFontHeight = 32;   (* Height in scanlines. Max 32 (EGA 14) *)

  type
    ScanProcedure = procedure(Height:Integer; const Desc, FileName:String);

    FontDataArray = array [0..256*MaxFontHeight] of Byte;

    PFontFile = ^TFontFile;
    TFontFile =
      object (TObject)
        Name   : PathStr;
        Desc   : String[80];
        Height : Integer;
        Data   : FontDataArray;

        constructor Load(var St:TStream);
        procedure DiskScan(const Path:String; Proc:ScanProcedure);
        procedure Display;
        function  DoRead(const Path:String):Boolean;
        function  DoWrite:Boolean;
        function  Read(const Path:String):Boolean;
        function  Write:Boolean;
        procedure Store(var St:TStream);

      private

        S        : TDosStream;
        FontOfs  : Word;
        FileType : Integer;
        procedure CalcType(var Buf);
        procedure Close;
        procedure GetFont;
        procedure GetInfo;
        procedure MakeDesc(var aDesc:String);
        procedure Open(aName:String);
      end;


(***************************************************************************
***************************************************************************)
implementation

  const
    COMDescOfs  = 2+18;
    DescLen     = 61;
    COMPointOfs = COMDescOfs+DescLen;
    COMFontOfs  = COMPointOfs+1;


  (*******************************************************************
    This is what is written as a font preamble to make it a working
    COM file. This is the first procedure in this segment, so code
    begins at offset 0
  *******************************************************************)
  procedure ComAsm; assembler;
  asm
      jmp  @Init                         {  2 bytes }
      db   13,'StickyFont Font',13,10    { 18 bytes }

    @Desc:
      dd   0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0
      db   26

    @Points:
      db   0
    @Font:
      dw   100h + OFFSET @ComEnd

    @Init:
      mov  bh,[100h + OFFSET @Points]
      mov  ax,1110h
      mov  cx,256
      xor  dx,dx
      mov  bl,dl
      mov  bp,[100h + OFFSET @Font]
      int  10h
      int  20h
    @ComEnd:
  end;

  procedure ComEnd; assembler; asm end;


    (*******************************************************************
    *******************************************************************)

  type
    MagicArray = array [0..3] of LongInt;
    FontFileInfo =
      record
        HeightOfs : word;
        FontOfs   : word;
        Magic     : ^MagicArray;
      end;

  const
    FileTypes = 3;
    FE1 : MagicArray = ($D9033EB, $D202020, $6370200A, $67616D20);
    FE2 : MagicArray = ($D01B7E9, $D202020, $63694D0A, $6C656168);
    FontFileArr : array [1..FileTypes] of FontFileInfo = (
      (HeightOfs:$32; FontOfs:$62; Magic:@FE1),
      (HeightOfs:$23; FontOfs:$62; Magic:@FE2),
      (HeightOfs: COMPointOfs; FontOfs: COMFontOfs; Magic:@ComAsm));


(***************************************************************************
***************************************************************************)

  (*******************************************************************
    Stream constructor
  *******************************************************************)
  constructor TFontFile.Load(var St:TStream);
  begin
    inherited Init;
    St.Read(Name, SizeOf(Name)+SizeOf(Desc)+SizeOf(Height));
    St.Read(Data, Height*256);
  end;


  (*******************************************************************
    Match the font file against known types
  *******************************************************************)
  procedure TFontFile.CalcType;
  begin
    FileType:=1;
    while (FileType<=FileTypes) and not
          MemComp(FontFileArr[FileType].Magic^, Buf, SizeOf(MagicArray)) do
      Inc(FileType);

    if FileType>FileTypes then
      FileType:=0;
  end;


  (*******************************************************************
    Close font stream
  *******************************************************************)
  procedure TFontFile.Close;
  begin
    S.Done;
  end;


  (*******************************************************************
    Scan directory for font files
  *******************************************************************)
  procedure TFontFile.DiskScan;
    var
      SR   : SearchRec;
  begin
    FindFirst(AddBackSlash(Path)+'*.COM', Archive+ReadOnly+Hidden, SR);
    while DosError=0 do
    begin
      Open(Path+SR.name);
      Close;
      if Height>0 then
        Proc(Height, Desc+','+ToStr(Height)+'p', SR.Name);
      FindNext(SR);
    end;
  end;


  (*******************************************************************
    Change the screen font
  *******************************************************************)
  procedure TFontFile.Display;
  begin
    TVVideo.SetUserFont(Height, @Data);
  end;


  (*******************************************************************
    Open and read font from file
  *******************************************************************)
  function TFontFile.DoRead;
  begin
    Open(Path);
    GetFont;
    DoRead:=(S.Status=stOK) and (Height>0);
    Close;
  end;


  (*******************************************************************
    Write a COM file that sets the font when run
  *******************************************************************)
  function TFontFile.DoWrite;
  begin
    Byte(Ptr(CSeg, Ofs(ComAsm)+COMPointOfs)^):=Height;

    if Desc='' then
      MakeDesc(Desc);
    Byte(Desc[0]):=Min(Length(Desc)+1, 61);
    Desc[Length(Desc)]:=#26;
    Move(Desc[1], Ptr(CSeg, Ofs(ComAsm)+COMDescOfs)^, Length(Desc));

    S.Init(Name, stCreate);
    S.Write(@ComAsm^, Ofs(ComEnd)-Ofs(ComAsm)-1);
    S.Write(Data, Height*256);
    S.Done;

    DoWrite:=S.Status=stOK;
  end;


  (*******************************************************************
    Read the font's bitmap from disk
  *******************************************************************)
  procedure TFontFile.GetFont;
  begin
    if Height<=MaxFontHeight then
    begin
      S.Seek(FontOfs);
      S.Read(Data, Height*256);
    end;
  end;


  (*******************************************************************
    Get font info from file
  *******************************************************************)
  procedure TFontFile.GetInfo;
    var
      Buf : array [0..127] of Byte;
  begin
    S.Read(Buf, SizeOf(Buf));
    if S.Status=stOK then
    begin
      CalcType(Buf);

      if FileType<>0 then
      begin
        Height:=Buf[FontFileArr[FileType].HeightOfs];
        if Height>32 then
          Height:=0;
        FontOfs:=FontFileArr[FileType].FontOfs;
      end;

      if FileType=3 then
      begin
        FontOfs:=Buf[FontOfs];
        Move(Buf[COMDescOfs], Desc[1], DescLen+1);
        Desc[0]:=Chr(DescLen);
        Desc[0]:=Chr(Pos(#26, Desc)-1);
      end
      else
        MakeDesc(Desc);
    end
  end;


  (*******************************************************************
    If there is no description, make one out of the base file name
    Only StickyFont (Far Niente) files have descriptions
  *******************************************************************)
  procedure TFontFile.MakeDesc(var aDesc:String);
    var
      Dir : DirStr;
      Ext : ExtStr;
  begin
    FSplit(Name, Dir, aDesc, Ext);
  end;


  (*******************************************************************
    Open font file and read info
  *******************************************************************)
  procedure TFontFile.Open;
  begin
    Name:=aName;
    S.Init(Name, stOpenRead);
    FileType:=0;
    Height:=0;
    GetInfo;
  end;


  (*******************************************************************
    Try to read a font from disk
  *******************************************************************)
  function TFontFile.Read;
  begin
    Read:=False;
    if DoRead(Path) then
      Read:=True
    else
      MessageBox(^C'Error reading font', Nil, mfError+mfOKButton);
  end;


  (*******************************************************************
    Stream storing
  *******************************************************************)
  procedure TFontFile.Store(var St:TStream);
  begin
    St.Write(Name, SizeOf(Name)+SizeOf(Desc)+SizeOf(Height));
    St.Write(Data, Height*256);
  end;


  (*******************************************************************
    Try to write a COM file
  *******************************************************************)
  function TFontFile.Write;
  begin
    if not DoWrite then
      MessageBox(^C'Error writing font', Nil, mfError+mfOKButton);
  end;


    (*******************************************************************
    *******************************************************************)

end.
