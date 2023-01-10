
/*

  FONT.H - Font information header file

  Copyright (c) 1988,89 Borland International

*/


#define FOREVER 1

#define TRUE	1
#define FALSE	0

#define Prefix_Size	0x80
#define Major_Version	1
#define Minor_Version	0
#define SIGNATURE	'+'

enum OP_CODES {
  END_OF_CHAR	=  0,
  DO_SCAN	=  1,
  MOVE		=  2,
  DRAW		=  3
  };

typedef struct {
  char	  sig;			/* SIGNATURE byte			*/
  int	  nchrs;		/* number of characters in file 	*/
  char	  mystery;		/* Currently Undefined			*/
  char	  first;		/* first character in file		*/
  int	  cdefs;		/* offset to char definitions		*/
  char	  scan_flag;		/* True if set is scanable		*/
  char	  org_to_cap;		/* Height from origin to top of capitol */
  char	  org_to_base;		/* Height from origin to baseline	*/
  char	  org_to_dec;		/* Height from origin to bot of decender*/
  char	  fntname[4];		/* Four character name of font		*/
  char	  unused;		/* Currently undefined			*/
  } HEADER;

typedef struct {
  char	  opcode;		/* Stroke opcode byte			*/
  int	  x;			/* Relative offset x direction		*/
  int	  y;			/* Relative offset y direction		*/
  } STROKE;

typedef struct {
  unsigned int	header_size;		/* Version 2.0 Header Format	*/
  unsigned char font_name[4];		/* Font Internal Name		*/
  unsigned int	font_size;		/* Size in byte of file 	*/
  unsigned char font_major, font_minor; /* Driver Version Information	*/
  unsigned char min_major, min_minor;	/* BGI Revision Information	*/
} FHEADER;

