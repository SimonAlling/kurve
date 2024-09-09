;[]------------------------------------------------------------[]
;|      C0W.ASM -- Start Up Code For Windows                    |
;|                                                              |
;|      Turbo C++ Run Time Library                              |
;|                                                              |
;|      Copyright (c) 1987, 1991 by Borland International Inc.  |
;|      All Rights Reserved.                                    |
;[]------------------------------------------------------------[]

                locals

                __C0__ = 1
include         RULES.ASI

                ASSUME CS:_TEXT, DS:DGROUP

                public  __acrtused              ;satisfy MS for now
__acrtused      equ     0

                public __exitclean
                public __exit

extrn           WINMAIN:DIST
extrn           INITAPP:far
extrn           INITTASK:far
extrn           FATALEXIT:far
extrn           WAITEVENT:far
extrn           LOCKSEGMENT:far
extrn           UNLOCKSEGMENT:far
extrn           GETWINFLAGS:far
extrn           _exit:DIST
extrn           __exitbuf:DIST
extrn           __exitfopen:DIST
extrn           __exitopen:DIST

NULL            segment
                db      16 dup (?)
                ends

_CVTSEG         segment
                public __RealCvtVector
__RealCvtVector label word
                ends

_SCNSEG         segment
                public __ScanTodVector
__ScanTodVector label word
                ends

_FPSEG          segment
                public __FPVector
__FPVector      dd      0
                ends

_DATA           segment
                public _errno
_errno          dw      0
                public __protected
__protected     dw      0
                public __8087
__8087          dw      0
                public __psp
__psp           dw      0
                public __hInstance
__hInstance     dw      0
                public __hPrev
__hPrev         dw      0
                public __pszCmdline
__pszCmdline    dw      0
                public __cmdShow
__cmdShow       dw      0
                public __StartTime
__StartTime     dd      0
                public __version
__version       label word
                public __osversion
__osversion     label word
                public __osmajor
__osmajor       db      0
                public __osminor
__osminor       db      0
                public __osmode         ; Used for OS/2 protected mode by MS, 
__osmode        db      0               ; currently set to 0 under Windows
                public __WinAllocFlag   ;Used by malloc to get additional flags
__WinAllocFlag  dw      0               ;to pass to GlobalAlloc (for DLL use)

CopyRight       db      'Borland C++ - Copyright 1991 Borland Intl.',0
                ends

_TEXT           segment

Main            proc near

;Windows initialization.  Sets up registers and stack.

                ;INITTASK returns:
                ;  'Failure:
                ;    AX = zero if it failed
                ;  Success:
                ;    AX = 1
                ;    CX = stack limit
                ;    DX = cmdShow parameter to CreateWindow
                ;    ES:BX = -> DOS format command line (ES = PSP address)
                ;    SI = hPrevinstance
                ;    DI = hinstance
                call    INITTASK
                or      ax,ax
                jnz     @@OK
                jmp     @@Fail
@@OK:           mov     __psp,es
                mov     word ptr __pszCmdline,bx
                mov     __hPrev,si
                mov     __hInstance,di
                mov     __cmdShow,dx

IF LDATA EQ false
                mov     ax,-1
                push    ax
                call    LOCKSEGMENT
ENDIF

;Clear _BSS, uninitialized data area

IFNDEF  __HUGE__
                xor     ax, ax
                push    ds
                pop     es
                mov     di,offset DGROUP:BeginBSS
                mov     cx,offset DGROUP:EndBSS
                sub     cx,di
                cld
                rep
                stosb
ENDIF

;Init the Windows App

                xor     ax,ax
                push    ax
                call    WAITEVENT
                push    __hInstance
                call    INITAPP
                or      ax,ax
                jnz     @@InitOK
                jmp     @@Fail
@@InitOK:

;Save start time of App

                mov     ah, 0
                int     1ah             ; get current BIOS time in ticks
                mov     word ptr __StartTime,dx ; save it for clock() fn
                mov     word ptr __StartTime+2,cx

;Determine DOS version

                mov     ah, 30h
                int     21h
                mov     __version, ax   ; save minor and major revision
 
;Determine whether we are in protected mode

                call    GETWINFLAGS
                test    ax,1            ; WF_PMODE = 1
                jz      @@realmode      ; Note:  GETWINFLAGS returns a long,
                                        ; so if WF_PMODE changed it could be 
                                        ; in the high word.
                mov     __protected, 8  ; Eight is for convenience.
@@realmode:

;Test for 8087 presence

                test    dx,04h          ; WF_8087 = 0x0400
                jz      @@no8087
                mov     __8087, 1
@@no8087:

;Call our initialization functions, including C++ static constructors.

                mov     ax,ds
                mov     es,ax
                mov     si,offset DGROUP:InitStart      ;si = start of table
                mov     di,offset DGROUP:InitEnd        ;di = end of table
                call    Initialize

