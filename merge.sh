#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

if [ -z "$1" ]; then
	echo "Usage: sudo ./merge.sh <image>"
	echo "Description: Merge the <merge> folder onto a Raspbian Image"
	exit 1
fi

LOOP=$( losetup --show -P -f "$1" )
printf "%s" "$LOOP" > "merge.loop"

mkdir -p mount_dir

mount -v ${LOOP}p2 mount_dir
mount -v ${LOOP}p1 mount_dir/boot

rsync -a merge_dir/ mount_dir/

umount -v mount_dir/{boot,}

losetup -d $LOOP
sync
rmdir mount_dir

rm merge.loop

