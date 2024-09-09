// Turbo Assembler    Copyright (c) 1988, 1991 By Borland International, Inc.

/* STRINGUP.C
   Program to demonstrate the use of StringToUpper().
   Calls StringToUpper to convert TestString to uppercase in
   UpperCaseString, then prints UpperCaseString and its length.
*/

// From the Turbo Assembler Users Guide - Interfacing Turbo Assembler
//                                         with Borland C++


#pragma inline
#include <stdio.h>

/* Function prototype for StringToUpper() */
extern unsigned int StringToUpper(
unsigned char far * DestFarString,
unsigned char far * SourceFarString);

#define MAX_STRING_LENGTH 100

char *TestString = "This Started Out As Lowercase!";

char UpperCaseString[MAX_STRING_LENGTH];

main()
{
   unsigned int StringLength;

   /* Copy an uppercase version of TestString to UpperCaseString*/
   StringLength = StringToUpper(UpperCaseString, TestString);

   /* Display the results of the conversion */
   printf("Original string:\n%s\n\n", TestString);
   printf("Uppercase string:\n%s\n\n", UpperCaseString);
   printf("Number of characters: %d\n\n", StringLength);
}

/* Function to perform high-speed translation to uppercase
   from one far string to another

   Input:
        DestFarString   - array in which to store uppercased
                          string (will be zero-terminated)
        SourceFarString - string containing characters to be
                          converted to all uppercase (must be
                          zero-terminated)

   Returns:
        The length of the source string in characters, not
        counting the terminating zero. */

unsigned int StringToUpper(unsigned char far * DestFarString,
                           unsigned char far * SourceFarString)
{
   unsigned int  CharacterCount;

   #define LOWER_CASE_A 'a'
   #define LOWER_CASE_Z 'z'
      asm ADJUST_VALUE  EQU  20h;    /* amount to subtract from lowercase 
                                        letters to make them uppercase */
      asm  cld;
      asm  push ds;                  /* save C's data segment */
      asm  lds  si,SourceFarString;  /* load far pointer to source string */
      asm  les  di,DestFarString;    /* load far pointer to destination string */
      CharacterCount = 0;            /* count of characters */
   StringToUpperLoop:
      asm  lodsb;                    /* get the next character */
      asm  cmp  al,LOWER_CASE_A;     /* if < a then it's not a lowercase letter */
      asm  jb   SaveCharacter;
      asm  cmp  al,LOWER_CASE_Z;     /* if > z then it's not a lowercase letter */
      asm  ja   SaveCharacter;
      asm  sub  al,ADJUST_VALUE;     /* it's lowercase; make it uppercase */
   SaveCharacter:
      asm  stosb;                    /* save the character */
      CharacterCount++;              /* count this character */
      asm  and  al,al;               /* is this the ending zero? */
      asm  jnz  StringToUpperLoop;   /* no, process the next character, if any */
      CharacterCount--;              /* don't count the terminating zero */
      asm  pop  ds;                  /* restore C's data segment */
      return(CharacterCount);
}
