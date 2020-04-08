FROM ubuntu:18.04

LABEL maintainer="Nilton Oliveira jniltinho@gmail.com"

ENV TZ America/Sao_Paulo

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive
ENV php_conf /etc/php/7.4/fpm/php.ini
ENV fpm_conf /etc/php/7.4/fpm/pool.d/www.conf

# Install Basic Requirements
RUN buildDeps='gcc make autoconf libc-dev zlib1g-dev pkg-config' \
    && set -x \
    && apt-get update \
    && apt-get install --no-install-recommends $buildDeps --no-install-suggests -q -y gnupg2 dirmngr apt-transport-https lsb-release ca-certificates \
    software-properties-common curl \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -q -y \
            apt-utils zip unzip git  libmemcached-dev \
            libmemcached11 libmagickwand-dev \
            php7.4-fpm php7.4-cli php7.4-bcmath \
            php7.4-dev php7.4-common php7.4-json \
            php7.4-opcache php7.4-readline php7.4-mbstring \
            php7.4-curl php7.4-gd php7.4-mysql php7.4-zip \
            php7.4-pgsql php7.4-intl php7.4-xml \
            php-pear \
    && mkdir -p /tmp/pear/cache \ 
    && pecl channel-update pecl.php.net \
    && pecl -d php_suffix=7.4 install -o -f redis memcached imagick \
    && mkdir -p /run/php \
    && sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} \
    && sed -i -e "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" ${php_conf} \
    && sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} \
    && sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} \
    && sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} \
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.4/fpm/php-fpm.conf \
    && sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_children = 5/pm.max_children = 4/g" ${fpm_conf} \
    && sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" ${fpm_conf} \
    && sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" ${fpm_conf} \
    && sed -i -e "s/^;clear_env = no$/clear_env = no/" ${fpm_conf} \
    && echo "extension=redis.so" > /etc/php/7.4/mods-available/redis.ini \
    && echo "extension=memcached.so" > /etc/php/7.4/mods-available/memcached.ini \
    && echo "extension=imagick.so" > /etc/php/7.4/mods-available/imagick.ini \
    && ln -sf /etc/php/7.4/mods-available/redis.ini /etc/php/7.4/fpm/conf.d/20-redis.ini \
    && ln -sf /etc/php/7.4/mods-available/redis.ini /etc/php/7.4/cli/conf.d/20-redis.ini \
    && ln -sf /etc/php/7.4/mods-available/memcached.ini /etc/php/7.4/fpm/conf.d/20-memcached.ini \
    && ln -sf /etc/php/7.4/mods-available/memcached.ini /etc/php/7.4/cli/conf.d/20-memcached.ini \
    && ln -sf /etc/php/7.4/mods-available/imagick.ini /etc/php/7.4/fpm/conf.d/20-imagick.ini \
    && ln -sf /etc/php/7.4/mods-available/imagick.ini /etc/php/7.4/cli/conf.d/20-imagick.ini

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install golang supervisord - https://github.com/ochinchina/supervisord
ADD https://github.com/ochinchina/supervisord/releases/download/v0.6.3/supervisord_0.6.3_linux_amd64 /usr/local/bin/supervisord

# Clean up
RUN apt-get purge -y --auto-remove $buildDeps

RUN apt-get update && apt-get install -qy goaccess nginx \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archive/*.deb

# Supervisor config
ADD ./supervisor.conf /etc/supervisor.conf

# Override nginx's default config
COPY ./default.conf /etc/nginx/sites-available/default

# Override default nginx welcome page
COPY html /usr/share/nginx/html

ADD ./run_goaccess /usr/local/bin/run_goaccess

# Add Scripts
ADD ./start.sh /start.sh
RUN chmod +x /start.sh /usr/local/bin/supervisord

WORKDIR /usr/share/nginx/

EXPOSE 80

CMD ["/start.sh"]
