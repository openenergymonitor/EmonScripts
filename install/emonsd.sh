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
# Review: reboot required before running:
echo "-- Installing firewall"
sudo apt-get install -y ufw
# sudo ufw allow 80/tcp
# sudo ufw allow 443/tcp (optional, HTTPS not present)
# sudo ufw allow 22/tcp
# sudo ufw allow 1883/tcp #(optional, Mosquitto)
# sudo ufw enable

boot_config=/boot/config.txt
if [ -f /boot/firmware/config.txt ]; then
    boot_config=/boot/firmware/config.txt
fi
echo "-- boot config directory: $boot_config"

# Underclock and memory tweak
# change arm_freq to 1200 and gpu_mem to 16
# more ram for general purpose, less for GPU
# Removed see: https://github.com/openenergymonitor/EmonScripts/issues/83
# sudo sed -i "s/^#arm_freq=800/arm_freq=1200\ngpu_mem=16/" /boot/config.txt


# One wire temperature sensing support for emonPi v2 
# IMPORTANT: This will likely interfere with shutdown button on emonPi v1
# It's best to disable onewire if using this image with an emonPi v1

if [ "$enable_onewire" == true ]; then
    echo "-- Enabling one-wire, w1-gpio,gpiopin=17"
    sudo sed -i -n '/dtoverlay=w1-gpio/!p;$a dtoverlay=w1-gpio,gpiopin=17' $boot_config
    
    sudo modprobe w1-gpio
    sudo modprobe w1-therm
else
    # Disable 1-Wire to prevent errors in logs
    echo "-- Disabling 1-Wire - will take effect on next reboot"
    sudo sed -i 's/dtoverlay=w1-gpio/#dtoverlay=w1-gpio/' $boot_config
fi
# 6 Sep 2019 decision to leave elevator setting as default
# option to review in future: elevator=noop

# Setup user group to enable reading GPU temperature (pi only)
sudo usermod -a -G video www-data

# Review automated install: Emoncms Language Support
# sudo dpkg-reconfigure locales

# emonSD rc.local includes wifiAP start and first boot update
echo "-- Installing /etc/rc.local"
sudo ln -sf $openenergymonitor_dir/EmonScripts/defaults/etc/rc.local /etc/rc.local

# emonSDexpand
echo "-- Installing /usr/bin/emonSDexpand"
sudo ln -sf $emoncms_dir/modules/usefulscripts/sdpart/sdpart_imagefile /usr/bin/emonSDexpand

# --------------------------------------------------------------------------------
# Misc
# --------------------------------------------------------------------------------
echo "-- Installing /home/pi/readme.md"
sudo ln -sf $openenergymonitor_dir/EmonScripts/defaults/readme.md /home/pi/
