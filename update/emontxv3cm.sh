#!/bin/bash
source load_config.sh

serial_port=$1

echo "-------------------------------------------------------------"
echo "EmonTxV3CM Firmware Upload"
echo "-------------------------------------------------------------"

echo "Getting latest EmonTxV3CM release info from github"
download_url="$(curl -s https://api.github.com/repos/openenergymonitor/EmonTxV3CM/releases | grep browser_download_url | head -n 1 | cut -d '"' -f 4)"
version="$(curl -s https://api.github.com/repos/openenergymonitor/EmonTxV3CM/releases | grep tag_name | head -n 1 |  cut -d '"' -f 4)"
echo "Latest EmonTxV3CM firmware: V"$version

echo "downloading latest EmonTxV3CM firmware from github releases:"
echo $download_url

echo "Saving to $openenergymonitor_dir/data/firmware/emontxv3cm-"$version".hex"

if [ ! -d $openenergymonitor_dir/data/firmware ]; then
  mkdir $openenergymonitor_dir/data/firmware
fi

wget -q $download_url -O $openenergymonitor_dir/data/firmware/emontxv3cm-$version.hex

if [ -f $openenergymonitor_dir/data/firmware/emontxv3cm-$version.hex ]; then
  sudo service emonhub stop
  echo
  echo "Flashing EmonTxV3CM on serial port $serial_port with V" $version
  echo
  avrdude -v -c arduino -p ATMEGA328P -P /dev/$serial_port -b 115200 -U flash:w:$openenergymonitor_dir/data/firmware/emontxv3cm-$version.hex
  sudo service emonhub start
  echo "Flashing EmonTxV3CM with V" $version " done"
else
 echo "Firmware download failed...check network connection"
fi
