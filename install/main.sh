# --------------------------------------------------------------------------------
# RaspberryPi Strech Build Script
# Emoncms, Emoncms Modules, EmonHub & dependencies
#
# Tested with: Raspbian Strech
# Date: 19 March 2019
#
# Status: Work in Progress
# --------------------------------------------------------------------------------

# Review splitting this up into seperate scripts
# - emoncms installer
# - emonhub installer
# Format as documentation

#!/bin/bash
if [ ! -f config.ini ]; then
    cp emonsd.config.ini config.ini
fi
source load_config.sh

echo "-------------------------------------------------------------"
echo "EmonSD Install"
echo "-------------------------------------------------------------"

echo "Warning: The default configuration of this script applies"
echo "significant modification to the underlying system!"
echo ""
read -p "Would you like to review the build script config before starting? (y/n) " start_confirm

if [ "$start_confirm" != "n" ] && [ "$start_confirm" != "N" ]; then
    echo ""
    echo "You selected 'yes' to review config"
    echo "Please review config.ini and restart the build script to continue"
    echo ""
    echo "    cd $emonscripts_dir/install/"
    echo "    nano config.ini"
    echo "    ./main.sh"
    echo ""
    exit 0
fi

if [ "$apt_get_upgrade_and_clean" = true ]; then
    echo "apt-get update"
    sudo apt-get update -y
    echo "-------------------------------------------------------------"
    echo "apt-get upgrade"
    sudo apt-get upgrade -y
    echo "-------------------------------------------------------------"
    echo "apt-get dist-upgrade"
    sudo apt-get dist-upgrade -y
    echo "-------------------------------------------------------------"
    echo "apt-get clean"
    sudo apt-get clean

    # Needed on stock raspbian lite 19th March 2019
    sudo apt --fix-broken install
fi

echo "-------------------------------------------------------------"
sudo apt-get install -y git build-essential python3-pip python3-dev

sudo mkdir -p $openenergymonitor_dir
sudo chown $user $openenergymonitor_dir

if [ "$install_apache" = true ]; then $emonscripts_dir/install/apache.sh; fi
if [ "$install_mysql" = true ]; then $emonscripts_dir/install/mysql.sh; fi
if [ "$install_php" = true ]; then $emonscripts_dir/install/php.sh; fi
if [ "$install_redis" = true ]; then $emonscripts_dir/install/redis.sh; fi
if [ "$install_mosquitto" = true ]; then $emonscripts_dir/install/mosquitto.sh; fi
if [ "$install_emoncms_core" = true ]; then $emonscripts_dir/install/emoncms_core.sh; fi
if [ "$install_emoncms_modules" = true ]; then $emonscripts_dir/install/emoncms_modules.sh; fi
if [ "$install_emonhub" = true ]; then $emonscripts_dir/install/emonhub.sh; fi
if [ "$install_emonmuc" = true ]; then $emonscripts_dir/install/emonmuc.sh; fi

if [ "$emonSD_pi_env" = "1" ]; then
    # Required for emonpiLCD, wifi, rfm69pi firmware (review)
    if [ ! -d $openenergymonitor_dir/data ]; then mkdir $openenergymonitor_dir/data; fi

    if [ "$install_emoncms_emonpi_modules" = true ]; then $emonscripts_dir/install/emoncms_emonpi_modules.sh; fi
    if [ "$install_firmware" = true ]; then $emonscripts_dir/install/firmware.sh; fi
    if [ "$install_emonpilcd" = true ]; then $emonscripts_dir/install/emonpilcd.sh; fi
    if [ "$install_wifiap" = true ]; then $emonscripts_dir/install/wifiap.sh; fi
    if [ "$install_emonsd" = true ]; then $emonscripts_dir/install/emonsd.sh; fi

    # Enable service-runner update
    # update checks for image type and only runs with a valid image name file in the boot partition
    sudo touch /boot/emonSD-02Oct19
    exit 0
    # Reboot to complete
    sudo reboot
else
    $emonscripts_dir/install/non_emonsd.sh;
    # sudo touch /boot/emonSD-30Oct18
    exit 0
    # Reboot to complete
    sudo reboot
fi
