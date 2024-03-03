SRC_VM_INDEX=$1
SOURCE_VMS=$2
TARGET_VMS=$3

if [ "$#" -ne 3 ]
then
  echo "DO NOT RUN MANUALLY Run like: collect_ping_metrics.sh [SRC_VM_INDEX]65 [SOURCE_VMS]3 [TARGET_VMS]125"
  exit 1
fi

# Initialize variables
total=0.0
count=0

TARGET_VM_INDEX=1

while [ $TARGET_VM_INDEX -le $TARGET_VMS ]; do

  file="ping_${SRC_VM_INDEX}_${TARGET_VM_INDEX}_${SOURCE_VMS}_${TARGET_VMS}"
  value=$(cat "$file")
  total=$(awk "BEGIN { printf \"%.3f\", $total + $value }")
  count=$((count + 1))
  TARGET_VM_INDEX=$(($TARGET_VM_INDEX + 1))
done

average=$(awk "BEGIN { printf \"%.3f\", $total / $count }")

echo $average

# python3 calc_ping_metrics.py $TARGET_VMS