/* Copyright (c) 1990, Borland International */
#include <stdio.h>
#include <math.h>

root(int n)
{
	return (int) sqrt((float) n);
}

prime(int n)
{
	int i;

	for (i=2; i <= root(n); i++)
		if (n % i == 0)
			return 0;
	return 1;
}

main()
{
	int i, n;

	n = 1000;
	for (i=2; i<=n; i++)
		if (prime(i))
			printf("%d\n", i);
}
