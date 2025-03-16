#!/bin/sh

# WAN IP
if [ -z "$WAN_IP" ] && [ -n "$WAN_IP_CMD" ]; then
  WAN_IP=$(eval "$WAN_IP_CMD")
fi
if [ -n "$WAN_IP" ]; then
  echo "Public IP address enforced to ${WAN_IP}"
fi
printf "%s" "$WAN_IP" > /var/run/s6/container_environment/WAN_IP

# Init
echo "Initializing rTorrent and ruTorrent files and folders..."
mkdir -p /data/rtorrent/log \
  /data/rtorrent/.session \
  /data/rutorrent/conf/users \
  /data/rutorrent/plugins \
  /data/rutorrent/plugins-conf \
  /data/rutorrent/share/users \
  /data/rutorrent/share/torrents \
  /data/rutorrent/themes
touch /passwd/rpc.htpasswd \
  /passwd/rutorrent.htpasswd \
  /data/rtorrent/log/rtorrent.log \
  "${RU_LOG_FILE}"
rm -f /data/rtorrent/.session/rtorrent.lock

# Check htpasswd files
if [ ! -s "/passwd/rpc.htpasswd" ]; then
  echo "rpc.htpasswd is empty, removing authentication..."
  sed -i "s!auth_basic .*!#auth_basic!g" /etc/nginx/conf.d/rpc.conf
  sed -i "s!auth_basic_user_file.*!#auth_basic_user_file!g" /etc/nginx/conf.d/rpc.conf
fi
if [ ! -s "/passwd/rutorrent.htpasswd" ]; then
  echo "rutorrent.htpasswd is empty, removing authentication..."
  sed -i "s!auth_basic .*!#auth_basic!g" /etc/nginx/conf.d/rutorrent.conf
  sed -i "s!auth_basic_user_file.*!#auth_basic_user_file!g" /etc/nginx/conf.d/rutorrent.conf
fi

# rTorrent local config
echo "Checking rTorrent local configuration..."
echo "Default download dir: ${RT_DEFAULT_DIR}"

sed -e "s!@RT_LOG_LEVEL@!$RT_LOG_LEVEL!g" \
  -e "s!@RT_DHT_PORT@!$RT_DHT_PORT!g" \
  -e "s!@RT_INC_PORT@!$RT_INC_PORT!g" \
  -e "s!@XMLRPC_SIZE_LIMIT@!$XMLRPC_SIZE_LIMIT!g" \
  -e "s!@RT_SESSION_SAVE_SECONDS@!$RT_SESSION_SAVE_SECONDS!g" \
  -e "s!@RT_TRACKER_DELAY_SCRAPE@!$RT_TRACKER_DELAY_SCRAPE!g" \
  -e "s!@RT_SEND_BUFFER_SIZE@!$RT_SEND_BUFFER_SIZE!g" \
  -e "s!@RT_RECEIVE_BUFFER_SIZE@!$RT_RECEIVE_BUFFER_SIZE!g" \
  -e "s!@RT_PREALLOCATE_TYPE@!$RT_PREALLOCATE_TYPE!g" \
  -e "s!@RT_DEFAULT_DIR@!$RT_DEFAULT_DIR!g" \
  /tpls/etc/rtorrent/.rtlocal.rc > /etc/rtorrent/.rtlocal.rc
if [ "${RT_LOG_EXECUTE}" = "true" ]; then
  echo "  Enabling rTorrent execute log..."
  sed -i "s!#log\.execute.*!log\.execute = (cat,(cfg.logs),\"execute.log\")!g" /etc/rtorrent/.rtlocal.rc
fi
if [ "${RT_LOG_XMLRPC}" = "true" ]; then
  echo "  Enabling rTorrent xmlrpc log..."
  sed -i "s!#log\.xmlrpc.*!log\.xmlrpc = (cat,(cfg.logs),\"xmlrpc.log\")!g" /etc/rtorrent/.rtlocal.rc
