; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.
;
; IFUNC.ASM
;
; Interfacing Turbo Assembler and Turbo Prolog.

     EXTRN   alloc_gstack:FAR              ; alloc_gstack returns
                                           ; pointer to memory block

IFUNC STRUC 
   FuncType  DB ?
   Value     DW ?
ENDS

IFUNC_TEXT     SEGMENT  WORD PUBLIC 'CODE'
     ASSUME    CS:IFUNC_TEXT

     PUBLIC    Makeifunc_0
Makeifunc_0    PROC FAR
     arg       __inval:WORD, __outp:dWORD
     push      bp
     mov       bp,sp
     mov       ax,3                             ;allocate 3 bytes
     push      ax
     call      FAR PTR alloc_gstack
     pop       cx
     les       bx,__outp
     mov       [WORD PTR ES:BX+2],DX
     mov       [WORD PTR ES:BX],AX
     mov       ax,__inval
;;   les       bx,__outp
     les       bx,[DWORD PTR ES:BX]
     mov       [(IFUNC PTR ES:BX).Value],AX     ;value = __inval
     mov       [(IFUNC PTR ES:BX).FuncType],1   ;type  = 1
     pop       bp
     ret
Makeifunc_0    ENDP
IFUNC_TEXT     ENDS
     END

 
