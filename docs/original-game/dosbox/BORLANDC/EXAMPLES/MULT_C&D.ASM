; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.
;
; MULT_C&D.ASM
;
; Program to demonstrate use of multiple code and data segments.
;
; Reads a string from the console, stores it in one data
; segment, copies the string to another data segment, converting
; it to lowercase in the process, then prints the string to the
; console. Uses functions in another code segment to read,
; print, and copy the string.
;
StackSeg     SEGMENT   PARA STACK 'STACK'
     DB   512 DUP (?)
StackSeg     ENDS

MAX_STRING_LENGTH   EQU  1000

SourceDataSeg  SEGMENT   PARA PRIVATE 'DATA'
InputBuffer    DB   MAX_STRING_LENGTH DUP (?)
SourceDataSeg  ENDS

DestDataSeg    SEGMENT   PARA PRIVATE 'DATA'
OutputBuffer   DB   MAX_STRING_LENGTH DUP (?)
DestDataSeg    ENDS

SubCode   SEGMENT   PARA PRIVATE 'CODE'
     ASSUME    CS:SubCode
;
; Subroutine to read a string from the console. String end is
; marked by a carriage-return, which is converted to a
; carriage-return/linefeed pair so it will advance to the next
; line when printed. A 0 is added to terminate the string.
;
; Input:
;    ES:DI - location to store string at
;
; Output: None
;
; Registers destroyed: AX,DI
;
GetString PROC FAR
GetStringLoop:
     mov  ah,1
     int  21h                             ;get the next character
     stosb                                ;save it
     cmp  al,13                           ;is it a carriage-return?
     jnz  GetStringLoop ;no-not done yet
     mov  BYTE PTR es:[di],10
     mov  BYTE PTR es:[di+1],0            ;end the string with a linefeed
                                          ; and a 0
     ret
GetString ENDP
;
; Subroutine to copy a string, converting it to lowercase.
;
; Input:
;    DS:SI - string to copy
;    ES:DI - place to put string
;
; Output: None
;
; Registers destroyed: AL, SI, DI
;
CopyLowercase  PROC FAR
CopyLoop:
     lodsb
     cmp  al,'A'
     jb   NotUpper
     cmp  al,'Z'
     ja   NotUpper
     add  al,20h                        ;convert to lowercase if it's uppercase
NotUpper:
     stosb
     and  al,al                         ;was that the 0 that ends the string?
     jnz  CopyLoop                      ;no, copy another character
     ret
CopyLowercase  ENDP
;
; Subroutine to display a string to the console.
;
; Input:
;    DS:SI - string to display
;
; Output: None
;
; Registers destroyed: AH,DL,SI
;
DisplayString  PROC FAR
DisplayStringLoop:
     mov  dl,[si]                       ;get the next character
     and  dl,dl                         ;is this the 0 that ends the string?
     jz   DisplayStringDone             ;yes, we're done
     inc  si                            ;point to the following character
     mov  ah,2
     int  21h                           ;display the character
     jmp  DisplayStringLoop
DisplayStringDone:
     ret
DisplayString  ENDP
SubCode   ENDS

Code SEGMENT   PARA PRIVATE 'CODE'
     ASSUME    CS:Code,DS:NOTHING,ES:NOTHING,SS:StackSeg
ProgramStart:
     cld                                ;make string instructions increment
                                        ; their pointer registers
;
; Read a string from the console into InputBuffer.
;
     mov  ax,SourceDataSeg
     mov  es,ax
     ASSUME    ES:SourceDataSeg
     mov  di,OFFSET InputBuffer
     call GetString                     ;read string from the console and
                                        ; store it at ES:DI
;
; Print a linefeed to advance to the next line.
;
     mov  ah,2
     mov  dl,10
     int  21h
;
; Copy the string from InputBuffer to OutputBuffer, converting
; it to lowercase in the process.
;
     push es
     pop  ds
     ASSUME    DS:SourceDataSeg
     mov  ax,DestDataSeg
     mov  es,ax
     ASSUME    ES:DestDataSeg
     mov  si,OFFSET InputBuffer         ;copy from DS:SI...
     mov  di,OFFSET OutputBuffer        ;...to ES:DI...
     call CopyLowercase                 ;...making it lowercase
;
; Display the lowercase string.
;
     push es
     pop  ds
     ASSUME    DS:DestDataSeg
     mov  si,OFFSET OutputBuffer
     call DisplayString                 ;display string at DS:SI to the console
;
; Done.
;
     mov  ah,4ch
     int  21h
Code ENDS
     END  ProgramStart
