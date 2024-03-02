
NUM_VMS=$1

# Initialize variables
total=0
count=0


for (( VM_INDEX=1; VM_INDEX<=$NUM_VMS; VM_INDEX++));
do
  file=ping_${VM_INDEX}
  value=$(cat "$file")
  total=$(echo "$total + $value" | bc)
  ((count++))

done

average=$(echo "scale=3; $total / $count" | bc)

echo $average

# python3 calc_ping_metrics.py $NUM_VMS