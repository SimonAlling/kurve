// Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

// SQRTBLE2.C - Example of inline assembler code

// From the Turbo Assembler Users Guide - Interfacing Turbo Assembler
//                                         with Borland C++

/* Function to look up the square of a value between 0 and 10 */
int LookUpSquare(int Value)
{
   asm  jmp  SkipAroundData /* jump past the data table */

   /* Table of square values */
   asm  SquareLookUpTable  label  word;
   asm  dw  0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100;

SkipAroundData:
   asm  mov  bx,Value;   /* get the value to square */
   asm  shl  bx,1;       /* multiply it by 2 to look up in */
                         /* a table of word-sized elements */
   asm  mov  ax,[SquareLookUpTable+bx]; /* look up the square */
   return(_AX);                         /* return the result */
}
