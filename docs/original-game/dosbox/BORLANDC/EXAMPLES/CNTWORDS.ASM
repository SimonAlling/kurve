; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.
;
; CNTWORDS.ASM
;
; Program to count the number of words in a file.  Words are
; delimited by whitespace, which consists of spaces, tabs,
; carriage returns, and linefeeds.


        DOSSEG                             ;select standard segment-ordering
        .MODEL  SMALL                      ;code and data each fit in 64K
        .STACK  200h                       ;512-byte stack
        .DATA
Count           DW    0                    ;used to count words
InWhitespace    DB    ?                    ;set to 1 when the last
                                           ; character read was whitespace
TempChar        DB    ?                    ;temporary storage used by
                                           ; GetNextCharacter
Result          DB    'Word count: ', 5 DUP (?)
                                           ;string printed to report the count
CountInsertEnd  LABEL BYTE                 ;used to find the end of the area the
                                           ; count value string is stored in
                DB    0dh,0ah,'$'
                                           ;DOS fn #9 expects strings to end with
                                           ; a dollar sign
        .CODE
ProgramStart:
        mov     ax,@data
        mov     ds,ax                      ;point DS to the .DATA segment
        mov     [InWhitespace],1           ;assume we're in whitespace, since
                                           ; the first non-whitespace we'll find
                                           ; will mark the start of a word
CountLoop:
        call    GetNextCharacter           ;get next character to check
        jz      CountDone                  ;...if any
        call    IsCharacterWhitespace      ;is it whitespace?
        jz      IsWhitespace               ;yes
        cmp     [InWhitespace],0           ;character is not
                                           ; whitespace-are we currently in
                                           ; whitespace?
        jz      CountLoop                  ;we're not in whitespace, and the
                                           ; character isn't whitespace, so
                                           ; we're done with this character
        inc     [Count]                    ;we are in whitespace, and the
                                           ; character is not whitespace, so
                                           ; we just found the start of a new word
        mov     [InWhitespace],0           ;mark that we're no longer in whitespace
        jmp     CountLoop                  ;do the next character
IsWhitespace:
        mov     [InWhitespace],1           ;mark that we're in whitespace
        jmp     CountLoop                  ;do the next character
;
; We're done counting--report the results.
;
CountDone:
        mov     ax,[Count]                 ;number to convert to a string
        mov     bx,OFFSET CountInsertEnd-1 ;point to the end of the string to
                                           ; put the number in
        mov     cx,5                       ;number of digits to convert
        call    ConvertNumberToString      ;make the number a string
        mov     bx,OFFSET Result           ;point to result string
        call    PrintString                ;print the count
        mov     ah,4ch                     ;DOS terminate program fn #
        int     21h                        ;end the program
;
; Subroutine to get the next character from the standard input.
;
; Input: None
;
; Output:
;       AL = character, if one was available
;       Z flag = 0 (NZ) if character available,
;              = 1 (Z) if end of file reached
;
; Registers destroyed: AH, BX, CX, DX
;
GetNextCharacter        PROC
        mov     ah,3fh                     ;DOS read from file fn #
        mov     bx,0                       ;standard input handle
        mov     cx,1                       ;read one character
        mov     dx,OFFSET TempChar         ;put the character in TempChar
        int     21h                        ;get the next character
        jc      NoCharacterRead            ;if DOS reports an error, then treat
                                           ; it as the end of the file
        cmp     [TempChar],1ah             ;was it Control-Z?
                                           ; (marks end of some files)
        jne     NotControlZ                ;no
NoCharacterRead:
        sub     ax,ax                      ;mark no character read
NotControlZ:
        and     ax,ax                      ;set Z flag to reflect whether a
                                           ; character was read (NZ), or the
                                           ; end of the file was reached (Z).
                                           ; Note that DOS fn #3fh sets AX to
                                           ; the number of characters read
        mov     al,[TempChar]              ;return the character read
        ret                                ;done
GetNextCharacter        ENDP
;
; Subroutine to report whether a given character is whitespace.
;
; Input:
;       AL = character to check
;
; Output:
;       Z flag = 0 (NZ) if character is not whitespace
;              = 1 (Z) if character is whitespace
;
; Registers destroyed: none
;
IsCharacterWhitespace   PROC
        cmp     al,' '                     ;is it a space?
        jz      EndIsCharacterWhitespace   ;if so, it's whitespace
        cmp     al,09h                     ;is it a tab?
        jz      EndIsCharacterWhitespace   ;if so, it's whitespace
        cmp     al,0dh                     ;is it a carriage return?
        jz      EndIsCharacterWhitespace   ;if so, it's whitespace
        cmp     al,0ah                     ;is it a linefeed? If so,
                                           ; it's whitespace, so return Z;
                                           ; if not, it's not whitespace,
                                           ; so return NZ as set by cmp
EndIsCharacterWhitespace:
        ret
IsCharacterWhitespace   ENDP
;
; Subroutine to convert a binary number to a text string.
;
; Input:
;       AX = number to convert
;       DS:BX = pointer to end of string to store text in
;       CX = number of digits to convert
;
; Output: None
;
; Registers destroyed: AX, BX, CX, DX, SI
;
ConvertNumberToString   PROC
        mov     si,10                      ;used to divide by 10
ConvertLoop:
        sub     dx,dx                      ;convert AX to doubleword in DX:AX
        div     si                         ;divide number by 10. Remainder is in
                                           ; DX--this is a one-digit decimal
                                           ; number. Number/10 is in AX
        add     dl,'0'                     ;convert remainder to a text character
        mov     [bx],dl                    ;put this digit in the string
        dec     bx                         ;point to the location for the
                                           ; next most-significant digit
        loop    ConvertLoop                ;do the next digit, if any
        ret
ConvertNumberToString   ENDP
;
; Subroutine to print a string on the display.
;
; Input:
;       DS:BX = pointer to string to print
;
; Output: None
;
; Registers destroyed: None
;
PrintString     PROC
        push    ax
        push    dx                         ;preserve registers in this subroutine
        mov     ah,9                       ;DOS print string function #
        mov     dx,bx                      ;point DS:DX to the string to print
        int     21h                        ;invoke DOS to print the string
        pop     dx                         ;restore registers we changed
        pop     ax
        ret
PrintString     ENDP
        END     ProgramStart
