#!/bin/sh

# PHP
echo "Setting PHP-FPM configuration..."
sed -e "s/@MEMORY_LIMIT@/$MEMORY_LIMIT/g" \
  -e "s/@UPLOAD_MAX_SIZE@/$UPLOAD_MAX_SIZE/g" \
  -e "s/@CLEAR_ENV@/$CLEAR_ENV/g" \
  /tpls/etc/php84/php-fpm.d/www.conf > /etc/php84/php-fpm.d/www.conf

echo "Setting PHP INI configuration..."
sed -i "s|memory_limit.*|memory_limit = ${MEMORY_LIMIT}|g" /etc/php84/php.ini
sed -i "s|;date\.timezone.*|date\.timezone = ${TZ}|g" /etc/php84/php.ini
sed -i "s|max_file_uploads.*|max_file_uploads = ${MAX_FILE_UPLOADS}|g" /etc/php84/php.ini

# OpCache
echo "Setting OpCache configuration..."
sed -e "s/@OPCACHE_MEM_SIZE@/$OPCACHE_MEM_SIZE/g" \
  /tpls/etc/php84/conf.d/opcache.ini > /etc/php84/conf.d/opcache.ini