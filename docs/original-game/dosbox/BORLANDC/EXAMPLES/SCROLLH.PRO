/* Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc. */
/* SCROLLH.PRO */
/* Interfacing Turbo Assembler and Turbo Prolog. */

global predicates
   scroll_left(integer,integer,integer,integer) - (i,i,i,i)
                                                  language asm

predicates
   scrollh
 
clauses
   scrollh :-
      makewindow(_,_,_,_,Row,Col,Nrows,Ncols),
      scroll_left(Row,Col,Nrows,Ncols),
      readchar(C),
      char_int(C,CI),
      not(CI = 27),
      scrollh.

goal
   makewindow(1,7,7," A SCROLLING MESSAGE ",10,20,4,60),
   write("This message will scroll across the window"),nl,
   write("Look at it go!"),
   readchar(_),
   scrollh,
   readchar(_).

 
