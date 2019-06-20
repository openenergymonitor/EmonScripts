#!/bin/bash
source config.ini

# --------------------------------------------------------------------------------
# Enable serial uploads with avrdude and autoreset
# --------------------------------------------------------------------------------
cd $openenergymonitor_dir
if [ ! -d $openenergymonitor_dir/avrdude-rpi ]; then
    git clone https://github.com/openenergymonitor/avrdude-rpi.git
    $openenergymonitor_dir/avrdude-rpi/install
else 
    echo "- avrdude-rpi already exists"
fi

cd $openenergymonitor_dir
if [ ! -d $openenergymonitor_dir/RFM2Pi ]; then
    git clone https://github.com/openenergymonitor/RFM2Pi
else
    echo "- RFM2Pi already exists"
fi
