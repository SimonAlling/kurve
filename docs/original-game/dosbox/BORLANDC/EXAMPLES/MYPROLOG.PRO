/* Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc. */
/* MYPROLOG.PRO */
/* Interfacing Turbo Assembler and Turbo Prolog. */

global predicates
   double(integer,integer) - (i,o) language asm

goal
   write("Enter an integer "),
   readint(I),
   double(I,Y),
   write(I," doubled is ",Y) ,
   readchar(_).

 
