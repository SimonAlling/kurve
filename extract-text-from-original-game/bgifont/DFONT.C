
/*

  DFONT - Dump Font file program

  Copyright (c)  1988,89 Borland International

*/


#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

#include "font.h"

FILE	*ffile, *OFile;

char	       *Font;			/* Pointer to font storage	*/
char		Prefix[Prefix_Size];	/* File Prefix Holder		*/
HEADER		Header; 		/* File Data Header		*/

int		Offset[256];		/* Font data offsets		*/
char		Char_Width[256];	/* Character Width Table	*/
int		Stroke_Count[256];	/* Stroke Count Table		*/
STROKE	       *Strokes[256];		/* Stroke Data Base		*/

char  *OpName[] = {
  "End    ",
  "Do Scan",
  "Move To",
  "Line To"
  };

char help[] = "Dump Font File Copyright (c) 1987,1989 Borland International, Inc.\n\n"
	      "Usage is:  DFONT [font file name] \n";



void dvalue( char *str, unsigned int value );
int unpack( char *buf, int index, STROKE **new );
int decode( unsigned int *iptr, int *x, int *y );

void main( int argc, char **argv )
{
  long length, current, base;
  char *cptr;
  FHEADER *fptr;
  int last_chr, i, j;
  STROKE *sptr;

  if( argc < 2 || argc > 3 ){		/* Invalid 3 of arguments	*/
    fprintf( stderr, help);
    exit( 1 );				/* Exit the program		*/
    }

  ffile = fopen( argv[1], "rb" );       /* Open the input font file     */
  if( NULL == ffile ){			/* Can not open font file	*/
    fprintf( stderr, "\nFontDisplay: Can not open input file %s.\n", argv[1] );
    exit( 1 );				/* Exit the program		*/
    }

  if( 3 == argc ){			/* Is there an output file?	*/
    OFile = fopen( argv[2], "rb" );       /* Open the input font file     */
    if( NULL == OFile ){		  /* Can not open font file	  */
      fprintf( stderr, "\nFontDisplay: Can not open output file %s.\n", argv[2] );
      exit( 1 );			  /* Exit the program		  */
      }
    }
  else	OFile = stdout; 		/* Write it to screen		*/

/*	Read in and display the file prefix record.			*/

  base = ftell( ffile );		/* Remember the address of table*/
  fread(Prefix, Prefix_Size, 1, ffile); /* Read in the file prefix	*/

  fprintf( stdout, "Prefix Record   File Base: %lx\n\n", base );

  cptr = Prefix;			/* Begin at base of prefix	*/
  while( 0x1a != *cptr ) ++cptr;	/* Move to EOF in prefix	*/
  *cptr = '\0';                         /* Cut prefix at EOF            */
  fptr = (FHEADER *)(cptr+1);		/* Point at Font Header Record	*/

  fprintf( stdout, "Text:\n\n%s\n", Prefix );
  dvalue( "Prefix Size", fptr->header_size );
  fprintf( stdout, "Prefix Name: %-.4s\n", fptr->font_name );
  dvalue( "Font Size", fptr->font_size );
  fprintf( stdout, "Revision:    %d.%d\n", fptr->font_major, fptr->font_minor );
  fprintf( stdout, "BGI Version: %d.%d\n", fptr->min_major, fptr->min_minor );

/*	Read in and display the font header record.			*/

  base = ftell( ffile );		/* Remember the address of table*/
  fread(&Header, sizeof(HEADER), 1, ffile);  /* Read in the file prefix */

  fprintf( stdout, "\nHeader Record   File Base: %lx\n\n", base );

  fprintf( stdout, "Signature:    %c\n", Header.sig );
  fprintf( stdout, "# Characters: %d.\n", Header.nchrs );
  fprintf( stdout, "First Char:   %02x\n", Header.first );
  fprintf( stdout, "Definition Offset:   %04x\n", Header.cdefs );
  fprintf( stdout, "Scanable Font:       %s\n", Header.scan_flag ? "Yes" : "No" );
  fprintf( stdout, "Origin to Cap  Height: %d\n", Header.org_to_cap );
  fprintf( stdout, "Origin to Base Height: %d\n", Header.org_to_base );
  fprintf( stdout, "Origin to Dec  Height: %d\n", Header.org_to_dec );
  fprintf( stdout, "Header Name: %-.4s\n\n", Header.fntname );

/*	Read file offset table into memory.				*/

  base = ftell( ffile );		/* Remember the address of table*/
  fread( &Offset[Header.first], Header.nchrs, sizeof(int), ffile );

/*	Display the offset table					*/

  last_chr = Header.first + Header.nchrs;

  fprintf( stdout, "Offset Table    File Base: %lx\n", base );

  for( i=Header.first ; i<last_chr ; ++i ){
    if( !((i+3) % 4) ) fprintf( stdout, "\n" );
    fprintf( stdout, " %c (%02x) : %04x ",
		    isprint(i) ? i : '.', i, Offset[i] );
    }

/*	Load the character width table into memory.			*/

  base = ftell( ffile );
  fread( &Char_Width[Header.first], Header.nchrs, sizeof(char), ffile );

/*	Determine the length of the stroke database.			*/

  current = ftell( ffile );		/* Current file location	*/
  fseek( ffile, 0, SEEK_END );		/* Go to the end of the file	*/
  length = ftell( ffile );		/* Get the file length		*/
  fseek( ffile, current, SEEK_SET );	/* Restore old file location	*/

/*	Load the stroke database.					*/

  Font = malloc( (int) length );	/* Create space for font data	*/
  if( NULL == Font ){			/* Was there enough memory	*/
    fprintf( stderr, "FontDisplay: Not Enough Memory to load Font.\n\n" );
    exit( 1 );
    }

  fread( Font, (int)length, 1 , ffile ); /* Load the stroke data	*/

/*	Font is now loaded, display the internal data			*/

  fprintf( stdout, "\n\nWidth Table File Base:  %lx\n", base );
  fprintf( stdout, "Stroke Table File Base: %lx\n", current );
  fprintf( stdout, "\n\nStroke Information\n\n" );

  for( i=Header.first ; i<last_chr ; ++i ){
    if( !Offset[i] && i!=Header.first ) continue;
    printf( "Char %02x (%c)    ", i, i );
    Stroke_Count[i] = unpack( Font, Offset[i], &Strokes[i] );
    printf( "Offset: %04x   Width: %-5d   Stroke Count: %d\n",
      Offset[i], Char_Width[i], Stroke_Count[i] );
    sptr = Strokes[i];
    for( j=0 ; j<Stroke_Count[i] ; ++j, ++sptr ){
      printf( "  %3d : OpCode: %s (%d)   X: %4d   Y: %4d\n",
	j, OpName[sptr->opcode], sptr->opcode, sptr->x, sptr->y );
      }
    }

}

