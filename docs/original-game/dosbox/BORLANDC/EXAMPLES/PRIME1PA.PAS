{ Copyright (c) 1990, Borland International }
program Prime1PA;

Var
  I,N: Integer;

Function Prime( N : Integer ):Boolean;
Var
  I : integer;
Begin
  For I := 2 to N-1 do
    If (N MOD I = 0) then
      Begin
        Prime := False;
        Exit;
      End;
  Prime := True;
End;

Begin
  N := 1000;
  For I := 2 to N do
    If Prime(I) then
      Writeln( I );
End.
