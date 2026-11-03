#!/bin/bash
# --------------------------------------------------------------------------------
# Build an emonSD image from Raspberry Pi OS Lite, without a Raspberry Pi
#
# Downloads Raspberry Pi OS Lite (64-bit), lays out the emonSD partitions,
# then runs install/main.sh and install/prepare_image.sh inside the image with
# systemd-nspawn. On a non-arm64 machine qemu user emulation runs the arm64
# programs, which is slow: expect one to two hours.
#
# EmonScripts is copied into the image from this checkout, at its current
# commit (uncommitted changes are not included), so an unpushed branch can be
# built. Everything else (emoncms, modules, emonhub) is cloned from GitHub.
#
# Requirements (Debian/Ubuntu):
#     sudo apt install systemd-container qemu-user-binfmt
#     (older releases: qemu-user-static instead of qemu-user-binfmt)
#
# Usage:
#     sudo image/build.sh [options]
#
# Options:
#   --root-size N   root partition size in GB (default 5)
#   --data-size N   data partition size in GB (default 2). It does not grow to
#                   fill the SD card yet: use emonSDexpand after flashing.
#   --base URL      Raspberry Pi OS image to start from (.img.xz)
#                   (default: latest Raspberry Pi OS Lite 64-bit)
#   --work DIR      work and output directory (default ~/emonsd-build)
#   --no-compress   leave the image uncompressed
#
# Output: DIR/emonSD-DDMMMYY.img.xz, its .sha256 and the build log.
# --------------------------------------------------------------------------------
set -euo pipefail

ROOT_GB=5
DATA_GB=2
BASE_URL=https://downloads.raspberrypi.com/raspios_lite_arm64_latest
COMPRESS=1
SECTORS_PER_GB=2097152
GITHUB_URL=https://github.com/openenergymonitor/EmonScripts.git

REPO="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )"
BUILD_USER=${SUDO_USER:-root}
WORK=$(getent passwd "$BUILD_USER" | cut -d: -f6)/emonsd-build

while [ $# -gt 0 ]; do
    case "$1" in
        --root-size) ROOT_GB=$2; shift ;;
        --data-size) DATA_GB=$2; shift ;;
        --base) BASE_URL=$2; shift ;;
        --work) WORK=$2; shift ;;
        --no-compress) COMPRESS=0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

die() { echo "ERROR: $*" >&2; exit 1; }
step() { echo; echo "=== $* ($(date +%H:%M:%S))"; }

