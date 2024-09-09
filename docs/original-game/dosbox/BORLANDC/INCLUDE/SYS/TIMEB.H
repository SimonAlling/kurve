/*  timeb.h

    Struct and function declarations for ftime().

        Copyright (c) Borland International 1987,1988,1990,1991
    All Rights Reserved.
*/

#if !defined( __TIMEB_H )
#define __TIMEB_H

#ifdef __DLL__
#define _FAR far
#else
#define _FAR
#endif

#if __STDC__
#define _Cdecl
#else
#define _Cdecl cdecl
#endif

#ifndef __PAS__
#define _CType _Cdecl
#else
#define _CType pascal
#endif

struct timeb {
      long  time;
      short millitm;
      short timezone;
      short dstflag;
      };

#ifdef __cplusplus
extern "C" {
#endif
void _Cdecl ftime(struct timeb _FAR *);
#ifdef __cplusplus
}
#endif

#endif  /* __TIMEB_H */

