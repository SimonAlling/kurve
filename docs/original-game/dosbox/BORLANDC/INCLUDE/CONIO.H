/*  conio.h

    Direct MSDOS console input/output.

    Copyright (c) Borland International 1987,1988,1990,1991
    All Rights Reserved.
*/

#if defined( _Windows )
#error conio routines not supported under Windows
#endif

#if !defined(__CONIO_H)
#define __CONIO_H

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

#define _NOCURSOR      0
#define _SOLIDCURSOR   1
#define _NORMALCURSOR  2

struct text_info {
    unsigned char winleft;
    unsigned char wintop;
    unsigned char winright;
    unsigned char winbottom;
    unsigned char attribute;
    unsigned char normattr;
    unsigned char currmode;
    unsigned char screenheight;
    unsigned char screenwidth;
    unsigned char curx;
    unsigned char cury;
};

enum text_modes { LASTMODE=-1, BW40=0, C40, BW80, C80, MONO=7, C4350=64 };

#if !defined(__COLORS)
#define __COLORS

enum COLORS {
    BLACK,          /* dark colors */
    BLUE,
    GREEN,
    CYAN,
    RED,
    MAGENTA,
    BROWN,
    LIGHTGRAY,
    DARKGRAY,       /* light colors */
    LIGHTBLUE,
    LIGHTGREEN,
    LIGHTCYAN,
    LIGHTRED,
    LIGHTMAGENTA,
    YELLOW,
    WHITE
};
#endif

#define BLINK       128 /* blink bit */

extern   int _Cdecl directvideo;
extern   int _Cdecl _wscroll;

#ifdef __cplusplus
extern "C" {
#endif

void        _Cdecl clreol( void );
void        _Cdecl clrscr( void );
void        _Cdecl delline( void );
int         _Cdecl gettext( int __left, int __top,
                            int __right, int __bottom,
                            void *__destin);
void        _Cdecl gettextinfo (struct text_info *__r );
void        _Cdecl gotoxy( int __x, int __y );
void        _Cdecl highvideo( void );
#ifdef __MSC
int         _Cdecl inport( int __portid );
#ifndef _PORT_DEFS
unsigned char _Cdecl inportb( int __portid );
#endif
#endif
void        _Cdecl insline( void );
void        _Cdecl lowvideo( void );
int         _Cdecl movetext( int __left, int __top,
                             int __right, int __bottom,
                             int __destleft, int __desttop );
void        _Cdecl normvideo( void );
#ifdef __MSC
void        _Cdecl outport( int __portid, int __value );
#ifndef _PORT_DEFS
void        _Cdecl outportb( int __portid, unsigned char __value );
#endif
#endif
int         _Cdecl puttext( int __left, int __top,
                            int __right, int __bottom,
                            void *__source );
void        _Cdecl textattr( int __newattr );
void        _Cdecl textbackground( int __newcolor );
void        _Cdecl textcolor( int __newcolor );
void        _Cdecl textmode( int __newmode );
int         _Cdecl wherex( void );
int         _Cdecl wherey( void );
void        _Cdecl window( int __left, int __top, int __right, int __bottom);

void        _Cdecl _setcursortype( int __cur_t );
char * _Cdecl cgets( char *__str );
int         _Cdecl cprintf( const char *__format, ... );
int         _Cdecl cputs( const char *__str );
int         _Cdecl cscanf( const char *__format, ... );
int         _Cdecl getch( void );
int         _Cdecl getche( void );
char * _Cdecl getpass( const char *__prompt );
int         _Cdecl kbhit( void );
int         _Cdecl putch( int __c );
int         _Cdecl ungetch( int __ch );

#ifdef __MSC
#ifndef _PORT_DEFS
#define _PORT_DEFS

    /* These are in-line functions.  These prototypes just clean up
       some syntax checks and code generation.
     */
unsigned char _Cdecl    __inportb__( int __portid );
unsigned int _Cdecl     __inportw__( int __portid );
void        _Cdecl      __outportb__( int __portid, unsigned char __value );
void        _Cdecl      __outportw__( int __portid, unsigned int __value );

#define inportb         __inportb__
#define inportw         __inportw__
#define outportb        __outportb__
#define outportw        __outportw__

#define inp( portid ) inportb( portid )
#define outp( portid,v )  outportb( portid,v )
#define inpw( portid ) inportw( portid )
#define outpw( portid,v )  outportw( portid,v )

#endif	/* _PORT_DEFS */
#endif	/* __MSC */

#ifdef __cplusplus
}
#endif


#endif  /* __CONIO_H */
