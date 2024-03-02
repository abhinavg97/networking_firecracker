NUM_VMS=$1
BRIDGE_PREFIX=$2

if [ "$#" -ne 2 ]
then
  echo "Run like: collect_ping_metrics.sh [NUM_VMS]125 [BRIDGE_PREFIX]192.167"
  exit 1
fi

for (( VM_INDEX=1; VM_INDEX<=$NUM_VMS; VM_INDEX++));
do
  TUN_IP="$(printf '%s.1.%s' ${BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"
  ping -c 100 $TUN_IP | grep rtt | awk -F'[/ ]+' '{print $8}' > ping_${VM_INDEX} &
done

sleep 120
