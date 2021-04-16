#!/bin/bash
source load_config.sh

switch_branch=$1

echo "-------------------------------------------------------------"
echo "Switch Emoncms Module branches"
echo "-------------------------------------------------------------"

# Check emoncms directory
if [ ! -d $emoncms_www ]; then
    echo "emoncms directory at $emoncms_www not found"
    exit 0
fi

# Emoncms core
M=/var/www/emoncms
git -C $M fetch --all --prune
git -C $M checkout $switch_branch
git -C $M pull 

# Update modules installed directly in the Modules folder
for M in $emoncms_www/Modules/*; do
  if [ -d "$M/.git" ]; then
    echo "------------------------------------------"
    echo "Updating $M module"
    echo "------------------------------------------"
    
    branch=$(git -C $M branch | grep \* | cut -d ' ' -f2)
    echo "- git branch: $branch"
    tags=$(git -C $M describe --tags)
    echo "- git tags: $tags"
    
    changes=$(git -C $M diff-index HEAD --)
    if [ "$changes" = "" ]; then
        echo "- no local changes"
        echo "- running: git fetch, checkout and pull"
        echo
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
  fi
done

# Update modules installed in the $emoncms_dir/modules folder
for M in $emoncms_dir/modules/*; do
  if [ -d "$M/.git" ]; then
    echo "------------------------------------------"
    echo "Updating $M module"
    echo "------------------------------------------"
    
    branch=$(git -C $M branch | grep \* | cut -d ' ' -f2)
    echo "- git branch: $branch"
    tags=$(git -C $M describe --tags)
    echo "- git tags: $tags"
    
    changes=$(git -C $M diff-index HEAD --)
    if [ "$changes" = "" ]; then
        echo "- no local changes"
        echo "- running: git fetch, checkout and pull"
        echo
        git -C $M fetch --all --prune
        git -C $M checkout $switch_branch
        git -C $M pull 
    else
        echo "- git status:"
        echo
        git -C $M status
        echo
    fi
    
    echo
  fi
done

echo "Update Emoncms database"
php $openenergymonitor_dir/EmonScripts/common/emoncmsdbupdate.php
