#!/bin/bash

# Configuration
BOSSAC_DIR="/opt/openenergymonitor/BOSSA"
SERIAL_PORT="/dev/ttyAMA0"
# Automatically find the bin file if it's in the current directory
FIRMWARE_FILE="${1:-/home/pi/emon32.bin}"

echo "--- Starting emonPi3 Firmware Update ---"

# 1. Pre-flight Check: Does the firmware even exist?
if [ ! -f "$FIRMWARE_FILE" ]; then
    echo "Error: Firmware file $FIRMWARE_FILE not found."
    echo "Usage: sudo ./update.sh [path_to_firmware.bin]"
    exit 1
fi

# 2. Install/Verify BOSSA
if [ ! -f "$BOSSAC_DIR/bin/bossac" ]; then
    echo "BOSSA not found. Installing..."
    sudo mkdir -p /opt/openenergymonitor
    sudo git clone https://github.com/shumatech/BOSSA /opt/openenergymonitor/BOSSA
    cd /opt/openenergymonitor/BOSSA && sudo make bossac
else
    echo "BOSSA is already installed."
fi

# 3. Stop emonhub
echo "Stopping emonhub..."
sudo systemctl stop emonhub.service

# 4. Trigger Bootloader via Serial
# Trap to ensure emonhub restarts even if interrupted
trap 'echo "Interrupted! Cleaning up..."; sudo systemctl start emonhub.service; exit' INT

echo "Sending bootloader trigger to $SERIAL_PORT..."
stty -F $SERIAL_PORT 115200 raw -echo
echo -ne 'e\n' > $SERIAL_PORT
sleep 0.5
echo -ne 'y\n' > $SERIAL_PORT
sleep 1

# 5. Verify Connection and Upload
echo "Checking device info..."
if $BOSSAC_DIR/bin/bossac -p $SERIAL_PORT -i > /dev/null 2>&1; then
    echo "Device detected. Starting upload..."
    $BOSSAC_DIR/bin/bossac -p $SERIAL_PORT -e -w -v -R --offset=0x2000 "$FIRMWARE_FILE"
else
    echo "Error: Could not communicate with ATSAMD21. Is it in bootloader mode?"
    sudo systemctl start emonhub.service
    exit 1
fi

# 6. Cleanup and Restart
echo "Starting emonhub..."
sudo systemctl start emonhub.service

echo "--- Update Complete ---"
