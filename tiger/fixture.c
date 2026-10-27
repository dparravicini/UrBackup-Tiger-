/* Dedicated fixtures only. Never traverse or remove existing directories. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/xattr.h>
#include <errno.h>
static char path[4096];
static const char *root;
static int expected_version;
static int name(const char *n) { return snprintf(path,sizeof(path),"%s/%s",root,n)<(int)sizeof(path); }
static int put(const char *n,const void *data,size_t len,int fresh) {
    int fd; struct timeval tv[2];
    if(!name(n)) return 1;
    fd=open(path,O_WRONLY|O_CREAT|O_NOFOLLOW|(fresh?O_EXCL:O_TRUNC),0640);
    if(fd<0) return 1;
    if(write(fd,data,len)!=(ssize_t)len || close(fd)) return 1;
    tv[0].tv_sec=1000000000;tv[0].tv_usec=0;tv[1]=tv[0];
    return utimes(path,tv)!=0;
}
static int forkput(const char *n,const char *value) {
    struct timeval tv[2];
    if(!name(n) || setxattr(path,"com.apple.ResourceFork",value,strlen(value),0,0)) return 1;
    tv[0].tv_sec=1000000000;tv[0].tv_usec=0;tv[1]=tv[0];return utimes(path,tv)!=0;
}
static int content(const char *n,const void *expected,size_t size) {
    char buf[1024];int fd;ssize_t got;struct stat st;
    if(!name(n) || lstat(path,&st) || !S_ISREG(st.st_mode) || st.st_size!=(off_t)size) return 1;
    if(st.st_mtime != 1000000000 + ((expected_version==2 && (!strcmp(n,"plain.txt") || !strcmp(n,"forked") || !strcmp(n,"resource-only")))?10:0)) {fprintf(stderr,"mtime mismatch: %s actual=%ld expected=%ld\n",n,(long)st.st_mtime,1000000000L+((expected_version==2 && (!strcmp(n,"plain.txt") || !strcmp(n,"forked") || !strcmp(n,"resource-only")))?10L:0L));return 1;}
    if(st.st_uid!=getuid() || st.st_gid!=getgid()) {fprintf(stderr,"owner mismatch: %s\n",n);return 1;}
    fd=open(path,O_RDONLY|O_NOFOLLOW);if(fd<0) return 1;
    got=read(fd,buf,sizeof(buf));close(fd);
    if(got!=(ssize_t)size || memcmp(buf,expected,size)) {fprintf(stderr,"Content mismatch: %s\n",n);return 1;}
    if((st.st_mode&0777)!=0640) {fprintf(stderr,"Mode mismatch: %s\n",n);return 1;}
    return 0;
}
static int forkcheck(const char *n,const char *expected) {
    char buf[128];ssize_t got;if(!name(n)) return 1;
    got=getxattr(path,"com.apple.ResourceFork",buf,sizeof(buf),0,0);
    if(got!=(ssize_t)strlen(expected) || memcmp(buf,expected,strlen(expected))) {fprintf(stderr,"ResourceFork mismatch: %s len=%ld expected=%lu errno=%d\n",n,(long)got,(unsigned long)strlen(expected),errno);return 1;}return 0;
}
static int add_nested(void) {
    struct timeval tv[2];int err=0;umask(0);name("nested");if(mkdir(path,0750))return 1;
    err|=put("nested/leaf.txt","nested-one\n",11,1);
    tv[0].tv_sec=1000000000;tv[0].tv_usec=0;tv[1]=tv[0];name("nested");err|=utimes(path,tv)!=0;return err;
}
int main(int argc,char **argv) {
    struct stat nested_stat;unsigned char binary[256],finder[32],actual[32];int i,err=0,version;char linkbuf[128];ssize_t got;
    if(argc<3) {fprintf(stderr,"Usage: fixture create|extend|mutate|verify ROOT [1|2]\n");return 2;}
    root=argv[2];for(i=0;i<256;++i)binary[i]=(unsigned char)i;memset(finder,0,sizeof(finder));memcpy(finder,"TEXTURBT",8);
    if(!strcmp(argv[1],"create")) {
        if(mkdir(root,0700)) {perror("exclusive fixture directory");return 3;}
        umask(0);
        err|=put("plain.txt","version-one\n",12,1);err|=put("binary",binary,256,1);err|=put("empty","",0,1);
        err|=put("forked","data-fork\n",10,1);err|=forkput("forked","resource-fork-one");
        err|=put("resource-only","",0,1);err|=forkput("resource-only","only-resource-one");
        err|=put("unicode-\xc3\xa9.txt","unicode\n",8,1);
        name("forked");err|=setxattr(path,"com.apple.FinderInfo",finder,32,0,0)!=0;
        name("link");err|=symlink("plain.txt",path)!=0;err|=add_nested();
        if(err)perror("create fixture");else puts("Fixture created: content, binary, empty, UTF-8, symlink, FinderInfo, resource forks");
        return err?4:0;
    }
    if(!strcmp(argv[1],"extend")) { err=add_nested();puts("Nested fixture added");return err?7:0; }
    if(!strcmp(argv[1],"mutate")) {
        struct timeval tv[2];err|=put("plain.txt","version-two\n",12,0);
        err|=forkput("forked","resource-fork-two");err|=forkput("resource-only","only-resource-two");
        tv[0].tv_sec=1000000010;tv[0].tv_usec=0;tv[1]=tv[0];
        name("plain.txt");err|=utimes(path,tv)!=0;name("forked");err|=utimes(path,tv)!=0;name("resource-only");err|=utimes(path,tv)!=0;
        if(err)perror("mutate fixture");else puts("Fixture mutated: data and resource-fork-only changes");return err?5:0;
    }
    if(strcmp(argv[1],"verify") || argc!=4) return 2;
    version=atoi(argv[3]);if(version!=1 && version!=2)return 2;expected_version=version;
    name("nested");if(lstat(path,&nested_stat) || !S_ISDIR(nested_stat.st_mode) || (nested_stat.st_mode&0777)!=0750 || nested_stat.st_mtime!=1000000000) {fputs("Nested directory metadata mismatch\n",stderr);err=1;}
    err|=content("nested/leaf.txt","nested-one\n",11);
    err|=content("plain.txt",version==1?"version-one\n":"version-two\n",12);err|=content("binary",binary,256);err|=content("empty","",0);
    err|=content("forked","data-fork\n",10);err|=content("resource-only","",0);err|=content("unicode-\xc3\xa9.txt","unicode\n",8);
    err|=forkcheck("forked",version==1?"resource-fork-one":"resource-fork-two");err|=forkcheck("resource-only",version==1?"only-resource-one":"only-resource-two");
    name("forked");got=getxattr(path,"com.apple.FinderInfo",actual,32,0,0);if(got!=32 || memcmp(actual,finder,32)) {fputs("FinderInfo mismatch\n",stderr);err=1;}
    name("link");got=readlink(path,linkbuf,sizeof(linkbuf));if(got!=9 || memcmp(linkbuf,"plain.txt",9)) {fputs("Symlink mismatch\n",stderr);err=1;}
    if(!err)puts("PASS fixture content, modes, uid/gid, mtime, resource forks, FinderInfo, Unicode and relative symlink");return err?6:0;
}
