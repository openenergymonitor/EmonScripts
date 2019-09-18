#!/bin/bash
source load_config.sh

# --------------------------------------------------------------------------------
# Install custom logrotate
# --------------------------------------------------------------------------------
sudo ln -sf $openenergymonitor_dir/EmonScripts/defaults/etc/logrotate.d/emoncms-non-emonsd /etc/logrotate.d/emoncms
sudo chown root /etc/logrotate.d/emoncms
