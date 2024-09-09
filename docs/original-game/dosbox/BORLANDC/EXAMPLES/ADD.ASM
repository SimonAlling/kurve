; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

; ADD.ASM

; Interfacing Turbo Assembler and Turbo Prolog.

       name     add

ADD_TEXT        SEGMENT   BYTE PUBLIC 'CODE'
       ASSUME   CS:ADD_TEXT
       PUBLIC   ADD_0                ;(i,i,o) flow pattern

ADD_0  PROC     FAR
       arg      Z:dWORD, Y:WORD, X:WORD = ARGLEN1
       push     bp
       mov      bp,sp
       mov      ax,X
       add      ax,Y
       les      bx,Z
       mov      WORD PTR ES:[BX],ax
       pop      bp
       ret      ARGLEN1
ADD_0  ENDP

       PUBLIC   ADD_1                      ;(i,o,i) flow pattern
ADD_1  PROC     FAR
arg    Z:WORD,  Y:dWORD, X:WORD = ARGLEN2
       push     bp
       mov      bp,sp
       mov      ax, Z
       sub      ax, X
       les      bx, Y
       mov      WORD PTR ES:[BX],AX
       pop      bp
       ret      ARGLEN2
ADD_1  ENDP

       PUBLIC   ADD_2                 ;(o,i,i) flow pattern
ADD_2  PROC     FAR
arg    Z:WORD,  Y:WORD, X:dWORD = ARGLEN3
       push     bp
       mov      bp,sp
       mov      ax, Z
       sub      ax, Y
       les      bx, X
       mov      WORD PTR ES:[BX],AX
       pop      bp
       ret      ARGLEN3
ADD_2  ENDP

ADD_TEXT        ENDS
       END

 
