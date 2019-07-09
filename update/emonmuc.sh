#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Update EmonMUC"
echo "-------------------------------------------------------------"

if [ -d $emonmuc_dir ]; then
    bash $emonmuc_dir/update.sh
else
    echo "EmonMUC not found at "
fi
