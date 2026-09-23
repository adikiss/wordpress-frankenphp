FROM dunglas/frankenphp:1-php8.3-bookworm

# PHP extensions required by WordPress (imagick skipped: buggy with FrankenPHP threads)
RUN install-php-extensions mysqli gd zip intl exif opcache apcu

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Download WordPress core into a staging dir; the entrypoint copies it
# into the docroot volume on first run (docroot is a persistent volume).
RUN curl -fsSL https://wordpress.org/latest.tar.gz -o /tmp/wordpress.tar.gz \
    && mkdir -p /usr/src/wordpress \
    && tar -xzf /tmp/wordpress.tar.gz --strip-components=1 -C /usr/src/wordpress \
    && rm /tmp/wordpress.tar.gz

COPY php-wordpress.ini /usr/local/etc/php/conf.d/zz-wordpress.ini
COPY Caddyfile /etc/caddy/Caddyfile
COPY wp-config.php.template /usr/src/wp-config.php.template
COPY generate-wp-config.php /usr/local/bin/generate-wp-config.php
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV SERVER_NAME=:80

WORKDIR /app/public

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
