# emonSD image build script

The following build script is currently development in progress. It is already more comprehensive than the altenative debian install guides. To see what is installed open each script as listed below.

**Todo**

- Fix/test Wifi AP Support, results inconsistent so far
- SSL https://community.openenergymonitor.org/t/emonsd-next-steps-filesystem-logrotate/10693/188
- Review .env configuration 
- Review logrotate configuration
- Review disk wear results from 1st release, investigate ext filesystem commit interval vs app level buffering
- Review service install path: /lib/systemd/system or /etc/systemd/system

[Forum: EmonSD build script progress update and alpha release](https://community.openenergymonitor.org/t/emonsd-build-script-progress-update-and-alpha-release/11222)

The following build script can be used to build a fully fledged emoncms installation on debian operating systems, including: installation of LAMP server and related packages, redis, mqtt, emoncms core, emoncms modules, emonhub and if applicable: raspberrypi support for serial port and wifi access point.

Tested on: 

- [Raspbian Stretch Lite](https://www.raspberrypi.org/downloads/raspbian/), Version: November 2018, Release date: 2018-11-13

**Before starting it is recommended to create an ext2 partition for emoncms data, see below.**

Run default install:

    wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/master/install/init.sh
    chmod +x init.sh
    ./init.sh
    
### Configure install

The default configuration is for the RaspberryPi platform and Raspbian Stretch image specifically. To run the installation on a different distribution, you may need to change the configuration to reflect the target environment.

See explanation and settings in installation configuration file here: [config.ini](https://github.com/openenergymonitor/EmonScripts/blob/master/install/config.ini)

### Running scripts individually

The installation process is broken out into seperate scripts that can be run individually.

---

**[init.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/init.sh)** Launches the full installation script, first downloading the EmonScripts repository that contains the rest of the installation scripts.

**[main.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/main.sh)** Loads the configuration file and runs the individual installation scripts as applicable.

---

**[apache.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/apache.sh)** Apache configuration, mod rewrite and apache logging.

**[mysql.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/mysql.sh)** Removal of test databases, creation of emoncms database and emoncms mysql user.

**[php.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/php.sh)** PHP packages installation and configuration

**[redis.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/redis.sh)** Installs redis and configures the redis configuration file: turning off redis database persistance.

**[mosquitto.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/mosquitto.sh)** Installation and configuration of mosquitto MQTT server, used for emoncms MQTT interface with emonhub and smart control e.g: demandshaper module.

---

**[emoncms_core.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/emoncms_core.sh)** Installation of emoncms core, data directories and emoncms core services.

**[emoncms_modules.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/emoncms_modules.sh)** Installation of emoncms optional modules listed in config.ini e.g: Graphs, Dashboards, Apps & Backup

**[emonhub.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/emonhub.sh)** Emonhub is used in the OpenEnergyMonitor system to read data received over serial from either the EmonPi board or the RFM12/69Pi adapter board then forward the data to emonCMS in a decoded ready-to-use form

**[firmware.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/firmware.sh)** Requirements for firmware upload to directly connected emonPi hardware or rfm69pi adapter board.

**[emonpilcd.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/emonpilcd.sh)** Support for emonPi LCD.

**[wifiap.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/wifiap.sh)** RaspberryPi 3B+ WIFI Access Point support.

**[emonsd.sh:](https://github.com/openenergymonitor/EmonScripts/blob/master/install/emonsd.sh)** RaspberryPi specific configuration e.g: logging, default SSH password and hostname.

### Setup ext2 data partition

Use a partition editor to resize the raspbian stretch OS partition, select 3-4GB for the OS partition and expand the new partition to the remaining space.

Steps for creating 3rd partition for data using fdisk and mkfs:

    sudo fdisk -l
    Note end of last partition (5785599 on standard sd card)
    sudo fdisk /dev/mmcblk0
    enter: n->p->3
    enter: 5785600
    enter: default or 7626751
    enter: w (write partition to disk)
    fails with error, will write at reboot
    sudo reboot

On reboot, login and run:

    sudo mkfs.ext2 -b 1024 /dev/mmcblk0p3

*Note: We create here an ext2 filesystem with a blocksize of 1024 bytes instead of the default 4096 bytes. A lower block size results in significant write load reduction when using an application like emoncms that only makes small but frequent and across many files updates to disk. Ext2 is choosen because it supports multiple linux user ownership options which are needed for the mysql data folder. Ext2 is non-journaling which reduces the write load a little although it may make data recovery harder vs Ext4, The data disk size is small however and the downtime from running fsck is perhaps less critical.*

Create a directory that will be a mount point for the rw data partition

    sudo mkdir /var/opt/emoncms
    sudo chwon www-data /var/opt/emoncms

Use modified fstab

    wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/master/defaults/etc/fstab
    sudo cp fstab /etc/fstab
    sudo reboot

