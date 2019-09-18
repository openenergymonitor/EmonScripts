#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Install Emoncms Core"
echo "-------------------------------------------------------------"

# Give user ownership over www folder
root_www=$(dirname "$emoncms_www")
if [ ! -d $root_www ]; then
    sudo mkdir -p $root_www
fi
sudo chown $user $root_www

# Install emoncms core repository with git
if [ ! -d $emoncms_www ]; then
    cd $root_www && git clone -b $emoncms_core_branch ${git_repo[emoncms_core]}
    cd
else
    echo "- emoncms already installed"
fi

# Create emoncms logfolder
if [ ! -f $emoncms_log_location ]; then
    echo "- creating emoncms log folder"
    sudo mkdir $emoncms_log_location
    sudo chown $user $emoncms_log_location
    sudo touch "$emoncms_log_location/emoncms.log"
    sudo chmod 666 "$emoncms_log_location/emoncms.log"
else
    echo "- log folder already exists"
fi

# Copy and install default.settings.php
if [ ! -f $emoncms_www/settings.php ]; then
    echo "- installing default emoncms settings.php"
    cp $openenergymonitor_dir/EmonScripts/defaults/emoncms/default.settings.php $emoncms_www/settings.php
    
    sed -i "s~EMONCMS_DIR~$emoncms_dir~" $emoncms_www/settings.php
    sed -i "s~OPENENERGYMONITOR_DIR~$openenergymonitor_dir~" $emoncms_www/settings.php
    
    sed -i "s~database = \"emoncms\"~database = \"$mysql_database\"~" $emoncms_www/settings.php
    sed -i "s~username = \"emoncms\"~username = \"$mysql_user\"~" $emoncms_www/settings.php
    sed -i "s~password = \"emonpiemoncmsmysql2016\"~password = \"$mysql_password\"~" $emoncms_www/settings.php
    
    sed -i "s~'user'     => 'emonpi'~'user'     => '$mqtt_user'~" $emoncms_www/settings.php
    sed -i "s~'password' => 'emonpimqtt2016'~'password' => '$mqtt_password'~" $emoncms_www/settings.php
else
    echo "- emoncms settings.php already exists"
fi

if [ ! -d $emoncms_datadir ]; then
    sudo mkdir $emoncms_datadir
    sudo chown $user $emoncms_datadir
fi

# Create data directories for emoncms feed engines:
for engine in "phpfina" "phpfiwa" "phptimeseries"; do
    if [ ! -d $emoncms_datadir/$engine ]; then
        echo "- create $engine dir"
        sudo mkdir $emoncms_datadir/$engine
        sudo chown www-data:root $emoncms_datadir/$engine
    else
        echo "- datadir $engine already exists"
    fi
done

if [ ! -d $emoncms_dir ]
then
    sudo mkdir $emoncms_dir
    sudo chown $USER $emoncms_dir
fi

# Create a symlink to reference emoncms within the web root folder (review):
if [ "$emoncms_www" != "/var/www/emoncms" ]; then
    echo "- symlinking emoncms folder to /var/www/emoncms"
    sudo ln -s $emoncms_www /var/www/emoncms
fi
if [ ! -d /var/www/html/emoncms ]; then
    echo "- symlinking emoncms folder to /var/www/html/emoncms"
    sudo -u www-data ln -s $emoncms_www /var/www/html/emoncms
    
    # Redirect (review)
    echo "- creating redirect to $emoncms_www"
    echo "<?php header('Location: ../emoncms'); ?>" > $emoncms_dir/index.php
    sudo mv $emoncms_dir/index.php /var/www/html/index.php
    sudo chown www-data /var/www/html/index.php
    sudo rm /var/www/html/index.html
fi

echo "-------------------------------------------------------------"
echo "Install Emoncms Services"
echo "-------------------------------------------------------------"
for service in "emoncms_mqtt" "feedwriter" "service-runner"; do
    servicepath=$emoncms_www/scripts/services/$service/$service.service
    $openenergymonitor_dir/EmonScripts/common/install_emoncms_service.sh $servicepath $service
done
echo

if [ "$emonSD_pi_env" = "1" ]; then  
  # Sudoers entry (review)
  sudo visudo -cf $openenergymonitor_dir/EmonScripts/sudoers.d/emoncms-rebootbutton && \
  sudo cp $openenergymonitor_dir/EmonScripts/sudoers.d/emoncms-rebootbutton /etc/sudoers.d/
  sudo chmod 0440 /etc/sudoers.d/emoncms-rebootbutton
  echo "emonPi emoncms admin reboot button sudoers updated"
fi

echo
