#!/bin/bash

if [ -f "~/raspbian/loop.var" ]; then
	echo "Error: No Active Container"
	exit
fi

LOOP=$( cat start.loop )

sudo umount -v mount_dir/{boot,}

sudo e2fsck -f ${LOOP}p2
sudo zerofree -v ${LOOP}p2

sudo losetup -d $LOOP
sync
rm start.loop
rmdir mount_dir
echo "Complete"

