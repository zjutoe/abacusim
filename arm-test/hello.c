#include <stdio.h>

int data_process()
{
  int i, sum;
  sum = 0;
  for (i=0; i<100; i++) {
    sum += i;
  }
  return sum;
}

int main(int argc, char * argv[])
{
  printf("%d\n", data_process());
  return 0;
}
