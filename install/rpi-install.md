# EmonCMS Install SD Card Preparation for RaspberryPi

1. Download the [Raspbian Buster Lite image](https://www.raspberrypi.org/downloads/raspbian/) and write it to an SD card with at least 16GB of space. [Balena](https://www.balena.io/) provide a nice tool called [Etcher](https://www.balena.io/etcher) which makes this process really easy.

1. After writing the image to the SD card, open the SD card `boot` folder on your computer.

1. Create a file called ssh on the boot partition - to enable SSH access to the system.

1. Copy the default `cmdline.txt` to `cmdline2.txt` in the boot partition.
1. Edit `cmdline.txt` and remove this text:

    ```shell
    init=/usr/lib/raspi-config/init_resize.sh
    ```

    This will stop the image from expanding to fill the full SD card size on first boot.

1. If you want to add a `wpa_supplicant.conf` to the boot folder so it connects to your Wi-Fi, especially if using a PiZero, do so now.

    ```
    ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
    update_config=1
    country=<Insert 2 letter ISO 3166-1 country code here>

    network={
     ssid="<Name of your wireless LAN>"
     psk="<Password for your wireless LAN>"
    }
    ```

1. Eject the SD card from your PC.

1. Place the SD card in your RaspberryPi & power up. After a couple of minutes you will be able to SSH into the new Buster image e.g:
`ssh pi@192.168.1.100 (password: raspberry)`

1. Install modified init_resize.sh and reinstate old `cmdline.txt`. This will setup the SD Card partitions on next reboot.

    ```shell
    wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/install/init_resize.sh
    chmod +x init_resize.sh
    sudo mv init_resize.sh /usr/lib/raspi-config/init_resize.sh
    sudo mv /boot/cmdline2.txt /boot/cmdline.txt
    sudo reboot
    ```

1. Finish filesystem resize and format the data partition:

    ```shell
    sudo resize2fs /dev/mmcblk0p2
    ```

    ```shell
    sudo mkfs.ext2 -b 1024 /dev/mmcblk0p3
    ```

    (The step above can take ages, depending on the type of SD card - it's faster with the latest generation SanDisks for example)
1. Update the fstab to include the data partition

    ```shell
    wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/defaults/etc/fstab
    sudo mv fstab /etc/fstab
    sudo reboot
    ```

1. Add a data directory.

    ```shell
    sudo mkdir /var/opt/emoncms
    sudo chown www-data /var/opt/emoncms
    ```

You can now continue with installing the EmonCMS stack.

## Manual setup of ext2 data partition

**Note:** This step is carried out as part of steps above, kept here for now for reference.

We create here an ext2 partition and filesystem with a blocksize of 1024 bytes instead of the default 4096 bytes - to store emoncms feed data. A lower block size results in significant write load reduction when using an application like emoncms that only makes small but frequent and across many files updates to disk. Ext2 is choosen because it supports multiple linux user ownership options which are needed for the mysql data folder. Ext2 is non-journaling which reduces the write load a little although it may make data recovery harder vs Ext4, The data disk size is small however and the downtime from running fsck is perhaps less critical.*

Use a partition editor to resize the raspbian stretch OS partition, select 3-4GB for the OS partition and expand the new partition to the remaining space.

GParted is a nice tool for doing this on a Ubuntu machine. Once complete place the SD card back in the RPi, power up and SSH back in.

Steps for creating 3rd partition for data using fdisk and mkfs:

```shell
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

On reboot, login and run:

```shell
sudo mkfs.ext2 -b 1024 /dev/mmcblk0p3
```

Create a directory that will be a mount point for the rw data partition

```shell
sudo mkdir /var/opt/emoncms
sudo chown www-data /var/opt/emoncms
```

Use modified fstab

```shell
wget https://raw.githubusercontent.com/openenergymonitor/EmonScripts/stable/defaults/etc/fstab
sudo cp fstab /etc/fstab
sudo reboot
```
