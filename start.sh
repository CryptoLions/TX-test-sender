#!/bin/bash
################################################################################
#
# Scrip Created by http://CryptoLions.io
# For testing Transaction 
# Created for EOS Junlge test network
#
# https://github.com/CryptoLions/
#
# Send EOS to random registered producer in system contract
################################################################################

config="config.json"
WORKERS="$( jq -r '.workers' "$config" )"
CLEOS="$( jq -r '.cleos' "$config" )"
WALLETHOST="$( jq -r '.walletAddr' "$config" )"
UNLOCK_WALLET="$( jq -r '.unlock_wallet' "$config" )"


declare -A WORK=()
declare -A WORK_RES=()

if [[ -f error_tx.log ]]; then
    rm error_tx.log
fi

if [[ $UNLOCK_WALLET != "" ]]; then
    .$CLEOS --wallet-url http://$WALLETHOST wallet unlock --password $UNLOCK_WALLET > /dev/null 2>/dev/null
fi


config_json=$(cat $config);

#get nodes list from config
declare -A HOSTS=()
for row in $(echo "$config_json" | jq -r '.nodes[]'); do
    HOSTS[${#HOSTS[@]}]=$row
done

#get random node
rnd_host=$(($RANDOM % ${#HOSTS[@]}))
NODEHOST=${HOSTS[$rnd_host]}


STARTTIME=$(date +%s.%N)

for i in $(seq 1 $WORKERS);
do

    WORK_RES[$i]="worker_$i"

    ./tx.sh > ${WORK_RES[$i]} &

    WORK[$i]=$!
    echo "Worker $i started"
done

wait ${WORK[*]}

ENDTIME=$(date +%s.%N)
DIFF=$(echo "$ENDTIME - $STARTTIME" | bc)

REQUEST_OK=0
REQUEST_FAILED=0

for i in $(seq 1 ${#WORK_RES[*]});
do
    data=($(cat ${WORK_RES[$i]}))
    REQUEST_OK=$((REQUEST_OK+${data[0]}))
    REQUEST_FAILED=$((REQUEST_FAILED+${data[1]}))
    rm ${WORK_RES[$i]}
done

echo "================================"
echo "Workers: $WORKERS"

echo "Failed Transactions: $REQUEST_FAILED"
echo "Good Transactions: $REQUEST_OK"
echo "Total Transactionss: "$(($REQUEST_OK+$REQUEST_FAILED))

echo "Finished."
echo "Time: $DIFF sec."
echo "TPS: " $(echo "scale=2; $REQUEST_OK/$DIFF" | bc)

#VAR=$(echo "scale=2; $REQUEST_OK/$DIFF" | bc)
