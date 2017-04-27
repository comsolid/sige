#!/bin/sh

set -e

PERM=777

composer.phar --no-interaction install

mkdir -p application/cache/common
chmod ${PERM} application/cache/common
mkdir -p library/HTMLPurifier/DefinitionCache/Serializer
chmod ${PERM} library/HTMLPurifier/DefinitionCache/Serializer
mkdir -p public/captcha
chmod ${PERM} public/captcha

mkdir -p vendor/mpdf/mpdf/ttfontdata/
chmod ${PERM} vendor/mpdf/mpdf/ttfontdata/
mkdir -p vendor/mpdf/mpdf/tmp/
chmod ${PERM} vendor/mpdf/mpdf/tmp/
mkdir -p vendor/mpdf/mpdf/graph_cache/
chmod ${PERM} vendor/mpdf/mpdf/graph_cache/

docker-php-entrypoint $@

php-fpm --nodaemonize
