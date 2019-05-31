#!/bin/bash
source config.ini

echo "-------------------------------------------------------------"
echo "Apache configuration"
echo "-------------------------------------------------------------"
sudo apt-get install -y apache2

# Enable apache mod rewrite
sudo a2enmod rewrite
sudo cp $usrdir/EmonScripts/defaults/apache2/emoncms.conf /etc/apache2/sites-available/emoncms.conf
sudo a2dissite 000-default.conf
sudo a2ensite emoncms
sudo systemctl restart apache2
