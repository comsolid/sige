
FROM postgres:9.4.4

MAINTAINER Átila Camurça, Samir Coutinho

ENV POSTGRES_DB postgres
ENV POSTGRES_PASSWORD **secret**

COPY ../../docs/INSTALACAO/ddl-schema.sql /docker-entrypoint-initdb.d/01-ddl-schema.sql

RUN pg_createcluster 9.4 main
