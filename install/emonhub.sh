#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "emonHub install"
echo "-------------------------------------------------------------"
cd $openenergymonitor_dir

if [ ! -d $openenergymonitor_dir/emonhub ]; then
    git clone -b $emonhub_branch ${git_repo[emonhub]}
else 
    echo "-- emonhub repository already installed"
    echo "-- emonhub running git pull:"
    git -C $openenergymonitor_dir/emonhub pull
fi

# emonhub's install.sh installs the emonPi2 default emonhub.conf if there is
# none. For other hardware put that hardware's default in place first, set up
# the same way install.sh sets up its own default.
emonhub_default_conf=$openenergymonitor_dir/emonhub/conf/${emonsd_hardware:-emonpi2}.default.emonhub.conf
if [ "${emonsd_hardware:-emonpi2}" != "emonpi2" ] && [ ! -f /etc/emonhub/emonhub.conf ]; then
    if [ -f "$emonhub_default_conf" ]; then
        echo "-- installing $(basename $emonhub_default_conf) as /etc/emonhub/emonhub.conf"
        sudo mkdir -p /etc/emonhub
        sudo cp "$emonhub_default_conf" /etc/emonhub/emonhub.conf
        sudo chmod 666 /etc/emonhub/emonhub.conf
        sudo sed -i "s/loglevel = DEBUG/loglevel = WARNING/" /etc/emonhub/emonhub.conf
    else
        echo "-- ERROR: $emonhub_default_conf not found, emonhub will install the emonPi2 default"
    fi
fi

if [ -f $openenergymonitor_dir/emonhub/install.sh ]; then
    # emonhub's install.sh takes the openenergymonitor directory (it reads
    # emonSD_pi_env from EmonScripts' config itself) and the user, the same
    # arguments update/update_component.sh passes
    $openenergymonitor_dir/emonhub/install.sh $openenergymonitor_dir $user
else
    echo "-- ERROR: $openenergymonitor_dir/emonhub/install.sh script does not exist"
fi

# Sudoers entry (review!)
sudo visudo -cf $openenergymonitor_dir/EmonScripts/sudoers.d/emonhub-sudoers && \
sudo cp $openenergymonitor_dir/EmonScripts/sudoers.d/emonhub-sudoers /etc/sudoers.d/
sudo chmod 0440 /etc/sudoers.d/emonhub-sudoers
echo "-- emonhub service control sudoers entry installed"
