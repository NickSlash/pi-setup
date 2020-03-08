# pi-setup
some simple bash scripts to automate modification of a raspbian image for use on Raspberry Pi 4 with a USB rootfs.

it works *(for me atleast)* .

## start&#46;sh `<image file>`
launch the image using systemd-nspawn so that you can update and install extra packages, add/remove users.
## stop&#46;sh
for use after `start.sh`. check the filesystems, zeros empty space and un-mount loop devices.
## merge&#46;sh `<image file>`
mounts the image and rsync's the content of `merge_dir`.
## split&#46;sh
splits the image into a `root.img` and `boot.img`, modifies fstab and `cmdline.txt` with correct partuuid and removes t$
## merge_dir scripts
`resize-rootfs` resizes the rootfs to fill the available space
`set-hostname` sets the hostname
## merge_dir services
`rfkill-unblock.service` unblock wifi and bluetooth
`ssh.service` enable ssh
