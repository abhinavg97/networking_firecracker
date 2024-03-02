BRIDGE_PREFIX=$1

if [ "$#" -ne 1 ]
then
  echo "Run like: one_time_setup.sh [BRIDGE_PREFIX]192.167"
  exit 1
fi

bash setup/setup_docker.sh

echo "setting up docker completed"

# the first argument is the bridge prefix like so - 192.167.1.1 or 192.168.1.1
bash setup/setup_bridge_firecracker.sh ${BRIDGE_PREFIX}


echo "setting up bridge and downloading firecracker and firectl binaries completed"

sudo cp server/parallel_start_many.sh /usr/local/bin/parallel_start_many
sudo cp server/cleanup.sh /usr/local/bin/cleanup