#!/bin/bash

rm -f /var/run/php/php7.4-fpm.sock
/usr/sbin/php-fpm7.4 --nodaemonize --fpm-config=/etc/php/7.4/fpm/pool.d/www.conf
