#!/bin/sh

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Creating rtorrent user with PUID [$PUID] and PGID [$PGID].."
addgroup -g $PGID rtorrent
adduser -D -H -u $PUID -G rtorrent -s /bin/sh rtorrent