#!/bin/bash
set -e

DATA_DIR="/var/www/data"
CONF_FILE="$DATA_DIR/LocalSettings.php"
mkdir -p "$DATA_DIR" /var/www/html/images
chown -R www-data:www-data "$DATA_DIR" /var/www/html/images

if [ ! -f "$CONF_FILE" ]; then
  : "${MW_ADMIN_PASS:?MW_ADMIN_PASS is required on first startup}"
  SERVER="${MW_SERVER:-http://localhost:8080}"
  php maintenance/run.php install \
    --dbtype=sqlite \
    --dbpath="$DATA_DIR" \
    --dbname=wikidb \
    --confpath="$CONF_FILE" \
    --server="$SERVER" \
    --scriptpath="" \
    --lang=zh-tw \
    --skins=all \
    --pass="$MW_ADMIN_PASS" \
    "黃名帝國百科" \
    "${MW_ADMIN_USER:-admin}"
fi

ln -sf "$CONF_FILE" /var/www/html/LocalSettings.php
exec apache2-foreground
