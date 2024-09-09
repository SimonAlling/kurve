/*  dos.h

    Defines structs, unions, macros, and functions for dealing
    with MSDOS and the Intel iAPX86 microprocessor family.

    Copyright (c) Borland International 1987,1988,1990,1991
    All Rights Reserved.
*/
#ifndef __DOS_H
#define __DOS_H

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

#ifndef __DLL__

/* Variables */
extern  int const _Cdecl _8087;
extern  int       _Cdecl _argc;
extern  char    **_Cdecl _argv;
extern  char    **_Cdecl  environ;

extern  int _Cdecl _doserrno;

extern  unsigned      _Cdecl _heaplen;
extern  unsigned char _Cdecl _osmajor;
extern  unsigned char _Cdecl _osminor;
extern  unsigned      _Cdecl _psp;
extern  unsigned      _Cdecl _stklen;
extern  unsigned      _Cdecl _fpstklen;
extern  unsigned      _Cdecl _version;

#endif  /* __DLL__*/


#define FA_NORMAL   0x00        /* Normal file, no attributes */
#define FA_RDONLY   0x01        /* Read only attribute */
#define FA_HIDDEN   0x02        /* Hidden file */
#define FA_SYSTEM   0x04        /* System file */
#define FA_LABEL    0x08        /* Volume label */
#define FA_DIREC    0x10        /* Directory */
#define FA_ARCH     0x20        /* Archive */

#define NFDS    20          /* Maximum number of fds */

struct  fcb {
    char    fcb_drive;      /* 0 = default, 1 = A, 2 = B */
    char    fcb_name[8];    /* File name */
    char    fcb_ext[3];     /* File extension */
    short   fcb_curblk;     /* Current block number */
    short   fcb_recsize;    /* Logical record size in bytes */
    long    fcb_filsize;    /* File size in bytes */
    short   fcb_date;       /* Date file was last written */
    char    fcb_resv[10];   /* Reserved for DOS */
    char    fcb_currec;     /* Current record in block */
    long    fcb_random;     /* Random record number */
};

struct  xfcb    {
    char        xfcb_flag;  /* Contains 0xff to indicate xfcb */
    char        xfcb_resv[5];/* Reserved for DOS */
    char        xfcb_attr;  /* Search attribute */
    struct  fcb xfcb_fcb;   /* The standard fcb */
};

struct  COUNTRY {
    int co_date;
    char    co_curr[5];
    char    co_thsep[2];
    char    co_desep[2];
    char    co_dtsep[2];
    char    co_tmsep[2];
    char    co_currstyle;
    char    co_digits;
    char    co_time;
    long    co_case;
    char    co_dasep[2];
    char    co_fill[10];
};

#if defined(__MSC) && !defined(__cplusplus)
struct  DOSERROR {
        int     exterror;
        char    class;
        char    action;
        char    locus;
};
#else
struct  DOSERROR {
        int     de_exterror;
        char    de_class;
        char    de_action;
        char    de_locus;
};
#endif	/* __MSC and not C++ */

struct  dfree   {
    unsigned df_avail;
    unsigned df_total;
    unsigned df_bsec;
    unsigned df_sclus;
};

struct  fatinfo {
    char    fi_sclus;
    char    fi_fatid;
    int fi_nclus;
    int fi_bysec;
};

struct  devhdr  {
    long        dh_next;        /* Next device pointer */
    short       dh_attr;        /* Attributes */
    unsigned short  dh_strat;   /* Driver strategy routine */
    unsigned short  dh_inter;   /* Driver interrupt routine */
    char        dh_name[8];     /* Device name */
};

struct  time    {
    unsigned char   ti_min;     /* Minutes */
    unsigned char   ti_hour;    /* Hours */
    unsigned char   ti_hund;    /* Hundredths of seconds */
    unsigned char   ti_sec;     /* Seconds */
};

struct  date    {
    int     da_year;        /* Year - 1980 */
    char        da_day;     /* Day of the month */
    char        da_mon;     /* Month (1 = Jan) */
};

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

typedef struct {
    char    ds_drive;          /* do not change    */
    char    ds_pattern [13];   /*  these fields,       */
    char    ds_reserved [7];   /*   Microsoft reserved */
    char    ds_attrib;
    short   ds_time;
    short   ds_date;
    long    ds_size;
    char    ds_nameZ [13];     /* result of the search, asciiz */
}   dosSearchInfo;  /* used with DOS functions 4E, 4F   */


#ifdef  __MSC
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
#endif	/* _FFBLK_DEF */
#endif  /* __MSC */

