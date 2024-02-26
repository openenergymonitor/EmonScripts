#!/bin/bash

# Copy stdout and stderr to a log file in addition to the console
# tee -a used in case script is run multiple times

LOG_FILE=~/$(basename "$0").log
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "Script output also stored in ${LOG_FILE}"
echo -e "Started: $(date)\n"

user=$USER
openenergymonitor_dir=/opt/openenergymonitor
emoncms_dir=/opt/emoncms

sudo apt-get update -y
sudo apt-get install -y git-core

sudo mkdir $openenergymonitor_dir
sudo chown $user $openenergymonitor_dir

sudo mkdir $emoncms_dir
sudo chown $user $emoncms_dir

cd $openenergymonitor_dir

echo "-- Installing EmonScripts"
git clone https://github.com/openenergymonitor/EmonScripts.git
cd $openenergymonitor_dir/EmonScripts
git checkout stable

echo "-- Running install/main.sh"
cd $openenergymonitor_dir/EmonScripts/install
./main.sh
cd

rm init.sh

echo -e "\nScript output also stored in ${LOG_FILE}"
