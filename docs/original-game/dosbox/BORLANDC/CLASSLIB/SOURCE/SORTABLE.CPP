// Borland C++ - (C) Copyright 1991 by Borland International


// Contents ----------------------------------------------------------------
//
//      Sortable::~Sortable
//      Sortable::isSortable()
//
// Description
//
//      Implementation of the class Sortable member functions
//
// End ---------------------------------------------------------------------

// Interface Dependencies ---------------------------------------------------

#ifndef __CLSTYPES_H
#include <clstypes.h>
#endif

#ifndef __OBJECT_H
#include <object.h>
#endif

#ifndef __SORTABLE_H
#include <sortable.h>
#endif

// End Interface Dependencies ------------------------------------------------


// Implementation Dependencies ----------------------------------------------
// End Implementation Dependencies -------------------------------------------


// Member Function //

Sortable::~Sortable()

// Summary -----------------------------------------------------------------
//
//      Destructor for a Sortable object.
//
// End ---------------------------------------------------------------------
{
}
// End Destructor //


// Member Function //

int Sortable::isSortable() const

// Summary -----------------------------------------------------------------
//
//      indicates whether an Object is sortable
//
// Return Value
//
//      returns 1, since every object of type Sortable is sortable.
//
// End ---------------------------------------------------------------------
{
    return 1;
}
// End Member Function Sortable::isSortable //

