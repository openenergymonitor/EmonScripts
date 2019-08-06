#!/bin/bash

user=$USER
oem_dir=/opt/openenergymonitor
emoncms_dir=/opt/emoncms

sudo apt-get update -y
sudo apt-get install -y git-core

sudo mkdir $oem_dir
sudo chown $user $oem_dir

sudo mkdir $emoncms_dir
sudo chown $user $emoncms_dir

git clone https://github.com/openenergymonitor/EmonScripts.git $oem_dir/EmonScripts

cd $oem_dir/EmonScripts/install
bash ./main.sh

cd
rm -f init.sh > 
