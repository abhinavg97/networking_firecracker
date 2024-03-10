#!/bin/bash

if [ "$#" -ne 2 ]
then
  echo "Run like: parallel_start_many.sh [NUM_VMS]125 [BRIDGE_PREFIX]192.167"
  exit 1
fi

NUM_VMS=$1
BRIDGE_PREFIX=$2
BRIDGE_IP="${BRIDGE_PREFIX}.1.1"

for (( VM_INDEX=1; VM_INDEX<=$NUM_VMS; VM_INDEX++ ));
do
        TAP_DEV="tap${VM_INDEX}"
        TAP_IP="$(printf '%s.1.%s' ${BRIDGE_PREFIX} $(((2 * VM_INDEX + 2) )))"
        TUN_IP="$(printf '%s.1.%s' ${BRIDGE_PREFIX} $(((2 * VM_INDEX + 1) )))"
        DNS0_IP="8.8.8.8"

        sudo ip tuntap add $TAP_DEV mode tap
        sudo ip addr add $TAP_IP/16 dev $TAP_DEV
        sudo ip link set $TAP_DEV up
        sudo ip r del ${BRIDGE_PREFIX}.0.0/16 dev $TAP_DEV proto kernel scope link src $TAP_IP
        sudo ip link set dev $TAP_DEV master br0

        TAP_MAC=$(cat /sys/class/net/$TAP_DEV/address)

        nohup sudo firectl \
        --firecracker-binary=/usr/local/bin/firecracker \
        --kernel=$HOME/networking_firecracker/rootfs.vmlinux \
        --kernel-opts="init=/sbin/boottime_init panic=1 pci=off nomodules reboot=k tsc=reliable quiet i8042.nokbd i8042.noaux 8250.nr_uarts=0 ipv6.disable=1 ip=${TUN_IP}::${BRIDGE_IP}:::eth0:off:${DNS0_IP}" \
        --root-drive=$HOME/networking_firecracker/rootfs.ext4 \
        --log-level=Error \
        -l=error.log \
        --tap-device=$TAP_DEV/$TAP_MAC > /dev/null 2>&1  </dev/null &

        sleep 0.02
        DUMMY=10
done

sleep 10
sleep $((2*$NUM_VMS/10))