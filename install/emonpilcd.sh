#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "emonPiLCD install"
echo "-------------------------------------------------------------"
cd $openenergymonitor_dir

if [ ! -d $openenergymonitor_dir/emonPiLCD ]; then
    git clone -b $emonhub_branch ${git_repo[emonPiLCD]}
else 
    echo "- emonPiLCD repository already installed"
    echo "- emonPiLCD running git pull:"
    git -C $openenergymonitor_dir/emonPiLCD pull
fi

if [ -f $openenergymonitor_dir/emonPiLCD/install.sh ]; then
    $openenergymonitor_dir/emonPiLCD/install.sh
else
    echo "ERROR: $openenergymonitor_dir/emonPiLCD/install.sh script does not exist"
fi
