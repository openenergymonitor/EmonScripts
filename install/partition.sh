#!/bin/bash
# --------------------------------------------------------------------------------
# Partition an SD card for emonSD
#
# Run on a freshly flashed and booted Raspberry Pi OS, before install/init.sh.
# Splits the card into the emonSD layout:
#
#   p1  /boot/firmware    vfat   (unchanged)
#   p2  /                 ext4   shrunk to the chosen size, default 6 GB
#   p3  /var/opt/emoncms  ext2   1024 byte blocks, low write data partition
#
# Raspberry Pi OS grows the root partition to fill the card on first boot, and
# a mounted root filesystem cannot be shrunk. So this runs in two stages:
#
#   1. ./partition.sh   installs a one-off step in the initramfs and reboots.
#      Before root is mounted, that step checks root, shrinks it and adds
#      partition 3.
#   2. ./partition.sh   run again after the reboot: formats partition 3,
#      installs the emonSD fstab, removes the one-off step and reboots.
#
# Usage:
#     wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/install/partition.sh
#     chmod +x partition.sh && ./partition.sh
#
# Options:
#   --root-size N   root partition size in GB, skips the question
#   --yes           do not ask for confirmation
#   --branch NAME   EmonScripts branch to fetch the emonSD fstab from
#                   (default stable, only used when not run from a checkout)
# --------------------------------------------------------------------------------

DEFAULT_ROOT_GB=6
MIN_ROOT_GB=4
MIN_DATA_GB=1
SECTORS_PER_GB=2097152   # 1 GiB in 512 byte sectors

HOOK=/etc/initramfs-tools/hooks/emonsd_partition
PREMOUNT=/etc/initramfs-tools/scripts/local-premount/emonsd_partition
LOG=/run/emonsd_partition.log
DATADIR=/var/opt/emoncms

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

root_gb=""
assume_yes=0
branch=stable
while [ $# -gt 0 ]; do
    case "$1" in
        --root-size) root_gb=$2; shift ;;
        --yes) assume_yes=1 ;;
        --branch) branch=$2; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

die() { echo "ERROR: $1"; exit 1; }

export PATH=$PATH:/usr/sbin:/sbin

if [ "$EUID" = "0" ]; then
    die "run as the normal user with sudo access, not as root"
fi

# --------------------------------------------------------------------------------
# Where things are
# --------------------------------------------------------------------------------
cmdline=/boot/firmware/cmdline.txt
[ -f "$cmdline" ] || cmdline=/boot/cmdline.txt
[ -f "$cmdline" ] || die "cannot find cmdline.txt, is this Raspberry Pi OS?"

root_part=$(findmnt -no SOURCE /)
root_part_name=$(basename "$root_part")
disk_name=$(lsblk -no PKNAME "$root_part" 2>/dev/null)
disk=/dev/$disk_name
p3=/dev/${disk_name}p3

if [ "$disk_name" != "mmcblk0" ] || [ "$root_part_name" != "mmcblk0p2" ]; then
    die "root is $root_part, expected /dev/mmcblk0p2 (the emonSD fstab assumes an SD card)"
fi

flag_set() { grep -q 'emonsd_partition=' "$cmdline"; }

remove_initramfs_step() {
    sudo sed -i 's/ *emonsd_partition=[0-9]*//g' "$cmdline"
    sudo rm -f "$HOOK" "$PREMOUNT"
    echo "-- Rebuilding initramfs without the partition step"
    sudo update-initramfs -u -k all
}

ask_reboot() {
    if [ "$assume_yes" != "1" ]; then
        read -p "Reboot now? (y/n) " answer
        [ "$answer" = "y" ] || [ "$answer" = "Y" ] || { echo "Reboot when ready: sudo reboot"; exit 0; }
    fi
    sudo reboot
}