void dvalue( char *str, unsigned int value )
{

  fprintf( OFile, "%-50s  %04xh  (%6u. )\n", str, value, value );

}

/*	UNPACK: This routine decodes the file format into a more	*/
/*	reasonable internal structure					*/

int unpack( char *buf, int index, STROKE **new )	/* FUNCTION	*/
{
  unsigned int *pb;
  STROKE *po;
  int	  num_ops = 0;
  int	  jx, jy, opcode, i, opc;

  pb = (unsigned int *)(buf + index);	/* Reset pointer to buffer	*/

  while( FOREVER ){			/* For each byte in buffer	*/
    num_ops += 1;			/* Count the operation		*/
    opcode = decode( pb++, &jx, &jy );	/* Decode the data record	*/
    if( opcode == END_OF_CHAR ) break;	/* Exit loop at end of char	*/
    }

  po = *new = calloc( num_ops, sizeof(STROKE) );

  if( !po ){				/* Out of memory loading font	*/
    fprintf( stderr, "DMPFNT: Out of memory decoding font\n" );
    exit( 100 );
    }

  pb = (unsigned int *)(buf + index);	/* Reset pointer to buffer	*/

  for( i=0 ; i<num_ops ; ++i ){ 	/* For each opcode in buffer	*/
    opc = decode(pb++, &po->x, &po->y); /* Decode the data field	*/
    po->opcode = opc;			/* Save the opcode		*/
    po++;
    }

  return( num_ops );			/* return OPS count		*/

}


/*	DECODE: This routine decodes a single word in file to a 	*/
/*	stroke record.							*/

int decode( unsigned int *iptr, int *x, int *y )  /* FUNCTION		*/
{
  struct DECODE {
    signed   int xoff  : 7;
    unsigned int flag1 : 1;
    signed   int yoff  : 7;
    unsigned int flag2 : 1;
  } cword;

  cword = *(struct DECODE *)iptr;

  *x = cword.xoff;
  *y = cword.yoff;

  return( (cword.flag1 << 1) + cword.flag2 );

}

