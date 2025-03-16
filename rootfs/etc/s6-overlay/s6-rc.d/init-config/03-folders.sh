#!/bin/sh

echo "Preparing directories and permissions.."

chown rtorrent:rtorrent /proc/self/fd/1 /proc/self/fd/2 || true

mkdir -p /data/rtorrent \
  /data/rutorrent \
  /passwd \
  /etc/nginx/conf.d \
  /etc/rtorrent \
  /var/cache/nginx \
  /var/lib/nginx \
  /var/log/nginx \
  /var/run/nginx \
  /var/run/php-fpm \
  /var/run/rtorrent
chown rtorrent:rtorrent \
  /data \
  /data/rtorrent 
chown -R rtorrent:rtorrent \
  /etc/rtorrent \
  /passwd \
  /tpls \
  /var/cache/nginx \
  /var/lib/nginx \
  /var/log/nginx \
  /var/log/php83 \
  /var/run/nginx \
  /var/run/php-fpm \
  /var/run/rtorrent