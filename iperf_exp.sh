if [ "$#" -ne 5 ]
then
  echo "run like: iperf_exp.sh [MIN_CONST_VMS]1 [TOTAL_CONST_VMS]10 [TARGET_NODE_IP]10.10.1.1 [SOURCE_BRIDGE_PREFIX]192.168 [TARGET_BRIDGE_PREFIX]192.167"
  exit 1
fi


MIN_CONST_VMS=$1
TOTAL_CONST_VMS=$2
TARGET_NODE="$3"
SOURCE_BRIDGE_PREFIX=$4
TARGET_BRIDGE_PREFIX=$5

# MAX_THROUGHPUT=5.71*1000*1000*1000 # 5.71 Gbps single vm to single vm scenario

S3_BUCKET="spec.ccfc.min"
TARGET="$(uname -m)"
kv="4.14"
REPO_NAME=$(basename `git rev-parse --show-toplevel`)

sudo ip route add ${TARGET_BRIDGE_PREFIX}.0.0/16 via $TARGET_NODE
ssh ag4786@${TARGET_NODE} sudo ip route add ${SOURCE_BRIDGE_PREFIX}.0.0/16 via 10.10.1.2

for (( CONST_VMS=${MIN_CONST_VMS}; CONST_VMS<=${TOTAL_CONST_VMS}; CONST_VMS++ ));
do
    sleep 3
    ssh ag4786@${TARGET_NODE} bash parallel_start_many ${CONST_VMS} ${TARGET_BRIDGE_PREFIX}
    sleep 5
    ssh ag4786@${TARGET_NODE} "export REPO_NAME='${REPO_NAME}'; bash enable_vm_networking ${CONST_VMS} ${TARGET_BRIDGE_PREFIX}"

    wget -N -q "https://s3.amazonaws.com/$S3_BUCKET/img/alpine_demo/fsfiles/xenial.rootfs.ext4" -O rootfs.ext4
    wget -N -q "https://s3.amazonaws.com/$S3_BUCKET/ci-artifacts/kernels/$TARGET/vmlinux-$kv.bin" -O "rootfs.vmlinux"

    bash parallel_start_many ${CONST_VMS} ${SOURCE_BRIDGE_PREFIX}
    sleep 5
    bash enable_vm_networking ${CONST_VMS} ${SOURCE_BRIDGE_PREFIX}

    pids=()

    for (( VM_INDEX=1; VM_INDEX<=$CONST_VMS; VM_INDEX++ ));
    do
        SRC_VM_IP="$(printf '%s.1.%s' ${SOURCE_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"
        DST_VM_IP="$(printf '%s.1.%s' ${TARGET_BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"

        ## add iperf3 package in the vm if it does not exist
        ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$SRC_VM_IP "apk info iperf3 >/dev/null 2>&1 || apk add iperf3"
        ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$DST_VM_IP "apk info iperf3 >/dev/null 2>&1 || apk add iperf3"

        ## start iperf3 server in the target vm
        ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$DST_VM_IP "iperf3 -s -D"  # -D option to run iperf3 in daemon mode

        ## start iperf3 client in the source vm
        ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$SRC_VM_IP "iperf3 -c $DST_VM_IP -t 60 -f g -i 0 > iperf_${VM_INDEX}" &
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
        value=$(ssh -i rootfs.id_rsa root@$SRC_VM_IP "cat iperf_${VM_INDEX}" | grep receiver | awk '{print $7}')
        total=$((total + value))
    done

    average=$(bc <<< "scale=5; $total / $CONST_VMS")

    echo $average >> iperf_${CONST_VMS}

    sudo bash $HOME/$REPO_NAME/server/cleanup.sh ${CONST_VMS}
    rm rootfs.ext4
    rm rootfs.vmlinux

    ssh -tt ag4786@${TARGET_NODE} "sudo bash $HOME/$REPO_NAME/server/cleanup.sh ${TARGET_VMS}"
    sleep 5
done