;Set up and call WinMain

                push    __hInstance
                push    __hPrev
                push    __psp
                push    word ptr __pszCmdline
                push    __cmdShow
                call    WINMAIN
                push    ax
                call    _exit

;Call our termination functions, including C++ static destructors.

__exitclean     label   DIST

                mov     ax,ds
                mov     es,ax
                mov     si,offset DGROUP:ExitStart
                mov     di,offset DGROUP:ExitEnd
                call    Cleanup
IF LPROG
                call    dword ptr [__exitbuf]
                call    dword ptr [__exitfopen]
                call    dword ptr [__exitopen]
ELSE
                call    word ptr [__exitbuf]
                call    word ptr [__exitfopen]
                call    word ptr [__exitopen]
ENDIF

__exit          label   DIST

IF LDATA EQ false
                mov     ax,-1
                push    ax
                call    UNLOCKSEGMENT
ENDIF
                mov     al,[bp+cPtrSize]
                mov     ah,4ch                  ;exit
                int     21h

@@Fail:         mov     al,0ffh
                push    ax
                call    _exit

                mov     ah,4ch                  ;exit
                int     21h
                endp


;------------------------------------------------------------------
;  Loop through a startup/exit (SE) table, 
;  calling functions in order of priority.
;  ES:SI is assumed to point to the beginning of the SE table
;  ES:DI is assumed to point to the end of the SE table
;  First 64 priorities are reserved by Borland
;------------------------------------------------------------------
PNEAR           EQU     0
PFAR            EQU     1
NOTUSED         EQU     0ffh

SE              STRUC
calltype        db      ?                       ; 0=near,1=far,ff=not used
priority        db      ?                       ; 0=highest,ff=lowest
addrlow         dw      ?
addrhigh        dw      ?
SE              ENDS

Initialize      proc near
@@Start:        mov     ah,0ffh                 ;start with lowest priority
                mov     dx,di                   ;set sentinel to end of table
                mov     bx,si                   ;bx = start of table

@@TopOfTable:   cmp     bx,di                   ;and the end of the table?
                je      @@EndOfTable            ;yes, exit the loop
                cmp     es:[bx.calltype],NOTUSED;check the call type
                je      @@Next
                cmp     es:[bx.priority],ah     ;check the priority
                ja      @@Next                  ;too high?  skip
                mov     ah,es:[bx.priority]     ;keep priority
                mov     dx,bx                   ;keep index in dx
@@Next:         add     bx,SIZE SE              ;bx = next item in table
                jmp     @@TopOfTable

@@EndOfTable:   cmp     dx,di                   ;did we exhaust the table?
                je      @@Done                  ;yes, quit
                mov     bx,dx                   ;bx = highest priority item
                cmp     es:[bx.calltype],PNEAR  ;is it near or far?
                mov     es:[bx.calltype],NOTUSED;wipe the call type
                push    es                      ;save es
                je      @@NearCall

@@FarCall:      call    DWORD PTR es:[bx.addrlow]
                pop     es                      ;restore es
                jmp     short @@Start

@@NearCall:     call    WORD PTR es:[bx.addrlow]
                pop     es                      ;restore es
                jmp     short @@Start

@@Done:         ret
                endp

Cleanup         proc near
@@Start:        mov     ah,0                    ;start with highest priority
                mov     dx,di                   ;set sentinel to end of table
                mov     bx,si                   ;bx = start of table

@@TopOfTable:   cmp     bx,di                   ;and the end of the table?
                je      @@EndOfTable            ;yes, exit the loop
                cmp     es:[bx.calltype],NOTUSED;check the call type
                je      @@Next
                cmp     es:[bx.priority],ah     ;check the priority
                jb      @@Next                  ;too low?  skip
                mov     ah,es:[bx.priority]     ;keep priority
                mov     dx,bx                   ;keep index in dx
@@Next:         add     bx,SIZE SE              ;bx = next item in table
                jmp     @@TopOfTable

@@EndOfTable:   cmp     dx,di                   ;did we exhaust the table?
                je      @@Done                  ;yes, quit
                mov     bx,dx                   ;bx = highest priority item
                cmp     es:[bx.calltype],PNEAR  ;is it near or far?
                mov     es:[bx.calltype],NOTUSED;wipe the call type
                push    es                      ;save es
                je      @@NearCall

@@FarCall:      call    DWORD PTR es:[bx.addrlow]
                pop     es                      ;restore es
                jmp     short @@Start

@@NearCall:     call    WORD PTR es:[bx.addrlow]
                pop     es                      ;restore es
                jmp     short @@Start

@@Done:         ret
                endp

                ends

                end Main