fi

# rTorrent config
echo "Checking rTorrent configuration..."
if [ ! -f /data/rtorrent/.rtorrent.rc ]; then
  echo "  Creating default configuration..."
  cp /tpls/.rtorrent.rc /data/rtorrent/.rtorrent.rc
fi
chown rtorrent:rtorrent /data/rtorrent/.rtorrent.rc

# ruTorrent config
echo "Bootstrapping ruTorrent configuration..."
sed -e "s!@RU_HTTP_USER_AGENT@!$RU_HTTP_USER_AGENT!g" \
  -e "s!@RU_HTTP_TIME_OUT@!$RU_HTTP_TIME_OUT!g" \
  -e "s!@RU_HTTP_USE_GZIP@!$RU_HTTP_USE_GZIP!g" \
  -e "s!@RU_RPC_TIME_OUT@!$RU_RPC_TIME_OUT!g" \
  -e "s!@RU_LOG_RPC_CALLS@!$RU_LOG_RPC_CALLS!g" \
  -e "s!@RU_LOG_RPC_FAULTS@!$RU_LOG_RPC_FAULTS!g" \
  -e "s!@RU_PHP_USE_GZIP@!$RU_PHP_USE_GZIP!g" \
  -e "s!@RU_PHP_GZIP_LEVEL@!$RU_PHP_GZIP_LEVEL!g" \
  -e "s!@RU_SCHEDULE_RAND@!$RU_SCHEDULE_RAND!g" \
  -e "s!@RU_DO_DIAGNOSTIC@!$RU_DO_DIAGNOSTIC!g" \
  -e "s!@RU_LOG_FILE@!$RU_LOG_FILE!g" \
  -e "s!@RU_SAVE_UPLOADED_TORRENTS@!$RU_SAVE_UPLOADED_TORRENTS!g" \
  -e "s!@RU_OVERWRITE_UPLOADED_TORRENTS@!$RU_OVERWRITE_UPLOADED_TORRENTS!g" \
  -e "s!@RU_FORBID_USER_SETTINGS@!$RU_FORBID_USER_SETTINGS!g" \
  -e "s!@RU_CACHED_PLUGIN_LOADING@!$RU_CACHED_PLUGIN_LOADING!g" \
  -e "s!@RU_LOCALE@!$RU_LOCALE!g" \
  /tpls/var/www/rutorrent/conf/config.php.rc > /var/www/rutorrent/conf/config.php
chown nobody:nogroup "/var/www/rutorrent/conf/config.php"

# Symlinking ruTorrent config
ln -sf /data/rutorrent/conf/users /var/www/rutorrent/conf/users
if [ ! -f /data/rutorrent/conf/access.ini ]; then
  echo "Symlinking ruTorrent access.ini file..."
  mv /var/www/rutorrent/conf/access.ini /data/rutorrent/conf/access.ini
  ln -sf /data/rutorrent/conf/access.ini /var/www/rutorrent/conf/access.ini
fi
chown rtorrent:rtorrent /data/rutorrent/conf/access.ini
if [ ! -f /data/rutorrent/conf/plugins.ini ]; then
  echo "Symlinking ruTorrent plugins.ini file..."
  mv /var/www/rutorrent/conf/plugins.ini /data/rutorrent/conf/plugins.ini
  ln -sf /data/rutorrent/conf/plugins.ini /var/www/rutorrent/conf/plugins.ini
fi
chown rtorrent:rtorrent /data/rutorrent/conf/plugins.ini

