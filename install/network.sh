#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Network install"
echo "-------------------------------------------------------------"

cd /opt/emoncms/modules/network
sudo ./install.sh
