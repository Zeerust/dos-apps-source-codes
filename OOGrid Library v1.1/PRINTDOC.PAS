program PrintDoc;

Uses Crt, Printer;

const
   DocFileName = 'MANUAL.TXT';

var
  DocFile : Text;
  Counter : Byte;
  LineRead : String;
  Page : Integer;
  X, Y : Byte;

begin
  writeln;
  write('Printing...');
  X := WhereX;
  Y := WhereY;
  Assign(DocFile, DocFileName);
  {$I-}
  Reset(DocFile);
  {$I+}
  if IOResult <> 0 then
  begin
    writeln('operation aborted');
    writeln ('ERROR: the file ', DocFileName, ' was not found.');
    halt(1);
  end; {...if IOResult <> 0 }
  for Counter := 1 to 4 do
    Readln(DocFile, LineRead);
  Page := 1;
  while not Eof(DocFile) do
  begin
    GoToXY(X, Y);
    Write('page ',Page);
    Counter := 1;
    while not Eof(DocFile) and (Counter <= 60) do
    begin
      Readln(DocFile, LineRead);
      Writeln(Lst, LineRead);
      Inc(Counter);
    end; {...while not Eof(DocFile) and (Counter <= 57) }
    Counter := 1;
    while not Eof(DocFile) and (((Page=1) and (Counter <= 6)) or
       ((Page>1) and (Counter <= 8))) do
    begin
      Readln(DocFile, LineRead);
      Inc(Counter);
    end; {...while not Eof(DocFile) and (Counter <= 9) }
    write(Lst, #12);
    Inc(Page);
  end; {...while not Eof(DocFile) }
  Close(DocFile);
  GoToXY(X, Y);
  writeln('done.     ');
  writeln;
end. {...PrintDoc program }