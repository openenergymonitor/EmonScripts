#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
source load_config.sh

serial_port=$1
hardware=$2
firmware_version=$3

echo "-------------------------------------------------------------"
echo "$2 Firmware Upload"
echo "-------------------------------------------------------------"

if [ ! -d $openenergymonitor_dir/data/firmware ]; then
  mkdir $openenergymonitor_dir/data/firmware
fi

result=$(./get_firmware_download_url.py $hardware $firmware_version)
result=($result)

download_url=${result[0]}
baud_rate=${result[1]}
firmware_version=${result[2]}

hexfile=$openenergymonitor_dir/data/firmware/$hardware-$firmware_version.hex

echo "Downloading firmware from: "
echo $download_url
wget -q $download_url -O $hexfile

echo
echo "Downloaded file: "
ls -lh $hexfile

if [ -f $hexfile ]; then

  state=$(systemctl show emonhub | grep ActiveState)
  
  if [ $state == "ActiveState=active" ]; then
    echo
    echo "EmonHub is running, stopping EmonHub"
    sudo systemctl stop emonhub
    emonhub_stopped_by_script=1
  else
    emonhub_stopped_by_script=0
  fi
  
  echo
  echo "Uploading $hardware $firmware_version on serial port $serial_port"
  echo
  avrdude -v -c arduino -p ATMEGA328P -P /dev/$serial_port -b $baud_rate -U flash:w:$hexfile

  echo
  echo "Upload complete"
  
  if [ $emonhub_stopped_by_script == 1 ]; then
    echo
    echo "Restarting EmonHub"
    sudo systemctl start emonhub
  fi

else
  echo "Firmware download failed...check network connection"
fi
