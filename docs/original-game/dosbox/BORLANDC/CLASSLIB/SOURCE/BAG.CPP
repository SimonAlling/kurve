// Borland C++ - (C) Copyright 1991 by Borland International

// Contents ----------------------------------------------------------------
//
//
// Description
//
//      Implementation of member functions for class Bag.
//
// End ---------------------------------------------------------------------

// Interface Dependencies ---------------------------------------------------

#ifndef __CLSTYPES_H
#include <clstypes.h>
#endif

#ifndef __BAG_H
#include <bag.h>
#endif

// End Interface Dependencies ------------------------------------------------

// Implementation Dependencies ----------------------------------------------
// End Implementation Dependencies -------------------------------------------


// Member Function //

Bag::~Bag()

// Summary -----------------------------------------------------------------
//
//      Destructor for a Bag object.
//
//		We don't do anything here, because the destructor for Container
//		will take care of destroying the contained objects.
//
// End ---------------------------------------------------------------------
{
}
// End Destructor //


// Member Function //

classType Bag::isA() const

// Summary -----------------------------------------------------------------
//
//      Returns the class type of a bag.
//
// End ---------------------------------------------------------------------
{
    return bagClass;
}
// End Member Function Bag::isA //


// Member Function //

char *Bag::nameOf() const

// Summary -----------------------------------------------------------------
//
//      Returns a pointer to the character string "Bag".
//
// End ---------------------------------------------------------------------
{
    return "Bag";
}
// End Member Function Bag::nameOf //

