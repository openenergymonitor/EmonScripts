#!/usr/bin/env python3

import sys
import json

import urllib.request, json 
with urllib.request.urlopen("https://raw.githubusercontent.com/openenergymonitor/EmonScripts/master/firmware_available.json") as url:
    firmware_available = json.load(url)
    
    if len(sys.argv)==2:
        firmware_key = sys.argv[1]
        if firmware_key in firmware_available:
            firmware = firmware_available[firmware_key]
            print(firmware['download_url']+" "+str(firmware['baud'])+" "+str(firmware['version'])+" "+str(firmware['core']))
            sys.exit(0)

# Error
print("firmware not found")
