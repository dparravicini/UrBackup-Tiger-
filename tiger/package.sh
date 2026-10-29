#!/bin/sh
set -eu

here=$(CDPATH= cd "$(dirname "$0")" && pwd)
root=$(dirname "$here")
cd "$root"

version=2.0.34
out=package/UrBackupTiger
app="$out/UrBackup Client.app"
resources="$app/Contents/Resources"
stage=package/dmg
dmg=UrBackupTiger-${version}-ppc.dmg

test -x urbackupclientgui
test -x urbackupclientbackend
test -x urbackupclientctl

rm -rf package
mkdir -p "$app/Contents/MacOS" "$resources/bin" "$resources/share/urbackup/lang"

cp urbackupclientgui "$app/Contents/MacOS/urbackupclientgui"
cp urbackupclientbackend urbackupclientctl "$resources/bin/"
chmod 755 "$app/Contents/MacOS/urbackupclientgui" "$resources/bin/urbackupclientbackend" "$resources/bin/urbackupclientctl"
/usr/bin/strip -S "$app/Contents/MacOS/urbackupclientgui" \
	"$resources/bin/urbackupclientbackend" "$resources/bin/urbackupclientctl"

cp client/data/*.ico client/data/logo1.png client/data/urbackup_ecdsa409k1.pub \
	client/data/updates_h.dat client/info.txt client/version.txt \
	"$resources/share/urbackup/"
cp client/version.txt "$resources/share/urbackup/curr_version.txt"
cp -R client/data/lang/. "$resources/share/urbackup/lang/"

sed \
	-e 's/\$version_num_short\$/'"$version"'/g' \
	-e 's/\$version_maj\$/2/g' \
	-e 's/\$version_min\$/0/g' \
	osx_installer/info.plist > "$app/Contents/Info.plist"
printf 'APPL????' > "$app/Contents/PkgInfo"

# cp/mkdir do not set the HFS bundle bit. Tiger LaunchServices otherwise
# refuses to open the application (error -10829).
if [ -x /Developer/Tools/SetFile ]; then
	/Developer/Tools/SetFile -a B "$app"
fi

# The upstream .icns is a text placeholder and Tiger's sips cannot write
# ICNS. Ship an ICNS generated from the original backup-ok.ico with the
# legacy is32/il32/ih32/it32 elements supported by Mac OS X 10.4.
cp osx_installer/urbackup.icns "$resources/urbackup.icns"

mkdir -p "$stage"
cp -R "$app" "$stage/"
# Keep the HFS bundle bit on the copy that is written into the DMG as well.
if [ -x /Developer/Tools/SetFile ]; then
	/Developer/Tools/SetFile -a B "$stage/UrBackup Client.app"
fi
ln -s /Applications "$stage/Applications"
cp COPYING "$stage/URBACKUP-COPYING.txt"
cp cryptoplugin/CRYPTOPP-LICENSE.txt "$stage/CRYPTOPP-LICENSE.txt"
cp README-TIGER-EN.md "$stage/README.md"
cat > "$stage/ReadMe.txt" <<'EOF'
UrBackup Client Tiger 2.0.34 (PowerPC)

Requirements
- Mac OS X 10.4.11 on a PowerPC Mac.
- An UrBackup 2.x server reachable over the network.

Installation
1. Drag "UrBackup Client" to the Applications folder.
2. Launch it from Applications. The client backend starts automatically.
3. Open Settings and configure the server, then add the folders you want to
   back up.

Settings and backup paths
Open Settings with:
  "/Applications/UrBackup Client.app/Contents/MacOS/urbackupclientgui" settings

The GUI asks for a full absolute path (for example /Users/you/Documents)
instead of opening the native Tiger folder picker, because NavigationServices
can terminate the application on Tiger. Open the path editor with:
  "/Applications/UrBackup Client.app/Contents/MacOS/urbackupclientgui" paths

Data and configuration
Each user has separate data in:
  ~/Library/Application Support/UrBackupTiger
The package contains no server, credentials or personal data. Configure the
UrBackup server in the client Settings window.

Menu bar and Dock
The original tray menu is implemented with a native NSStatusItem. On some
Tiger sessions SystemUIServer does not display status items; if the icon is
not visible, use the settings, paths and logs commands above.

Uninstall
1. Quit UrBackup from its menu, or stop the backend process.
2. Remove the application from Applications.
3. To remove local configuration and state as well, delete
   ~/Library/Application Support/UrBackupTiger.

License: GNU AGPL v3 or later. See URBACKUP-COPYING.txt.
EOF

"$resources/bin/urbackupclientbackend" --tiger-self-test
/usr/bin/file "$resources/bin/urbackupclientbackend" "$resources/bin/urbackupclientctl" "$app/Contents/MacOS/urbackupclientgui"
/usr/bin/otool -L "$resources/bin/urbackupclientbackend"
/usr/bin/otool -L "$app/Contents/MacOS/urbackupclientgui"

rm -f "$dmg"
/usr/bin/hdiutil create -volname "UrBackup Tiger $version" -srcfolder "$stage" \
	-ov -format UDZO "$dmg"
/usr/bin/hdiutil verify "$dmg"
/usr/bin/tar -czf "UrBackupTiger-${version}-ppc.tar.gz" -C "$stage" .
