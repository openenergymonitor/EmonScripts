# Individual Install Scripts

All these links, link to the `stable` branch.

The installation process is broken out into separate scripts that can be run individually.

**[init.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/init.sh)** Launches the full installation script, first downloading the EmonScripts repository that contains the rest of the installation scripts.

**[main.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/main.sh)** Loads the configuration file and runs the individual installation scripts as applicable.

---

**[apache.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/apache.sh)** Apache configuration, mod rewrite and apache logging.

**[mysql.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/mysql.sh)** Removal of test databases, creation of emoncms database and emoncms mysql user.

**[php.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/php.sh)** PHP packages installation and configuration

**[redis.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/redis.sh)** Installs redis and configures the redis configuration file: turning off redis database persistance.

**[mosquitto.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/mosquitto.sh)** Installation and configuration of mosquitto MQTT server, used for emoncms MQTT interface with emonhub and smart control e.g: demandshaper module.

---

**[emoncms_core.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/emoncms_core.sh)** Installation of emoncms core, data directories and emoncms core services.

**[emoncms_modules.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/emoncms_modules.sh)** Installation of emoncms optional modules listed in config.ini e.g: Graphs, Dashboards, Apps & Backup

**[emonhub.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/emonhub.sh)** Emonhub is used in the OpenEnergyMonitor system to read data received over serial from either the EmonPi board or the RFM12/69Pi adapter board then forward the data to emonCMS in a decoded ready-to-use form

**[firmware.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/firmware.sh)** Requirements for firmware upload to directly connected emonPi hardware or rfm69pi adapter board.

**[emonpilcd.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/emonpilcd.sh)** Support for emonPi LCD.

**[wifiap.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/wifiap.sh)** RaspberryPi 3B+ WIFI Access Point support.

**[emonsd.sh:](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/emonsd.sh)** RaspberryPi specific configuration e.g: logging, default SSH password and hostname.
