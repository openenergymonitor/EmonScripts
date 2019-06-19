#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Apache configuration"
echo "-------------------------------------------------------------"
sudo apt-get install -y apache2

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

