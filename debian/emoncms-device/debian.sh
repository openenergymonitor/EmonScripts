#!/bin/bash
#Description: Build script to generate the emoncms debian package

repository_tmp="$root_dir/build/tmp/emoncms-device"

if [ ! -d $repository_tmp ]; then
    git clone -b ${emoncms_modules[device]} ${git_repo[device]} $repository_tmp
else
    git -C $repository_tmp pull
fi
if [ -f "$repository_tmp/module.json" ]; then
    package_vers=$(cat "$repository_tmp/module.json" | jq -r '.version')
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

cp -r $repository_tmp $package_build
mv $package_build/emoncms-device $package_build/device 

sed -i 's~<root_dir>~'$emoncms_www'~g' $package_build/debian/install
sed -i 's~<root_dir>~'$emoncms_www'~g' $package_build/debian/postinst
