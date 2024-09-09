{ Copyright (c) 1990, Borland International }
Uses Crt;

Procedure Route66;
Begin
  Writeln( 'Entering Route 66' );
  Delay(2000);
  Writeln( 'Leaving  Route 66' );
End;

Procedure Highway80;
Begin
  Writeln( 'Entering Highway 80' );
  Delay(2000);
  Writeln( 'Leaving  Highway 80' );
End;

Begin
  Writeln( 'Entering main' );
  route66;
  Writeln( 'back in main' );
  Delay(1000);
  highway80;
  Writeln( 'back in main' );
  delay(100);
  Writeln( 'Leaving main' );
End.
