/*  malloc.h

  memory management functions and variables.

  Copyright (c) Borland International 1991
  All Rights Reserved.
*/

#include <alloc.h>

#if (sizeof(void *) != 4)

/* Near heap functions currently allowed only in small data models */

#define _nmalloc(size)		malloc(size)
#define _nfree(block)		free(block)
#define _nrealloc(block,size)	realloc(block,size)
#define _ncalloc(num,size)	calloc(num,size)
#define _nheapmin()		0
#define _memavl()		coreleft()

#endif	/* sizeof(void *) != 4 */

/* Model-independent functions */

#define _fmalloc(size)		farmalloc((unsigned long)(size))
#define _ffree(block)		farfree(block)
#define _frealloc(block,size)	farrealloc(block,(unsigned long)(size))
#define _fcalloc(num,size)	farcalloc((unsigned long)(num),(unsigned long)(size))
#define halloc(num,size)	(void huge *)farmalloc((unsigned long)(num)*(size))
#define hfree(block)		farfree((void far *)(block))
#define _heapmin()		0
#define _fheapmin()		0
