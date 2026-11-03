#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Install PHP"
echo "-------------------------------------------------------------"

# PHP comes from the distribution's own repository: PHP 8.2 on bookworm,
# PHP 8.4 on trixie. The distribution keeps PHP on one minor version for the
# life of a release and backports security fixes to it, so the compiled
# phpredis and Mosquitto-PHP extensions stay valid when security updates are
# applied. Images up to emonSD-10Mar26 used the third party sury repository
# instead; update/php_xml.sh and common/sury_keyring.sh still support those.

sudo apt-get install -y php

# if [ "$install_apache" = true ]; then
#     sudo apt-get install -y libapache2-mod-php
# fi

if [ "$install_mysql" = true ]; then
    sudo apt-get install -y php-mysql
fi

sudo apt-get install -y php-gd php-curl php-pear php-dev php-common php-mbstring php-xml

PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
echo "-- Installed PHP $PHP_VER"

sudo pecl channel-update pecl.php.net
