; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

;  SCROL.ASM
;
;  Interfacing Turbo Assembler and Turbo Prolog.

     name   scrol
;
;
SCROL_TEXT     SEGMENT  BYTE PUBLIC 'CODE'
     ASSUME    CS:SCROL_TEXT

PUBLIC SCROLL_LEFT_0

SCROLL_LEFT_0  PROC FAR
;
; parameters
arg  NCOLS:WORD, NROWS:WORD, COL:WORD, ROW:WORD = ARGLEN
;
; local variable
local      SSEG :WORD = LSIZE
     push  bp
     mov   bp,sp
     sub   sp,LSIZE              ;room for local variables
     push  si
     push  di

     mov   SSEG, 0B800h

     sub   NCOLS, 3              ;NCOLS = NCOLS - 3

     mov   ax, ROW               ;DEST = ROW*160 + (COL+1)*2
     mov   dx,160
     mul   dx
     mov   dx, COL
     inc   dx                    ;added
     shl   dx,1
     add   dx,ax

     push  ds
     push  es

     mov   bx , NROWS            ;loop NROWS times using BX as counter
     dec   bx                    ;NROWS = NROWS - 2
     dec   bx

Top: cmp   bx ,0
     je    Done

     add   dx, 160               ;dest = dest + 160

     mov   ax,NCOLS              ;lastchar = dest + nc*2
     shl   ax,1
     add   ax,dx
     push  ax                    ;push lastchar offset on stack

     mov   ax,SSEG               ;load screen segment into ES, DS
     mov   es,ax
     mov   ds,ax

     mov   di,dx                 ;set up SI and DI for movs
     mov   si,di                 ;source is 2 bytes above DEST
     add   si,2

     mov   ax,[di]               ;save the char in col 0 in AX

     mov   cx,NCOLS              ;mov NCOLS words
     cld
     rep   movsw

     pop   di                    ;pop lastchar offset to DI
     mov   [di],ax               ;put char in AX to last column

     dec   bx
     jmp   Top
Done:pop   es
     pop   ds
     pop   di
     pop   si
     mov   sp,bp
     pop   bp
     ret   ARGLEN
SCROLL_LEFT_0  ENDP
SCROL_TEXT     ENDS
     END

 
