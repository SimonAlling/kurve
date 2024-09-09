; Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

; FROM_NEW.ASM

; Interfacing Turbo Assembler and Turbo Prolog.

       extrn    PopMessage_0:far
       .model 	large,c
       .code 
       public   FROM_ASM

FROM_ASM     proc
       push  ds
       mov   ax, OFFSET DGROUP:mess1
       push  ax
       call  FAR PTR PopMessage_0
       pop   cx
       pop   cx
       ret
FROM_ASM     ENDP

       .data
mess1  DB       "Report: Condition Red",0
       END

 
