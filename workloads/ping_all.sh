SRC_VM_INDEX=$1
NUM_VMS=$2
BRIDGE_PREFIX=$3

if [ "$#" -ne 3 ]
then
  echo "DO NOT RUN MANUALLY Run like: ping_all.sh [SRC_VM_INDEX]65 [NUM_VMS]125 [TARGET_BRIDGE_PREFIX]192.167"
  exit 1
fi

TARGET_VM_INDEX=1

while [ $TARGET_VM_INDEX -le $NUM_VMS ]; do
    TUN_IP="$(printf '%s.1.%s' ${BRIDGE_PREFIX} $(((2 * TARGET_VM_INDEX + 1) )))"
    ping -c 100 $TUN_IP | grep round-trip | awk -F'[/ ]+' '{print $7}' > ping_${SRC_VM_INDEX}_${TARGET_VM_INDEX} &
    TARGET_VM_INDEX=$(($TARGET_VM_INDEX + 1))
done

sleep 120
