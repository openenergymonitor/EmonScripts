#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
source load_config.sh

serial_port=$1
firmware_key=$2

if [ $serial_port == "none" ]; then
  echo "no serial port selected or available"
  exit
fi

if [ $firmware_key == "emonpi" ]; then
  firmware_key="emonPi_discrete_jeelib"
fi

echo "-------------------------------------------------------------"
echo "$firmware_key Firmware Upload"
echo "-------------------------------------------------------------"

if [ ! -d $openenergymonitor_dir/data/firmware ]; then
  mkdir $openenergymonitor_dir/data/firmware
fi

result=$(./get_firmware_download_url.py $firmware_key)
if [ "$result" != "firmware not found" ]; then
  result=($result)

  download_url=${result[0]}
  baud_rate=${result[1]}

  hexfile=$openenergymonitor_dir/data/firmware/$firmware_key.hex

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
    echo "Uploading $firmware_key on serial port $serial_port"
        
    for attempt in {1..3}
    do
      echo "Attempt $attempt..."
      echo
      avrdude -v -c arduino -p ATMEGA328P -P /dev/$serial_port -b $baud_rate -U flash:w:$hexfile

      # Find output logfile
      output_log_file=$( lsof -p $$ -a -d 1 -F n | awk '/^n/ {print substr($1, 2)}' )
      # double check that it exists
      if [ -f $output_log_file ]; then
        # check for completion status
        not_in_sync=$(cat $output_log_file | grep "not in sync" | wc -l)
        flash_verified=$(cat $output_log_file | grep "flash verified" | wc -l)
        
        # if [ "$not_in_sync" == "0" ]; then
        if [ $flash_verified == "1" ]; then
            echo "SUCCESS: flash verifed"
            break;
        else 
            echo "ERROR: Not in sync" 
        fi
      fi
    done
    
    if [ $emonhub_stopped_by_script == 1 ]; then
      echo
      echo "Restarting EmonHub"
      sudo systemctl start emonhub
    fi

  else
    echo "Firmware download failed...check network connection"
  fi
else
  echo "Firmware not found: $firmware_key"
fi
