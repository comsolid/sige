FROM php:5.6-fpm-alpine

MAINTAINER Átila Camurça, Samir Coutinho

RUN set -xe && \
  apk add --no-cache --virtual .persistent-deps \
    # for gd extension
    gd-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    # for intl extension
    icu-dev \
    gettext-dev \
    # for mcrypt extension
    libmcrypt-dev \
    # for SSL certificate
    openssl \
    # for postgres
    postgresql-dev

RUN set -xe && \
  apk add --no-cache --virtual .build-deps \
    autoconf \
    curl \
    g++ \
    make

RUN set -xe && \
  # install xdebug
  pecl install xdebug && \
  docker-php-ext-enable xdebug

RUN set -xe && \
  docker-php-ext-install \
    intl \
    gd \
    gettext \
    mcrypt \
    pdo \
    pdo_pgsql

RUN set -xe && \
  # install composer
  curl -Lq \
    https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer \
    | php -- --quiet --install-dir=/usr/local/bin/

RUN set -xe && \
  # clean
  apk del .build-deps && \
  rm -rf /tmp/* /var/cache/apk/*

# COPY ./php-fpm.conf /.../conf.d/sige-php-fpm.conf
COPY ./php.ini $PHP_INI_DIR/conf.d/sige.conf

COPY ./gen-ssl-certificate.sh /
COPY ./docker-sige-php-entrypoint.sh /

ENTRYPOINT ["/docker-sige-php-entrypoint.sh"]
