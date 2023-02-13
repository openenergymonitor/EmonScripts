# EmonCMS Install Scripts

## Introduction

The [EmonScripts build scripts](https://github.com/openenergymonitor/EmonScripts/) can be used to build a fully fledged emonCMS installation on debian based operating systems, including: installation of LAMP server and related packages, redis, MQTT, emonCMS core, emonCMS modules, and if applicable, emonhub & RaspberryPi support for serial port, and WiFi access point.

We use EmonScripts to build the pre-built emonSD SD card image for the Raspberry Pi. If you prefer to build your own or customise the installation using EmonScripts directly is a good approach.

The installation process is carried out by a series of scripts that install each required component. These can be explored here: [https://github.com/openenergymonitor/EmonScripts/tree/master/install](https://github.com/openenergymonitor/EmonScripts/tree/master/install).

It is **strongly recommended** that you dedicate a single device (NUC/VM/Pi) to emoncms. Using it alongside other software can prove problematic.

**Before starting,** please review the EmonScripts issue list for any new issues that might affect your build. We try to list new issues and notes from recent builds there that might be useful or required to complete a successful build: [https://github.com/openenergymonitor/EmonScripts/issues](https://github.com/openenergymonitor/EmonScripts/issues).

## Building Your Own - Base OS Preparation

### RaspberryPi

To install on a RaspberryPi, a number of tasks are first required. Please follow [these instructions first](rpi-install.md).

### Ubuntu

For Ubuntu, post base OS install, run this command so the user does not need a password for `sudo`.

```shell
sudo echo $USER' ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/$USER && sudo chmod 0440 /etc/sudoers.d/$USER
```

### Digital Ocean Droplet

For installation on a Digital Ocean Droplet, follow [these instructions](digital-ocean-install.md).

## Install the EmonCMS Installation Scripts

Pull the script from GitHub (note if you wish to pull the script from `master` change the path). If you **want** to install the master branch

```shell
wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/install/init.sh
chmod +x init.sh && ./init.sh
```

The `init` script automatically calls the `main` script. At this point you will be offered the option to configure the installation process.

If you are on a RaspberryPi or EmonPi you can usually just proceed.

Be patient, the install process takes some time.

### Ubuntu

For Ubuntu, once the script starts and asks if you "would like to review the build script before starting?" Answer y(es)
The installation must be configured before proceeding...

## Configure install

The default configuration is specifically for the RaspberryPi platform and Raspbian Buster image. To run the installation on a different distribution, you may need to change the configuration to reflect the target environment, e.g. set `emonSD_pi_env=0`

To edit the configuration (standard file paths):

```shell
cd /opt/openenergymonitor/EmonScripts/install/
nano config.ini
```
### Ubuntu

Change the following:
```
user=[YOUR_UBUNTU_USERNAME]
emonSD_pi_env=0

install_emonhub=false

install_emoncms_emonpi_modules=false
install_firmware=false
install_emonpilcd=false
install_emonsd=false
install_wifiap=false
```
Comment out the following:
```
#emoncms_modules[config]=stable
#emoncms_modules[wifi]=stable
#emoncms_modules[setup]=stable
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
