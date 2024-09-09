; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

; TOGLFLAG.ASM - Example dealing with underscores and linking

; From the Turbo Assembler User's Guide - Interfacing Turbo Assembler
;                                          with Borland C++

        DOSSEG
        .MODEL  SMALL
        .DATA
        EXTRN   _Flag:word
        .CODE
        PUBLIC  _ToggleFlag
_ToggleFlag     PROC
        cmp     [_Flag],0              ;is the flag reset?
        jz      SetFlag                ;yes, set it
        mov     [_Flag],0              ;no, reset it
        jmp     short EndToggleFlag    ;done
SetFlag:
        mov     [_Flag],1              ;set flag
EndToggleFlag:
        ret
_ToggleFlag     ENDP
        END
