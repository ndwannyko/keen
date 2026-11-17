FROM composer:2 AS vendor

WORKDIR /app

COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --no-interaction \
    --no-progress \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

COPY . .

RUN composer dump-autoload --optimize --no-scripts --no-dev \
    && rm -f bootstrap/cache/packages.php bootstrap/cache/services.php \
    && php artisan package:discover --no-interaction


FROM php:8.2-cli-alpine

RUN for i in 1 2 3; do apk add --no-cache bash libpq libpng libjpeg-turbo freetype && break || sleep 5; done \
    && for i in 1 2 3; do apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS postgresql-dev sqlite-dev libpng-dev libjpeg-turbo-dev freetype-dev && break || sleep 5; done \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" pdo_pgsql pdo_sqlite gd opcache \
    && apk del .build-deps

COPY --from=vendor /app /var/www/html

WORKDIR /var/www/html

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p storage/app/public storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr \
    PHP_CLI_SERVER_WORKERS=4 \
    PORT=8080

EXPOSE 8080

CMD ["/usr/local/bin/entrypoint.sh"]
