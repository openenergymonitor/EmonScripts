# EmonCMS Install Scripts

## Introduction

This build script is currently a development in progress ([Forum: EmonSD build script progress update and alpha release](https://community.openenergymonitor.org/t/emonsd-build-script-progress-update-and-alpha-release/11222)). It is already more comprehensive than the alternative debian install guides.

This build script can be used to build a fully fledged emoncms installation on debian based operating systems, including: installation of LAMP server and related packages, redis, mqtt, emoncms core, emoncms modules, and if applicable, emonhub & raspberrypi support for serial port, and WiFi access point.

The script is a series of scripts that install each required component. To see what is installed and how open each script.

As at 7 Oct 19 - Tested on:

- [Raspbian Buster Lite](https://www.raspberrypi.org/downloads/raspbian/), Release date: 2019-07-10
- Ubuntu 1804 LTS

## Todo

- SSL [Community Discussion](https://community.openenergymonitor.org/t/emonsd-next-steps-filesystem-logrotate/10693/188)
- Review .env configuration
- Review logrotate configuration
- Review disk wear results from 1st release, investigate ext filesystem commit interval vs app level buffering

[Forum: EmonSD build script progress update and alpha release](https://community.openenergymonitor.org/t/emonsd-build-script-progress-update-and-alpha-release/11222)

## Base OS Preparation

### RaspberryPi

To install onto a RaspberryPi, a number of tasks are required. Please follow [this instruction first](https://github.com/openenergymonitor/EmonScripts/blob/master/install/rpi-install.md).

### Ubuntu

For Ubuntu, post base OS install, run this command so the user does not need a password for `sudo`.

```shell
sudo echo $USER' ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/$USER && sudo chmod 0440 /etc/sudoers.d/$USER
```

## Install the EmonCMS Installation Scripts

Pull the script from GitHub (note if you wish to pull the script from `master` change the path).

```shell
wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/install/init.sh
chmod +x init.sh && ./init.sh
```

The `init` script automatically calls the `main` script. At this point you will be offered the option to configure the installation process.

If you are on a RaspberryPi or EmonPi you can usually just proceed.

The Install process does takes sometime.

## Post Install - Settings

If you have used EmonCMS before you may need to edit the settings to suit your local setup. This is now an `ini` file called `settings.ini` in `/var/www/emoncms/`.

## Post Install - First Use

To access EmonCMS go to the IP of your machine in your browser.  This [Guide](https://guide.openenergymonitor.org/setup/connect/) will help you set your system up.

At the initial user screen, you need to select **Register** and create a user - this will be the admin user.

If you are migrating from an old system, Export your data from the old system and Import the data to the new system (after registering a user). This will then require you to login as the original user.

## Configure install

The default configuration is for the RaspberryPi platform and Raspbian Buster image specifically. To run the installation on a different distribution, you may need to change the configuration to reflect the target environment.

To edit the configuration (standard file paths):

```shell
cd /opt/openenergymonitor/EmonScripts/install/
nano config.ini
```

To restart the installation:

```shell
./main.sh
```

See explanation and settings in installation configuration file here: [config.ini](https://github.com/openenergymonitor/EmonScripts/blob/stable/install/config.ini)

## Run Scripts Individually

It is possible to run the [scripts individually](https://github.com/openenergymonitor/EmonScripts/blob/master/install/install-scripts.md) for a single part of the stack. These are not guaranteed to be a complete solution (some folders may not be created for instance).

## Standard Setup Filepaths

Install location for code from OpenEnergyMonitor GitHub repository such as EmonScripts `/opt/openenergymonitor`

Install location for modules symlinked to www `/opt/emoncms`

Main code location `/var/www/emoncms`

Log file location `/var/log/emoncms`

Data directory `/var/opt/emoncms`
