#!/usr/bin/env python3

import sys
import json

with open("../firmware_available.json") as jsonFile:
    firmware_available = json.load(jsonFile)
    jsonFile.close()

if len(sys.argv)==2:
    firmware_key = sys.argv[1]
    if firmware_key in firmware_available:
        firmware = firmware_available[firmware_key]
        print(firmware['download_url']+" "+str(firmware['baud'])+" "+str(firmware['version']))
        sys.exit(0)

# Error
print("firmware not found")
