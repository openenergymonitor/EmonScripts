#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Install PHP"
echo "-------------------------------------------------------------"

sudo apt-get install -y php7.3

if [ "$install_apache" = true ]; then
    sudo apt-get install -y libapache2-mod-php
fi

if [ "$install_mysql" = true ]; then
    sudo apt-get install -y php7.3-mysql
fi

sudo apt-get install -y php7.3-gd php7.3-opcache php7.3-curl php-pear php7.3-dev php-mcrypt php7.3-common php7.3-mbstring

sudo pecl channel-update pecl.php.net
