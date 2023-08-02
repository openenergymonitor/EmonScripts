#!/usr/bin/env python3

# This script is used to upload pre-compiled firmware to OpenEnergyMonitor hardware
# It is designed to be ran from the command line and is an alternative to using the Emoncms firmware upload tool

import sys
import json
import subprocess
import os.path
import urllib.request

# Load firmware list from firmware_available.json
with open("firmware_available.json") as jsonFile:
    firmware_available = json.load(jsonFile)
    jsonFile.close()

# --------------------------------------------------------------------------------------------
# 1) Hardware selection
# --------------------------------------------------------------------------------------------

# Create list of hardware
hardware_list = []
for key in firmware_available:
  hardware = firmware_available[key]['hardware']
  if not hardware in hardware_list:
    hardware_list.append(hardware)

# Print list of hardware
print ("Select hardware:")
for idx, key in enumerate(hardware_list):
  print ("  "+str(int(idx)+1)+". "+key)

# Select hardware
x = int(input("Enter number:"))-1
# Check if valid
try:
  selected_hardware = hardware_list[x]
except IndexError:
  sys.exit(0)

# --------------------------------------------------------------------------------------------
# 2) Firmware selection
# --------------------------------------------------------------------------------------------

# Print list of firmware for selected hardware
print("\nSelect firmware:")
keys = []
idx = 0
for key in firmware_available:
  if firmware_available[key]['hardware'] == selected_hardware:
    if firmware_available[key]['radio_format'] != "jeelib_native":
      idx += 1

      # Easier to read radio format
      radio_format_string = ""
      if firmware_available[key]['radio_format'] == 'lowpowerlabs':
        radio_format_string = " (Standard LowPowerLabs)"
      elif firmware_available[key]['radio_format'] == 'jeelib_classic':
        radio_format_string = " (Compatibility)"

      print (str(idx)+". "+key.ljust(40)+firmware_available[key]['version'].ljust(10)+radio_format_string)
      keys.append(key)
      
# Select firmware
x = int(input("Enter number:"))-1
# Check if valid
try:
  selected_firmware = keys[x]
except IndexError:
  sys.exit(0)

# Print selected firmware
print("\nSelected firmware: "+str(selected_firmware)+"\n")

# --------------------------------------------------------------------------------------------
# 3) Download and upload firmware
# --------------------------------------------------------------------------------------------

# Check if /dev/ttyUSB0,1,2,3 exists
print ("Checking for serial port...")
for i in range(0,4):
  serial_port = "/dev/ttyUSB"+str(i)
  print("- checking: "+serial_port)
  if os.path.exists(serial_port):
    break
  else:
    serial_port = None

# Exit if no serial port found
if serial_port == None:
  print("Error: No serial port found")
  sys.exit(0)

# Get firmware details & convert to object
f = type('obj', (object,), firmware_available[selected_firmware])()

# File name of downloaded firmware
download_filename = selected_firmware + "_" + f.radio_format + "_v" + f.version + ".hex"

# Download using python
urllib.request.urlretrieve(f.download_url, download_filename)

# Check if firmware downloaded
if not os.path.isfile(download_filename):
  print("Error: Firmware download failed")

# Upload firmware
cmd = ' avrdude -Cupdate/avrdude.conf -v -p' + f.core + ' -carduino -D -P' + str(serial_port) + ' -b' + str(f.baud) + ' -Uflash:w:' + download_filename
print(cmd)
subprocess.call(cmd, shell=True)

# cleanup
os.remove(download_filename)