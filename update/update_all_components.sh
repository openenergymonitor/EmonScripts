#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
source load_config.sh

switch_branch=$1

# Check emoncms directory
if [ ! -d $emoncms_www ]; then
    echo "emoncms directory at $emoncms_www not found"
    exit 0
fi

# Emoncms core
./update_component.sh /var/www/emoncms $switch_branch

# Update emoncms modules /var/www/emoncms/Modules
for M in $emoncms_www/Modules/*; do
    ./update_component.sh $M $switch_branch
done

# Update emoncms modules /opt/emoncms/modules
for M in $emoncms_dir/modules/*; do
    ./update_component.sh $M $switch_branch
done

# Update components in /opt/openenergymonitor
for M in $openenergymonitor_dir/*; do
    ./update_component.sh $M $switch_branch
done

echo "- all components updated"
