#!/bin/bash
#Description: Build script to generate the emonmuc debian package
if [ ! -d $build_tmp/emonmuc ]; then
    git clone -b $emonmuc_branch ${git_repo[emonmuc]} $build_tmp/emonmuc
else
    git -C $build_tmp/emonmuc pull
fi
if [ -f "$build_tmp/emonmuc/version.json" ]; then
    package_vers=$(cat "$build_tmp/emonmuc/version.json" | jq -r '.version')
else
    echo "Unable to find emonmuc version file"
    exit 1
fi
package_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
package_name="$(basename "$package_path")"
package_id="$package_name"-"$package_vers"
package_build="$build_dir/$package_id"

mkdir -p $package_build

cp -r $defaults_dir/debian $package_build
cp -rf $package_dir/debian $package_build

cp -r $build_tmp/emonmuc/www/modules $package_build
cp -r $build_tmp/emonmuc/www/themes $package_build
cp -r $build_tmp/emonmuc/lib/device $package_build
cp -r $build_tmp/emonmuc/lib/driver $package_build