[ "$EUID" = "0" ] || die "run with sudo"
# The work directory is written to as root: only allow a dedicated directory
WORK=${WORK%/}
[[ "$WORK" == /* ]] || die "--work must be an absolute path"
[[ "$WORK" != *..* ]] || die "--work must not contain '..'"
case "$WORK" in
    /|/root|/home|/usr|/usr/*|/etc|/etc/*|/var|/opt|/boot|/boot/*|/tmp|/dev*|/proc*|/sys*)
        die "--work $WORK is not safe, use a dedicated directory" ;;
esac
[ "$WORK" != "$(getent passwd "$BUILD_USER" | cut -d: -f6)" ] || die "--work must not be your home directory itself"
[[ "$ROOT_GB" =~ ^[0-9]+$ ]] && [ "$ROOT_GB" -ge 4 ] || die "--root-size must be at least 4"
[[ "$DATA_GB" =~ ^[0-9]+$ ]] && [ "$DATA_GB" -ge 1 ] || die "--data-size must be at least 1"

# --------------------------------------------------------------------------------
step "Checking requirements"
# --------------------------------------------------------------------------------
for tool in systemd-nspawn losetup sfdisk e2fsck resize2fs mkfs.ext2 xz curl sha256sum git mountpoint; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool not found (sudo apt install systemd-container qemu-user-binfmt)"
done

if [ "$(uname -m)" != "aarch64" ]; then
    binfmt=""
    for f in /proc/sys/fs/binfmt_misc/*; do
        if grep -q 'aarch64' "$f" 2>/dev/null && grep -q '^enabled' "$f"; then binfmt=$f; fi
    done
    [ -n "$binfmt" ] || die "no arm64 emulation registered (sudo apt install qemu-user-binfmt)"
    # F (fix binary) lets the emulator run inside the container's filesystem
    grep -q '^flags:.*F' "$binfmt" || die "$binfmt is registered without the F flag, systemd-nspawn needs it"
    echo "arm64 emulation: $binfmt"
fi

# Running as root on the build user's checkout: tell git that is expected,
# and never write to it (GIT_OPTIONAL_LOCKS=0 stops git status refreshing
# .git/index, which would leave it owned by root)
export GIT_OPTIONAL_LOCKS=0
git() { command git -c safe.directory='*' "$@"; }

branch=$(git -C "$REPO" rev-parse --abbrev-ref HEAD)
commit=$(git -C "$REPO" rev-parse --short HEAD)
if [ -n "$(git -C "$REPO" status --porcelain --untracked-files=no)" ]; then
    echo "WARNING: $REPO has uncommitted changes, they are not included in the image"
fi
echo "EmonScripts: $branch at $commit"

mkdir -p "$WORK/download"
chown "$BUILD_USER" "$WORK" 2>/dev/null || true
LOG="$WORK/build.log"
exec > >(tee "$LOG") 2>&1
echo "Build log: $LOG"

IMG="$WORK/emonsd.img"
ROOT="$WORK/root"
LOOP=""

cleanup() {
    set +e
    if mountpoint -q "$ROOT" 2>/dev/null; then
        umount -R "$ROOT"
    fi
    [ -n "$LOOP" ] && losetup -d "$LOOP" 2>/dev/null
}
trap cleanup EXIT

# --------------------------------------------------------------------------------
step "Downloading Raspberry Pi OS"
# --------------------------------------------------------------------------------
base_final=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$BASE_URL")
base_file="$WORK/download/$(basename "$base_final")"
echo "$base_final"
if [ ! -f "$base_file" ]; then
    curl -fL --retry 3 -o "$base_file.part" "$base_final"
    mv "$base_file.part" "$base_file"
fi
expected=$(curl -fsSL "$base_final.sha256" | cut -d' ' -f1)
actual=$(sha256sum "$base_file" | cut -d' ' -f1)
[ -n "$expected" ] && [ "$expected" = "$actual" ] || die "sha256 mismatch for $base_file"
echo "sha256 ok: $actual"

step "Decompressing"
xz -dc "$base_file" > "$IMG"

# --------------------------------------------------------------------------------
step "Partitioning: root $ROOT_GB GB, data $DATA_GB GB"
# --------------------------------------------------------------------------------
p2_start=$(sfdisk -d "$IMG" | sed -n 's/.*2 : start= *\([0-9]*\),.*/\1/p')
[ -n "$p2_start" ] || die "could not read partition 2 from $IMG"
[ "$(sfdisk -d "$IMG" | grep -c ' : start=')" = "2" ] || die "base image does not have 2 partitions"
label_id=$(sfdisk -d "$IMG" | sed -n 's/^label-id: //p')

root_sectors=$((ROOT_GB * SECTORS_PER_GB))
p3_start=$((p2_start + root_sectors))
data_sectors=$((DATA_GB * SECTORS_PER_GB))
[ $((p3_start % 2048)) -eq 0 ] || die "partition 3 start $p3_start is not aligned"

current_root=$(sfdisk -d "$IMG" | sed -n 's/.*2 : start= *[0-9]*, size= *\([0-9]*\),.*/\1/p')
[ "$current_root" -le "$root_sectors" ] || die "base image root partition is larger than $ROOT_GB GB"

truncate -s $(( (p3_start + data_sectors) * 512 )) "$IMG"
echo ",$root_sectors" | sfdisk -q --wipe never --wipe-partitions never -N 2 "$IMG"
echo "$p3_start,$data_sectors,83" | sfdisk -q --wipe never --wipe-partitions never --append "$IMG"
[ "$(sfdisk -d "$IMG" | sed -n 's/^label-id: //p')" = "$label_id" ] || die "disk ID changed"
sfdisk -l "$IMG"

LOOP=$(losetup -Pf --show "$IMG")
udevadm settle 2>/dev/null || sleep 2
case "$LOOP" in /dev/loop[0-9]*) ;; *) die "unexpected loop device '$LOOP'" ;; esac
for n in 1 2 3; do
    [ -b "${LOOP}p$n" ] || die "${LOOP}p$n does not exist"
