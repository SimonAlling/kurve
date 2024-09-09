/* Copyright (c) 1990, Borland International */
#include <stdio.h>
#include <dos.h>   /* contains prototype for delay() */

main()
{
    printf("Entering main\n");
    route66();
    printf("Back in main\n");
    delay(1000);
    highway80();
    printf("Back in main\n");
    delay(1000);
    printf("Leaving main\n\n");
}

route66()
{
    printf("Entering Route 66\n");
    delay(2000);
    printf("Leaving  Route 66\n");
}

highway80()
{
    printf("Entering Highway 80\n");
    delay(2000);
    printf("Leaving Highway 80\n");
}
