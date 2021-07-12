#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
source ../install/config.ini

mode=$1

for dir in "$emoncms_www" "$emoncms_www/Modules/*" "$emoncms_dir/modules/*" "$openenergymonitor_dir/*"; do
    for M in $dir; do
        if [ -d "$M/.git" ]; then
            url=$(git -C $M remote get-url origin)
            
            # 1. switch https:// to ssh
            if [ "$mode" = "ssh" ]; then
                ssh_url="${url/https:\/\/github.com\//git@github.com:}"
                git -C $M remote set-url origin $ssh_url
                echo $ssh_url
            fi

            # 2. switch https:// to ssh            
            if [ "$mode" = "https" ]; then
                https_url="${url/git@github.com:/https:\/\/github.com\/}"
                git -C $M remote set-url origin $https_url
                echo $https_url
            fi
        fi
    done
done


