NUM_VMS=$1

# Initialize variables
total=0
count=0

VM_INDEX=1
while [ $VM_INDEX -le $NUM_VMS ]; do

  file="ping_${VM_INDEX}"
  value=$(cat "$file")
  total=$((total + value))
  count=$((count + 1))
  VM_INDEX=$(($VM_INDEX + 1))
done

average=$((total / count))

echo $average

# python3 calc_ping_metrics.py $NUM_VMS