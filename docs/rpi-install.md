# EmonScripts: SD Card Preparation for RaspberryPi

emonSD splits the SD card into three partitions:

| Partition | Mount | Filesystem |
|---|---|---|
| `/dev/mmcblk0p1` | `/boot/firmware` | vfat |
| `/dev/mmcblk0p2` | `/` | ext4, fixed size (default 6 GB) |
| `/dev/mmcblk0p3` | `/var/opt/emoncms` | ext2, rest of the card |

Emoncms feed data is written to the separate data partition. It uses ext2 with a 1024 byte block size instead of the default 4096: emoncms makes small but frequent updates across many files, and a smaller block size significantly reduces the write load on the SD card. Ext2 is non-journaling, which reduces the write load a little further, at the cost of a longer `fsck` and harder data recovery than ext4.

## Prepare the card

1\. Flash Raspberry Pi OS Lite (64-bit) with [Raspberry Pi Imager](https://www.raspberrypi.com/software/). In the Imager settings set a username (`pi`) and password, enable SSH, and add your WiFi credentials if required.

2\. Insert the card into the Pi and let it complete its first boot (be patient, it may reboot). Then SSH into the Pi, e.g. `ssh pi@192.168.1.100`.

3\. Download and run the partition script. It asks for the root partition size (default 6 GB), then reboots to do the partitioning before the root filesystem is mounted.

```shell
wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/install/partition.sh
chmod +x partition.sh && ./partition.sh
```

4\. After the reboot, SSH in again and run the script a second time. It formats the data partition, installs the emonSD `fstab` and reboots.

```shell
./partition.sh
```

5\. After that reboot `df -h` should look roughly like this (sizes depend on the card):

```shell
pi@emonpi:~ $ df -h / /var/opt/emoncms
Filesystem      Size  Used Avail Use% Mounted on
/dev/mmcblk0p2  4.9G  1.9G  2.8G  41% /
/dev/mmcblk0p3   23G   14K   22G   1% /var/opt/emoncms
```

The card is now ready: continue with [Build with EmonScripts](install.md).

## Manual partitioning (reference)

The steps `partition.sh` automates, for reference or if the script cannot be used. Flash the card as in step 1 above, but **do not insert it into the Pi yet**.

1\. Eject the SD Card from computer and reinsert. On Windows open 'Disk Management' and look for the SDCard. At the end there will be a large area of unallocated space. Right Click on that and select `New Simple Volume`. What you select here does not matter, but do not format it (waste of time!). This placeholder partition stops the Pi expanding the root filesystem to fill the card on first boot. Eject card and insert into the Pi. Let the Pi do it's first boot (be patient it reboots several times).

2\. Once it has booted SSH into the Pi. e.g. `ssh pi@192.168.1.100` (password: your password) or use PuTTY.

3\. Delete the placeholder partition

```shell
sudo parted /dev/mmcblk0 rm 3
```

4\. Create a new partition at the end - you specify the **start** point and the partition fills to the end of the card. The **example** 5G figure is the **start** point for the data partition and can vary depending on size of card of course. You will get an error message in red - ignore it.

```shell
echo "5G, +" | sudo sfdisk --force -N 3 /dev/mmcblk0
```

5\. Expand the root partition in the space available. Again an error message - ignore it!

```shell
echo ", +" | sudo sfdisk --force -N 2 /dev/mmcblk0
```

6\. Run partprobe

```shell
sudo partprobe
```

7\. Resize the rootfs

```shell
sudo resize2fs /dev/mmcblk0p2
```

8\. Format the new partition as ext2 with a 1024 byte block size

```shell
sudo mkfs.ext2 -m 1 -b 1024 /dev/mmcblk0p3
```

9\. Install the emonSD fstab (change `stable` to `master` if you want the master branch) and reboot

```shell
wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/defaults/etc/fstab
sudo mv fstab /etc/fstab && sudo reboot now
```
