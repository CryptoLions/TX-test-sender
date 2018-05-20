# TX-test-sender
To test sending transactions in threads

- Please edit config.json before start.
- Stake more in CPU bandwidth
- run start.sh

# Dependencies 
apt install bc
apt install jq

All failed transactions will be saved to log.

config.json parametrs

cleos - path to compiled cleos

from - who will tx sender
amount - amount to send on each tx
txmemo - transaction memo

workers - how many threads to start
jobs_per_worker - transaction count per 1 worker

walletAddr - your keosd connection info (with key for sender account)
unlock_wallet - password for you wallet to unlock automatically. can be empty

nodes - array of your local nodes which will be used randomly for each transaction
