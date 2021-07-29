#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Install EmonMUC"
echo "-------------------------------------------------------------"

emonmuc_dir="/opt/emonmuc"

if [ ! -d $emonmuc_dir ]; then emonmuc_dir=$openenergymonitor_dir/emonmuc; fi
if [ ! -d $emonmuc_dir ]; then
    sudo git clone -b $emonmuc_branch ${git_repo[emonmuc]} $emonmuc_dir
    sudo chown $user -R $emonmuc_dir
else
    echo "EmonMUC framework already installed"
    git -C $emonmuc_dir pull
fi
sudo cp -fp $emonscripts_dir/defaults/emonmuc/emoncms.conf /opt/openmuc/conf/emoncms.conf
sed -i "18s/.*user.*$/user = $mqtt_user/"                  /opt/openmuc/conf/emoncms.conf
sed -i "19s/.*password.*$/password = $mqtt_password/"      /opt/openmuc/conf/emoncms.conf
sed -i "30s/.*username.*$/username = $mysql_user/"         /opt/openmuc/conf/emoncms.conf
sed -i "31s/.*password.*$/password = $mysql_password/"     /opt/openmuc/conf/emoncms.conf

sudo bash $emonmuc_dir/setup.sh --emoncms $emoncms_www
