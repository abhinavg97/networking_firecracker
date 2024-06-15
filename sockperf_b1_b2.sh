if [ "$#" -ne 3 ]
then
  echo "run like: sockperf_b1_b2.sh [MIN_CONST_PORTS]1 [TOTAL_CONST_PORTS]10 [TARGET_NODE_IP]10.10.1.1"
  exit 1
fi

MIN_CONST_PORTS=$1
TOTAL_CONST_PORTS=$2
TARGET_NODE="$3"

PIVOT_PORT=7000

RESULTS=results
TEMP=temp

function check_server_ready {
    local ip=$1
    local port=$2

    echo "checking ip $ip:$port for liveness"

    for i in {1..30}; do
        # Check if the port is open using ss
        if nc -z -w 2 "$ip" "$port"; then
            return 0
        fi
        # Wait for a second before the next check
        echo "Waiting for server $ip:$port to be ready... ($i)"

        if [ $i -eq 15 ]; then
            echo "Attempt $i: Restarting sockperf server on $ip:$port"
            ssh ag4786@$TARGET_NODE "sockperf sr --tcp --ip ${ip} --port $port --daemonize > /dev/null" &
        fi

        sleep 1
    done
    return 1
}

for (( CONST_PORTS=${MIN_CONST_PORTS}; CONST_PORTS<=${TOTAL_CONST_PORTS}; CONST_PORTS++ ));
do

    pids=()

    echo "Starting servers..."

    for (( PORT_INDEX=1; PORT_INDEX<=$CONST_PORTS; PORT_INDEX++ ));
    do
		PORT=$((PORT_INDEX + PIVOT_PORT))
        ssh ag4786@$TARGET_NODE "sockperf sr --tcp --ip ${TARGET_NODE} --port $PORT --daemonize > /dev/null" &
    done

    for (( PORT_INDEX=1; PORT_INDEX<=$CONST_PORTS; PORT_INDEX++ ));
    do
        # Give the server a moment to start up and check if it's ready
        PORT=$((PORT_INDEX + PIVOT_PORT))

        if ! check_server_ready $TARGET_NODE $PORT; then
            echo "sockperf server on $TARGET_NODE:$PORT failed to start or is not ready."
            exit 1
        fi
    done

    echo "All servers started. Starting clients..."

    for (( PORT_INDEX=1; PORT_INDEX<=$CONST_PORTS; PORT_INDEX++ ));
    do
		PORT=$((PORT_INDEX + PIVOT_PORT))
        ## start sockperf client in the source machine
        sockperf ping-pong --tcp --ip ${TARGET_NODE} --port $PORT --time 100 > $TEMP/sockperf_${CONST_PORTS}_${PORT} &
        pids+=($!)
    done

    for pid in ${pids[*]};
    do
        wait $pid
    done

    sleep 5

    totalreceived=0
    totalsent=0
    totalfivenine=0
    totalfournine=0
    totalthreenine=0
    totaltwonine=0
    totalonenine=0
    totalsevenfive=0
    totalfivezero=0
    totaltwofive=0
    totalavglatency=0
    totalstddevlatency=0

    for (( PORT_INDEX=1; PORT_INDEX<=$CONST_PORTS; PORT_INDEX++ ));
    do
		PORT=$((PORT_INDEX + PIVOT_PORT))

        receivedmessages=$(cat $TEMP/sockperf_${CONST_PORTS}_${PORT} | grep "Valid Duration" | grep -oP 'ReceivedMessages=\K[0-9]+')
        sentmessages=$(cat $TEMP/sockperf_${CONST_PORTS}_${PORT} | grep "Valid Duration" | grep -oP 'SentMessages=\K[0-9]+')
        valuefivenine=$(cat $TEMP/sockperf_${CONST_PORTS}_${PORT} | grep "percentile 99.999" | awk '{print $6}')
        valuefournine=$(cat $TEMP/sockperf_${CONST_PORTS}_${PORT} | grep "percentile 99.990" | awk '{print $6}')
        valuethreenine=$(cat $TEMP/sockperf_${CONST_PORTS}_${PORT} | grep "percentile 99.900" | awk '{print $6}')
        valuetwonine=$(cat $TEMP/sockperf_${CONST_PORTS}_${PORT} | grep "percentile 99.000" | awk '{print $6}')
        valueonenine=$(cat $TEMP/sockperf_${CONST_PORTS}_${PORT} | grep "percentile 90.000" | awk '{print $6}')
        valuesevenfive=$(cat $TEMP/sockperf_${CONST_PORTS}_${PORT} | grep "percentile 75.000" | awk '{print $6}')
        valuefivezero=$(cat $TEMP/sockperf_${CONST_PORTS}_${PORT} | grep "percentile 50.000" | awk '{print $6}')
        valuetwofive=$(cat $TEMP/sockperf_${CONST_PORTS}_${PORT} | grep "percentile 25.000" | awk '{print $6}')
        valueavglatency=$(cat $TEMP/sockperf_${CONST_PORTS}_${PORT} | grep "avg-latency" | grep -oP 'avg-latency=\K[0-9.]+')
        valuestddevlatency=$(cat $TEMP/sockperf_${CONST_PORTS}_${PORT} | grep "avg-latency" | grep -oP 'std-dev=\K[0-9.]+')

        if [ -z "$receivedmessages" ] || [ -z "$sentmessages" ] || [ -z "$valuefivenine" ] || [ -z "$valuefournine" ] || [ -z "$valuethreenine" ] || [ -z "$valuetwonine" ] || [ -z "$valueonenine" ] || [ -z "$valuesevenfive" ] || [ -z "$valuefivezero" ] || [ -z "$valuetwofive" ] || [ -z "$valueavglatency" ] || [ -z "$valuestddevlatency" ]; then 
            echo "One of the metrics is empty."
            exit 1
        fi

        totalreceived=$(echo "$totalreceived + $receivedmessages" | bc)
        totalsent=$(echo "$totalsent + $sentmessages" | bc)
        totalfivenine=$(echo "$totalfivenine + $valuefivenine" | bc)
        totalfournine=$(echo "$totalfournine + $valuefournine" | bc)
        totalthreenine=$(echo "$totalthreenine + $valuethreenine" | bc)
        totaltwonine=$(echo "$totaltwonine + $valuetwonine" | bc)
        totalonenine=$(echo "$totalonenine + $valueonenine" | bc)
        totalsevenfive=$(echo "$totalsevenfive + $valuesevenfive" | bc)
        totalfivezero=$(echo "$totalfivezero + $valuefivezero" | bc)
        totaltwofive=$(echo "$totaltwofive + $valuetwofive" | bc)
        totalavglatency=$(echo "$totalavglatency + $valueavglatency" | bc)
        totalstddevlatency=$(echo "$totalstddevlatency + $valuestddevlatency" | bc)
    done

    averagereceived=$(bc <<< "scale=5; $totalreceived / $CONST_PORTS")
    averagesent=$(bc <<< "scale=5; $totalsent / $CONST_PORTS")
    averagefivenine=$(bc <<< "scale=5; $totalfivenine / $CONST_PORTS")
    averagefournine=$(bc <<< "scale=5; $totalfournine / $CONST_PORTS")
    averagethreenine=$(bc <<< "scale=5; $totalthreenine / $CONST_PORTS")
    averagetwonine=$(bc <<< "scale=5; $totaltwonine / $CONST_PORTS")
    averageonenine=$(bc <<< "scale=5; $totalonenine / $CONST_PORTS")
    averagesevenfive=$(bc <<< "scale=5; $totalsevenfive / $CONST_PORTS")
    averagefivezero=$(bc <<< "scale=5; $totalfivezero / $CONST_PORTS")
    averagetwofive=$(bc <<< "scale=5; $totaltwofive / $CONST_PORTS")
    averageavglatency=$(bc <<< "scale=5; $totalavglatency / $CONST_PORTS")
    averagestddevlatency=$(bc <<< "scale=5; $totalstddevlatency / $CONST_PORTS")

    echo $averagereceived > $RESULTS/sockperf_${CONST_PORTS}
    echo $averagesent >> $RESULTS/sockperf_${CONST_PORTS}
    echo $averagefivenine >> $RESULTS/sockperf_${CONST_PORTS}
    echo $averagefournine >> $RESULTS/sockperf_${CONST_PORTS}
    echo $averagethreenine >> $RESULTS/sockperf_${CONST_PORTS}
    echo $averagetwonine >> $RESULTS/sockperf_${CONST_PORTS}
    echo $averageonenine >> $RESULTS/sockperf_${CONST_PORTS}
    echo $averagesevenfive >> $RESULTS/sockperf_${CONST_PORTS}
    echo $averagefivezero >> $RESULTS/sockperf_${CONST_PORTS}
    echo $averagetwofive >> $RESULTS/sockperf_${CONST_PORTS}
    echo $averageavglatency >> $RESULTS/sockperf_${CONST_PORTS}
    echo $averagestddevlatency >> $RESULTS/sockperf_${CONST_PORTS}

	ssh ag4786@$TARGET_NODE "killall sockperf"
	killall sockperf
    killall ssh

    sleep 5
done
