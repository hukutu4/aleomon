#!/bin/bash
#set -x # uncomment to enable debug
rpcAddr="http://localhost:3032/"
now=$(date +%s%N)
monitorName="aleomon"
apiAddr="https://www.aleo.network/api/miner-info?address="
#####  END CONFIG  ##################################################################################################

nodeState=$(curl -s --data-binary '{"jsonrpc": "2.0", "id":"documentation", "method": "getnodestate", "params": [] }' -H 'content-type: application/json' $rpcAddr | jq '.result')
minerAddress=$(journalctl -u aleod-miner.service --since="10 min ago" -o cat | grep confirmed_blocks | tail -n1 | awk '{print $14}' | sed -r 's/\)//g')
blocksMined=$(journalctl -u aleod-miner.service --since="10 min ago" -o cat | grep confirmed_blocks | tail -n1 | awk '{print ($8+$11)}')

minerInfoFromAPI=$(curl -s -H 'content-type: application/json' "$apiAddr$minerAddress" | jq)
lb_blocksMined=$(echo "$minerInfoFromAPI" | jq '.blocksMined | length')
lb_position=$(echo "$minerInfoFromAPI" | jq '.position')
lb_lastBlockMined=$(echo "$minerInfoFromAPI" | jq '.lastBlockMined')
lb_score=$(echo "$minerInfoFromAPI" | jq '.score')
lb_calibrationScore=$(echo "$minerInfoFromAPI" | jq '.calibrationScore')

latest_block_height=$(echo "$nodeState" | jq '.latest_block_height')
latest_cumulative_weight=$(echo "$nodeState" | jq '.latest_cumulative_weight')
number_of_candidate_peers=$(echo "$nodeState" | jq '.number_of_candidate_peers')
number_of_connected_peers=$(echo "$nodeState" | jq '.number_of_connected_peers')
number_of_connected_sync_nodes=$(echo "$nodeState" | jq '.number_of_connected_sync_nodes')
software=$(echo "$nodeState" | jq '.software')
status=$(echo "$nodeState" | jq '.status')
type=$(echo "$nodeState" | jq '.type')
version=$(echo "$nodeState" | jq '.version')

case $(echo "$status" | sed -r 's/\"//g') in
"Mining") status_code=0;;
"Ready") status_code=1;;
"Peering") status_code=2;;
"Syncing") status_code=3;;
*) status_code=4;;
esac

logentry="blocksMined=$blocksMined,status_code=$status_code"
logentry="$logentry,latest_block_height=$latest_block_height,latest_cumulative_weight=$latest_cumulative_weight,number_of_candidate_peers=$number_of_candidate_peers,number_of_connected_peers=$number_of_connected_peers,number_of_connected_sync_nodes=$number_of_connected_sync_nodes,software=$software,status=$status,type=$type,version=$version"
logentry="$logentry,lb_blocksMined=$lb_blocksMined,lb_position=$lb_position,lb_lastBlockMined=$lb_lastBlockMined,lb_score=$lb_score,lb_calibrationScore=$lb_calibrationScore"
logentry="$monitorName,minerAddress=$minerAddress $logentry $now"
echo "$logentry"
