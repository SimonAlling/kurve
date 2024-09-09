/* C++ Stream I/O header file

    Copyright (c) Borland International 1987,1988,1990,1991
    All Rights Reserved.

    NOTE: The data and function variables are declared so that any
    combination of alignment and size-of-enum compiler options will
    produce the same results.
*/

#ifndef __cplusplus
#error Must use C++ for the type stream.
#endif

#if ! defined( __STREAM_H )
#define __STREAM_H

#if !defined( __STDIO_H )
#include <stdio.h>
#endif

#ifdef __DLL__
#define _FAR far
#else
#define _FAR
#endif

#if   defined(__SMALL__) || defined(__MEDIUM__)
#define _CLASSTYPE  near
#elif defined(__COMPACT__) || defined(__LARGE__)
#define _CLASSTYPE  far
#else
#define _CLASSTYPE  huge
#endif

/*
 * whitespace
 */
struct whitespace { char x; };
extern struct whitespace WS;

class _CLASSTYPE istream;
class _CLASSTYPE ostream;

/*
 * basic stream buffer class
 */
class _CLASSTYPE streambuf {
  friend istream;
  friend ostream;

  protected:
    FILE _FAR *file;            // if non-0, connected stdio file
    char _FAR *base;            // start of buffer
    char _FAR *pptr;            // next free char (for output)
    char _FAR *gptr;            // next avail char (for input)
    char _FAR *eptr;            // one off end of buffer
    int didalloc;       // non-0 if we allocated a buffer

    // empty full output buffer, put c in it
    virtual int _Cdecl overflow( int = EOF );

    // fill empty input buffer, get first char
    virtual int _Cdecl underflow();

    // allocate a buffer
    int _Cdecl allocate();

    // specify a buffer to use, possibly with data in it (offset > 0 )
    streambuf _FAR * _Cdecl setbuf( char _FAR *, int, unsigned = 0 );

    // add a null byte to a string without advancing pointer
    virtual void _Cdecl terminate();

  public:
    // constructor: no buffer
    _Cdecl streambuf()
    { file = 0; didalloc = 0; base = pptr = gptr = eptr = 0; }

    // constructor: user buffer
    _Cdecl streambuf( char _FAR *buf, int len )
    { file = 0; didalloc = 0; setbuf(buf, len); }

    // destructor
    virtual _Cdecl ~streambuf();

    // get next char from input buffer
    virtual int _Cdecl snextc();

    // write a char to output buffer
    virtual int _Cdecl sputc( int );

    // return a char to input buffer
    virtual void _Cdecl sputbackc( char );
};


/*
 * file buffer class
 */
enum open_mode { input, output, append }; // mode for opening a file

class _CLASSTYPE filebuf: public streambuf {

  private:
    int fd;         // external file id
    int isopen;         // non-0 if open

  protected:

    // we don't need to add a null byte to a file
    void _Cdecl terminate() { };

  public:
    _Cdecl filebuf() { isopen = 0; fd = 0; } // basic constructor
    _Cdecl filebuf( FILE _FAR * );      // tie to existing stdio file
    _Cdecl filebuf( int );      // tie to existing file
    _Cdecl filebuf( int , char _FAR *, int ); // tie to file, user buffer
    _Cdecl ~filebuf() { close(); }  // destructor (virtual)

    // open a named external file
    filebuf _FAR * _Cdecl open( char _FAR *, int );

    // close the external file
    int _Cdecl close();

    // get next char from input buffer
    int _Cdecl snextc() { return ::fgetc(file); }

    // write a char to output buffer
    int _Cdecl sputc( int _C ) { return ::fputc(_C, file); }

    // return a char to input buffer
    void _Cdecl sputbackc( char _C ) { (void) ::ungetc(_C, file); }
};


/*
 * formatting functions
 */
char _FAR * _Cdecl dec( long, int = 0 );    // internal to decimal text
char _FAR * _Cdecl hex( long, int = 0 );    // internal to hex text
char _FAR * _Cdecl oct( long, int = 0 );    // internal to octal text

char _FAR * _Cdecl chr( int, int = 0 ); // char to string
char _FAR * _Cdecl str( const char _FAR *, int = 0 ); // make fixed-width string
char _FAR * _Cdecl form( char _FAR * ... ); // general formating


/*
 * state of istream or ostream
 */
enum stream_state { _good, _eof, _fail, _bad };

/*
 * class ostream
 */
class _CLASSTYPE ostream {
  friend istream;

  private:
    streambuf _FAR *stream;         // connected streambuf or filebuf
    char mystream;          // non-0 if stream was alloc'd here
    char state;             // state of stream

  public:
    _Cdecl ostream( streambuf _FAR * );     // connect to existing streambuf
    _Cdecl ostream( int );          // connect to open file
    _Cdecl ostream( int, char _FAR * );     // connect to char array
    _Cdecl ~ostream() {         // destructor
    (void) flush();
    if( mystream ) delete stream;
    }

    // test the stream
    _Cdecl operator void _FAR *() { return (state==_good) ? this : 0; }
    int _Cdecl operator !() { return (state != _good); }

