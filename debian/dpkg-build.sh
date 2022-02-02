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

if [ ! -f $root_dir/install/config.ini ]; then
    cp $root_dir/install/emonpi.config.ini $root_dir/install/config.ini
fi
cd $debian_dir
source $debian_dir/dpkg.ini
source $root_dir/install/load_config.sh

rm -rf $build_dir/*

build_date="$(export LC_ALL=POSIX; date '+%a, %d %b %Y %H:%M:%S %z')"
build_tmp="$root_dir/build/tmp"

if [ ! -d $build_tmp/emoncms ]; then
    git clone -b $emoncms_core_branch ${git_repo[emoncms_core]} $build_tmp/emoncms
else
    git -C $build_tmp/emoncms pull
fi
if [ -f "$build_tmp/emoncms/version.txt" ]; then
    emoncms_version=$(cat "$build_tmp/emoncms/version.txt")

elif [ -f "$build_tmp/emoncms/version.json" ]; then
    emoncms_version=$(cat "$build_tmp/emoncms/version.json" | jq -r '.version')
else
    echo "Unable to find emoncms version file"
    exit 1
fi

for package in $(find $root_dir -name 'debian*.sh'); do
    package_dir=`dirname "${package}"`
    source $package

    cd $package_build
    chmod 755 $package_build/debian/pre* 2>/dev/null
    chmod 755 $package_build/debian/post* 2>/dev/null
    chmod 755 $package_build/debian/rules

	for deb_file in "conffiles" "config" "install" "prerm" "preinst" "postinst" "postrm"; do
	    deb_file_path=$package_build/debian/$deb_file
	    if [ -f $deb_file_path ]; then
			sed -i 's|<root_dir>|'$emoncms_www'|g'         $deb_file_path
			sed -i 's|<data_dir>|'$emoncms_datadir'|g'     $deb_file_path
			sed -i 's|<log_dir>|'$emoncms_log_location'|g' $deb_file_path
	    fi
	done

    for control in $(find $package_build/debian -name '*control'); do
        sed -i "s/<package>/$package_name/g"          $control
        sed -i "s/<version>/$package_vers/g"          $control
        sed -i "s/<maintainer>/$package_maintainer/g" $control
        sed -i "s|<repository>|$package_repository|g" $control
        sed -i "s|<homepage>|$package_homepage|g"     $control
    done

    sed -i "s/<date>/$build_date/g"               $package_build/debian/changelog
    sed -i "s/<package>/$package_name/g"          $package_build/debian/changelog
    sed -i "s/<version>/$package_vers/g"          $package_build/debian/changelog
    sed -i "s/<maintainer>/$package_maintainer/g" $package_build/debian/changelog
    sed -i "s|<repository>|$package_repository|g" $package_build/debian/copyright

    dpkg-buildpackage -us -uc
done
exit 0
