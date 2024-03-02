NUM_VMS=$1
BRIDGE_PREFIX=$2

if [ "$#" -ne 2 ]
then
  echo "Run like: collect_ping_metrics.sh [NUM_VMS]125 [BRIDGE_PREFIX]192.167"
  exit 1
fi

VM_INDEX=1

while [ $VM_INDEX -le $NUM_VMS ]; do
    TUN_IP="$(printf '%s.1.%s' ${BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"
    ping -c 100 $TUN_IP | grep round-trip | awk -F'[/ ]+' '{print $7}' > ping_${VM_INDEX} &
    VM_INDEX=$(($VM_INDEX + 1))
done

sleep 120
