#!/bin/bash
CHECK=$(echo "info" |redis-cli -h ind-sint-redis1.ind1.sth.basefarm.net -p 6379  | grep master_host | awk -F':' '{print $2}'|strings)
if [[ ! $CHECK ]]; then
HOST="ind-sint-redis1.ind1.sth.basefarm.net"
else
HOST=`host $CHECK | awk '{print $5}' |sed 's/\.$//g'`;
fi

if [[ ! $HOST ]]; then echo "Something is wrong, exiting"; fi

echo "clearing INTYGSSTATISTIK_*"
#echo "info replication"| redis-cli -h $HOST -p 6379
echo " EVAL \"return redis.call('del', unpack(redis.call('keys', ARGV[1])))\" 0 *INTYGSSTATISTIK_*" | redis-cli -h $HOST -p 6379