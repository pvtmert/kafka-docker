#!/usr/bin/env -S docker build --compress -t pvtmert/confluent -f

FROM centos:7

# https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz

ENV JAVA_HOME="/usr/java"
RUN mkdir -p "${JAVA_HOME}"; \
	curl -#L "https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz" \
	| tar --strip=1 -zxC "${JAVA_HOME}"

ENV CONFLUENT_ROOT="/home/confluent"
RUN mkdir -p "${CONFLUENT_ROOT}" ; \
	curl -#L "https://packages.confluent.io/archive/5.3/confluent-community-5.3.2-2.12.tar.gz" \
	| tar --strip=1 -zxC "${CONFLUENT_ROOT}"

ENV CONFLUENT_DATA="${CONFLUENT_ROOT}/data"
ENV PATH "${PATH}:${JAVA_HOME}/bin:${CONFLUENT_ROOT}/bin"
RUN yum install -y bind-utils net-tools which
COPY init.sh init.sh
ENTRYPOINT [ "bash",  "init.sh" ]
CMD [ ]

EXPOSE \
	2181 \
	2888 \
	3888 \
	9092 \
