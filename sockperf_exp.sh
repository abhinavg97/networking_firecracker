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

sudo ip route add ${TARGET_BRIDGE_PREFIX}.0.0/16 via $TARGET_NODE
ssh ag4786@${TARGET_NODE} sudo ip route add ${SOURCE_BRIDGE_PREFIX}.0.0/16 via 10.10.1.2

for (( CONST_VMS=${MIN_CONST_VMS}; CONST_VMS<=${TOTAL_CONST_VMS}; CONST_VMS++ ));
do
    sleep 3
    ssh ag4786@${TARGET_NODE} bash parallel_start_many ${CONST_VMS} ${TARGET_BRIDGE_PREFIX} ${OS}

    bash parallel_start_many ${CONST_VMS} ${SOURCE_BRIDGE_PREFIX} ${OS}
    pids=()

    for (( VM_INDEX=1; VM_INDEX<=$CONST_VMS; VM_INDEX++ ));
    do
        SRC_VM_IP="$(printf '%s.1.%s' ${SOURCE_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"
        DST_VM_IP="$(printf '%s.1.%s' ${TARGET_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"

        ## start sockperf server in the target vm
        ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$DST_VM_IP "sockperf sr --tcp --ip ${DST_VM_IP} --port 7000"  # -D option to run sockperf in daemon mode
    done

    for (( VM_INDEX=1; VM_INDEX<=$CONST_VMS; VM_INDEX++ ));
    do
        SRC_VM_IP="$(printf '%s.1.%s' ${SOURCE_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"
        DST_VM_IP="$(printf '%s.1.%s' ${TARGET_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"

        ## start sockperf client in the source vm
        ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$SRC_VM_IP "sockperf ping-pong --tcp --ip ${DST_VM_IP} --port 7000 > sockperf_${VM_INDEX}" &
        pids+=($!)
    done

    for pid in ${pids[*]};
    do
        wait $pid
    done

    sleep 5

    totalreceived=0
    totalsent=0

    for (( VM_INDEX=1; VM_INDEX<=$CONST_VMS; VM_INDEX++ ));
    do
        SRC_VM_IP="$(printf '%s.1.%s' ${SOURCE_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"
        # valuefivenine=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${VM_INDEX}" | grep "percentile 99.999" | awk '{print $6}')
        receivedmessages=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${VM_INDEX}" | grep "Valid Duration" | grep -oP 'ReceivedMessages=\K[0-9]+')
        sentmessages=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat sockperf_${VM_INDEX}" | grep "Valid Duration" | grep -oP 'SentMessages=\K[0-9]+')

        totalreceived=$(echo "$totalreceived + $receivedmessages" | bc)
        totalsent=$(echo "$totalsent + $sentmessages" | bc)
    done

    averagereceived=$(bc <<< "scale=5; $totalreceived / $CONST_VMS")
    averagesent=$(bc <<< "scale=5; $totalsent / $CONST_VMS")

    echo $averagereceived > sockperf_${CONST_VMS}
    echo $averagesent >> sockperf_${CONST_VMS}

    sudo bash $HOME/$REPO_NAME/server/cleanup.sh ${CONST_VMS}

    ssh -tt ag4786@${TARGET_NODE} "sudo bash $HOME/$REPO_NAME/server/cleanup.sh ${CONST_VMS}"
    sleep 5
done
