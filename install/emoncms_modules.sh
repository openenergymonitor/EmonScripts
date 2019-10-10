#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Install Emoncms Modules"
echo "-------------------------------------------------------------"
# Review default branch: e.g stable
cd $emoncms_www/Modules
for module in ${!emoncms_modules[@]}; do
    branch=${emoncms_modules[$module]}
    if [ ! -d $module ]; then
        echo "- Installing module: $module"
        git clone -b $branch ${git_repo[$module]} $module
    else
        echo "- Module $module already exists"
    fi
done

if [ -d $emoncms_www/Modules/wifi ]; then
    # wifi module sudoers entry
    sudo visudo -cf $openenergymonitor_dir/EmonScripts/sudoers.d/wifi-sudoers && \
    sudo cp $openenergymonitor_dir/EmonScripts/sudoers.d/wifi-sudoers /etc/sudoers.d/
    sudo chmod 0440 /etc/sudoers.d/wifi-sudoers
    echo "wifi sudoers entry installed"
    # wpa_supplicant permissions
    sudo chmod 644 /etc/wpa_supplicant/wpa_supplicant.conf
fi

if [ ! -d $emoncms_dir ]
then
    sudo mkdir $emoncms_dir
    sudo chown $USER $emoncms_dir
fi

# Install emoncms modules that do not reside in /var/www/emoncms/Modules
if [ ! -d $emoncms_dir/modules ]; then
    mkdir $emoncms_dir/modules
fi

cd $emoncms_dir/modules
for module in ${!symlinked_emoncms_modules[@]}; do
    branch=${symlinked_emoncms_modules[$module]}
    if [ ! -d $module ]; then
        echo "- Installing module: $module"
        git clone -b $branch ${git_repo[$module]}
        # If module contains emoncms UI folder, symlink to $emoncms_www/Modules
        if [ -d $emoncms_dir/modules/$module/$module-module ]; then
            echo "-- UI directory symlink"
            ln -s $emoncms_dir/modules/$module/$module-module $emoncms_www/Modules/$module
        fi
        # run module install script if present
        if [ -f $emoncms_dir/modules/$module/install.sh ]; then
            $emoncms_dir/modules/$module/install.sh $openenergymonitor_dir
            echo
        fi
    else
        echo "- Module $module already exists"
    fi
done

# backup module
if [ -d $emoncms_dir/modules/backup ]; then
    cd $emoncms_dir/modules/backup
    if [ ! -f config.cfg ]; then
        cp default.config.cfg config.cfg
        sed -i "s~USER~$user~" config.cfg
        sed -i "s~BACKUP_SCRIPT_LOCATION~$emoncms_dir/modules/backup~" config.cfg
        sed -i "s~EMONCMS_LOCATION~$emoncms_www~" config.cfg
        sed -i "s~BACKUP_LOCATION~$openenergymonitor_dir/data~" config.cfg
        sed -i "s~DATABASE_PATH~$emoncms_datadir~" config.cfg
        sed -i "s~EMONHUB_CONFIG_PATH~/etc/emonhub~" config.cfg
        sed -i "s~EMONHUB_SPECIMEN_CONFIG~$openenergymonitor_dir/emonhub/conf~" config.cfg
        sed -i "s~BACKUP_SOURCE_PATH~$openenergymonitor_dir/data/uploads~" config.cfg
    fi
    cd
fi

echo "Update Emoncms database"
php $openenergymonitor_dir/EmonScripts/common/emoncmsdbupdate.php
