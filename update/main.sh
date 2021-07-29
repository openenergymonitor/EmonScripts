#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
source load_config.sh

echo "-------------------------------------------------------------"
echo "Update EmonPi stack"
echo "-------------------------------------------------------------"

type=$1
firmware_key=$2
serial_port=$3

datestr=$(date)

echo "Date:" $datestr
echo "EUID: $EUID"
echo "root: $openenergymonitor_dir"
echo "type: $type"
echo "serial_port: $serial_port"
echo "firmware: $firmware_key"

if [ "$EUID" = "0" ] ; then
    # update is being ran mistakenly as root, switch to user
    echo "update running as root, switch to user"
    exit 0
fi

sudo mkdir -p $openenergymonitor_dir
sudo chown $user $openenergymonitor_dir

sudo apt-get install -y python3-pip
pip3 install redis

if [ "$emonSD_pi_env" = "1" ]; then
    # Check if we have an emonpi LCD connected, 
    # if we do assume EmonPi hardware else assume RFM69Pi
    lcd27=$(sudo $openenergymonitor_dir/emonpi/lcd/emonPiLCD_detect.sh 27 1)
    lcd3f=$(sudo $openenergymonitor_dir/emonpi/lcd/emonPiLCD_detect.sh 3f 1)
    
    # Check if python3-smbus is available for LCD
    lcdp3=$(dpkg-query -W -f='${Status}' python3-smbus)
    if [ "$lcdp3" == 'install ok installed' ]; then python_cmd="python3"; else python_cmd="python"; fi
    
    if [ $lcd27 == 'True' ] || [ $lcd3f == 'True' ]; then
        hardware="EmonPi"
    else
        hardware="rfm2pi"
    fi
    echo "Hardware detected: $hardware"
    
    if [ "$hardware" == "EmonPi" ]; then    
        # Stop emonPi LCD servcice
        echo "Stopping emonPiLCD service"
        sudo systemctl stop emonPiLCD

        # Display update message on LCD
        echo "Display update message on LCD"
        $python_cmd $openenergymonitor_dir/emonpi/lcd/./emonPiLCD_update.py
    fi
    
    # Ensure logrotate configuration has correct permissions
    sudo chown root:pi $emonscripts_dir/defaults/etc/logrotate.d/*

fi

if [ "$type" == "all" ] || [ "$type" == "emonhub" ]; then
    echo "Running apt-get update"
    sudo apt-get update
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ]; then
    sudo rm -rf hardware/emonpi/emonpi2c/

    for repo in "emonpi" "RFM2Pi" "usefulscripts" "huawei-hilink-status" "oem_openHab" "oem_node-red"; do
        if [ -d $emonscripts_dir/$repo ]; then
            echo "git pull $emonscripts_dir/$repo"
            cd $emonscripts_dir/$repo
            git branch
            git status
            git fetch --all --prune
            git pull
			echo
        fi
    done
fi
cd $emonscripts_dir/update

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "emonhub" ]; then
    echo "Start emonhub update script:"
    $emonscripts_dir/update/emonhub.sh
    echo
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "emonmuc" ]; then
    echo "Start emonmuc update script:"
    $emonscripts_dir/update/emonmuc.sh
    echo
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "emoncms" ]; then    
    echo "Start emoncms update:"
    $emonscripts_dir/update/emoncms.sh
    echo
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ] && [ "$emonSD_pi_env" = "1" ]; then  
    $emonscripts_dir/update/emonsd.sh $python_cmd
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "firmware" ]; then
    if [ "$firmware_key" != "none" ]; then
        $emonscripts_dir/update/atmega_firmware_upload.sh $serial_port $firmware_key
    fi
fi

# -----------------------------------------------------------------

if [ "$hardware" == "EmonPi" ]; then
    echo
    # Wait for update to finish
    echo "Starting emonPi LCD service.."
    sleep 5
    sudo service emonPiLCD restart
    echo
fi

# -----------------------------------------------------------------

datestr=$(date)
echo "-------------------------------------------------------------"
echo "System update done: $datestr" # this text string is used by service runner to stop the log window polling, DO NOT CHANGE!
echo "-------------------------------------------------------------"

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "emoncms" ]; then
    echo "restarting service-runner"
    sudo systemctl restart service-runner.service 
fi
