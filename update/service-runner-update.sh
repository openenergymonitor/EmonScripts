#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
source load_config.sh

type="all"
if [ ! -z $1 ]; then
  type=$1
fi

firmware_key="emonPi_discrete_jeelib"
if [ ! -z $2 ]; then
  firmware_key=$2
fi

serial_port="ttyAMA0"
if [ ! -z $3 ]; then
  serial_port=$3
fi

# Clear log update file
cat /dev/null > /var/log/emoncms/emonupdate.log

# Find largest log file and remove
varlog_available=$(df | awk '$NF == "/var/log" { print $4 }')
if [ "$varlog_available" -lt "1024" ]; then
    largest_log_file=$(sudo find /var/log -type f -printf "%s\t%p\n" | sort -n | tail -1 | cut -f 2)
    sudo truncate -s 0 $largest_log_file
    echo "$largest_log_file truncated to make room for update log" 
fi

echo "Starting update via service-runner-update.sh (v3.0) >"
# Log the free space on each filesystem.
df -h

# -----------------------------------------------------------------

# Check emonSD version
image_version=$(ls /boot | grep emonSD)

if [ "$image_version" = "" ]; then
    echo "- Could not find emonSD version file"
    emonSD_pi_env=0
else 
    echo "- emonSD version: $image_version"
    valid=0
    
    retry=0
    while [ $retry -lt 5 ]; do
        safe_to_update=$(curl -s https://raw.githubusercontent.com/openenergymonitor/EmonScripts/master/safe-update)
        if [ "$safe_to_update" == "" ]; then
            echo "  retry fetching safe-update list"
            retry=$((retry+1))        
            sleep 3
        else
            break
        fi
    done
    if [ "$safe_to_update" == "" ]; then
        echo "ERROR: Could not load safe-update list, please check network connection"
        exit 0
    fi

    echo "- supported images: "$safe_to_update

    while read -r image_name; do
        if [ "$image_version" == "$image_name" ]; then
            echo "- emonSD base image check passed...continue update"
            valid=1
        fi
    done <<< "$safe_to_update"

    if [ $valid == 0 ]; then
        echo "ERROR: emonSD base image old or undefined...update will not continue"
        echo "See latest verson: https://github.com/openenergymonitor/emonpi/wiki/emonSD-pre-built-SD-card-Download-&-Change-Log"
        echo "Stopping update"
        exit 0
    fi
fi

# -----------------------------------------------------------------

# Pull in latest EmonScripts repo before then running updated update scripts
echo "git pull $emonscripts_dir"
cd $emonscripts_dir
git branch
git status
git pull
echo

# Run update in main update script
$emonscripts_dir/update/main.sh $type $firmware_key $serial_port
