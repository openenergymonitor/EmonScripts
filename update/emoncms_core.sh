#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Update Emoncms Core"
echo "-------------------------------------------------------------"

# Check emoncms directory
if [ ! -d $emoncms_www ]; then
    echo "emoncms directory at $emoncms_www not found"
    exit 0
fi

# -----------------------------------------------------------------
# Record current state of emoncms settings.php
# This needs to be run prior to emoncms git pull
# -----------------------------------------------------------------
cd
echo
current_settings_md5="$($openenergymonitor_dir/EmonScripts/common/./md5sum.py $emoncms_www/settings.php)"
echo "current settings.php md5: $current_settings_md5"

current_default_settings_md5="$($openenergymonitor_dir/EmonScripts/common/md5sum.py $emoncms_www/default.emonpi.settings.php)"
echo "Default settings.php md5: $current_default_settings_md5"

if [ "$current_default_settings_md5" == "$current_settings_md5" ]; then
  echo "settings.php has NOT been user modifed"
  settings_unmodified=true
else
  echo "settings.php HAS been user modified"
  settings_unmodified=false
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
    git pull origin $branch
else
    echo "- changes"
fi

# -----------------------------------------------------------------
# check to see if user has modifed settings.php and if update is need. Auto apply of possible
# -----------------------------------------------------------------
echo
new_default_settings_md5="$($openenergymonitor_dir/EmonScripts/common/md5sum.py $emoncms_www/default.emonpi.settings.php)"
echo "NEW default settings.php md5: $new_default_settings_md5"

# check to see if there is an update waiting for settings.php
if [ "$new_default_settings_md5" != "$current_default_settings_md5" ]; then
  echo "Update required to settings.php..."
  if [ $settings_unmodified == true ]; then
    sudo cp $emoncms_www/default.emonpi.settings.php $emoncms_www/settings.php
    echo "settings.php autoupdated"
  else
    echo "**ERROR: unable to autoupdate settings.php since user changes are present, manual review required**"
  fi
else
  echo "settings.php not updated"
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
  # Sudoers installation (provides sudo access to specific commands from emoncms)
  for sudoersfile in "emoncms-rebootbutton"; do
      if [ ! -f /etc/sudoers.d/$sudoersfile ]; then
          sudo visudo -cf $openenergymonitor_dir/EmonScripts/sudoers.d/$sudoersfile && \
          sudo cp $openenergymonitor_dir/EmonScripts/sudoers.d/$sudoersfile /etc/sudoers.d/
          sudo chmod 0440 /etc/sudoers.d/$sudoersfile
          echo
          echo "$sudoersfile sudoers entry installed"
      fi
  done
fi

echo
