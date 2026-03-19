(***************************************************************************
  Stream registration unit
  PJB December 15, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright PJB 1993, All Rights Reserved.
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  All stream registration in one unit

***************************************************************************)
unit StrmRec;

interface

  uses
    Objects,
    toyPrefs,
    ColorBox, ColorTxt, FontDlg, FontFiles, ModeDlg, TVPal, TVUtils;


  procedure RegisterAllToys;
  procedure RegisterColoredText;
  procedure RegisterFontFile;


(***************************************************************************
***************************************************************************)
implementation


  const
    RColoredText: TStreamRec = (
       ObjType: toyColorTxtRN;
       VmtLink: Ofs(TypeOf(TColoredText)^);
       Load:    @TColoredText.Load;
       Store:   @TColoredText.Store
    );

  const
    RColorDialog: TStreamRec = (
       ObjType: 21;
       VmtLink: Ofs(TypeOf(TColorBox)^);
       Load:    @TColorBox.Load;
       Store:   @TColorBox.Store
    );

  const
    RHexValidator: TStreamRec = (
       ObjType: toyHexValidatorRN;
       VmtLink: Ofs(TypeOf(THexValidator)^);
       Load:    @THexValidator.Load;
       Store:   @THexValidator.Store
    );

  const
    RFileValidator: TStreamRec = (
       ObjType: toyFileValidatorRN;
       VmtLink: Ofs(TypeOf(TFileValidator)^);
       Load:    @TFileValidator.Load;
       Store:   @TFileValidator.Store
    );

  const
    RFontFile: TStreamRec = (
       ObjType: toyFontFileRN;
       VmtLink: Ofs(TypeOf(TFontFile)^);
       Load:    @TFontFile.Load;
       Store:   @TFontFile.Store
    );

  const
    RPathValidator: TStreamRec = (
       ObjType: toyPathValidatorRN;
       VmtLink: Ofs(TypeOf(TPathValidator)^);
       Load:    @TPathValidator.Load;
       Store:   @TPathValidator.Store
    );

  const
    RRealValidator: TStreamRec = (
       ObjType: toyRealValidatorRN;
       VmtLink: Ofs(TypeOf(TRealValidator)^);
       Load:    @TRealValidator.Load;
       Store:   @TRealValidator.Store
    );

  const
    RSelectFontDialog: TStreamRec = (
       ObjType: toySelectFontRN;
       VmtLink: Ofs(TypeOf(TSelFontDialog)^);
       Load:    @TSelFontDialog.Load;
       Store:   @TSelFontDialog.Store
    );

  const
    RSelectVideoModeDialog: TStreamRec = (
       ObjType: toySelectVideoModeRN;
       VmtLink: Ofs(TypeOf(TSelectVideoModeDialog)^);
       Load:    @TSelectVideoModeDialog.Load;
       Store:   @TSelectVideoModeDialog.Store
    );

  const
    RSliderValidator: TStreamRec = (
       ObjType: toySliderValidatorRN;
       VmtLink: Ofs(TypeOf(TSliderValidator)^);
       Load:    @TSliderValidator.Load;
       Store:   @TSliderValidator.Store
    );

  const
    RVideoPaletteDialog : TStreamRec = (
      ObjType : toyVideoPaletteRN;
      VmtLink : Ofs(Typeof(TVideoPaletteDialog)^);
      Load    : @TVideoPaletteDialog.Load;
      Store   : @TVideoPaletteDialog.Store);


    (*******************************************************************
    *******************************************************************)

  procedure RegisterFontFile;
  begin
    RegisterType(RFontFile);
  end;

  procedure RegisterColoredText;
  begin
    RegisterType(RColoredText);
  end;

  procedure RegisterAllToys;
  begin
    RegisterType(RColorDialog);
    RegisterType(RColoredText);
    RegisterType(RFileValidator);
    RegisterType(RFontFile);
    RegisterType(RHexValidator);
    RegisterType(RPathValidator);
    RegisterType(RRealValidator);
    RegisterType(RSelectFontDialog);
    RegisterType(RSelectVideoModeDialog);
    RegisterType(RSliderValidator);
    RegisterType(RVideoPaletteDialog);
  end;


end.