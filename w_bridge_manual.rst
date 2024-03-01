
SB_ID=27
TAP_DEV="tap${SB_ID}"
BRIDGE_IP="192.167.1.1"

MASK_LONG="255.255.255.2"
TAP_IP="$(printf '192.167.1.%s' $(((2 * SB_ID + 2) )))"
TUN_IP="$(printf '192.167.1.%s' $(((2 * SB_ID + 1) )))"
DNS0_IP="8.8.8.8"

sudo ip tuntap add $TAP_DEV mode tap
sudo ip addr add $TAP_IP/16 dev $TAP_DEV
sudo ip link set $TAP_DEV up
sudo ip r del 192.167.0.0/16 dev $TAP_DEV proto kernel scope link src $TAP_IP
sudo ip link set dev $TAP_DEV master br0

TAP_MAC=$(cat /sys/class/net/$TAP_DEV/address)

sudo firectl \
        --firecracker-binary=/usr/local/bin/firecracker \
        --kernel=rootfs.vmlinux \
        --kernel-opts="init=/sbin/boottime_init panic=1 pci=off nomodules reboot=k tsc=reliable quiet i8042.nokbd i8042.noaux 8250.nr_uarts=0 ipv6.disable=1 ip=${TUN_IP}::${BRIDGE_IP}:::eth0:off:${DNS0_IP}" \
        --root-drive=rootfs.ext4 \
        --log-level=Error \
        -l=error.log \
        --tap-device=$TAP_DEV/$TAP_MAC > /dev/null 2>&1 &


# 2>&1 1>/dev/null
        # --kernel-opts="console=ttyS0 noapic reboot=k panic=1 pci=off nomodules rw ip=${FC_IP}::${BRIDGE_IP}:${MASK_LONG}::eth0:off" \


        # "nfsrootdebug console=ttyS0 noapic panic=1 pci=off nomodules reboot=k rw ipv6.disable=1 ip=${TUN_IP}::${TAP_IP}:::eth0:off:${DNS0_IP}"

        # init=/sbin/boottime_init console=ttyS0 noapic reboot=k tsc=reliable quiet i8042.nokbd i8042.noaux 8250.nr_uarts=0 panic=1 pci=off nomodules rw ip=${TUN_IP}::${BRIDGE_IP}:${MASK_LONG}::eth0:off:${DNS0_IP}