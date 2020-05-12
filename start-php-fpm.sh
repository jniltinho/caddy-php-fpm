#!/bin/bash

chown -Rf www-data:www-data /var/www

rm -f /var/run/php/php${PHP_VERSION}-fpm.sock
/usr/sbin/php-fpm${PHP_VERSION} --nodaemonize --fpm-config=/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
