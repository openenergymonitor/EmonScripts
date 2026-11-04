#!/bin/bash
# --------------------------------------------------------------------------------
# Grow the emonSD data partition and its filesystem to fill the SD card
#
# Run as root at boot by emonsd-grow-data.service, before the data partition is
# mounted: ext2 can only be resized while it is not mounted. The service
# disables itself once this has succeeded. If this fails, the data partition is
# still mounted at its current size, and this runs again on the next boot.
#
# Safe to run again: each step does nothing if there is nothing to grow. Only
# the end of the partition moves, so existing data and the disk ID are kept.
# --------------------------------------------------------------------------------
set -euo pipefail

DATADIR=/var/opt/emoncms

die() { echo "ERROR: $*" >&2; exit 1; }

part=$(findmnt --fstab -no SOURCE --mountpoint "$DATADIR") || die "$DATADIR is not in /etc/fstab"
[ -b "$part" ] || die "$part is not a block device"
if findmnt -n --source "$part" >/dev/null; then
    die "$part is mounted"
fi

name=$(basename "$part")
sys=/sys/class/block/$name
[ -f "$sys/partition" ] || die "$part is not a partition"
number=$(cat "$sys/partition")
disk_name=$(basename "$(dirname "$(readlink -f "$sys")")")
disk=/dev/$disk_name

sfdisk -d "$disk" | grep -q '^label: dos' || die "$disk does not have an MBR (dos) partition table"

# All sizes in /sys are in 512 byte sectors
start=$(cat "$sys/start")
size=$(cat "$sys/size")
disk_size=$(cat "/sys/class/block/$disk_name/size")

for other in "/sys/class/block/$disk_name/$disk_name"*; do
    [ "$(cat "$other/start")" -le "$start" ] || die "$part is not the last partition on $disk"
done

unused=$(( disk_size - start - size ))
if [ "$unused" -ge 2048 ]; then
    echo "Growing partition $number of $disk by $(( unused / 2048 )) MB"
    # Root is on the same disk, so the kernel cannot re-read the whole table:
    # write it without re-reading, then update just this partition
    echo ", +" | sfdisk -q --no-reread --no-tell-kernel --wipe never --wipe-partitions never -N "$number" "$disk"
    partx --update --nr "$number" "$disk"
    [ "$(cat "$sys/size")" -gt "$size" ] || die "the kernel did not see the new size of $part"
else
    echo "Partition $number of $disk already fills the card"
fi

# Exit status 1 means problems were found and corrected
fsck_result=0
e2fsck -fy "$part" || fsck_result=$?
[ "$fsck_result" -le 1 ] || die "e2fsck failed with status $fsck_result"

# Does nothing if the filesystem already fills the partition
resize2fs "$part"

echo "$DATADIR will have $(( $(cat "$sys/size") / 2097152 )) GB"
