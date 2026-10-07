FROM mediawiki:1.46.0

COPY docker-entrypoint-wongming.sh /usr/local/bin/docker-entrypoint-wongming.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-wongming.sh  && sed -i '/exec apache2-foreground/i chown -R www-data:www-data /var/www/data /var/www/html/images /var/www/html/LocalSettings.php 2>/dev/null || true' /usr/local/bin/docker-entrypoint-wongming.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-wongming.sh"]
