if [ "$#" -ne 6 ]
then
  echo "run like: sockperf_exp.sh [MIN_CONST_VMS]1 [TOTAL_CONST_VMS]10 [TARGET_NODE_IP]10.10.1.1 [SOURCE_BRIDGE_PREFIX]192.168 [TARGET_BRIDGE_PREFIX]192.167 [OS]alpine"
  exit 1
fi

MIN_CONST_VMS=$1
TOTAL_CONST_VMS=$2
TARGET_NODE="$3"
SOURCE_BRIDGE_PREFIX=$4
TARGET_BRIDGE_PREFIX=$5
OS=$6

REPO_NAME=$(basename `git rev-parse --show-toplevel`)
RESULTS=results

sudo ip route add ${TARGET_BRIDGE_PREFIX}.0.0/16 via $TARGET_NODE
ssh ag4786@${TARGET_NODE} sudo ip route add ${SOURCE_BRIDGE_PREFIX}.0.0/16 via 10.10.1.2

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
        sleep 1
    done
    return 1
}

for (( CONST_VMS=${MIN_CONST_VMS}; CONST_VMS<=${TOTAL_CONST_VMS}; CONST_VMS++ ));
do
    sleep 3
    ssh ag4786@${TARGET_NODE} bash parallel_start_many ${CONST_VMS} ${TARGET_BRIDGE_PREFIX} ${OS}

    bash parallel_start_many ${CONST_VMS} ${SOURCE_BRIDGE_PREFIX} ${OS}
    pids=()

    echo "Starting servers..."

    for (( VM_INDEX=1; VM_INDEX<=$CONST_VMS; VM_INDEX++ ));
    do
        DST_VM_IP="$(printf '%s.1.%s' ${TARGET_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"

        ## start sockperf server in the target vm
        ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$DST_VM_IP "sockperf sr --tcp --ip ${DST_VM_IP} --port 7000 --daemonize > /dev/null" &
    done

    for (( VM_INDEX=1; VM_INDEX<=$CONST_VMS; VM_INDEX++ ));
    do
        DST_VM_IP="$(printf '%s.1.%s' ${TARGET_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"

        # Give the server a moment to start up and check if it's ready
        if ! check_server_ready $DST_VM_IP 7000; then
            echo "sockperf server on $DST_VM_IP:7000 failed to start or is not ready."
            exit 1
        fi
    done

    echo "All servers started. Starting clients..."

    for (( VM_INDEX=1; VM_INDEX<=$CONST_VMS; VM_INDEX++ ));
    do
        SRC_VM_IP="$(printf '%s.1.%s' ${SOURCE_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"
        DST_VM_IP="$(printf '%s.1.%s' ${TARGET_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"

        ## start sockperf client in the source vm
        ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$SRC_VM_IP "sockperf ping-pong --tcp --ip ${DST_VM_IP} --port 7000 --time 100 > sockperf_${CONST_VMS}_${VM_INDEX}" &
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

    for (( VM_INDEX=1; VM_INDEX<=$CONST_VMS; VM_INDEX++ ));
    do
        SRC_VM_IP="$(printf '%s.1.%s' ${SOURCE_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"
        receivedmessages=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${CONST_VMS}_${VM_INDEX}" | grep "Valid Duration" | grep -oP 'ReceivedMessages=\K[0-9]+')
        sentmessages=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${CONST_VMS}_${VM_INDEX}" | grep "Valid Duration" | grep -oP 'SentMessages=\K[0-9]+')
        valuefivenine=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${CONST_VMS}_${VM_INDEX}" | grep "percentile 99.999" | awk '{print $6}')
        valuefournine=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${CONST_VMS}_${VM_INDEX}" | grep "percentile 99.990" | awk '{print $6}')
        valuethreenine=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${CONST_VMS}_${VM_INDEX}" | grep "percentile 99.900" | awk '{print $6}')
        valuetwonine=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${CONST_VMS}_${VM_INDEX}" | grep "percentile 99.000" | awk '{print $6}')
        valueonenine=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${CONST_VMS}_${VM_INDEX}" | grep "percentile 90.000" | awk '{print $6}')
        valuesevenfive=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${CONST_VMS}_${VM_INDEX}" | grep "percentile 75.000" | awk '{print $6}')
        valuefivezero=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${CONST_VMS}_${VM_INDEX}" | grep "percentile 50.000" | awk '{print $6}')
        valuetwofive=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${CONST_VMS}_${VM_INDEX}" | grep "percentile 25.000" | awk '{print $6}')
        valueavglatency=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${CONST_VMS}_${VM_INDEX}" | grep "avg-latency" | grep -oP 'avg-latency=\K[0-9.]+')
        valuestddevlatency=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${CONST_VMS}_${VM_INDEX}" | grep "avg-latency" | grep -oP 'std-dev=\K[0-9.]+')

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

    averagereceived=$(bc <<< "scale=5; $totalreceived / $CONST_VMS")
    averagesent=$(bc <<< "scale=5; $totalsent / $CONST_VMS")
    averagefivenine=$(bc <<< "scale=5; $totalfivenine / $CONST_VMS")
    averagefournine=$(bc <<< "scale=5; $totalfournine / $CONST_VMS")
    averagethreenine=$(bc <<< "scale=5; $totalthreenine / $CONST_VMS")
    averagetwonine=$(bc <<< "scale=5; $totaltwonine / $CONST_VMS")
    averageonenine=$(bc <<< "scale=5; $totalonenine / $CONST_VMS")
    averagesevenfive=$(bc <<< "scale=5; $totalsevenfive / $CONST_VMS")
    averagefivezero=$(bc <<< "scale=5; $totalfivezero / $CONST_VMS")
    averagetwofive=$(bc <<< "scale=5; $totaltwofive / $CONST_VMS")
    averageavglatency=$(bc <<< "scale=5; $totalavglatency / $CONST_VMS")
    averagestddevlatency=$(bc <<< "scale=5; $totalstddevlatency / $CONST_VMS")

    echo $averagereceived > $RESULTS/sockperf_${CONST_VMS}
    echo $averagesent >> $RESULTS/sockperf_${CONST_VMS}
    echo $averagefivenine >> $RESULTS/sockperf_${CONST_VMS}
    echo $averagefournine >> $RESULTS/sockperf_${CONST_VMS}
    echo $averagethreenine >> $RESULTS/sockperf_${CONST_VMS}
    echo $averagetwonine >> $RESULTS/sockperf_${CONST_VMS}
    echo $averageonenine >> $RESULTS/sockperf_${CONST_VMS}
    echo $averagesevenfive >> $RESULTS/sockperf_${CONST_VMS}
    echo $averagefivezero >> $RESULTS/sockperf_${CONST_VMS}
    echo $averagetwofive >> $RESULTS/sockperf_${CONST_VMS}
    echo $averageavglatency >> $RESULTS/sockperf_${CONST_VMS}
    echo $averagestddevlatency >> $RESULTS/sockperf_${CONST_VMS}

    sudo bash $HOME/$REPO_NAME/server/cleanup.sh ${CONST_VMS}

    ssh -tt ag4786@${TARGET_NODE} "sudo bash $HOME/$REPO_NAME/server/cleanup.sh ${CONST_VMS}"
    killall ssh

    sleep 5
done
