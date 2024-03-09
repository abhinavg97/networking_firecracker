if [ "$#" -ne 7 ]
then
  echo "run like: ping_nodex.sh [MIN_SRC_VMS]1 [MIN_TARGET_VMS]1 [TOTAL_SOURCE_VMS]10 [TOTAL_TARGET_VMS]10 [TARGET_NODE_IP]10.10.1.1 [SOURCE_BRIDGE_PREFIX]192.167 [TARGET_BRIDGE_PREFIX]192.168"
  exit 1
fi


MIN_SRC_VMS=$1
MIN_TARGET_VMS=$2
TOTAL_SOURCE_VMS=$3
TOTAL_TARGET_VMS=$4
TARGET_NODE="$5"
SOURCE_BRIDGE_PREFIX=$6
TARGET_BRIDGE_PREFIX=$7

S3_BUCKET="spec.ccfc.min"
TARGET="$(uname -m)"
kv="4.14"
REPO_NAME=$(basename `git rev-parse --show-toplevel`)

sudo ip route add ${TARGET_BRIDGE_PREFIX}.0.0/16 via $TARGET_NODE
ssh ag4786@${TARGET_NODE} sudo ip route add ${SOURCE_BRIDGE_PREFIX}.0.0/16 via 10.10.1.2

for (( TARGET_VMS=${MIN_TARGET_VMS}; TARGET_VMS<=${TOTAL_TARGET_VMS}; TARGET_VMS++ ));
do
    sleep 3
    ## like so parallel_start_many START_VM END_VM BRIDGE_PREFIX
    ssh ag4786@${TARGET_NODE} bash parallel_start_many ${TARGET_VMS} ${TARGET_BRIDGE_PREFIX}
    sleep 5

    for (( SOURCE_VMS=${MIN_SRC_VMS}; SOURCE_VMS<=${TOTAL_SOURCE_VMS}; SOURCE_VMS++ ));
    do
        bash parallel_start_many ${SOURCE_VMS} ${SOURCE_BRIDGE_PREFIX}
        sleep 5

        pids=()

        for (( SRC_VM_INDEX=1; SRC_VM_INDEX<=$SOURCE_VMS; SRC_VM_INDEX++ ));
        do
            SRC_VM_IP="$(printf '%s.1.%s' ${SOURCE_BRIDGE_PREFIX} $(((2 * SRC_VM_INDEX + 1) )))"
            # scp -i rootfs.id_rsa ~/${REPO_NAME}/workloads/ping_all.sh root@$SRC_VM_IP:~/ping_all.sh
            ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$SRC_VM_IP "cat >| ping_all.sh" < $HOME/${REPO_NAME}/workloads/ping_all.sh
            ssh -i rootfs.id_rsa root@$SRC_VM_IP sh ping_all.sh $SRC_VM_INDEX $SOURCE_VMS $TARGET_VMS $TARGET_BRIDGE_PREFIX &
            pids+=($!)
        done

        for pid in ${pids[*]};
        do
            wait $pid
        done

        sleep 5

        for (( SRC_VM_INDEX=1; SRC_VM_INDEX<=$SOURCE_VMS; SRC_VM_INDEX++ ));
        do
            SRC_VM_IP="$(printf '%s.1.%s' ${SOURCE_BRIDGE_PREFIX} $(((2 * SRC_VM_INDEX + 1) )))"
            # scp -i rootfs.id_rsa ~/${REPO_NAME}/workloads/collect_ping_metrics.py root@$SRC_VM_IP:~/collect_ping_metrics.py
            ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$SRC_VM_IP "cat >| collect_ping_metrics.sh" < $HOME/${REPO_NAME}/workloads/collect_ping_metrics.sh
            ssh -i rootfs.id_rsa root@$SRC_VM_IP sh collect_ping_metrics.sh $SRC_VM_INDEX $SOURCE_VMS $TARGET_VMS >> "ping_${SOURCE_VMS}x${TARGET_VMS}_${SRC_VM_INDEX}"
        done

        sudo bash $HOME/$REPO_NAME/server/cleanup.sh ${SOURCE_VMS}
        rm rootfs.ext4
        rm rootfs.vmlinux
        wget -N -q "https://s3.amazonaws.com/$S3_BUCKET/img/alpine_demo/fsfiles/xenial.rootfs.ext4" -O rootfs.ext4
        wget -N -q "https://s3.amazonaws.com/$S3_BUCKET/ci-artifacts/kernels/$TARGET/vmlinux-$kv.bin" -O "rootfs.vmlinux"
    done

    ssh -tt ag4786@${TARGET_NODE} "sudo bash $HOME/$REPO_NAME/server/cleanup.sh ${TARGET_VMS}"
    sleep 5
done
