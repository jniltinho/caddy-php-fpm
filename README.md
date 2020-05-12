# Ubuntu + Caddy + PHP-FPM 7.4

Caddy + PHP-FPM 7.4 + Composer built on Ubuntu 18.04 (Bionic) image for Laravel and PHP Projects

## Introduction

This is a Dockerfile to build a ubuntu based container image running nginx and php-fpm 7.4.x & Composer.

### Versioning

| Docker Tag | GitHub Release | Caddy Version | PHP Version | Ubuntu Version |
|-----|-------|-----|--------|--------|
| latest | master Branch |2 | 7.4.3 | bionic |
| php73 | php73 Branch |2 | 7.3.15 | bionic |
| php72 | php72 Branch |2 | 7.2.28 | bionic |

## Building from source

To build from source you need to clone the git repo and run docker build:

```bash
git clone https://github.com/jniltinho/nginx-php-fpm.git
cd nginx-php-fpm
```

followed by

```bash
docker build --no-cache -t nginx-php-fpm:latest . # PHP 7.4.x
```

or

```bash
docker build --no-cache -t nginx-php-fpm:php74 . # PHP 7.4.x
```

## Pulling from Docker Hub

```bash
docker pull jniltinho/nginx-php-fpm:latest
```

## Running

To run the container:

```bash
docker run -d -p 8080:80 jniltinho/nginx-php-fpm

## Laravel
docker run --rm -it -p 8080:80 -v $PWD:/usr/share/nginx jniltinho/nginx-php-fpm /bin/bash
```

Default web root:

```bahs
/usr/share/nginx/html
```
