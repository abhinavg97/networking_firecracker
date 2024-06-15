if [ "$#" -ne 5 ]
then
  echo "run like: iperf_exp.sh [MIN_CONST_VMS]1 [TOTAL_CONST_VMS]10 [TARGET_NODE_IP]10.10.1.1 [SOURCE_BRIDGE_PREFIX]192.168 [OS]alpine"
  exit 1
fi


MIN_CONST_VMS=$1
TOTAL_CONST_VMS=$2
TARGET_NODE="$3"
SOURCE_BRIDGE_PREFIX=$4
OS=$5

RESULTS=results

# MAX_THROUGHPUT=5.71*1000*1000*1000 # 5.71 Gbps single vm to single vm scenario

S3_BUCKET="spec.ccfc.min"
TARGET="$(uname -m)"
kv="4.14"
REPO_NAME=$(basename `git rev-parse --show-toplevel`)

ssh ag4786@${TARGET_NODE} sudo ip route add ${SOURCE_BRIDGE_PREFIX}.0.0/16 via 10.10.1.2

PIVOT_PORT=7000

for (( CONST_VMS=${MIN_CONST_VMS}; CONST_VMS<=${TOTAL_CONST_VMS}; CONST_VMS++ ));
do

    bash parallel_start_many ${CONST_VMS} ${SOURCE_BRIDGE_PREFIX} ${OS}
    sleep 5
    bash enable_vm_networking ${CONST_VMS} ${SOURCE_BRIDGE_PREFIX}

    pids=()

    for (( VM_INDEX=1; VM_INDEX<=$CONST_VMS; VM_INDEX++ ));
    do
        SRC_VM_IP="$(printf '%s.1.%s' ${SOURCE_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"

        ## add iperf3 package in the vm if it does not exist
        ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$SRC_VM_IP "apk info iperf3 >/dev/null 2>&1 || apk add iperf3"
    done

    for (( VM_INDEX=1; VM_INDEX<=$CONST_VMS; VM_INDEX++ ));
    do

		PORT=$((VM_INDEX + PIVOT_PORT))

        ## start iperf3 server in the target bare metal
        ssh ag4786@$TARGET_NODE "iperf3 -s -D -p $PORT"  # -D option to run iperf3 in daemon mode
    done

    for (( VM_INDEX=1; VM_INDEX<=$CONST_VMS; VM_INDEX++ ));
    do
        SRC_VM_IP="$(printf '%s.1.%s' ${SOURCE_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"


        ## start iperf3 client in the source vm
		PORT=$((VM_INDEX + PIVOT_PORT))
        ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$SRC_VM_IP "iperf3 -c $TARGET_NODE -t 300 -f g -i 0 -p ${PORT} > iperf_${CONST_VMS}_${VM_INDEX}" &
        pids+=($!)
    done

    for pid in ${pids[*]};
    do
        wait $pid
    done

    sleep 5

    total=0
    for (( VM_INDEX=1; VM_INDEX<=$CONST_VMS; VM_INDEX++ ));
    do
        SRC_VM_IP="$(printf '%s.1.%s' ${SOURCE_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"
        value=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat iperf_${CONST_VMS}_${VM_INDEX}" | grep receiver | awk '{print $7}')
        total=$(echo "$total + $value" | bc)
    done

    average=$(bc <<< "scale=5; $total / $CONST_VMS")

    echo $average > $RESULTS/iperf_${CONST_VMS}

    sudo bash $HOME/$REPO_NAME/server/cleanup.sh ${CONST_VMS}
	ssh ag4786@$TARGET_NODE "killall iperf3"

    sleep 5
done
