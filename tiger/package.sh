#!/bin/sh
set -eu
out=package/UrBackupTiger
mkdir -p "$out/bin" "$out/docs"
test -x urbackupclientgui
cp urbackupclientbackend urbackupclientctl urbackupclientgui "$out/bin/"
/usr/bin/strip -S "$out/bin/urbackupclientbackend" "$out/bin/urbackupclientctl" "$out/bin/urbackupclientgui"

mkdir -p "$out/share/urbackup/lang"
cp client/data/*.ico client/data/logo1.png client/data/urbackup_ecdsa409k1.pub client/data/updates_h.dat client/info.txt client/version.txt "$out/share/urbackup/"
cp -R client/data/lang/. "$out/share/urbackup/lang/"

app="$out/Applications/UrBackup Client.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp urbackupclientgui "$app/Contents/MacOS/urbackupclientgui"
sed \
 -e 's/\$version_num_short\$/2.0.34/g' \
 -e 's/\$version_maj\$/2/g' \
 -e 's/\$version_min\$/0/g' \
 osx_installer/info.plist > "$app/Contents/Info.plist"
cp osx_installer/urbackup.icns "$app/Contents/Resources/urbackup.icns"
chmod 700 "$app/Contents/MacOS/urbackupclientgui"

cp tiger/install.sh "$out/install.sh"
chmod 700 "$out/install.sh"
cp tiger/make-launchagent.py "$out/"
cp COPYING "$out/URBACKUP-COPYING"
cp cryptoplugin/CRYPTOPP-LICENSE.txt "$out/CRYPTOPP-LICENSE.txt"
cp README-TIGER.md "$out/README.md"
cp docs/tiger/*.md "$out/docs/"
"$out/bin/urbackupclientbackend" --tiger-self-test
/usr/bin/file "$out/bin/urbackupclientbackend" "$out/bin/urbackupclientctl" "$out/bin/urbackupclientgui"
/usr/bin/otool -L "$out/bin/urbackupclientbackend"
/usr/bin/otool -L "$out/bin/urbackupclientgui"
/usr/bin/tar -czf UrBackupTiger-2.0.34-ppc.tar.gz -C package UrBackupTiger
