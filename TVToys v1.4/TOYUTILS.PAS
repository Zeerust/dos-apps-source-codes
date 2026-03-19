(***************************************************************************
  Utils unit
  Odd stuff
  PJB November 3, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright 1993, All Rights Reserved
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  These are non-TV specific helpers with no error checking

***************************************************************************)
unit toyUtils;

interface

  uses
    Dos;

  function AddBackslash(const s:String):String;
  function DefaultExtension(const FileName, Ext:String; Force:Boolean):String;

  function HexChar(i:Integer):Char;
  function HexStr(w:Word):String;
  function HexStrValue(const s:String):Word;
  function HexValue(c:Char):Byte;

  function Min(a,b:Integer):Integer;
  function Max(a,b:Integer):Integer;
  function MemComp(const m1, m2; Len:Integer):Boolean;
  function ToStr(l:Longint):String;

  const
    HexChars : array [0..15] of char = '0123456789ABCDEF';


(***************************************************************************
***************************************************************************)
implementation


  (*******************************************************************
    Make sure we can append a file name
  *******************************************************************)
  function AddBackslash(const s:String):String;
  begin
    if (s<>'') and not (s[Length(s)] in ['\',':']) then
      AddBackslash:=s+'\'
    else
      AddBackslash:=s;
  end;


  (*******************************************************************
    Add extension if necessary
  *******************************************************************)
  function DefaultExtension;
    var
      P: PathStr;
      D: DirStr;
      N: NameStr;
      E: ExtStr;
  begin
    FSplit(FileName, D, N, E);
    if (E = '') or Force then
      E:=Ext;
    DefaultExtension:=D+N+E;
  end;


  (*******************************************************************
    Convert 0-15 to hex (0-F)
  *******************************************************************)
  function HexChar;
  begin
    HexChar:=HexChars[i and 15];
  end;


  (*******************************************************************
    Convert word to four hex chars, zero extended
  *******************************************************************)
  function HexStr;
  begin
    HexStr[0]:=Chr(4);
    HexStr[1]:=HexChars[Hi(w) shr 4];
    HexStr[2]:=HexChars[Hi(w) and $F];
    HexStr[3]:=HexChars[Lo(w) shr 4];
    HexStr[4]:=HexChars[Lo(w) and $F];
  end;


  (*******************************************************************
    Convert hex string to word
  *******************************************************************)
  function HexStrValue;
    var
      sum, i : Word;
  begin
    sum:=0;
    for i:=1 to Length(s) do
      sum:=16*sum+HexValue(s[i]);
    HexStrValue:=sum;
  end;


  (*******************************************************************
    Convert hex char (0-F) to byte (0-15)
  *******************************************************************)
  function HexValue;
  begin
    c:=Upcase(c);
    if c>'9' then
      Dec(Byte(c), 7);
    HexValue:=Ord(c)-Ord('0');
  end;


  (*******************************************************************
    Min and Max
  *******************************************************************)
  function Min;
  begin
    if a<b then Min:=a else Min:=b;
  end;

  function Max;
  begin
    if a>b then Max:=a else Max:=b;
  end;


  (*******************************************************************
    Compare two blocks of memory, returns True if equal
  *******************************************************************)
  function MemComp; assembler;
  asm
      push ds
      les  di,m1
      lds  si,m2
      mov  cx,Len
      cld
      rep  cmpsb
      mov  al,1
      je   @Fin
      dec  al
    @Fin:
      pop  ds
  end;


  (*******************************************************************
    Function version of Str(), incurs speed overhead
  *******************************************************************)
  function ToStr;
    var
      s : String[15];
  begin
    Str(l,s);
    ToStr:=s;
  end;


end.