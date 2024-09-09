; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

; SUB1.ASM

; This is part of the example of linking multiple assembly code modules.
; This modules provides the ConcatenateStrings function to be called
; by MAIN.ASM

     DOSSEG
     .MODEL    SMALL
     .DATA
     GLOBAL    FinalString:BYTE
     .CODE
;
; Subroutine copies first one string, and then another
; to FinalString.
;
; Input:
;    DS:AX = pointer to first string to copy
;    DS:BX = pointer to second string to copy
;
; Output: None
;
; Registers destroyed: AL, SI, DI, ES
;
     PUBLIC    ConcatenateStrings
ConcatenateStrings  PROC
     cld                         ;strings count up
     mov  di,SEG FinalString
     mov  es,di
     mov  di,OFFSET FinalString
                                 ;ES:DI points to the destination
     mov  si,ax                  ;first string to copy
String1Loop:
     lodsb                       ;get string 1 character
     and  al,al                  ;is it 0?
     jz   DoString2              ;yes, done with string 1
     stosb                       ;save string 1 character
     jmp  String1Loop
DoString2:
     mov  si,bx                  ;second string to copy
String2Loop:
     lodsb                       ;get string 2 character
     stosb                       ;save string 2 character
                                 ; (including 0 when we find it)
     and  al,al                  ;is it 0?
     jnz  String2Loop            ;no, do next character
     ret                         ;done
ConcatenateStrings   ENDP
     END
