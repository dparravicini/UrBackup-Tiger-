#ifndef URBACKUP_TIGER_COMPAT_TIME_H
#define URBACKUP_TIGER_COMPAT_TIME_H
#include <sys/attr.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
/* Tiger lacks lutimes. Set the link itself, never its target. */
static inline int tiger_lutimes(const char* path, const struct timeval tv[2]) {
    struct attrlist attrs;
    struct timespec times[2];
    memset(&attrs, 0, sizeof(attrs));
    attrs.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrs.commonattr = ATTR_CMN_MODTIME | ATTR_CMN_ACCTIME;
    times[0].tv_sec = tv[1].tv_sec; times[0].tv_nsec = tv[1].tv_usec * 1000;
    times[1].tv_sec = tv[0].tv_sec; times[1].tv_nsec = tv[0].tv_usec * 1000;
    return setattrlist(path, &attrs, times, sizeof(times), FSOPT_NOFOLLOW);
}
static inline int tiger_lchflags(const char* path, unsigned int flags) {
    struct attrlist attrs;
    memset(&attrs, 0, sizeof(attrs));
    attrs.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrs.commonattr = ATTR_CMN_FLAGS;
    return setattrlist(path, &attrs, &flags, sizeof(flags), FSOPT_NOFOLLOW);
}
#endif
