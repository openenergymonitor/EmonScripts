#!/bin/bash
# --------------------------------------------------------------------------------
# Prepare a freshly built emonSD card for imaging
#
# DESTRUCTIVE: run only on the build Pi, as the very last step before imaging.
# It removes this card's SSH host keys, machine-id, saved WiFi networks, logs
# and shell history so that every device made from the image starts clean and
# unique, then shuts down.
#
#     cd /opt/openenergymonitor/EmonScripts/install
#     ./prepare_image.sh
#
# Do not boot the card again after this has run. Booting regenerates the SSH
# host keys and machine-id, and every device made from the image would share
# them. If it is booted by mistake, run this script again.
#
# Options:
#   --yes          do not ask for confirmation
#   --force        continue even if verify.sh reports failures
#   --skip-verify  do not run verify.sh (image/build.sh, services are not running)
#   --no-shutdown  leave the system running at the end
# --------------------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"
source load_config.sh

assume_yes=0
force=0
skip_verify=0
shutdown_at_end=1
for arg in "$@"; do
    case "$arg" in
        --yes) assume_yes=1 ;;
        --force) force=1 ;;
        --skip-verify) skip_verify=1 ;;
        --no-shutdown) shutdown_at_end=0 ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

# --------------------------------------------------------------------------------
# Only ever run on a built emonSD card
# --------------------------------------------------------------------------------
if [ "$emonSD_pi_env" != "1" ]; then
    echo "emonSD_pi_env is not 1 in config.ini, this script is only for emonSD builds"
    exit 1
fi

image_version=$(ls /boot 2>/dev/null | grep '^emonSD-' | head -n1)
if [ -z "$image_version" ]; then
    echo "No /boot/emonSD-* version file found. This does not look like a built emonSD card,"
    echo "or install/main.sh has not been run. Nothing changed."
    exit 1
fi

if [ "$EUID" = "0" ]; then
    echo "Run as the build user ($user), not as root. Nothing changed."
    exit 1
fi

# --------------------------------------------------------------------------------
# Verify the build first
# --------------------------------------------------------------------------------
if [ "$skip_verify" = "1" ]; then
    echo "Skipping verify.sh"
elif ! ./verify.sh; then
    if [ "$force" = "1" ]; then
        echo
        echo "verify.sh reported failures, continuing because of --force"
    else
        echo
        echo "verify.sh reported failures. Fix them, or re-run with --force. Nothing changed."
        exit 1
    fi
fi

wifi_country=${wifi_country:-GB}

echo
echo "-------------------------------------------------------------"
echo "Prepare $image_version for imaging"
echo "-------------------------------------------------------------"
echo "This will:"
echo "  - set the WiFi country to $wifi_country"
echo "  - save /etc/emonhub/emonhub.conf as the factory default for other/factoryreset"
echo "  - disable SSH and remove this card's SSH host keys and authorized_keys"
echo "  - remove saved WiFi client networks (this disconnects WiFi)"
echo "  - clear logs, build logs (~/init.sh.log, ~/main.sh.log), shell history and caches"
echo "  - reset the machine-id"
if [ "$shutdown_at_end" = "1" ]; then
    echo "  - shut down"
fi
echo
echo "Copy off ~/main.sh.log first if you want to keep it."
echo

if [ "$assume_yes" != "1" ]; then
    read -p "Type 'yes' to continue: " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Nothing changed."
        exit 1
    fi
fi

# --------------------------------------------------------------------------------
echo "-- WiFi country: $wifi_country"
if command -v raspi-config >/dev/null 2>&1; then
    sudo raspi-config nonint do_wifi_country "$wifi_country"
else
    echo "   raspi-config not found, WiFi country not set"
fi

# --------------------------------------------------------------------------------
# other/factoryreset restores the emonhub.conf the image shipped with
if [ -f /etc/emonhub/emonhub.conf ]; then
    echo "-- Saving factory emonhub.conf"
    sudo cp /etc/emonhub/emonhub.conf /etc/emonhub/emonhub.conf.factory
fi

