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

# The upstream .icns is a placeholder. Derive a real Tiger icon from the
# original UrBackup status asset already shipped by the frontend.
if /usr/bin/sips -s format png client/data/backup-ok.ico --out "$out/icon.png" >/dev/null 2>&1 \
	&& /usr/bin/sips -s format icns "$out/icon.png" --out "$resources/urbackup.icns" >/dev/null 2>&1
then
	rm -f "$out/icon.png"
else
	cp osx_installer/urbackup.icns "$resources/urbackup.icns"
fi

mkdir -p "$stage"
cp -R "$app" "$stage/"
# Keep the HFS bundle bit on the copy that is written into the DMG as well.
if [ -x /Developer/Tools/SetFile ]; then
	/Developer/Tools/SetFile -a B "$stage/UrBackup Client.app"
fi
ln -s /Applications "$stage/Applications"
cp COPYING "$stage/URBACKUP-COPYING.txt"
cp cryptoplugin/CRYPTOPP-LICENSE.txt "$stage/CRYPTOPP-LICENSE.txt"
cp README-TIGER.md "$stage/README-TIGER.md"
cat > "$stage/Leggimi.txt" <<'EOF'
UrBackup Client Tiger 2.0.34 (PowerPC)

Requisiti
- Mac OS X 10.4.11 su PowerPC.

Installazione
1. Trascinare "UrBackup Client" nella cartella Applicazioni.
2. Avviarlo da Applicazioni. Il backend parte automaticamente.
3. Nella sessione Tiger di verifica l'icona nel Dock e lo status item non sono
   stati visibili. Aprire Impostazioni e Percorsi con i comandi indicati sotto.

Dati e configurazione
Ogni utente ha dati separati in:
  ~/Library/Application Support/UrBackupTiger
Il pacchetto non contiene server, credenziali o dati personali. Il server
UrBackup va configurato nelle Impostazioni del client.

Impostazioni e configurazione delle cartelle
Aprire Impostazioni con:
  "/Applications/UrBackup Client.app/Contents/MacOS/urbackupclientgui" settings

La GUI usa l'inserimento del percorso completo (es. /etc), perche' il
selettore directory nativo di Tiger puo' chiudere inaspettatamente
l'applicazione. Aprire:
  "/Applications/UrBackup Client.app/Contents/MacOS/urbackupclientgui" paths
Selezionare "Aggiungi percorso", digitare il percorso assoluto e premere OK.

Rimozione
1. Chiudere UrBackup e il relativo processo backend.
2. Eliminare l'applicazione da Applicazioni.
3. Se si vogliono eliminare anche configurazione e stato locali, eliminare
   ~/Library/Application Support/UrBackupTiger.

Licenza: GNU AGPL v3 o successiva. Vedere URBACKUP-COPYING.txt.
EOF

"$resources/bin/urbackupclientbackend" --tiger-self-test
/usr/bin/file "$resources/bin/urbackupclientbackend" "$resources/bin/urbackupclientctl" "$app/Contents/MacOS/urbackupclientgui"
/usr/bin/otool -L "$resources/bin/urbackupclientbackend"
/usr/bin/otool -L "$app/Contents/MacOS/urbackupclientgui"

rm -f "$dmg"
/usr/bin/hdiutil create -volname "UrBackup Tiger $version" -srcfolder "$stage" \
	-ov -format UDZO "$dmg"
/usr/bin/hdiutil verify "$dmg"
/usr/bin/tar -czf "UrBackupTiger-${version}-ppc.tar.gz" -C package "UrBackupTiger"
