#!/bin/bash
# Do not change these lines, they are used to auto detect the installation location
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# usrdir=${DIR/\/EmonScripts\/install/}

if [ -f config.ini ]; then
    source config.ini
else
    echo "config.ini does not exist, please create from default e.g emonsd.config.ini"
    exit 0
fi
