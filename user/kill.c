#include "types.h"
#include <stdlib.h>
#include <unistd.h>

int
main(int argc, char **argv)
{
  int i;

  if(argc < 2){
    _fdprintf(2, "usage: kill pid...\n");
    return 1;
  }
  for(i=1; i<argc; i++)
    kill(atoi(argv[i]));
  return 0;
}
