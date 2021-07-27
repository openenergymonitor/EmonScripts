#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
source load_config.sh

M=$1
switch_branch=$2

if [ -d "$M/.git" ]; then
    echo "Updating $M"
    
    branch=$(git -C $M branch | grep \* | cut -d ' ' -f2)
    echo "- current branch: $branch"
    #tags=$(git -C $M describe --tags)
    #echo "- git tags: $tags"
    
    if [ ! $switch_branch ]; then
        switch_branch=$branch
    fi
    
    changes=$(git -C $M diff-index -G. HEAD --)
    if [ "$changes" = "" ]; then
        echo "- local changes: no"
        result=$(git -C $M fetch --all --prune)
        echo "- git fetch: $result"
        result=$(git -C $M checkout $switch_branch)
        echo "- git checkout: $result"
        result=$(git -C $M pull)
        echo "- git pull: $result"
        
        # update mysql database    
        result=$(php $openenergymonitor_dir/EmonScripts/common/emoncmsdbupdate.php)
        if [ ! $result = "[]" ]; then 
            echo "- database update: $result"
        else 
            echo "- database update: no changes"
        fi
        
        # run module install (& update) script if present
        if [ -f $M/install.sh ]; then
            echo "- running module install/update script"
            $M/install.sh $openenergymonitor_dir
        fi
        
        echo "- component updated" 
    else
        echo "WARNING local changes in $M - Module not updated"
        result=$(git -C $M status)
        echo "- git status: $result"
    fi
    # else
    # echo "ERROR: not a git repository"
fi
