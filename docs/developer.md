# Developer Notes on EmonScripts

These notes are to explain why certain things have been done as they are done!

## Creating the SD Image

The SD Image is created primarily for user of the emonPi.

1\. Flash Raspberry Pi OS Lite (64-bit) with Raspberry Pi Imager. In the Imager settings set the hostname to `emonpi`, the user to `pi` with password `emonsd`, and enable SSH for the build.

2\. Partition the card into the emonSD layout: root shrunk to a fixed size (asked, default 6 GB) and an ext2 data partition at `/var/opt/emoncms` using the rest of the card. The script reboots once to do the partitioning before root is mounted; log in and run it again to finish.

```shell
wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/install/partition.sh
chmod +x partition.sh && ./partition.sh
# after the reboot
./partition.sh
```

3\. Run the build with defaults. The image version file `/boot/emonSD-DDMMMYY` is created automatically from the build date. The image is configured for the emonPi3 by default: its `emonhub.conf`, and GPIO17 held low with 1-Wire on GPIO27 and GPIO22 in `config.txt`. For emonPi2 or emonBase hardware set `emonsd_hardware=emonpi2` in `install/config.ini`.

```shell
wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/install/init.sh
chmod +x init.sh && ./init.sh
```

4\. Reboot, then check the build. `verify.sh` is read only; fix anything it reports as `FAIL`.

```shell
sudo reboot
cd /opt/openenergymonitor/EmonScripts/install
./verify.sh
```

5\. Add the image name, e.g. `emonSD-03Nov26`, to the `safe-update` list on the **master** branch. Without it, devices made from the image cannot update.

6\. Prepare the card for imaging. This runs `verify.sh` again, then sets the WiFi country (`wifi_country` in `config.ini`, default `GB`), saves the current `emonhub.conf` as the factory default used by `other/factoryreset`, disables SSH, removes this card's SSH host keys, authorized_keys and saved WiFi networks, clears logs, build logs and shell history, resets the machine-id, sets the data partition to grow to fill the card on first boot and shuts down. Copy off `~/main.sh.log` first if you want to keep it.

```shell
cd /opt/openenergymonitor/EmonScripts/install
./prepare_image.sh
```

**Do not boot the card again before imaging it.** Each device generates its own SSH host keys and machine-id on first boot; booting the build card would bake one set into every device. If it does get booted, run `prepare_image.sh` again.

7\. Create the image on another machine

```shell
sudo dd if=/dev/sdb of=emonSD-03Nov26.img bs=4M
```

## Building the image without a Raspberry Pi (experimental)

`image/build.sh` builds the image on any Linux machine. It downloads Raspberry Pi OS Lite (64-bit), creates the emonSD partitions directly in the image file, and runs `install/main.sh` and `install/prepare_image.sh` inside it with `systemd-nspawn`. On a non-arm64 machine the arm64 programs run under qemu emulation, so a build takes one to two hours.

EmonScripts is copied into the image from the local checkout at its current commit, so a branch can be built before it is pushed.

```shell
sudo apt install systemd-container qemu-user-binfmt passt
sudo image/build.sh                  # root 6 GB, data 2 GB
sudo image/build.sh --root-size 7    # if the root partition runs out of space
```

The result is `~/emonsd-build/emonSD-DDMMMYY.img.xz`, with its sha256 and the build logs. The minimum SD card size is 16 GB. Flash it with Raspberry Pi Imager (Choose OS, Use custom) and do not apply OS customisation: the image already has the `pi` user, hostname and settings. SSH is disabled as shipped; to log in, create an empty file named `ssh` on the boot partition after flashing.

On the first boot of each device, `emonsd-grow-data.service` grows the data partition to fill the card before it is mounted. This can add minutes to the first boot on a large card, so do not remove power during it. If it fails, the partition stays at its current size and it tries again on the next boot (`journalctl -u emonsd-grow-data`).

Not done yet: services are installed but never started during the build, so run `verify.sh` on the Pi after the first boot.

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
