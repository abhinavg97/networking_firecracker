sudo killall screen
sleep 10
sudo killall firecracker
sleep 5
sudo killall firectl
sleep 5
sudo killall -s  SIGKILL firecracker
sleep 5
sudo killall -s SIGKILL firectl

START_VM_NO=$1
END_VM_NO=$2

if [ "$#" -ne 2 ]
then
  echo "Run like: cleanup.sh [START_VM_NO]1 [END_VM_NO]125"
  exit 1
fi

for (( SB_ID=$START_VM_NO ; SB_ID<$END_VM_NO ; SB_ID++ ));
do
        TAP_DEV="tap${SB_ID}"
        sudo ip tuntap del $TAP_DEV mode tap
done