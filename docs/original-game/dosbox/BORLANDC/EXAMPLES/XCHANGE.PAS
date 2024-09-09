{ Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

  XCHANGE.PAS - Example of exchanging two variables

  From the Turbo Assembler Users Guide - Interfacing Turbo Assembler with
                                            Turbo Pascal
 }

program TextExchange;

type
  EmployeeRecord = record
                     Name    :  string [30];
                     Address :  string [30];
                     City    :  string [15];
                     State   :  string [2];
                     Zip     :  string [10];
                    end ;
var
  OldEmployee, NewEmployee : EmployeeRecord;

{$F+}

procedure Exchange(var var1,var2; count : word); external;
{$L XCHANGE.OBJ}
{$F-}
begin
  with OldEmployee do
  begin
    Name := 'John Smith';
    Address := '123 F Street';
    City := 'Scotts Valley';
    State := 'CA';
    Zip := '90000-0000';
  end;
  with NewEmployee do
  begin
    Name := 'Mary Jones';
    Address := '9471 41st Avenue';
    City := 'New York';
    State := 'NY';
    Zip := '10000-1111';
  end;
  Writeln('Before: ',OldEmployee.Name,'  ',NewEmployee.Name);
  Exchange(OldEmployee,NewEmployee,sizeof(OldEmployee));
  Writeln('After:  ',OldEmployee.Name,'  ',NewEmployee.Name);
  Exchange(OldEmployee,NewEmployee,sizeof(OldEmployee));
  Writeln('After:  ',OldEmployee.Name,'  ',NewEmployee.Name);
end.
