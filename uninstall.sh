#!/bin/sh
set -eu
if [ ! -x /usr/libexec/bili-ipv4-uninstall ]; then
    echo 'No managed bili-ipv4 installation found.' >&2
    exit 1
fi
exec /usr/libexec/bili-ipv4-uninstall
