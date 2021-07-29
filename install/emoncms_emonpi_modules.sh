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
        echo "- Installing module: $module"
        git clone -b $branch ${git_repo[$module]}
    else
        echo "- Module $module already exists"
    fi
done

if [ -d $emoncms_www/Modules/wifi ]; then
    # wifi module sudoers entry
    sudo visudo -cf $emonscripts_dir/sudoers.d/wifi-sudoers && \
    sudo cp $emonscripts_dir/sudoers.d/wifi-sudoers /etc/sudoers.d/
    sudo chmod 0440 /etc/sudoers.d/wifi-sudoers
    echo "wifi sudoers entry installed"
    # wpa_supplicant permissions
    sudo chmod 644 /etc/wpa_supplicant/wpa_supplicant.conf
fi

echo "Update Emoncms database"
php $emonscripts_dir/common/emoncmsdbupdate.php
