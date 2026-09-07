#!/bin/sh

mkdir -p /var/www/app/var/cache /var/www/app/var/log /var/www/app/var/share

composer dump-env prod

php ./bin/console d:m:m --no-interaction

chown -R www-data:www-data /var/www/app/var

php-fpm
