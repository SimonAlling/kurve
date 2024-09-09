{ Copyright (c) 1990, Borland International }
program Prime0PA;

const
  MaxPrimes = 1000;

type
  PrimeArray = array[1..1000] of Integer;

var
  Primes              : PrimeArray;
  CurPrime, LastPrime : Integer;
  J                   : Integer;
  GetOut              : Boolean;

begin
  Primes[1] := 2;
  Primes[2] := 3;
  LastPrime := 2;
  CurPrime  := 3;

  Writeln('Prime 1 = ', Primes[1]);
  Writeln('Prime 2 = ', Primes[2]);

  while CurPrime < MaxPrimes do
  begin
    GetOut := False;
    J := 1;
    while (J <= LastPrime) and (not GetOut) do
    begin
      if (CurPrime mod Primes[J]) = 0 then
      begin
        CurPrime := CurPrime + 2;
        GetOut := True;
      end
      else
        Inc(J);
    end; { while }
    if J > LastPrime then
    begin
      Inc(LastPrime);
      Writeln('Prime ', LastPrime, ' = ', CurPrime);
      Primes[LastPrime] := CurPrime;
      CurPrime := CurPrime + 2;
    end; { if }
  end; { while }
end. { Prime0 }
