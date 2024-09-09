/*  bios.h

    Access to bios services.

    Copyright (c) Borland International 1987,1988,1990,1991
    All Rights Reserved.
*/

#if !defined( __BIOS_H )
#define __BIOS_H

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

/* register structure definitions for int86(), int86x() */

#ifdef __MSC
#ifndef _REG_DEFS
#define _REG_DEFS

struct WORDREGS {
    unsigned int    ax, bx, cx, dx, si, di, cflag, flags;
};

struct BYTEREGS {
    unsigned char   al, ah, bl, bh, cl, ch, dl, dh;
};

union   REGS    {
    struct  WORDREGS x;
    struct  BYTEREGS h;
};

struct  SREGS   {
    unsigned int    es;
    unsigned int    cs;
    unsigned int    ss;
    unsigned int    ds;
};

struct  REGPACK {
    unsigned    r_ax, r_bx, r_cx, r_dx;
    unsigned    r_bp, r_si, r_di, r_ds, r_es, r_flags;
};

#endif	/* _REG_DEFS */
#endif	/* __MSC */

#ifdef __cplusplus
extern "C" {
#endif
int _Cdecl bioscom(int __cmd, char __abyte, int __port);
int _Cdecl biosdisk(int __cmd, int __drive, int __head, int __track,
                    int __sector, int __nsects, void _FAR *__buffer);
int _Cdecl biosequip(void);
int _Cdecl bioskey(int __cmd);
int _Cdecl biosmemory(void);
int _Cdecl biosprint(int __cmd, int __abyte, int __port);
long    _Cdecl biostime(int __cmd, long __newtime);

#ifdef __MSC
int         _Cdecl int86( int __intno,
                          union REGS _FAR *__inregs,
                          union REGS _FAR *__outregs );
int         _Cdecl int86x( int __intno,
                           union REGS _FAR *__inregs,
                           union REGS _FAR *__outregs,
                           struct SREGS _FAR *__segregs );
#endif

#ifdef __cplusplus
}
#endif

#ifdef __MSC

/* cmd values for _bios_keybrd() */

#define _KEYBRD_READ		0	/* read key */
#define _NKEYBRD_READ		0x10	/* read key - enhanced */
#define _KEYBRD_READY		1	/* check key ready */
#define _NKEYBRD_READY		0x11	/* check key ready - enhanced */
#define _KEYBRD_SHIFTSTATUS	2	/* get shift status */
#define _NKEYBRD_SHIFTSTATUS	0x12	/* get shift status - enhanced */


/* cmd values for _bios_printer() */

#define _PRINTER_WRITE	0	/* send abyte to printer */
#define _PRINTER_INIT	1	/* initialize printer */
#define _PRINTER_STATUS	2	/* read printer status */

/* cmd values for _bios_serialcom() */

#define _COM_INIT	0	/* set communication parms to abyte */
#define _COM_SEND	1	/* send abyte to port */
#define _COM_RECEIVE	2	/* read character from port */
#define _COM_STATUS	3	/* get status of port */

/* abyte values for _COM_INIT cmd of _bios_serialcom() */

#define _COM_CHR7	0x02	/* 7 data bits */
#define _COM_CHR8	0x03	/* 8 data bits */
#define _COM_STOP1	0x00	/* 1 stop bit */
#define _COM_STOP2	0x04	/* 2 stop bits */
#define _COM_NOPARITY	0x00	/* no parity */
#define _COM_EVENPARITY	0x18	/* even parity */
#define _COM_ODDPARITY	0x08	/* odd parity */
#define _COM_110	0x00	/* 110 baud */
#define _COM_150	0x20	/* 150 baud */
#define _COM_300	0x40	/* 300 baud */
#define _COM_600	0x60	/* 600 baud */
#define _COM_1200	0x80	/* 1200 baud */
#define _COM_2400	0xa0	/* 2400 baud */
#define _COM_4800	0xc0	/* 4800 baud */
#define _COM_9600	0xe0	/* 9600 baud */

/* Macros for MSC functions */

#define _bios_equiplist()	(unsigned)biosequip()
#define _bios_keybrd(cmd)	(unsigned)bioskey((int)(cmd))
#define _bios_memsize()		(unsigned)biosmemory()
#define _bios_printer(cmd,port,data) \
  (unsigned)biosprint((int)(cmd),(int)(data),(int)(port))
#define _bios_serialcom(cmd,port,data) \
  (unsigned)bioscom((int)(cmd),(int)(data),(int)(port))

#endif	/* __MSC */

#endif  /* __BIOS_H */
