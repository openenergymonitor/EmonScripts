#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Install Emoncms EMONPi / EmonBase specific Modules"
echo "-------------------------------------------------------------"
# Review default branch: e.g stable
cd $emoncms_www/Modules
for module in ${!emoncms_emonpi_modules[@]}; do
    branch=${emoncms_emonpi_modules[$module]}
    if [ ! -d $module ]; then
        echo "-- Installing module: $module"
        git clone -b $branch ${git_repo[$module]}
    else
        echo "-- Module $module already exists"
    fi
done

echo "-- Update Emoncms database"
php $openenergymonitor_dir/EmonScripts/common/emoncmsdbupdate.php
