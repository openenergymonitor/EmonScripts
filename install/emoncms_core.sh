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

# Install emoncms core repository with git
if [ ! -d $emoncms_www ]; then
    sudo git clone -b $emoncms_core_branch ${git_repo[emoncms_core]} $emoncms_www
    sudo chown $user -R $emoncms_www
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

# Copy and install emonpi.settings.ini
if [ ! -f $emoncms_www/settings.ini ]; then
    echo "- installing default emoncms settings.ini"
    cp $emonscripts_dir/defaults/emoncms/emonpi.settings.ini $emoncms_www/settings.ini

    sed -i "s~OPENENERGYMONITOR_DIR~$openenergymonitor_dir~" $emoncms_www/settings.ini
    sed -i "s~EMONCMS_DATADIR~$emoncms_datadir~"             $emoncms_www/settings.ini
    sed -i "s~EMONCMS_DIR~$emoncms_dir~"                     $emoncms_www/settings.ini

    sed -i "s~MYSQL_DATABASE~$mysql_database~"               $emoncms_www/settings.ini
    sed -i "s~MYSQL_USERNAME~$mysql_user~"                   $emoncms_www/settings.ini
    sed -i "s~MYSQL_PASSWORD~$mysql_password~"               $emoncms_www/settings.ini

    sed -i "s~MQTT_USER~$mqtt_user~"                         $emoncms_www/settings.ini
    sed -i "s~MQTT_PASSWORD~$mqtt_password~"                 $emoncms_www/settings.ini
else
    echo "- emoncms settings.ini already exists"
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

if [ "$install_redis" = true ]; then
# Install actual services, enable and start
    for service in "feedwriter" "service-runner"; do
        servicepath=$emoncms_www/scripts/services/$service/$service.service
        echo "installing $service to $servicepath"
        $emonscripts_dir/common/install_emoncms_service.sh $servicepath $service
    done

    # Install service-runner drop-in if system user is different
    if [ "$user" != "pi" ]; then
        echo "installing service-runner drop-in User=$user"
        if [ ! -d /lib/systemd/system/service-runner.service.d ]; then
            sudo mkdir /lib/systemd/system/service-runner.service.d
        fi
        echo $'[Service]\nUser='$user > service-runner.conf
        sudo mv service-runner.conf /lib/systemd/system/service-runner.service.d/service-runner.conf

        echo "installing feedwriter drop-in User=$user"
        if [ ! -d /lib/systemd/system/feedwriter.service.d ]; then
            sudo mkdir /lib/systemd/system/feedwriter.service.d
        fi
        echo $'[Service]\nEnvironment="USER='$user'"' > feedwriter.conf
        sudo mv feedwriter.conf /lib/systemd/system/feedwriter.service.d/feedwriter.conf
    fi
    sudo systemctl daemon-reload
    sudo systemctl restart {feedwriter.service,service-runner.service}

    if [ "$install_mosquitto_client" = true ]; then
        servicepath=$emoncms_www/scripts/services/emoncms_mqtt/emoncms_mqtt.service
        echo "installing $service to $servicepath"
        $emonscripts_dir/common/install_emoncms_service.sh $servicepath emoncms_mqtt

        if [ "$user" != "pi" ]; then
            echo "installing emoncms_mqtt drop-in User=$user"
            if [ ! -d /lib/systemd/system/emoncms_mqtt.service.d ]; then
                sudo mkdir /lib/systemd/system/emoncms_mqtt.service.d
            fi
            echo $'[Service]\nEnvironment="USER='$user'"' > emoncms_mqtt.conf
            sudo mv emoncms_mqtt.conf /lib/systemd/system/emoncms_mqtt.service.d/emoncms_mqtt.conf
        fi
        sudo systemctl daemon-reload
        sudo systemctl restart emoncms_mqtt.service
    fi
fi

echo

if [ "$emonSD_pi_env" = "1" ]; then
    # Sudoers entry (review)
    sudo visudo -cf $emonscripts_dir/sudoers.d/emoncms-rebootbutton && \
    sudo cp $emonscripts_dir/sudoers.d/emoncms-rebootbutton /etc/sudoers.d/
    sudo chmod 0440 /etc/sudoers.d/emoncms-rebootbutton
    echo "emonPi emoncms admin reboot button sudoers updated"
fi

echo
