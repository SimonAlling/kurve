{ Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

  ENVTEST.PAS - Example of calling assembler to look for environment strings.

  From the Turbo Assembler Users Guide - Interfacing Turbo Assembler with
                                            Turbo Pascal
 }

program EnvTest;
{ program looks for environment strings }

var
  EnvVariable : string;
  EnvValue : string;

{$F+}

function EnvString(s:string) : string; external;
{$L ENVSTR.OBJ}
{$F-}
begin
  EnvVariable := 'PROMPT';
  EnvValue := EnvString(EnvVariable);
  if EnvValue='' then EnvValue := '*** not found ***';
  Writeln('Environment Variable: ',EnvVariable,'  Value: ',EnvValue);
end.
