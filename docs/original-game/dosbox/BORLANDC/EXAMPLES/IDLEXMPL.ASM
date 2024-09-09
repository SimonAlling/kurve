; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

; IDLEXMPL.ASM - Ideal mode example program to uppercase a line

; From the Turbo Assembler Users Guide - Turbo Assembler Ideal Mode

; File <idlexmpl.asm>
; Ideal mode example program to uppercase a line
     IDEAL                                                    ;#1
     %TITLE    "Example Ideal-Mode Program"                   ;#2
     P286N                                                    ;#3

BufSize   =    128

MACRO dosint intnum                                           ;#4
     mov  ah,intnum
     int  21h
ENDM

SEGMENT stk STACK                                             ;#5
     db   100h DUP (?)
ENDS                                                          ;#6

SEGMENT DATA WORD                                             ;#7
inbuf     db   BufSize DUP (?)
outbuf    db   BufSize DUP (?)
ENDS DATA                                                     ;#8

GROUP DGROUP stk,DATA                                         ;#9

SEGMENT CODE WORD                                             ;#10
      ASSUME   cs:CODE
start:
     mov  ax,DGROUP
     mov  ds,ax
     ASSUME    ds:DGROUP
     mov  dx,OFFSET inbuf                                    ;#11
     xor  bx,bx
     call readline
     mov  bx,ax
     mov  [inbuf + bx],0                                     ;#12
     push ax
     call mungline
     pop  cx
     mov  dx,OFFSET outbuf                                   ;#13
     mov  bx,1
     dosint    40h
     dosint    4ch

;Read a line, called with dx => buffer, returns count in AX
PROC readline near                                           ;#14
     mov  cx,BufSize
     dosint    3fh
     and  ax,ax
     ret
ENDP                                                         ;#15

;Convert line to uppercase
PROC mungline NEAR                                           ;#16
     mov  si,OFFSET inbuf                                    ;#17
     mov  di,0
@@uloop:
     cmp  [BYTE si],0                                        ;#18
     je   @@done
     mov  al,[si]
     and  al,not 'a' - 'A'
     mov  [outbuf + di],al                                   ;#19
     inc  si
     inc  di
     jmp  @@uloop
@@done:   ret
ENDP mungline                                                ;#20
ENDS                                                         ;#21
     END  start
