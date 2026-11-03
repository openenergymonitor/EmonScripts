#!/bin/bash
source load_config.sh

echo "-------------------------------------------------------------"
echo "Redis configuration"
echo "-------------------------------------------------------------"
sudo apt-get install -y redis-server

if [ "$install_php" = true ]; then
    # Packaged phpredis, built for the distribution's PHP and enabled by
    # its own postinst. Replaces the build from phpredis git HEAD.
    sudo apt-get install -y php-redis
fi

# Python redis client (emonPiLCD and others), packaged by the distribution
sudo apt-get install -y python3-redis

# Disable redis persistance
sudo sed -i "s/^save 900 1/#save 900 1/" /etc/redis/redis.conf
sudo sed -i "s/^save 300 1/#save 300 1/" /etc/redis/redis.conf
sudo sed -i "s/^save 60 1/#save 60 1/" /etc/redis/redis.conf
sudo systemctl restart redis-server
