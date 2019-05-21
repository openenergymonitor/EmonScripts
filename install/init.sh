#!/bin/bash

user=$USER
usrdir=/opt/emon

sudo apt-get update -y
sudo apt-get install -y git-core

sudo mkdir $usrdir
sudo chown $user $usrdir
cd $usrdir

git clone https://github.com/openenergymonitor/EmonScripts.git

cd $usrdir/EmonScripts/install
./main.sh
cd

rm init.sh
