#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
source load_config.sh

BOSSAC_DIR="/opt/openenergymonitor/BOSSA"

if [ ! -d $openenergymonitor_dir/data/firmware ]; then
  mkdir -p $openenergymonitor_dir/data/firmware
fi

serial_port=$1
firmware_key=$2

if [ "$serial_port" == "none" ] || [ -z "$serial_port" ]; then
  echo "no serial port selected or available"
  exit 1
fi

if [ -z "$firmware_key" ]; then
  echo "no firmware key provided"
  exit 1
fi

if [ "$firmware_key" == "emonpi" ]; then
  firmware_key="emonPi_discrete_jeelib"
fi

# if custom, get baud_rate, core, autoreset and custom_firmware_filename
if [ "$firmware_key" == "custom" ]; then
  custom_firmware_filename=$3
  baud_rate=$4
  core=$5
  autoreset=$6

  # Create upload folder if it does not exist
  if [ ! -d $openenergymonitor_dir/data/firmware/upload ]; then
    mkdir $openenergymonitor_dir/data/firmware/upload
    # change ownership of upload folder to www-data
    sudo chown -R www-data:www-data $openenergymonitor_dir/data/firmware/upload
    # this is the first time and so no fimware will have been uploaded
    echo "Looks like this is the first custom upload attempt."
    echo "Upload directory has now been created and permissions set."
    echo "Please upload firmware again to continue."
    exit 0
  fi

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
if [ "$firmware_key" != "custom" ]; then
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

    # work out file extension from download_url
    # it may be hex or bin

    extension="hex" 
    if [[ $download_url == *.bin ]]; then 
        extension="bin" 
    fi
    hexfile=$openenergymonitor_dir/data/firmware/$firmware_key.$extension

    echo "Downloading firmware from: "
    echo $download_url
    wget -q $download_url -O $hexfile
    
    if [ $? -ne 0 ]; then
      echo "ERROR: Failed to download firmware"
      exit 1
    fi
    
    echo
    echo "Downloaded file: "
    ls -lh $hexfile
  else
    echo "Firmware not found: $firmware_key"
    exit 1
  fi
fi

if [ -f $hexfile ]; then

  state=$(systemctl show emonhub | grep ActiveState)
  
  if [ "$state" == "ActiveState=active" ]; then
    echo
    echo "EmonHub is running, stopping EmonHub"
    sudo systemctl stop emonhub
    emonhub_stopped_by_script=1
  else
    emonhub_stopped_by_script=0
  fi
  

  echo "Core: $core"
  echo
  echo "Uploading $firmware_key on serial port $serial_port"

  if [ "$core" == "ATSAMD21J17" ] || [ "$core" == "ATSAMD21" ]; then

    # Install/Verify BOSSA
    if [ ! -f "$BOSSAC_DIR/bin/bossac" ]; then
        echo "BOSSA not found. Installing..."
        sudo mkdir -p /opt/openenergymonitor
        if sudo git clone https://github.com/shumatech/BOSSA /opt/openenergymonitor/BOSSA; then
            cd /opt/openenergymonitor/BOSSA && sudo make bossac
            if [ $? -ne 0 ]; then
                echo "ERROR: Failed to build BOSSA"
                cd $DIR
                if [ $emonhub_stopped_by_script == 1 ]; then
                    sudo systemctl start emonhub
                fi
                exit 1
            fi
            cd $DIR
        else
            echo "ERROR: Failed to clone BOSSA repository"
            cd $DIR
            if [ $emonhub_stopped_by_script == 1 ]; then
                sudo systemctl start emonhub
            fi
            exit 1
        fi
    else
        echo "BOSSA is already installed."
    fi

    # Trap to ensure emonhub restarts even if interrupted
    trap 'echo "Interrupted! Cleaning up..."; if [ $emonhub_stopped_by_script == 1 ]; then sudo systemctl start emonhub; fi; exit' INT

    # Trigger Bootloader via Serial
    echo "Sending bootloader trigger to /dev/$serial_port..."
    if [ -e /dev/$serial_port ]; then
        stty -F /dev/$serial_port 115200 raw -echo 2>/dev/null
        echo -ne 'e\n' > /dev/$serial_port
        sleep 0.5
        echo -ne 'y\n' > /dev/$serial_port
        sleep 1
    else
        echo "ERROR: Serial port /dev/$serial_port does not exist"
        if [ $emonhub_stopped_by_script == 1 ]; then
            sudo systemctl start emonhub
        fi
        exit 1
    fi

    # Verify Connection and Upload with retry logic
    echo "Checking device info..."
    upload_success=0
    
    for attempt in {1..3}
    do
        echo "Upload attempt $attempt of 3..."
        
        if $BOSSAC_DIR/bin/bossac -p $serial_port -i > /dev/null 2>&1; then
            echo "Device detected. Starting upload..."
            $BOSSAC_DIR/bin/bossac -p $serial_port -e -w -v -R --offset=0x2000 "$hexfile"
            
            if [ $? -eq 0 ]; then
                echo "SUCCESS: Firmware uploaded successfully"
                upload_success=1
                break
            else
                echo "ERROR: Upload failed on attempt $attempt"
                if [ $attempt -lt 3 ]; then
                    echo "Retrying in 2 seconds..."
                    sleep 2
                fi
            fi
        else
            echo "Warning: Could not communicate with ATSAMD21 on attempt $attempt"
            if [ $attempt -lt 3 ]; then
                echo "Retrying bootloader trigger..."
                stty -F /dev/$serial_port 115200 raw -echo 2>/dev/null
                echo -ne 'e\n' > /dev/$serial_port
                sleep 0.5
                echo -ne 'y\n' > /dev/$serial_port
                sleep 2
            fi
        fi
    done
    
    if [ $upload_success -eq 0 ]; then
        echo "ERROR: Failed to upload firmware after 3 attempts"
        if [ $emonhub_stopped_by_script == 1 ]; then
            sudo systemctl start emonhub
        fi
        exit 1
    fi

  else
        
    for attempt in {1..3}
    do
      echo "Attempt $attempt of 3..."
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
            echo "SUCCESS: flash verified"
            break;
        else 
            echo "ERROR: Not in sync" 
        fi
      fi
    done

  fi
  
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
  echo "ERROR: Firmware file not found or download failed - check network connection"
  exit 1
fi
