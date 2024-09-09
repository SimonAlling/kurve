/*      search.h

        Definitions for search functions.

        Copyright (c) Borland International 1991
        All Rights Reserved.
*/

#ifndef __SEARCH_H
#define __SEARCH_H

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

#ifndef _SIZE_T
#define _SIZE_T
typedef unsigned size_t;
#endif

#ifdef __cplusplus
extern "C" {
#endif
void   _FAR *_CType bsearch(const void _FAR *__key, const void _FAR *__base, 
                size_t __nelem, size_t __width,
                int _Cdecl(*fcmp)(const void _FAR *, const void _FAR *));
void   _FAR *_Cdecl lfind(const void _FAR *__key, const void _FAR *__base, 
                 size_t _FAR *__num, size_t __width,
                 int _Cdecl(*fcmp)(const void _FAR *, const void _FAR *));
void   _FAR *_Cdecl lsearch(const void _FAR *__key, void _FAR *__base, 
                 size_t _FAR *__num, size_t __width, 
                 int _Cdecl(*fcmp)(const void _FAR *, const void _FAR *));
void    _Cdecl qsort(void _FAR *__base, size_t __nelem, size_t __width,
                int _Cdecl(*__fcmp)(const void _FAR *, const void _FAR *));
#ifdef __cplusplus
}
#endif

#endif	/* __SEARCH_H */
