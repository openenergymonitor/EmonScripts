#!/bin/bash
# --------------------------------------------------------------------------------
# emonSD / emoncms build script
# Emoncms, Emoncms Modules, EmonHub & dependencies
#
# Runs the component scripts enabled in config.ini. For an emonSD image,
# follow docs/developer.md (then verify.sh and prepare_image.sh).
# --------------------------------------------------------------------------------

# Copy stdout and stderr to a log file in addition to the console
# tee -a used in case script is run multiple times

# --yes: run without questions (automated image builds, see image/build.sh)
assume_yes=0
if [ "$1" = "--yes" ]; then
    assume_yes=1
fi

LOG_FILE=~/$(basename "$0").log
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "Script output also stored in ${LOG_FILE}"
echo -e "Started: $(date)\n"

# fix interactive popup that keeps asking for service restart
if [ -f /etc/needrestart/needrestart.conf ]; then
  sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
fi

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
if [ "$assume_yes" = "1" ]; then
    start_confirm=n
else
    read -p "Would you like to review the build script config before starting? (y/n) " start_confirm
fi

if [ "$start_confirm" != "n" ] && [ "$start_confirm" != "N" ]; then
    echo ""
    echo "You selected 'yes' to review config"
    echo "Please review config.ini and restart the build script to continue"
    echo ""
    echo "    cd $openenergymonitor_dir/EmonScripts/install/"
    echo "    nano config.ini"
    echo "    ./main.sh"
    echo ""
    exit 0
fi

if [ "$emonSD_pi_env" = "1" ] && [ "$prune_os" = true ]; then
    echo "-------------------------------------------------------------"
    echo "Removing unused Raspberry Pi OS software"
    echo "-------------------------------------------------------------"
    $openenergymonitor_dir/EmonScripts/install/prune.sh
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

    sudo apt-get install -y --fix-broken
    
    echo ""
    echo "Important: Did you get a request to reboot your machine, if so we recommend you do this now."
    if [ "$assume_yes" = "1" ]; then
        reboot_confirm=n
    else
        read -p "Would you like to exit installation to reboot your machine? (y/n) " reboot_confirm
    fi
    if [ "$reboot_confirm" != "n" ] && [ "$reboot_confirm" != "N" ]; then
        exit 0
    fi
fi

# Required to allow the webserver to use git commands. ref 
# https://community.openenergymonitor.org/t/ubuntu-22-04-lxc-install-issues-git/22189/1
sudo git config --system --add safe.directory '*'

# Required for emonpiLCD, wifi, rfm69pi firmware (review)
if [ ! -d $openenergymonitor_dir/data ]; then mkdir $openenergymonitor_dir/data; fi

echo "-------------------------------------------------------------"
sudo apt-get install -y git build-essential python3-pip python3-dev sysstat

# Remove the pip external management marker for the python version in use,
# so later pip3 installs (emonhub dependencies) work. Same approach as
# emonhub/install.sh. It's probably better to fix this by using python venv
python_lib_dir=$(python3 -c 'import sysconfig; print(sysconfig.get_paths()["stdlib"])' 2>/dev/null)
for marker in "$python_lib_dir/EXTERNALLY-MANAGED" "$python_lib_dir/EXTERNALLY-MANAGED.orig"; do
    if [ -n "$python_lib_dir" ] && [ -e "$marker" ]; then
        sudo rm -f "$marker"
        echo "Removed pip3 external management warning: $marker"
    fi
done


echo "-------------------------------------------------------------"

if [ "$install_apache" = true ]; then $openenergymonitor_dir/EmonScripts/install/apache.sh; fi
if [ "$install_mysql" = true ]; then $openenergymonitor_dir/EmonScripts/install/mysql.sh; fi
if [ "$install_php" = true ]; then $openenergymonitor_dir/EmonScripts/install/php.sh; fi
if [ "$install_redis" = true ]; then $openenergymonitor_dir/EmonScripts/install/redis.sh; fi
if [ "$install_mosquitto" = true ]; then $openenergymonitor_dir/EmonScripts/install/mosquitto.sh; fi
if [ "$install_emoncms_core" = true ]; then $openenergymonitor_dir/EmonScripts/install/emoncms_core.sh; fi
if [ "$install_emoncms_modules" = true ]; then $openenergymonitor_dir/EmonScripts/install/emoncms_modules.sh; fi

if [ "$emonSD_pi_env" = "1" ]; then
    if [ "$install_emoncms_emonpi_modules" = true ]; then $openenergymonitor_dir/EmonScripts/install/emoncms_emonpi_modules.sh; fi
    if [ "$install_emonhub" = true ]; then $openenergymonitor_dir/EmonScripts/install/emonhub.sh; fi
    if [ "$install_firmware" = true ]; then $openenergymonitor_dir/EmonScripts/install/firmware.sh; fi
    if [ "$install_emonpilcd" = true ]; then $openenergymonitor_dir/EmonScripts/install/emonpilcd.sh; fi
    if [ "$install_docker" = true ]; then $openenergymonitor_dir/EmonScripts/install/docker.sh; fi
    if [ "$install_emonsd" = true ]; then $openenergymonitor_dir/EmonScripts/install/emonsd.sh; fi
    # Network must be run last
    if [ "$install_network" = true ]; then $openenergymonitor_dir/EmonScripts/install/network.sh; fi
else
    $openenergymonitor_dir/EmonScripts/install/non_emonsd.sh;
fi

echo -e "\nScript output also stored in ${LOG_FILE}"
