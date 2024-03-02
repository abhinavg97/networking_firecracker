TOTAL_SOURCE_VMS=$1
TOTAL_TARGET_VMS=$2
TARGET_NODE="node$3"
SOURCE_BRIDGE_PREFIX=$4
TARGET_BRIDGE_PREFIX=$5

if [ "$#" -ne 5 ]
then
  echo "run like: ping_nodex.sh [TOTAL_SOURCE_VMS]10 [TOTAL_TARGET_VMS]10 [TARGET_NODE]1 [SOURCE_BRIDGE_PREFIX]192.167 [TARGET_BRIDGE_PREFIX]192.168"
  exit 1
fi

sudo ip route add ${TARGET_BRIDGE_PREFIX}.0.0/16 via 10.10.1.1
ssh ag4786@${TARGET_NODE} sudo ip route add ${SOURCE_BRIDGE_PREFIX}.0.0/16 via 10.10.1.2

for (( TARGET_VMS=1; TARGET_VMS<=${TOTAL_TARGET_VMS}; TARGET_VMS++ ));
do
    sleep 5
    ## like so parallel_start_many START_VM END_VM BRIDGE_PREFIX
    ssh ag4786@${TARGET_NODE} bash parallel_start_many ${TARGET_VMS} ${TARGET_BRIDGE_PREFIX}
    sleep 5

    for (( SOURCE_VMS=1; SOURCE_VMS<=${TOTAL_SOURCE_VMS}; SOURCE_VMS++ ));
    do
        bash parallel_start_many ${SOURCE_VMS} ${BRIDGE_PREFIX_SOURCE_NODE}
        pids=()
        
        for (( SRC_VM_INDEX=1; SRC_VM_INDEX<=$SOURCE_VMS; SRC_VM_INDEX++ ));
        do
            SRC_VM_IP="$(printf '%s.1.%s' ${BRIDGE_PREFIX_SOURCE_NODE} $(((2 * SRC_VM_INDEX + 1) )))"
            scp -i rootfs.id_rsa ~/firecracker_networking/workloads/ping_all.sh root@$SRC_VM_IP:/ping_all.sh
            ssh -i rootfs.id_rsa root@$SRC_VM_IP ./ping_all.sh $TARGET_VMS $TARGET_BRIDGE_PREFIX &
            pids+=($!)
        done


        for pid in ${pids[*]};
        do
            wait $pid
        done

        for (( SRC_VM_INDEX=1; SRC_VM_INDEX<=$SOURCE_VMS; SRC_VM_INDEX++ ));
        do
            SRC_VM_IP="$(printf '%s.1.%s' ${BRIDGE_PREFIX_SOURCE_NODE} $(((2 * SRC_VM_INDEX + 1) )))"
            scp -i rootfs.id_rsa ~/firecracker_networking/workloads/collect_ping_metrics.py root@$SRC_VM_IP:/collect_ping_metrics.py
            ssh -i rootfs.id_rsa root@$SRC_VM_IP python3 collect_ping_metrics.py $TARGET_VMS >> "ping_${SOURCE_VMS}x${TARGET_VMS}_${SRC_VM_INDEX}"
            sleep 5
        done

        sudo bash cleanup ${SOURCE_VMS}
        sleep 5
    done

    ssh -tt ag4786@${TARGET_NODE} "sudo bash cleanup ${TARGET_VMS}"
    sleep 5
done
