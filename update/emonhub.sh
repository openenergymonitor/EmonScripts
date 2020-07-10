#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Update EmonHub"
echo "-------------------------------------------------------------"
cd $openenergymonitor_dir

if [ -d $openenergymonitor_dir/emonhub ]; then

    cd $openenergymonitor_dir/emonhub
    branch=$(git rev-parse --abbrev-ref HEAD)

    echo "git fetch --all --prune -v"
    git fetch --all --prune -v
    echo "git status"
    git status
        
    if [ $branch == "emon-pi" ]; then
        # Switch to stable
        branch="stable"
        echo "Migrating from emon-pi branch to $branch branch"
        echo "git checkout $branch"
        git checkout $branch
        echo
    fi
    
    echo "git pull origin $branch"
    git pull origin $branch
    echo
    
    # Run install script again to update
    # script handles restart of emonhub service
    echo "Running emonhub install & update script emonSD_pi_env:$emonSD_pi_env"
    echo "--------------------------------------------------------------------"
    ./install.sh $emonSD_pi_env
    echo "--------------------------------------------------------------------"
    
    echo "Running emonhub automatic node addition script"
    $openenergymonitor_dir/emonhub/conf/nodes/emonpi_auto_add_nodes.sh $openenergymonitor_dir

else
    echo "Not found at $openenergymonitor_dir/emonhub"
fi
