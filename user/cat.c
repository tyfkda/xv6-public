#include "types.h"
#include <unistd.h>

char buf[512];

int
cat(int fd)
{
  int n;

  while((n = read(fd, buf, sizeof(buf))) > 0) {
    if (write(1, buf, n) != n) {
      _fdprintf(1, "cat: write error\n");
      return 1;
    }
  }
  if(n < 0){
    _fdprintf(1, "cat: read error\n");
    return 1;
  }
  return 0;
}

int
main(int argc, char *argv[])
{
  int fd, i;
  int result;

  if(argc <= 1){
    return cat(0);
  }

  for(i = 1; i < argc; i++){
    if((fd = open(argv[i], 0)) < 0){
      _fdprintf(1, "cat: cannot open %s\n", argv[i]);
      return 1;
    }
    result = cat(fd);
    close(fd);
  }
  return result;
}
