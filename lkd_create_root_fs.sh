#!/usr/bin/env bash

IMG=lkd_qemu_image.qcow2
DIR=mount-point.dir

ROOT_PASSWD_HASH=$(openssl passwd -1 test) && \
qemu-img create $IMG 5g && \
mkfs.ext2 $IMG && \
mkdir $DIR && \
sudo mount -o loop $IMG $DIR && \
sudo debootstrap --arch amd64 bullseye $DIR && \
sudo sed -i -e "s#root:\*#root:${ROOT_PASSWD_HASH}#" $DIR/etc/shadow && \
echo "lkd-debian-qemu" | sudo tee $DIR/etc/hostname && \
sudo umount $DIR && \
rmdir $DIR && exit 0

exit 1
