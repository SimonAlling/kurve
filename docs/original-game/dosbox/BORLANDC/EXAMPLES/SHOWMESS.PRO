/* Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc. */
/* SHOWMESS.PRO */
/* Interfacing Turbo Assembler and Turbo Prolog. */

global predicates
   popmessage(string) - (i) language c  % predicate called from 
                                        % assembly language 
   from_asm - language asm              % assembly language procedure 

clauses
   popmessage(S) :-  % can be called as a C function named popmessage_0 
      str_len(S,L),
      LL = L + 4,
      makewindow(13,7,7,"",10,10,3,LL),
      write(S),
      readchar(_),
      removewindow.

goal
   from_asm.         /* external call */

 
