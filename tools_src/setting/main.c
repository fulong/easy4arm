#include <stdio.h>
#include <stdlib.h>
int main()
{
	int i = 0xC00000;
	void* ii = (void*) &i;
	float* temp1 = (float*) ii;
	unsigned int* temp2 = (unsigned int*) ii;
	unsigned char* char1 = (unsigned char*) ii;
	printf( "float is %f\n" , i);
	printf( "temp1 is %f\n" , *temp1);
	printf( "the value of temp2_x is %x\n" , *temp2);
	printf( "the value of temp2_d is %d\n" , *temp2);
	printf( "temp1 adress is %p\n" , temp1);
	printf( "temp2 adress is %p\n" , temp2);
	printf( "ii adress is %p\n" , ii);
	printf( "i adress is %p\n" , &i);
	printf( "char1 adress is %p\n" , char1);
	printf( "one byte adress is %x\n" , *(char1 + 0));
	printf( "two byte adress is %x\n" , *(char1 + 1));
	printf( "three byte adress is %x\n" , *(char1 + 2));
	printf( "four byte adress is %x\n" , *(char1 + 3));
	printf( "the size of float adress is %x\n" , sizeof(i));
	exit( 0);
}
