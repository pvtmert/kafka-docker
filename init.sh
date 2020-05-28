#!/usr/bin/env bash

#ID="${2}"
DNS="${1}"
DIG="$(which dig)"
INIT=".init.kafka"
#FQDN=$(hostname -f)

: ${DNS:?name is required}
IP=$(hostname -i)
ID=$(  "${DIG}" +short    "${DNS}" | sort -Vr | grep -n "${IP}" | cut -d: -f1 | head -1)
FQDN=$("${DIG}" +short -x "${IP}"  | grep -v '^;;' || hostname -f)

: ${ID?of broker is necessary}
: ${DNS?host is necessary}
: ${CONFLUENT_ROOT?is missing}
: ${CONFLUENT_DATA?is missing}
: ${DIG?is required to discover hosts}

#FQDN="${FQDN%%.}"
PEERS=( $("${DIG}" +short "${DNS}" | sort -Vr) )

#JOLOKIA_PATH=/opt/jolokia/jolokia.jar
#test -e "${JOLOKIA_PATH}" || {
#	JOLOKIA_URL=https://github.com/rhuss/jolokia/releases/download/v1.6.2/jolokia-1.6.2-bin.tar.gz
#	JOLOKIA_DIR="$(dirname "${JOLOKIA_PATH}")"
#	mkdir -p "${JOLOKIA_DIR}"
#	curl -#L "${JOLOKIA_URL}" | tar -C "${JOLOKIA_DIR}" -vxz
#}

export KAFKA_OPTS="-javaagent:${JOLOKIA_PATH}=port=8778,host=0.0.0.0"

function start {
	trap "killall java" SIGINT SIGTERM
	"zookeeper-server-start" "${CONFLUENT_ROOT}/etc/kafka/zookeeper.properties" || exit &
	"kafka-server-start"     "${CONFLUENT_ROOT}/etc/kafka/server.properties"    || exit &
	"${DIG}" +short -x "${IP}" | printf "My PTR  is: %s\n" "$(cat)"
	hostname -A                | printf "My FQDN is: %s\n" "$(cat)"
	test -e "${SPLUNK_HOME}" \
		&& runuser -p splunk -c "${SHELL} $(realpath ./splunk.sh)" \
		| tee -a /tmp/splunk.log
	wait
}

test -e "${INIT}" && {
	start
	exit
} || touch "${INIT}"

mkdir -p "${CONFLUENT_DATA}"
echo "${ID:-0}" | tee "${CONFLUENT_DATA}/myid"

tee "${CONFLUENT_ROOT}/etc/kafka/zookeeper.properties" <<EOF
dataDir=${CONFLUENT_DATA}
tickTime=2000
initLimit=50
syncLimit=20
clientPort=2181
autopurge.snapRetainCount=3
autopurge.purgeInterval=24
##server.0=0.0.0.0:2888:3888
EOF

for ip in "${PEERS[@]}"; do
	echo "server.$((++counter))=${ip}:2888:3888"
done \
| sed "s:${IP}:0.0.0.0:g" \
| tee -a "${CONFLUENT_ROOT}/etc/kafka/zookeeper.properties"
unset counter

#echo "--------"
#cat "${CONFLUENT_ROOT}/etc/kafka/zookeeper.properties"
#echo "--------"

tee -a "${CONFLUENT_ROOT}/etc/kafka/server.properties" <<EOF
advertised.listeners=PLAINTEXT://${IP}:9092
zookeeper.connect=${FQDN%%.}:2181
#broker.id.generation.enable=true
broker.id=${ID:-0}
EOF

start
exit
