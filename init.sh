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

function start {
	trap "killall java" SIGINT SIGTERM
	LOG_DIR="${ZOOKEEPER_LOG_DIR}" "zookeeper-server-start" "${CONFLUENT_ROOT}/etc/kafka/zookeeper.properties" || exit &
	LOG_DIR="${KAFKA_LOG_DIR}"     "kafka-server-start"     "${CONFLUENT_ROOT}/etc/kafka/server.properties"    || exit &
	"${DIG}" +short -x "${IP}" | printf "My PTR  is: %s\n" "$(cat)"
	hostname -A                | printf "My FQDN is: %s\n" "$(cat)"
	test -e "${SPLUNK_HOME}" && which -a splunk && {
		splunk start \
			--accept-license \
			--answer-yes \
			--auto-ports \
			--no-prompt \
			#--gen-and-print-passwd
		splunk add forward-server splunk:9997 \
			-auth "${SPLUNK_USER}:${SPLUNK_PASS}"
		splunk set deploy-poll splunk:8089 \
			-auth "${SPLUNK_USER}:${SPLUNK_PASS}"
		splunk add monitor "${CONFLUENT_ROOT}/logs/*.log" \
			-auth "${SPLUNK_USER}:${SPLUNK_PASS}"
	} &> /tmp/splunk.log
	wait
}

for dir in "${LOG_DIR_BASE}" "${KAFKA_LOG_DIR}" "${ZOOKEEPER_LOG_DIR}"; do
	test -e "${dir}" || mkdir -p "${dir}"
done

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
controlled.shutdown.enable=true
advertised.listeners=PLAINTEXT://${IP}:9092
zookeeper.connect=${FQDN%%.}:2181
#broker.id.generation.enable=true
broker.id=${ID:-0}
EOF

start
exit
