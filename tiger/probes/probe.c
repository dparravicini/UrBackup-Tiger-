#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/xattr.h>
#include <string.h>
#include <stdlib.h>
#include "macsurf_runtime_profile.h"
int main(void) {
 char dir[]="/tmp/urbackup-tiger-probe-XXXXXX", fn[256], fork[300], buf[16]; int fd; ssize_t n;
 printf("macTLS profile classic=%d host_stubs=%d\n", MACSURF_CLASSIC_RUNTIME, MACSURF_HOST_STUB_BUILD);
 if (!mkdtemp(dir)) return 1;
 snprintf(fn,sizeof(fn),"%s/fixture",dir);
 fd=open(fn,O_WRONLY|O_CREAT|O_EXCL,0600); if(fd<0) return 2;
 if(write(fd,"data",4)!=4 || close(fd)!=0) return 3;
 snprintf(fork,sizeof(fork),"%s/..namedfork/rsrc",fn);
 fd=open(fork,O_WRONLY|O_CREAT,0600); if(fd<0) {perror("resource fork"); return 4;}
 if(write(fd,"resource",8)!=8 || close(fd)!=0) return 5;
 n=getxattr(fn,"com.apple.ResourceFork",buf,sizeof(buf),0,0);
 if(n!=8 || memcmp(buf,"resource",8)) {perror("resource fork xattr"); return 6;}
 printf("HFS+ resource fork readable through getxattr: %ld bytes\n",(long)n);
 if(unlink(fn)!=0 || rmdir(dir)!=0) return 7;
 return MACSURF_HOST_STUB_BUILD==1 ? 0 : 8;
}
