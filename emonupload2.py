#!/usr/bin/env python3

import sys
import json
import subprocess

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
bashCommand = "update/atmega_firmware_upload.sh ttyUSB0 "+selected_firmware
process = subprocess.Popen(bashCommand.split(), stdout=subprocess.PIPE)
output, error = process.communicate()
