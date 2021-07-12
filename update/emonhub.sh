#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Update EmonHub"
echo "-------------------------------------------------------------"

M=$openenergymonitor_dir/emonhub

if [ -d "$M/.git" ]; then
    # emon-pi to stable migration
    branch=$(git -C $M branch | grep \* | cut -d ' ' -f2)
    if [ $branch == "emon-pi" ]; then
        branch="stable"
        echo "Migrating from emon-pi branch to $branch branch"
    fi
    
    ./update_component.sh $M $branch
else
    echo "Not found at $openenergymonitor_dir/emonhub"
fi
