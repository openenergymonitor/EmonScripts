#!/bin/bash

# most of the following is here to remove the older ways the services have been installed 
# including init.d and direct installation in /etc/systemd/system and hard copies to /lib/systemd/system
# the intended correct installation is a symlink of the original service to /lib/systemd/system
# systemd itself then symlinks this service further to /etc/systemd/system as part of systemctl enable

servicepath=$1
service=$2

# check if systemd is available and service file exists
if [ -d /etc/systemd ] && [ -f $servicepath ]; then

  # The following checks are not needed on systems built from scratch using latest build script
  # commented for reference for now

  # 1. if the service file exists as an init.d script remove it 
  # as this script replaces init.d services with systemd services
  # if [ -f /etc/init.d/$service ]; then
  #   echo "removing initd $service service"
  #   sudo /etc/init.d/$service stop
  #   sudo rm /etc/init.d/$service
  # fi
  
  # 2. Remove original copied service file from /etc/systemd/system
  # we are installing the service in part 3 in /lib/systemd/system
  # it then gets symlinked back to /etc/systemd/system by "systemctl enable"
  # if [ -f /etc/systemd/system/$service.service ]; then
  #   if ! [ -L /etc/systemd/system/$service.service ]; then
  #     echo "Removing hard copy of $service.service from /etc/systemd/system (should be symlink)"
  #     sudo systemctl stop $service.service
  #     sudo systemctl disable $service.service
  #     sudo rm /etc/systemd/system/$service.service
  #     sudo systemctl daemon-reload
  #   fi
  # fi
  
  # 3. Remove systemd service from /lib/systemd/system if a hard copy has been made
  # we are installing a symlink of the service file in /lib/systemd/system (pointing to original git repo)
  # if [ -f /lib/systemd/system/$service.service ]; then
  #   if ! [ -L /lib/systemd/system/$service.service ]; then
  #     echo "Removing hard copy of $service.service in /lib/systemd/system (should be symlink)"
  #     sudo systemctl stop $service.service
  #     sudo systemctl disable $service.service
  #     sudo rm /lib/systemd/system/$service.service
  #     sudo systemctl daemon-reload
  #   fi
  # fi
  
  # 4. Finally install the service in /lib/systemd/system by symlinking from original location (e.g /var/www/emoncms/scripts..)
  if [ ! -f /lib/systemd/system/$service.service ]; then
    echo "Installing $service.service in /lib/systemd/system (creating symlink)"
    sudo ln -s $servicepath /lib/systemd/system
    sudo systemctl enable $service.service
    sudo systemctl start $service.service
  else 
    echo "$service.service already installed"
  fi
fi
