#!/bin/bash
source load_config.sh

# --------------------------------------------------------------------------------
# Install log2ram, so that logging is on RAM to reduce SD card wear.
# Logs are written to disk every hour or at shutdown
# log2ram forked from @pb66 repo here https://github.com/pb66/log2ram
# --------------------------------------------------------------------------------
cd $openenergymonitor_dir

echo "-- Installing log2ram"
git clone -b $log2ram_branch ${git_repo[log2ram]}
cd log2ram
chmod +x install.sh && sudo ./install.sh
cd ..
rm -rf log2ram

# --------------------------------------------------------------------------------
# Install custom logrotate
# --------------------------------------------------------------------------------
echo "-- Installing custom logrotate"
# logrotate log
if [ ! -d /var/log/logrotate ]; then
  sudo mkdir /var/log/logrotate
  sudo chown -R root:adm /var/log/logrotate
fi
# custom logrotate config
sudo ln -sf $openenergymonitor_dir/EmonScripts/defaults/etc/logrotate.d/00_defaults /etc/logrotate.d/00_defaults
sudo ln -sf $openenergymonitor_dir/EmonScripts/defaults/etc/logrotate.d/emonhub /etc/logrotate.d/emonhub
sudo ln -sf $openenergymonitor_dir/EmonScripts/defaults/etc/logrotate.d/emoncms /etc/logrotate.d/emoncms
sudo ln -sf $openenergymonitor_dir/EmonScripts/defaults/etc/logrotate.d/logrotate /etc/logrotate.d/logrotate

sudo chown root /etc/logrotate.d/00_defaults
sudo chown root /etc/logrotate.d/emonhub
sudo chown root /etc/logrotate.d/emoncms
sudo chown root /etc/logrotate.d/logrotate

# log2ram cron hourly entry
echo "-- Setting up log2ram cron.hourly entry"
sudo ln -sf $openenergymonitor_dir/EmonScripts/defaults/etc/cron.hourly/log2ram /etc/cron.hourly/log2ram
sudo chmod +x /etc/cron.hourly/log2ram
# copy in commented out placeholder logrotate file
echo "-- Setting up log2ram cron.daily entry"
sudo cp $openenergymonitor_dir/EmonScripts/defaults/etc/cron.daily/logrotate /etc/cron.daily/logrotate

if [ ! -d /var/log.old ]; then
    echo "-- Creating /var/log.old directory"
    sudo mkdir /var/log.old
fi

# --------------------------------------------------------------------------------
# UFW firewall
# --------------------------------------------------------------------------------
# Rules are in install/firewall.sh. Applying them needs a working iptables:
# if the kernel was upgraded during this build and the Pi has not been
# rebooted yet, or the image is built in a container (image/build.sh), it
# fails. Then ufw is left off and emonsd-firewall.service applies the rules
# on the next boot. ufw is never enabled without its allow rules, which
# would block the web interface and SSH.
echo "-- Installing firewall"
sudo apt-get install -y ufw

if sudo $openenergymonitor_dir/EmonScripts/install/firewall.sh; then
    echo "-- firewall enabled"
else
    echo "-- firewall could not be applied now, it will be applied on the next boot"
    sudo sed -i 's/^ENABLED=.*/ENABLED=no/' /etc/ufw/ufw.conf
    sudo cp $openenergymonitor_dir/EmonScripts/defaults/etc/systemd/system/emonsd-firewall.service /etc/systemd/system/
    sudo systemctl enable emonsd-firewall.service
fi

boot_config=/boot/config.txt
if [ -f /boot/firmware/config.txt ]; then
    boot_config=/boot/firmware/config.txt
fi
echo "-- boot config directory: $boot_config"

# Hardware specific GPIO and one wire lines, see emonsd_hardware in config.ini.
# Lines are appended to the end of config.txt, which must be an [all] section.
#   emonpi2: one wire on GPIO17. Also used for emonBase and emonPi v1, where
#            one wire will likely interfere with the shutdown button, so it is
#            best disabled (enable_onewire=false).
#   emonpi3: GPIO17 held low as an output. It drives the emonPi3 board's
#            DISABLE_EXT_INTFn input (emon32-fw src/board_def.h): low tells the
#            emonPi3 microcontroller a Pi is attached, so it releases the
#            RFM69 SPI bus and the two one wire / pulse inputs to the Pi, and
#            stops reading and reporting them itself. Left high or floating
#            the emonPi3 runs standalone and drives them itself.
#            The Pi then reads one wire on GPIO27 and GPIO22, and the RFM69
#            through emonhub's [[SPI]] interfacer.
hardware=${emonsd_hardware:-emonpi2}
case "$hardware" in
    emonpi3) onewire_pins="27 22" ;;
    emonpi2) onewire_pins="17" ;;
    *) echo "-- ERROR: unknown emonsd_hardware=$hardware, expected emonpi3 or emonpi2"; exit 1 ;;
esac
echo "-- Configuring $boot_config for $hardware"

# Remove lines from a previous run, so this is safe to run again
sudo sed -i -e '/^#\?dtoverlay=w1-gpio/d' -e '/^gpio=17=op,dl/d' \
    -e '/^# emonSD: /d' $boot_config

last_section=$(grep -E '^\[[^]]+\]' $boot_config | tail -n1)
if [ -n "$last_section" ] && [ "$last_section" != "[all]" ]; then
    echo "[all]" | sudo tee -a $boot_config >/dev/null
fi

if [ "$hardware" = "emonpi3" ]; then
    echo "-- Holding GPIO17 low"
    printf '%s\n' "# emonSD: emonPi3 only, GPIO17 low = Pi attached, the Pi drives RFM69 and one wire" \
        "gpio=17=op,dl" | sudo tee -a $boot_config >/dev/null
fi

if [ "$enable_onewire" == true ]; then
    for pin in $onewire_pins; do
        echo "-- Enabling one-wire, w1-gpio,gpiopin=$pin"
        echo "dtoverlay=w1-gpio,gpiopin=$pin" | sudo tee -a $boot_config >/dev/null
    done
    sudo modprobe w1-gpio
    sudo modprobe w1-therm
else
    echo "-- One-wire disabled, enable_onewire=false"
fi

# Setup user group to enable reading GPU temperature (pi only)
sudo usermod -a -G video www-data

# emonSD rc.local runs the network module wifi-check at boot
echo "-- Installing /etc/rc.local"
sudo ln -sf $openenergymonitor_dir/EmonScripts/defaults/etc/rc.local /etc/rc.local

# --------------------------------------------------------------------------------
# Misc
# --------------------------------------------------------------------------------
echo "-- Installing /home/pi/readme.md"
sudo ln -sf $openenergymonitor_dir/EmonScripts/defaults/readme.md /home/pi/

# --------------------------------------------------------------------------------

# update checks for image type and only runs with a valid image name file in the boot partition
# Update this value to the latest safe image version - this could be automated to pull from safe list
emonsd_date=$(date +"%d%b%y")
echo "-- creating version file: emonSD-$emonsd_date"

sudo touch /boot/emonSD-$emonsd_date
if [ -d /boot/firmware ]; then
    sudo cp /boot/emonSD-$emonsd_date /boot/firmware
fi
