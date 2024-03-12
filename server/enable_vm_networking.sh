if [ "$#" -ne 2 ]
then
  echo "run like: enable_vm_networking.sh [NUM_VMS]1 [BRIDGE_PREFIX]192.167"
  exit 1
fi

NUM_VMS=$1
BRIDGE_PREFIX=$2
REPO_NAME=$(basename `git rev-parse --show-toplevel`)

for (( VM_INDEX=1; VM_INDEX<=${NUM_VMS}; NUM_VMS++ ));
do

    VM_IP="$(printf '%s.1.%s' ${BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"

    while true; do
        ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$VM_IP "echo nameserver 8.8.8.8 > /etc/resolv.conf"
        ssh -i $HOME/$REPO_NAME/rootfs.id_rsa root@$VM_IP "echo nameserver 8.8.4.4 > /etc/resolv.conf"

        if [ $? -eq 0 ]; then
            break
        else
            echo "Retrying to ssh root@$VM_IP ..."
            sleep 1
        fi
    done
done