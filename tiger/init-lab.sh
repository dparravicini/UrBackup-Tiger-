#!/bin/sh
set -eu
umask 077
root="$HOME/Library/UrBackupTigerLab"
if test -e "$root"; then echo "Refusing to initialize existing lab" >&2; exit 42; fi
mkdir -p "$root/var/urbackup/data" "$root/log" "$root/fixtures"
/usr/bin/gcc -std=c89 -Wall -Wextra -arch ppc -isysroot /Developer/SDKs/MacOSX10.4u.sdk tiger/fixture.c -o tiger-fixture
./tiger-fixture create "$root/fixtures/source"
./tiger-fixture verify "$root/fixtures/source" 1
printf 'computername=Tiger-PPC-Lab-20261027\ndefault_dirs=\n' > "$root/var/urbackup/data/settings.cfg"
touch "$root/.urbackup-tiger-lab"
echo "Lab initialized with exclusive fixtures; client not started"
