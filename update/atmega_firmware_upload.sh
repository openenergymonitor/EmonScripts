#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
source load_config.sh

if [ ! -d $openenergymonitor_dir/data/firmware ]; then
  mkdir $openenergymonitor_dir/data/firmware
fi

serial_port=$1
firmware_key=$2

if [ $serial_port == "none" ]; then
  echo "no serial port selected or available"
  exit
fi

if [ $firmware_key == "emonpi" ]; then
  firmware_key="emonPi_discrete_jeelib"
fi

# if custom, get baud_rate, core, autoreset and custom_firmware_filename
if [ $firmware_key == "custom" ]; then
  custom_firmware_filename=$3
  baud_rate=$4
  core=$5
  autoreset=$6

  hexfile=$openenergymonitor_dir/data/firmware/upload/$custom_firmware_filename
  # check if custom firmware file exists
  if [ ! -f $hexfile ]; then
    echo "Custom firmware file not found: $hexfile"
    exit 1
  fi

  echo "-------------------------------------------------------------"
  echo "Custom firmware selected: $custom_firmware_filename"
  echo "baud_rate: $baud_rate"
  echo "core: $core"
  echo "autoreset: $autoreset"
  echo "-------------------------------------------------------------"
fi

# If not custom download firmware from firmware list
if [ $firmware_key != "custom" ]; then
  echo "-------------------------------------------------------------"
  echo "Firmware selected: $firmware_key"
  echo "-------------------------------------------------------------"
  result=$(./get_firmware_download_url.py $firmware_key)
  if [ "$result" != "firmware not found" ]; then
    result=($result)

    download_url=${result[0]}
    baud_rate=${result[1]}
    core=${result[3]}
    autoreset=${result[4]}

    hexfile=$openenergymonitor_dir/data/firmware/$firmware_key.hex

    echo "Downloading firmware from: "
    echo $download_url
    wget -q $download_url -O $hexfile
    
    echo
    echo "Downloaded file: "
    ls -lh $hexfile
  else
    echo "Firmware not found: $firmware_key"
    # exit
    exit 1
  fi
fi

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
      
  for attempt in {1..1}
  do
    echo "Attempt $attempt..."
    echo
    echo "avrdude -Cavrdude.conf -v -p$core -carduino -D -P/dev/$serial_port -b$baud_rate -Uflash:w:$hexfile:i $autoreset"
    avrdude -Cavrdude.conf -v -p$core -carduino -D -P/dev/$serial_port -b$baud_rate -Uflash:w:$hexfile:i $autoreset

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
    
    if [ "$serial_port" = "ttyAMA0" ]; then 
      if [ "$(systemctl is-active emonPiLCD)" = "active" ]; then
          echo "emonPiLCD is running. Restarting in 5s..."
          sleep 5
          sudo systemctl restart emonPiLCD
          echo "emonPiLCD service has been restarted"
      fi
    fi
  fi

else
  echo "Firmware download failed...check network connection"
fi