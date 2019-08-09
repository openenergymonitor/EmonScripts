#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Install Emoncms Core"
echo "-------------------------------------------------------------"

# Give user ownership over /var/www/ folder
sudo chown $user /var/www

# Install emoncms core repository with git
if [ ! -d $emoncms_www ]; then
    cd /var/www && git clone -b $emoncms_core_branch https://github.com/emoncms/emoncms.git
    cd
else
    echo "- emoncms already installed"
fi

# Create emoncms logfolder
if [ ! -f $emoncms_log_location ]; then
    echo "- creating emoncms log folder"
    sudo mkdir $emoncms_log_location
    sudo chown pi $emoncms_log_location
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
else
    echo "- emoncms settings.php already exists"
fi

if [ ! -d $emoncms_datadir ]; then
    sudo mkdir $emoncms_datadir
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

# Create a symlink to reference emoncms within the web root folder (review):
if [ ! -d /var/www/html/emoncms ]; then
    echo "- symlinking emoncms folder to /var/www/html/emoncms"
    sudo ln -s $emoncms_www /var/www/html/emoncms
    
    # Redirect (review)
    echo "- creating redirect to $emoncms_www"
    echo "<?php header('Location: ../emoncms'); ?>" > $emoncms_dir/index.php
    sudo mv $emoncms_dir/index.php /var/www/html/index.php
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