#ifdef __cplusplus
extern "C" {
#endif

#if !defined( _Windows )
int         _Cdecl absread( int __drive, int __nsects, long __lsect,
                            void *__buffer );
int         _Cdecl abswrite( int __drive, int __nsects, long __lsect,
                             void *__buffer );
int         _Cdecl allocmem( unsigned __size, unsigned _FAR *__segp );
#endif

int         _CType bdos( int __dosfun, unsigned __dosdx, unsigned __dosal );
int         _Cdecl bdosptr( int __dosfun, void _FAR *__argument,
                            unsigned __dosal );
struct COUNTRY _FAR *_Cdecl country( int __xcode, struct COUNTRY _FAR *__cp);
void        _Cdecl ctrlbrk( int _Cdecl( *handler )( void ));

#if !defined( _Windows )
void        _Cdecl delay( unsigned __milliseconds );
#endif

void        _Cdecl disable( void );
int         _Cdecl dosexterr( struct DOSERROR _FAR *__eblkp );
long        _Cdecl dostounix( struct date _FAR *__d, struct time _FAR *__t );
void            __emit__( );
void        _Cdecl enable( void );

#if !defined( _Windows )
int         _Cdecl freemem( unsigned __segx );
#endif

int         _Cdecl getcbrk( void );
void        _CType getdate( struct date _FAR *__datep );
void        _Cdecl getdfree( unsigned char __drive,
                             struct dfree _FAR *__dtable );
void        _Cdecl getfat( unsigned char __drive,
                           struct fatinfo _FAR *__dtable );
void        _Cdecl getfatd( struct fatinfo _FAR *__dtable );
unsigned    _Cdecl getpsp( void );
int         _Cdecl getswitchar( void );
void        _CType gettime( struct time _FAR *__timep );
int         _Cdecl getverify( void );

#if !defined( _Windows )
void        _Cdecl harderr( int _Cdecl( *handler )( ) );
void        _Cdecl hardresume( int __axret );
void        _Cdecl hardretn( int __retn );
#endif

int         _Cdecl inport( int __portid );
#ifndef _PORT_DEFS
unsigned char _Cdecl inportb( int __portid );
#endif
int         _Cdecl int86( int __intno,
                          union REGS _FAR *__inregs,
                          union REGS _FAR *__outregs );
int         _Cdecl int86x( int __intno,
                           union REGS _FAR *__inregs,
                           union REGS _FAR *__outregs,
                           struct SREGS _FAR *__segregs );
int         _Cdecl intdos( union REGS _FAR *__inregs,
                           union REGS _FAR *__outregs );
int         _Cdecl intdosx( union REGS _FAR *__inregs,
                            union REGS _FAR *__outregs,
                            struct SREGS _FAR *__segregs );
void        _Cdecl intr( int __intno, struct REGPACK _FAR *__preg );

#if !defined( _Windows )
void        _Cdecl keep( unsigned char __status, unsigned __size );
void        _Cdecl nosound( void );
#endif

void        _Cdecl outport( int __portid, int __value );
#ifndef _PORT_DEFS
void        _Cdecl outportb( int __portid, unsigned char __value );
#endif
char _FAR * _Cdecl parsfnm( const char _FAR *__cmdline,
                            struct fcb _FAR *__fcb, int __opt );
int         _Cdecl peek( unsigned __segment, unsigned __offset );
char        _Cdecl peekb( unsigned __segment, unsigned __offset );
void        _Cdecl poke( unsigned __segment, unsigned __offset, int __value);
void        _Cdecl pokeb( unsigned __segment,
                          unsigned __offset, char __value );

#if !defined( _Windows )
int         _Cdecl randbrd( struct fcb _FAR *__fcb, int __rcnt );
int         _Cdecl randbwr( struct fcb _FAR *__fcb, int __rcnt );
#endif

void        _Cdecl segread( struct SREGS _FAR *__segp );

#if !defined( _Windows )
int         _Cdecl setblock( unsigned __segx, unsigned __newsize );
#endif

int         _Cdecl setcbrk( int __cbrkvalue );
void        _Cdecl setdate( struct date _FAR *__datep );
void        _Cdecl setswitchar( char __ch );
void        _Cdecl settime( struct time _FAR *__timep );
void        _Cdecl setverify( int __value );

#if !defined( _Windows )
void        _Cdecl sleep( unsigned __seconds );
void        _Cdecl sound( unsigned __frequency );
#endif

void        _Cdecl unixtodos( long __time, struct date _FAR *__d,
                              struct time _FAR *__t );
int         _CType unlink( const char _FAR *__path );

    /* These are in-line functions.  These prototypes just clean up
       some syntax checks and code generation.
     */

void        _Cdecl          __cli__( void );
void        _Cdecl          __sti__( void );
void        _Cdecl          __int__( int __interruptnum );

#define disable( ) __emit__( (char )( 0xfa ) )
#define enable( )  __emit__( (char )( 0xfb ) )

#define geninterrupt( i ) __int__( i )      /* Interrupt instruction */

#ifndef _PORT_DEFS
#define _PORT_DEFS

unsigned char _Cdecl    __inportb__( int __portid );
unsigned int _Cdecl     __inportw__( int __portid );
void        _Cdecl      __outportb__( int __portid, unsigned char __value );
void        _Cdecl      __outportw__( int __portid, unsigned int __value );

#define inportb         __inportb__
#define inportw         __inportw__
#define outportb        __outportb__
#define outportw        __outportw__

/* some other compilers use inp, outp for inportb, outportb */
#define inp( portid ) inportb( portid )
#define outp( portid,v )  outportb( portid,v )
#define inpw( portid ) inportw( portid )
#define outpw( portid,v )  outportw( portid,v )

#endif	/* _PORT_DEFS */

#if !__STDC__

extern  unsigned    _Cdecl  _ovrbuffer;
int cdecl far _OvrInitEms( unsigned __emsHandle, unsigned __emsFirst,
                           unsigned __emsPages );
int cdecl far _OvrInitExt( unsigned long __extStart,
                           unsigned long __extLength );

char far *cdecl getdta( void );
void      cdecl setdta( char far *__dta );

#define MK_FP( seg,ofs )( (void _seg * )( seg ) +( void near * )( ofs ))
#define FP_SEG( fp )( (unsigned )( void _seg * )( void far * )( fp ))
#define FP_OFF( fp )( (unsigned )( fp ))

#ifdef __cplusplus
void    interrupt( far * _CType getvect( int __interruptno ))( ... );
void        _CType setvect( int __interruptno,
                            void interrupt( far *__isr )( ... ));
int  inline _Cdecl peek( unsigned __segment, unsigned __offset )  
                  { return( *( (int  far* )MK_FP( __segment, __offset )) ); }
char inline _Cdecl peekb( unsigned __segment, unsigned __offset ) 
                  { return( *( (char far* )MK_FP( __segment, __offset )) ); }
void inline _Cdecl poke( unsigned __segment, unsigned __offset, int __value )  
               {( *( (int  far* )MK_FP( __segment, __offset )) = __value ); }
void inline _Cdecl pokeb( unsigned __segment, unsigned __offset, char __value )   
               {( *( (char far* )MK_FP( __segment, __offset )) = __value ); }
#else
void    interrupt( far * _CType getvect( int __interruptno ))( );
void        _CType setvect( int __interruptno,
                            void interrupt( far *__isr )( ) );
#define peek( a,b )( *( (int  far* )MK_FP( (a ),( b )) ))
#define peekb( a,b )( *( (char far* )MK_FP( (a ),( b )) ))
#define poke( a,b,c )( *( (int  far* )MK_FP( (a ),( b )) ) =( int )( c ))
#define pokeb( a,b,c )( *( (char far* )MK_FP( (a ),( b )) ) =( char )( c ))
#endif

#endif

#ifdef __MSC

/* Prototypes needed for MSC _dos_??? macros */
int  _CType findfirst( const char _FAR *__path,
                              struct ffblk _FAR *__ffblk, 
                              int __attrib );
int  _CType findnext( struct ffblk _FAR *__ffblk );

#endif	/* __MSC */

#ifdef __cplusplus
}
#endif

#ifdef __MSC

/* File attributes */

#define _A_NORMAL   0x00        /* Normal file, no attributes */
#define _A_RDONLY   0x01        /* Read only attribute */
#define _A_HIDDEN   0x02        /* Hidden file */
#define _A_SYSTEM   0x04        /* System file */
#define _A_VOLID    0x08        /* Volume label */
#define _A_SUBDIR   0x10        /* Directory */
#define _A_ARCH     0x20        /* Archive */

/* Structures */

struct find_t {
    char     reserved[21];	/* Microsoft reserved - do not change */
    char     attrib;		/* attribute byte for matched file */
    unsigned wr_time;		/* time of last write to file */
    unsigned wr_date;		/* date of last write to file */
    long     size;		/* size of file */
    char     name[13];		/* asciiz name of matched file */
};

/* Variables */

#define _osversion _version

/* Macros for MSC functions */

#define _disable()		disable()
#define _dos_findfirst(path,attrib,fileinfo) \
  (unsigned)findfirst(path,(struct ffblk _FAR *)fileinfo,attrib)
#define _dos_findnext(fileinfo) (unsigned)findnext((struct ffblk *)fileinfo)
#define _enable()		enable()
#endif	/* __MSC */

#endif
