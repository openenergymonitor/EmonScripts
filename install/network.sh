#!/bin/bash
source load_config.sh

# Install emonpi repo if it doesnt already exist
if [ ! -d $openenergymonitor_dir/emonpi ]; then
    echo "Installing emonpi repository"
    cd $openenergymonitor_dir
    git clone ${git_repo[emonpi]}
fi

# Wifi setup
sudo ln -s $openenergymonitor_dir/emonpi/wifi-check /usr/local/bin/wifi-check

sudo crontab -l > mycron
if grep -Fq "wifi-check" mycron; then
    echo "wifi-check already present in crontab"
else
    echo "* * * * * /usr/local/bin/wifi-check >> /var/log/emoncms/wificheck.log 2>&1" >> mycron
    sudo crontab mycron
    rm mycron
fi
