{$N+,E+}

(* File: TPDEMOB.PAS

   Broken Turbo Pascal Demonstration program to show off Turbo Debugger
   Copyright (c) 1988, 1989 - Borland Intl.

   Reads words from standard input, analyzes letter and word frequency.
   Uses linked list to store commandline parameters on heap.

   Uses the following data types:

     Boolean,
     Char, Byte,
     Integer, Word,
     LongInt,
     Extended (8087 type, links in emulator)
     String,
     Array,
     Record,
     Set,
     Pointer

  Comments that look like this:

    { ** Bug: <description> }

  are inserted above lines that contain bugs.

*)
program TPDemo;

const
  BufSize    = 128;    { length of line buffer }
  MaxWordLen =  10;    { maximum word length allowed }

type
  BufferStr = String[BufSize];

  LInfoRec = record
    Count : Word;               { number of occurrences of this letter }
    FirstLetter : Word;         { number of times as first letter of a }
  end;


var
  NumLines, NumWords : Word;                     { counters }
  NumLetters : LongInt;
  WordLenTable : array [1..MaxWordLen] of Word;  { info for each word }
  LetterTable : array['A'..'Z'] of LInfoRec;     { info for each letter }
  Buffer : BufferStr;

procedure ShowResults;

procedure ShowLetterInfo(FromLet, ToLet : Char);
{ Dump letter information }
var
  ch : Char;
begin
  Writeln;
  Write('Letter:     ');
  { ** Bug: Extra semicolon }
  for ch := FromLet to ToLet do;                { column titles }
    Write(ch:5);
  Writeln;

  Write('Frequency:  ');
  for ch := FromLet to ToLet do                 { letter count }
    Write(LetterTable[ch].Count:5);
  Writeln;
  Write('Word starts:');
  for ch := FromLet to ToLet do                 { first letter count }
    Write(LetterTable[ch].FirstLetter:5);
  Writeln;
end; { ShowLetterInfo }

var
  i : Integer;
  AvgWords : Extended;

begin { ShowResults }
  { ** Bug: should test to avoid divide by zero; should be words per line }
  AvgWords := NumLines / NumWords;
  Writeln;
  Writeln(NumLetters, ' char(s) in ',
          NumWords, ' word(s) in ',
          NumLines, ' line(s)');
  Writeln('Average of ', AvgWords:0:2, ' words per line');
  Writeln;

  { Dump word count }
  Write('Word length:');
  for i := 1 to MaxWordLen do
    Write(i:4);
  Writeln;

  Write('Frequency:  ');
  for i := 1 to MaxWordLen do
    Write(WordLenTable[i]:4);
  Writeln;

  { Dump letter counts }
  ShowLetterInfo('A', 'M');
  ShowLetterInfo('N', 'Z');
end; { ShowResults }

procedure Init;
begin
  NumLines := 0; NumWords := 0; NumLetters := 0;
  FillChar(LetterTable, SizeOf(LetterTable), 0);
  FillChar(WordLenTable, SizeOf(WordLenTable), 0);
  Writeln('Enter a string to process, an empty string quits.');
end; { Init }

procedure ProcessLine(S : BufferStr);

function IsLetter(ch : Char) : Boolean;
begin
  { ** Bug: Should shift character to uppercase before testing }
  IsLetter := ch in ['A'..'Z'];
end; { IsLetter }

var
  i : Integer;
  WordLen : Word;

begin { ProcessLine }
  Inc(NumLines);
  i := 1;
  while i <= Length(S) do
  begin
    { Skip non-letters }
    while (i <= Length(S)) and not IsLetter(S[i]) do
      Inc(i);

    { Find end of word, bump letter & word counters }
    WordLen := 0;
    while (i <= Length(S)) and IsLetter(S[i]) do
    begin
      Inc(NumLetters);
      Inc(LetterTable[UpCase(S[i])].Count);
      if WordLen = 0 then                    { bump counter }
        Inc(LetterTable[UpCase(S[i])].FirstLetter);
      Inc(i);
      Inc(WordLen);
    end;

    { Bump word count info }
    if WordLen > 0 then
    begin
      Inc(NumWords);
      if WordLen <= MaxWordLen then
        Inc(WordLenTable[WordLen]);
    end;
  end; { while }
end; { ProcessLine }

function GetLine : BufferStr;
var
  S : BufferStr;
begin
  Write('String: ');
  Readln(S);
  GetLine := S;
end;

procedure ParmsOnHeap;
{ Builds a linked list of commandline parameters on the heap.
  Note that the zero'th parameter, ParamStr(0), returns the
  Exec name of the program on Dos 3.xx only.
}
type
  ParmRecPtr = ^ParmRec;
  ParmRec = record
    Parm : ^String;
    Next : ParmRecPtr;
  end;
var
  Head, Tail, Temp : ParmRecPtr;
  i : Integer;
  s : String;
begin
  Head := nil;
  for i := 0 to ParamCount do
  begin
    { Get next commandline parameter }
    s := ParamStr(i);
    if MaxAvail < SizeOf(ParmRec) + Length(s) + 1 then  { room on heap? }
    begin
      Writeln('Heap full, procedure aborting...');
      Exit;
    end;

    { Add to linked list }
    New(Temp);                         { another Parm record }
    with Temp^ do
    begin
      { ** Bug: Should allocate enough for length byte }
      GetMem(Parm, Length(s));         { string + length byte }
      Parm^ := s;
      Next := nil;
    end;
    if Head = nil then                 { initialize list pointer }
      Head := Temp
    else
      Tail^.Next := Temp;              { add to end }
    Tail := Temp;                      { update tail pointer }
  end; { for }

  { Dump list }
  Writeln;
  with Head^ do
    if Parm^ <> '' then
      Writeln('Program name: ', Parm^);
  Write('Command line parameters: ');
  Tail := Head^.Next;
  while Tail <> nil do
    with Tail^ do
    begin
      Write(Parm^, ' ');
      Tail := Next;
    end;
  Writeln;
end; { ParmsOnHeap }

begin { program }
  Init;
  Buffer := GetLine;
  while Buffer <> '' do
  begin
    ProcessLine(Buffer);
    Buffer := GetLine;
  end;
  ShowResults;
  ParmsOnHeap;
end.
