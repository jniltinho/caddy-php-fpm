FROM ubuntu:18.04

LABEL maintainer="Nilton Oliveira jniltinho@gmail.com"

ENV TZ America/Sao_Paulo

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive
ENV php_conf /etc/php/7.2/fpm/php.ini
ENV fpm_conf /etc/php/7.2/fpm/pool.d/www.conf
ENV PHP_VERSION 7.2

# Install Basic Requirements
RUN buildDeps='gcc make autoconf libc-dev zlib1g-dev pkg-config' \
    && set -x \
    && apt-get update \
    && apt-get install --no-install-recommends $buildDeps --no-install-suggests -q -y gnupg2 dirmngr apt-transport-https lsb-release ca-certificates \
    software-properties-common curl wget \
    && apt-get install --no-install-recommends --no-install-suggests -q -y \
    && curl gcc make autoconf libc-dev zlib1g-dev pkg-config \
    && apt-utils zip unzip git libmemcached-dev \
    && libmemcached11 libmagickwand-dev php7.2-fpm php7.2-cli php7.2-bcmath \
    && php7.2-dev php7.2-common php7.2-json php7.2-opcache \
    && php7.2-readline php7.2-mbstring php7.2-curl php7.2-gd php7.2-mysql \
    && php7.2-zip php7.2-intl php7.2-xml php-pear \
    && mkdir -p /tmp/pear/cache /run/php \
    && pecl channel-update pecl.php.net \
    && pecl -d php_suffix=${PHP_VERSION} install -o -f redis memcached imagick \
    && sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} \
    && sed -i "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" ${php_conf} \
    && sed -i "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} \
    && sed -i "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} \
    && sed -i "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} \
    && sed -i "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} \
    && sed -i "s/pm.max_children = 5/pm.max_children = 4/g" ${fpm_conf} \
    && sed -i "s/pm.start_servers = 2/pm.start_servers = 3/g" ${fpm_conf} \
    && sed -i "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${fpm_conf} \
    && sed -i "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${fpm_conf} \
    && sed -i "s/pm.max_requests = 500/pm.max_requests = 200/g" ${fpm_conf} \
    && sed -i "s/^;clear_env = no$/clear_env = no/" ${fpm_conf} \
    && echo "extension=redis.so" > /etc/php/${PHP_VERSION}/mods-available/redis.ini \
    && echo "extension=memcached.so" > /etc/php/${PHP_VERSION}/mods-available/memcached.ini \
    && echo "extension=imagick.so" > /etc/php/${PHP_VERSION}/mods-available/imagick.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/redis.ini /etc/php/${PHP_VERSION}/fpm/conf.d/20-redis.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/redis.ini /etc/php/${PHP_VERSION}/cli/conf.d/20-redis.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/memcached.ini /etc/php/${PHP_VERSION}/fpm/conf.d/20-memcached.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/memcached.ini /etc/php/${PHP_VERSION}/cli/conf.d/20-memcached.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/imagick.ini /etc/php/${PHP_VERSION}/fpm/conf.d/20-imagick.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/imagick.ini /etc/php/${PHP_VERSION}/cli/conf.d/20-imagick.ini


# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN wget https://github.com/caddyserver/caddy/releases/download/v2.0.0/caddy_2.0.0_linux_amd64.tar.gz \
    && tar -xvf caddy_2.0.0_linux_amd64.tar.gz \
    && rm -f LICENSE README.md caddy_2.0.0_linux_amd64.tar.gz \
    && mv caddy /usr/bin/ && mkdir -p  /etc/caddy/conf.d \
    && echo 'import /etc/caddy/conf.d/*.conf' >/etc/caddy/Caddyfile \
    && mkdir -p /var/www/app/public \
    && echo 'Hello, World!, Caddy v2 WebServer' >> /var/www/app/public/index.html

# Install golang supervisord - https://github.com/ochinchina/supervisord
ADD https://github.com/ochinchina/supervisord/releases/download/v0.6.3/supervisord_0.6.3_linux_amd64 /usr/local/bin/supervisord

# Clean up
RUN apt-get purge -y --auto-remove $buildDeps \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archive/*.deb

# Supervisor config
ADD ./supervisor.conf /etc/supervisor.conf
COPY ./start-php-fpm.sh /usr/local/bin/start-php-fpm.sh

# Override nginx's default config
COPY ./default.conf /etc/caddy/conf.d/default.conf
#ADD ./run_goaccess /usr/local/bin/run_goaccess

# Add Scripts
RUN chmod +x /usr/local/bin/supervisord

WORKDIR /var/www
EXPOSE 80

CMD ["/usr/local/bin/supervisord", "-c",  "/etc/supervisor.conf"]