# ================================================================================
# Stage 2: partition 3 exists, finish off
# ================================================================================
if [ -b "$p3" ]; then
    echo "-------------------------------------------------------------"
    echo "emonSD partitioning: finishing"
    echo "-------------------------------------------------------------"
    [ -f "$LOG" ] && sed 's/^/   /' "$LOG"

    if mountpoint -q "$DATADIR" && ! flag_set && [ ! -f "$PREMOUNT" ]; then
        echo "Already done: $DATADIR is mounted from $(findmnt -no SOURCE "$DATADIR")"
        exit 0
    fi

    fstype=$(sudo blkid -p -s TYPE -o value "$p3" 2>/dev/null)
    if [ -z "$fstype" ]; then
        echo "-- Formatting $p3 as ext2 with 1024 byte blocks"
        # Small blocks cut the write load from emoncms' many small appends.
        # ext2 has no journal, which also reduces writes.
        # 1% reserved for root, not the default 5%: feed data is written by
        # www-data, which cannot use it, and the OS is on its own partition.
        sudo mkfs.ext2 -F -q -m 1 -b 1024 -L emondata "$p3" || die "mkfs.ext2 failed"
    elif [ "$fstype" != "ext2" ]; then
        die "$p3 already has a $fstype filesystem, not changing it"
    else
        echo "-- $p3 is already ext2"
    fi

    if ! grep -q "[[:space:]]$DATADIR[[:space:]]" /etc/fstab; then
        echo "-- Installing the emonSD fstab"
        fstab_tmp=$(mktemp)
        if [ -f "$DIR/../defaults/etc/fstab" ]; then
            cp "$DIR/../defaults/etc/fstab" "$fstab_tmp"
        else
            url=https://raw.githubusercontent.com/openenergymonitor/EmonScripts/$branch/defaults/etc/fstab
            curl -fsSL --retry 3 "$url" -o "$fstab_tmp" || die "could not download $url"
        fi
        grep -q "$DATADIR" "$fstab_tmp" || die "downloaded fstab does not mount $DATADIR, not installing it"
        sudo cp -a /etc/fstab /etc/fstab.orig
        sudo install -m 0644 "$fstab_tmp" /etc/fstab
        rm -f "$fstab_tmp"
        sudo systemctl daemon-reload
        echo "   original saved as /etc/fstab.orig"
    fi

    sudo mkdir -p "$DATADIR"
    if ! mountpoint -q "$DATADIR"; then
        sudo mount "$DATADIR" || die "could not mount $DATADIR"
    fi

    if flag_set || [ -f "$PREMOUNT" ]; then
        remove_initramfs_step
    fi

    echo
    df -h / "$DATADIR"
    echo
    echo "Partitioning done. Reboot, then run init.sh to build emonSD."
    ask_reboot
fi

# ================================================================================
# Partition step ran but partition 3 was not created
# ================================================================================
if flag_set && sudo sfdisk -d "$disk" 2>/dev/null | grep -q "^$p3 "; then
    echo "Partition 3 is in the partition table but the kernel has not loaded it yet."
    echo "Reboot and run this script again."
    ask_reboot
fi
if flag_set; then
    echo "The partition step was set up but partition 3 does not exist."
    if [ -f "$LOG" ]; then
        echo "Log from the last boot:"
        sed 's/^/   /' "$LOG"
    else
        echo "No log from the initramfs: the step did not run on the last boot."
    fi
    echo
    echo "Removing the partition step so it does not run again."
    remove_initramfs_step
    echo "Nothing was partitioned. Fix the problem above and run this script again."
    exit 1
fi

# ================================================================================
# Stage 1: checks
# ================================================================================
echo "-------------------------------------------------------------"
echo "emonSD partitioning"
echo "-------------------------------------------------------------"

grep -qw resize "$cmdline" && die "Raspberry Pi OS has not finished its first boot resize yet, reboot and run again"

[ "$(findmnt -no FSTYPE /)" = "ext4" ] || die "root filesystem is not ext4"

parts=$(lsblk -nlo TYPE "$disk" | grep -c part)
[ "$parts" = "2" ] || die "$disk has $parts partitions, expected 2 on a fresh Raspberry Pi OS card"

sudo sfdisk -d "$disk" 2>/dev/null | grep -q '^label: dos' || die "$disk does not have an MBR (dos) partition table"

if [ -d /var/www/emoncms ] || command -v mariadb >/dev/null 2>&1; then
    die "emoncms or mariadb is already installed. Partition a fresh card, before running init.sh"
fi

for tool in e2fsck resize2fs sfdisk mkfs.ext2 update-initramfs lsinitramfs; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool not found"
done

config_txt=$(dirname "$cmdline")/config.txt
if ! grep -qE '^(auto_initramfs=1|initramfs )' "$config_txt" 2>/dev/null; then
    die "the Pi is not booting with an initramfs (no auto_initramfs=1 in $config_txt)"
