; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

; ASMPROC.ASM
; Calls pascal routines in SAMPLE.PAS.

; From the Turbo Assembler User's Guide - Interfacing Turbo Assembler
;                                          with Turbo Pascal

DATA     SEGMENT WORD PUBLIC
         ASSUME DS:DATA
         EXTRN  A:WORD             ;variable from the unit
DATA     ENDS


CODE     SEGMENT BYTE PUBLIC
         ASSUME CS:CODE
         EXTRN  PublicProc : FAR   ;far procedure (exported by the unit)
         EXTRN  NearProc : NEAR    ;near procedure (local to unit)
         EXTRN  FarProc  : FAR     ;far procedure (local but forced far)

AsmProc  PROC NEAR
         PUBLIC AsmProc
         CALL   FAR PTR PublicProc
         CALL   NearProc
         CALL   FAR PTR FarProc
         mov    cx,ds:A            ;pull in variable A from the unit
         sub    cx,2               ;do something to change it
         mov    ds:A,cx            ;store it back
         RET
AsmProc  ENDP
CODE     ENDS
         END
