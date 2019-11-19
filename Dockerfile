FROM registry.query.consul:5000/ubuntu:xenial-20181218 AS unpacker

RUN apt-get update && apt-get install -y --no-install-recommends unzip && rm -rf /var/lib/apt/lists/*
WORKDIR /tmp
COPY packages/instantclient-basic-linux.x64-12.2.0.1.0.zip /tmp/
COPY packages/instantclient-sdk-linux.x64-12.2.0.1.0.zip /tmp/
RUN unzip instantclient-basic-linux.x64-12.2.0.1.0.zip -d /tmp/basic
RUN unzip instantclient-sdk-linux.x64-12.2.0.1.0.zip -d /tmp/sdk

FROM redash/redash:7.0.0.b18042
LABEL maintainer="Fedorov Andrey <andreiyf@halykbank.kz>"

USER root

RUN apt-get update && \
apt-get install -y --no-install-recommends libaio1 && \
rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/lib/oracle/12.2/client64/lib && mkdir -p /usr/include/oracle/12.2/client64/
COPY --from=unpacker /tmp/basic/instantclient_12_2/ /usr/lib/oracle/12.2/client64/lib/
COPY --from=unpacker /tmp/sdk/instantclient_12_2/sdk/include/ /usr/include/oracle/12.2/client64/

RUN ln -s /usr/lib/oracle/12.2/client64/lib/libclntsh.so.12.1 /usr/lib/oracle/12.2/client64/lib/libclntsh.so
RUN ln -s /usr/lib/oracle/12.2/client64/lib/libocci.so.12.1 /usr/lib/oracle/12.2/client64/lib/libocci.so

ENV LD_LIBRARY_PATH /usr/lib:/usr/local/lib:/usr/lib/oracle/12.2/client64/lib
ENV NLS_LANG AMERICAN_AMERICA.AL32UTF8

RUN pip install cx_Oracle==5.2.1
RUN pip install ldap3
USER redash
ENV REDASH_ADDITIONAL_QUERY_RUNNERS=redash.query_runner.oracle