fi

disk_sectors=$(cat /sys/block/$disk_name/size)
p2_start=$(cat /sys/block/$disk_name/$root_part_name/start)
disk_gb=$(( disk_sectors / SECTORS_PER_GB ))
used_kb=$(df --output=used -k / | tail -n1)
used_gb=$(( (used_kb + 1048575) / 1048576 ))
max_root_gb=$(( (disk_sectors - p2_start) / SECTORS_PER_GB - MIN_DATA_GB ))

echo "Card: $disk, $disk_gb GB. Root currently uses $used_gb GB."
[ "$max_root_gb" -ge "$MIN_ROOT_GB" ] || die "card is too small"

# --------------------------------------------------------------------------------
# Root size
# --------------------------------------------------------------------------------
if [ -z "$root_gb" ]; then
    read -p "Root partition size in GB [$DEFAULT_ROOT_GB]: " root_gb
    root_gb=${root_gb:-$DEFAULT_ROOT_GB}
fi
[[ "$root_gb" =~ ^[0-9]+$ ]] || die "root size must be a whole number of GB"
[ "$root_gb" -ge "$MIN_ROOT_GB" ] || die "root size must be at least $MIN_ROOT_GB GB"
[ "$root_gb" -le "$max_root_gb" ] || die "root size can be at most $max_root_gb GB on this card"
[ "$root_gb" -gt $(( used_gb + 1 )) ] || die "root already uses $used_gb GB, choose a larger size"

root_sectors=$(( root_gb * SECTORS_PER_GB ))
data_gb=$(( (disk_sectors - p2_start - root_sectors) / SECTORS_PER_GB ))

echo
echo "  /                 $root_gb GB  ($root_part, ext4, shrunk)"
echo "  $DATADIR  about $data_gb GB  ($p3, ext2, new)"
echo
echo "The Pi will reboot. Partitioning happens during that boot, before root is"
echo "mounted. Then log in and run this script again to finish."
echo "If anything goes wrong the card may need reflashing: use a fresh card only."
echo

if [ "$assume_yes" != "1" ]; then
    read -p "Type 'yes' to continue: " confirm
    [ "$confirm" = "yes" ] || { echo "Nothing changed."; exit 1; }
fi

# --------------------------------------------------------------------------------
# Initramfs hook: copy the tools the partition step needs into the initramfs
# --------------------------------------------------------------------------------
echo "-- Installing initramfs partition step"
sudo tee "$HOOK" >/dev/null <<'EOF'
#!/bin/sh
# emonSD one-off partitioning, installed by EmonScripts install/partition.sh
PREREQ=""
prereqs () { echo "$PREREQ"; }
case "$1" in
  prereqs) prereqs; exit 0 ;;
esac
. /usr/share/initramfs-tools/hook-functions
for tool in e2fsck resize2fs sfdisk; do
  path=$(PATH=/usr/sbin:/sbin:/usr/bin:/bin command -v $tool)
  [ -n "$path" ] && copy_exec "$path" /sbin
done
exit 0
EOF

# --------------------------------------------------------------------------------
# Initramfs premount script: runs before root is mounted
#
# Written for a minimal initramfs shell: no sed, awk or grep.
# Never stops the boot: on any problem it logs and leaves the card as it was.
# The filesystem is shrunk before the partition table is touched, so a failure
# at any point leaves a filesystem that fits inside its partition.
# --------------------------------------------------------------------------------
sudo tee "$PREMOUNT" >/dev/null <<'EOF'
#!/bin/sh
# emonSD one-off partitioning, installed by EmonScripts install/partition.sh
PREREQ=""
prereqs () { echo "$PREREQ"; }
case "$1" in
  prereqs) prereqs; exit 0 ;;
esac

ROOT_SECTORS=""
for arg in $(cat /proc/cmdline); do
  case "$arg" in
    emonsd_partition=*) ROOT_SECTORS="${arg#emonsd_partition=}" ;;
  esac
done
[ -n "$ROOT_SECTORS" ] || exit 0

. /scripts/functions
. /scripts/local

LOG=/run/emonsd_partition.log
log () { echo "$1" >> "$LOG"; echo "emonsd_partition: $1"; }
stop () { log "$1"; log "card left unchanged from this point"; exit 0; }

