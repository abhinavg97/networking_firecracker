SRC_VM_INDEX=$1
NUM_VMS=$2

# Initialize variables
total=0.0
count=0

TARGET_VM_INDEX=1

while [ $TARGET_VM_INDEX -le $NUM_VMS ]; do

  file="ping_${SRC_VM_INDEX}_${TARGET_VM_INDEX}"
  value=$(cat "$file")
  total=$(awk "BEGIN { printf \"%.3f\", $total + $value }")
  count=$((count + 1))
  TARGET_VM_INDEX=$(($TARGET_VM_INDEX + 1))
done

average=$(awk "BEGIN { printf \"%.3f\", $total / $count }")

echo $average

# python3 calc_ping_metrics.py $NUM_VMS