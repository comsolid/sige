FROM nmcteam/php56

MAINTAINER Átila Camurça, Samir Coutinho

COPY . /usr/share/nginx/html/site

WORKDIR /usr/share/nginx/html/site

RUN apt-get update && apt-get install -y git

RUN php -r "readfile('https://getcomposer.org/installer');" | php
RUN ["/bin/bash", "-c", "php composer.phar install"]
RUN mkdir -p application/cache/common
RUN chmod 777 application/cache/common
RUN mkdir -p library/HTMLPurifier/DefinitionCache/Serializer
RUN chmod 777 library/HTMLPurifier/DefinitionCache/Serializer
RUN mkdir -p public/captcha
RUN chmod 777 public/captcha
VOLUME /usr/share/nginx/html/site/application/cache/common
VOLUME /usr/share/nginx/html/site/library/HTMLPurifier/DefinitionCache/Serializer
VOLUME /usr/share/nginx/html/site/public/captcha

RUN mkdir -p vendor/mpdf/mpdf/ttfontdata/
RUN chmod 777 vendor/mpdf/mpdf/ttfontdata/
RUN mkdir -p vendor/mpdf/mpdf/tmp/
RUN chmod 777 vendor/mpdf/mpdf/tmp/
RUN mkdir -p vendor/mpdf/mpdf/graph_cache/
RUN chmod 777 vendor/mpdf/mpdf/graph_cache/

VOLUME /usr/share/nginx/html/site/vendor
