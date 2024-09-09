/*  dir.h

    Defines structures, macros, and functions for dealing with
    directories and pathnames.

    Copyright (c) Borland International 1987,1988,1990,1991
    All Rights Reserved.
*/

#if !defined( __DIR_H )
#define __DIR_H

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

#ifndef _FFBLK_DEF
#define _FFBLK_DEF
struct  ffblk   {
    char        ff_reserved[21];
    char        ff_attrib;
    unsigned    ff_ftime;
    unsigned    ff_fdate;
    long        ff_fsize;
    char        ff_name[13];
};
#endif

#define WILDCARDS 0x01
#define EXTENSION 0x02
#define FILENAME  0x04
#define DIRECTORY 0x08
#define DRIVE     0x10

#define MAXPATH   80
#define MAXDRIVE  3
#define MAXDIR    66
#define MAXFILE   9
#define MAXEXT    5

#ifdef __cplusplus
extern "C" {
#endif

int         _Cdecl chdir( const char _FAR *__path );
int         _CType findfirst( const char _FAR *__path,
                              struct ffblk _FAR *__ffblk, 
                              int __attrib );
int         _CType findnext( struct ffblk _FAR *__ffblk );
void        _CType fnmerge( char _FAR *__path,
                            const char _FAR *__drive,
                            const char _FAR *__dir,
                            const char _FAR *__name,
                            const char _FAR *__ext );
int         _CType fnsplit( const char _FAR *__path,
                            char _FAR *__drive, 
                            char _FAR *__dir, 
                            char _FAR *__name,
                            char _FAR *__ext );
int         _Cdecl getcurdir( int __drive, char _FAR *__directory );
char _FAR * _Cdecl getcwd( char _FAR *__buf, int __buflen );
int         _Cdecl getdisk( void );
int         _Cdecl mkdir( const char _FAR *__path );
char _FAR * _Cdecl mktemp( char _FAR *__template );
int         _Cdecl rmdir( const char _FAR *__path );
char _FAR * _CType searchpath( const char _FAR *__file );
int         _Cdecl setdisk( int __drive );
#ifdef __cplusplus
}
#endif

#endif  /* __DIR_H */

