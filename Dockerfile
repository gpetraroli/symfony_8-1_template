FROM php:8.4-fpm AS php_upstream
FROM composer/composer:2-bin AS composer_upstream
FROM caddy:2.7.6-alpine AS caddy_upstream

# =====================================================================
# PHP BASE IMAGE ======================================================

FROM php_upstream AS php_base

# Install php extensions using docker-php-extension-installer from github.com/mlocati
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions
RUN install-php-extensions \
    intl \
    opcache \
    zip \
    pdo \
    pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

# install composer
COPY --from=composer_upstream --link /composer /usr/bin/composer

# RUN apt update

WORKDIR /var/www/app

EXPOSE 9000

# =====================================================================
# PHP DEV IMAGE =======================================================

FROM php_base AS php_dev

ENTRYPOINT ["/var/www/app/docker/entrypoint.dev.sh"]

# =====================================================================
# PHP PROD IMAGE ======================================================

FROM php_base AS php_prod

# copy project
COPY . .

RUN composer install --prefer-dist --no-progress --no-interaction

RUN php ./bin/console importmap:install

RUN ./bin/console sass:build

RUN chmod +x /var/www/app/docker/entrypoint.prod.sh

ENTRYPOINT ["/var/www/app/docker/entrypoint.prod.sh"]

# =====================================================================
# CADDY IMAGE =========================================================

FROM caddy_upstream AS caddy

# copy caddy config
COPY docker/Caddyfile /etc/caddy/Caddyfile

# copy project
COPY . /var/www/app/

EXPOSE 80 443
