#!/bin/bash
#
#
count=${1:-"5000"}
interval=${2:-"5"}
HOST="http://localhost"
PORT="8081"
URI="/"
for i in $(seq $count )
do
  now=`date `
  echo "$started - $now - Iteration "$i
  curl $HOST:$PORT$URI
	sleep $interval
done
