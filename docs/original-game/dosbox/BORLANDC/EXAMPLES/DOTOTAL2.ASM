; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

; DOTOTAL2.ASM - Using old-style segment directives to interface to C++

; From the Turbo Assembler User's Guide - Interfacing Turbo Assembler
;                                          with Borland C++

DGROUP  group    _DATA,_BSS
_DATA   segment  word public 'DATA'
        EXTRN    _Repetitions:WORD        ;externally defined
        PUBLIC   _StartingValue           ;available to other
                                          ;modules
_StartingValue    DW 0
_DATA   ends
_BSS    segment   word public 'BSS'
RunningTotal      DW  ?
_BSS    ends
_TEXT   segment   byte public 'CODE'
        assume    cs:_TEXT,ds:DGROUP,ss:DGROUP
        PUBLIC    _DoTotal
_DoTotal          PROC                    ;function (near-callable
                                          ; in small model)
        mov       cx,[_Repetitions]       ;# of counts to do
        mov       ax,[_StartingValue]
        mov       [RunningTotal],ax       ;set initial value
TotalLoop:
        inc       [RunningTotal]          ;RunningTotal++
        loop      TotalLoop
        mov       ax,[RunningTotal]       ;return final total
        ret
_DoTotal ENDP
_TEXT   ENDS
        END


