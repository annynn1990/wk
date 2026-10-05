#!/bin/bash
set -e

DATA_DIR="/var/www/data"
CONF_FILE="/var/www/html/LocalSettings.php"
SERVER="${MW_SERVER:-http://localhost:8080}"

mkdir -p "$DATA_DIR" /var/www/html/images
chown -R www-data:www-data "$DATA_DIR" /var/www/html/images

if [ -f "$DATA_DIR/wikidb.sqlite" ]; then
  # Existing database: recreate configuration, then run upgrades.
  cat > "$CONF_FILE" <<'PHP'
<?php
$wgSitename = "黃名帝國百科";
$wgMetaNamespace = "黃名帝國百科";
$wgServer = getenv('MW_SERVER') ?: 'http://localhost:8080';
$wgScriptPath = "";
$wgLanguageCode = "zh-tw";
$wgLocaltimezone = "Asia/Taipei";
$wgDBtype = "sqlite";
$wgDBname = "/var/www/data/wikidb.sqlite";
$wgSecretKey = getenv('MW_SECRET_KEY') ?: 'wongming-empire-mediawiki-secret-2026';
$wgUpgradeKey = getenv('MW_UPGRADE_KEY') ?: 'wongming-upgrade-2026';
$wgEnableUploads = true;
PHP
  chown www-data:www-data "$CONF_FILE"
  php maintenance/run.php update --quick || true
else
  # First boot: let MediaWiki's installer create LocalSettings.php itself.
  rm -f "$CONF_FILE"
  : "${MW_ADMIN_PASS:?MW_ADMIN_PASS is required for first installation}"
  php maintenance/run.php install     --dbtype=sqlite     --dbpath="$DATA_DIR"     --dbname=wikidb     --confpath="/var/www/html"     --server="$SERVER"     --scriptpath=""     --lang=zh-tw     --pass="$MW_ADMIN_PASS"     "黃名帝國百科"     "${MW_ADMIN_USER:-admin}"
fi

exec apache2-foreground
