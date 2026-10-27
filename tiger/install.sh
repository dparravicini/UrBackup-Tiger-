#!/bin/sh
# Per-user installation for the iBook home used at build time.
set -eu
umask 077
here=$(CDPATH= cd "$(dirname "$0")" && pwd)
vardir=$("$here/bin/urbackupclientbackend" --tiger-vardir)
root=$(dirname "$vardir")
if test "$root" != "$HOME/Library/UrBackupTigerLab"; then
 echo "This package must be rebuilt for this user's home using Vintage-DevKit" >&2; exit 2
fi
if test -e "$root" && ! test -f "$root/.urbackup-tiger-lab"; then
 echo "Refusing to overwrite an unmarked installation" >&2; exit 3
fi
if test -f "$root/client.pid"; then
 pid=$(cat "$root/client.pid")
 case "$pid" in ''|*[!0-9]*) exit 4;; esac
 if kill -0 "$pid" 2>/dev/null; then echo 'Stop the lab client before installation' >&2; exit 5; fi
fi
mkdir -p "$root/sbin" "$root/var/urbackup/data" "$root/log"
cp "$here/bin/urbackupclientbackend" "$root/sbin/urbackupclientbackend"
cp "$here/bin/urbackupclientctl" "$root/sbin/urbackupclientctl"
chmod 700 "$root/sbin/urbackupclientbackend" "$root/sbin/urbackupclientctl"
touch "$root/.urbackup-tiger-lab"
"$root/sbin/urbackupclientbackend" --tiger-self-test
if test "${1-}" = '--enable-launchd'; then
 mkdir -p "$HOME/Library/LaunchAgents"
 plist="$HOME/Library/LaunchAgents/org.urbackup.tiger.lab.plist"
 if test -e "$plist"; then echo 'LaunchAgent already exists; inspect before replacing' >&2; exit 6; fi
 /usr/bin/python "$here/make-launchagent.py" "$root" "$plist"
 /usr/bin/plutil -lint "$plist"
 /bin/launchctl load "$plist"
 echo 'Per-user LaunchAgent loaded; starts again on login'
fi
echo 'Standalone client installed in the dedicated per-user directory'
