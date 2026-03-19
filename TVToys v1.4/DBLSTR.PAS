(***************************************************************************
  DoubleStr unit
  Dual string management and string collection
  PJB November 3, 1993, Internet mail to d91-pbr@nada.kth.se
  Copyright 1993, All Rights Reserved
  Free source, use at your own risk.
  If modified, please state so if you pass this around.

  This is the easy way out if you want to connect items in a list box
  to other items. You should really override the ListBox' GetText
  function. Double strings work with any type of list box, though!

  Borland botched by not using (or creating) a virtual method for
  collection data access, probably for speed reasons.

***************************************************************************)
unit DblStr;
{$R-,X+}

interface

  uses
    Objects, Strings;

  type
    PCaseInsensitiveStringCollection = ^TCaseInsensitiveStringCollection;
    TCaseInsensitiveStringCollection =
      object (TStringCollection)
        function Compare(Key1, Key2:Pointer):Integer; virtual;
      end;

    PDblStringCollection = ^TDblStringCollection;
    TDblStringCollection =
      object (TCaseInsensitiveStringCollection)
        function  At2nd(Index:Integer) : Pointer;
        procedure FreeItem(Item:Pointer); virtual;
      end;

  function  NewDoubleStr(const s1,s2:String):PString;
  procedure DisposeDoubleStr(P:PString);


(***************************************************************************
***************************************************************************)
implementation


  (*******************************************************************
    Create a "double" string, two strings in one block
  *******************************************************************)
  function NewDoubleStr;
    var
      p : PChar;
  begin
    GetMem(p, Length(s1)+Length(s2)+2);
    PString(p)^:=s1;
    PString(p+Length(s1)+1)^:=s2;
    NewDoubleStr:=PString(p);
  end;


  (*******************************************************************
    Dispose of a double string allocated by NewDoubleStr
  *******************************************************************)
  procedure DisposeDoubleStr;
  begin
    FreeMem(P, Ord(P^[0]) + Ord(P^[Ord(P^[0])+1]));
  end;


(***************************************************************************
***************************************************************************)

  (*******************************************************************
    FAST Case insensitive comparison
  *******************************************************************)
  function TCaseInsensitiveStringCollection.Compare;
    var
      l, l1, l2 : Byte;
      c : Integer;
  begin
    l1:=Byte(Key1^);
    l2:=Byte(Key2^);

    l:=l2;
    if l1<l2 then
      l:=l1;

    c:=StrLIComp(PChar(Key1)+1, PChar(Key2)+1, l);
    if (c=0) and (l1<>l2) then
      if l1<l2 then
        Compare:=-1
      else
        Compare:=1
    else
      Compare:=c;
  end;


(***************************************************************************
***************************************************************************)

  (*******************************************************************
    Access the "hidden" string
  *******************************************************************)
  function TDblStringCollection.At2nd;
    var
      p : PChar;
  begin
    p:=At(Index);
    inc(p, ord(p^)+1);
    At2nd:=p;
  end;


  (*******************************************************************
    Free double string
  *******************************************************************)
  procedure TDblStringCollection.FreeItem;
  begin
    DisposeDoubleStr(Item);
  end;


    (*******************************************************************
    *******************************************************************)

end.
