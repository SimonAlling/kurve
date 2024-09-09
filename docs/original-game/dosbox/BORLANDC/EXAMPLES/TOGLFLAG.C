// Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

/* TOGLFLAG.C
   Example of linking C++ and Turbo Assembler, and dealing with underscores.
*/

// From the Turbo Assembler Users Guide - Interfacing Turbo Assembler
//                                         with Borland C++

extern int ToggleFlag();
int Flag;
main()
{
   ToggleFlag();
}
