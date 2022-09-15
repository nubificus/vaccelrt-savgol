#include <stdio.h>


int savgol_GPU(int argc, char ** argv, double *time1, double *time2);

int main(int argc, char **argv)
{
	double time1, time2;
	savgol_GPU(argc, argv, &time1, &time2);
	return 0;
}
