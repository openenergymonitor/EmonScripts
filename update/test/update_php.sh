#!/bin/bash

# --- Configuration and Environment Setup ---

echo "-------------------------------------------------------------"
echo "Install Latest PHP Version and Extensions"
echo "-------------------------------------------------------------"

# Set the desired latest PHP version. This should be updated as new versions are released.
LATEST_PHP_VER="8.3"
PHP_Ver=""
sudo apt-get update

# 1. Architecture Check
if grep -Fq "ARMv6" /proc/cpuinfo; then
    echo "-- ARMv6 architecture detected (e.g., Raspberry Pi 1, Zero W)."
    # Stick to PHP 8.0, which is known to work on older Pis on standard repos.
    PHP_Ver="8.0"
    echo "-- Falling back to PHP $PHP_Ver for ARMv6 compatibility."
else
    echo "-- Not ARMv6 architecture. Targeting PHP $LATEST_PHP_VER."
    PHP_Ver="$LATEST_PHP_VER"

    # 2. Add Sury Repository for Latest PHP
    # This block is essential for getting the latest versions (like 8.3) on
    # standard Debian/Raspberry Pi OS releases where the default repos lag.
    # The original script gated this behind emonSD_pi_env.
    if [ "$emonSD_pi_env" = "1" ]; then
        echo "--- Adding Sury repository for PHP $PHP_Ver (emonSD_pi_env is set) ---"

        # Dynamically determine the Debian/Raspberry Pi OS codename
        if command -v lsb_release &> /dev/null; then
            DISTRO_CODENAME=$(lsb_release -cs)
            echo "--- Detected OS codename: $DISTRO_CODENAME"
        else
            # Fallback if lsb_release is not installed (e.g., on very minimal systems)
            DISTRO_CODENAME="bullseye"
            echo "--- Warning: lsb_release not found. Using fallback codename: $DISTRO_CODENAME"
        fi

        # Add the key and repository
        echo "Adding Sury GPG Key..."
        curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /usr/share/keyrings/suryphp-archive-keyring.gpg
        echo "Adding Sury repository source file..."
        echo "deb [signed-by=/usr/share/keyrings/suryphp-archive-keyring.gpg] https://packages.sury.org/php/ $DISTRO_CODENAME main" | sudo tee /etc/apt/sources.list.d/sury-php.list > /dev/null

        sudo apt update
    fi
fi

# 3. Install Core PHP and Dependencies
echo "--- Installing PHP $PHP_Ver and Core Dependencies ---"
sudo apt-get install -y php$PHP_Ver php$PHP_Ver-dev php-pear

# 4. Install Required Extensions
# php-common is usually redundant/handled by dependencies, so we omit it for simplicity.
sudo apt-get install -y \
    php$PHP_Ver-gd \
    php$PHP_Ver-curl \
    php$PHP_Ver-mbstring

# Install optional MySQL/MariaDB driver if enabled in load_config.sh
if [ "$install_mysql" = true ]; then
    echo "--- Installing MySQL/MariaDB extension ---"
    sudo apt-get install -y php$PHP_Ver-mysql
fi

# Install development headers for Mosquitto (required for extension compilation)
echo "--- Installing libmosquitto-dev for Mosquitto-PHP ---"
sudo apt-get install -y libmosquitto-dev

# 5. Setup for Extension Compilation
SCRIPT_DIR=$(pwd)
TEMP_BUILD_DIR="/tmp/php_extensions_build_$(date +%s)"
mkdir -p "$TEMP_BUILD_DIR"
cd "$TEMP_BUILD_DIR" || { echo "Error: Failed to change to temp directory $TEMP_BUILD_DIR"; exit 1; }

# Get the major.minor version of the *currently installed* PHP for correct pathing
# This is crucial for systems with multiple PHP versions installed
ACTUAL_PHP_VER=$(php -v 2>/dev/null | head -n 1 | cut -d " " -f 2 | cut -f1-2 -d"." )

if [ -z "$ACTUAL_PHP_VER" ]; then
    echo "Error: Could not determine the installed PHP version using 'php -v'. Aborting extension build."
    cd "$SCRIPT_DIR"
    rm -rf "$TEMP_BUILD_DIR"
    exit 1
fi
echo "--- Installed PHP version directory detected as: $ACTUAL_PHP_VER ---"
sudo pecl channel-update pecl.php.net

# 6. Install PHPRedis Extension
echo "-------------------------------------------------------------"
echo "Compiling and installing PHPRedis extension"
echo "-------------------------------------------------------------"
git clone https://github.com/phpredis/phpredis.git phpredis_temp
cd phpredis_temp
phpize
./configure
make
sudo make install
cd .. # Go back to TEMP_BUILD_DIR
rm -rf phpredis_temp

# Enable redis module
REDIS_INI_PATH="/etc/php/$ACTUAL_PHP_VER/mods-available/redis.ini"
if [ ! -f "$REDIS_INI_PATH" ]; then
    echo "Adding redis.ini configuration file..."
    printf "extension=redis.so\n" | sudo tee "$REDIS_INI_PATH" > /dev/null
    sudo phpenmod redis
else
    echo "Redis extension configuration already exists."
fi


# 7. Install Mosquitto-PHP Extension
echo "-------------------------------------------------------------"
echo "Compiling and installing Mosquitto-PHP extension"
echo "-------------------------------------------------------------"
git clone https://github.com/openenergymonitor/Mosquitto-PHP.git mosquitto_temp
cd mosquitto_temp
phpize
./configure
make
sudo make install
cd .. # Go back to TEMP_BUILD_DIR
rm -rf mosquitto_temp

# Enable mosquitto module
MOSQUITTO_INI_PATH="/etc/php/$ACTUAL_PHP_VER/mods-available/mosquitto.ini"
if [ ! -f "$MOSQUITTO_INI_PATH" ]; then
    echo "Adding mosquitto.ini configuration file..."
    printf "extension=mosquitto.so\n" | sudo tee "$MOSQUITTO_INI_PATH" > /dev/null
    sudo phpenmod mosquitto
else
    echo "Mosquitto extension configuration already exists."
fi


# 8. Cleanup and Final Messages
echo "-------------------------------------------------------------"
echo "Installation complete."
echo "Cleaning up temporary build files."
cd "$SCRIPT_DIR"
rm -rf "$TEMP_BUILD_DIR"
echo "The installed PHP version is: $ACTUAL_PHP_VER"

# Switch Apache to use the new PHP version
echo "-------------------------------------------------------------"
echo "Switching Apache to use PHP $ACTUAL_PHP_VER"
echo "-------------------------------------------------------------"

# Disable all existing PHP modules
sudo a2dismod php* 2>/dev/null || true

# Enable the new PHP version module
sudo a2enmod php$ACTUAL_PHP_VER

echo "Restarting the web server"
sudo systemctl restart apache2
echo "-------------------------------------------------------------"
printf "\n"
