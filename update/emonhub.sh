#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "emonHub update"
echo "-------------------------------------------------------------"
cd $openenergymonitor_dir

if [ -d $openenergymonitor_dir/emonhub ]; then

    echo "git pull $openenergymonitor_dir/emonhub"
    cd $openenergymonitor_dir/emonhub
    
    branch=$(git rev-parse --abbrev-ref HEAD)
    if [ $branch == "emon-pi" ]; then
        git fetch origin
        git checkout stable
        sudo apt-get update
        ./install.sh $emonSD_pi_env
    else
        git branch
        git status
        git pull
    fi 
    
    # can be used to change service source location in future
    # sudo ln -sf $openenergymonitor_dir/emonhub/service/emonhub.service /lib/systemd/system
    
    sudo systemctl restart $service.service
    state=$(systemctl show $service | grep ActiveState)
    echo "- Service $state"
    # ---------------------------------------------------------
    
    echo "Running emonhub automatic node addition script"
    $openenergymonitor_dir/emonhub/conf/nodes/emonpi_auto_add_nodes.sh $openenergymonitor_dir

else
    echo "EmonHub not found"
fi

