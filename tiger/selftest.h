#ifndef URBACKUP_TIGER_SELFTEST_H
#define URBACKUP_TIGER_SELFTEST_H
#include "../Server.h"
#include "compat.h"
#include "compat_time.h"
#include "../common/data.h"
#include "../Interface/File.h"
#include "../cryptoplugin/cryptopp_inc.h"
#include <sys/stat.h>
#include <sys/xattr.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static int tiger_selftest() {
    const unsigned char expected_wire[] = {0x78,0x56,0x34,0x12,0xef,0xcd,0xab,0x89,0x67,0x45,0x23,0x01};
    CWData wire; wire.addUInt(0x12345678U); wire.addUInt64(0x0123456789abcdefULL);
    if(wire.getDataSize()!=sizeof(expected_wire) || memcmp(wire.getDataPtr(), expected_wire, sizeof(expected_wire))) return 10;
    CRData input(wire.getDataPtr(), wire.getDataSize()); unsigned int u; uint64 v;
    if(!input.getUInt(&u) || !input.getInt64(reinterpret_cast<int64*>(&v)) || u!=0x12345678U || v!=0x0123456789abcdefULL) return 11;
    if(sizeof(IFsFile::SSparseExtent)!=16) return 12;
    printf("PASS protocol little endian bytes, round trip and sparse extent layout\n");
    unsigned char key[16]={0}, plain[16]={0}, encrypted[16];
    const unsigned char aes_expected[16]={0x66,0xe9,0x4b,0xd4,0xef,0x8a,0x2c,0x3b,0x88,0x4c,0xfa,0x59,0xca,0x34,0x2b,0x2e};
    CryptoPP::AES::Encryption aes(key,16); aes.ProcessBlock(plain,encrypted);
    if(memcmp(encrypted,aes_expected,16)) return 13;
    unsigned char digest[32];
    const unsigned char sha_expected[32]={0xba,0x78,0x16,0xbf,0x8f,0x01,0xcf,0xea,0x41,0x41,0x40,0xde,0x5d,0xae,0x22,0x23,0xb0,0x03,0x61,0xa3,0x96,0x17,0x7a,0x9c,0xb4,0x10,0xff,0x61,0xf2,0x00,0x15,0xad};
    CryptoPP::SHA256 sha; sha.CalculateDigest(digest,reinterpret_cast<const unsigned char*>("abc"),3);
    if(memcmp(digest,sha_expected,32)) return 14;
    CryptoPP::AutoSeededRandomPool random; unsigned char r1[32],r2[32]; random.GenerateBlock(r1,32); random.GenerateBlock(r2,32);
    if(!memcmp(r1,r2,32)) return 15;
    printf("PASS Crypto++ AES and SHA256 known answers; OS random generation\n");
    char temp[]="/tmp/urbackup-tiger-selftest-XXXXXX";
    if(!mkdtemp(temp)) return 16;
    std::string fn=std::string(temp)+"/fixture", ln=std::string(temp)+"/link";
    int fd=open(fn.c_str(),O_WRONLY|O_CREAT|O_EXCL,0600); if(fd<0) return 17;
    if(write(fd,"data",4)!=4 || close(fd)) return 18;
    if(setxattr(fn.c_str(),"com.apple.ResourceFork","resource",8,0,0)) return 19;
    char fork_data[16]; if(getxattr(fn.c_str(),"com.apple.ResourceFork",fork_data,sizeof(fork_data),0,0)!=8 || memcmp(fork_data,"resource",8)) return 20;
    unsigned char finder[32]={0}; memcpy(finder,"TEXTTEST",8);
    if(setxattr(fn.c_str(),"com.apple.FinderInfo",finder,32,0,0)) return 21;
    unsigned char restored_finder[32]; if(getxattr(fn.c_str(),"com.apple.FinderInfo",restored_finder,32,0,0)!=32 || memcmp(finder,restored_finder,32)) return 22;
    struct stat before, after, link_stat; if(stat(fn.c_str(),&before) || symlink("fixture",ln.c_str())) return 23;
    struct timeval tv[2]; tv[0].tv_sec=946684800; tv[0].tv_usec=0; tv[1]=tv[0];
    errno=0;
    if(tiger_lutimes(ln.c_str(),tv)!=-1 || errno!=ENOTSUP) return 24;
    if(lstat(ln.c_str(),&link_stat) || stat(fn.c_str(),&after) || before.st_mtime!=after.st_mtime) return 25;
    if(tiger_lchflags(ln.c_str(),0)) return 27;
    if(tiger_lutimes(fn.c_str(),tv) || stat(fn.c_str(),&after) || after.st_mtime!=946684800) return 28;
    printf("LIMIT verified: Darwin 8 HFS+ does not set symlink timestamps; target unchanged\n");
    if(unlink(ln.c_str()) || unlink(fn.c_str()) || rmdir(temp)) return 26;
    printf("PASS HFS+ ResourceFork, FinderInfo, regular timestamps and symlink flags\n");
    return 0;
}
#endif
