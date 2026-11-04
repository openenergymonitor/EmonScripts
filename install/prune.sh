#!/bin/bash
# --------------------------------------------------------------------------------
# Remove Raspberry Pi OS Lite software that emonSD does not use
#
# Called by install/main.sh before anything else is installed. --autoremove also
# removes every other package nothing needs any more, so this must stay at the
# start of the build: later on it would catch unrelated packages that have been
# orphaned by then (e.g rpi.gpio-common). Libraries the build needs later are
# installed again as usual.
# --------------------------------------------------------------------------------
# mkvtoolnix: video file tools, also brings in Qt6 and ICU
# rpicam-apps-lite, v4l-utils: camera software, also brings in libcamera and
# TensorFlow Lite
candidates="mkvtoolnix rpicam-apps-lite v4l-utils"

packages=""
for package in $candidates; do
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q 'ok installed'; then
        packages="$packages $package"
    fi
done

if [ -z "$packages" ]; then
    echo "-- Nothing to remove"
    exit 0
fi

echo "-- Removing:$packages"
sudo apt-get purge -y --autoremove $packages
