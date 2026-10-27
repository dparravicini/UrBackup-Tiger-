#!/bin/sh
set -eu
root="$HOME/Library/UrBackupTigerLab"
case "${1-}" in ''|*[!0-9]*) echo 'Numeric backup ID required' >&2; exit 2;; esac
case "${2-}" in full|incr) ;; *) echo 'Use full or incr' >&2; exit 2;; esac
tag=${3-$2}
case "$tag" in ''|*[!a-zA-Z0-9_-]*) echo 'Invalid restore directory tag' >&2; exit 2;; esac
out="$root/fixtures/restored-$tag"
test ! -e "$out" || { echo 'Refusing existing restore directory' >&2; exit 3; }
mkdir "$out"
./urbackupclientctl restore-start --backupid "$1" --map-from / --map-to "$out" --no-remove --no-follow-symlinks
version=1
test "$2" != incr || version=2
./tiger-fixture verify "$out/${root#/}/fixtures/source" "$version"
