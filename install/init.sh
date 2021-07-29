#!/bin/bash

user=$USER
emonscripts_dir=/opt/openenergymonitor/emonscripts
emoncms_dir=/opt/emoncms

sudo apt-get update -y
sudo apt-get install -y git-core

sudo mkdir $emoncms_dir $(dirname "emonscripts_dir"))
sudo chown $user $emoncms_dir

sudo git clone -b seal https://github.com/isc-konstanz/emonscripts.git $emonscripts_dir
sudo chown $user -R $emonscripts_dir

cd $emonscripts_dir/install
bash ./main.sh

cd
rm -f init.sh
