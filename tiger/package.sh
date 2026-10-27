#!/bin/sh
set -eu
out=package/UrBackupTiger
mkdir -p "$out/bin" "$out/docs"
cp urbackupclientbackend urbackupclientctl "$out/bin/"
/usr/bin/strip -S "$out/bin/urbackupclientbackend" "$out/bin/urbackupclientctl"
cp tiger/install.sh "$out/install.sh"
chmod 700 "$out/install.sh"
cp tiger/make-launchagent.py "$out/"
cp COPYING "$out/URBACKUP-COPYING"
cp cryptoplugin/CRYPTOPP-LICENSE.txt "$out/CRYPTOPP-LICENSE.txt"
cp README-TIGER.md "$out/README.md"
cp docs/tiger/*.md "$out/docs/"
"$out/bin/urbackupclientbackend" --tiger-self-test
/usr/bin/file "$out/bin/urbackupclientbackend" "$out/bin/urbackupclientctl"
/usr/bin/otool -L "$out/bin/urbackupclientbackend"
/usr/bin/tar -czf UrBackupTiger-2.0.34-ppc.tar.gz -C package UrBackupTiger
