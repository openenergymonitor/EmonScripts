#!/bin/bash
#Description: Build script to generate the emoncms debian package
if [ ! -d $build_tmp/emoncms-app ]; then
    git clone -b ${emoncms_modules[app]} ${git_repo[app]} $build_tmp/emoncms-app
else
    git -C $build_tmp/emoncms-app pull
fi
if [ -f "$build_tmp/emoncms-app/module.json" ]; then
    package_vers=$(cat "$build_tmp/emoncms-app/module.json" | jq -r '.version')
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

cp -r $build_tmp/emoncms-app $package_build/app
rm -r $package_build/app/.git*
rm $package_build/app/.travis.yml
rm $package_build/app/composer.json
rm $package_build/app/Readme.md
rm $package_build/app/LICENSE*