    ostream& _Cdecl operator << ( int );        // write a char, uns char, short, or int
    ostream& _Cdecl operator << ( long );       // write a long
    ostream& _Cdecl operator << ( unsigned int _U ) {   // write uns short, uns int
    return *this << ((long) _U);
    }
    ostream& _Cdecl operator << ( unsigned long );  // write unsigned long
    ostream& _Cdecl operator << ( const char _FAR * );  // write a string
    ostream& _Cdecl operator << ( double );     // write floating-point
    ostream& _Cdecl operator << ( long double );    // write floating-point

    ostream& _Cdecl put( char _C ) {        // write char as a char
    if( stream->sputc(_C) == EOF )
        state = _fail;
    return *this;
    }

    ostream& _Cdecl flush();            // flush output buffer

    // return stream state
    int _Cdecl rdstate() { return state; }

    // set stream state
    void _Cdecl clear( int _S = _good ) { state = _S; }

    // non-0 if bad
    int _Cdecl bad() { return (state >= _bad); }

    // non-0 if bad or failed
    int _Cdecl fail() { return (state >= _fail); }

    // non-0 if end of input
    int _Cdecl eof() { return (state == _eof); }

    // non-0 if ok
    int _Cdecl good() { return (state == _good); }
};


/*
 * class istream
 */
class _CLASSTYPE istream {
  friend ostream;
  friend void _Cdecl eatwhite( istream & _S ) { _S >> WS; }

  private:
    ostream _FAR *tied_to;          // tied ostream, if non-0
    streambuf _FAR *stream;         // connected streambuf or filebuf
    char skipping;          // non-0 if skipping whitespace
    char mystream;          // non-0 if stream was alloc'd here
    int state;              // state of stream

    void _Cdecl checkskip( int&, int& );    // used internally
    long _Cdecl get_long( int );        // used internally

  public:
    // connect to streambuf or filebuf
    _Cdecl istream( streambuf _FAR *, int = 1, ostream _FAR * = 0 );
    // connect to string
    _Cdecl istream( int, char _FAR *, int = 1 );
    // connect to open file
    _Cdecl istream( int, int = 1, ostream _FAR * = 0 );
    // destructor
    _Cdecl ~istream() {
    if( mystream ) delete stream;
    }

    // test the stream
    _Cdecl operator void _FAR *() { return (state==_good) ? this : 0; }
    int _Cdecl operator !() { return (state != _good); }

    /*
     * input functions
     */
    istream& _Cdecl operator >> ( signed char& _C ) {
    unsigned char _X;
    *this >> _X;
    if( state == _good ) _C = (signed char) _X;
    return *this;
    }
    istream& _Cdecl operator >> ( short& _S ) {
    short _T = (short) get_long(0);
    if( state == _good ) _S = _T;
    return *this;
    }
    istream& _Cdecl operator >> ( int& _I ) {
    int _T = (int) get_long(0);
    if( state == _good ) _I = _T;
    return *this;
    }
    istream& _Cdecl operator >> ( long& _L ) {
    long _T = get_long(0);
    if( state == _good ) _L = _T;
    return *this;
    }
    istream& _Cdecl operator >> ( unsigned char& );
    istream& _Cdecl operator >> ( unsigned short& _S ) {
    unsigned short _T = (unsigned short) get_long(1);
    if( state == _good ) _S = _T;
    return *this;
    }
    istream& _Cdecl operator >> ( unsigned int& _I ) {
    unsigned int _T = (unsigned int) get_long(1);
    if( state == _good ) _I = _T;
    return *this;
    }
    istream& _Cdecl operator >> ( unsigned long& _L ) {
    unsigned long _T = (unsigned long) get_long(1);
    if( state == _good ) _L = _T;
    return *this;
    }
    istream& _Cdecl operator >> ( float& );
    istream& _Cdecl operator >> ( double& );
    istream& _Cdecl operator >> ( long double& );
    istream& _Cdecl operator >> ( char _FAR * );
    istream& _Cdecl operator >> ( whitespace& );
    istream& _Cdecl get(char& );
    istream& _Cdecl get(char _FAR *, int, int = '\n' );

    // set skipping state
    int _Cdecl skip( int _S ) {
    short _T = skipping; skipping = _S; return _T;
    }

    // tie to ostream
    ostream _FAR * _Cdecl tie( ostream _FAR *_To ) {
    ostream _FAR *_T = tied_to; tied_to = _To; return _T;
    }

    // return a character to input
    void _Cdecl putback( char _C ) { stream->sputbackc(_C); };

    // return stream state
    int _Cdecl rdstate() { return state; }

    // set stream state
    void _Cdecl clear( int _S = _good ) { state = _S; }

    // non-0 if bad
    int _Cdecl bad() { return (state >= _bad); }

    // non-0 if bad or failed
    int _Cdecl fail() { return (state >= _fail); }

    // non-0 if end of input
    int _Cdecl eof() { return (state == _eof); }

    // non-0 if ok
    int _Cdecl good() { return (state == _good); }
};

extern istream _Cdecl cin;
extern ostream _Cdecl cout;
extern ostream _Cdecl cerr;

#endif  // __STREAM_H
