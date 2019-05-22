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
    
    # ---------------------------------------------------------
    # Update service
    # ---------------------------------------------------------
    service=emonhub
    emonhub_src_path=$usrdir/emonhub/src
    emonhub_conf_path=$usrdir/data
    emonhub_logfile_path=/var/log/emonhub
    
    if [ ! -d /var/log/emonhub ]; then
        sudo mkdir $emonhub_logfile_path
        sudo chown emonhub $emonhub_logfile_path
    fi

    if [ -f /lib/systemd/system/$service.service ]; then
        echo "- reinstalling $service.service"
        sudo systemctl stop $service.service
        sudo systemctl disable $service.service
        sudo rm /lib/systemd/system/$service.service
    else
        echo "- installing $service.service"
    fi

    sudo cp $usrdir/emonhub/service/$service.service /lib/systemd/system
    # Set ExecStart path to point to installed script and config location
    sudo sed -i "s~ExecStart=.*~ExecStart=$emonhub_src_path/emonhub.py --config-file=$emonhub_conf_path/emonhub.conf --logfile=$emonhub_logfile_path/emonhub.log~" /lib/systemd/system/$service.service
    sudo systemctl enable $service.service
    sudo systemctl restart $service.service

    state=$(systemctl show $service | grep ActiveState)
    echo "- Service $state"
    # ---------------------------------------------------------
    
    # echo "Running emonhub automatic node addition script"
    # $usrdir/emonhub/conf/nodes/emonpi_auto_add_nodes.sh $usrdir

else
    echo "EmonHub not found"
fi

