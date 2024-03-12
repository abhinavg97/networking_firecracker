if [ "$#" -ne 1 ]
then
  echo "Run like: one_time_setup.sh [BRIDGE_PREFIX]192.167"
  exit 1
fi

BRIDGE_PREFIX=$1

bash setup/setup_docker.sh

echo "setting up docker completed"

# the first argument is the bridge prefix like so - 192.167.1.1 or 192.168.1.1
bash setup/setup_bridge_firecracker.sh ${BRIDGE_PREFIX}


echo "setting up bridge and downloading firecracker and firectl binaries completed"

sudo cp server/parallel_start_many.sh /usr/local/bin/parallel_start_many
sudo cp server/cleanup.sh /usr/local/bin/cleanup
sudo cp server/enable_vm_networking.sh /usr/local/bin/enable_vm_networking

sudo chmod a+x /usr/local/bin/parallel_start_many
sudo chmod a+x /usr/local/bin/cleanup
sudo chmod a+x /usr/local/bin/enable_vm_networking

## Enable networking inside the VM

echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

## Enable internet access in the VM via nat
DEFAULT_INTERFACE=$(ip route show default | awk '/default/ {print $5}')
sudo iptables -t nat -A POSTROUTING -s ${BRIDGE_PREFIX}.0.0/16 -o ${DEFAULT_INTERFACE} -j MASQUERADE
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -s ${BRIDGE_PREFIX}.0.0/16 -o ${DEFAULT_INTERFACE} -j ACCEPT

echo "    StrictHostKeyChecking no" | sudo tee -a /etc/ssh/ssh_config
echo "    ConnectionAttempts 10" | sudo tee -a /etc/ssh/ssh_config
echo "    ConnectTimeout 60" | sudo tee -a /etc/ssh/ssh_config
