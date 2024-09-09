; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

; STDSEG.ASM - Show "Hello, world" in a program uses standard segments.

StkSeg  SEGMENT PARA STACK 'STACK'
        DB      200h DUP (?)
StkSeg  ENDS

Data    SEGMENT WORD 'DATA'
HelloMessage    DB      'Hello, world',13,10,'$'
Data    ENDS

Code    SEGMENT WORD 'CODE'
        ASSUME  CS:Code, DS:Data
ProgramStart:
        mov   ax,Data
        mov   ds,ax                    ;set DS to the Data segment
        mov   dx,OFFSET HelloMessage   ;DS:DX points to the hello message
        mov   ah,9                     ;DOS print string function #
        int   21h                      ;print the hello string
        mov   ah,4ch                   ;DOS terminate program function #
        int   21h                      ;end the program
Code    ENDS
        END   ProgramStart
