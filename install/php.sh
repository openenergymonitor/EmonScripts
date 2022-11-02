#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Install PHP"
echo "-------------------------------------------------------------"
if [ "$emonSD_pi_env" = "1" ]; then
    curl https://packages.sury.org/php/apt.gpg | sudo tee /usr/share/keyrings/suryphp-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/suryphp-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
    sudo apt update
fi

sudo apt-get install -y php8.1

# if [ "$install_apache" = true ]; then
#     sudo apt-get install -y libapache2-mod-php
# fi

if [ "$install_mysql" = true ]; then
    sudo apt-get install -y php8.1-mysql
fi

sudo apt-get install -y php8.1-gd php8.1-curl php-pear php8.1-dev php8.1-common php8.1-mbstring

sudo pecl channel-update pecl.php.net

