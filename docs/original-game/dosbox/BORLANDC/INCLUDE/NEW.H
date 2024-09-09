/*  new.h

    Access to operator new() and newhandler()

    Copyright (c) Borland International 1990,1991
    All Rights Reserved.
*/

#if !defined( __NEW_H )
#define __NEW_H

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

#ifndef __cplusplus
#error Must use C++ with new.h
#endif

typedef void (*pvf)();
 
extern void (* _Cdecl _new_handler)();
 
void (*set_new_handler( void (*)() ))();

void _FAR * operator new( unsigned );

#endif  /* __NEW_H */

