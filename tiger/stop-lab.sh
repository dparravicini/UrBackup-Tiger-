#!/bin/sh
set -eu
root="$HOME/Library/UrBackupTigerLab"
test -f "$root/client.pid" || exit 0
pid=$(cat "$root/client.pid")
case "$pid" in ''|*[!0-9]*) echo 'Invalid lab PID' >&2; exit 2;; esac
if ! kill -0 "$pid" 2>/dev/null; then exit 0; fi
cmd=$(ps -ww -p "$pid" -o command=)
case "$cmd" in *UrBackupTigerLab/log/client.log*) ;; *) echo 'PID does not identify the lab client' >&2; exit 3;; esac
kill -TERM "$pid"
i=0
while kill -0 "$pid" 2>/dev/null; do
 i=$((i+1)); test "$i" -lt 20 || { echo 'Lab client did not stop' >&2; exit 4; }
 sleep 1
done
echo 'Lab client stopped'
