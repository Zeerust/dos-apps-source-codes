(***************************************************************************
  ExeStream unit
  Stream that makes adding resources to your .EXE a piece of cake
  PJB November 13, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright PJB 1993, All Rights Reserved. Portions copyright Borland.
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  All seeks are relative to the first header byte.

  Does NOT work with DPMI programs. Seems to need an "patching" program.
  Doubt TVRDEMO would find its resources if compiled to protected mode.
  Don't use this to write to your EXE file, since
  1) You can't insert new data, only overwrite
  2) You'll probably get virus warnings

  To add your own resource types, follow the THeader format.
  This should be the first 8 bytes in your resource:

     Signature : Word;    { Use $4246 }
     InfoType  : Word;    { Any unused, not $4648 or $5250 }
     InfoSize  : Longint  { Length in bytes of resource, not counting this }
                          { header itself }

***************************************************************************)
unit ExeStrm;

{$B-}

interface

  uses
    Objects;

  type
    PExeScanningStream = ^TExeScanningStream;
    TExeScanningStream =
      object (TDosStream)
        BasePos : Longint;
        constructor Init(FileName:FNameStr; Mode:Word; InfoType:Word);
        procedure Seek(Pos:Longint); virtual;
      end;

  const
    magicHelpFile     = $4648;
    magicResourceFile = $5250;


(***************************************************************************
***************************************************************************)
implementation

  {$IFDEF DPMI}
    {$DEFINE NewExeFormat}
  {$ENDIF}
  {$IFDEF WINDOWS}
    {$DEFINE NewExeFormat}
  {$ENDIF}


  (*******************************************************************
    Find the beginning of the EXE appendix
  *******************************************************************)
  constructor TExeScanningStream.Init(FileName:FNameStr; Mode:Word; InfoType:Word);
    type
     {$IFDEF NewExeFormat}
      TExeHeader = record
        eHdrSize:   Word;
        eMinAbove:  Word;
        eMaxAbove:  Word;
        eInitSS:    Word;
        eInitSP:    Word;
        eCheckSum:  Word;
        eInitPC:    Word;
        eInitCS:    Word;
        eRelocOfs:  Word;
        eOvlyNum:   Word;
        eRelocTab:  Word;
        eSpace:     array [1..30] of Byte;
        eNewHeader: Word;
      end;
     {$ENDIF}

      THeader =
        record
          Signature: Word;
          case Integer of
            0: (
              LastCount: Word;
              PageCount: Word;
              ReloCount: Word);
            1: (
              InfoType: Word;
              InfoSize: Longint);
        end;

    var
      Found  : Boolean;
      Header : THeader;
     {$IFDEF NewExeFormat}
      ExeHeader: TExeHeader;
     {$ENDIF}

  begin
    inherited Init(FileName, Mode);

    BasePos:=0;
    Found:=False;

    while (Status=stOK) and (BasePos<=GetSize-SizeOf(THeader)) do
    begin
      Seek(0);                                        (* Seek to BasePos *)
      Read(Header, SizeOf(THeader));
      case Header.Signature of

       {$IFDEF NewExeFormat}
        $5A4D:
          begin
            Read(ExeHeader, SizeOf(TExeHeader));
            BasePos:=ExeHeader.eNewHeader;
          end;
        $454E:  BasePos:=GetSize;
        $4246:                                        (* Borland header *)
          if Header.InfoType=InfoType then
          begin
            Found:=True;
            Break;
          end
          else
            case Header.Infotype of
              $4C42: Dec(BasePos, Header.InfoSize-8); { Found BackLink }
              else                       { Found TV HelpFile, Resource etc }
                Inc(BasePos, Header.InfoSize+8);
                { Dec(BasePos, SizeOf(THeader)*2); (* Windows helpfile? *)}
            end;
        $424E:
          if Header.InfoType=$3230 then               { Found Debug Info }
            Dec(BasePos, Header.InfoSize);
        else
          Break;

       {$ELSE}

        $5A4D: Inc(BasePos, LongMul(Header.PageCount, 512) -
                 (-Header.LastCount and 511));
        $4246:                                         (* Borland header *)
          if Header.InfoType=InfoType then
          begin
            Found:=True;
            Break;
          end
          else
            Inc(BasePos, Header.InfoSize+8);
        else
          Break;
       {$ENDIF}

      end;
    end;

    if not Found then
      Error(stInitError, 0);
  end;


  (*******************************************************************
    Overridden seek does relative seeks
  *******************************************************************)
  procedure TExeScanningStream.Seek(Pos:Longint);
  begin
    inherited Seek(BasePos+Pos);
  end;


    (*******************************************************************
    *******************************************************************)

end.
