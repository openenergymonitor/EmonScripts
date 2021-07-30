#!/bin/bash
# Do not change these lines, they are used to auto detect the installation location
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# usrdir=${DIR/\/EmonScripts\/install/}

if [ -f ../install/config.ini ]; then
    source ../install/config.ini
else
    echo "config.ini does not exist, please create from default e.g emonsd.config.ini"
    exit 0
fi
if [ -z "$emonscripts_dir" ]; then
    emonscripts_dir="$(dirname $DIR)"
fi
