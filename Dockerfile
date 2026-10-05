FROM mediawiki:1.46.0

COPY docker-entrypoint-wongming.sh /usr/local/bin/docker-entrypoint-wongming.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-wongming.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint-wongming.sh"]
