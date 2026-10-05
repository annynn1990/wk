#!/bin/bash
set -e

DATA_DIR="/var/www/data"
CONF_FILE="$DATA_DIR/LocalSettings.php"
mkdir -p "$DATA_DIR" /var/www/html/images
chown -R www-data:www-data "$DATA_DIR" /var/www/html/images

if [ ! -f "$CONF_FILE" ]; then
  : "${MW_ADMIN_PASS:?MW_ADMIN_PASS is required on first startup}"
  SERVER="${MW_SERVER:-http://localhost:8080}"

  if [ -n "${DATABASE_URL:-}" ]; then
    eval "$(
      php -r '
        $u = parse_url(getenv("DATABASE_URL"));
        echo "export MW_DBTYPE=postgresql\n";
        echo "export MW_DBHOST=" . escapeshellarg($u["host"] ?? "") . "\n";
        echo "export MW_DBPORT=" . escapeshellarg((string)($u["port"] ?? 5432)) . "\n";
        echo "export MW_DBUSER=" . escapeshellarg($u["user"] ?? "") . "\n";
        echo "export MW_DBPASS=" . escapeshellarg($u["pass"] ?? "") . "\n";
        echo "export MW_DBNAME=" . escapeshellarg(ltrim($u["path"] ?? "", "/")) . "\n";
      '
    )"
  else
    export MW_DBTYPE=sqlite
    export MW_DBPATH="$DATA_DIR"
  fi

  if [ "${MW_DBTYPE}" = "postgresql" ]; then
    php maintenance/run.php install       --dbtype=postgres       --dbserver="${MW_DBHOST}:${MW_DBPORT}"       --dbuser="${MW_DBUSER}"       --dbpass="${MW_DBPASS}"       --dbname="${MW_DBNAME}"       --confpath="$DATA_DIR"       --server="$SERVER"       --scriptpath=""       --lang=zh-tw       --pass="$MW_ADMIN_PASS"       "黃名帝國百科"       "${MW_ADMIN_USER:-admin}"
  else
    php maintenance/run.php install       --dbtype=sqlite       --dbpath="$DATA_DIR"       --dbname=wikidb       --confpath="$DATA_DIR"       --server="$SERVER"       --scriptpath=""       --lang=zh-tw       --pass="$MW_ADMIN_PASS"       "黃名帝國百科"       "${MW_ADMIN_USER:-admin}"
  fi
fi

ln -sf "$CONF_FILE" /var/www/html/LocalSettings.php
exec apache2-foreground
