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