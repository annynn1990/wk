FROM php:8.5-apache

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git unzip curl libicu-dev libonig-dev libxml2-dev libzip-dev \
       libpng-dev libjpeg62-turbo-dev libwebp-dev libfreetype6-dev \
       libsqlite3-dev libpq-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" intl mbstring xml zip gd mysqli pdo_mysql pdo_sqlite \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . /var/www/html/

RUN composer install --no-dev --optimize-autoloader --no-interaction \
    && mkdir -p /var/www/data /var/www/html/images \
    && chown -R www-data:www-data /var/www/data /var/www/html/images

COPY docker-entrypoint-wongming.sh /usr/local/bin/docker-entrypoint-wongming.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-wongming.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-wongming.sh"]
