START_VM_NO=$1
END_VM_NO=$2
BRIDGE_PREFIX=$3

EXP_NO=$(($END_VM_NO - 1))


if [ "$#" -ne 3 ]
then
  echo "Run like: collect_ping_metrics.sh [START_VM_NO]1 [END_VM_NO]125 [BRIDGE_PREFIX]192.167"
  exit 1
fi

for (( SB_ID=$START_VM_NO ; SB_ID<$END_VM_NO ; SB_ID++ ));
do
        TUN_IP="$(printf '%s.1.%s' ${BRIDGE_PREFIX} $(((2 * SB_ID + 1) )))"
        ping -c 100 $TUN_IP | grep rtt > ${EXP_NO}_ping_${SB_ID} &
done


sleep 120

python3 calc_ping_metrics.py $START_VM_NO $END_VM_NO