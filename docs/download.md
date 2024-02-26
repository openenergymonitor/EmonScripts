# emonSD Download

emonSD is a pre-built SD card image for the Raspberry Pi to function as an OpenEnergyMonitor emonPi / emonBase. The image is available for download below or if you need a new SD card we also offer industrial grade SD cards with the image pre-loaded [in the shop](https://shop.openenergymonitor.com/pre-loaded-emonsd-microsd-card-for-raspberry-pi/).

---

<details>
<summary><b>emonSD-01Feb24</b></summary>

**Download (1.4 GB):** [UK Server](https://openenergymonitor.org/files/emonSD-01Feb24.zip)

(eligible for updates)
```
(.zip) MD5: b64503d08704d1605a7ea23745f0a6fc
```

**Credentials**

- **SSH:** username: `pi`, password: `emonsd` (default - please change)
- **WiFi Access Point:** SSID: `emonpi`, Password: `emonpi2016`
- **MQTT:** username: `emonpi`, password: `emonpimqtt2016`
- **MySQL:** username: `emoncms`, password: `emonpiemoncmsmysql2016`

*SSH access disabled by default. Long press emonPi LCD push button for 5s to enable. Or create file `/boot/ssh` in FAT partition.*

**Build**

- Built using EmonScripts emoncms installation script, see<br> [https://github.com/openenergymonitor/EmonScripts](https://github.com/openenergymonitor/EmonScripts).
- Based on Raspberry Pi OS Lite (32-bit Bookworm), 2023-12-11
- Compatible with Raspberry Pi 3, 3B+, 4 & Pi Zero2
- Emoncms data is logged to low-write ext2 partition mounted in `/var/opt/emoncms`
- Log partition `/var/log` mounted as tmpfs using log2ram, now persistent after reboot

**Kernel**
```
$ uname -a
Linux emonpi 6.1.0-rpi8-rpi-v8 #1 SMP PREEMPT Debian 1:6.1.73-1+rpt1 (2024-01-25) aarch64 GNU/Linux
```

**File System**
```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            661M     0  661M   0% /dev
tmpfs           185M  4.3M  181M   3% /run
/dev/mmcblk0p2  4.4G  3.0G  1.3G  71% /
tmpfs           925M     0  925M   0% /dev/shm
tmpfs           5.0M   16K  5.0M   1% /run/lock
tmpfs            30M   28K   30M   1% /tmp
tmpfs           1.0M     0  1.0M   0% /var/lib/php/sessions
tmpfs           128M     0  128M   0% /var/tmp
/dev/mmcblk0p1  510M   93M  418M  19% /boot/firmware
/dev/mmcblk0p3  9.7G   19K  9.2G   1% /var/opt/emoncms
log2ram          50M  824K   50M   2% /var/log
tmpfs           185M     0  185M   0% /run/user/1000
```

**Emoncms**

```
Server Information
-----------------------

Services
	emonhub :	 Active Running                      
	emoncms_mqtt :	 Active Running                      
	feedwriter :	 Active Running - sleep 300s 0 feed points pending write
	service-runner :	 Active Running                      
	emonPiLCD :	 Active Running                      
	redis-server :	 Active Running                      
	mosquitto :	 Active Running                      
	demandshaper :	 Not found or not installed                                  
Emoncms
	Version :	 low-write 11.4.11
	Git :	 
		URL :	 https://github.com/emoncms/emoncms.git
		Branch :	 * stable
		Describe :	 11.4.11
	Components :	 Emoncms Core v11.4.11 | App v2.8.1 | EmonHub Config v2.1.5 | Dashboard v2.3.3 | Device v2.2.3 | Graph v2.2.3 | Network Setup v1.0.5 | Backup v2.3.3 | Network v3.1.2 | Postprocess v2.4.7 | Sync v2.1.5 | Usefulscripts v2.3.11 | EmonScripts v1.7.10 | RFM2Pi v1.4.2 | Avrdude-rpi v1.0.3 | EmonPiLCD v2.0.1 | Emonhub v2.6.5

Server
	CPU :	 Cortex-A72 | 1 Threads(s) | - Sockets(s) | 108.00MIPS | 
	OS :	 Linux 6.1.0-rpi8-rpi-v8
	Host :	 emonpi | emonpi | (192.168.42.1)
	Date :	 2024-02-01 15:59:51 UTC
	Uptime :	 15:59:51 up 20 min,  1 user,  load average: 0.03, 0.04, 0.04

Memory
	RAM :	 Used: 14.09%
		Total :	 1.8 GB
		Used :	 260.43 MB
		Free :	 1.55 GB
	Swap :	 Used: 0.00%
		Total :	 100 MB
		Used :	 0 B
		Free :	 100 MB

Disk
	 :	 - / :	 Used: 66.84%
		Total :	 4.39 GB
		Used :	 2.94 GB
		Free :	 1.24 GB
		Read Load :	 n/a
		Write Load :	 n/a
		Load Time :	 n/a
	/boot/firmware :	 Used: 18.07%
		Total :	 509.99 MB
		Used :	 92.17 MB
		Free :	 417.83 MB
		Read Load :	 n/a
		Write Load :	 n/a
		Load Time :	 n/a
	/var/opt/emoncms :	 Used: 0.00%
		Total :	 9.68 GB
		Used :	 19 KB
		Free :	 9.19 GB
		Read Load :	 n/a
		Write Load :	 n/a
		Load Time :	 n/a
	/var/log :	 Used: 1.63%
		Total :	 50 MB
		Used :	 836 KB
		Free :	 49.18 MB
		Read Load :	 n/a
		Write Load :	 n/a
		Load Time :	 n/a

HTTP
	Server :	 Apache/2.4.57 (Raspbian) HTTP/1.1 CGI/1.1 80

MySQL
	Version :	 10.11.3-MariaDB-1+rpi1
	Host :	 127.0.0.1 (127.0.0.1)
	Date :	 2024-02-01 15:59:51 (UTC 00:00‌​)
	Stats :	 Uptime: 1232  Threads: 6  Questions: 281  Slow queries: 0  Opens: 46  Open tables: 39  Queries per second avg: 0.228

Redis
	Version :	 
		Redis Server :	 7.0.11
		PHP Redis :	 6.0.3-dev
	Host :	 localhost:6379
	Size :	 52 keys (1.01M)
	Uptime :	 0 days

MQTT Server
	Version :	 Mosquitto 2.0.11
	Host :	 localhost:1883 (127.0.0.1)

PHP
	Version :	 8.1.27 (Zend Version 4.1.27)
	Run user :	 User: www-data Group: www-data video Script Owner: pi
	Modules :	 apache2handler calendar Core ctype curl date exif FFI fileinfo filter ftp gd gettext hash iconv json libxml mbstring mosquitto v0.4.0mysqli mysqlnd vmysqlnd 8.1.27openssl pcre PDO pdo_mysql Phar posix readline redis v6.0.3-devReflection session shmop sockets sodium SPL standard sysvmsg sysvsem sysvshm tokenizer Zend OPcache zlib 
Pi
	Model :	 Raspberry Pi  Model N/A Rev  -  ()
	Serial num. :	 - CPU Temperature :	 39.43°C
	GPU Temperature :	 N/A (to show GPU temp execute this command from the console "sudo usermod -G video www-data" )
	emonpiRelease :	 emonSD-01Feb24
	File-system :	 read-write

Client Information
-----------------------

HTTP
	Browser :	 Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0
	Language :	 en-GB,en;q=0.5

Window
	Size :	 1856 x 968

Screen
	Resolution :	 1920 x 1080
```

</details>

<details>
<summary><b>emonSD-20Nov23</b></summary>

---

**Download standard emonPi1 / emonBase image (1.3 GB):** [UK Server](https://openenergymonitor.org/files/emonSD-20Nov23.zip)<br>(MD5: ed9ecc0d8930d7f7422890e462b3020c)

---

*Download emonPi2 version (1.3 GB): [UK Server](https://openenergymonitor.org/files/emonSD-20Nov23-emonpi2.zip)<br>(MD5: 164899034638325952572dbe68f3285e)<br>Includes emonPi2 compatible emonhub.conf and one wire temperature sensing on GPIO17 is enabled. Download the emonPi1/emonBase image for existing installations.*

---

(eligible for updates)

**Credentials**

- **SSH:** username: `pi`, password: `emonsd` (default - please change)
- **WiFi Access Point:** SSID: `emonpi`, Password: `emonpi2016`
- **MQTT:** username: `emonpi`, password: `emonpimqtt2016`
- **MySQL:** username: `emoncms`, password: `emonpiemoncmsmysql2016`

*SSH access disabled by default. Long press emonPi LCD push button for 5s to enable. Or create file `/boot/ssh` in FAT partition.*

**Build**

- Built using EmonScripts emoncms installation script, see<br> [https://github.com/openenergymonitor/EmonScripts](https://github.com/openenergymonitor/EmonScripts).
- Based on Debian Raspberry Pi OS (64-bit) Legacy Lite, 2023-05-03
- Compatible with Raspberry Pi 3, 3B+, 4 & Pi Zero2
- Emoncms data is logged to low-write ext2 partition mounted in `/var/opt/emoncms`
- Log partition `/var/log` mounted as tmpfs using log2ram, now persistent after reboot

**Kernel**
```
$ uname -a
Linux emonpi 6.1.21-v8+ #1642 SMP PREEMPT Mon Apr  3 17:24:16 BST 2023 aarch64 GNU/Linux

```
**File System**
```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       5.7G  2.5G  3.0G  46% /
devtmpfs        667M     0  667M   0% /dev
tmpfs           925M     0  925M   0% /dev/shm
tmpfs           370M  5.8M  365M   2% /run
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs            30M     0   30M   0% /tmp
tmpfs           1.0M     0  1.0M   0% /var/lib/php/sessions
tmpfs           1.0M     0  1.0M   0% /var/tmp
/dev/mmcblk0p1  255M   51M  205M  20% /boot
/dev/mmcblk0p3  8.7G   23K  8.3G   1% /var/opt/emoncms
log2ram          50M  3.0M   47M   6% /var/log
tmpfs           185M     0  185M   0% /run/user/1000
```
**Emoncms**

```
Server Information
-----------------------

Services
	emonhub :	 Active Running                      
	emoncms_mqtt :	 Active Running                      
	feedwriter :	 Active Running - sleep 300s 0 feed points pending write
	service-runner :	 Active Running                      
	emonPiLCD :	 Active Running                      
	redis-server :	 Active Running                      
	mosquitto :	 Active Running                      
	demandshaper :	 Not found or not installed                                  
Emoncms
	Version :	 low-write 11.4.2
	Git :	 
		URL :	 https://github.com/emoncms/emoncms.git
		Branch :	 * stable
		Describe :	 11.4.2
	Components :	 Emoncms Core v11.4.2 | App v2.7.9 | EmonHub Config v2.1.5 | Dashboard v2.3.3 | Device v2.2.3 | Graph v2.2.3 | Network Setup v1.0.2 | WiFi v2.1.1 | Backup v2.3.3 | Postprocess v2.4.7 | Sync v2.1.5 | Usefulscripts v2.3.11 | EmonScripts v1.6.25 | RFM2Pi v1.4.2 | Avrdude-rpi v1.0.3 | Emonhub v2.6.2 | EmonPi v3.0.2

Server
	CPU :	 1 Threads(s) | 4 Core(s) | 1 Sockets(s) | Cortex-A72 | 108.00MIPS | 
	OS :	 Linux 6.1.21-v8+
	Host :	 emonpi | emonpi | (10.0.206.98)
	Date :	 2023-11-21 13:46:54 UTC
	Uptime :	 13:46:54 up 5 min,  1 user,  load average: 0.10, 0.13, 0.07

Memory
	RAM :	 Used: 12.57%
		Total :	 1.81 GB
		Used :	 232.36 MB
		Free :	 1.58 GB
	Swap :	 Used: 0.00%
		Total :	 100 MB
		Used :	 0 B
		Free :	 100 MB

Disk
	 :	 - / :	 Used: 43.43%
		Total :	 5.62 GB
		Used :	 2.44 GB
		Free :	 2.92 GB
		Read Load :	 336.44 KB/s
		Write Load :	 0 B/s
		Load Time :	 0 mins
	/boot :	 Used: 19.77%
		Total :	 254.99 MB
		Used :	 50.42 MB
		Free :	 204.57 MB
		Read Load :	 0 B/s
		Write Load :	 0 B/s
		Load Time :	 0 mins
	/var/opt/emoncms :	 Used: 0.00%
		Total :	 8.69 GB
		Used :	 23 KB
		Free :	 8.25 GB
		Read Load :	 0 B/s
		Write Load :	 113.78 B/s
		Load Time :	 0 mins
	/var/log :	 Used: 6.01%
		Total :	 50 MB
		Used :	 3 MB
		Free :	 47 MB
		Read Load :	 n/a
		Write Load :	 n/a
		Load Time :	 n/a

HTTP
	Server :	 Apache/2.4.56 (Raspbian) HTTP/1.1 CGI/1.1 80

MySQL
	Version :	 10.5.21-MariaDB-0+deb11u1
	Host :	 127.0.0.1 (127.0.0.1)
	Date :	 2023-11-21 13:46:53 (UTC 00:00‌​)
	Stats :	 Uptime: 2768  Threads: 7  Questions: 170  Slow queries: 0  Opens: 45  Open tables: 38  Queries per second avg: 0.061

Redis
	Version :	 
		Redis Server :	 6.0.16
		PHP Redis :	 6.0.3-dev
	Host :	 localhost:6379
	Size :	 73 keys (722.77K)
	Uptime :	 0 days

MQTT Server
	Version :	 Mosquitto 2.0.11
	Host :	 localhost:1883 (127.0.0.1)

PHP
	Version :	 8.1.25 (Zend Version 4.1.25)
	Run user :	 User: www-data Group: www-data video Script Owner: pi
	Modules :	 apache2handler calendar Core ctype curl date exif FFI fileinfo filter ftp gd gettext hash iconv json libxml mbstring mosquitto v0.4.0mysqli mysqlnd vmysqlnd 8.1.25openssl pcre PDO pdo_mysql Phar posix readline redis v6.0.3-devReflection session shmop sockets sodium SPL standard sysvmsg sysvsem sysvshm tokenizer Zend OPcache zlib 
Pi
	Model :	 Raspberry Pi 4 Model B Rev 1.5 - 2GB (Sony UK)
	Serial num. :	 100000003F81AAAB
	CPU Temperature :	 36.51°C
	GPU Temperature :	 N/A (to show GPU temp execute this command from the console "sudo usermod -G video www-data" )
	emonpiRelease :	 emonSD-20Nov23
	File-system :	 read-write

Client Information
-----------------------

HTTP
	Browser :	 Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0
	Language :	 en-GB,en;q=0.5

Window
	Size :	 1848 x 938

Screen
	Resolution :	 1920 x 1080
```
</details>

<details>
<summary><b>emonSD-10Nov22</b></summary>
<br>

<!--**Download (1.0 GB):** [UK Server](https://openenergymonitor.org/files/emonSD-10Nov22.zip)-->
**Download (1.0 GB):** [UK Server](https://openenergymonitor.org/files/emonSD-10Nov22_16gb.zip)

(eligible for updates)
```
(.zip) MD5: 271d8d502e822e3703500a5762519c1d
```

**Credentials**

- **SSH:** username: `pi`, password: `emonsd` (default - please change)
- **WiFi Access Point:** SSID: `emonsd`, Password: `emonsd2022`
- **MQTT:** username: `emonpi`, password: `emonpimqtt2016`
- **MySQL:** username: `emoncms`, password: `emonpiemoncmsmysql2016`

*SSH access disabled by default. Long press emonPi LCD push button for 5s to enable. Or create file `/boot/ssh` in FAT partition.*

**Build**

- Built using EmonScripts emoncms installation script, see<br> [https://github.com/openenergymonitor/EmonScripts](https://github.com/openenergymonitor/EmonScripts).
- Based on Debian Raspberry Pi OS (32-bit) Lite, 2021-03-04
- Compatible with Raspberry Pi 2, 3, 3B+, 4 & Pi Zero
- Emoncms data is logged to low-write ext2 partition mounted in `/var/opt/emoncms`
- Log partition `/var/log` mounted as tmpfs using log2ram, now persistent after reboot

**Kernel**
```
$ uname -a
Linux emonpi 5.15.76-v7l+ #1597 SMP Fri Nov 4 12:14:58 GMT 2022 armv7l GNU/Linux

```
**File System**
```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       5.8G  2.4G  3.2G  43% /
devtmpfs        776M     0  776M   0% /dev
tmpfs           937M     0  937M   0% /dev/shm
tmpfs           375M  9.2M  366M   3% /run
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs            30M     0   30M   0% /tmp
tmpfs           1.0M     0  1.0M   0% /var/lib/php/sessions
tmpfs           1.0M     0  1.0M   0% /var/tmp
/dev/mmcblk0p1  255M   50M  206M  20% /boot
/dev/mmcblk0p3  9.7G   19K  9.2G   1% /var/opt/emoncms
log2ram          50M  3.4M   47M   7% /var/log
tmpfs           188M     0  188M   0% /run/user/1000
```
**Emoncms**

```
Server Information
-----------------------

Services
	emonhub :	 Active Running                      
	emoncms_mqtt :	 Active Running                      
	feedwriter :	 Active Running - sleep 300s 0 feed points pending write
	service-runner :	 Active Running                      
	redis-server :	 Active Running                      
	mosquitto :	 Active Running                      
	emonPiLCD :	 Failed loaded failed failed                      
	demandshaper :	 Not found or not installed                                  
Emoncms
	Version :	 low-write 11.2.8
	Git :	 
		URL :	 https://github.com/emoncms/emoncms.git
		Branch :	 * stable
		Describe :	 11.2.8
	Components :	 Emoncms Core v11.2.8 | App v2.6.8 | EmonHub Config v2.1.5 | Dashboard v2.3.3 | Device v2.2.1 | Graph v2.2.3 | Network Setup v1.0.2 | WiFi v2.1.1 | Backup v2.3.2 | Postprocess v2.2.7 | Sync v2.1.4 | Usefulscripts v2.3.10 | EmonScripts v1.5.10 | RFM2Pi v1.4.1 | Avrdude-rpi v1.0.1 | Emonhub v2.5.2 | EmonPi v2.9.5

Server
	CPU :	 1 Threads(s) | 4 Core(s) | 1 Sockets(s) | Cortex-A72 | 324.00MIPS | 
	OS :	 Linux 5.15.76-v7l+
	Host :	 emonpi | emonpi | (10.0.206.190)
	Date :	 2022-11-29 15:55:08 UTC
	Uptime :	 15:55:08 up 13 min,  1 user,  load average: 0.33, 0.26, 0.19

Memory
	RAM :	 Used: 10.18%
		Total :	 1.83 GB
		Used :	 190.7 MB
		Free :	 1.64 GB
	Swap :	 Used: 0.00%
		Total :	 100 MB
		Used :	 0 B
		Free :	 100 MB

Disk
	 :	 - / :	 Used: 39.88%
		Total :	 5.78 GB
		Used :	 2.3 GB
		Free :	 3.16 GB
		Read Load :	 n/a
		Write Load :	 n/a
		Load Time :	 n/a
	/boot :	 Used: 19.52%
		Total :	 254.99 MB
		Used :	 49.78 MB
		Free :	 205.21 MB
		Read Load :	 n/a
		Write Load :	 n/a
		Load Time :	 n/a
	/var/opt/emoncms :	 Used: 0.00%
		Total :	 9.61 GB
		Used :	 19 KB
		Free :	 9.12 GB
		Read Load :	 n/a
		Write Load :	 n/a
		Load Time :	 n/a
	/var/log :	 Used: 6.64%
		Total :	 50 MB
		Used :	 3.32 MB
		Free :	 46.68 MB
		Read Load :	 n/a
		Write Load :	 n/a
		Load Time :	 n/a

HTTP
	Server :	 Apache/2.4.54 (Raspbian) HTTP/1.1 CGI/1.1 80

MySQL
	Version :	 10.5.15-MariaDB-0+deb11u1
	Host :	 127.0.0.1 (127.0.0.1)
	Date :	 2022-11-29 15:55:08 (UTC 00:00‌​)
	Stats :	 Uptime: 2266  Threads: 5  Questions: 137  Slow queries: 0  Opens: 47  Open tables: 39  Queries per second avg: 0.060

Redis
	Version :	 
		Redis Server :	 6.0.16
		PHP Redis :	 6.0.0-dev
	Host :	 localhost:6379
	Size :	 34 keys (701.23K)
	Uptime :	 0 days

MQTT Server
	Version :	 Mosquitto 2.0.11
	Host :	 localhost:1883 (127.0.0.1)

PHP
	Version :	 8.1.12 (Zend Version 4.1.12)
	Run user :	 User: www-data Group: www-data video Script Owner: pi
	Modules :	 apache2handler calendar Core ctype curl date dom v20031129exif FFI fileinfo filter ftp gd gettext hash iconv json libxml mbstring mosquitto v0.4.0mysqli mysqlnd vmysqlnd 8.1.12openssl pcre PDO pdo_mysql Phar posix readline redis v6.0.0-devReflection session shmop SimpleXML sockets sodium SPL standard sysvmsg sysvsem sysvshm tokenizer xml xmlreader xmlwriter xsl Zend OPcache zlib 
Pi
	Model :	 Raspberry Pi 4 Model B Rev 1.5 - 2GB (Sony UK)
	Serial num. :	 10000000014CB367
	CPU Temperature :	 39.43°C
	GPU Temperature :	 N/A (to show GPU temp execute this command from the console "sudo usermod -G video www-data" )
	emonpiRelease :	 emonSD-10Nov22
	File-system :	 read-write

Client Information
-----------------------

HTTP
	Browser :	 Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:107.0) Gecko/20100101 Firefox/107.0
	Language :	 en-GB,en;q=0.5

Window
	Size :	 1848 x 939

Screen
	Resolution :	 1920 x 1080
```
</details>

<details>
<summary><b>emonSD-21Jul21</b></summary>
<br>

**Download (1.8 GB):** [UK Server](https://openenergymonitor.org/files/emonSD-21Jul21.zip)

(eligible for updates)
```
(.zip) MD5: 1bf5988a61ae363768362dcfdb6b0190
```

- **SSH Credentials:** username: pi, password: emonpi2016 (default - please change)
- Built using EmonScripts emoncms installation script, see<br> [https://github.com/openenergymonitor/EmonScripts](https://github.com/openenergymonitor/EmonScripts).
- Based on Debian Raspberry Pi OS (32-bit) Lite, 2021-03-04
- Compatible with Raspberry Pi 2, 3, 3B+, 4 & Pi Zero
- Emoncms data is logged to low-write ext2 partition mounted in `/var/opt/emoncms`
- Log partition `/var/log` mounted as tmpfs using log2ram, now persistent after reboot
- [SSH access disabled by default](https://community.openenergymonitor.org/t/emonpi-ssh-disabled-by-default/8847), long press emonPi LCD push button for 5s to enable. Or create file `/boot/ssh` in FAT partition.

**Kernel**
```
$ uname -a
Linux emonpi 5.10.17-v7+ #1421 SMP Thu May 27 13:59:01 BST 2021 armv7l GNU/Linux

$ sudo /opt/vc/bin/vcgencmd version
May 27 2021 14:04:13 
Copyright (c) 2012 Broadcom
version 7d9a298cda813f747b51fe17e1e417e7bf5ca94d (clean) (release) (start)

```
**File System**
```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       4.1G  2.1G  1.9G  52% /
devtmpfs        430M     0  430M   0% /dev
tmpfs           463M     0  463M   0% /dev/shm
tmpfs           463M   47M  416M  11% /run
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs           463M     0  463M   0% /sys/fs/cgroup
tmpfs            30M     0   30M   0% /tmp
tmpfs           1.0M     0  1.0M   0% /var/tmp
tmpfs           1.0M  4.0K 1020K   1% /var/lib/php/sessions
/dev/mmcblk0p3  9.9G  1.8G  7.6G  20% /var/opt/emoncms
/dev/mmcblk0p1  253M   48M  205M  19% /boot
log2ram          50M  4.2M   46M   9% /var/log
tmpfs            93M     0   93M   0% /run/user/1000

```
**Emoncms**

```
Server Information
-----------------------

Services
	emonhub :	 Active Running                  
	emoncms_mqtt :	 Active Running                  
	feedwriter :	 Active Running - sleep 300s 0 feed points pending write
	service-runner :	 Active Running                  
	emonPiLCD :	 Failed Failed                  
	redis-server :	 Active Running                  
	mosquitto :	 Active Running                  
	demandshaper :	 Active Running                  
Emoncms
	Version :	 low-write 10.8.1
	Git :	 
		URL :	 https://github.com/emoncms/emoncms.git
		Branch :	 * stable
		Describe :	 10.8.1
	Components :	 Emoncms Core v10.8.1 | App v2.3.2 | EmonHub Config v2.1.1 | Dashboard v2.1.5 | Device v2.1.2 | Graph v2.1.1 | Network Setup v1.0.2 | WiFi v2.1.0 | Backup v2.3.2 | DemandShaper v2.2.2 | Postprocess v2.2.2 | Sync v2.1.1 | Usefulscripts v2.3.7 | EmonScripts v1.3.9 | RFM2Pi v1.4.1 | Avrdude-rpi v1.0.0 | Emonhub v2.3.1 | EmonPi v2.9.4

Server
	OS :	 Linux 5.10.17-v7+
	Host :	 emonpi | emonpi | (192.168.1.120)
	Date :	 2021-09-21 17:51:13 BST
	Uptime :	 17:51:13 up 54 days, 18:53,  1 user,  load average: 0.61, 0.48, 0.48

Memory
	RAM :	 Used: 20.02%
		Total :	 924.21 MB
		Used :	 185 MB
		Free :	 739.21 MB
	Swap :	 Used: 0.00%
		Total :	 100 MB
		Used :	 0 B
		Free :	 100 MB
Write Load Period
Disk
	/ :	 Used: 49.40%
		Total :	 4.07 GB
		Used :	 2.01 GB
		Free :	 1.86 GB
		Write Load :	 814.53 B/s (26 days 20 hours 33 mins)
	/var/opt/emoncms :	 Used: 18.06%
		Total :	 9.84 GB
		Used :	 1.78 GB
		Free :	 7.56 GB
		Write Load :	 295.85 B/s (26 days 20 hours 33 mins)
	/boot :	 Used: 18.90%
		Total :	 252.05 MB
		Used :	 47.65 MB
		Free :	 204.4 MB
		Write Load :	 0.01 B/s (26 days 20 hours 33 mins)
	/var/log :	 Used: 8.30%
		Total :	 50 MB
		Used :	 4.15 MB
		Free :	 45.85 MB
		Write Load :	 n/a

HTTP
	Server :	 Apache/2.4.38 (Raspbian) HTTP/1.1 CGI/1.1 80

MySQL
	Version :	 5.5.5-10.3.29-MariaDB-0+deb10u1
	Host :	 127.0.0.1 (127.0.0.1)
	Date :	 2021-09-21 17:51:13 (UTC 01:00‌​)
	Stats :	 Uptime: 4733656  Threads: 12  Questions: 281610  Slow queries: 0  Opens: 60  Flush tables: 1  Open tables: 53  Queries per second avg: 0.059

Redis
	Version :	 
		Redis Server :	 5.0.3
		PHP Redis :	 5.3.4
	Host :	 localhost:6379
	Size :	 408 keys (787.93K)
	Uptime :	 54 days
MQTT Server
	Version :	 Mosquitto 1.5.7
	Host :	 localhost:1883 (127.0.0.1)

PHP
	Version :	 7.3.29-1~deb10u1 (Zend Version 3.3.29)
	Modules :	 apache2handlercalendar Core ctype curl date dom v20031129exif fileinfo filter ftp gd gettext hash iconv json v1.7.0libxml mbstring mosquitto v0.4.0mysqli mysqlnd vmysqlnd 5.0.12-dev - 20150407 - $Id: 7cc7cc96e675f6d72e5cf0f267f48e167c2abb23 $openssl pcre PDO pdo_mysql Phar posix readline redis v5.3.4Reflection session shmop SimpleXML sockets sodium SPL standard sysvmsg sysvsem sysvshm tokenizer wddx xml xmlreader xmlwriter xsl Zend OPcache zlib 
Pi
	Model :	 Raspberry Pi 3 Model B Rev 1.2 - 1GB (Sony UK)
	Serial num. :	 B6918B05
	CPU Temperature :	 49.39°C
	GPU Temperature :	 48.3°C
	emonpiRelease :	 emonSD-21Jul21
	File-system :	 read-write

Client Information
-----------------------

HTTP
	Browser :	 Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/92.0
	Language :	 en-GB,en;q=0.5

Window
	Size :	 1836 x 898

Screen
	Resolution :	 1920 x 1080

```
</details>

<details>
<summary><b>emonSD-08May21</b></summary>

**Download (1.7 GB)**

- [UK Server](https://openenergymonitor.org/files/emonSD-08May21.zip)

(eligible for updates)
```
(.zip) MD5: 82e2ba6a281db539dc1e814b96b4b37b
```
- Built using EmonScripts emoncms installation script, see<br> [https://github.com/openenergymonitor/EmonScripts](https://github.com/openenergymonitor/EmonScripts).
- Based on Debian Raspberry Pi OS (32-bit) Lite, 2021-03-04
- Compatible with Raspberry Pi 3, 3B+ & 4
- Emoncms data is logged to low-write ext2 partition mounted in `/var/opt/emoncms`
- Log partition `/var/log` mounted as tmpfs using log2ram, now persistent after reboot
- [SSH access disabled by default](https://community.openenergymonitor.org/t/emonpi-ssh-disabled-by-default/8847), long press emonPi LCD push button for 5s to enable. Or create file `/boot/ssh` in FAT partition.

</details>


<details>
<summary><b>emonSD-24Jul20</b></summary>

**Download (1.4 GB)**

- [UK Server](https://openenergymonitor.org/files/emonSD-24Jul20.img.zip)

(eligible for updates)
```
(.img) MD5: 1db713787a1f3469fc3a1027767fd607
(.zip) MD5: a160f746595872d30b735ab17e8a0b1c
```
- Built using EmonScripts emoncms installation script, see<br> [https://github.com/openenergymonitor/EmonScripts](https://github.com/openenergymonitor/EmonScripts).
- Based on Debian Raspberry Pi OS (32-bit) Lite, 2020-05-27
- Compatible with Raspberry Pi 3, 3B+ & 4
- Emoncms data is logged to low-write ext2 partition mounted in `/var/opt/emoncms`
- Log partition `/var/log` mounted as tmpfs using log2ram, now persistent after reboot
- [SSH access disabled by default](https://community.openenergymonitor.org/t/emonpi-ssh-disabled-by-default/8847), long press emonPi LCD push button for 5s to enable. Or create file `/boot/ssh` in FAT partition.

**Kernel**
```
$ uname -a
Linux emonpi 5.4.51-v7l+ #1333 SMP Mon Aug 10 16:51:40 BST 2020 armv7l GNU/Linux

$ sudo /opt/vc/bin/vcgencmd version
Aug  6 2020 16:22:25 
Copyright (c) 2012 Broadcom
version af3edc2de473197cdfe1ff5a8ff2d34095d5b336 (clean) (release) (start)
```
**File System**
```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       4.1G  2.0G  1.9G  52% /
devtmpfs        299M     0  299M   0% /dev
tmpfs           428M     0  428M   0% /dev/shm
tmpfs           428M  5.9M  422M   2% /run
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs           428M     0  428M   0% /sys/fs/cgroup
tmpfs           1.0M   12K 1012K   2% /var/lib/php/sessions
tmpfs           1.0M     0  1.0M   0% /var/tmp
tmpfs            30M   16K   30M   1% /tmp
/dev/mmcblk0p1  253M   54M  199M  22% /boot
/dev/mmcblk0p3   10G  5.3M  9.5G   1% /var/opt/emoncms
log2ram          50M  2.1M   48M   5% /var/log
tmpfs            86M     0   86M   0% /run/user/1000
```
**Emoncms**

```
Server Information
-----------------------

Services
	emonhub :	 Active Running
	emoncms_mqtt :	 Active Running
	feedwriter :	 Active Running - sleep 300s 533 feed points pending write
	service-runner :	 Active Running
	emonPiLCD :	 Active Running
	redis-server :	 Active Running
	mosquitto :	 Active Running
	demandshaper :	 Activating Auto-restart

Emoncms
	Version :	 low-write 10.2.5
	Modules :	 Administration | App v2.1.6 | Backup v2.2.4 | EmonHub Config v2.0.5 | Dashboard v2.0.8 | DemandShaper v1.2.6 | Device v2.0.6 | EventProcesses | Feed | Graph v2.0.9 | Input | Postprocess v2.1.4 | CoreProcess | Schedule | Network Setup v1.0.0 | sync | Time | User | Visualisation | WiFi v2.0.3
	Git :	 
		URL :	 https://github.com/emoncms/emoncms.git
		Branch :	 * stable
		Describe :	 10.2.5

Server
	OS :	 Linux 5.4.51-v7l+
	Host :	 emonpi | emonpi | (192.168.1.64)
	Date :	 2020-08-24 14:07:33 BST
	Uptime :	 14:07:33 up 51 min,  1 user,  load average: 0.19, 0.12, 0.21

Memory
	RAM :	 Used: 21.84%
		Total :	 855.19 MB
		Used :	 186.82 MB
		Free :	 668.38 MB
	Swap :	 Used: 0.75%
		Total :	 100 MB
		Used :	 768 KB
		Free :	 99.25 MB
Write Load Period
Disk
	/ :	 Used: 49.08%
		Total :	 4.06 GB
		Used :	 1.99 GB
		Free :	 1.87 GB
		Write Load :	 63.14 B/s (33 mins)
	/boot :	 Used: 21.15%
		Total :	 252.05 MB
		Used :	 53.32 MB
		Free :	 198.73 MB
		Write Load :	 0 B/s (33 mins)
	/var/opt/emoncms :	 Used: 8.13%
		Total :	 9.84 GB
		Used :	 819.75 MB
		Free :	 8.54 GB
		Write Load :	 360.51 B/s (33 mins)
	/var/log :	 Used: 4.04%
		Total :	 50 MB
		Used :	 2.02 MB
		Free :	 47.98 MB
		Write Load :	 n/a

HTTP
	Server :	 Apache/2.4.38 (Raspbian) HTTP/1.1 CGI/1.1 80

MySQL
	Version :	 5.5.5-10.3.23-MariaDB-0+deb10u1
	Host :	 localhost:6379 (127.0.0.1)
	Date :	 2020-08-24 14:07:33 (UTC 01:00‌​)
	Stats :	 Uptime: 2895  Threads: 12  Questions: 4079  Slow queries: 0  Opens: 57  Flush tables: 1  Open tables: 51  Queries per second avg: 1.408

Redis
	Version :	 
		Redis Server :	 5.0.3
		PHP Redis :	 5.3.1
	Host :	 localhost:6379
	Size :	 514 keys (849.12K)
	Uptime :	 4 days
MQTT Server
	Version :	 Mosquitto 1.5.7
	Host :	 localhost:1883 (127.0.0.1)

PHP
	Version :	 7.3.19-1~deb10u1 (Zend Version 3.3.19)
	Modules :	 apache2handlercalendar Core ctype curl date dom v20031129exif fileinfo filter ftp gd gettext hash iconv json v1.7.0libxml mbstring mosquitto v0.4.0mysqli mysqlnd vmysqlnd 5.0.12-dev - 20150407 - $Id: 7cc7cc96e675f6d72e5cf0f267f48e167c2abb23 $openssl pcre PDO pdo_mysql Phar posix readline redis v5.3.1Reflection session shmop SimpleXML sockets sodium SPL standard sysvmsg sysvsem sysvshm tokenizer wddx xml xmlreader xmlwriter xsl Zend OPcache zlib 
Pi
	Model :	 Raspberry Pi 4 Model B Rev 1.1 - 1GB (Sony UK)
	Serial num. :	 10000000EA26C808
	CPU Temperature :	 49.17°C
	GPU Temperature :	 49.0°C
	emonpiRelease :	 emonSD-24Jul20
	File-system :	 read-write

```
</details>


<details>
<summary><b>emonSD-17Oct19</b></summary>

[Forum Thread](https://community.openenergymonitor.org/t/emonsd-17oct19-release/12231)

**Download (1.1 GB)**

- [UK Server](http://files.openenergymonitor.org/emonSD-17Oct19.img.zip)
- [Canada Server](https://distanthost.com/oem/emonSD-17Oct19.img.zip)

(eligible for updates)
```
(.img) MD5: a7d12ac6b589ae0d470c4a6f1ce38414
(.zip) MD5: 52ecf81c2ad4afbd9da42a6e703b5c59
```
- Built using EmonScripts emoncms installation script, see<br> [https://github.com/openenergymonitor/EmonScripts](https://github.com/openenergymonitor/EmonScripts).
- Based on Debian Raspbian Buster minimal 
- Compatible with Raspberry Pi 3, 3B+ & 4
- Emoncms data is logged to low-write ext2 partition mounted in `/var/opt/emoncms`
- Log partition `/var/log` mounted as tmpfs using log2ram, now persistent after reboot
- [SSH access disabled by default](https://community.openenergymonitor.org/t/emonpi-ssh-disabled-by-default/8847), long press emonPi LCD push button for 5s to enable. Or create file `/boot/ssh` in FAT partition.

\* To use this image on Pi2 remove the following lines from `/boot/config.txt`:

```
arm_freq=1200
arm_freq_min=600
```

**Kernel**
```
$ uname -a
Linux emonpi 4.19.75-v7+ #1270 SMP Tue Sep 24 18:45:11 BST 2019 armv7l GNU/Linux

$ sudo /opt/vc/bin/vcgencmd version
Sep 24 2019 17:37:47 
Copyright (c) 2012 Broadcom
version 6820edeee4ef3891b95fc01cf02a7abd7ca52f17 (clean) (release) (start_cd)
```
**File System**
```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       4.0G  1.9G  2.0G  49% /
devtmpfs        484M     0  484M   0% /dev
tmpfs           488M     0  488M   0% /dev/shm
tmpfs           488M  6.6M  482M   2% /run
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs           488M     0  488M   0% /sys/fs/cgroup
tmpfs           1.0M  4.0K 1020K   1% /var/lib/php/sessions
tmpfs           1.0M     0  1.0M   0% /var/tmp
tmpfs            30M   16K   30M   1% /tmp
/dev/mmcblk0p3   10G  5.3M  9.5G   1% /var/opt/emoncms
/dev/mmcblk0p1  253M   52M  201M  21% /boot
log2ram          50M  2.1M   48M   5% /var/log
tmpfs            98M     0   98M   0% /run/user/1000

```
**Emoncms**

```
Server Information
-----------------------

Emoncms
	Version :	 low-write 10.1.9
	Modules :	 Administration | App v2.0.7 | Backup v2.1.4 | EmonHub Config v2.0.4 | Dashboard v2.0.5 | DemandShaper v1.0.2 | Device v2.0.2 | EventProcesses | Feed | Graph v2.0.5 | Input | Postprocess v2.1.1 | CoreProcess | Schedule | Network Setup v1.0.0 | sync | Time | User | Visualisation | WiFi v2.0.2
	Git :	 
		URL :	 https://github.com/emoncms/emoncms.git
		Branch :	 * stable
		Describe :	 10.1.9

Server
	OS :	 Linux 4.19.75-v7+
	Host :	 emonpi | emonpi | (192.168.0.109)
	Date :	 2019-10-17 13:10:53 BST
	Uptime :	 13:10:53 up 15 min,  1 user,  load average: 0.10, 0.11, 0.09

Memory
	RAM :	 Used: 19.37%
		Total :	 975.62 MB
		Used :	 188.99 MB
		Free :	 786.63 MB
	Swap :	 Used: 0.00%
		Total :	 100 MB
		Used :	 0 B
		Free :	 100 MB

Disk
	/ :	 Used: 46.42%
		Total :	 3.92 GB
		Used :	 1.82 GB
		Free :	 1.91 GB
		Write Load :	 n/a
	/var/opt/emoncms :	 Used: 0.05%
		Total :	 9.98 GB
		Used :	 5.27 MB
		Free :	 9.47 GB
		Write Load :	 n/a
	/boot :	 Used: 20.55%
		Total :	 252.05 MB
		Used :	 51.79 MB
		Free :	 200.26 MB
		Write Load :	 n/a
	/var/log :	 Used: 4.20%
		Total :	 50 MB
		Used :	 2.1 MB
		Free :	 47.9 MB
		Write Load :	 n/a

HTTP
	Server :	 Apache/2.4.38 (Raspbian) HTTP/1.1 CGI/1.1 80

MySQL
	Version :	 5.5.5-10.3.17-MariaDB-0+deb10u1
	Host :	 localhost:6379 (127.0.0.1)
	Date :	 2019-10-17 13:10:52 (UTC 01:00‌​)
	Stats :	 Uptime: 899  Threads: 14  Questions: 1757  Slow queries: 0  Opens: 70  Flush tables: 1  Open tables: 36  Queries per second avg: 1.954

Redis
	Version :	 
		Redis Server :	 5.0.3
		PHP Redis :	 5.0.2
	Host :	 localhost:6379
	Size :	 114 keys (810.42K)
	Uptime :	 0 days
MQTT Server
	Version :	 Mosquitto 1.5.7
	Host :	 localhost:1883 (127.0.0.1)

PHP
	Version :	 7.3.9-1~deb10u1 (Zend Version 3.3.9)
	Modules :	 apache2handler | calendar v7.3.9-1~deb10u1 | Core v7.3.9-1~deb10u1 | ctype v7.3.9-1~deb10u1 | curl v7.3.9-1~deb10u1 | date v7.3.9-1~deb10u1 | dom v20031129 | exif v7.3.9-1~deb10u1 | fileinfo v7.3.9-1~deb10u1 | filter v7.3.9-1~deb10u1 | ftp v7.3.9-1~deb10u1 | gd v7.3.9-1~deb10u1 | gettext v7.3.9-1~deb10u1 | hash v7.3.9-1~deb10u1 | iconv v7.3.9-1~deb10u1 | json v1.7.0 | libxml v7.3.9-1~deb10u1 | mbstring v7.3.9-1~deb10u1 | mosquitto v0.4.0 | mysqli v7.3.9-1~deb10u1 | mysqlnd vmysqlnd 5.0.12-dev - 20150407 - $Id: 7cc7cc96e675f6d72e5cf0f267f48e167c2abb23 $ | openssl v7.3.9-1~deb10u1 | pcre v7.3.9-1~deb10u1 | PDO v7.3.9-1~deb10u1 | pdo_mysql v7.3.9-1~deb10u1 | Phar v7.3.9-1~deb10u1 | posix v7.3.9-1~deb10u1 | readline v7.3.9-1~deb10u1 | redis v5.0.2 | Reflection v7.3.9-1~deb10u1 | session v7.3.9-1~deb10u1 | shmop v7.3.9-1~deb10u1 | SimpleXML v7.3.9-1~deb10u1 | sockets v7.3.9-1~deb10u1 | sodium v7.3.9-1~deb10u1 | SPL v7.3.9-1~deb10u1 | standard v7.3.9-1~deb10u1 | sysvmsg v7.3.9-1~deb10u1 | sysvsem v7.3.9-1~deb10u1 | sysvshm v7.3.9-1~deb10u1 | tokenizer v7.3.9-1~deb10u1 | wddx v7.3.9-1~deb10u1 | xml v7.3.9-1~deb10u1 | xmlreader v7.3.9-1~deb10u1 | xmlwriter v7.3.9-1~deb10u1 | xsl v7.3.9-1~deb10u1 | Zend OPcache v7.3.9-1~deb10u1 | zlib v7.3.9-1~deb10u1

Pi
	Model :	 Raspberry Pi 3 Model B+ Rev 1.3 - 1GB (Sony UK)
	Serial num. :	 78A9D9F
	Temperature :	 48.31°C - 47.8°C
	emonpiRelease :	 emonSD-17Oct19
	File-system :	 read-write
```
</details>

<details>
<summary><b>emonSD-30Oct18</b></summary>

**Download (1.2GB)**

- [UK Server](http://files.openenergymonitor.org/emonSD-30Oct18.zip)
- [Canada Server](http://distanthost.com/oem/emonSD-30Oct18.zip)

Following the [release of emonSD-24Jul20](https://community.openenergymonitor.org/t/emonsd-24jul20-release/15170), this version is no longer eligible for updates. For more details see the [release notes](https://community.openenergymonitor.org/t/emonsd-24jul20-release/15170).

```
(.img) MD5: eb24460efcd8af7bc568415002581649
(.zip) MD5: 0c6cbfc59403ba536ad7c0120bb687e5
```

- Based on Debian Raspbian Stretch minimal 
- Compatible with Raspberry Pi 3 & 3B+ (minor change required for Pi2*)
- [No longer use read-only root file system](https://community.openenergymonitor.org/t/new-emonsd-dropping-read-only-root-filesystem-requirement/8293)
- Emoncms data is logged to low-write ext2 partition mounted in `~/data`
- Log partition `/var/log` mounted as tmpfs, non-persistent between boots
- [SSH access disabled by default](https://community.openenergymonitor.org/t/emonpi-ssh-disabled-by-default/8847), long press emonPi LCD push button for 5s to enable. Or create file `/boot/ssh` in FAT partition.
- OpenHAB & NodeRED removed, can easily be installed via apt-get

\* To use this image on Pi2 remove the following lines from `/boot/config.txt` :

```
arm_freq=1200
arm_freq_min=600
```

**Kernel**
```
$ uname -a
Linux emonpi 4.14.71-v7+ #1145 SMP Fri Sep 21 15:38:35 BST 2018 armv7l GNU/Linux
$ sudo /opt/vc/bin/vcgencmd version
Sep 21 2018 15:44:25 
Copyright (c) 2012 Broadcom
version 07f57128b8491ffdefcdfd13f7b4961b3006d9a9 (clean) (release)
```
**File System**
```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       3.9G  1.6G  2.2G  42% /
devtmpfs        484M     0  484M   0% /dev
tmpfs           489M     0  489M   0% /dev/shm
tmpfs           489M   13M  476M   3% /run
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs           489M     0  489M   0% /sys/fs/cgroup
tmpfs           1.0M     0  1.0M   0% /var/tmp
tmpfs            50M 1004K   50M   2% /var/log
tmpfs            30M     0   30M   0% /tmp
/dev/mmcblk0p1   43M   22M   21M  52% /boot
/dev/mmcblk0p3  3.3G  113M  3.0G   4% /home/pi/data
tmpfs            98M     0   98M   0% /run/user/1000
```
**Emoncms**

```
<details><summary>Server Information</summary><pre>

| | | |
| --- | --- | --- |
|Emoncms|Version|low-write 9.9.3
||Modules|Administration : App v1.2.0 : Backup v1.1.5 : EmonHub Config v1.0.0 : Dashboard v1.3.1 : Device v1.1.1 : EventProcesses : Feed : Graph v1.2.1 : Input : Postprocess v1.0.0 : CoreProcess : Schedule : Network Setup v1.0.0 : sync : Time : User : Visualisation : WiFi v1.3.0
||Git URL|https://github.com/emoncms/emoncms.git
||Git Branch|* stable
||Buffer|<span id="bufferused">loading...</span>
||Writer|Daemon is running with sleep 60s
|Server|OS|Linux 4.14.71-v7+
||Host|emonpi emonpi (192.168.86.36)
||Date|2018-10-30 01:34:56 UTC
||Uptime| 01:34:56 up 27 min,  1 user,  load average: 1.75, 1.59, 1.34
|HTTP|Server|Apache/2.4.25 (Raspbian) HTTP/1.1 CGI/1.1 80
|MySQL|Version|5.5.5-10.1.23-MariaDB-9+deb9u1
||Host|127.0.0.1 (127.0.0.1)
||Date|2018-10-30 01:34:56 (UTC 00:00‌)
||Stats|Uptime: 1667  Threads: 3  Questions: 68  Slow queries: 0  Opens: 23  Flush tables: 1  Open tables: 17  Queries per second avg: 0.040
|Redis|Version|3.2.6
||Host|localhost:6379 (127.0.0.1)
||Size|<span id="redisused">44 keys  (840.02K)</span>
||Uptime|0 days
|MQTT Server|Version|Mosquitto 1.4.10
||Host|localhost:1883 (127.0.0.1)
|Pi|Model|Raspberry Pi 3 Model B Rev 1.2 - 1 GB (Stadium)
||SoC|Broadcom BCM2835
||Serial num.|68D8124E
||Temperature|CPU: 49.39°C - GPU: 49.4'C
||Release|emonSD-30Oct18
||File-system|Current: read-write - Set root file-system temporarily to read-write, (default read-only) 
|Memory|RAM|Used: 15.91% Total: 976.74 MB Used: 155.45 MB Free: 821.29 MB
||Swap|Used: 0.00% Total: 100 MB Used: 0 B Free: 100 MB
|Disk|Mount|Stats
||/|Used: 39.77% Total: 3.81 GB Used: 1.52 GB Free: 2.12 GB
||/boot|Used: 51.69% Total: 42.52 MB Used: 21.98 MB Free: 20.54 MB
||/home/pi/data|Used: 3.43% Total: 3.21 GB Used: 112.78 MB Free: 2.93 GB
|PHP|Version|7.0.30-0+deb9u1 (Zend Version 3.0.0)
||Modules|apache2handler : calendar v7.0.30-0+deb9u1 : Core v7.0.30-0+deb9u1 : ctype v7.0.30-0+deb9u1 : curl v7.0.30-0+deb9u1 : date v7.0.30-0+deb9u1 : dom v20031129 : exif v7.0.30-0+deb9u1 : fileinfo v1.0.5 : filter v7.0.30-0+deb9u1 : ftp v7.0.30-0+deb9u1 : gd v7.0.30-0+deb9u1 : gettext v7.0.30-0+deb9u1 : hash v1.0 : iconv v7.0.30-0+deb9u1 : igbinary v2.0.1 : json v1.4.0 : libxml v7.0.30-0+deb9u1 : mbstring v7.0.30-0+deb9u1 : mcrypt v7.0.30-0+deb9u1 : mosquitto v0.4.0 : mysqli v7.0.30-0+deb9u1 : mysqlnd vmysqlnd 5.0.12-dev - 20150407 - $Id: b5c5906d452ec590732a93b051f3827e02749b83 $ : openssl v7.0.30-0+deb9u1 : pcre v7.0.30-0+deb9u1 : PDO v7.0.30-0+deb9u1 : pdo_mysql v7.0.30-0+deb9u1 : Phar v2.0.2 : posix v7.0.30-0+deb9u1 : readline v7.0.30-0+deb9u1 : redis v4.1.1 : Reflection v7.0.30-0+deb9u1 : session v7.0.30-0+deb9u1 : shmop v7.0.30-0+deb9u1 : SimpleXML v7.0.30-0+deb9u1 : sockets v7.0.30-0+deb9u1 : SPL v7.0.30-0+deb9u1 : standard v7.0.30-0+deb9u1 : sysvmsg v7.0.30-0+deb9u1 : sysvsem v7.0.30-0+deb9u1 : sysvshm v7.0.30-0+deb9u1 : tokenizer v7.0.30-0+deb9u1 : wddx v7.0.30-0+deb9u1 : xml v7.0.30-0+deb9u1 : xmlreader v7.0.30-0+deb9u1 : xmlwriter v7.0.30-0+deb9u1 : xsl v7.0.30-0+deb9u1 : Zend OPcache v7.0.30-0+deb9u1 : zlib v7.0.30-0+deb9u1
</pre></details>
```

**Known Issues**

- Current bug in rpi-gpio 0.6.4 causes LCD push button to stop working, a solution is to continue using 0.6.3 `pip install RPi.GPIO==0.6.3`. [Open issue](https://github.com/RPi-Distro/python-gpiozero/issues/687).
- Mosquitto 1.4.10 is included in this release, this is a downgrade from 1.4.14 included in the previous image (emonSD-26Oct17). This is because 1.4.10 is the current stable Stretch apt release. A newer version can be manually installed if required https://mosquitto.org/download/
</details>

<details>
<summary><b>emonSD-26Oct17</b></summary>

[Download (1.4GB)](http://files.openenergymonitor.org/emonSD-26Oct17.img.zip)

Following the [release of emonSD-24Jul20](https://community.openenergymonitor.org/t/emonsd-24jul20-release/15170), this version is no longer eligible for updates. For more details see the [release notes](https://community.openenergymonitor.org/t/emonsd-24jul20-release/15170).

```
(.img) MD5: 88f8ff9a5f7bc0e9b07012895a5cdd95
(.zip) MD5: 6726564f379d0127052e8c30a3ffa534 
```
New changes compared with previous release, [SD-card-build.md](https://github.com/openenergymonitor/emonpi/blob/master/docs/SD-card-build.md) has been updated:

- Based on Debian Raspbian Jessie minimal, updated to latest packages, kernel and firmware. Includes patch for [KRACK WPA vulnerability](https://www.krackattacks.com/):
- Compatible with Raspberry Pi 2/3 (not zero or 3B+)

```
$ uname -a
Linux emonpi 4.9.35-v7+ #1014 SMP Fri Jun 30 14:47:43 BST 2017 armv7l GNU/Linux
$ sudo /opt/vc/bin/vcgencmd version
Jul  3 2017 14:17:30 
version 4139c62f14cafdb7d918a3eaa0dbd68cf434e0d8 (tainted) (release)
```
- Automatic NTP time update: see [forum thread](https://community.openenergymonitor.org/t/emontx-communication-with-rpi/3659/2) and [changes](https://github.com/openenergymonitor/emonpi/commit/0081b6d4724cb2a1445adc22eef777fd1aa3797c).
- Fix random seed: improved HTTPS / SSH security. See [forum thread](https://community.openenergymonitor.org/t/random-seed/3637).
- Use `dtoverlay=pi3-miniuart-bt` instead of `dtoverlay=pi3-disable-bt` in `/boot/config.txt`
This re-maps RasPi3 bluetooth to software serial`/dev/ttyS0` instead of disabling it. 

**File System**

*4GB min SD card (8GB+ recommended). If SD card is larger than 4GB, expand `data` partition with `sudo emonSDexpand`*

```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       3.4G  2.0G  1.2G  63% /
devtmpfs        481M     0  481M   0% /dev
tmpfs           486M     0  486M   0% /dev/shm
tmpfs           486M  6.6M  479M   2% /run
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs           486M     0  486M   0% /sys/fs/cgroup
tmpfs            40M  6.1M   34M  16% /var/lib/openhab
tmpfs           1.0M  4.0K 1020K   1% /var/lib/dhcpcd5
/dev/mmcblk0p1   60M   22M   39M  37% /boot
tmpfs           1.0M     0  1.0M   0% /var/lib/dhcp
tmpfs            50M  480K   50M   1% /var/log
tmpfs            30M  152K   30M   1% /tmp
/dev/mmcblk0p3  3.5G   39M  1000M  2% /home/pi/data
```
**Emoncms Server Information**

```
Emoncms	Version	low-write 9.8.10 | 2017.08.17
Modules	Administration | App v1.0.0 | Backup v1.0.0 | EmonHub Config v1.0.0 | Dashboard v1.1.1 | EventProcesses | Feed | Graph v1.0.0 | Input | postprocess | CoreProcess | Schedule | setup | Time | User | Visualisation | WiFi v1.0.0
Buffer	0 feed points pending write
Writer	Daemon is running with sleep 60s
Server	OS	Linux 4.9.35-v7+
Host	emonpi emonpi (127.0.1.1)
Date	2017-10-27 16:04:08 UTC
Uptime	16:04:08 up 6 min, 1 user, load average: 0.09, 0.17, 0.09
HTTP	Server	Apache/2.4.10 (Raspbian) HTTP/1.1 CGI/1.1 80
Database	Version	MySQL 5.5.57-0+deb8u1
Host	localhost (127.0.0.1)
Date	2017-10-27 16:04:08 (UTC 00:00‌)
Stats	Uptime: 82668 Threads: 3 Questions: 196 Slow queries: 0 Opens: 59 Flush tables: 1 Open tables: 51 Queries per second avg: 0.002
Redis	Version	2.8.17
Host	localhost:6379 (127.0.0.1)
Size	13 keys (473.56K)Flush
Uptime	0 days
MQTT	Version	1.4.14
Host	localhost:1883 (127.0.0.1)
Pi	CPU Temp	40.78°CShutdownReboot
Release	emonSD-26Oct17
File-system	Set root file-system temporarily to read-write, (default read-only)Read-Write Read-Only
Memory	RAM	
Used 25.03%
Total: 970.93 MB Used: 242.99 MB Free: 727.94 MB
Disk	Mount	Stats
/	
Used 59.18%
Total: 3.33 GB Used: 1.97 GB Free: 1.2 GB
/boot	
Used 36.32%
Total: 59.95 MB Used: 21.77 MB Free: 38.17 MB
/home/pi/data	
Used 1.09%
Total: 3.46 GB Used: 38.69 MB Free: 3.25 GB
PHP	Version	5.6.30-0+deb8u1 (Zend Version 2.6.0)
Modules	apache2handler | bcmath | bz2 | calendar | Core v5.6.30-0+deb8u1 | ctype | curl | date v5.6.30-0+deb8u1 | dba | dio v0.0.4RC4 | dom v20031129 | ereg | exif v1.4 | fileinfo v1.0.5 | filter v0.11.0 | ftp | gettext | hash v1.0 | iconv | json v1.3.6 | libxml | mbstring | mcrypt | mhash | mosquitto v0.3.0 | mysql v1.0 | mysqli v0.1 | openssl | pcre | PDO v1.0.4dev | pdo_mysql v1.0.2 | Phar v2.0.2 | posix | readline v5.6.30-0+deb8u1 | redis v2.2.7 | Reflection | session | shmop | SimpleXML v0.1 | soap | sockets | SPL v0.2 | standard v5.6.30-0+deb8u1 | sysvmsg | sysvsem | sysvshm | tokenizer v0.1 | wddx | xml | xmlreader v0.1 | xmlwriter v0.1 | Zend OPcache v7.0.6-devFE | zip v1.12.5 | zlib v2.0 | 
```
</details>

<details>
<summary><b>emonSD-07Nov16</b></summary>

**RELEASE**

[Download (824MB)](http://files.openenergymonitor.org/emonSD-07Nov16.zip) | [Mirror 1 (Canada)](http://www.distanthost.com/oem/emonSD-07Nov16.zip)

Following the [release of emonSD-24Jul20](https://community.openenergymonitor.org/t/emonsd-24jul20-release/15170), this version is no longer eligible for updates. For more details see the [release notes](https://community.openenergymonitor.org/t/emonsd-24jul20-release/15170).

[Forum Discussion](https://community.openenergymonitor.org/t/emonsd-07nov16-beta/2137?u=glyn.hudson)

```
(.img) MD5: cf8537e90ffd98ffb5838fbe3c878d4d
(.zip) MD5: 3961e96cf2e1ab46d750d0a0cae72a2e 
```

**File System**

*4GB min SD card (8GB+ recommended). If SD card is larger than 4GB, expand `data` partition with `sudo emonSDexpand`*
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/root       3.4G  2.1G  1.2G  64% /
devtmpfs        483M     0  483M   0% /dev
tmpfs           487M     0  487M   0% /dev/shm
tmpfs           487M  6.6M  480M   2% /run
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs           487M     0  487M   0% /sys/fs/cgroup
tmpfs            40M  3.8M   37M  10% /var/lib/openhab
tmpfs           1.0M  4.0K 1020K   1% /var/lib/dhcpcd5
tmpfs           1.0M     0  1.0M   0% /var/lib/dhcp
tmpfs            50M  328K   50M   1% /var/log
tmpfs            30M   52K   30M   1% /tmp
/dev/mmcblk0p1   60M   21M   40M  35% /boot
/dev/mmcblk0p3  194M   37M  147M  21% /home/pi/data
```

**Linux**
* Update Linux kernal to at least 4.4.26-v7+ to get latest security & raspi firmware fixes (e.g. Dirty Cow) (dist-upgrade) [forum topic](https://community.openenergymonitor.org/t/dirty-cow-vulnerability/2010/2)
* `$ apt-get clean all` (free up unused packages, approx 700Mb)

**Emoncms**
* Latest Emoncms (currently V9.7.7)
 * New graph module
 * Lots of dashboard fixes and improvements

**emonPi**
* Remove personal GitHub credentials 
* Fix Mosquitto MQTT server hanging after V1.4.10 update [forum thread](https://community.openenergymonitor.org/t/mqtt-log-files/1597/6)
* [Add bash prompt RW indicator](https://community.openenergymonitor.org/t/increase-emonsd-pre-built-sd-card-to-8gb-min/1730/12?u=glyn.hudson), add to ` /etc/bash.bashrc` 
* Install [emonUpload](https://github.com/openenergymonitor/emonupload) to enable easier user emonTx, emonTH firmware updates
* Updated [motd](https://github.com/openenergymonitor/emonpi/blob/master/motd)
* [PlatformIO](https://platformio.org) installed for on-device firmware compiling & updating. [See blog post](https://blog.openenergymonitor.org/2016/06/platformio/).

**nodeRED**
* Add weather underground nodeRED node + [flow example](https://github.com/openenergymonitor/oem_node-red)

**OpenHAB**
* Update to Java 8 - fix my.openhab connection issue [forum thread](https://community.openenergymonitor.org/t/openhab-problems-connecting-through-myopenhab-with-java-8/1232)
* [Disable OpenHAB Jetty server request logs](https://github.com/openenergymonitor/oem_openHab/blob/master/Readme.md#disable-request-log). Stop filling up /var/log partition.

**Emoncms Server Info**

```
Server Information
Emoncms	Version	low-write 9.7.7 | 2016.10.29
Modules	app, config, dashboard, graph, wifi
Buffer	0 feed points pending write
Writer	Daemon is running with sleep 60s
Server	OS	Linux 4.4.26-v7+
Host	emonpi emonpi (127.0.1.1)
Date	2016-11-01 00:52:38 UTC
Uptime	00:52:38 up 5 min, 1 user, load average: 0.76, 0.65, 0.31
HTTP	Server	Apache/2.4.10 (Raspbian) HTTP/1.1 CGI/1.1 80
Database	Version	MySQL 5.5.52-0+deb8u1
Host	localhost (127.0.0.1)
Date	2016-11-01 00:52:38 (UTC 00:00‌)
Stats	Uptime: 5583 Threads: 3 Questions: 1699 Slow queries: 0 Opens: 61 Flush tables: 1 Open tables: 50 Queries per second avg: 0.304
Redis	Version	2.8.17
Host	localhost:6379 (127.0.0.1)
Size	0 keys (471.91K)Flush
Uptime	0 days
MQTT	Version	1.4.10
Host	localhost:1883 (127.0.0.1)
Pi	CPU Temp	41.86°CShutdownReboot
Release	emonSD-07Nov16
Memory	RAM	
Used 25.23%
Total: 973.11 MB Used: 245.53 MB Free: 727.58 MB
Disk	Mount	Stats
/	
Used 60.45%
Total: 3.33 GB Used: 2.01 GB Free: 1.16 GB
/boot	
Used 34.67%
Total: 59.95 MB Used: 20.78 MB Free: 39.16 MB
/home/pi/data	
Used 19.04%
Total: 193.66 MB Used: 36.87 MB Free: 146.8 MB
PHP	Version	5.6.27-0+deb8u1 (Zend Version 2.6.0)
Modules	Core   date   ereg   libxml   openssl   pcre   zlib   bcmath   bz2   calendar   ctype   dba   dom   hash   fileinfo   filter   ftp   gettext   SPL   iconv   mbstring   session   posix   Reflection   standard   shmop   SimpleXML   soap   sockets   Phar   exif   sysvmsg   sysvsem   sysvshm   tokenizer   wddx   xml   xmlreader   xmlwriter   zip   apache2handler   PDO   curl   dio   json   mcrypt   mosquitto   mysql   mysqli   pdo_mysql   readline   redis   mhash   Zend OPcache  
```

By default emonSD has a number of services running. If you don't want to use them, they can be disabled with:

```
pi@emonpi:~ $ sudo systemctl disable openhab.service  
pi@emonpi:~ $ sudo systemctl disable nodered.service  
pi@emonpi:~ $ sudo systemctl disable emonPiLCD.service  
pi@emonpi:~ $ sudo systemctl disable apache2.service  
```
</details>

<details>
<summary><b>emonSD-03May16</b></summary>

[Download (1.7GB)](http://files.openenergymonitor.org/emonSD-03May16.img.zip) | [UK Mirror 1](http://217.9.195.227/files/emonSD-03May16.img.zip) | [Forum Discussion](https://community.openenergymonitor.org/t/emonsd-03may16-release/145)

```
MD5 Checksum (zip): d102aff6dafd89d2e4d3209eee964251
MD5 Checksum (.img): 08557bda1c12daa76ab94bef0c04f3fd
```

*   Based on RASPBIAN JESSIE LITE (2015-11-21) `SSH user,pass:pi,emonpi2016`
*   Linux Kernal 4.1.19-v7+
*   RasPi Firmware & packages updated to support Raspberry Pi3 & onboard Wifi ([RasPi3 BT disabled](https://blog.openenergymonitor.org/2016/03/raspberry-pi-3/))
*   Tested to work on RasPi 3, 2 Model B+, B, A and even [Pi zero](https://community.openenergymonitor.org/t/emonsd-03may16-release/145/66)!
*   Emoncms V9.5.1 | 2016.04.28 [stable branch](https://github.com/emoncms/emoncms/tree/stable)
*   emonHub [emon-pi variant](https://github.com/openenergymonitor/emonhub) - now default HTTPS to Emoncms.org
*   [MQTT LightWave RF OOK](https://github.com/openenergymonitor/lightwaverf-pi)
*   [NodeRED 13.4 - with custom OEM setup](https://github.com/openenergymonitor/oem_node-red) *port:1880* `user,pass:emonpi,emonpi2016`
*   [OpenHab 1.8.2 - with custom OEM setup](https://github.com/openenergymonitor/oem_openhab) *port:8080* `user,pass:pi,emonpi2016`
*   Mosquitto MQTT server V1.4.8 with authentication *port:1883* `user,pass:emonpi,emonpimqtt2016`
*   MYSQL `username: emoncms, password:emonpiemoncmsmysql2016` port 3306 (not open externally) 
* [GSM 3G USB modem support](https://guide.openenergymonitor.org/setup/connect/#5-connect-via-3g-gsm-optional) 

New Changes 
[forum discussion](https://openenergymonitor.org/emon/node/12566)
* Append `gpu_mem=16` to `/boot/config.txt` to give us more RAM at expense of GPU
* Symlink `fstab` in emonpi repo to `/etc/fstab` to allow updating 
* Reduce garbage in /var/log/messages but to Raspbian bug 
* Fix log rotate to includue all log files to ensure /var/log does not fill up
* RasPi3 SSHD fix
* Fix language pack support (install gettext & locales), language setting in 'Account' now works out the box 
* Fix node-RED flows to survive update cycle 
* Trim SD card (allow 60mB of unallocated partition) to fit on all (or majority) of 4GB SD cards, shop pre-built SD cards included with emonPi / emonBase will be 8GB with ~/data partition expanded accordingly. 
* Generate new SSH keys

By default emonSD has a number of services running, if you don't want to use these they can be disabled with:

```
pi@emonpi:~ $ sudo systemctl disable openhab.service  
pi@emonpi:~ $ sudo systemctl disable nodered.service  
pi@emonpi:~ $ sudo systemctl disable emonPiLCD.service  
pi@emonpi:~ $ sudo systemctl disable apache2.service  
```
</details>

<details>
<summary><b>emonSD-17Jun15</b></summary>

[Download](http://files.openenergymonitor.org/emonSD-17Jun2015.img.zip) | [Forum Thread](https://openenergymonitor.org/emon/node/10729)

*   **Shipped on all emonPi's Jun15-March16**
*   Emoncms V8 
*   2015-05-05 version of Raspbian 
*   Mosquitto MQTT with no authentication (port closed) ****
</details>


<details>
<summary><b>emonpi-28may2015</b></summary>

*   First emonPi release
*   Emoncms V8
*   Shipped with first batch of Kickstarter backer units 
*   Shipped on emonpi's May15-June15

</details>

---

## Writing the image to an SD card:

**Option 1:** We recommend using [balenaEtcher](https://www.etcher.io/) to flash the image to an SD card. See [forum discussion](https://community.openenergymonitor.org/t/using-etcher-tool-to-flash-emonsd-image-to-sd-card/1773).

**Option 2:** [Use the Raspberry Pi Imager](https://www.raspberrypi.com/software/). Select 'Use custom: Select a custom.img from your computer' and then select the emonSD image that you have just downloaded. There is no need to unzip the image first, just use the .zip file directly. **WARNING: the user name must not be changed; it must be "pi"**.

## Before bootup SSH & WiFi configuration

**Before booting up the Raspberry Pi** you may want to enable SSH and pre-configure your WiFi details on the image first. SSH provides command line access to the RaspberryPi. If you are not sure if you need this, leave it disabled for now, it can be enabled later.

Plug the SD card into your computer again and wait for the SD card partitions to load. On Linux you should see three partitions: boot, rootfs and a larger data volume. On Windows you may only see the boot partition.

**To enable SSH:** Open the boot partition and add an empty file called `ssh`.

**To configure WiFi:** add a file called `wpa_supplicant.conf` to the boot folder. Add the following template and replace the <> parts with your WiFi details:

```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=<Insert 2 letter ISO 3166-1 country code here>

network={
  ssid="<Name of your wireless LAN>"
  psk="<Password for your wireless LAN>"
}
```

Safely dismount the SD card and insert in the Raspberry Pi.

**First boot update:** If connected to the internet by Ethernet (or pre-configured WiFi), a fresh emonSD will run a full system update. It's best not to interrupt this process. Leave about 10 min before switching off or rebooting. See `/var/log/emoncms/update.log` if you want to view the update log to check if it's finished.

**WiFi Access Point:** If the SD card is booted without ethernet connected or WiFi configured it will create a WiFi access point (emonSD-10Nov22 SSID: `emonSD`, Password: `emonsd2022`) to allow scanning for a local network and configuration via the web user interface `IP address: 192.168.42.1`. The first boot update is not performed in this case and we suggest updating via the emoncms admin interfacer at a convenient time once the system is up and running.

***

## Identify Image Version

The Image version can be identified in three ways: 

**emonPi systems:** - View emonPi LCD at startup or press the LCD button the scroll through the pages until `emonSD-XX` is displayed.

**All systems: Emoncms admin interface** - view the emonSD version in the local Emoncms admin interface.

**All systems: Look for a file in /boot partition** for a file called `emonSD-XXX` in the FAT /boot partition:

```$ sudo ls /boot | grep emonSD```