# --------------------------------------------------------------------------------
# SSH: disabled by default, enabled by the user with /boot/firmware/ssh or the
# emonPi LCD button. Each device must get its own host keys.
# --------------------------------------------------------------------------------
echo "-- Installing emonsd-ssh-keygen.service"
sudo cp "$openenergymonitor_dir/EmonScripts/defaults/etc/systemd/system/emonsd-ssh-keygen.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable emonsd-ssh-keygen.service

echo "-- Disabling SSH (the current session stays open until shutdown)"
sudo systemctl disable ssh.service 2>/dev/null
sudo systemctl disable ssh.socket 2>/dev/null
sudo rm -f /boot/ssh /boot/firmware/ssh /boot/ssh.txt /boot/firmware/ssh.txt

echo "-- Removing SSH host keys"
sudo rm -f /etc/ssh/ssh_host_*

echo "-- Removing authorized_keys"
rm -f ~/.ssh/authorized_keys
sudo rm -f /root/.ssh/authorized_keys

# --------------------------------------------------------------------------------
# WiFi: remove client networks used during the build. The network module
# counts these to decide whether to start the access point, and they contain
# the build network's password. Access point profiles are kept.
# --------------------------------------------------------------------------------
echo "-- Removing saved WiFi client networks"
for file in /etc/NetworkManager/system-connections/*; do
    sudo test -f "$file" || continue
    if sudo grep -q '^type=wifi' "$file" && ! sudo grep -q '^mode=ap' "$file"; then
        echo "   $file"
        sudo rm -f "$file"
    fi
done
if [ -f /etc/wpa_supplicant/wpa_supplicant.conf ] && grep -q 'network=' /etc/wpa_supplicant/wpa_supplicant.conf 2>/dev/null; then
    echo "   NOTE: /etc/wpa_supplicant/wpa_supplicant.conf contains networks, not modified"
fi

# --------------------------------------------------------------------------------
echo "-- Clearing shell history and caches"
rm -f ~/.bash_history ~/.lesshst ~/.wget-hsts ~/.python_history ~/.mysql_history
rm -rf ~/.cache
sudo rm -f /root/.bash_history /root/.lesshst /root/.wget-hsts /root/.python_history /root/.mysql_history
sudo rm -rf /root/.cache

echo "-- Cleaning apt cache"
sudo apt-get clean

echo "-- Removing build logs"
rm -f ~/init.sh.log ~/main.sh.log

# --------------------------------------------------------------------------------
# Logs: rotated logs are removed, current logs are emptied in place so their
# ownership and permissions (e.g emoncms.log is 666) are kept.
# /var/log is held in RAM by log2ram and written back to disk at shutdown.
# --------------------------------------------------------------------------------
echo "-- Clearing logs"
sudo journalctl --rotate >/dev/null 2>&1
sudo journalctl --vacuum-time=1s >/dev/null 2>&1
for logdir in /var/log /var/log.old; do
    [ -d "$logdir" ] || continue
    sudo find "$logdir" -type f \( -name '*.gz' -o -name '*.[0-9]' -o -name '*.[0-9].log' -o -name '*.old' \) -delete
    sudo find "$logdir" -type f ! -path '*/journal/*' -exec truncate -s 0 {} +
done

# --------------------------------------------------------------------------------
# machine-id last. It must be emptied, not deleted: an empty file gets a new ID
# on the next boot, a missing one is treated by systemd as a first boot and it
# re-applies unit presets, which on Debian re-enables ssh and docker.
# --------------------------------------------------------------------------------
echo "-- Resetting machine-id"
sudo truncate -s 0 /etc/machine-id
if [ -f /var/lib/dbus/machine-id ] && [ ! -L /var/lib/dbus/machine-id ]; then
    sudo rm -f /var/lib/dbus/machine-id
fi

sync

echo
echo "-------------------------------------------------------------"
echo "$image_version is ready to image."
echo "Do not boot this card again before imaging it."
echo "-------------------------------------------------------------"

if [ "$shutdown_at_end" = "1" ]; then
    echo "Shutting down..."
    sudo shutdown -h now
fi
