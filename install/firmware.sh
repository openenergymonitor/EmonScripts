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

# bossac uploads emonPi3 (ATSAMD21) firmware. update/emonpi3_firmware_upload.sh
# and update/atmega_firmware_upload.sh build it here on first use if missing,
# which fails without network access, so build it into the image.
cd $openenergymonitor_dir
if [ ! -f $openenergymonitor_dir/BOSSA/bin/bossac ]; then
    echo "-- installing BOSSA (bossac)"
    if [ ! -d $openenergymonitor_dir/BOSSA ]; then
        git clone ${git_repo[BOSSA]:-https://github.com/shumatech/BOSSA}
    fi
    if make -C $openenergymonitor_dir/BOSSA bossac; then
        echo "-- $($openenergymonitor_dir/BOSSA/bin/bossac --version 2>&1 | head -n1)"
    else
        echo "-- ERROR: BOSSA build failed, firmware upload will try again on first use"
    fi
else
    echo "-- BOSSA already exists"
fi
