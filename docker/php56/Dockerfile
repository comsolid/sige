FROM php:5.6-fpm-alpine

MAINTAINER Átila Camurça, Samir Coutinho

RUN set -xe && \
  apk add --no-cache --virtual .persistent-deps \
    # for gd extension
    gd-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    freetype \
    freetype-dev \
    # for intl extension
    icu-dev \
    gettext-dev \
    # for mcrypt extension
    libmcrypt-dev \
    # for SSL certificate
    openssl \
    # for postgres
    postgresql-dev \
    git

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
  docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/freetype/ \
    --with-png-dir=/usr/include/libpng16/ \
    --with-jpeg-dir=/usr/include/

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

COPY ./php.ini $PHP_INI_DIR/conf.d/sige.conf

COPY ./gen-ssl-certificate.sh /
COPY ./docker-sige-php-entrypoint.sh /

ENTRYPOINT ["/docker-sige-php-entrypoint.sh"]

# Allow Composer to be run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

################################################################################
# Health check                                                                 #
################################################################################

RUN apk add --no-cache fcgi

HEALTHCHECK --interval=30s --timeout=3s \
    CMD \
    SCRIPT_NAME=/ping \
    SCRIPT_FILENAME=/ping \
    REQUEST_METHOD=GET \
    cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1
