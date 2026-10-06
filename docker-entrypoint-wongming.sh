#!/bin/bash
set -e
mkdir -p /var/www/data /var/www/html/images
chown -R www-data:www-data /var/www/data /var/www/html/images
if [ ! -f /var/www/html/LocalSettings.php ] || [ ! -f /var/www/data/wikidb.sqlite ]; then
 rm -f /var/www/html/LocalSettings.php /var/www/data/wikidb.sqlite
 php maintenance/run.php install --dbtype=sqlite --dbpath=/var/www/data --confpath=/var/www/html --server="${MW_SERVER:-https://wongming-encyclopedia.onrender.com}" --scriptpath="" --lang=zh-tw --pass="${MW_ADMIN_PASS}" "黃名帝國百科" "${MW_ADMIN_USER:-admin}"
else
 php maintenance/run.php update --quick
fi
chown www-data:www-data /var/www/html/LocalSettings.php
exec apache2-foreground
