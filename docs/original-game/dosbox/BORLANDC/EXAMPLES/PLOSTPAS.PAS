{ Copyright (c) 1990, Borland International }
Uses Crt;

Procedure Lost_in_town;
Var
  I : integer;
Begin
  writeln( 'Looking for highway...' );
  delay(100);
  for I := 0 to 9 do
  Begin
    Writeln( 'Ask for directions' );
    Writeln( 'Wrong turn' );
    Writeln;
    delay(1000);
  End;
  Writeln( 'on the road again' );
End;

Begin
  Writeln( 'Entering Main' );
  Lost_in_town;
  Delay(1000);
  writeln( 'Leaving main' );
  writeln;
  delay(1000);
End.
