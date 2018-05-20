#!/bin/bash
################################################################################
#
# Scrip Created by http://CryptoLions.io
# For testing Transaction in EOS Junlge test network
#
# https://github.com/CryptoLions/
#
################################################################################

config="config.json"
FROM="$( jq -r '.from' "$config" )"
LIMIT="$( jq -r '.jobs_per_worker' "$config" )"

NODEOSBINDIR="$( jq -r '.eos_bld_dir' "$config" )"
WALLETHOST="$( jq -r '.walletAddr' "$config" )"
UNLOCK_WALLET="$( jq -r '.unlock_wallet' "$config" )"

AMMOUNT="$( jq -r '.amount' "$config" )"
MEMO="$( jq -r '.txmemo' "$config" )"

config_json=$(cat $config);
#get nodes list from config
declare -A HOSTS=()

for row in $(echo "$config_json" | jq -r '.nodes[]'); do
    HOSTS[${#HOSTS[@]}]=$row
done


#get random node
rnd_host=$(($RANDOM % ${#HOSTS[@]}))
NODEHOST=${HOSTS[$rnd_host]}

#echo $NODEHOST

#get random node
#rnd_host=$(($RANDOM % ${#HOSTS[@]}))
#NODEHOST=${HOSTS[$rnd_host]}

#echo $NODEHOST
#exit
i=0
loop=true

RQ_RECIVED=0
RQ_FAILED=0


#get list reg producers to use as rnd receiver
#prods_json=$(./cleos.sh system listproducers -l 100 -j)
prods_json=$($NODEOSBINDIR/cleos/cleos -u http://$NODEHOST --wallet-url http://$WALLETHOST system listproducers -l 100 -j)

declare -A PRODS=()
for row in $(echo "${prods_json}" | jq -r '.rows[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }
    accsTO=$(_jq '.owner')
    if [[ $accsTO != $FROM ]]; then
	PRODS[${#PRODS[@]}]=$accsTO
    fi
done



while $loop
do

    i=$(($i+1))

    rnd_produce=$(($RANDOM % ${#PRODS[@]}))
    TO=${PRODS[$rnd_produce]}

    #host_index=$(($i % ${#HOSTS[@]}))
    host_index=$(($RANDOM % ${#HOSTS[@]}))

    #echo ${HOSTS[$host_index]}


    ANSWER_OK=1

    #cmd='./cleos.sh transfer '$FROM' '$TO' "'$AMMOUNT'" "'$MEMO'" -f'
    #response=$(./cleos.sh transfer $FROM $TO "$AMMOUNT" "$MEMO" -f -j 2>&1)
    cmd="$NODEOSBINDIR/cleos/cleos -u http://${HOSTS[$host_index]} --wallet-url http://$WALLETHOST transfer $FROM $TO \"$AMMOUNT\" \"$MEMO\" -f -j"

    response=$($NODEOSBINDIR/cleos/cleos -u http://${HOSTS[$host_index]} --wallet-url http://$WALLETHOST transfer $FROM $TO "$AMMOUNT" "$MEMO" -f -j 2>&1)


    if [[ "$response" =~ "Error" ]]; then
        ANSWER_OK=0
	echo "$cmd">>error_tx.log
	echo "$response">>error_tx.log
	echo "------------------------">>error_tx.log
    fi


    if [[ $ANSWER_OK -eq 1 ]]; then
        RQ_RECIVED=$(($RQ_RECIVED+1))
    else
        RQ_FAILED=$(($RQ_FAILED+1))
	#echo "M"
    fi

    if [ $i -ge $LIMIT ]; then
        loop=false
    fi
done
echo "$RQ_RECIVED $RQ_FAILED"
