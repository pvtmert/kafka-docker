#!/usr/bin/env bash

#ID="${2}"
DNS="${1}"
DIG="$(which dig)"
INIT=".init.kafka"
FQDN=$(hostname -f)

: ${DNS:?name is required}
IP=$(hostname -i)
ID=$(dig +short "${DNS}" | sort -Vr | grep -n "${IP}" | cut -d: -f1 | head -1)
FQDN=$(dig +short -x "${IP}")

: ${ID?of broker is necessary}
: ${DNS?host is necessary}
: ${CONFLUENT_HOME?is missing}
: ${CONFLUENT_DATA?is missing}
: ${DIG?is required to discover hosts}

FQDN=${FQDN%%.}

function start {
	"zookeeper-server-start" ${CONFLUENT_HOME}/etc/kafka/zookeeper.properties || exit &
	"kafka-server-start"     ${CONFLUENT_HOME}/etc/kafka/server.properties    || exit &
	dig +short -x "${IP}" | printf "My PTR  is: %s\n" "$(cat)"
	hostname -A           | printf "My FQDN is: %s\n" "$(cat)"
	wait
}

test -e "${INIT}" && {
	start
	exit
}

touch "${INIT}"

mkdir -p "${CONFLUENT_DATA}"
echo "${ID:-0}" | tee "${CONFLUENT_DATA}/myid"

tee "${CONFLUENT_HOME}/etc/kafka/zookeeper.properties" <<EOF
dataDir=${CONFLUENT_DATA}
tickTime=2000
initLimit=50
syncLimit=20
clientPort=2181
autopurge.snapRetainCount=3
autopurge.purgeInterval=24
#server.0=0.0.0.0:2888:3888
EOF

for ip in $("${DIG}" +short "${DNS}" | sort -Vr); do
	echo "server.$((++counter))=${ip}:2888:3888"
done \
| sed "s:${IP}:0.0.0.0:g" \
| tee -a "${CONFLUENT_HOME}/etc/kafka/zookeeper.properties"
unset counter

#echo "--------"
#cat "${CONFLUENT_HOME}/etc/kafka/zookeeper.properties"
#echo "--------"

tee -a "${CONFLUENT_HOME}/etc/kafka/server.properties" <<EOF
advertised.listeners=PLAINTEXT://${IP}:9092
zookeeper.connect=${FQDN}:2181
broker.id=${ID:-0}
EOF

start
exit
