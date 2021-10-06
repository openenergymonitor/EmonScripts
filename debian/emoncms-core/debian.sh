#!/bin/bash
#Description: Build script to generate the emoncms debian package

emoncms_dir="$root_dir/build/tmp/emoncms"
if [ ! -d $emoncms_dir ]; then
    git clone -b $emoncms_core_branch ${git_repo[emoncms_core]} $emoncms_dir
else
    git -C $emoncms_dir pull
fi
if [ -f "$emoncms_dir/version.txt" ]; then
    package_vers=$(cat "$emoncms_dir/version.txt")

elif [ -f "$emoncms_dir/version.json" ]; then
    package_vers=$(cat "$emoncms_dir/version.json" | jq -r '.version')
else
    echo "Unable to find emoncms version file"
    exit 1
fi
package_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
package_name="$(basename "$package_path")"
package_id="$package_name"-"$package_vers"
package_build="$build_dir/$package_id"

mkdir -p $package_build

cp -r $defaults_dir/debian $package_build
cp -rf $package_dir/debian $package_build
