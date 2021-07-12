# How to run scripts manually

Current directory is EmonScripts/update

### Update Emoncms

    ./emoncms.sh IS_EMONSD
    ./emoncms.sh 0
    
### Update EmonHub

    ./emonhub.sh
    
### Update Firmware: EmonPi

    ./emonpi.sh
    
### Update Firmware: rfm69pi

    ./rfm69pi.sh
    
### Via main.sh

    ./main.sh UPDATE_TYPE FIRMWARE IMAGE_NAME
    ./main.sh all emonpi emonSD-30Oct18
    ./main.sh emoncms emonSD-30Oct18
    ./main.sh emonhub emonSD-30Oct18
    ./main.sh firmware emonpi emonSD-30Oct18
    
### Via service-runner-update.sh

Current directory is EmonScripts.

This script is triggered from emoncms via service-runner.

    ./service-runner-update.sh UPDATE_TYPE FIRMWARE
    ./service-runner-update.sh all emonpi

# How do the automatic update process work in practise ? 

The automatic update process is managed from the admin module of emoncms. 
It consists of 2 main steps, launched by two different shell scripts located in the `/opt/openenergymonitor/EmonScripts` folder :

1) [update/service-runner-update.sh](service-runner-update.sh)
2) [update/main.sh](main.sh)

## step 1 : update/service-runner-update.sh

- version check and comparison to labels stored in the safe-update file of the EmonScripts repository
- pull the latest version of the EmonScripts repository
- if version check is successful, goto step 2

## step 2 : update/main.sh

### emonPiLCD & al example

- stop the emonPiLCD service
- launch lcd/emonPiLCD_update.py from the emonpi repo (to display the "UPDATING..." message on the LCD)
- pull the emonpi repo
- run the update/emonpi.sh script of the EmonScripts repo, which runs the lcd/install.sh from the emonpi repo
