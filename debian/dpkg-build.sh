#!/bin/bash
#Description: Build script to generate the emoncms debian package
if [ $(id -u) != 0 ]; then
    echo "DPKG build process should be performed with root privileges." 1>&2
    exit 1
fi
debian_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd )"
root_dir="$(dirname "$debian_dir")"
build_dir="$root_dir/build/dpkg"
defaults_dir="$root_dir/defaults"

if ! dpkg -l | grep -q -e "\<git\>"; then
    apt-get -y install git
fi
if ! dpkg -l | grep -q -e "\<jq\>"; then
    apt-get -y install jq
fi
if [ -f "$root_dir/module.json" ]; then
    version=$(cat "$root_dir/module.json" | jq -r '.version')

elif [ -f "$root_dir/version.json" ]; then
    version=$(cat "$root_dir/version.json" | jq -r '.version')
else
    echo "Unable to find module or version file"
    exit 1
fi

if [ ! -f $debian_dir/config.ini ]; then
    cp $root_dir/install/emonsd.config.ini $debian_dir/config.ini
fi
cd $debian_dir
source $debian_dir/dpkg.ini
source $root_dir/install/load_config.sh

rm -rf $build_dir/*

package_date="$(date '+%a, %d %b %Y %H:%M:%S %:z')"

for package in $(find $root_dir -name 'debian*.sh'); do
    package_dir=`dirname "${package}"`
    source $package

    cd $package_build
    chmod 755 $package_build/debian/pre* 2>/dev/null
    chmod 755 $package_build/debian/post* 2>/dev/null
    chmod 755 $package_build/debian/rules

    sed -i "s/<package>/$package_name/g"          $package_build/debian/control
    sed -i "s/<version>/$package_vers/g"          $package_build/debian/control
    sed -i "s/<maintainer>/$package_maintainer/g" $package_build/debian/control
    sed -i "s|<repository>|$package_repository|g" $package_build/debian/control
    sed -i "s|<homepage>|$package_homepage|g"     $package_build/debian/control

    sed -i "s/<date>/$package_date/g"             $package_build/debian/changelog
    sed -i "s/<package>/$package_name/g"          $package_build/debian/changelog
    sed -i "s/<version>/$package_vers/g"          $package_build/debian/changelog
    sed -i "s/<maintainer>/$package_maintainer/g" $package_build/debian/changelog
    sed -i "s|<repository>|$package_repository|g" $package_build/debian/copyright

    dpkg-buildpackage -us -uc
done
exit 0
