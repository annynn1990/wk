FROM mediawiki:1.46.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq-dev \
    && docker-php-ext-install pdo_pgsql pgsql \
    && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint-wongming.sh /usr/local/bin/docker-entrypoint-wongming.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-wongming.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-wongming.sh"]
