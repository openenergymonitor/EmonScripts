#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Install PHP"
echo "-------------------------------------------------------------"

sudo apt-get install -y php

# if [ "$install_apache" = true ]; then
#     sudo apt-get install -y libapache2-mod-php
# fi

if [ "$install_mysql" = true ]; then
    sudo apt-get install -y php-mysql
fi

sudo apt-get install -y php-gd php7.3-opcache php-curl php-pear php-dev php-mcrypt php-common php-mbstring

sudo pecl channel-update pecl.php.net