done
e2fsck -fy "${LOOP}p2" || [ $? -le 1 ]
resize2fs "${LOOP}p2"
mkfs.ext2 -F -q -b 1024 -L emondata "${LOOP}p3"

# --------------------------------------------------------------------------------
step "Mounting"
# --------------------------------------------------------------------------------
mkdir -p "$ROOT"
mount "${LOOP}p2" "$ROOT"
mount "${LOOP}p1" "$ROOT/boot/firmware"
mkdir -p "$ROOT/var/opt/emoncms"
mount "${LOOP}p3" "$ROOT/var/opt/emoncms"

# Raspberry Pi OS would try to grow root over partition 3 on first boot
sed -i 's/ resize\b//' "$ROOT/boot/firmware/cmdline.txt"
echo "cmdline.txt: $(cat "$ROOT/boot/firmware/cmdline.txt")"

# emonSD fstab: the three partitions plus tmpfs mounts
cp "$ROOT/etc/fstab" "$ROOT/etc/fstab.orig"
install -m 0644 "$REPO/defaults/etc/fstab" "$ROOT/etc/fstab"

# EmonScripts from this checkout, pointing at GitHub for later updates
mkdir -p "$ROOT/opt/openenergymonitor" "$ROOT/opt/emoncms"
git clone -q --no-hardlinks --branch "$branch" "$REPO" "$ROOT/opt/openenergymonitor/EmonScripts"
git -C "$ROOT/opt/openenergymonitor/EmonScripts" remote set-url origin "$GITHUB_URL"

# --------------------------------------------------------------------------------
# Runs inside the image. No systemd is running, so services are installed and
# enabled but not started; MariaDB is started by hand because the build needs
# the database.
# --------------------------------------------------------------------------------
cat > "$ROOT/root/emonsd-build-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive

for dir in /boot/firmware /var/opt/emoncms; do
    mountpoint -q "$dir" || { echo "ERROR: $dir is not mounted inside the container"; exit 1; }
done

echo "=== User pi"
first_user=$(getent passwd 1000 | cut -d: -f1 || true)
if [ -n "$first_user" ] && [ -x /usr/lib/userconf-pi/userconf ]; then
    # Raspberry Pi's own rename tool, as used by Imager's settings
    /usr/lib/userconf-pi/userconf pi "" || true
elif [ -z "$first_user" ]; then
    useradd -m -s /bin/bash pi
fi
getent passwd pi >/dev/null || { echo "ERROR: user pi was not created"; exit 1; }
echo "pi:emonsd" | chpasswd
for group in sudo adm dialout cdrom audio video plugdev games users input render netdev gpio i2c spi; do
    getent group "$group" >/dev/null && usermod -aG "$group" pi
done
echo "pi ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_pi-nopasswd
chmod 0440 /etc/sudoers.d/010_pi-nopasswd
# No first boot username wizard: pi is already set up
systemctl disable userconfig.service 2>/dev/null || true

echo "=== Hostname emonpi"
echo emonpi > /etc/hostname
sed -i 's/\braspberrypi\b/emonpi/g' /etc/hosts

chown -R pi:pi /opt/openenergymonitor /opt/emoncms

echo "=== Starting MariaDB for the build"
apt-get update
apt-get install -y mariadb-server
mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld
# Socket only: the container shares the host's network, which may run its own MariaDB
mariadbd-safe --skip-syslog --skip-networking >/dev/null 2>&1 &
for i in $(seq 60); do
    mariadb-admin ping >/dev/null 2>&1 && break
    sleep 2
done
mariadb-admin ping || { echo "ERROR: MariaDB did not start"; exit 1; }

echo "=== install/main.sh"
runuser -l pi -c 'cd /opt/openenergymonitor/EmonScripts/install && ./main.sh --yes'
build_result=$?
cp /home/pi/main.sh.log /root/emonsd-main.sh.log 2>/dev/null

echo "=== Stopping MariaDB"
mariadb-admin shutdown
sleep 3

