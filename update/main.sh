#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Main Update Script"
echo "-------------------------------------------------------------"

type=$1
firmware=$2

datestr=$(date)

echo "Date:" $datestr
echo "EUID: $EUID"
echo "usrdir: $usrdir"
echo "type: $type"
echo "firmware: $firmware"

if [ "$EUID" = "0" ] ; then
    # update is being ran mistakenly as root, switch to user
    echo "update running as root, switch to user"
    exit 0
fi

if [ "$emonSD_pi_env" = "1" ]; then
    # Check if we have an emonpi LCD connected, 
    # if we do assume EmonPi hardware else assume RFM69Pi
    lcd27=$(sudo $usrdir/emonpi/lcd/emonPiLCD_detect.sh 27 1)
    lcd3f=$(sudo $usrdir/emonpi/lcd/emonPiLCD_detect.sh 3f 1)

    if [ $lcd27 == 'True' ] || [ $lcd3f == 'True' ]; then
        hardware="EmonPi"
    else
        hardware="rfm2pi"
    fi
    echo "Hardware detected: $hardware"
    
    if [ $hardware == "EmonPi" ]; then    
        # Stop emonPi LCD servcice
        echo "Stopping emonPiLCD service"
        sudo service emonPiLCD stop

        # Display update message on LCD
        echo "Display update message on LCD"
        sudo $usrdir/emonpi/lcd/./emonPiLCD_update.py
    fi
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ]; then
    sudo rm -rf hardware/emonpi/emonpi2c/

    for repo in "emonpi" "RFM2Pi" "usefulscripts" "huawei-hilink-status" "oem_openHab" "oem_node-red"; do
        if [ -d $usrdir/$repo ]; then
            echo "git pull $usrdir/$repo"
            cd $usrdir/$repo
            git branch
            git status
            git pull
        fi
    done
fi
cd $usrdir/EmonScripts/update

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "firmware" ]; then

    if [ "$firmware" == "emonpi" ]; then
        $usrdir/EmonScripts/update/emonpi.sh
    fi

    if [ "$firmware" == "rfm69pi" ]; then
        $usrdir/EmonScripts/update/rfm69pi.sh
    fi
    
    if [ "$firmware" == "rfm12pi" ]; then
        $usrdir/EmonScripts/update/rfm12pi.sh
    fi
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "emonhub" ]; then
    echo "Start emonhub update script:"
    $usrdir/EmonScripts/update/emonhub.sh
    echo
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "emoncms" ]; then    
    echo "Start emoncms update:"
    $usrdir/EmonScripts/update/emoncms_core.sh
    $usrdir/EmonScripts/update/emoncms_modules.sh
    echo
fi

# -----------------------------------------------------------------

if [ $hardware == "EmonPi" ]; then
    echo
    # Wait for update to finish
    echo "Starting emonPi LCD service.."
    sleep 5
    sudo service emonPiLCD restart
    echo
fi

# -----------------------------------------------------------------

datestr=$(date)

echo
echo "-------------------------------------------------------------"
echo "Update done: $datestr" # this text string is used by service runner to stop the log window polling, DO NOT CHANGE!
echo "-------------------------------------------------------------"

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "emoncms" ]; then
    echo "restarting service-runner"
    sudo systemctl restart service-runner.service 
fi
