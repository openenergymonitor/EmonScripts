#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Install EmonMUC"
echo "-------------------------------------------------------------"

# Install emonmuc repository with git
if [ ! -d $emonmuc_dir ]; then
    echo "Downloading emonmuc framework"
    sudo git clone -b $emonmuc_branch ${git_repo[emonmuc]} $emonmuc_dir
    sudo chown -R $user $emonmuc_dir
    
    sudo bash $emonmuc_dir/setup.sh --emoncms $emoncms_www
else
    echo "Emonmuc framework already installed"
fi
