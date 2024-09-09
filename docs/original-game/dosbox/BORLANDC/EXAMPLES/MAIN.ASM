; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

; MAIN.ASM

; Example of linking multiple assembly code modules. This needs SUB1.ASM
; to provide the ConcatenateStrings function.
;

     DOSSEG
     .MODEL    SMALL
     .STACK    200H
     .DATA
String1        DB   'Hello, ',0
String2        DB   'world',0dh,0ah,'$',0
     GLOBAL    FinalString:BYTE:50
FinalString    DB   50 DUP (?)
     .CODE
     EXTRN     ConcatenateStrings:PROC
ProgramStart:
     mov  ax,@data
     mov  ds,ax
     mov  ax,OFFSET String1
     mov  bx,OFFSET String2
     call ConcatenateStrings       ;combine the two strings
                                   ; into a single string
     mov  ah,9
     mov  dx,OFFSET FinalString
     int  21h                      ;print the resulting string
     mov  ah,4ch
     int  21h                      ;and done
     END  ProgramStart



