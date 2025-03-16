#!/bin/sh

# Nginx
echo "Setting Nginx configuration..."
sed -e "s#@REAL_IP_FROM@#$REAL_IP_FROM#g" \
  -e "s#@REAL_IP_HEADER@#$REAL_IP_HEADER#g" \
  -e "s#@LOG_IP_VAR@#$LOG_IP_VAR#g" \
  -e "s#@AUTH_DELAY@#$AUTH_DELAY#g" \
  -e "s#@NGINX_WORKER_PROCESSES@#$NGINX_WORKER_PROCESSES#g" \
  -e "s#@NGINX_WORKER_CONNECTIONS@#$NGINX_WORKER_CONNECTIONS#g" \
  /tpls/etc/nginx/nginx.conf > /etc/nginx/nginx.conf
if [ "${LOG_ACCESS}" != "true" ]; then
  echo "  Disabling Nginx access log..."
  sed -i "s!access_log /proc/self/fd/1 main!access_log off!g" /etc/nginx/nginx.conf
fi

# Nginx XMLRPC over SCGI
echo "Setting Nginx XMLRPC over SCGI configuration..."
sed -e "s!@XMLRPC_AUTHBASIC_STRING@!$XMLRPC_AUTHBASIC_STRING!g" \
  -e "s!@XMLRPC_PORT@!$XMLRPC_PORT!g" \
  -e "s!@XMLRPC_HEALTH_PORT@!$XMLRPC_HEALTH_PORT!g" \
  -e "s!@XMLRPC_SIZE_LIMIT@!$XMLRPC_SIZE_LIMIT!g" \
  /tpls/etc/nginx/conf.d/rpc.conf > /etc/nginx/conf.d/rpc.conf

# Nginx ruTorrent
echo "Setting Nginx ruTorrent configuration..."
sed -e "s!@UPLOAD_MAX_SIZE@!$UPLOAD_MAX_SIZE!g" \
  -e "s!@RUTORRENT_AUTHBASIC_STRING@!$RUTORRENT_AUTHBASIC_STRING!g" \
  -e "s!@RUTORRENT_PORT@!$RUTORRENT_PORT!g" \
  -e "s!@RUTORRENT_HEALTH_PORT@!$RUTORRENT_HEALTH_PORT!g" \
  /tpls/etc/nginx/conf.d/rutorrent.conf > /etc/nginx/conf.d/rutorrent.conf


# Healthcheck
echo "Update healthcheck script..."
cat > /usr/local/bin/healthcheck <<EOL
#!/bin/sh
set -e

# rTorrent
curl --fail -d "<?xml version='1.0'?><methodCall><methodName>system.api_version</methodName></methodCall>" http://127.0.0.1:${XMLRPC_HEALTH_PORT}

# ruTorrent / PHP
curl --fail http://127.0.0.1:${RUTORRENT_HEALTH_PORT}/ping
EOL