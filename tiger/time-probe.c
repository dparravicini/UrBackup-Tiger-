#include "compat_time.h"
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
int main(void) {
 char tmp[]="/tmp/urbackup-tiger-time-XXXXXX",fn[256],ln[256];int fd,rc;struct stat st;struct timeval tv[2];
 if(!mkdtemp(tmp))return 1;snprintf(fn,sizeof(fn),"%s/file",tmp);snprintf(ln,sizeof(ln),"%s/link",tmp);
 fd=open(fn,O_CREAT|O_EXCL|O_WRONLY,0600);if(fd<0)return 2;close(fd);if(symlink("file",ln))return 3;
 tv[0].tv_sec=946684800;tv[0].tv_usec=0;tv[1]=tv[0];
 printf("sizes attrlist=%lu timespec=%lu timeval=%lu flags=%lx\n",(unsigned long)sizeof(struct attrlist),(unsigned long)sizeof(struct timespec),(unsigned long)sizeof(struct timeval),(unsigned long)(ATTR_CMN_MODTIME|ATTR_CMN_ACCTIME));
 rc=tiger_lutimes(fn,tv);lstat(fn,&st);printf("regular rc=%d errno=%d mtime=%ld\n",rc,errno,(long)st.st_mtime);
 rc=tiger_lutimes(ln,tv);lstat(ln,&st);printf("symlink rc=%d errno=%d mtime=%ld\n",rc,errno,(long)st.st_mtime);
 rc=tiger_lutimes(ln,tv);lstat(ln,&st);printf("symlink retry rc=%d errno=%d mtime=%ld\n",rc,errno,(long)st.st_mtime);
 unlink(ln);unlink(fn);rmdir(tmp);return 0;
}
