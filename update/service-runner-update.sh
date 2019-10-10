#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
source config.ini

if [ -z "$2" ]; then
    type="all"
    firmware=$1
else
    type=$1
    firmware=$2
fi

# Clear log update file
cat /dev/null > /var/log/emoncms/emonupdate.log

echo "Starting update via service-runner-update.sh (v3.0) >"

# -----------------------------------------------------------------

# Check emonSD version
image_version=$(ls /boot | grep emonSD)

if [ "$image_version" = "" ]; then
    echo "- Could not find emonSD version file"
    emonSD_pi_env=0
else 
    echo "- emonSD version: $image_version"
    valid=0
    
    save_to_update=$(curl -s https://raw.githubusercontent.com/openenergymonitor/EmonScripts/master/safe-update)
    while read -r image_name; do
        if [ "$image_version" == "$image_name" ]; then
            echo "emonSD base image check passed...continue update"
            valid=1
        fi
    done <<< "$save_to_update"

    if [ $valid == 0 ]; then
        echo "ERROR: emonSD base image old or undefined...update will not continue"
        echo "See latest verson: https://github.com/openenergymonitor/emonpi/wiki/emonSD-pre-built-SD-card-Download-&-Change-Log"
        echo "Stopping update"
        exit 0
    fi
fi

# -----------------------------------------------------------------

# Pull in latest EmonScripts repo before then running updated update scripts
echo "git pull $openenergymonitor_dir/EmonScripts"
cd $openenergymonitor_dir/EmonScripts
git branch
git status
git pull
echo

# Run update in main update script
$openenergymonitor_dir/EmonScripts/update/main.sh $type $firmware
