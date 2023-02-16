# Developer Notes on EmonScripts

These notes are to explain why certain things have been done as they are done!

## Creating the SD Image

The SD Image is created primarily for user of the emonPi.

1\. Before creating a stable release of `EmonScripts`, update the `main.sh` file with the new image name

[sudo touch /boot/emonSD-DDMMMYY](https://github.com/openenergymonitor/EmonScripts/blob/a7c03955f8e2450cdedbaac34e9410188d3eb818/install/main.sh#L102)

2\. Run `EmonScripts` with defaults.

3\. After running the EmonScripts, reboot.

4\. Set WiFi country code via `raspi-config`

```shell
sudo raspi-config
```

5\. Prepare wifiAP

```shell
sudo systemctl disable hostapd.service
sudo wifiAP start
sudo reboot
```

6\. Remove emoncms logs. `emonpiupdate.log` will be present, remove to ensure emonpifirstupdate runs next time.

```shell
sudo rm /var/log/emoncms/emonpiupdate.log
sudo rm /var/log/emoncms/emonupdate.log
sudo rm /var/log/emoncms/emoncms.log
```

7\. Disable SSH

```shell
sudo update-rc.d ssh disable
sudo invoke-rc.d ssh stop
sudo dpkg-reconfigure openssh-server
```

8\. Check that emonpiupdate.log has been removed before creating image.

9\. Update the Image name `emonSD-DDMMMYY` file on boot partition and in safe-update list on master branch.

10\. Create image

```shell
sudo dd if=/dev/sdb of=emonSD-17Oct19.img bs=4M
```

## Logs, `journald` and `logrotate`

### Why is it important

It was suspected that the writing of the logs was having an impact on the life of the SD Card. Several mechanisms were put in place to reduce that write load, primarily the use of placing the log folder into RAM as opposed to disc. each write is then to a RAM file not an SD Card file.  It was subsequently acknowledged that having a persistent form of logs was benificial so `log2ram` was introduced. With this brought a need to ensure `logrotate` worked for all logs and worked correctly. Finally, `journald` must also write to RAM.

### Principle - use drop-in files

Adding to the standard configuration file is **always** a bad idea. As we do for other configuration changes, add in a drop-in to the `conf.d` folder and add the command to read it. From the `systemd` man (but they all say the same);

```shell
When packages need to customize the configuration, they can install configuration snippets in /usr/lib/systemd/*.conf.d/ or /usr/local/lib/systemd/*.conf.d/. The main configuration file is read before any of the configuration directories, and has the lowest precedence;
```

In the Emonscripts folder `opt/openenergymonitor/EmonScripts/defaults/etc/logrotate` are a number of drop in files that are linked to from the `/etc/logrotate.d/` folder. If they need updating the update process replaces these files so logrotate will pick them up automatically.

### Changes to logrotate package

A number of changes to the logrotate package have required the config files to be updated.

`logrotate` should alos be run hourly by updating the `systemd` `timer`.

### `journald` changes

TL:DR - by default in Bullseye `journald` writes to disk. To stop this delete the `/var/log/journal` file and it reverts to writing the log to RAM.

There was an issue with `journald` - by default it is set to `auto` but a `/var/log/journal` folder is created somewhere along the line on first boot, so the journal is saved to disk.

this question provides some insight. [Stackoverflow Question](https://unix.stackexchange.com/questions/513212/journald-storage-persistent-just-disk-or-ram-disk)

You can see what files are in use using this command:

```shell
journalctl --unit=systemd-journald --boot 0 --output cat
```

There may be some advantage to saving the `journal` files as they do contain some good info on occasions, however, `ForwardToSyslog=yes` is enabled by default and we preserve this.

By default `journald` will use 10% of the available space.
