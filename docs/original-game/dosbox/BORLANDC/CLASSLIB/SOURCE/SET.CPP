// Borland C++ - (C) Copyright 1991 by Borland International


// Contents ----------------------------------------------------------------
//
//
// Description
//
//      Implementation of member functions for class Set.
//
// End ---------------------------------------------------------------------

// Interface Dependencies ---------------------------------------------------

#ifndef __CLSTYPES_H
#include <clstypes.h>
#endif

#ifndef __SET_H
#include <set.h>
#endif

// End Interface Dependencies ------------------------------------------------

// Implementation Dependencies ----------------------------------------------
// End Implementation Dependencies -------------------------------------------


// Member Function //

Set::~Set()

// Summary -----------------------------------------------------------------
//
//      Destructor for a Set object.
//
//		We don't do anything here, because the destructor for HashTable
//		will take care of destroying the contained objects.
//
// End ---------------------------------------------------------------------
{
}
// End Destructor //


// Member Function //

classType Set::isA() const

// Summary -----------------------------------------------------------------
//
//      Returns the class type of a set.
//
// End ---------------------------------------------------------------------
{
    return setClass;
}
// End Member Function Set::isA //


// Member Function //

char *Set::nameOf() const

// Summary -----------------------------------------------------------------
//
//      Returns a pointer to the character string "Set".
//
// End ---------------------------------------------------------------------
{
    return "Set";
}
// End Member Function Set::isA //


// Member Function //

void Set::add( Object& objectToAdd )

// Summary -----------------------------------------------------------------
//
//      Adds an object to the set.  Sets may have only one copy of an object
//      in the set at any time.
//
// Parameters
//
//      objectToAdd
//
// End ---------------------------------------------------------------------
{
	if ( !(Bag::hasMember( objectToAdd )) )
    {
		Bag::add( objectToAdd );
    }
}
// End Member Function Set::add //



