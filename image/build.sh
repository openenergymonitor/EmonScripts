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
#     sudo apt install systemd-container qemu-user-binfmt passt
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

# Rebuild the register line for a binfmt_misc entry from its /proc file
binfmt_line() {
    local f=$1
    printf ':%s:M:%s:%s:%s:%s:%s' "$(basename "$f")" \
        "$(sed -n 's/^offset //p' "$f")" \
        "$(sed -n 's/^magic //p' "$f" | sed 's/../\\x&/g')" \
        "$(sed -n 's/^mask //p' "$f" | sed 's/../\\x&/g')" \
        "$(sed -n 's/^interpreter //p' "$f")" \
        "$(sed -n 's/^flags: *//p' "$f")"
}
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
for tool in systemd-nspawn pasta ip losetup sfdisk e2fsck resize2fs mkfs.ext2 xz curl sha256sum git mountpoint; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool not found (sudo apt install systemd-container qemu-user-binfmt passt)"
done

if [ "$(uname -m)" != "aarch64" ]; then
    binfmt=""
    # Match on what the entry handles, not its name: little-endian 64-bit ELF
    # (7f454c46 02 01) for machine aarch64 (b7 00). qemu-aarch64_be also has
    # aarch64 in its name but is big-endian, and nothing in the image uses it.
    for f in /proc/sys/fs/binfmt_misc/*; do
        case "$(basename "$f")" in register|status) continue ;; esac
        [ -f "$f" ] || continue
        if grep -q '^enabled' "$f" && grep -qE '^magic 7f454c460201.*0200b700$' "$f"; then
            binfmt=$f
        fi
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
APPARMOR_PROFILE="$WORK/emonsd-build.apparmor"
APPARMOR_LOADED=0
BINFMT_ORIG=""
NETNS=""
NETNS_TMP=""
PASTA_PID=""

cleanup() {
    set +e
    if [ -n "$PASTA_PID" ]; then
        kill "$PASTA_PID" 2>/dev/null
        # pasta holds the namespace open until it exits, which blocks the umount
        wait "$PASTA_PID" 2>/dev/null
    fi
    if [ -n "$NETNS_TMP" ]; then
        umount "$NETNS_TMP" 2>/dev/null
        rm -f "$NETNS_TMP"
    fi
    if [ -n "$NETNS" ]; then
        ip netns delete "$NETNS" 2>/dev/null && echo "Build network namespace removed"
    fi
    if mountpoint -q "$ROOT" 2>/dev/null; then
        umount -R "$ROOT"
    fi
    [ -n "$LOOP" ] && losetup -d "$LOOP" 2>/dev/null
    if [ "$APPARMOR_LOADED" = "1" ]; then
        apparmor_parser -R "$APPARMOR_PROFILE" 2>/dev/null
        echo "AppArmor build profile unloaded"
    fi
    rm -f "$APPARMOR_PROFILE"
    if [ -n "$BINFMT_ORIG" ]; then
        name=$(echo "$BINFMT_ORIG" | cut -d: -f2)
        echo -1 > "/proc/sys/fs/binfmt_misc/$name" 2>/dev/null
        if printf '%s' "$BINFMT_ORIG" > /proc/sys/fs/binfmt_misc/register; then
            echo "arm64 emulation registration restored"
        else
            echo "WARNING: could not restore arm64 emulation, run: sudo systemctl restart systemd-binfmt"
        fi
    fi
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
# Runs inside the image, in its own network namespace (see pasta below). No
# systemd is running: SYSTEMD_OFFLINE=1 makes systemctl enable/disable edit
# unit files directly and skip start/restart. MariaDB is started by hand
# because the build needs the database.
# --------------------------------------------------------------------------------
cat > "$ROOT/root/emonsd-build-inside.sh" <<'INSIDE'
#!/bin/bash
set -uo pipefail
export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export SYSTEMD_OFFLINE=1

fail() { echo "ERROR: $*"; exit 1; }

for dir in /boot/firmware /var/opt/emoncms; do
    mountpoint -q "$dir" || fail "$dir is not mounted inside the container"
done
# /var/lock points into /run, which starts empty in the container
mkdir -p /run/lock

echo "=== Network"
getent hosts github.com >/dev/null || fail "no DNS inside the container"
echo "ok"

echo "=== User pi"
first_user=$(getent passwd 1000 | cut -d: -f1 || true)
if [ -n "$first_user" ] && [ -x /usr/lib/userconf-pi/userconf ]; then
    # Raspberry Pi's own rename tool, as used by Imager's settings
    /usr/lib/userconf-pi/userconf pi "" || true
elif [ -z "$first_user" ]; then
    useradd -m -s /bin/bash pi
fi
getent passwd pi >/dev/null || fail "user pi was not created"
echo "pi:emonsd" | chpasswd
for group in sudo adm dialout cdrom audio video plugdev games users input render netdev gpio i2c spi; do
    getent group "$group" >/dev/null && usermod -aG "$group" pi
done
echo "pi ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_pi-nopasswd
chmod 0440 /etc/sudoers.d/010_pi-nopasswd
# Build only: keep SYSTEMD_OFFLINE through sudo (removed after the build)
echo 'Defaults env_keep += "SYSTEMD_OFFLINE"' > /etc/sudoers.d/zz-emonsd-build
chmod 0440 /etc/sudoers.d/zz-emonsd-build
# No first boot username wizard: pi is already set up
systemctl disable userconfig.service 2>/dev/null || true

echo "=== Checking pi can use sudo"
if ! runuser -l pi -c 'sudo -n true'; then
    echo "--- diagnostics: root"
    grep -E '^(NoNewPrivs|Seccomp|CapEff|CapBnd):' /proc/self/status
    echo "apparmor: $(cat /proc/self/attr/current 2>/dev/null)"
    findmnt -no TARGET,FSTYPE,OPTIONS -T /usr/bin/sudo
    echo "--- diagnostics: pi"
    runuser -u pi -- grep -E '^(Uid|NoNewPrivs|Seccomp|CapBnd):' /proc/self/status
    runuser -u pi -- /usr/bin/sudo -n id 2>&1
    fail "sudo does not work for pi inside the image"
fi
echo "ok"

echo "=== Hostname emonpi"
echo emonpi > /etc/hostname
sed -i 's/\braspberrypi\b/emonpi/g' /etc/hosts
grep -qw emonpi /etc/hosts || echo "127.0.1.1	emonpi" >> /etc/hosts

chown -R pi:pi /opt/openenergymonitor /opt/emoncms

# mkinitramfs cannot find the root device in a container with MODULES=dep
# (Raspberry Pi OS's setting). Build with MODULES=most; the override is
# removed at the end so kernel updates on the device use the normal setting.
echo "MODULES=most" > /etc/initramfs-tools/conf.d/emonsd-build

echo "=== Packages init.sh installs on a Pi"
apt-get update || fail "apt-get update failed"
apt-get install -y git mariadb-server || fail "could not install git and mariadb-server"

echo "=== Starting MariaDB for the build"
mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld
# Own network namespace: emoncms connects to 127.0.0.1:3306, which is this
# MariaDB and not the host's
mariadbd-safe --skip-syslog >/dev/null 2>&1 &
for i in $(seq 60); do
    mariadb-admin ping >/dev/null 2>&1 && break
    sleep 2
done
if ! mariadb-admin ping; then
    tail -n 20 /var/lib/mysql/*.err 2>/dev/null
    fail "MariaDB did not start"
fi

echo "=== install/main.sh"
runuser -l pi -c 'export SYSTEMD_OFFLINE=1; cd /opt/openenergymonitor/EmonScripts/install && ./main.sh --yes'
main_result=$?
cp /home/pi/main.sh.log /root/emonsd-main.sh.log 2>/dev/null
# main.sh does not stop or report when a component script fails: this only
# catches main.sh not running to the end. The checks below find the rest.
[ "$main_result" = "0" ] || fail "install/main.sh failed ($main_result)"

echo "=== Finishing packages and initramfs"
dpkg --configure -a
update-initramfs -u -k all || fail "update-initramfs failed"
rm -f /etc/initramfs-tools/conf.d/emonsd-build
[ -z "$(dpkg --audit)" ] || { dpkg --audit; fail "packages left half installed"; }

echo "=== Checking the build"
problems=0
problem() { echo "  PROBLEM: $*"; problems=$((problems+1)); }

for kernel in $(ls /lib/modules); do
    [ -s "/boot/initrd.img-$kernel" ] || problem "no initramfs for kernel $kernel"
    case "$kernel" in
        *-2712) fw=/boot/firmware/initramfs_2712 ;;
        *-v8)   fw=/boot/firmware/initramfs8 ;;
        *)      fw="" ;;
    esac
    if [ -n "$fw" ] && ! cmp -s "/boot/initrd.img-$kernel" "$fw"; then
        problem "$fw does not match /boot/initrd.img-$kernel"
    fi
done

for unit in apache2 mariadb redis-server mosquitto feedwriter service-runner emoncms_mqtt log2ram; do
    state=$(systemctl is-enabled "$unit.service" 2>/dev/null)
    [ "$state" = "enabled" ] || problem "$unit.service is ${state:-missing}, expected enabled"
done
# emonhub.service is a symlink to its unit file, so is-enabled reports "alias"
# whether it is enabled or not: check for the link that enabling creates
[ -e /etc/systemd/system/multi-user.target.wants/emonhub.service ] || problem "emonhub.service is not enabled"
[ -x /usr/local/bin/log2ram ] || problem "/usr/local/bin/log2ram is missing"
for unit in docker.service docker.socket containerd.service; do
    state=$(systemctl is-enabled "$unit" 2>/dev/null)
    [ "$state" = "disabled" ] || problem "$unit is ${state:-missing}, expected disabled"
done

tables=$(mariadb -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='emoncms'" 2>/dev/null)
[ "${tables:-0}" -gt 0 ] || problem "emoncms database has no tables"
echo "  emoncms tables: ${tables:-0}"

if grep -q '^ENABLED=yes' /etc/ufw/ufw.conf; then
    rules=$(grep -c '^-A ufw-user-input' /etc/ufw/user.rules 2>/dev/null)
    [ "${rules:-0}" -gt 0 ] || problem "ufw is enabled with no allow rules"
elif [ "$(systemctl is-enabled emonsd-firewall.service 2>/dev/null)" != "enabled" ]; then
    problem "firewall is neither configured nor set up for first boot"
else
    echo "  firewall: applied on first boot by emonsd-firewall.service"
fi

php -m | grep -qx redis || problem "php redis extension missing"
php -m | grep -qx mosquitto || problem "php mosquitto extension missing"
[ -n "$(ls /boot | grep '^emonSD-')" ] || problem "no /boot/emonSD-* version file"

echo "=== Stopping MariaDB"
mariadb-admin shutdown
sleep 3

[ "$problems" = "0" ] || fail "$problems problems in the build, see above"
echo "  all checks passed"

echo "=== install/prepare_image.sh"
runuser -l pi -c 'export SYSTEMD_OFFLINE=1; cd /opt/openenergymonitor/EmonScripts/install && ./prepare_image.sh --yes --skip-verify --no-shutdown' \
    || fail "prepare_image.sh failed"
state=$(systemctl is-enabled emonsd-ssh-keygen.service 2>/dev/null)
[ "$state" = "enabled" ] || fail "emonsd-ssh-keygen.service is ${state:-missing}, expected enabled"

rm -f /etc/sudoers.d/zz-emonsd-build
exit 0
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
# AppArmor attaches the host's profiles by path, so on a host that has e.g.
# MariaDB installed, the image's /usr/sbin/mariadbd is confined by the host's
# mariadbd profile and cannot start. The build runs under its own profile
# instead: it allows everything, and "file" makes every program the build
# starts inherit it (ix), so no host profile attaches inside the container.
# The profile has no path attachment, so it affects nothing else on the host,
# and it is unloaded when the build ends.
# --------------------------------------------------------------------------------
run_prefix=()
if [ "$(cat /sys/module/apparmor/parameters/enabled 2>/dev/null)" = "Y" ] && \
        command -v apparmor_parser >/dev/null 2>&1 && command -v aa-exec >/dev/null 2>&1; then
    cat > "$APPARMOR_PROFILE" <<'APPARMOR'
abi <abi/4.0>,
profile emonsd-build flags=(attach_disconnected,mediate_deleted) {
  file,
  capability,
  network,
  mount,
  remount,
  umount,
  pivot_root,
  ptrace,
  signal,
  unix,
  dbus,
  mqueue,
  io_uring,
  userns,
}
APPARMOR
    apparmor_parser -r "$APPARMOR_PROFILE"
    APPARMOR_LOADED=1
    run_prefix=(aa-exec -p emonsd-build --)
    echo "AppArmor: build runs under the emonsd-build profile"
fi

# --------------------------------------------------------------------------------
# setuid programs (sudo) only work under emulation if qemu is registered with
# the C (credentials) flag: without it the kernel takes the privileges from
# qemu itself, which is not setuid, and sudo fails with "effective uid is not
# 0". Add C for the duration of the build; the original registration is
# restored on exit.
# --------------------------------------------------------------------------------
if [ -n "${binfmt:-}" ] && ! grep -q '^flags:.*C' "$binfmt"; then
    original=$(binfmt_line "$binfmt")
    echo -1 > "$binfmt"
    BINFMT_ORIG=$original
    printf '%sC' "$original" > /proc/sys/fs/binfmt_misc/register
    grep -q '^flags:.*C' "$binfmt" || die "could not add the C flag to $binfmt"
    echo "arm64 emulation: added C flag for the build ($(sed -n 's/^flags: *//p' "$binfmt"))"
