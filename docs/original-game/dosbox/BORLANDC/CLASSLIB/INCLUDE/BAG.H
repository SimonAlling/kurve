// Borland C++ - (C) Copyright 1991 by Borland International

// Contents ----------------------------------------------------------------
//
//      Bag
//      Bag::Bag
//
// Description
//
// 	Defines the class Bag.  A bag is a collection of objects which
//      can contain more than one of the same object.
//
// End ---------------------------------------------------------------------

// Interface Dependencies ---------------------------------------------------

#ifndef __BAG_H
#define __BAG_H

#ifndef __IOSTREAM_H
#include <iostream.h>
#define __IOSTREAM_H
#endif

#ifndef __CLSTYPES_H
#include "clstypes.h"
#endif

#ifndef __RESOURCE_H
#include "resource.h"
#endif

#ifndef __OBJECT_H
#include "object.h"
#endif

#ifndef __HASHTBL_H
#include "hashtbl.h"
#endif

// End Interface Dependencies ------------------------------------------------


// Class //

class Bag:  public HashTable
{
public:
            Bag( sizeType bagSize = DEFAULT_BAG_SIZE ) : HashTable( bagSize ) {}
    virtual ~Bag();

    virtual classType       isA() const;
    virtual char           *nameOf() const;
};

// Description -------------------------------------------------------------
//
// 	Defines the class Bag.  A bag is a collection of objects which
//      can contain more than one of the same object.
//      
// Constructors
//
//      Bag( sizeType )
//
//      Constructs a bag of the given size.
//
// Public Members
//
// 	isA
//
// 	Inherited from Object.
//
// 	nameOf
//
// 	Inherited from Object.
// 	
// Inherited Members
//
//      add
//
//      Inherited from HashTable
//
//      destroy
//
//      Inherited from HashTable
//
// 	detach
//
//      Inherited from HashTable
//
//      hasMember
//
//      Inherited from HashTable
//
// 	isEmpty
//
//      Inherited from HashTable
//
//      firstThat
//
//      Inherited from HashTable
//
//      lastThat
//
//      Inherited from HashTable
//
// 	hashValue
//
// 	Inherited from Object.
//
// 	operator ==
//
// 	Inherited from Object.
//
// 	printOn
//
// 	Inherited from Object.
//
// End ---------------------------------------------------------------------


#endif // ifndef __BAG_H //

