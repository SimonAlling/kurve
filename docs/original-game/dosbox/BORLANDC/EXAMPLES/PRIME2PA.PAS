{ Copyright (c) 1990, Borland International }
program Prime2PA;

Var
  I,N: Integer;

Function Root( N : Integer ): Integer;
Begin
  Root := Trunc(Sqrt( N ));
End;

Function Prime( N : Integer ):Boolean;
Var
  I : integer;
Begin
  For I := 2 to Root(N) do
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