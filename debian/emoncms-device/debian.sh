#!/bin/bash
#Description: Build script to generate the emoncms debian package
if [ ! -d $build_tmp/emoncms-device ]; then
    git clone -b ${emoncms_modules[device]} ${git_repo[device]} $build_tmp/emoncms-device
else
    git -C $build_tmp/emoncms-device pull
fi
if [ -f "$build_tmp/emoncms-device/module.json" ]; then
    package_vers=$(cat "$build_tmp/emoncms-device/module.json" | jq -r '.version')
else
    echo "Unable to find module version file"
    exit 1
fi
package_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
package_name="$(basename "$package_path")"
package_id="$package_name"-"$package_vers"
package_build="$build_dir/$package_id"

mkdir -p $package_build

cp -r $defaults_dir/debian $package_build
cp -rf $package_dir/debian $package_build

mkdir -p $package_build/scripts/admin
cp $emonscripts_dir/common/emonmucdevupdate.php $package_build/scripts/admin/device_update.php

cp -r $build_tmp/emoncms-device $package_build/device
rm -r $package_build/device/docs
rm -r $package_build/device/.git*
rm $package_build/device/.travis.yml
rm $package_build/device/composer.json
rm $package_build/device/README.md
rm $package_build/device/LICENSE*
rm $package_build/device/LICENSE*
