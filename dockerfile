#!/usr/bin/env -S docker build --compress -t pvtmert/confluent -f

FROM centos:7

RUN yum install -y bind-utils net-tools which

# https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz

ENV JAVA_HOME="/usr/java"
RUN mkdir -p "${JAVA_HOME}"; \
	curl -#L "https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz" \
	| tar --strip=1 -zxC "${JAVA_HOME}"

ENV CONFLUENT_ROOT="/home/confluent"
RUN mkdir -p "${CONFLUENT_ROOT}" ; \
	curl -#L "https://packages.confluent.io/archive/5.3/confluent-community-5.3.2-2.12.tar.gz" \
	| tar --strip=1 -zxC "${CONFLUENT_ROOT}"

ARG JOLOKIA_VER="1.6.2"
ARG JOLOKIA_DIR="/opt/jolokia"
ENV JOLOKIA_PATH="${JOLOKIA_DIR}/jolokia-jvm-${JOLOKIA_VER}-agent.jar"
RUN mkdir -p "${JOLOKIA_DIR}" ; \
	curl -#L "https://github.com/rhuss/jolokia/releases/download/v${JOLOKIA_VER}/jolokia-${JOLOKIA_VER}-bin.tar.gz" \
	| tar --strip=1 -xzC "${JOLOKIA_DIR}" ; \
	curl -#Lo "${JOLOKIA_PATH}" \
	"https://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/${JOLOKIA_VER}/jolokia-jvm-${JOLOKIA_VER}-agent.jar"

# wget -O splunkforwarder-8.0.4-767223ac207f-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.0.4&product=universalforwarder&filename=splunkforwarder-8.0.4-767223ac207f-Linux-x86_64.tgz&wget=true'

ARG SPLUNK_VER=7.2.10.1-40b15aa1f501
ENV SPLUNK_HOME=/opt/splunkforwarder
RUN curl -#L "https://www.splunk.com/page/download_track?file=${SPLUNK_VER%%-*}/linux/splunkforwarder-${SPLUNK_VER}-Linux-$(uname -m).tgz&ac=&wget=true&name=wget&platform=Linux&architecture=$(uname -m)&version=${SPLUNK_VER%%-*}&product=universalforwarder&typed=release" \
	| tar -xzC /opt

RUN ln -sf "${SPLUNK_HOME}/bin/splunk" "/usr/local/bin/"

ENV SPLUNK_USER=splunk
ENV SPLUNK_PASS=password
RUN useradd -MNro \
	-d /opt/splunkforwarder \
	-g daemon \
	-u 10777 \
	"${SPLUNK_USER}"
RUN passwd -f -d "${SPLUNK_USER}"
RUN passwd -f -u "${SPLUNK_USER}"
RUN chpasswd <<< "${SPLUNK_USER}:${SPLUNK_PASS}"

ENV CONFLUENT_DATA="${CONFLUENT_ROOT}/data"
ENV PATH="${PATH}:${JAVA_HOME}/bin:${CONFLUENT_ROOT}/bin"
COPY \
	splunk.sh \
	init.sh \
	./
ENTRYPOINT [ "bash",  "init.sh" ]
CMD [ ]

EXPOSE \
	2181 \
	2888 \
	3888 \
	9092 \
	8778 \
