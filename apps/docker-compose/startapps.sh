#!/bin/bash

# APPS is a space separated list of apps to run in docker containers locally
# start containers with command ./startapps.sh
APPS=("mi-frontend" "ips" "it" "wc" "mi2")

# OPTIONS:
# frontends: 'wc-frontend' 'rs-frontend' 'mi-frontend'
# spring apps: 'wc' 'it' 'rs' 'mi' 'st' 'pp' 'ls'
# springboot apps: 'ia' 'cts' 'ips' 'mi2' 'sjut' 'srs'


# returns 'host.docker.external' if $1 in $APPS, else returns 'host.docker.internal'
function getHost() {
  host=$(contains $1 && echo 'external' || echo 'internal')
  echo "host.docker.$host"
}

# returns 0 (true) if $1 in $APPS, otherwise 1 (false)
function contains() {
  for APP in ${APPS[@]}; do
    if [[ $APP == $1 ]]; then return 0; fi
  done
  return 1
}

# exports environment variable with name $1 and value $2 and prints it
function setEnv() {
  export "$1=$2"
  echo "$1: $2"
}

# transforms $APPS array to comma separated string
function collectProfiles() {
  data_string="${APPS[*]}"
  echo "${data_string//${IFS:0:1}/,}"
}


setEnv 'WSL_HOST_IP' "$(cat /etc/resolv.conf | grep 'nameserver' | cut -d\  -f2)"
setEnv 'COMPOSE_PROFILES' "$(collectProfiles)"

setEnv IA_HOST   $(getHost 'ia')
setEnv IT_HOST   $(getHost 'it')
setEnv LS_HOST   $(getHost 'ls')
setEnv MI_HOST   $(getHost 'mi')
setEnv PP_HOST   $(getHost 'pp')
setEnv RS_HOST   $(getHost 'rs')
setEnv ST_HOST   $(getHost 'st')
setEnv WC_HOST   $(getHost 'wc')
setEnv CTS_HOST  $(getHost 'cts')
setEnv IPS_HOST  $(getHost 'ips')
setEnv MI2_HOST  $(getHost 'mi2')
setEnv SRS_HOST  $(getHost 'srs')
setEnv SJUT_HOST $(getHost 'sjut')

exec docker compose up
