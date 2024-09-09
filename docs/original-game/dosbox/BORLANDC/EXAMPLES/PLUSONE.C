// Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

// PLUSONE.C - Example of inline assembler

// From the Turbo Assembler Users Guide - Interfacing Turbo Assembler
//                                         with Borland C++


#include <stdio.h>

int  main(void)

{
   int  TestValue;

   scanf("%d",&TestValue);          /* get the value to increment*/
   asm  inc  WORD PTR TestValue;    /* increment it (inassembler) */
   printf("%d",TestValue);          /* print the incremented value */
}
