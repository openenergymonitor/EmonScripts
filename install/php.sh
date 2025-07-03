#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Install PHP"
echo "-------------------------------------------------------------"

PHP_Ver=""

if grep -Fq "ARMv6" /proc/cpuinfo; then
    echo "-- ARMv6 architecture Use PHP8.0"
    PHP_Ver="8.0"

else
    echo "-- not ARMv6 architecture OK to use PHP8.1"

    if [ "$emonSD_pi_env" = "1" ]; then
        curl https://packages.sury.org/php/apt.gpg | sudo tee /usr/share/keyrings/suryphp-archive-keyring.gpg >/dev/null
        echo "deb [signed-by=/usr/share/keyrings/suryphp-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
        sudo apt update
    fi
fi

sudo apt-get install -y php$PHP_Ver

# if [ "$install_apache" = true ]; then
#     sudo apt-get install -y libapache2-mod-php
# fi

if [ "$install_mysql" = true ]; then
    sudo apt-get install -y php$PHP_Ver-mysql
fi

sudo apt-get install -y php$PHP_Ver-gd php$PHP_Ver-curl php-pear php$PHP_Ver-dev php$PHP_Ver-common php$PHP_Ver-mbstring

sudo pecl channel-update pecl.php.net

