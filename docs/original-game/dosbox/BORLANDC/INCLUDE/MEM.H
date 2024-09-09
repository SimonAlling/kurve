/*  mem.h

    Memory manipulation functions

    Copyright (c) Borland International 1987,1988,1990,1991
    All Rights Reserved.
*/

#if !defined( __MEM_H )
#define __MEM_H

#ifdef __DLL__
#define _FAR far
#else
#define _FAR
#endif

#if __STDC__
#define _Cdecl
#else
#define _Cdecl  cdecl
#endif

#ifndef __PAS__
#define _CType _Cdecl
#else
#define _CType pascal
#endif

#ifndef _STDDEF
#define _STDDEF
#ifndef _PTRDIFF_T
#define _PTRDIFF_T
#if defined(__LARGE__) || defined(__HUGE__) || defined(__COMPACT__)
typedef long    ptrdiff_t;
#else
typedef int ptrdiff_t;
#endif
#endif
#ifndef _SIZE_T
#define _SIZE_T
typedef unsigned size_t;
#endif
#endif

#ifndef NULL
#if defined(__TINY__) || defined(__SMALL__) || defined(__MEDIUM__)
#define NULL    0
#else
#define NULL    0L
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif
void _FAR * _Cdecl memccpy(void _FAR *__dest, const void _FAR *__src,
                           int __c, size_t __n);
void _FAR * _Cdecl memchr(const void _FAR *__s, int __c, size_t __n);
int         _Cdecl memcmp(const void _FAR *__s1, const void _FAR *__s2,
                          size_t __n);
void _FAR * _Cdecl memcpy(void _FAR *__dest, const void _FAR *__src,
                          size_t __n);
int         _Cdecl memicmp(const void _FAR *__s1, const void _FAR *__s2,
                          size_t __n);
void _FAR * _CType memmove(void _FAR *__dest, const void _FAR *__src,
                          size_t __n);
void _FAR * _CType memset(void _FAR *__s, int __c, size_t __n);
void        _Cdecl movedata(unsigned __srcseg, unsigned __srcoff,
                            unsigned __dstseg,unsigned __dstoff, size_t __n);
void        _Cdecl movmem(void _FAR *__src, void _FAR *__dest,
                          unsigned __length);
void        _Cdecl setmem(void _FAR *__dest,unsigned __length, char __value);

#if !__SDTC__
void  far * far cdecl _fmemccpy(void far *__dest, const void far *__src,
                                int c, size_t __n);
void  far * far cdecl _fmemchr(const void far *__s, int c, size_t __n);
int   far       cdecl _fmemcmp(const void far *__s1, const void far *__s2,
                                size_t __n);
void  far * far cdecl _fmemcpy(void far *__dest, const void far *__src,
                                size_t __n);
int   far       cdecl _fmemicmp(const void far *__s1, const void far *__s2,
                                size_t __n);
void  far * far cdecl _fmemmove(void far *__dest, const void far *__src,
                                size_t __n);
void  far * far cdecl _fmemset(void far *__s, int c, size_t __n);
void  far       cdecl _fmovmem(void far *__src, void far *__dest,
                                unsigned __length);
void  far       cdecl _fsetmem(void far *__dest,unsigned __length, 
                                char __value);
#endif

#ifdef __cplusplus
}
#endif

#endif  /* __MEM_H */

