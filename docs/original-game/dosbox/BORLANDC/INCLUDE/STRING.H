/*  string.h

    Definitions for memory and string functions.

        Copyright (c) Borland International 1987,1988,1990,1991
    All Rights Reserved.
*/

#ifndef __STRING_H
#define __STRING_H

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

#ifndef NULL
#if defined(__TINY__) || defined(__SMALL__) || defined(__MEDIUM__)
#define NULL    0
#else
#define NULL    0L
#endif
#endif

#ifndef _SIZE_T
#define _SIZE_T
typedef unsigned size_t;
#endif

#ifdef __cplusplus
extern "C" {
#endif
void _FAR * _Cdecl memchr  (const void _FAR *__s, int __c, size_t __n);
int         _Cdecl memcmp(const void _FAR *__s1,
                          const void _FAR *__s2, size_t __n);
void _FAR * _Cdecl memcpy(void _FAR *__dest, const void _FAR *__src,
                          size_t __n);
void _FAR * _CType memmove(void _FAR *__dest, const void _FAR *__src,
                           size_t __n);
void _FAR * _CType memset(void _FAR *__s, int __c, size_t __n);
char _FAR * _CType strcat(char _FAR *__dest, const char _FAR *__src);
char _FAR * _Cdecl strchr(const char _FAR *__s, int __c);
int         _CType strcmp(const char _FAR *__s1, const char _FAR *__s2);
int         _Cdecl strcoll(const char _FAR *__s1, const char _FAR *__s2);
char _FAR * _CType strcpy(char _FAR *__dest, const char _FAR *__src);
size_t      _Cdecl strcspn(const char _FAR *__s1, const char _FAR *__s2);
char _FAR * _Cdecl strerror(int __errnum);
size_t      _CType strlen(const char _FAR *__s);
char _FAR * _Cdecl strncat(char _FAR *__dest, const char _FAR *__src,
                           size_t __maxlen);
int         _Cdecl strncmp(const char _FAR *__s1, const char _FAR *__s2,
                           size_t __maxlen);
char _FAR * _CType strncpy(char _FAR *__dest, const char _FAR *__src,
                           size_t __maxlen);
char _FAR * _Cdecl strpbrk(const char _FAR *__s1, const char _FAR *__s2);
char _FAR * _CType strrchr(const char _FAR *__s, int __c);
size_t      _Cdecl strspn(const char _FAR *__s1, const char _FAR *__s2);
char _FAR * _Cdecl strstr(const char _FAR *__s1, const char _FAR *__s2);
char _FAR * _Cdecl strtok(char _FAR *__s1, const char _FAR *__s2);
size_t      _Cdecl strxfrm(char _FAR *__s1, const char _FAR *__s2,
                           size_t __n );
char _FAR * _Cdecl _strerror(const char _FAR *__s);


#if !__STDC__
/* compatibility with other compilers */
#define strcmpi(s1,s2)      stricmp(s1,s2)
#define strncmpi(s1,s2,n)   strnicmp(s1,s2,n)

void _FAR * _Cdecl memccpy(void _FAR *__dest, const void _FAR *__src,
                           int __c, size_t __n);
int         _Cdecl memicmp(const void _FAR *__s1, const void _FAR *__s2,
                           size_t __n);
void        _Cdecl movedata(unsigned __srcseg,unsigned __srcoff,
                            unsigned __dstseg,unsigned __dstoff, size_t __n);
char _FAR * _Cdecl stpcpy(char _FAR *__dest, const char _FAR *__src);
char _FAR * _Cdecl strdup(const char _FAR *__s);
int         _CType stricmp(const char _FAR *__s1, const char _FAR *__s2);
char _FAR * _Cdecl strlwr(char _FAR *__s);
int         _Cdecl strnicmp(const char _FAR *__s1, const char _FAR *__s2,
                            size_t __maxlen);
char _FAR * _Cdecl strnset(char _FAR *__s, int __ch, size_t __n);
char _FAR * _Cdecl strrev(char _FAR *__s);
char _FAR * _Cdecl strset(char _FAR *__s, int __ch);
char _FAR * _Cdecl strupr(char _FAR *__s);

void    far * far cdecl _fmemccpy(void far *__dest, const void far *__src,
                                int c, size_t __n);
void    far * far cdecl _fmemchr(const void far *__s, int c, size_t __n);
int     far       cdecl _fmemcmp(const void far *__s1, const void far *__s2,
                                size_t __n);
void    far * far cdecl _fmemcpy(void far *__dest, const void far *__src,
                                size_t __n);
int     far       cdecl _fmemicmp(const void far *__s1, const void far *__s2,
                                size_t __n);
void    far * far cdecl _fmemmove(void far *__dest, const void far *__src,
                                size_t __n);
void    far * far cdecl _fmemset(void far *__s, int c, size_t __n);
void    far       cdecl _fmovmem(void far *__src, void far *__dest,
                                unsigned __length);
void    far       cdecl _fsetmem(void far *__dest,unsigned __length, 
                                char __value);

char    far * far cdecl _fstrcat(char far *__dest, const char far *__src);
char    far * far cdecl _fstrchr(const char far *__s, int c);
int     far       cdecl _fstrcmp(const char far *__s1, const char far *__s2);
char    far * far cdecl _fstrcpy(char far *__dest, const char far *__src);
size_t  far       cdecl _fstrcspn(const char far *__s1, const char far *__s2);
char    far * far cdecl _fstrdup(const char far *__s);
int     far       cdecl _fstricmp(const char far *__s1, const char far *__s2);
size_t  far       cdecl _fstrlen(const char far *__s);
char    far * far cdecl _fstrlwr(char far *__s);
char    far * far cdecl _fstrncat(char far *__dest, const char far *__src,
                                  size_t maxlen);
int     far       cdecl _fstrncmp(const char far *__s1, const char far *__s2,
                                  size_t maxlen);
char    far * far cdecl _fstrncpy(char far *__dest, const char far *__src,
                                  size_t maxlen);
int     far       cdecl _fstrnicmp(const char far *__s1, const char far *__s2,
                                   size_t maxlen);
char    far * far cdecl _fstrnset(char far *__s, int ch, size_t __n);
char    far * far cdecl _fstrpbrk(const char far *__s1, const char far *__s2);
char    far * far cdecl _fstrrchr(const char far *__s, int c);
char    far * far cdecl _fstrrev(char far *__s);
char    far * far cdecl _fstrset(char far *__s, int ch);
size_t  far       cdecl _fstrspn(const char far *__s1, const char far *__s2);
char    far * far cdecl _fstrstr(const char far *__s1, const char far *__s2);
char    far * far cdecl _fstrtok(char far *__s1, const char far *__s2);
char    far * far cdecl _fstrupr(char far *__s);

#endif

#ifdef __cplusplus
}
#endif

#endif
