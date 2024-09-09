/* Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc. */
/* SHOWNEW.PRO */
/* Interfacing Turbo Assembler and Turbo Prolog. */

global predicates
   popmessage(string) - (i) language c  /* predicate called from
                                           assembly language procedure */
                                          
   from_asm - language c as "_from_asm"    /* define public name of 
                                              the assembly language 
                                              procedure */

clauses
   popmessage(S) :-
      str_len(S,L),
      LL=L+4,
      makewindow(13,7,7,"window",10,10,3,LL),
      write(S),
      readchar(_),
      removewindow.

goal
   from_asm.             /* call assembly language procedure */

 
