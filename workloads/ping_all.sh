SRC_VM_INDEX=$1
SOURCE_VMS=$2
TARGET_VMS=$3
BRIDGE_PREFIX=$4


if [ "$#" -ne 4 ]
then
  echo "DO NOT RUN MANUALLY Run like: ping_all.sh [SRC_VM_INDEX]65 [SOURCE_VMS]3 [TARGET_VMS]125 [TARGET_BRIDGE_PREFIX]192.167"
  exit 1
fi

TARGET_VM_INDEX=1

while [ $TARGET_VM_INDEX -le $TARGET_VMS ]; do
    TUN_IP="$(printf '%s.1.%s' ${BRIDGE_PREFIX} $(((2 * TARGET_VM_INDEX + 1) )))"
    ping -c 100 $TUN_IP | grep round-trip | awk -F'[/ ]+' '{print $7}' > ping_${SRC_VM_INDEX}_${TARGET_VM_INDEX}_${SOURCE_VMS}_${TARGET_VMS} &
    TARGET_VM_INDEX=$(($TARGET_VM_INDEX + 1))
done

sleep 120
