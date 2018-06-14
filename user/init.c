// init: The initial user-level program

#include "types.h"
#include "fcntl.h"
#include <unistd.h>
#include <stdlib.h>

char *argv[] = { "sh", 0 };

int
main(void)
{
  int pid, wpid;

  if(open("console", O_RDWR) < 0){
    mknod("console", 1, 1);
    open("console", O_RDWR);
  }
  dup(0);  // stdout
  dup(0);  // stderr

  for(;;){
    _fdprintf(1, "init: starting sh\n");
    pid = fork();
    if(pid < 0){
      _fdprintf(1, "init: fork failed\n");
      exit(1);
    }
    if(pid == 0){
      exec("sh", argv);
      _fdprintf(1, "init: exec sh failed\n");
      exit(1);
    }
    while((wpid=wait()) >= 0 && wpid != pid)
      _fdprintf(1, "zombie!\n");
  }
}
