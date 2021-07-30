#!/bin/bash

user=$USER
emonscripts_dir=/opt/openenergymonitor/EmonScripts

sudo mkdir -p $(dirname "$emonscripts_dir")

sudo apt-get update
sudo apt-get install -y git-core

sudo git clone https://github.com/openenergymonitor/EmonScripts.git $emonscripts_dir
sudo chown $user -R $emonscripts_dir

cd $emonscripts_dir/install
bash ./main.sh

cd
rm -f $(readlink -f "${BASH_SOURCE[0]}")
