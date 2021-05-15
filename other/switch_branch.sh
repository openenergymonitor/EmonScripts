#!/bin/bash
openenergymonitor_dir="/opt/openenergymonitor"

M=$1
switch_branch=$2

if [ -d "$M/.git" ]; then
    branch=$(git -C $M branch | grep \* | cut -d ' ' -f2)
    echo "Current git branch: $branch"
    
    changes=$(git -C $M diff-index HEAD --)
    if [ "$changes" = "" ]; then
        echo "No local changes"
        echo "Running git fetch, checkout and pull"
        echo "------------------------------------"
        git -C $M fetch --all --prune
        git -C $M checkout $switch_branch
        git -C $M pull 
    else
        echo "WARNING local changes in $M - Module not updated"
        echo "- git status:"
        echo
        git -C $M status
        echo
    fi
    
    echo
else
    echo "ERROR: not a git repository"
fi

echo "------------------------------------"
echo "Update Emoncms database"
php $openenergymonitor_dir/EmonScripts/common/emoncmsdbupdate.php
