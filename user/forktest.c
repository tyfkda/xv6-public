// Test that fork fails gracefully.
// Tiny executable so that the limit can be filling the proc table.

#include "types.h"
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define N  1000

void
forktest(void)
{
  int n, pid;

  _fdprintf(1, "fork test\n");

  for(n=0; n<N; n++){
    pid = fork();
    if(pid < 0)
      break;
    if(pid == 0)
      exit(0);
  }

  if(n == N){
    _fdprintf(1, "fork claimed to work N times!\n", N);
    exit(1);
  }

  for(; n > 0; n--){
    if(wait() < 0){
      _fdprintf(1, "wait stopped early\n");
      exit(1);
    }
  }

  if(wait() != -1){
    _fdprintf(1, "wait got too many\n");
    exit(1);
  }

  _fdprintf(1, "fork test OK\n");
}

int
main(void)
{
  forktest();
  return 0;
}
