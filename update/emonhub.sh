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
        echo "Migrating from emon-pi branch to stable branch"
        echo
        echo "git fetch --all --prune -v"
        git fetch --all --prune -v
        echo "git checkout stable"
        git checkout stable
        echo "git pull origin stable"
        git pull origin stable
        echo
        echo "running emonhub install script emonSD_pi_env:$emonSD_pi_env"
        ./install.sh $emonSD_pi_env
    else
        echo "git fetch --all --prune -v"
        git fetch --all --prune -v
        echo "git status"
        git status
        echo "git pull origin $branch"
        git pull origin $branch
        # Temporary addition of paho-mqtt & requests here
        # remove once issue has cleared:
        # https://community.openenergymonitor.org/t/emonpi-new-sd-image-emonhub-failing/14578
        sudo apt update
        sudo apt-get install -y python3-serial python3-configobj python3-pip
        sudo pip3 install paho-mqtt requests
    fi 
    
    # can be used to change service source location in future
    # sudo ln -sf $openenergymonitor_dir/emonhub/service/emonhub.service /lib/systemd/system
    
    sudo systemctl restart emonhub.service
    state=$(systemctl show emonhub | grep ActiveState)
    echo "- Service $state"
    # ---------------------------------------------------------
    
    echo "Running emonhub automatic node addition script"
    $openenergymonitor_dir/emonhub/conf/nodes/emonpi_auto_add_nodes.sh $openenergymonitor_dir

else
    echo "EmonHub not found"
fi

