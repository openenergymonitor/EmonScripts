#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "emonpiLCD install"
echo "-------------------------------------------------------------"
cd $openenergymonitor_dir

if [ ! -d $openenergymonitor_dir/emonpi ]; then
    git clone ${git_repo[emonpi]}
else
    echo "- emonpi repository already installed"
    git pull
fi

if [ -f $openenergymonitor_dir/emonpi/lcd/install.sh ]; then
    $openenergymonitor_dir/emonpi/lcd/install.sh
else
    echo "ERROR: $openenergymonitor_dir/emonpi/lcd/install.sh script does not exist"
fi