echo "=== install/prepare_image.sh"
runuser -l pi -c 'cd /opt/openenergymonitor/EmonScripts/install && ./prepare_image.sh --yes --skip-verify --no-shutdown'

exit $build_result
INSIDE
chmod +x "$ROOT/root/emonsd-build-inside.sh"

# DNS for the build: a copy of the host's settings in the image, restored
# afterwards. Nothing in the container can write to the host's resolv.conf.
mv "$ROOT/etc/resolv.conf" "$ROOT/etc/resolv.conf.emonsd-build"
cat /etc/resolv.conf > "$ROOT/etc/resolv.conf"
if grep -q '^nameserver 127\.' "$ROOT/etc/resolv.conf"; then
    # systemd-resolved stub: use the real upstream servers
    [ -f /run/systemd/resolve/resolv.conf ] && cat /run/systemd/resolve/resolv.conf > "$ROOT/etc/resolv.conf"
fi

# Stop package installs from starting services through init.d fallbacks
printf '#!/bin/sh\nexit 101\n' > "$ROOT/usr/sbin/policy-rc.d"
chmod +x "$ROOT/usr/sbin/policy-rc.d"

# --------------------------------------------------------------------------------
step "Building inside the image (this is the long part)"
# --------------------------------------------------------------------------------
set +e
# The container shares the host's network but cannot change it: no network
# admin (firewall, WiFi), no kernel modules, no clock changes. It sees only
# the image's files and no host disks.
systemd-nspawn -q -D "$ROOT" --as-pid2 --machine=emonsd-build --register=no \
    --console=pipe --resolv-conf=off --timezone=off \
    --drop-capability=CAP_NET_ADMIN,CAP_SYS_MODULE,CAP_SYS_TIME \
    /root/emonsd-build-inside.sh
inside_result=$?
set -e

mv "$ROOT/root/emonsd-main.sh.log" "$WORK/main.sh.log" 2>/dev/null || true
rm -f "$ROOT/root/emonsd-build-inside.sh" "$ROOT/usr/sbin/policy-rc.d" "$ROOT/etc/resolv.conf"
mv "$ROOT/etc/resolv.conf.emonsd-build" "$ROOT/etc/resolv.conf"
echo "main.sh log: $WORK/main.sh.log"
[ "$inside_result" = "0" ] || die "build inside the image failed ($inside_result), see $LOG and $WORK/main.sh.log"

# --------------------------------------------------------------------------------
step "Final clean up"
# --------------------------------------------------------------------------------
# Done here as well as in prepare_image.sh: inside the container these can be
# masked by files systemd-nspawn mounts over them
mountpoint -q "$ROOT" || die "$ROOT is not mounted, not cleaning up"
truncate -s 0 "$ROOT/etc/machine-id"
[ -f "$ROOT/var/lib/dbus/machine-id" ] && [ ! -L "$ROOT/var/lib/dbus/machine-id" ] && rm -f "$ROOT/var/lib/dbus/machine-id"
rm -f "$ROOT"/etc/ssh/ssh_host_* "$ROOT/root/.bash_history"

image_name=$(ls "$ROOT/boot" | grep '^emonSD-' | head -n1)
[ -n "$image_name" ] || die "no /boot/emonSD-* version file, the build did not complete"
echo "Image version: $image_name"

umount -R "$ROOT"
e2fsck -fy "${LOOP}p2" || [ $? -le 1 ]
e2fsck -fy "${LOOP}p3" || [ $? -le 1 ]
losetup -d "$LOOP"
LOOP=""

out="$WORK/$image_name.img"
mv "$IMG" "$out"

if [ "$COMPRESS" = "1" ]; then
    step "Compressing"
    xz -T0 -f "$out"
    out="$out.xz"
fi
(cd "$WORK" && sha256sum "$(basename "$out")" > "$(basename "$out").sha256")
rmdir "$ROOT" 2>/dev/null || true
chown -R "$BUILD_USER" "$WORK/download" 2>/dev/null || true
chown "$BUILD_USER" "$WORK" "$out" "$out.sha256" "$LOG" "$WORK/main.sh.log" 2>/dev/null || true

step "Done"
ls -lh "$out"
echo "Flash with Raspberry Pi Imager: Choose OS > Use custom > $out"
