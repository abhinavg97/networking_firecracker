BRIDGE_PREFIX=$1
bash setup_docker.sh

# the first argument is the bridge prefix like so - 192.167.1.1 or 192.168.1.1
bash setup_bridge_firecracker.sh ${BRIDGE_PREFIX}