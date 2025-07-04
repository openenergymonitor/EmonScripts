#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
source load_config.sh

# Check for emonHP image version
# do not update these
image_version=$(ls /boot | grep emonHP)
if [ "$image_version" = "emonHP-20Nov23" ]; then
    echo "emonHP image 20Nov23 cannot be updated"
    exit
fi


echo "-------------------------------------------------------------"
echo "Main Update Script"
echo "-------------------------------------------------------------"
# Remove /tmp/emon_reboot_required if it exists
if [ -f /tmp/emon_reboot_required ]; then
    sudo rm -f /tmp/emon_reboot_required
fi

type=$1
firmware_key=$2
serial_port=$3

datestr=$(date)

echo "Date:" $datestr
echo "EUID: $EUID"
echo "openenergymonitor_dir: $openenergymonitor_dir"
echo "type: $type"
echo "serial_port: $serial_port"
echo "firmware: $firmware_key"

if [ "$EUID" = "0" ] &&  [ "$user" != "root" ]; then
    # update is being ran mistakenly as root, switch to user
    echo "update running as root, switch to user"
    exit 0
fi

i2c_address=$(python3 $openenergymonitor_dir/EmonScripts/other/i2cdetect.py)

if [ "$i2c_address" == "0x3c" ]; then
    hardware="EmonPi" # emonPi v2
elif [ "$i2c_address" == "0x3f" ]; then
    hardware="EmonPi" # emonPi v1
elif [ "$i2c_address" == "0x27" ]; then
    hardware="EmonPi" # emonPi v1
else
    hardware="rfm2pi"
fi

echo "Hardware detected: $hardware"

sudo apt-get install -y python3-pip

if [ -e /usr/lib/python3.11/EXTERNALLY-MANAGED ]; then
    sudo rm -rf /usr/lib/python3.11/EXTERNALLY-MANAGED
    echo "Removed pip3 external management warning."
fi
if [ -e /usr/lib/python3.11/EXTERNALLY-MANAGED.orig ]; then
    sudo rm -rf /usr/lib/python3.11/EXTERNALLY-MANAGED.orig
    echo "Removed pip3 external management warning."
fi

pip3 install redis

if [ "$emonSD_pi_env" = "1" ]; then
    
    if [ "$hardware" == "EmonPi" ]; then    
        # Stop emonPi LCD servcice
        echo "Stopping emonPiLCD service"
        sudo systemctl stop emonPiLCD
        # Display update message on LCD
        # echo "Display update message on LCD"
        # $python_cmd $openenergymonitor_dir/emonpi/lcd/./emonPiLCD_update.py
    fi
    
    # Ensure logrotate configuration has correct permissions
    sudo chown root:$user $openenergymonitor_dir/EmonScripts/defaults/etc/logrotate.d/*

fi

if [ "$type" == "all" ] || [ "$type" == "emonhub" ]; then
    echo "Running apt-get update"
    sudo apt-get update
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ]; then
    sudo rm -rf hardware/emonpi/emonpi2c/

    for repo in "emonpi" "RFM2Pi" "huawei-hilink-status" "emonPiLCD"; do
        if [ -d $openenergymonitor_dir/$repo ]; then
            echo "git pull $openenergymonitor_dir/$repo"
            cd $openenergymonitor_dir/$repo
            git branch
            git status
            git fetch --all --prune
            git pull
        fi
    done
fi
cd $openenergymonitor_dir/EmonScripts/update

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "emonhub" ]; then
    echo "Start emonhub update script:"
    $openenergymonitor_dir/EmonScripts/update/emonhub.sh
    echo
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "emoncms" ]; then    
    echo "Start emoncms update:"
    $openenergymonitor_dir/EmonScripts/update/emoncms.sh
    echo
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ] && [ "$emonSD_pi_env" = "1" ]; then  
    $openenergymonitor_dir/EmonScripts/update/emonsd.sh $python_cmd
fi

# -----------------------------------------------------------------

if [ "$type" == "firmware" ]; then
    if [ "$firmware_key" != "none" ]; then
        $openenergymonitor_dir/EmonScripts/update/atmega_firmware_upload.sh $serial_port $firmware_key
    fi
fi

# -----------------------------------------------------------------

if [ "$hardware" == "EmonPi" ]; then
    echo
    # Wait for update to finish
    echo "Starting emonPi LCD service.."
    sleep 5
    sudo systemctl restart emonPiLCD
    echo
fi

# -----------------------------------------------------------------

datestr=$(date)

echo
echo "-------------------------------------------------------------"
echo "System update done: $datestr" # this text string is used by service runner to stop the log window polling, DO NOT CHANGE!
echo "-------------------------------------------------------------"

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "emoncms" ]; then
    echo "restarting service-runner"
    sudo systemctl restart service-runner.service 
fi

# Display REBOOT REQUIRED message if flag file exists
if [ -f /tmp/emon_reboot_required ]; then
    echo
    echo "*************************************************************"
    echo "******************** REBOOT REQUIRED ************************"
    echo "*************************************************************"
fi
