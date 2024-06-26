S3_BUCKET="spec.ccfc.min"
TARGET="$(uname -m)"
kv="4.14"

if [ "$#" -ne 2 ]
then
  echo "Run like: setup_bridge_firecracker.sh [BRIDGE_PREFIX]192.167 [OS]alpine,ubuntu"
  exit 1
fi

BRIDGE_PREFIX=$1
OS=$2


if [ "$OS" = "alpine" ];
then
  wget -N -q "https://s3.amazonaws.com/$S3_BUCKET/img/alpine_demo/fsfiles/xenial.rootfs.ext4" -O "rootfs.ext4"
  wget -N -q "https://s3.amazonaws.com/$S3_BUCKET/ci-artifacts/kernels/$TARGET/vmlinux-$kv.bin" -O "rootfs.vmlinux"
  wget -N -q "https://s3.amazonaws.com/$S3_BUCKET/img/alpine_demo/fsfiles/xenial.rootfs.id_rsa" -O "rootfs.id_rsa"
else
  wget -N -q "https://storage.googleapis.com/firecracker_data/rootfs.ext4" -O "rootfs.ext4"
  wget -N -q "https://storage.googleapis.com/firecracker_data/rootfs.vmlinux" -O "rootfs.vmlinux"
  wget -N -q "https://storage.googleapis.com/firecracker_data/rootfs.id_rsa" -O "rootfs.id_rsa"
fi

sudo chmod 400 rootfs.id_rsa

MASK_LONG="255.255.255.252"
BRIDGE_IP="$BRIDGE_PREFIX.1.1"

sudo ip link add name br0 type bridge
sudo ip addr add ${BRIDGE_IP}/16 dev br0
sudo ip link set br0 up

# get firectl
source ~/.bashrc # source for go
cd ~
git clone https://github.com/firecracker-microvm/firectl.git
cd firectl
go build
chmod +x firectl
sudo cp firectl /usr/local/bin/firectl

# install firecracker
cd ~
git clone https://github.com/firecracker-microvm/firecracker
cd firecracker
sudo tools/devtool build
toolchain="$(uname -m)-unknown-linux-musl"
sudo cp build/cargo_target/${toolchain}/debug/firecracker /usr/local/bin/firecracker