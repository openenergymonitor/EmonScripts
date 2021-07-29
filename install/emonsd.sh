#!/bin/bash
source load_config.sh

# --------------------------------------------------------------------------------
# Install log2ram, so that logging is on RAM to reduce SD card wear.
# Logs are written to disk every hour or at shutdown
# log2ram forked from @pb66 repo here https://github.com/pb66/log2ram
# --------------------------------------------------------------------------------
cd $openenergymonitor_dir
git clone -b $log2ram_branch ${git_repo[log2ram]}
cd log2ram
chmod +x install.sh && sudo ./install.sh
cd ..
rm -rf log2ram

# --------------------------------------------------------------------------------
# Install custom logrotate
# --------------------------------------------------------------------------------
# logrotate log
if [ ! -d /var/log/logrotate ]; then
  sudo mkdir /var/log/logrotate
  sudo chown -R root:adm /var/log/logrotate
fi
# custom logrotate config
sudo ln -sf $emonscripts_dir/defaults/etc/logrotate.d/00_defaults /etc/logrotate.d/00_defaults
sudo ln -sf $emonscripts_dir/defaults/etc/logrotate.d/emonhub /etc/logrotate.d/emonhub
sudo ln -sf $emonscripts_dir/defaults/etc/logrotate.d/emonmuc /etc/logrotate.d/emonmuc
sudo ln -sf $emonscripts_dir/defaults/etc/logrotate.d/emoncms /etc/logrotate.d/emoncms

sudo chown root /etc/logrotate.d/00_defaults
sudo chown root /etc/logrotate.d/emonhub
sudo chown root /etc/logrotate.d/emonmuc
sudo chown root /etc/logrotate.d/emoncms

# log2ram cron hourly entry
sudo ln -sf $emonscripts_dir/defaults/etc/cron.hourly/log2ram /etc/cron.hourly/log2ram
sudo chmod +x /etc/cron.hourly/log2ram
# copy in commented out placeholder logrotate file
sudo cp $emonscripts_dir/defaults/etc/cron.daily/logrotate /etc/cron.daily/logrotate

# --------------------------------------------------------------------------------
# UFW firewall
# --------------------------------------------------------------------------------
# Review: reboot required before running:
sudo apt-get install -y ufw
# sudo ufw allow 80/tcp
# sudo ufw allow 443/tcp (optional, HTTPS not present)
# sudo ufw allow 22/tcp
# sudo ufw allow 1883/tcp #(optional, Mosquitto)
# sudo ufw enable

# Underclock and memory tweak
# change arm_freq to 1200 and gpu_mem to 16
# more ram for general purpose, less for GPU
# Removed see: https://github.com/openenergymonitor/EmonScripts/issues/83
# sudo sed -i "s/^#arm_freq=800/arm_freq=1200\ngpu_mem=16/" /boot/config.txt

# 6 Sep 2019 decision to leave elevator setting as default
# option to review in future: elevator=noop

# Setup user group to enable reading GPU temperature (pi only)
sudo usermod -a -G video www-data

# Review automated install: Emoncms Language Support
# sudo dpkg-reconfigure locales

# Wifi setup
sudo ln -s $openenergymonitor_dir/emonpi/wifi-check /usr/local/bin/wifi-check

sudo crontab -l > mycron
if grep -Fq "wifi-check" mycron; then
    echo "wifi-check already present in crontab"
else
    echo "*/5 * * * * /usr/local/bin/wifi-check > /var/log/emoncms/wificheck.log 2>&1" >> mycron
    sudo crontab mycron
    rm mycron
fi

# emonSD rc.local includes wifiAP start and first boot update
sudo ln -sf $emonscripts_dir/defaults/etc/rc.local /etc/rc.local

# emonSDexpand
sudo ln -sf $emoncms_dir/modules/usefulscripts/sdpart/sdpart_imagefile /usr/bin/emonSDexpand

# --------------------------------------------------------------------------------
# Misc
# --------------------------------------------------------------------------------

sudo ln -sf $emonscripts_dir/defaults/readme.md /home/pi/

# Review: provide configuration file for default password and hostname

# Set hostname
sudo sed -i "s/raspberrypi/$hostname/g" /etc/hosts
printf $hostname | sudo tee /etc/hostname > /dev/null

echo "Please enter a new SSH password to secure your system"
read ssh_password
# Set default SSH password:
printf "raspberry\n$ssh_password\n$ssh_password" | passwd
