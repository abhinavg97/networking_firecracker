# sudo killall screen
# sleep 10
sudo killall firecracker
sleep 5
sudo killall firectl
sleep 5
sudo killall -s  SIGKILL firecracker
sleep 5
sudo killall -s SIGKILL firectl

NUM_VMS=$1

if [ "$#" -ne 1 ]
then
  echo "Run like: cleanup.sh [NUM_VMS]125"
  exit 1
fi

for (( VM_INDEX=1; VM_INDEX<=$NUM_VMS; VM_INDEX++ ));
do
        TAP_DEV="tap${VM_INDEX}"
        sudo ip tuntap del $TAP_DEV mode tap
done