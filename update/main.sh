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
    
    # Stop emonPi LCD servcice
    echo "Stopping emonPiLCD service"
    sudo service emonPiLCD stop

    # Display update message on LCD
    echo "Display update message on LCD"
    sudo $usrdir/emonpi/lcd/./emonPiLCD_update.py
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ]; then

    if [ -d $usrdir/emonpi ]; then
        echo "git pull $usrdir/emonpi"
        cd $usrdir/emonpi
        sudo rm -rf hardware/emonpi/emonpi2c/
        git branch
        git status
        git pull
    fi

    if [ -d $usrdir/RFM2Pi ]; then
        echo "git pull $usrdir/RFM2Pi"
        cd $usrdir/RFM2Pi
        git branch
        git status
        git pull
        echo
    fi

    if [ -d $usrdir/usefulscripts ]; then
        echo "git pull $usrdir/usefulscripts"
        cd $usrdir/usefulscripts
        git branch
        git status
        git pull
        echo
    fi

    if [ -d $usrdir/huawei-hilink-status ]; then
        echo "git pull $usrdir/huawei-hilink-status"
        cd $usrdir/huawei-hilink-status
        git branch
        git status
        git pull
        echo
    fi

    if [ -d $usrdir/oem_openHab ]; then
        echo "git pull $usrdir/oem_openHab"
        cd $usrdir/oem_openHab
        git branch
        git status
        git pull
        echo
    fi

    if [ -d $usrdir/oem_node-red ]; then
        echo "git pull $usrdir/oem_node-red"
        cd $usrdir/oem_node-red
        git branch
        git status
        git pull
        echo
    fi
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
    # Run emonHub update script to update emonhub.conf nodes
    $usrdir/EmonScripts/update/emonhub.sh
    echo
fi

# -----------------------------------------------------------------

if [ "$type" == "all" ] || [ "$type" == "emoncms" ]; then    
    echo "Start emoncms update:"
    # Run emoncms update script to pull in latest emoncms & emonhub updates
    $usrdir/EmonScripts/update/emoncms_core.sh
    $usrdir/EmonScripts/update/emoncms_modules.sh
    echo
fi

# -----------------------------------------------------------------

if [ "$emonSD_pi_env" = "1" ]; then
    echo
    # Wait for update to finish
    echo "Starting emonPi LCD service.."
    sleep 5
    sudo service emonPiLCD restart
    echo

    if [ -f /usr/bin/rpi-ro ]; then
        rpi-ro
    fi
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
    # old service runner
    killall service-runner
    # new service runner
    sudo systemctl restart service-runner.service 
fi

