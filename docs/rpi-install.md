# EmonScripts: SD Card Preparation for RaspberryPi

1\. Start by following the first part of this nice guide by Pimoroni: [Setting up a Headless Pi](https://learn.pimoroni.com/article/setting-up-a-headless-pi) to flash the base OS Image. Choose the Lite 32-bit image. Set a username and password and add your WiFi credentials if required. **Do not insert into the Pi**.

2\. Eject the SD Card and reinsert. On Windows you need the `boot` partition (ignore other error messages). Open the SD card on your computer and edit the file `/usr/lib/raspberrypi-sys-mods/firstboot` on the boot partition. Comment out the lines:

```
# if check_variables; then
  # do_resize
# fi
```

3\. Our automated step for partition creation and resizing needs revisiting. In the mean time use gParted to extend the root (usually /dev/mmcblk0p2) to around 6GB. Create a 3rd partition to house the emoncms data using the ext2 filesystem, this can fill the rest of the disk. We usually create this to be around 10GB which should give about 10 years of data storage with 85x 10s PHPFina feeds.

4\. Eject the SD card from your PC. Place the SD card in your RaspberryPi & power up. After a couple of minutes you will be able to SSH into the new image e.g:

`ssh pi@192.168.1.100 (password: your password)`

5\. Finish the partition creation process by formatting the data partition.

We set the blocksize here to be 1024 bytes instead of the default 4096 bytes. A lower block size results in significant write load reduction when using an application like emoncms that only makes small but frequent and across many files updates to disk. Ext2 is choosen because it supports multiple linux user ownership options which are needed for the mysql data folder. Ext2 is non-journaling which reduces the write load a little although it may make data recovery harder vs Ext4, The data disk size is small however and the downtime from running fsck is perhaps less critical.


```
sudo mkfs.ext2 -b 1024 /dev/mmcblk0p3
```

*This step can take ages, depending on the type of SD card - it's faster with the latest generation SanDisks.*

6\. Update the fstab to include the data partition

```
wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/defaults/etc/fstab
sudo mv fstab /etc/fstab
sudo reboot
```

7\. Add a data directory.

```
sudo mkdir /var/opt/emoncms
sudo chown www-data /var/opt/emoncms
```

You can now continue with installing the EmonCMS stack.

Note post EmonScripts steps listed in the [RaspberryPi OS 32bit Lite install (10th Nov 2022) PROCESS UPDATE issue](https://github.com/openenergymonitor/EmonScripts/issues/148).

## Manual setup of ext2 data partition without gParted

Steps for creating 3rd partition for data using fdisk and mkfs:

```
sudo fdisk -l
Note end of last partition (5785599 on standard sd card)
sudo fdisk /dev/mmcblk0
enter: n->p->3
enter: 5785600
enter: default or 7626751
enter: w (write partition to disk)
fails with error, will write at reboot
sudo reboot
```

Continue at this point with step 5 onwards above.
