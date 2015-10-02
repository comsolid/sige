
FROM postgres:9.4.4

MAINTAINER Átila Camurça, Samir Coutinho

ENV POSTGRES_DB postgres
ENV POSTGRES_PASSWORD **secret**

COPY docker-entrypoint-initdb.d/01-orcamento-production.sql /docker-entrypoint-initdb.d/01-orcamento-production.sql
# COPY docker-entrypoint-initdb.d/database.backup /docker-entrypoint-initdb.d/database.backup
# COPY docker-entrypoint-initdb.d/restore.sh /docker-entrypoint-initdb.d/restore.sh

RUN pg_createcluster 9.4 main
