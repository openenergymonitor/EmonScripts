#!/bin/bash
#Description: Build script to generate the emonmuc debian package

repository_tmp="$root_dir/build/tmp/emonmuc"

if [ ! -d $repository_tmp ]; then
    git clone -b $emonmuc_branch ${git_repo[emonmuc]} $repository_tmp
else
    git -C $repository_tmp pull
fi
#if [ -f "$repository_tmp/version.txt" ]; then
#    package_vers=$(cat "$repository_tmp/version.txt")
#
#elif [ -f "$repository_tmp/version.json" ]; then
#    package_vers=$(cat "$repository_tmp/version.json" | jq -r '.version')
#else
#    echo "Unable to find emonmuc version file"
#    exit 1
#fi

package_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
package_name="$(basename "$package_path")"
package_id="$package_name"-"$package_vers"
package_build="$build_dir/$package_id"

mkdir -p $package_build

cp -r $defaults_dir/debian $package_build
cp -rf $package_dir/debian $package_build

cp -r $repository_tmp/www/modules $package_build
cp -r $repository_tmp/www/themes $package_build
cp -r $repository_tmp/lib/device $package_build
cp -r $repository_tmp/lib/driver $package_build
cp "/opt/oem/emonscripts/common/emonmucdevupdate.php" $package_build

sed -i 's~<ROOT_DIR>~'$emoncms_www'~g' $package_build/debian/install
sed -i 's~<ROOT_DIR>~'$emoncms_www'~g' $package_build/debian/postinst
