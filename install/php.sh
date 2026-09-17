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
        source $openenergymonitor_dir/EmonScripts/common/sury_keyring.sh

        # Validated download, an error page or a failed fetch would otherwise
        # be written straight into the keyring and break every later apt run
        if ! sury_install_keyring; then
            echo "-- ERROR: could not install the sury signing key, aborting PHP install"
            exit 1
        fi

        echo "deb [signed-by=$SURY_KEYRING] https://packages.sury.org/php/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/sury-php.list

        # Re-fetches the key and retries if sury still fails to verify
        sury_repair
    fi
fi

sudo apt-get install -y php$PHP_Ver

# if [ "$install_apache" = true ]; then
#     sudo apt-get install -y libapache2-mod-php
# fi

if [ "$install_mysql" = true ]; then
    sudo apt-get install -y php$PHP_Ver-mysql
fi

sudo apt-get install -y php$PHP_Ver-gd php$PHP_Ver-curl php-pear php$PHP_Ver-dev php$PHP_Ver-common php$PHP_Ver-mbstring php$PHP_Ver-xml

sudo pecl channel-update pecl.php.net

