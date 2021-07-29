#!/bin/bash
source load_config.sh

# --------------------------------------------------------------------------------
# Install custom logrotate
# --------------------------------------------------------------------------------
sudo ln -sf $emonscripts_dir/defaults/etc/logrotate.d/emoncms-non-emonsd /etc/logrotate.d/emoncms
sudo chmod 644 $emonscripts_dir/defaults/etc/logrotate.d/emoncms-non-emonsd
sudo chown root /etc/logrotate.d/emoncms
