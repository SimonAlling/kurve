/* Program CALLTEST */
/* Copyright (c) 1990, Borland International */
#include <stdio.h>

main()
{
  c();
  b2();
  b1();
  a();
}

a()
{
  int i;

  for (i=0; i<100; i++)
    b2();
  b1();
}

b1()
{
  int i;

  for (i=0; i<33; i++)
    c();
}

b2()
{
  int i;

  for (i=0; i<77; i++)
    c();
}

c()
{
  int i;

  for (i=0; i<3; i++)
    ;
}
