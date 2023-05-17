#!/usr/bin/env bash
URLS=${HEROKU_REDIS_BLUE_URL}
n=1

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

for URL in $URLS
do
  eval URL_VALUE=\$$URL
  PARTS=$(echo $URL_VALUE | perl -lne 'print "$1 $2 $3 $4 $5 $6 $7" if /^([^:]+):\/\/([^:]+):([^@]+)@(.*?):(.*?)(\/(.*?)(\\?.*))?$/')
  if [ -z "$PARTS" ]
  then
    PARTS=$(echo $URL_VALUE | perl -lne 'print "$1 $2 $3 $4 $5 $6 $7" if /^([^:]+):\/\/:([^@]+)@(.*?):(.*?)(\/(.*?)(\\?.*))?$/')
    WITHOUT_USERNAME=true
  fi
  URI=( $PARTS )

  URI_SCHEME=${URI[0]}
  URI_USER=${URI[1]}
  URI_PASS=${URI[2]}
  URI_HOST=${URI[3]}
  URI_PORT=${URI[4]}

  echo "Setting REDIS_URL config var"
  export REDIS_URL=redis://$URI_USER:$URI_PASS@127.0.0.1:637${n}
  # echo "Setting ${URL}_STUNNEL config var"
  # export ${URL}_STUNNEL=$URI_SCHEME://$URI_USER:$URI_PASS@127.0.0.1:637${n}

  cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
[REDIS_URL]
client = yes
accept = 127.0.0.1:637${n}
connect = $URI_HOST:$URI_PORT
retry = ${STUNNEL_CONNECTION_RETRY:-"no"}
EOFEOF

  let "n += 1"
done

cat /app/vendor/stunnel/stunnel.conf
env
chmod go-rwx /app/vendor/stunnel/*
