#!/bin/bash

# most of the following is here to remove the older ways the services have been installed 
# including init.d and direct installation in /etc/systemd/system and hard copies to /lib/systemd/system
# the intended correct installation is a symlink of the original service to /lib/systemd/system
# systemd itself then symlinks this service further to /etc/systemd/system as part of systemctl enable

servicepath=$1
service=$2

# check if systemd is available and service file exists
if [ -d /etc/systemd ] && [ -f $servicepath ]; then

  # Install the service in /lib/systemd/system by symlinking from original location (e.g /var/www/emoncms/scripts..)
  if [ ! -f /lib/systemd/system/$service.service ]; then
    echo "Installing $service.service in /lib/systemd/system (creating symlink)"
    sudo ln -s $servicepath /lib/systemd/system
    sudo systemctl enable $service.service
    sudo systemctl start $service.service
  else 
    echo "$service.service already installed"
  fi
fi
