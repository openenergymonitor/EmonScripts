#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Update EmonPi Firmware"
echo "-------------------------------------------------------------"

if ! [ -x "avrdude" ] || ! [ -f $openenergymonitor_dir/emonpi/firmware/compiled/latest.hex ]; then
    echo "Not found or incomplete installation at $openenergymonitor_dir/emonpi"
    exit 1
fi
sudo service emonhub stop

echo "Start ATmega328 serial upload using avrdude with latest.hex"

echo "Discrete Sampling"

echo "avrdude -c arduino -p ATMEGA328P -P /dev/ttyAMA0 -b 115200 -U flash:w:$openenergymonitor_dir/emonpi/firmware/compiled/latest.hex"

avrdude -c arduino -p ATMEGA328P -P /dev/ttyAMA0 -b 115200 -U flash:w:$openenergymonitor_dir/emonpi/firmware/compiled/latest.hex

sudo service emonhub start
