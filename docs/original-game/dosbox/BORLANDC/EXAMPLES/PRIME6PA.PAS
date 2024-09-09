{ Copyright (c) 1990, Borland International }
program Prime6PA;

Var
  I,N: Integer;

Function Prime( N : Integer ):Boolean;
Var
  I : integer;
Begin
  If (N MOD 2 = 0) then
  Begin
    Prime := N = 2;
    Exit;
  End;
  If (N MOD 3 = 0) then
  Begin
    Prime := N = 3;
    Exit;
  End;
  If (N MOD 5 = 0) then
  Begin
    Prime := N = 5;
    Exit;
  End;
  For I := 7 to N-1 do
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
      Write( I,' ' );
End.
