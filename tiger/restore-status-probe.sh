#!/bin/sh
set -eu
pid=$(cat "$HOME/Library/UrBackupTigerLab/client.pid")
/usr/bin/gdb --batch --pid "$pid" -ex 'set print elements 0' -ex 'thread apply all bt 4'
