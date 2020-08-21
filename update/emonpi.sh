#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "EmonPi Firmware Update (Discrete Sampling)"
echo "-------------------------------------------------------------"

sudo systemctl stop emonhub
echo "Start ATmega328 serial upload using avrdude with latest.hex"

firmware_log=/var/log/emoncms/firmware.log
#sudo touch $firmware_log
sudo chmod 666 $firmware_log

for attempt in {1..3}
do
    echo "Attempt: "$attempt
    echo "avrdude -c arduino -p ATMEGA328P -P /dev/ttyAMA0 -b 115200 -U flash:w:$openenergymonitor_dir/emonpi/firmware/compiled/latest.hex"
    echo "Note: progress written to logfile $firmware_log"
    echo
    
    avrdude -c arduino -p ATMEGA328P -P /dev/ttyAMA0 -b 115200 -U flash:w:$openenergymonitor_dir/emonpi/firmware/compiled/latest.hex -l $firmware_log
    
    echo
    not_in_sync=$(cat $firmware_log | grep "not in sync" | wc -l)
    flash_verified=$(cat $firmware_log | grep "flash verified" | wc -l)
    
    if [ "$not_in_sync" == "0" ]; then
        if [ $flash_verified == "1" ]; then
            cat $firmware_log
            echo "SUCCESS: flash verifed"
            break;
        fi
    else
        echo "ERROR: Not in sync" 
    fi
done

echo

sudo systemctl start emonhub

echo "waiting for emonpi to stop controlling LCD"
sleep 3
