#include "types.h"
#include <unistd.h>

int
main(int argc, char *argv[])
{
  if(argc != 3){
    _fdprintf(2, "Usage: ln old new\n");
    return 1;
  }
  if(link(argv[1], argv[2]) < 0)
    _fdprintf(2, "link %s %s: failed\n", argv[1], argv[2]);
  return 0;
}