log_begin_msg "emonSD: partitioning SD card"

local_device_setup "$ROOT" "root file system"
PART_NAME="${DEV#/dev/}"
DISK_NAME=""
for d in /sys/block/*/"$PART_NAME"; do
  [ -e "$d" ] || continue
  DISK_NAME="${d#/sys/block/}"
  DISK_NAME="${DISK_NAME%%/*}"
done
[ -n "$DISK_NAME" ] || stop "could not find the disk for $DEV"
DISK="/dev/$DISK_NAME"
log "root $DEV on $DISK, target size $ROOT_SECTORS sectors"

[ "$(cat /sys/block/$DISK_NAME/$PART_NAME/partition)" = "2" ] || stop "root is not partition 2"
[ -e "/sys/block/$DISK_NAME/${DISK_NAME}p3" ] && stop "partition 3 already exists, nothing to do"

P2_START=$(cat /sys/block/$DISK_NAME/$PART_NAME/start)
DISK_SECTORS=$(cat /sys/block/$DISK_NAME/size)
P3_START=$((P2_START + ROOT_SECTORS))
P3_SIZE=$((DISK_SECTORS - P3_START))
[ $((P3_START % 2048)) -eq 0 ] || stop "partition 3 start $P3_START is not aligned"
[ "$P3_SIZE" -gt 2097152 ] || stop "not enough space for partition 3"

log "checking root filesystem"
e2fsck -fy "$DEV" >> "$LOG" 2>&1
RET=$?
[ "$RET" -le 1 ] || stop "e2fsck failed ($RET)"

log "shrinking root filesystem"
resize2fs "$DEV" "${ROOT_SECTORS}s" >> "$LOG" 2>&1 || stop "resize2fs failed"

log "shrinking partition 2"
echo ",$ROOT_SECTORS" | sfdisk --no-reread --wipe never --wipe-partitions never -N 2 "$DISK" >> "$LOG" 2>&1 || stop "sfdisk could not shrink partition 2"

log "creating partition 3"
# This call lets sfdisk re-read the table, so the kernel knows about partition 3
echo "$P3_START,$P3_SIZE,83" | sfdisk --wipe never --wipe-partitions never --append "$DISK" >> "$LOG" 2>&1 || stop "sfdisk could not create partition 3"

blockdev --rereadpt "$DISK" >> "$LOG" 2>&1 || log "could not re-read the partition table"
wait_for_udev 10

log "done: partition 2 is $ROOT_SECTORS sectors, partition 3 starts at $P3_START"
log_end_msg
exit 0
EOF

sudo chmod 0755 "$HOOK" "$PREMOUNT"

echo "-- Adding emonsd_partition=$root_sectors to $cmdline"
sudo sed -i 's/ *emonsd_partition=[0-9]*//g; 1 s/$/ emonsd_partition='"$root_sectors"'/' "$cmdline"

echo "-- Rebuilding initramfs"
if ! sudo update-initramfs -u -k all; then
    echo "update-initramfs failed, undoing"
    remove_initramfs_step
    exit 1
fi

# Make sure the initramfs the Pi will boot actually contains the step and tools
initrd=/boot/initrd.img-$(uname -r)
contents=$(lsinitramfs "$initrd" 2>/dev/null)
for item in scripts/local-premount/emonsd_partition sbin/resize2fs sbin/e2fsck sbin/sfdisk; do
    if ! printf '%s\n' "$contents" | grep -q "$item\$"; then
        echo "$initrd does not contain $item, undoing"
        remove_initramfs_step
        exit 1
    fi
done
# The firmware boots a copy in the boot partition, check it was updated too
case "$(uname -r)" in
    *-2712) fw_initrd=$(dirname "$cmdline")/initramfs_2712 ;;
    *-v8)   fw_initrd=$(dirname "$cmdline")/initramfs8 ;;
    *)      fw_initrd="" ;;
esac
if [ -n "$fw_initrd" ] && [ -f "$fw_initrd" ] && ! cmp -s "$initrd" "$fw_initrd"; then
    echo "$fw_initrd was not updated from $initrd, undoing"
    remove_initramfs_step
    exit 1
fi
echo "-- $initrd contains the partition step"

echo
echo "Ready. After the reboot, log in and run this script again to finish."
ask_reboot
