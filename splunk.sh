#!/usr/bin/env bash

which -a "splunk" || exit 9

until test -e "${SPLUNK_HOME}/etc/system/local"; do
	sleep 1;
done

tee /dev/stderr "${SPLUNK_HOME}/etc/system/local/user-seed.conf" <<-EOF
	[user_info]
	USERNAME = ${SPLUNK_USER}
	PASSWORD = ${SPLUNK_PASS}
EOF

#chown -R "${SPLUNK_USER}:${SPLUNK_GROUP}" "${SPLUNK_HOME}"

splunk start \
	--accept-license \
	--answer-yes \
	--auto-ports \
	--no-prompt \
	#--gen-and-print-passwd

splunk add forward-server splunk:9997 \
	-auth "${SPLUNK_USER}:${SPLUNK_PASS}"

splunk add monitor "${CONFLUENT_ROOT}/logs" \
	-auth "${SPLUNK_USER}:${SPLUNK_PASS}"

splunk add monitor "/var/log" \
	-auth "${SPLUNK_USER}:${SPLUNK_PASS}"
