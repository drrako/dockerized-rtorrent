#!/bin/bash

IMAGE="drrako/rtorrent:latest"

# Determine script directory to set up .temp folder next to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default folders inside .temp in the script's directory
DATA_DIR="$SCRIPT_DIR/.temp/data"
PASSWD_DIR="$SCRIPT_DIR/.temp/passwd"
MEDIA_DIR="$SCRIPT_DIR/.temp/media"

# Create directories if they don't exist
mkdir -p "$DATA_DIR" "$PASSWD_DIR" "$MEDIA_DIR"

echo "Starting rTorrent (attached)..."
echo "Data volume:      $DATA_DIR -> /data"
echo "Passwd volume:    $PASSWD_DIR -> /passwd"
echo "Media/Downloads:  $MEDIA_DIR -> /media/library"
echo "Press Ctrl+C to stop and remove the container."
echo ""

# Run according to README Usage section (refined for attached mode + local .temp volumes)
docker run --name drrako-rtorrent \
  --rm \
  --ulimit nproc=65535 \
  --ulimit nofile=32000:40000 \
  -e RT_DEFAULT_DIR=/media/library \
  -p 6881:6881/udp \
  -p 8000:8000 \
  -p 8080:8080 \
  -p 9000:9000 \
  -p 50000:50000 \
  -v "$DATA_DIR:/data" \
  -v "$PASSWD_DIR:/passwd" \
  -v "$MEDIA_DIR:/media/library" \
  $IMAGE
