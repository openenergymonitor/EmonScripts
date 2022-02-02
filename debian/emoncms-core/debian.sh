#!/bin/bash
#Description: Build script to generate the emoncms debian package
package_vers=$emoncms_version
package_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
package_name="$(basename "$package_path")"
package_id="$package_name"-"$package_vers"
package_build="$build_dir/$package_id"

mkdir -p $package_build

cp -r $defaults_dir/debian $package_build
cp -rf $package_dir/debian $package_build

cp -r $build_tmp/emoncms/Lib $package_build
cp -r $build_tmp/emoncms/Theme $package_build
cp -r $build_tmp/emoncms/Modules $package_build
cp -r $build_tmp/emoncms/scripts $package_build

mkdir $package_build/scripts/admin
cp $emonscripts_dir/common/emoncmsdbupdate.php $package_build/scripts/admin/database_update.php

cp $build_tmp/emoncms/.htaccess $package_build
cp $build_tmp/emoncms/version.* $package_build
cp $build_tmp/emoncms/index.php $package_build
cp $build_tmp/emoncms/core.php $package_build
cp $build_tmp/emoncms/route.php $package_build
cp $build_tmp/emoncms/param.php $package_build
cp $build_tmp/emoncms/locale.php $package_build
cp $build_tmp/emoncms/php-info.php $package_build
cp $build_tmp/emoncms/process_settings.php $package_build
cp $build_tmp/emoncms/default-settings.ini $package_build
cp $build_tmp/emoncms/default-settings.php $package_build
cp $build_tmp/emoncms/settings.env.ini $package_build

cp $defaults_dir/emoncms/emonpi.settings.ini $package_build/settings.ini

sed -i '/openenergymonitor_dir/d' $package_build/settings.ini
sed -i '/emoncms_dir/d'           $package_build/settings.ini
sed -i '1{/^$/d}'                 $package_build/settings.ini

sed -i '/\[mqtt\]/,+4 d'          $package_build/settings.ini

sed -i '/enable_admin_ui.*/a\
enable_update_ui = false'         $package_build/settings.ini
