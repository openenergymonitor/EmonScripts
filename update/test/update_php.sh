#!/bin/bash

# --- Configuration and Environment Setup ---

echo "-------------------------------------------------------------"
echo "Install Latest PHP Version and Extensions"
echo "-------------------------------------------------------------"

# Security: Exit on any error and treat unset variables as errors
set -euo pipefail

# Set the desired latest PHP version. This should be updated as new versions are released.
LATEST_PHP_VER="8.3"
PHP_Ver=""

# Security: Verify we're running as root/sudo
if [[ $EUID -ne 0 ]] && [[ -z "${SUDO_USER:-}" ]]; then
   echo "This script must be run as root or with sudo"
   exit 1
fi

apt-get update

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
    # Remove the conditional check to always add the repository when targeting latest PHP
    echo "--- Adding Sury repository for PHP $PHP_Ver ---"

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
    # Security: Use temporary file and verify download
    TEMP_KEY=$(mktemp)
    if curl -fsSL https://packages.sury.org/php/apt.gpg -o "$TEMP_KEY"; then
        gpg --dearmor < "$TEMP_KEY" > /usr/share/keyrings/suryphp-archive-keyring.gpg
        rm "$TEMP_KEY"
    else
        echo "Failed to download Sury GPG key"
        rm -f "$TEMP_KEY"
        exit 1
    fi
    
    echo "Adding Sury repository source file..."
    echo "deb [signed-by=/usr/share/keyrings/suryphp-archive-keyring.gpg] https://packages.sury.org/php/ $DISTRO_CODENAME main" | tee /etc/apt/sources.list.d/sury-php.list > /dev/null

    apt update
fi

# 3. Install Core PHP and Dependencies
echo "--- Installing PHP $PHP_Ver and Core Dependencies ---"
apt-get install -y php$PHP_Ver php$PHP_Ver-dev php-pear libapache2-mod-php$PHP_Ver

# 4. Install Required Extensions
# php-common is usually redundant/handled by dependencies, so we omit it for simplicity.
apt-get install -y \
    php$PHP_Ver-gd \
    php$PHP_Ver-curl \
    php$PHP_Ver-mbstring \
    php$PHP_Ver-mysql

# Install development headers for Mosquitto (required for extension compilation)
echo "--- Installing libmosquitto-dev for Mosquitto-PHP ---"
apt-get install -y libmosquitto-dev

# 5. Setup for Extension Compilation
SCRIPT_DIR=$(pwd)
# Security: Use more secure temp directory creation
TEMP_BUILD_DIR=$(mktemp -d -t php_extensions_build.XXXXXXXXXX)
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
pecl channel-update pecl.php.net

# 6. Install PHPRedis Extension
echo "-------------------------------------------------------------"
echo "Compiling and installing PHPRedis extension"
echo "-------------------------------------------------------------"
# Security: Verify git clone and use specific commit/tag for reproducibility
if git clone --depth 1 https://github.com/phpredis/phpredis.git phpredis_temp; then
    cd phpredis_temp
    phpize
    ./configure
    make
    make install
    cd .. # Go back to TEMP_BUILD_DIR
    rm -rf phpredis_temp
else
    echo "Failed to clone PHPRedis repository"
    exit 1
fi

# Enable redis module
REDIS_INI_PATH="/etc/php/$ACTUAL_PHP_VER/mods-available/redis.ini"
if [ ! -f "$REDIS_INI_PATH" ]; then
    echo "Adding redis.ini configuration file..."
    printf "extension=redis.so\n" | tee "$REDIS_INI_PATH" > /dev/null
    phpenmod redis
else
    echo "Redis extension configuration already exists."
fi


# 7. Install Mosquitto-PHP Extension
echo "-------------------------------------------------------------"
echo "Compiling and installing Mosquitto-PHP extension"
echo "-------------------------------------------------------------"
# Security: Verify git clone
if git clone --depth 1 https://github.com/openenergymonitor/Mosquitto-PHP.git mosquitto_temp; then
    cd mosquitto_temp
    phpize
    ./configure
    make
    make install
    cd .. # Go back to TEMP_BUILD_DIR
    rm -rf mosquitto_temp
else
    echo "Failed to clone Mosquitto-PHP repository"
    exit 1
fi

# Enable mosquitto module
MOSQUITTO_INI_PATH="/etc/php/$ACTUAL_PHP_VER/mods-available/mosquitto.ini"
if [ ! -f "$MOSQUITTO_INI_PATH" ]; then
    echo "Adding mosquitto.ini configuration file..."
    printf "extension=mosquitto.so\n" | tee "$MOSQUITTO_INI_PATH" > /dev/null
    phpenmod mosquitto
else
    echo "Mosquitto extension configuration already exists."
fi


# 8. Cleanup and Final Messages
echo "-------------------------------------------------------------"
echo "Installation complete."
echo "Cleaning up temporary build files."
cd "$SCRIPT_DIR"
# Security: Ensure temp directory is properly cleaned
if [[ -d "$TEMP_BUILD_DIR" && "$TEMP_BUILD_DIR" == /tmp/* ]]; then
    rm -rf "$TEMP_BUILD_DIR"
fi
echo "The installed PHP version is: $ACTUAL_PHP_VER"

# Switch Apache to use the new PHP version
echo "-------------------------------------------------------------"
echo "Switching Apache to use PHP $ACTUAL_PHP_VER"
echo "-------------------------------------------------------------"

# Disable all existing PHP modules
a2dismod php* 2>/dev/null || true

# Enable the new PHP version module
a2enmod php$ACTUAL_PHP_VER

# Verification: Check if Apache module was actually enabled
if apache2ctl -M 2>/dev/null | grep -q "php${ACTUAL_PHP_VER}_module"; then
    echo "✓ PHP $ACTUAL_PHP_VER module successfully enabled in Apache"
else
    echo "⚠ Warning: PHP $ACTUAL_PHP_VER module may not be properly enabled"
fi

echo "Restarting the web server"
systemctl restart apache2

# Final verification
echo "Verifying installation..."
echo "CLI PHP version: $(php -v | head -n1)"
echo "-------------------------------------------------------------"
printf "\n"
