/*  assert.h

    assert macro

    Copyright (c) Borland International 1987,1988,1990,1991
    All Rights Reserved.
*/

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

#ifdef __cplusplus
extern "C" {
#endif

void        _Cdecl __assertfail( char _FAR *__msg,
                                 char _FAR *__cond,
                                 char _FAR *__file,
                                 int __line);

#ifdef  __cplusplus
}
#endif

#undef assert

#ifdef NDEBUG
#define assert(p)   ((void)0)
#else
#define assert(p)   ((p) ? (void)0 : (void) __assertfail( \
                    "Assertion failed: %s, file %s, line %d\n", \
                    #p, __FILE__, __LINE__ ) )
#endif
