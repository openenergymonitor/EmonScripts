#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "emonHub update"
echo "-------------------------------------------------------------"
cd $openenergymonitor_dir

if [ -d $openenergymonitor_dir/emonhub ]; then

    echo "git pull $openenergymonitor_dir/emonhub"
    cd $openenergymonitor_dir/emonhub
    
    # Get current branch
    branch=$(git rev-parse --abbrev-ref HEAD)
    # update the repository and switch to stable
    git fetch --all --prune -v
    git checkout origin/stable
    git pull origin stable
    
    # If this installation was on the old emon-pi branch
    # reinstall to switch to Python3

    if [ $branch == "emon-pi" ]; then
        sudo apt-get update
        ./install.sh $emonSD_pi_env
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

