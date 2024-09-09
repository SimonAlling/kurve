{
  Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

  HEXTEST.PAS
  Accessing Turbo Assembler functions from Turbo Pascal.

  From the Turbo Assembler Users Guide - Interfacing Turbo Assembler
                                         with Turbo Pascal
}

program HexTest;
var
  num : word;

{$F+}

function HexStr (var num; byteCount : byte) : string; external;

{$L HEXSTR.OBJ}

{$F-}
begin
  num := $face;
  Writeln('The Converted Hex String is "',HexStr(num,sizeof(num)),'"');
end.
