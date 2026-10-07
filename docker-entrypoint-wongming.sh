#!/bin/bash
set -e

CONF_FILE="/var/www/html/LocalSettings.php"
DATA_DIR="/var/www/data"
SERVER="${MW_SERVER:-https://wongming-encyclopedia.onrender.com}"
ADMIN_USER="${MW_ADMIN_USER:-admin}"
ADMIN_PASS="${MW_ADMIN_PASS:-Wongming-Admin-2026}"

mkdir -p "$DATA_DIR" /var/www/html/images
chown -R www-data:www-data "$DATA_DIR" /var/www/html/images

# Rebuild LocalSettings.php from the real SQLite database when the existing
# config is missing or has invalid PHP syntax.
if [ -f "$CONF_FILE" ]; then
  if ! php -l "$CONF_FILE" >/dev/null 2>&1; then
    rm -f "$CONF_FILE"
  fi
fi

if [ ! -f "$CONF_FILE" ]; then
  if [ ! -f "$DATA_DIR/wikidb.sqlite" ]; then
    php maintenance/run.php install       --dbtype=sqlite       --dbpath="$DATA_DIR"       --confpath="/var/www/html"       --server="$SERVER"       --scriptpath=""       --lang=zh-tw       --pass="$ADMIN_PASS"       "黃名帝國百科"       "$ADMIN_USER"
  else
    php maintenance/run.php install       --dbtype=sqlite       --dbpath="$DATA_DIR"       --confpath="/var/www/html"       --server="$SERVER"       --scriptpath=""       --lang=zh-tw       --pass="$ADMIN_PASS"       "黃名帝國百科"       "$ADMIN_USER"
  fi
fi

# Ensure the requested logo is present exactly once and remains valid PHP.
sed -i '/^[[:space:]]*\$wgLogo[[:space:]]*=/d' "$CONF_FILE"
cat >> "$CONF_FILE" <<'PHPLOGO'
$wgLogos = [
    '1x' => 'https://www.wongmingempire.com/bbswm/data/attachment/forum/202102/20/012657b8fiibi8irgzkl2g.png',
    'icon' => 'https://www.wongmingempire.com/bbswm/data/attachment/forum/202102/20/012657b8fiibi8irgzkl2g.png',
];
PHPLOGO

php -l "$CONF_FILE"

chown www-data:www-data "$CONF_FILE"
chown -R www-data:www-data "$DATA_DIR" /var/www/html/images
exec apache2-foreground
