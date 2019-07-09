#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Install EmonMUC"
echo "-------------------------------------------------------------"

# Install emonmuc repository with git
if [ ! -d $emonmuc_dir ]; then
    echo "Downloading emonmuc framework"
    git clone -b $emonmuc_branch https://github.com/isc-konstanz/emonmuc.git
	
    bash $emonmuc_dir/setup.sh --emoncms $emoncms_www
else
    echo "Emonmuc framework already installed"
fi
