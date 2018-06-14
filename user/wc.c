#include "types.h"
#include <string.h>
#include <unistd.h>

char buf[512];

int
wc(int fd, char *name)
{
  int i, n;
  int l, w, c, inword;

  l = w = c = 0;
  inword = 0;
  while((n = read(fd, buf, sizeof(buf))) > 0){
    for(i=0; i<n; i++){
      c++;
      if(buf[i] == '\n')
        l++;
      if(strchr(" \r\t\n\v", buf[i]))
        inword = 0;
      else if(!inword){
        w++;
        inword = 1;
      }
    }
  }
  if(n < 0){
    _fdprintf(1, "wc: read error\n");
    return 1;
  }
  _fdprintf(1, "%d %d %d %s\n", l, w, c, name);
  return 0;
}

int
main(int argc, char *argv[])
{
  int fd, i;
  int result;

  if(argc <= 1){
    return wc(0, "");
  }

  for(i = 1; i < argc; i++){
    if((fd = open(argv[i], 0)) < 0){
      _fdprintf(1, "wc: cannot open %s\n", argv[i]);
      return 1;
    }
    result = wc(fd, argv[i]);
    if (result != 0)
      break;
    close(fd);
  }
  return 0;
}
