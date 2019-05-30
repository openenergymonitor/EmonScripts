#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "emonHub install"
echo "-------------------------------------------------------------"
cd $usrdir

if [ ! -d $usrdir/emonhub ]; then
    git clone https://github.com/openenergymonitor/emonhub.git
    cd emonhub
    git checkout env_example
    sudo cp $usrdir/EmonScripts/defaults/emonhub.env /etc/emonhub.env
    cd $usrdir
else 
    echo "- emonhub repository already installed"
    git pull
fi

if [ -f $usrdir/emonhub/install.sh ]; then
    $usrdir/emonhub/install.sh $emonSD_pi_env
else
    echo "ERROR: $usrdir/emonhub/install.sh script does not exist"
fi

# Sudoers entry (review!)
sudo visudo -cf $usrdir/EmonScripts/sudoers.d/emonhub-sudoers && \
sudo cp $usrdir/EmonScripts/sudoers.d/emonhub-sudoers /etc/sudoers.d/
sudo chmod 0440 /etc/sudoers.d/emonhub-sudoers
echo "emonhub service control sudoers entry installed"
