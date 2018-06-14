#include "types.h"
#include <unistd.h>

int
main(int argc, char *argv[])
{
  int i;

  if(argc < 2){
    _fdprintf(2, "Usage: rm files...\n");
    return 1;
  }

  for(i = 1; i < argc; i++){
    if(unlink(argv[i]) < 0){
      _fdprintf(2, "rm: %s failed to delete\n", argv[i]);
      return 1;
    }
  }

  return 0;
}
