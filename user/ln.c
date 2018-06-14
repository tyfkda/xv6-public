#include "types.h"
#include "stat.h"
#include "user.h"

int
main(int argc, char *argv[])
{
  if(argc != 3){
    _fdprintf(2, "Usage: ln old new\n");
    exit(1);
  }
  if(link(argv[1], argv[2]) < 0)
    _fdprintf(2, "link %s %s: failed\n", argv[1], argv[2]);
  return 0;
}
