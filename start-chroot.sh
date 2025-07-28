#!/usr/bin/env bash
if [ $EUID -ne 0 ]; then
	echo "Run it as root"
	exit 1
fi
if [ -z "$1" ]; then
	read -p "Path to chroot directory: " CHROOT_DIR
else
	CHROOT_DIR="$1"
fi
if [ ! -d "$CHROOT_DIR" ]; then
  echo "Error: Chroot directory $CHROOT_DIR does not exist."
  exit 1
fi
mount | grep "$CHROOT_DIR/proc" > /dev/null
proc_result="$?"
if [ "$proc_result" -eq 0 ]; then
	echo "/proc already mounted"
else 
	echo "Mounting /proc"
	mount -t proc /proc "$CHROOT_DIR/proc"
fi
mount | grep "$CHROOT_DIR/dev" > /dev/null
dev_result="$?"
if [ "$dev_result" -eq 0 ]; then
	echo "/dev already mounted"
else
	echo "Mounting /dev"
	mount --bind /dev "$CHROOT_DIR/dev"
fi
mount | grep "$CHROOT_DIR/dev/pts" > /dev/null
pts_result="$?"
if [ "$pts_result" -eq 0 ]; then
        echo "/dev/pts already mounted"
else
        echo "Mounting /dev/pts"
	mount --bind /dev/pts "$CHROOT_DIR/dev/pts"
fi
mount | grep "$CHROOT_DIR/sys" > /dev/null
sys_result="$?"
if [ "$sys_result" -eq 0 ]; then
        echo "/sys already mounted"
else
        echo "Mounting /sys"
mount --rbind /sys "$CHROOT_DIR/sys"
fi
#unmount on exit
cleanup() {
umount "$CHROOT_DIR/dev/pts"
umount "$CHROOT_DIR/dev"
umount "$CHROOT_DIR/sys"
umount "$CHROOT_DIR/proc"
}
trap cleanup EXIT

#Enter the chroot
#I usually use zsh as the standard shell
if [ -f "$CHROOT_DIR/usr/bin/zsh" ]; then
	chroot "$CHROOT_DIR" /usr/bin/zsh
else
    if [ -f "$CHROOT_DIR/bin/bash" ]; then
	    chroot "$CHROOT_DIR" /bin/bash
    else
        chroot "$CHROOT_DIR" /bin/sh
    fi
fi
