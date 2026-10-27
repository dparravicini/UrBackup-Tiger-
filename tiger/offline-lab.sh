#!/bin/sh
set -eu
root="$HOME/Library/UrBackupTigerLab"
grep -q '^computername=Tiger-PPC-Lab-20261027$' "$root/var/urbackup/data/settings.cfg"
./urbackupclientbackend --tiger-self-test
# Keep discovery disabled while local backup directory is configured.
# This endpoint and dummy key cannot connect to any backup server.
printf 'internet_mode_enabled=true\ninternet_authkey=unused-local-fixture\ninternet_server=127.0.0.1\ninternet_server_port=1\n' >> "$root/var/urbackup/data/settings.cfg"
./urbackupclientbackend --internet-only --daemon --pidfile "$root/client.pid" --logfile "$root/log/client.log" --restore client-confirms
sleep 2
./urbackupclientctl add-backupdir --path "$root/fixtures/source" --name TigerFixture --no-follow-symlinks --one-filesystem
./urbackupclientctl list-backupdirs
