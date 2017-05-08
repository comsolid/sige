
FROM postgres:9.4.4

MAINTAINER Átila Camurça, Samir Coutinho

ENV POSTGRES_DB postgres
ENV POSTGRES_PASSWORD **secret**

ADD https://raw.githubusercontent.com/docker-library/healthcheck/master/postgres/docker-healthcheck /docker-healthcheck

RUN pg_createcluster 9.4 main

RUN chmod +x /docker-healthcheck

HEALTHCHECK CMD /docker-healthcheck
