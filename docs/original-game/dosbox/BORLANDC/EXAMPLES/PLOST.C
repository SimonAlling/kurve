/* Copyright (c) 1990, Borland International */
#include <stdio.h>
#include <dos.h>   /* contains prototype for delay() */

main()
{
    printf("Entering main\n");
    lost_in_town();
    delay(1000);
    printf("Leaving main\n\n");
    delay(1000);
}

lost_in_town()
{
    int i;
    printf("Looking for highway...\n");
    delay(100);
    for (i=0; i<10; i++)
    {
	printf("Ask for directions\n");
	printf("Wrong turn\n\n");
	delay(1000);
    }
    printf("On the road again\n");
}
