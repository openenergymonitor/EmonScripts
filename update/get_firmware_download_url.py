#!/usr/bin/env python3

import sys
import json

with open("../firmware_available.json") as jsonFile:
    firmware_available = json.load(jsonFile)
    jsonFile.close()

# Returns latest firmware (first in the list for a particular hardware entry)
if len(sys.argv)==2:
    hardware = sys.argv[1]
    if hardware in firmware_available:
        for firmware in firmware_available[hardware]:
            print(firmware['download_url']+" "+str(firmware['baud'])+" "+str(firmware['version']))
            sys.exit(0)

# Returns specific firmware version
if len(sys.argv)==3:
    hardware = sys.argv[1]
    version = sys.argv[2]

    if hardware in firmware_available:
        for firmware in firmware_available[hardware]:
            if firmware['version']==version:
                print(firmware['download_url']+" "+str(firmware['baud'])+" "+str(firmware['version']))
                sys.exit(0)

# Error
print("firmware not found")
