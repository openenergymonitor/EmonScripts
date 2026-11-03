#!/bin/bash
source load_config.sh

if [ ! -f /etc/logrotate.d/logrotate ]; then
    echo "-------------------------------------------------------------"
    echo "EmonPi Update logrotate"
    echo "-------------------------------------------------------------"
    sudo ln -sf $openenergymonitor_dir/EmonScripts/defaults/etc/logrotate.d/logrotate /etc/logrotate.d/logrotate
    sudo chown root /etc/logrotate.d/logrotate
fi

echo "-------------------------------------------------------------"
echo "EmonPi LCD Update"
echo "-------------------------------------------------------------"

if [ -d $openenergymonitor_dir/emonPiLCD ]; then
    $openenergymonitor_dir/emonPiLCD/install.sh
elif [ -f $openenergymonitor_dir/emonpi/lcd/install.sh ]; then
    $openenergymonitor_dir/emonpi/lcd/install.sh
fi

echo "Stopping emonPiLCD service"
sudo systemctl stop emonPiLCD
