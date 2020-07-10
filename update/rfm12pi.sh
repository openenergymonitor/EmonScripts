#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "RFM12Pi Firmware Update"
echo "-------------------------------------------------------------"
download_url="https://raw.githubusercontent.com/openenergymonitor/RFM2Pi/master/firmware/RFM69CW_RF_Demo_ATmega328/RFM12_Demo_ATmega328.cpp.hex"

if [ ! -d $openenergymonitor_dir/data/firmware ]; then
  mkdir $openenergymonitor_dir/data/firmware
fi

wget -q $download_url -O $openenergymonitor_dir/data/firmware/rfm12pi.hex

if [ -f $openenergymonitor_dir/data/firmware/rfm12pi.hex ]; then
  sudo service emonhub stop
  echo
  echo "Flashing RFM12Pi"
  echo
  avrdude -v -c arduino -p ATMEGA328P -P /dev/ttyAMA0 -b 38400 -U flash:w:$openenergymonitor_dir/data/firmware/rfm12pi.hex
  sudo service emonhub start
  echo "Flashing RFM12Pi done"
else
 echo "Firmware download failed...check network connection"
fi
