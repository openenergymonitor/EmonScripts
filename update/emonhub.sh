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
    
    # can be used to change service source location in future
    # sudo ln -sf $usrdir/emonhub/service/emonhub.service /lib/systemd/system
    
    sudo systemctl restart $service.service
    state=$(systemctl show $service | grep ActiveState)
    echo "- Service $state"
    # ---------------------------------------------------------
    
    # echo "Running emonhub automatic node addition script"
    # $usrdir/emonhub/conf/nodes/emonpi_auto_add_nodes.sh $usrdir

else
    echo "EmonHub not found"
fi

