/*  alloc.h

  memory management functions and variables.

  Copyright (c) Borland International 1987,1988,1990,1991
  All Rights Reserved.
*/

#if     !defined(__ALLOC_H)
#define __ALLOC_H

#ifdef __DLL__
#define _FAR far
#else
#define _FAR
#endif

#define _HEAPEMPTY      1
#define _HEAPOK         2
#define _FREEENTRY      3
#define _USEDENTRY      4
#define _HEAPEND        5
#define _HEAPCORRUPT    -1
#define _BADNODE        -2
#define _BADVALUE       -3

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
typedef long  ptrdiff_t;
#else
typedef int ptrdiff_t;
#endif
#endif
#ifndef _SIZE_T
#define _SIZE_T
typedef unsigned size_t;
#endif
#endif

#if !__STDC__
struct farheapinfo
  {
  void huge *ptr;
  unsigned long size;
  int in_use;
  };
#endif

#if defined(__TINY__) || defined(__SMALL__) || defined(__MEDIUM__)
struct heapinfo
  {
  void _FAR *ptr;
  unsigned int size;
  int in_use;
  };
#else
#define heapinfo farheapinfo 
#endif

#ifndef NULL
#if defined(__TINY__) || defined(__SMALL__) || defined(__MEDIUM__)
#define NULL  0
#else
#define NULL  0L
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

void  _FAR *_Cdecl calloc  (size_t __nitems, size_t __size);
void        _Cdecl free  (void _FAR *__block);
void  _FAR *_Cdecl malloc  (size_t  __size);
void  _FAR *_Cdecl realloc (void _FAR *__block, size_t __size);

#if !defined( _Windows )

int         _Cdecl brk  (void _FAR *__addr);
void  _FAR *_Cdecl sbrk  (int __incr);

int         _Cdecl heapcheck( void );
int         _Cdecl heapfillfree( unsigned int __fillvalue );
int         _Cdecl heapcheckfree( unsigned int __fillvalue );

#if defined(__COMPACT__) || defined(__LARGE__) || defined(__HUGE__)

unsigned long _Cdecl coreleft (void);

#if !__STDC__
int         _Cdecl heapchecknode( void far *__node );
int         _Cdecl heapwalk( struct farheapinfo far *__hi );
#endif

#else

unsigned    _Cdecl coreleft  (void);
int         _Cdecl heapchecknode( void _FAR *__node );
int         _Cdecl heapwalk( struct heapinfo _FAR *__hi );

#endif

#endif  /* WINDOWS */

#if !__STDC__
void far  * _Cdecl farcalloc(unsigned long __nunits, unsigned long __unitsz);
unsigned long _Cdecl farcoreleft( void );
void        _Cdecl      farfree( void far *__block);
void far  * _Cdecl farmalloc( unsigned long __nbytes);
void far  * _Cdecl farrealloc( void far *__oldblock, unsigned long __nbytes);
int         _Cdecl farheapcheck( void );
int         _Cdecl farheapchecknode( void far *__node );
int         _Cdecl farheapfillfree( unsigned int __fillvalue );
int         _Cdecl farheapcheckfree( unsigned int __fillvalue );
int         _Cdecl farheapwalk( struct farheapinfo *__hi );
#endif

#ifdef __cplusplus
}
#endif

#endif  /* __ALLOC_H */
