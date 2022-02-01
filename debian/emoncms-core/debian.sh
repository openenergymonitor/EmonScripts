#!/bin/bash
#Description: Build script to generate the emoncms debian package

repository_tmp="$root_dir/build/tmp/emoncms"

if [ ! -d $repository_tmp ]; then
    git clone -b $emoncms_core_branch ${git_repo[emoncms_core]} $repository_tmp
else
    git -C $repository_tmp pull
fi
if [ -f "$repository_tmp/version.txt" ]; then
    package_vers=$(cat "$repository_tmp/version.txt")

elif [ -f "$repository_tmp/version.json" ]; then
    package_vers=$(cat "$repository_tmp/version.json" | jq -r '.version')
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

cp -r $repository_tmp/Lib $package_build
cp -r $repository_tmp/Theme $package_build
cp -r $repository_tmp/Modules $package_build
cp -r $repository_tmp/scripts $package_build

cp $emonscripts_dir/common/emoncmsdbupdate.php $package_build/scripts/database_update.php

cp $repository_tmp/.htaccess $package_build
cp $repository_tmp/version.* $package_build
cp $repository_tmp/index.php $package_build
cp $repository_tmp/core.php $package_build
cp $repository_tmp/route.php $package_build
cp $repository_tmp/param.php $package_build
cp $repository_tmp/locale.php $package_build
cp $repository_tmp/php-info.php $package_build
cp $repository_tmp/process_settings.php $package_build
cp $repository_tmp/default-settings.ini $package_build
cp $repository_tmp/default-settings.php $package_build
cp $repository_tmp/settings.env.ini $package_build

cp $defaults_dir/emoncms/emonpi.settings.ini $package_build/settings.ini

sed -i '/\[mqtt\]/,+4 d' $package_build/settings.ini
