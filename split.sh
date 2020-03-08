#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

IMG=$1
# root_id is taken from the raspbian image
ROOT_PARTUUID=$(openssl rand -hex 4)
# boot_id can be anything, except the same as root_id
BOOT_PARTUUID=$(openssl rand -hex 4)

while [ "$BOOT_PARTUUID" = "$ROOT_PARTUUID" ]; do
	BOOT_ID=$(openssl rand -hex 4)
done

LOOP=$( losetup --show -P -f "$IMG" )

BOOT_LOOP=${LOOP}p1
ROOT_LOOP=${LOOP}p2

cat $BOOT_LOOP > boot_part.img
cat $ROOT_LOOP > root_part.img

losetup -d $LOOP

mkdir -p image

dd if=/dev/zero of=image/boot.img count=1 bs=1MiB
cp image/boot.img image/root.img

cat boot_part.img >> image/boot.img
cat root_part.img >> image/root.img

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk image/boot.img
	o	# clear partition table
	n	# create new partition
	p	# primary partition
	1	# partition number 1
	2048	# first sector position
		# last sector - default value
	n	# do not remove signature
	t	# configure partition type
	c	# W95 FAT32 LBA
	x	# open expert menu
	i	# configure disk identifier
	0x${BOOT_PARTUUID}	# set partition id
	r	# return to main menu
	a	# set partition bootable
	w	# write partition table
	q	# quit
EOF

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk image/root.img
	o	# clear partition table
	n	# create new partition
	p	# primary partition
	1	# partition number 1
	2048	# first sector position
		# last sector - default value
	n	# do not remove signature
	t	# configure partition type
	83	# Linux
	x	# open expert menu
	i	# configure disk identifier
	0x${ROOT_PARTUUID}	# set partition id
	r	# return to main menu
	w	# write partition table
	q	# quit
EOF

rm -f boot_part.img
rm -f root_part.img

chown nick:nick image/boot.img
chown nick:nick image/root.img

LOOP=$( losetup --show -P -f "image/boot.img" )
BOOT_LOOP=${LOOP}p1
mkdir -p mount_dir
mount $BOOT_LOOP mount_dir

# updatte the PARTUUID for the root partition
sed -i -r "s/PARTUUID=[0-9a-fA-F]{8}-[0-9]{2}/PARTUUID=${ROOT_PARTUUID}-01/" mount_dir/cmdline.txt

# stop init_resize as it wont work
sed -i 's| init=/usr/lib/raspi-config/init_resize\.sh||' mount_dir/cmdline.txt
sed -i "s/ quiet//g" mount_dir/cmdline.txt

umount mount_dir
losetup -d $LOOP

LOOP=$( losetup --show -P -f "image/root.img" )
ROOT_LOOP=${LOOP}p1
mount $ROOT_LOOP mount_dir

while read line; do
    line=($line)
    if [ "${line[1]}" = "/" ]; then
        FSTAB_ROOT_PARTUUID=${line[0]/PARTUUID=/}
    elif [ "${line[1]}" = "/boot" ]; then
        FSTAB_BOOT_PARTUUID=${line[0]/PARTUUID=/}
    fi
done < mount_dir/etc/fstab

sed -i -r "s/${FSTAB_ROOT_PARTUUID}/${ROOT_PARTUUID}-01/g" mount_dir/etc/fstab
sed -i -r "s/${FSTAB_BOOT_PARTUUID}/${BOOT_PARTUUID}-01/g" mount_dir/etc/fstab

umount mount_dir
losetup -d $LOOP
