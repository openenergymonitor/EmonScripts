#!/bin/bash
source load_config.sh

# --------------------------------------------------------------------------------
# Enable serial uploads with avrdude and autoreset
# --------------------------------------------------------------------------------
cd $openenergymonitor_dir
if [ ! -d $openenergymonitor_dir/avrdude-rpi ]; then
    echo "-- installing avrdude-rpi"
    git clone ${git_repo[avrdude-rpi]}
    $openenergymonitor_dir/avrdude-rpi/install
else 
    echo "-- avrdude-rpi already exists"
fi

cd $openenergymonitor_dir
if [ ! -d $openenergymonitor_dir/RFM2Pi ]; then
    echo "-- installing RFM2Pi"
    git clone ${git_repo[RFM2Pi]}
else
    echo "-- RFM2Pi already exists"
fi
