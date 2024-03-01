# Add Docker's official GPG key:
sudo apt-get -y update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

#install docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
sudo systemctl enable docker.service
sudo systemctl enable containerd.service



# install firecracker
cd ~
git clone https://github.com/firecracker-microvm/firecracker
cd firecracker
tools/devtool build
toolchain="$(uname -m)-unknown-linux-musl"
sudo cp build/cargo_target/${toolchain}/debug/firecracker /usr/local/bin/firecracker


# get firectl
cd ~
git clone https://github.com/firecracker-microvm/firectl.git
sudo apt -y install golang
cd firectl
go build
chmod +x firectl
sudo cp firectl /usr/local/bin/firectl


## todo: lookup the interface used by tap0 (created earlier)
# todo: fetch ubuntu-vmlinux and ubuntu.ext4 from somewhere, alternatively create (commands later)
scp ubuntu.ext4 ag4786@hp115.utah.cloudlab.us:/users/ag4786/ubuntu.ext4
scp ubuntu-vmlinux ag4786@hp115.utah.cloudlab.us:/users/ag4786/ubuntu-vmlinux

####################################################################################################################################################################################

# add tun tap interface
sudo ip tuntap add tap0 mode tap # user $(id -u) group $(id -g)
sudo ip addr add 172.20.0.1/24 dev tap0
sudo ip link set tap0 up

## todo lookup for the ethernet interface to forward packets to the tap device
# pending lookup commmand
# ETH=eno49np0
# DEVICE_NAME=ETH

sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o $DEVICE_NAME -j MASQUERADE
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i tap0 -o $DEVICE_NAME -j ACCEPT

sudo firectl \
--firecracker-binary=/usr/local/bin/firecracker \
--kernel=ubuntu-vmlinux \
--kernel-opts="console=ttyS0 noapic reboot=k panic=1 pci=off nomodules rw" \
--root-drive=ubuntu.ext4 \
--log-level=Error \
-l=error.log \
--tap-device=tap1/36:0f:88:10:c1:43


# turn on networking inside the guest vm
ip addr add 172.20.0.2/24 dev eth0
ip link set eth0 up
ip route add default via 172.20.0.1 dev eth0


# enable dns
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

##############################################################################################################################################################################
### bridge to connect all vms
# on host
## setup bridge for getting the vm iface known to the world
sudo ip link add name br0 type bridge

sudo ip link set dev tap0 master br0

# check for default gateway 
# ip route | grep default
sudo ip addr add 128.110.216.7/24 dev br0


# allow routing to guest
sudo iptables -t nat -A POSTROUTING -o br0 -j MASQUERADE

# on the guest
ip addr add 10.0.0.1/24 dev eth0
ip link set eth0 up
ip r add 128.110.216.1 via 128.110.216.7 dev eth0

ip r add default via 128.110.216.7 dev eth0
echo nameserver 128.110.216.1 >> /etc/resolv.conf



## 128.110.218.154/21


################

#w/ bridge

sudo ip route add 192.168.0.0/16 via 10.10.1.2