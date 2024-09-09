/* Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc. */
/* FUNC.PRO */
/* Interfacing Turbo Assembler and Turbo Prolog. */

global domains
   ifunc = int(integer)

global predicates
   makeifunc(integer,ifunc) - (i,o) language c

goal
   makeifunc(4,H),
   write(H),
   readchar(_).

 