fi

# --------------------------------------------------------------------------------
step "Building inside the image (this is the long part)"
# --------------------------------------------------------------------------------
set +e
# Private network: the container gets its own network namespace, with its
# own loopback, and internet access through pasta (user mode networking, no
# changes to the host's network or firewall). Without this the container
# shares the host's network, and emoncms' connections to 127.0.0.1:3306
# reach the host's MariaDB instead of the image's. No port forwarding in
# either direction, and no route from the container to the host's loopback.
NETNS="emonsd-build-$$"
ip netns add "$NETNS"
ip -n "$NETNS" link set lo up
# Ubuntu's AppArmor profile for pasta (usr.bin.pasta) does not allow it to
# open /run/netns/*, but does allow /tmp/**: give it the same namespace bind
# mounted under /tmp. Run it in the foreground as a background job, so its
# PID is known without a PID file (the profile only allows writes in a few
# places). Wait for it to configure the namespace.
# --runas 0: by default pasta started as root switches to nobody before
# joining the namespace, and nobody cannot join one created by root
# ("Couldn't switch to pasta namespaces: Operation not permitted"). It stays
# confined by its AppArmor profile and its own sandbox, and only runs for the
# build.
NETNS_TMP="/tmp/emonsd-build-netns-$$"
touch "$NETNS_TMP"
mount --bind "/run/netns/$NETNS" "$NETNS_TMP"
# --no-netns-quit: pasta would otherwise watch the namespace's directory
# (/tmp) to exit when it is removed, and the profile does not allow reading
# /tmp itself. The build stops pasta itself.
pasta -f --runas 0 --no-netns-quit --config-net --netns "$NETNS_TMP" \
    -t none -u none -T none -U none \
    --map-host-loopback none --map-guest-addr none \
    -q &
PASTA_PID=$!
for i in $(seq 40); do
    kill -0 "$PASTA_PID" 2>/dev/null || die "pasta could not set up networking for the build"
    ip -n "$NETNS" -4 -brief address | grep -v '^lo ' | grep -q '[0-9]\.[0-9]' && break
    sleep 0.5
done
ip -n "$NETNS" -4 -brief address | grep -v '^lo ' | grep -q '[0-9]\.[0-9]' \
    || die "pasta did not configure the build network"
ip -n "$NETNS" -4 -brief address | grep -v '^lo '
echo "Build network: namespace $NETNS, pasta pid $PASTA_PID"

# The container cannot change the host: no network admin (firewall, WiFi), no
# kernel modules, no clock changes. It sees only the image's files and no
# host disks.
"${run_prefix[@]}" systemd-nspawn -q -D "$ROOT" --as-pid2 --machine=emonsd-build --register=no \
    --hostname=emonpi --network-namespace-path="/run/netns/$NETNS" \
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
