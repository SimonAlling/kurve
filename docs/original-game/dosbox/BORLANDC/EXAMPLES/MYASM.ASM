; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.
;
; MYASM.ASM
;
; Interfacing Turbo Assembler and Turbo Prolog.

A_PROG     SEGMENT BYTE
           ASSUME CS:A_PROG
           PUBLIC double_0
double_0   PROC   FAR
           push   bp
           mov    bp,sp

           mov    ax, [bp]+10          ; get the value which MyInVar is bound
           add    ax,ax                ; double that value
           lds    si,DWORD PTR [bp]+6
           mov    [si],ax              ; store the value of MyOutVar 
                                       ; in the appropriate address
	   mov    sp,bp                                       
           pop    bp
           ret    6
double_0  ENDP
A_PROG    ENDS
          END
