#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Update Emoncms Modules"
echo "-------------------------------------------------------------"

# Check emoncms directory
if [ ! -d $emoncms_www ]; then
    echo "emoncms directory at $emoncms_www not found"
    exit 0
fi

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

# backup module
if [ -d $emoncms_dir/modules/backup ]; then
    cd $emoncms_dir/modules/backup
    if [ ! -f config.cfg ]; then
        cp default.config.cfg config.cfg
        sed -i "s~USER~$user~" config.cfg
        sed -i "s~BACKUP_SCRIPT_LOCATION~$emoncms_dir/modules/backup~" config.cfg
        sed -i "s~EMONCMS_LOCATION~$emoncms_www~" config.cfg
        sed -i "s~BACKUP_LOCATION~$openenergymonitor_dir/data~" config.cfg
        sed -i "s~DATABASE_PATH~$emoncms_datadir~" config.cfg
        sed -i "s~EMONHUB_CONFIG_PATH~/etc/emonhub~" config.cfg
        sed -i "s~EMONHUB_SPECIMEN_CONFIG~$openenergymonitor_dir/emonhub/conf~" config.cfg
        sed -i "s~BACKUP_SOURCE_PATH~$openenergymonitor_dir/data/uploads~" config.cfg
    fi
    cd
fi

echo "Update Emoncms database"
php $openenergymonitor_dir/EmonScripts/common/emoncmsdbupdate.php
