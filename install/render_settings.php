<?php
// Render the initial settings.ini using the sourced installer configuration.
$template = file_get_contents(__DIR__ . '/../defaults/emoncms/emonpi.settings.ini');
if ($template === false) {
    exit(1);
}

$replacements = array();
foreach (array('emoncms_dir', 'openenergymonitor_dir', 'emoncms_datadir',
    'mysql_database', 'mysql_user', 'mysql_password', 'mqtt_user', 'mqtt_password') as $name) {
    $value = getenv($name);
    if ($value === false) {
        fwrite(STDERR, "Missing installer setting: $name\n");
        exit(1);
    }
    // Values sit inside double-quoted INI strings. Keep quotes, backslashes
    // and ${...} literal when Emoncms reads them with INI_SCANNER_TYPED.
    $replacements[strtoupper($name)] = addcslashes($value, "\\\"$");
}

echo strtr($template, $replacements);
