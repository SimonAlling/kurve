; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

; MASEXMPL.ASM - MASM Mode example program to uppercase a line

; From the Turbo Assembler Users Guide - Turbo Assembler Ideal Mode

     TITLE  Example MASM Program      ;this comment is in the
                                      ;title!
     .286

bufsize  =   128                      ;size of input and output
                                      ;buffers

dosint MACRO intnum
     mov  ah,intnum                   ;assign FN number to AH
     int  21h                         ;call DOS function &INTNUM
ENDM

stk SEGMENT STACK
     db   100h DUP (?)                ;reserve stack space
stk ENDS

data SEGMENT WORD
inbuf     db   bufsize DUP (?)        ;input buffer
outbuf    db   bufsize DUP (?)        ;output buffer
data ENDS

DGROUP GROUP stk,data                 ;group stack and data segs

code SEGMENT WORD
     ASSUME   cs:code                 ;assume CS is code seg
start:
     mov  ax,DGROUP                   ;assign address of DGROUP
     mov  ds,ax                       ;segment to DS
     ASSUME   ds:DGROUP               ;default data segment is DS
     mov  dx,OFFSET DGROUP:inbuf      ;load into DX inbuf offset
     xor  bx,bx                       ;standard input
     call readline                    ;read one line
     mov  bx,ax                       ;assign length to BX
     mov  inbuf[bx],0                 ;add null terminator
     push ax                          ;save AX on stack
     call mungline                    ;convert line to uppercase
     pop  cx                          ;restore count
     mov  dx,OFFSET DGROUP:outbuf     ;load into DX outbuf offset
     mov  bx,1                        ;standard output
     dosint    40h                    ;write file function
     dosint    4ch                    ;exit to DOS

;Read a line, called with dx => buffer, returns count in AX
readline PROC near
     mov  cx,bufsize                  ;specify buffer size
     dosint    3fh                    ;read file function
     and  ax,ax                       ;set zero flag on count
     ret                              ;return to caller
readline ENDP

;Convert line to uppercase
mungline PROC NEAR
     mov  si,OFFSET DGROUP:inbuf      ;address inbuf with SI
     mov  di,0                        ;initialize DI
@@uloop:
     cmp  BYTE PTR[si],0              ;end of text?
     je   @@done                      ;if yes, jump to @@done
     mov  al,[si]                     ;else get next character
     and  al,not 'a' - 'A'            ;convert to uppercase
     mov  outbuf[di],al               ;store in output buffer
     inc  si                          ;better to use lodsb,stosb
     inc  di                          ;...this is just an example!
     jmp  @@uloop                     ;continue converting text
@@done:   ret
mungline ENDP                         ;end of procedure
code ENDS                             ;end of code segment
     END  start                       ;end of text and DOS entry                                       ;point
