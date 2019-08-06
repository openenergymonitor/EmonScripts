#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Install EmonHub"
echo "-------------------------------------------------------------"
cd $openenergymonitor_dir

if [ ! -d $openenergymonitor_dir/emonhub ]; then
    git clone https://github.com/openenergymonitor/emonhub.git
else 
    echo "- emonhub repository already installed"
    git pull
fi

if [ -f $openenergymonitor_dir/emonhub/install.sh ]; then
    $openenergymonitor_dir/emonhub/install.sh $emonSD_pi_env
else
    echo "ERROR: $openenergymonitor_dir/emonhub/install.sh script does not exist"
fi

# Sudoers entry (review!)
sudo visudo -cf $openenergymonitor_dir/EmonScripts/sudoers.d/emonhub-sudoers && \
sudo cp $openenergymonitor_dir/EmonScripts/sudoers.d/emonhub-sudoers /etc/sudoers.d/
sudo chmod 0440 /etc/sudoers.d/emonhub-sudoers
echo "emonhub service control sudoers entry installed"
