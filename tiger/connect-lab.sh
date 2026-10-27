#!/bin/sh
set -eu
root="$HOME/Library/UrBackupTigerLab"
/bin/sh tiger/stop-lab.sh
grep -q '^computername=Tiger-PPC-Lab-20261027$' "$root/var/urbackup/data/settings.cfg"
sed '/^internet_/d' "$root/var/urbackup/data/settings.cfg" > "$root/var/urbackup/data/settings.cfg.new"
printf 'internet_mode_enabled=false\n' >> "$root/var/urbackup/data/settings.cfg.new"
mv "$root/var/urbackup/data/settings.cfg.new" "$root/var/urbackup/data/settings.cfg"
./urbackupclientbackend --daemon --pidfile "$root/client.pid" --logfile "$root/log/client.log" --restore client-confirms
sleep 2
./urbackupclientctl list-backupdirs
