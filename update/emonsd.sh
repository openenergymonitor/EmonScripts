#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "EmonPi LCD Update"
echo "-------------------------------------------------------------"
if [ -f $openenergymonitor_dir/emonpi/lcd/install.sh ]; then
    $openenergymonitor_dir/emonpi/lcd/./install.sh
fi
