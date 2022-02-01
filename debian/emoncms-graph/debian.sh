#!/bin/bash
#Description: Build script to generate the emoncms debian package
if [ ! -d $build_tmp/emoncms-graph ]; then
    git clone -b ${emoncms_modules[graph]} ${git_repo[graph]} $build_tmp/emoncms-graph
else
    git -C $build_tmp/emoncms-graph pull
fi
if [ -f "$build_tmp/emoncms-graph/module.json" ]; then
    package_vers=$(cat "$build_tmp/emoncms-graph/module.json" | jq -r '.version')
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

cp -r $build_tmp/emoncms-graph $package_build/graph
rm -r $package_build/graph/images
rm -r $package_build/graph/.git*
rm $package_build/graph/.travis.yml
rm $package_build/graph/composer.json
rm $package_build/graph/readme.md
rm $package_build/graph/LICENSE*
