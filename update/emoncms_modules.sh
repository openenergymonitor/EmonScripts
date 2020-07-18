#!/bin/bash
source load_config.sh

# Check emoncms directory
if [ ! -d $emoncms_www ]; then
    echo "Not found at $emoncms_www"
    exit 0
fi

# Update modules installed directly in the Modules folder
for M in $emoncms_www/Modules/*; do
  if [ -d "$M/.git" ]; then
    echo "------------------------------------------"
    echo "Update Emoncms Module $M"
    echo "------------------------------------------"
    
    branch=$(git -C $M branch | grep \* | cut -d ' ' -f2)
    echo "- git branch: $branch"
    tags=$(git -C $M describe --tags)
    echo "- git tags: $tags"
    
    changes=$(git -C $M diff-index HEAD --)
    if [ "$changes" = "" ]; then
        echo "- no local changes"
        echo "- running: git pull origin $branch"
        echo
        git -C $M fetch --all --prune
        git -C $M checkout $branch
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

if [ -d $emoncms_www/Modules/wifi ]; then
    # wifi module sudoers entry
    sudo visudo -cf $openenergymonitor_dir/EmonScripts/sudoers.d/wifi-sudoers && \
    sudo cp $openenergymonitor_dir/EmonScripts/sudoers.d/wifi-sudoers /etc/sudoers.d/
    sudo chmod 0440 /etc/sudoers.d/wifi-sudoers
    echo "wifi sudoers entry updated"
fi

# Update modules installed in the $emoncms_dir/modules folder
for M in $emoncms_dir/modules/*; do
  if [ -d "$M/.git" ]; then
    echo "------------------------------------------"
    echo "Update Emoncms Module $M"
    echo "------------------------------------------"
    
    branch=$(git -C $M branch | grep \* | cut -d ' ' -f2)
    echo "- git branch: $branch"
    tags=$(git -C $M describe --tags)
    echo "- git tags: $tags"
    
    changes=$(git -C $M diff-index HEAD --)
    if [ "$changes" = "" ]; then
        echo "- no local changes"
        echo "- running: git pull origin $branch"
        echo
        git -C $M pull 
        git -C $M checkout $branch
    else
        echo "- git status:"
        echo
        git -C $M status
        echo
    fi
    
    echo
  fi
done

# run module install (& update) script if present
module=backup
if [ -f $emoncms_dir/modules/$module/install.sh ]; then
    $emoncms_dir/modules/$module/install.sh $openenergymonitor_dir
    echo
fi

echo "------------------------------------------"
echo "Update Emoncms Database"
echo "------------------------------------------"

php $openenergymonitor_dir/EmonScripts/common/emoncmsdbupdate.php
