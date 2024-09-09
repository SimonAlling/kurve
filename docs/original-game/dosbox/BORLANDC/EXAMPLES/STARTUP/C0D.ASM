;[]------------------------------------------------------------[]
;|      C0D.ASM -- Start Up Code For Windows DLLs               |
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

                extrn LIBMAIN:far       ;the C routine to be called
                extrn LOCALINIT:far     ;Windows heap init routine
                extrn LOCKSEGMENT:far
                extrn UNLOCKSEGMENT:far
                extrn GETWINFLAGS:far
                extrn __WEP:far

                extrn __exitbuf:DIST
                extrn __exitfopen:DIST
                extrn __exitopen:DIST

                public LibEntry         ;Entry point for the DLL
                publicdll WEP

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
                public __version
__version       label word
                public __osversion
__osversion     label word
                public __osmajor
__osmajor       db      0
                public __osminor
__osminor       db      0
                public __osmode         ;Used for OS/2 protected mode by MS, 
__osmode        db      0               ;currently set to 0 under Windows
                public __hInstance
__hInstance     dw      0
                public __WinAllocFlag   ;Used by malloc for additional flags
__WinAllocFlag  dw      0               ;to pass to GlobalAlloc (used in DLLs)

_abend          dw      0               ;gets set to 1 if DLL is terminated
                                        ;by a call to abort() or _exit().

CopyRight       db      'Borland C++ - Copyright 1991 Borland Intl.',0
                ends

_TEXT           segment

LibEntry        proc far
                mov     __hInstance, di ;save SI and DI
                push    si

                push    di              ;handle of the module instance
                push    ds              ;library data segment
                push    cx              ;heap size
                push    es              ;command line segment
                push    si              ;command line offset

                ;if we have some heap then initialize it
                jcxz    @@Init          ;jump if no heap specified

                ;call the Windows function LocalInit() to set up the heap
                ;LocalInit((LPSTR)start, WORD cbHeap);

                push    ds              ;Heap segment
                xor     ax,ax
                push    ax              ;Heap start offset in segment
                push    cx              ;Heap end offset in segment
                call    LOCALINIT
                xchg    ax,cx
                jcxz    @@Exit          ;quit if it failed

@@Init:

IF LDATA EQ false
                mov     ax,-1
                push    ax
                call    LOCKSEGMENT
ENDIF

                ;Clear _BSS, uninitialized data area

                xor     ax, ax
                push    ds
                pop     es
                mov     di,offset DGROUP:BeginBSS
                mov     cx,offset DGROUP:EndBSS
                sub     cx,di
                cld
                rep
                stosb

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

                mov     __WinAllocFlag, 2000h           ; GMEM_SHARE
                call    Initialize
                mov     __WinAllocFlag, 0

                ;invoke the C routine to do any special initialization
@@Main:         call    LIBMAIN         ;invoke the 'C' routine (result in AX)
                mov     di, __hInstance ;restore SI and DI
                pop     si
                ret

@@Exit:         mov ax, 0               ;set return code
                pop si                  ;remove arguments to LIBMAIN
                pop es                  ;  since we didn't call it. 
                pop cx
                pop ds
                pop di                  
                pop si                  ;restore saved SI.  DI is restored 
                ret                     ;  by removing arguments to LIBMAIN
                endp

__exit          proc
                mov _abend, 1
__exitclean:
                mov al,[bp+cPtrSize]
                mov ah,4ch
                int 21h
                ret
                endp

WEP             proc    windows pascal far nParam:WORD
                push    si
                push    di

                cmp     _abend, 0
                jne     @@error
                push    nParam
                call    __WEP
                push    ax

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

@@unlock:

IF LDATA EQ false
                mov     ax,-1
                push    ax
                call    UNLOCKSEGMENT
ENDIF

                pop     ax  
                pop     di
                pop     si
                ret

@@error:
                push    1
                jmp     @@unlock
                
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
                end LibEntry

