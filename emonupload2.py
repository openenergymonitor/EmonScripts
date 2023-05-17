#!/usr/bin/env python3

import sys
import json
import subprocess
import os.path
import urllib.request

with open("firmware_available.json") as jsonFile:
    firmware_available = json.load(jsonFile)
    jsonFile.close()
    
hardware_list = []
for key in firmware_available:
  hardware = firmware_available[key]['hardware']
  if not hardware in hardware_list:
    hardware_list.append(hardware)

print ("Select hardware:")
for idx, key in enumerate(hardware_list):
  print ("  "+str(int(idx)+1)+". "+key)

x = int(input("Enter number:"))-1

try:
  selected_hardware = hardware_list[x]
except IndexError:
  sys.exit(0)

print("\nSelect firmware:")
keys = []
idx = 0
for key in firmware_available:
  if firmware_available[key]['hardware'] == selected_hardware:
    idx += 1
    print (str(idx)+". "+key)
    keys.append(key)
      
x = int(input("Enter number:"))-1
  
try:
  selected_firmware = keys[x]
except IndexError:
  sys.exit(0)
  
print(selected_firmware)

download_url = firmware_available[selected_firmware]['download_url']
radio_format = firmware_available[selected_firmware]['radio_format']
version = firmware_available[selected_firmware]['version']
core = firmware_available[selected_firmware]['core']
baud = firmware_available[selected_firmware]['baud']

# File name of downloaded firmware
download_filename = selected_firmware + "_" + radio_format + "_v" + version + ".hex"

# Download using python
urllib.request.urlretrieve(download_url, download_filename)

# Check if firmware downloaded
if not os.path.isfile(download_filename):
  print("Error: Firmware download failed")

serial_port = "/dev/ttyUSB0"

cmd = ' avrdude -Cupdate/avrdude.conf -v -p' + core + ' -carduino -D -P' + str(serial_port) + ' -b' + str(baud) + ' -Uflash:w:' + download_filename
print(cmd)
subprocess.call(cmd, shell=True)
