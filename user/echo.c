#include "types.h"
#include <unistd.h>

int
main(int argc, char *argv[])
{
  int i;

  for(i = 1; i < argc; i++)
    _fdprintf(1, "%s%s", argv[i], i+1 < argc ? " " : "\n");
  return 0;
}
