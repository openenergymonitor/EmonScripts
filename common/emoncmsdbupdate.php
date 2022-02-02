<?php
// Update Emoncms database
define('EMONCMS_EXEC', 1);

$options_short = "d:";
$options_long  = array(
    "dir:"
);
$options = getopt($options_short, $options_long);

if (isset($options['d'])) {
    $dir = $options['d'];
}
else if (isset($options['dir'])) {
    $dir = $options['dir'];
}
else {
    $dir = "/var/www/emoncms";
}
if(substr_compare($dir, '/', strlen($dir)-1, 1) !== 0) {
    $dir = $dir."/";
}
chdir($dir);
require "process_settings.php";
require "core.php";

# Check MySQL PHP modules are loaded
if (!extension_loaded('mysql') && !extension_loaded('mysqli')){
    echo "Your PHP installation appears to be missing the MySQL extension(s) which are required by Emoncms."; die;
}

# Check Gettext PHP  module is loaded
if (!extension_loaded('gettext')){
    echo "Your PHP installation appears to be missing the gettext extension which is required by Emoncms."; die;
}
$mysqli = @new mysqli(
    $settings['sql']['server'],
    $settings['sql']['username'],
    $settings['sql']['password'],
    $settings['sql']['database'],
    $settings['sql']['port']
);
if ($mysqli->connect_error) {
    echo "Can't connect to database, please verify credentials/configuration in settings.php"; die;
}
// Set charset to utf8
$mysqli->set_charset("utf8");

$applychanges = true;

require_once "Lib/dbschemasetup.php";
print json_encode(db_schema_setup($mysqli, load_db_schema(), $applychanges))."\n";