# Remove ruTorrent core plugins
if [ "$RU_REMOVE_CORE_PLUGINS" != "false" ]; then
  for i in ${RU_REMOVE_CORE_PLUGINS//,/ }
  do
    if [ -z "$i" ]; then continue; fi
    if [ "$i" == "httprpc" ]; then
      echo "Warning: skipping core plugin httprpc, required for ruTorrent v4.3+ operation"
      echo "Please remove httprpc from RU_REMOVE_CORE_PLUGINS environment varriable"
      continue;
    fi      
    echo "Removing core plugin $i..."
    rm -rf "/var/www/rutorrent/plugins/${i}"
  done
fi

echo "Setting custom config for create plugin..."
if [ -d "/var/www/rutorrent/plugins/create" ]; then

  cat > /var/www/rutorrent/plugins/create/conf.php <<EOL
<?php

\$useExternal = 'mktorrent';
\$pathToCreatetorrent = '/usr/local/bin/mktorrent';
\$recentTrackersMaxCount = 15;
\$useInternalHybrid = true;
EOL
  chown nobody:nogroup "/var/www/rutorrent/plugins/create/conf.php"
else
  echo "  WARNING: create plugin does not exist"
fi

echo "Checking ruTorrent custom plugins..."
plugins=$(ls -l /data/rutorrent/plugins | grep -E '^d' | awk '{print $9}')
for plugin in ${plugins}; do
  if [ "${plugin}" = "theme" ]; then
    echo "  WARNING: theme plugin cannot be overriden"
    continue
  fi
  echo "  Copying custom ${plugin} plugin..."
  if [ -d "/var/www/rutorrent/plugins/${plugin}" ]; then
    rm -rf "/var/www/rutorrent/plugins/${plugin}"
  fi
  cp -Rf "/data/rutorrent/plugins/${plugin}" "/var/www/rutorrent/plugins/${plugin}"
  chown -R nobody:nogroup "/var/www/rutorrent/plugins/${plugin}"
done

echo "Checking ruTorrent plugins configuration..."
for pluginConfFile in /data/rutorrent/plugins-conf/*.php; do
  if [ ! -f "$pluginConfFile" ]; then
    continue
  fi
  pluginConf=$(basename "$pluginConfFile")
  pluginName=$(echo "$pluginConf" | cut -f 1 -d '.')
  if [ ! -d "/var/www/rutorrent/plugins/${pluginName}" ]; then
    echo "  WARNING: $pluginName plugin does not exist"
    continue
  fi
  if [ -d "/data/rutorrent/plugins/${pluginName}" ]; then
    echo "  WARNING: $pluginName plugin already exist in /data/rutorrent/plugins/"
    continue
  fi
  echo "  Copying ${pluginName} plugin config..."
  cp -f "${pluginConfFile}" "/var/www/rutorrent/plugins/${pluginName}/conf.php"
  chown nobody:nogroup "/var/www/rutorrent/plugins/${pluginName}/conf.php"
done

echo "Checking ruTorrent custom themes..."
themes=$(ls -l /data/rutorrent/themes | grep -E '^d' | awk '{print $9}')
for theme in ${themes}; do
  echo "  Copying custom ${theme} theme..."
  if [ -d "/var/www/rutorrent/plugins/theme/themes/${theme}" ]; then
    rm -rf "/var/www/rutorrent/plugins/theme/themes/${theme}"
  fi
  cp -Rf "/data/rutorrent/themes/${theme}" "/var/www/rutorrent/plugins/theme/themes/${theme}"
  chown -R nobody:nogroup "/var/www/rutorrent/plugins/theme/themes/${theme}"
done

echo "Fixing rTorrent and ruTorrent folder permissions.."
chown rtorrent:rtorrent \
  /data/rutorrent/share/users \
  /data/rutorrent/share/torrents \
  "${RU_LOG_FILE}"
chown -R rtorrent:rtorrent \
  /data/rtorrent/log \
  /data/rtorrent/.session \
  /data/rutorrent/conf \
  /data/rutorrent/plugins \
  /data/rutorrent/plugins-conf \
  /data/rutorrent/share \
  /data/rutorrent/themes \
  /etc/rtorrent
chmod 644 \
  /data/rtorrent/.rtorrent.rc \
  /passwd/*.htpasswd \
  /etc/rtorrent/.rtlocal.rc