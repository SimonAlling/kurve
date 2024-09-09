; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

; FROM_ASM.ASM

; Interfacing Turbo Assembler and Turbo Prolog.

        EXTRN   PopMessage_0:FAR
DGROUP  GROUP   _DATA
        ASSUME  CS:SENDMESS_TEXT,DS:DGROUP

_DATA   SEGMENT WORD PUBLIC 'DATA'
mess1   DB      "Report: Condition Red",0
_DATA   ENDS

SENDMESS_TEXT   SEGMENT   BYTE PUBLIC 'CODE'
        PUBLIC  FROM_ASM_0
FROM_ASM_0      PROC    FAR
        push  ds
        mov   ax,OFFSET DGROUP:mess1
        push  ax
        call  FAR PTR PopMessage_0
        pop   cx
        pop   cx
        ret
FROM_ASM_0      ENDP
SENDMESS_TEXT   ENDS
        END

 
