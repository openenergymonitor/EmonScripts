#!/bin/bash

user=$USER
openenergymonitor_dir=/opt/openenergymonitor

sudo apt-get update -y
sudo apt-get install -y git-core

sudo mkdir $openenergymonitor_dir
sudo chown $user $openenergymonitor_dir
cd $openenergymonitor_dir

git clone https://github.com/openenergymonitor/EmonScripts.git

cd $openenergymonitor_dir/EmonScripts/install
./main.sh
cd

rm init.sh
