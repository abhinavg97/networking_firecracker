if [ "$#" -ne 5 ]
then
  echo "run like: iperf_b1_b2.sh [MIN_CONST_PORTS]1 [TOTAL_CONST_PORTS]10 [TARGET_NODE_IP]10.10.1.1 [SOURCE_BRIDGE_PREFIX]192.168 [TARGET_BRIDGE_PREFIX]192.167"
  exit 1
fi

MIN_CONST_PORTS=$1
TOTAL_CONST_PORTS=$2
TARGET_NODE="$3"
SOURCE_BRIDGE_PREFIX=$4
TARGET_BRIDGE_PREFIX=$5

PIVOT_PORT=7000

for (( CONST_PORTS=${MIN_CONST_PORTS}; CONST_PORTS<=${TOTAL_CONST_PORTS}; CONST_PORTS++ ));
do

    pids=()

    for (( PORT_INDEX=1; PORT_INDEX<=$CONST_PORTS; PORT_INDEX++ ));
    do
		PORT=$((PORT_INDEX + PIVOT_PORT))
        ssh ag4786@$TARGET_NODE "iperf3 -s -D -p $PORT"  # -D option to run iperf3 in daemon mode
    done

    for (( PORT_INDEX=1; PORT_INDEX<=$CONST_PORTS; PORT_INDEX++ ));
    do
		PORT=$((PORT_INDEX + PIVOT_PORT))
        ## start iperf3 client in the source machine
        iperf3 -c $TARGET_NODE -t 300 -f g -i 0 -p $PORT > iperf_${PORT} &
        pids+=($!)
    done

    for pid in ${pids[*]};
    do
        wait $pid
    done

    sleep 5

    total=0
    for (( PORT_INDEX=1; PORT_INDEX<=$CONST_PORTS; PORT_INDEX++ ));
    do
		PORT=$((PORT_INDEX + PIVOT_PORT))
        value=$(cat iperf_${PORT} | grep receiver | awk '{print $7}')
        total=$(echo "$total + $value" | bc)
    done

    average=$(bc <<< "scale=5; $total / $CONST_PORTS")

    echo $average > iperf_${CONST_PORTS}

	ssh ag4786@$TARGET_NODE "killall iperf3"
	killall iperf3

    sleep 5
done
