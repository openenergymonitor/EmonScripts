# EmonScripts: SD Card Preparation for RaspberryPi

1\. Start by following the first part of this nice guide by Pimoroni: [Setting up a Headless Pi](https://learn.pimoroni.com/article/setting-up-a-headless-pi) to flash the base OS Image. Choose the Lite 32-bit image. Set a username (`pi`) & password, Enable SSH, and add your WiFi credentials if required. **Do not insert into the Pi**.

2\. Eject the SD Card from computer and reinsert. On Windows open 'Disk Management' and look for the SDCard. At the end there will be a large area of unallocated space. Right Click on that and select `New Simple Volume`. What you select here does not matter, but do not format it (waste of time!). Eject card and insert into the Pi. Let the Pi do it's first boot (be patient it reboots several times).

3\. Once it has booted SSH into the Pi. e.g. `ssh pi@192.168.1.100` (password: your password)` or use PuTTY.

4\. You now need to delete the partition you created. It was there to prevent the Pi expanding the `rootfs` on first boot. You cannot easily shrink `rootfs`! You will then create a new partition at the end of the card and then increase `rootfs` to fill the remaining space. Follow the following instructions:

5\. Delete additional partition

```shell
sudo parted /dev/mmcblk0 rm 3
```

6\. Create a new partition at the end - you specify the **start** point and the partition filles to the end of the card. The **example** 20G figure is the **start** point for the data partition and can vary depending on size of card of course. For testing make it small so the mkfs doesn't take an age!! You will get an error message in red - ignore it.

Create partition starting at XX and filling to the end.

```shell
echo "5G, +" | sudo sfdisk --force -N 3 /dev/mmcblk0
```

7\. Expand the root partition in the space available. Again an error message - ignore it!

```shell
echo ", +" | sudo sfdisk --force -N 2 /dev/mmcblk0
```

8\. Run partprobe

```shell
sudo partprobe
```

9\. Resize the rootfs

```shell
sudo resize2fs /dev/mmcblk0p2
```

10\. Format the new partition. We set the blocksize here to be 1024 bytes instead of the default 4096 bytes. A lower block size results in significant write load reduction when using an application like emoncms that only makes small but frequent and across many files updates to disk. Ext2 is choosen because it supports multiple linux user ownership options which are needed for the mysql data folder. Ext2 is non-journaling which reduces the write load a little although it may make data recovery harder vs Ext4, The data disk size is small however and the downtime from running fsck is perhaps less critical.

```shell
sudo mkfs.ext2 -b 1024 /dev/mmcblk0p3
```

11\. Pull down the fstab as before (change `stable` to `master` if you want the master branch)

```shell
wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/defaults/etc/fstab
```

12\. Then

```shell
sudo mv fstab /etc/fstab && sudo reboot now
```

After the rebbot it should look like this (roughly, your sizes may vary).

```shell
pi@emonsdtestZ:~ $ df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            661M     0  661M   0% /dev
tmpfs           185M  1.2M  184M   1% /run
/dev/mmcblk0p2  4.4G  1.7G  2.6G  39% /
tmpfs           925M     0  925M   0% /dev/shm
tmpfs           5.0M   16K  5.0M   1% /run/lock
tmpfs            30M     0   30M   0% /tmp
tmpfs           1.0M     0  1.0M   0% /var/lib/php/sessions
tmpfs           1.0M     0  1.0M   0% /var/tmp
/dev/mmcblk0p1  510M   93M  418M  19% /boot
/dev/mmcblk0p3  9.7G   14K  9.2G   1% /var/opt/emoncms
tmpfs           185M     0  185M   0% /run/user/1000
```

Note post EmonScripts steps listed in the [RaspberryPi OS 32bit Lite install (10th Nov 2022) PROCESS UPDATE issue](https://github.com/openenergymonitor/EmonScripts/issues/148).
