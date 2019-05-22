#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "emonHub update"
echo "-------------------------------------------------------------"
cd $usrdir

if [ -d $usrdir/emonhub ]; then

    echo "git pull $usrdir/emonhub"
    cd $usrdir/emonhub
    git branch
    git status
    git pull
    
    if [ ! -d /var/log/emonhub ]; then
        sudo mkdir /var/log/emonhub
        sudo chown emonhub:emonhub /var/log/emonhub
    fi
    
    service="emonhub"
    servicepath="$usrdir/emonhub/service/emonhub.service"
    $usrdir/EmonScripts/common/install_emoncms_service.sh $servicepath $service

    # echo
    # echo "Running emonhub automatic node addition script"
    # $usrdir/emonhub/conf/nodes/emonpi_auto_add_nodes.sh $usrdir

else
    echo "EmonHub not found"
fi

