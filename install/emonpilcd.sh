#!/bin/bash
source config.ini

sudo apt-get install -y python-smbus i2c-tools python-rpi.gpio python-gpiozero
sudo pip install xmltodict

# Uncomment dtparam=i2c_arm=on
sudo sed -i "s/^#dtparam=i2c_arm=on/dtparam=i2c_arm=on/" /boot/config.txt
# Append line i2c-dev to /etc/modules
sudo sed -i -n '/i2c-dev/!p;$a i2c-dev' /etc/modules

if [ ! -d /var/log/emonpilcd ]; then
    # emonPiLCD Logger
    sudo mkdir /var/log/emonpilcd
    sudo chown $user /var/log/emonpilcd
    # Permissions?
    touch /var/log/emonpilcd/emonpilcd.log
fi

# ---------------------------------------------------------
# Install service
# ---------------------------------------------------------
service=emonPiLCD

if [ -f /lib/systemd/system/$service.service ]; then
    echo "- reinstalling $service.service"
    sudo systemctl stop $service.service
    sudo systemctl disable $service.service
    sudo rm /lib/systemd/system/$service.service
else
    echo "- installing $service.service"
fi

# Install emonpi repo if it doesnt already exist
if [ ! -d $openenergymonitor_dir/emonpi ]; then
    echo "Installing emonpi repository"
    cd $openenergymonitor_dir
    git clone https://github.com/openenergymonitor/emonpi.git
fi

sudo cp $openenergymonitor_dir/emonpi/lcd/$service.service /lib/systemd/system
sudo sed -i "s~ExecStart=.*~ExecStart=/usr/bin/python $openenergymonitor_dir/emonpi/lcd/emonPiLCD.py~" /lib/systemd/system/$service.service
sudo systemctl enable $service.service
sudo systemctl restart $service.service

state=$(systemctl show $service | grep ActiveState)
echo "- Service $state"
# ---------------------------------------------------------
