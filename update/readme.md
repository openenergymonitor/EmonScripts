# How to run scripts manually

Current directory is EmonScripts/update

### Update Emoncms

    ./emoncms.sh

### Update EmonHub

    ./emonhub.sh

### Via main.sh

    ./main.sh UPDATE_TYPE FIRMWARE_KEY SERIAL_PORT
    ./main.sh all
    ./main.sh emoncms
    ./main.sh emonhub
    ./main.sh firmware emonPi_discrete_jeelib ttyAMA0

### Via service-runner-update.sh

This script is triggered from emoncms via service-runner. Arguments are the same as main.sh and default to `all emonPi_discrete_jeelib ttyAMA0`.

    ./service-runner-update.sh all

# How does the update process work in practice?

The update process is started from the admin module of emoncms.
It consists of 2 main steps, launched by two different shell scripts located in the `/opt/openenergymonitor/EmonScripts` folder:

1) [update/service-runner-update.sh](service-runner-update.sh)
2) [update/main.sh](main.sh)

## step 1 : update/service-runner-update.sh

- check the emonSD version file in `/boot` against the safe-update list on the master branch of the EmonScripts repository
- pull the latest version of the EmonScripts repository
- if the version check is successful, go to step 2

## step 2 : update/main.sh

- stop the emonPiLCD service (emonPi hardware)
- pull the emonpi, RFM2Pi, huawei-hilink-status and emonPiLCD repositories if present
- update emonhub (update/emonhub.sh), emoncms core and modules (update/emoncms.sh), and on emonSD the logrotate and LCD configuration (update/emonsd.sh)
- restart the emonPiLCD service and, last, service-runner
