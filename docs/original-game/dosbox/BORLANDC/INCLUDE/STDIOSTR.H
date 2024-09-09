/* stdiostream.h -- class stdiobuf and stdiostream declarations

    Copyright (c) 1990,1991 by Borland International    
    All rights reserved

    NOTE: These are inefficient and obsolete.  Use the standard classes and
    functions in <fstream.h> instead.
*/

#ifndef __cplusplus
#error Must use C++ for the type stdiostream.
#endif

#ifndef __STDSTREAM_H
#define __STDSTREAM_H

#if !defined( __IOSTREAM_H )
#include <iostream.h>
#endif

#if !defined( __STDIO_H )
#include <stdio.h>
#endif

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

#if   defined(__SMALL__) || defined(__MEDIUM__)
#define _CLASSTYPE  near
#elif defined(__COMPACT__) || defined(__LARGE__)
#define _CLASSTYPE  far
#else
#define _CLASSTYPE  huge
#endif

class _CLASSTYPE stdiobuf : public streambuf {
public:
        _Cdecl stdiobuf(FILE _FAR *);
    FILE _FAR * _Cdecl stdiofile();
        _Cdecl ~stdiobuf();

virtual int _Cdecl overflow(int=EOF);
virtual int _Cdecl pbackfail(int);
virtual int _Cdecl sync();
virtual streampos _Cdecl seekoff(streamoff, seek_dir, int);
virtual int _Cdecl underflow();

private:
    FILE _FAR * sio;            
    char    lahead[2];
};
inline  FILE _FAR * _Cdecl stdiobuf::stdiofile() { return sio; }


class _CLASSTYPE stdiostream : public ios {
public:
        _Cdecl stdiostream(FILE _FAR *);
        _Cdecl ~stdiostream();
    stdiobuf _FAR * _Cdecl rdbuf();

private:
    stdiobuf buf;
};
inline  stdiobuf _FAR * _Cdecl stdiostream::rdbuf() { return &buf; }

#endif
