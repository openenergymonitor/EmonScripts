#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Update Emoncms Core"
echo "-------------------------------------------------------------"

# Check emoncms directory
if [ ! -d $emoncms_www ]; then
    echo "emoncms directory at $emoncms_www not found"
    exit 0
fi

# Use update_component script to update emoncms core
./update_component.sh /var/www/emoncms

# This should be moved to an install/update script in the emoncms directory
echo "-------------------------------------------------------------"
echo "Update Emoncms Services"
echo "-------------------------------------------------------------"
for service in "emoncms_mqtt" "feedwriter" "service-runner"; do
    servicepath=$emoncms_www/scripts/services/$service/$service.service
    $emonscripts_dir/common/install_emoncms_service.sh $servicepath $service
done
echo

if [ -d /lib/systemd/system ]; then
  echo "Reloading systemctl deamon"
  sudo systemctl daemon-reload
fi

echo "Restarting Services..."

for service in "feedwriter" "emoncms_mqtt" "emonhub"; do
  if [ -f /lib/systemd/system/$service.service ]; then
    echo "- sudo systemctl restart $service.service"
    sudo systemctl restart $service.service
    state=$(systemctl show $service | grep ActiveState)
    echo "--- $state ---"
  fi
done

if [ "$emonSD_pi_env" = "1" ]; then  
  # Sudoers entry (review)
  sudo visudo -cf $emonscripts_dir/sudoers.d/emoncms-rebootbutton && \
  sudo cp $emonscripts_dir/sudoers.d/emoncms-rebootbutton /etc/sudoers.d/
  sudo chmod 0440 /etc/sudoers.d/emoncms-rebootbutton
  echo "emonPi emoncms admin reboot button sudoers updated"
fi

echo

echo "-------------------------------------------------------------"
echo "Update Emoncms Modules"
echo "-------------------------------------------------------------"

# Check emoncms directory
if [ ! -d $emoncms_www ]; then
    echo "emoncms directory at $emoncms_www not found"
    exit 0
fi

# Update modules installed directly in the Modules folder
for M in $emoncms_www/Modules/*; do
    ./update_component.sh $M
done

# Update modules installed in the $emoncms_dir/modules folder
for M in $emoncms_dir/modules/*; do
    ./update_component.sh $M
done

# This should be moved to wifi module install.sh
if [ -d $emoncms_www/Modules/wifi ]; then
    # wifi module sudoers entry
    sudo visudo -cf $emonscripts_dir/sudoers.d/wifi-sudoers && \
    sudo cp $emonscripts_dir/sudoers.d/wifi-sudoers /etc/sudoers.d/
    sudo chmod 0440 /etc/sudoers.d/wifi-sudoers
    echo "wifi sudoers entry updated"
fi
