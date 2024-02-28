START_VM_NO=$1
END_VM_NO=$2
EXP_NO=$(($END_VM_NO - 1))

for (( SB_ID=$START_VM_NO ; SB_ID<$END_VM_NO ; SB_ID++ ));
do
        TUN_IP="$(printf '%s.1.%s' ${BRIDGE_PREFIX} $(((2 * SB_ID + 1) )))"
        ping -c 100 $TUN_IP | grep rtt > ${EXP_NO}_ping_${SB_ID} &
done


sleep 120

python3 calc_ping_metrics.py $START_VM_NO $END_VM_NO