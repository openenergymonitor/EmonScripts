#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Update EmonMUC"
echo "-------------------------------------------------------------"

emonmuc_dir="/opt/emonmuc"

if [ ! -d $emonmuc_dir ]; then emonmuc_dir=$openenergymonitor_dir/emonmuc; fi
if [ ! -d $emonmuc_dir ]; then
    sudo bash $emonmuc_dir/update.sh
else
    echo "Not found at $openenergymonitor_dir/emonmuc"
fi
