#!/bin/sh
# Run on the existing Debian DevKit host, never on the Tiger system.
set -eu
./switch_build.sh client
autoreconf -fi
