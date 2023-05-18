#!/usr/bin/env bash

mkdir -p /app/vendor/stunnel/var/run/stunnel/

cat > /app/vendor/stunnel/stunnel.conf << EOFEOF
foreground = yes

pid = /app/vendor/stunnel/stunnel4.pid

socket = r:TCP_NODELAY=1
options = NO_SSLv3
TIMEOUTidle = 86400
ciphers = HIGH:!ADH:!AECDH:!LOW:!EXP:!MD5:!3DES:!SRP:!PSK:@STRENGTH
debug = ${STUNNEL_LOGLEVEL:-notice}
EOFEOF

REDIS_URL=${HEROKU_REDIS_BLUE_URL/rediss/redis}
REDIS_URL=${REDIS_URL%@*}
REDIS_URL=${REDIS_URL}@127.0.0.1:6371

export REDIS_URL=$REDIS_URL

STUNNEL_URI=${HEROKU_REDIS_BLUE_URL#*@}
#STUNNEL_URI=rediss://${STUNNEL_URI}
export STUNNEL_URI=${STUNNEL_URI}

cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
[REDIS_URL]
client = yes
accept = 127.0.0.1:6371
connect = ${STUNNEL_URI}
retry = ${STUNNEL_CONNECTION_RETRY:-"no"}
EOFEOF

cat /app/vendor/stunnel/stunnel.conf
env
chmod go-rwx /app/vendor/stunnel/*
