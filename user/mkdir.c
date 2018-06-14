#include "types.h"
#include <sys/stat.h>
#include <unistd.h>

int
main(int argc, char *argv[])
{
  int i;

  if(argc < 2){
    _fdprintf(2, "Usage: mkdir files...\n");
    return 1;
  }

  for(i = 1; i < argc; i++){
    if(mkdir(argv[i]) < 0){
      _fdprintf(2, "mkdir: %s failed to create\n", argv[i]);
      return 1;
    }
  }

  return 0;
}
