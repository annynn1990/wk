FROM mediawiki:latest

WORKDIR /var/www/html

COPY . /var/www/html/

RUN if [ -f composer.json ]; then composer install --no-dev --optimize-autoloader --no-interaction; fi \
    && mkdir -p /var/www/data /var/www/html/images \
    && chown -R www-data:www-data /var/www/data /var/www/html/images

COPY docker-entrypoint-wongming.sh /usr/local/bin/docker-entrypoint-wongming.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-wongming.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-wongming.sh"]
