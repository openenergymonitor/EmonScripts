## EmonCMS file system

| | | |
-- | -- | --
EMONCMS_WWW | /var/www/emoncms | location of the core package and of the main modules (admin, dashboards, config)
EMONCMS_DATADIR | /var/opt/emoncms | timeseries database directories
EMONCMS_DIR | /opt/emoncms | location of symlinked modules (postprocess, sync) and of uploaded tar.gz archives when importing a backup 
OPENENERGYMONITOR_DIR | /opt/openenergymonitor | location of EmonScripts, emonhub and of created backup archives
EMONCMS_LOG_LOCATION | /var/log/emoncms | log location for emoncms logs <br> emoncms.log is main emoncms log, managed with the EmonLogger PHP class


### main dependencies
| | | |
-- | -- | --
web server | Apache2 |  
relational databases | mysql or maria |  
key:value database  | redis-server | data buffering for timeseries and backgroud processing for service-runner
message broker | mosquitto |   
data engine language |php with extensions | pear (for pecl needs)<br>mysql<br>gd dev, common<br>mbstring<br>redis<br>mosquitto (https://github.com/mgdm/Mosquitto-PHP)<br>curl


### EmonCMS systemd services

<h3>all systemd services have to be symlinked in /etc/systemd/system</h3>

```
emoncms_mqtt.service -> /var/www/emoncms/scripts/services/emoncms_mqtt/emoncms_mqtt.service
emonhub.service -> /opt/openenergymonitor/emonhub/service/emonhub.service
feedwriter.service -> /var/www/emoncms/scripts/services/feedwriter/feedwriter.service
service-runner.service -> /var/www/emoncms/scripts/services/service-runner/service-runner.service
```
MariaDB and Redis services are in lib/systemd/system, but they are compiled...
```
mysqld.service -> /lib/systemd/system/mariadb.service
mysql.service -> /lib/systemd/system/mariadb.service
redis.service -> /lib/systemd/system/redis-server.service
```

phpmqtt input (PHP)|listen to payloads published to the mosquitto broker on topic emon
--|--
scriptpath	| EMONCMS_WWW/scripts/services/emoncms_mqtt/emoncms_mqtt.php
Servicepath | EMONCMS_WWW/scripts/services/emoncms_mqtt/emoncms_mqtt.service
globals	| $log , $mysqli, $redis, $user, $feed_settings, $mqtt_server $mqttsettings, $mqtt_client, <br> $feed, $input, $process
non globals | $connected, $subscribed, $last_retry, $last_heartbeat, $count
log	| uses emoncms main log file <br>`journalctl -f -u emoncms_mqtt`
specific conf file | no

feedwriter (PHP)|writes input data from redis-buffer to disk in order to feed the timeseries database
--|--
scriptpath	| EMONCMS_WWW/scripts/feedwriter.php
Servicepath | EMONCMS_WWW/scripts/services/feedwriter/feedwriter.service
globals	| $log, $feed_settings, $mysqli, $redis <br> $user, $feed
log	| uses emoncms main log file <br>`journalctl -f -u feedwriter`
specific conf file | no
	
Service-runner (Python)|trigger background workers from modules (update, backup, sync, postprocess)
--|--
scriptpath	| EMONCMS_WWW/scripts/services/service-runner/service-runner.py
Servicepath | EMONCMS_WWW/scripts/services/service-runner/service-runner.service
log	| uses systemd log file <br>`journalctl -f -u service-runner`
specific conf file | no

emonhub (Python)| listen on serial port or ethernet and publish to mosquitto broker topic emon
--|--
scriptpath	| OPENENERGYMONITOR_DIR/emonhub/src/emonhub.py
Servicepath | OPENENERGYMONITOR_DIR/service/emonhub.service
log | log file is in  /var/log/emonhub<br>`journalctl -u emonhub -n 30 –no-pager`
specific conf file | /etc/emonhub/emonhub.conf<br>/etc/emonhub/emonhub.env

emonPiLCD (Python)| manages the emonpi LCD screen
--|--
scriptpath	| OPENENERGYMONITOR_DIR/emonpi/lcd/emonPiLCD.py
Servicepath | OPENENERGYMONITOR_DIR/emonpi/lcd/emonPiLCD.service
log | log file is in  /var/log/emonpilcd<br>`journalctl -u emonPiLCD`
specific conf file | no

### EmonCMS modules

admin| module integrated into the core package - does not have its own git repo
--|--			
place | EMONCMS_WWW/Modules/admin
globals	|  $mysqli,$session,$route,$updatelogin,$allow_emonpi_admin, $redis, $openenergymonitor_dir, $admin_show_update, $path <br> $log, $log_location, $log_enabled, $log_level
background workers | none	
log	| uses emoncms main log file
specific conf file | no

config|web interface to supervise and configure emonhub
--|--
place | EMONCMS_WWW/Modules/config
globals | $route, $session, $redis, $homedir
non globals | $emonhub_config_file, $emonhub_logfile, $restart_log<br> Also in model : $logfile, $config_file, $restart_log_name
background workers | restart.sh	
log	|  /var/log/emoncms/emonhub-restart.log	
specific conf file | no

dashboard|Dashboard Module
--|--
place | EMONCMS_WWW/Modules/dashboard
globals | $mysqli, $session, $route, $path
background workers | no
log | no
specific conf file | no
			
graph|main graph module with averaging on the fly
--|--
place | EMONCMS_WWW/Modules/graph
globals | $session,$route,$mysqli,$redis, $path
background workers | no
log | no
specific conf file | no	

backup|import/export all timeseries+mysql database
--|--
place | EMONCMS_DIR/modules/backup
globals | $route, $session, $path, $redis, $linked_modules_dir, $log_location
background workers | emoncms-import.sh<br>emoncms-export.sh<br>emoncms-copy.sh ?<br>service-runner bash file why ? All things related to service-runner are in controller
log | EMONCMS_LOG_LOCATION/exportbackup.log <br>EMONCMS_LOG_LOCATION/importbackup.log
specific conf file | config.cfg which has to be set up during installation

sync|connect to distant EmonCMS machines to retrieve feeds <br> IOT flavoured alternative to backup
--|--
place | EMONCMS_DIR/modules/sync
globals | $linked_modules_dir,$path,$session,$route<br>$mysqli,$redis,$user,$feed_settings,$log_location<br> $log in model
background workers | emoncms-sync.sh launching sync_run.php in CLI
log | EMONCMS_LOG_LOCATION/sync.log	<br> also uses emoncms main log file
specific conf file | no
	
postprocess|postprocess feeds - calculation module
--|--
place |EMONCMS_DIR/modules/postprocess
globals | $linked_modules_dir,$session,$route,$mysqli,$redis,$feed_settings, $log_location
background workers | postprocess.sh launching postprocess_run.php in CLI  <br> Postprocess_run.php scans the redis postprocessqueue and start process functions
log | EMONCMS_LOG_LOCATION/postprocess.log
specific conf file | no
