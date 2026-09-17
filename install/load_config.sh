#!/bin/bash
# Updates run from service-runner with no controlling tty, so debconf cannot
# open its Dialog or Readline frontends and logs a fallback warning for every
# package configured. Noninteractive also guarantees nothing can ever stop and
# wait for an answer that no one is there to give.
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

# Do not change these lines, they are used to auto detect the installation location
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# usrdir=${DIR/\/EmonScripts\/install/}

if [ -f config.ini ]; then
    source config.ini
else
    echo "config.ini does not exist, please create from default e.g emonsd.config.ini"
    exit 0
fi
