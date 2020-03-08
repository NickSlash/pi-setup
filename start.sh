#!/bin/bash
#
# Usage: sudo ./start-container
#
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

if [ -z "$1" ]
then
echo "Usage: sudo ./start.sh <image file>"
exit
fi

IMG=$1

if [ -f start.loop ]; then

	echo "Error: Container Active, Unload First"
	exit

fi

LOOP=$( losetup --show -P -f "$IMG" )

printf "%s" "$LOOP" > start.loop

mkdir -p mount_dir

mount -v ${LOOP}p2 mount_dir
mount -v ${LOOP}p1 mount_dir/boot

systemd-nspawn --bind /usr/bin/qemu-arm-static --directory mount_dir/raspbian
