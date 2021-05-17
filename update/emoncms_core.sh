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

# -----------------------------------------------------------------
# Pulling in latest Emoncms changes
# -----------------------------------------------------------------
echo
echo "Checking status of $emoncms_www git repository"
cd $emoncms_www
branch=$(git branch | grep \* | cut -d ' ' -f2)
echo "- git branch: $branch"
changes=$(git diff-index --quiet HEAD --)
if $changes; then
    echo "- no local changes"
    echo "- running: git pull origin $branch"
    echo
    git fetch --all --prune
    git pull origin $branch
else
    echo "WARNING local changes Emoncms Core not updated"
    echo "- git status:"
    echo
    git status
    echo
fi

#########################################################################################

echo "Update Emoncms database"
php $openenergymonitor_dir/EmonScripts/common/emoncmsdbupdate.php
echo

echo "-------------------------------------------------------------"
echo "Update Emoncms Services"
echo "-------------------------------------------------------------"
for service in "emoncms_mqtt" "feedwriter" "service-runner"; do
    servicepath=$emoncms_www/scripts/services/$service/$service.service
    $openenergymonitor_dir/EmonScripts/common/install_emoncms_service.sh $servicepath $service
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

#########################################################################################

if [ "$emonSD_pi_env" = "1" ]; then  
  # Sudoers entry (review)
  sudo visudo -cf $openenergymonitor_dir/EmonScripts/sudoers.d/emoncms-rebootbutton && \
  sudo cp $openenergymonitor_dir/EmonScripts/sudoers.d/emoncms-rebootbutton /etc/sudoers.d/
  sudo chmod 0440 /etc/sudoers.d/emoncms-rebootbutton
  echo "emonPi emoncms admin reboot button sudoers updated"
fi

echo
