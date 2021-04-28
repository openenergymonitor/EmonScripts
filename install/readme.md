# EmonCMS Install Scripts

## Introduction

This build script can be used to build a fully fledged emonCMS installation on debian based operating systems, including: installation of LAMP server and related packages, redis, MQTT, emonCMS core, emonCMS modules, and if applicable, emonhub & RaspberryPi support for serial port, and WiFi access point.

The script is a series of scripts that install each required component. To see what is installed and how open each script.

**New image released July20<br>[https://community.openenergymonitor.org/t/emonsd-24jul20-release/15170](https://community.openenergymonitor.org/t/emonsd-24jul20-release/15170)**

As of July 2020 - Tested on:

- Raspberry Pi OS (32-bit) Lite 2020-05-27
- Ubuntu 20.04 LTS

It is **strongly recommended** that you dedicate a single device (NUC/VM/Pi) to emoncms. Using it alongside other software can prove problematic.

[**Forum:** EmonSD build script progress update and beta release](https://community.openenergymonitor.org/t/emonsd-build-script-progress-update-and-beta-release/11222)

## Pre-built Image

Download (1.4 GB)

- [UK Server](https://openenergymonitor.org/files/emonSD-24Jul20.img.zip)

```
(.img) MD5: 1db713787a1f3469fc3a1027767fd607
(.zip) MD5: a160f746595872d30b735ab17e8a0b1c
```
- Minimum 16Gb SD Card
- Built using EmonScripts emonCMS installation script, see
- Based on Raspberry Pi OS (32-bit) Lite 2020-05-27
- Compatible with Raspberry Pi 3, 3B+ & 4
- EmonCMS data is logged to low-write ext2 partition mounted in `/var/opt/emoncms`
- Log partition `/var/log` mounted as tmpfs using log2ram, now presistant after reboot
- [SSH access disabled by default](https://community.openenergymonitor.org/t/emonpi-ssh-disabled-by-default/8847), long press emonPi LCD push button for 5s to enable. Or create file `/boot/ssh` in FAT partition.

## Building Your Own - Base OS Preparation

### RaspberryPi

To install on a RaspberryPi, a number of tasks are required. Please follow [these instructions first](https://github.com/openenergymonitor/EmonScripts/blob/master/install/rpi-install.md).

### Ubuntu

For Ubuntu, post base OS install, run this command so the user does not need a password for `sudo`.

```shell
sudo echo $USER' ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/$USER && sudo chmod 0440 /etc/sudoers.d/$USER
```

### Digital Ocean Droplet

For installation on a Digital Ocean Droplet, follow [these instructions](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/digital-ocean-install.md).

## Install the EmonCMS Installation Scripts

Pull the script from GitHub (note if you wish to pull the script from `master` change the path).

```shell
wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/install/init.sh
chmod +x init.sh && ./init.sh
```

The `init` script automatically calls the `main` script. At this point you will be offered the option to configure the installation process.

If you are on a RaspberryPi or EmonPi you can usually just proceed.

Be patient, the install process takes some time.

## Configure install

The default configuration is specifically for the RaspberryPi platform and Raspbian Buster image. To run the installation on a different distribution, you may need to change the configuration to reflect the target environment, e.g. set `emonSD_pi_env=0`

To edit the configuration (standard file paths):

```shell
cd /opt/openenergymonitor/EmonScripts/install/
nano config.ini
```

To restart the installation:

```shell
./main.sh
```

See explanation and settings in the installation configuration file here: [config.ini](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/emonsd.config.ini)

## Run Scripts Individually

It is possible to run the [scripts individually](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/install-scripts.md) for a single part of the stack. These are not guaranteed to be a complete solution (some folders may not be created for instance).

## Post Install - Settings

If you have used EmonCMS before, you may need to edit the settings to suit your local setup. This is now an `ini` file called `settings.ini` in `/var/www/emoncms/`.

## Post Install - First Use

To access EmonCMS go to the IP of your machine, in your browser.  This [Guide](https://guide.openenergymonitor.org/setup/connect/) will help you set your system up.

At the initial user screen, you need to select **Register** and create a user - this will be the admin user.

If you are migrating from an old system, export your data from the old system and import the data to the new system (after registering a user). This will require you to login as the original user.

## Standard Setup Filepaths

| Role       | Location     |
| :------------- | :----------- |
| Install location for code from OpenEnergyMonitor GitHub repository such as EmonScripts  | `/opt/openenergymonitor` |
| Install location for modules symlinked to www  | `/opt/emoncms` |
| Main code location  | `/var/www/emoncms` |
| Log file location   | `/var/log/emoncms` |
| Data directory      | `/var/opt/emoncms` |
