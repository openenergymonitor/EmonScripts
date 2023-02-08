#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Apache configuration"
echo "-------------------------------------------------------------"
sudo apt-get install -y apache2 gettext

sudo chown $user /var/www

# create emoncms www folder
if [ ! -d $emoncms_www ]; then
    echo "- create emoncms www folder for Apache"
    mkdir $emoncms_www
else
    echo "- emoncms www folder already installed"
fi

# Create emoncms logfolder
if [ ! -d $emoncms_log_location ]; then
    echo "- creating emoncms log folder"
    sudo mkdir $emoncms_log_location
    sudo chown $user $emoncms_log_location
else
    echo "- log folder already exists"
fi

sudo sed -i "s/^CustomLog/#CustomLog/" /etc/apache2/conf-available/other-vhosts-access-log.conf

# Enable apache mod rewrite
sudo a2enmod rewrite

# Default apache2 configuration
sudo cp $openenergymonitor_dir/EmonScripts/defaults/apache2/emonsd.conf /etc/apache2/conf-available/emonsd.conf
sudo a2enconf emonsd.conf

# Configure virtual host
sudo cp $openenergymonitor_dir/EmonScripts/defaults/apache2/emoncms.conf /etc/apache2/sites-available/emoncms.conf
sudo a2dissite 000-default.conf
sudo a2ensite emoncms

sudo systemctl restart apache2

