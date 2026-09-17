#!/bin/bash
# Ensure the PHP XML/DOM extension is available.
#
# The dashboard module needs the DOM extension. On older installs it was only
# present as a dependency of php-pear, so some deployed systems do not have it.
#
# This has to be safe across every image on the safe-update list (buster
# through to current) and on non-emonSD Debian/Ubuntu installs:
#
#  - Does nothing at all if the extension is already installed.
#  - Installs the *versioned* package (php8.1-xml) for the PHP that is actually
#    running. The unversioned php-xml metapackage on the sury repository
#    follows the newest PHP sury publishes, so it would pull in a whole new PHP
#    stack and silently orphan the compiled phpredis and mosquitto extensions.
#  - Repairs the sury signing key first if, and only if, sury is configured and
#    is what is failing.
#  - Never fails the update: if the package cannot be found we warn and move on
#    rather than leave apt in a half applied state.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "-------------------------------------------------------------"
echo "Check PHP XML/DOM extension"
echo "-------------------------------------------------------------"

if ! command -v php >/dev/null 2>&1; then
    echo "-- php not installed, skipping"
    exit 0
fi

# Prefer the version apache runs, emoncms runs under apache rather than the CLI
php_ver=$(a2query -m 2>/dev/null | sed -nE 's/^php([0-9]+\.[0-9]+).*/\1/p' | head -n1)
if [ -z "$php_ver" ]; then
    php_ver=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
fi

if [ -z "$php_ver" ]; then
    echo "-- could not determine the PHP version, skipping"
    exit 0
fi

package="php$php_ver-xml"
echo "-- PHP version: $php_ver"

if [ "$(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null)" = "installed" ]; then
    echo "-- $package already installed"
    exit 0
fi

if php -m 2>/dev/null | grep -qx "dom"; then
    echo "-- DOM extension already available"
    exit 0
fi

echo "-- $package is missing, installing"

# Lists on a system that has not updated in a long time will not have the
# package, and sury may be failing to verify. Fix both before asking apt.
if [ -f "$DIR/../common/sury_keyring.sh" ]; then
    source "$DIR/../common/sury_keyring.sh"
    sury_repair
else
    sudo apt-get update
fi

if [ -z "$(apt-cache policy "$package" 2>/dev/null | sed -n 's/^  Candidate: //p' | grep -v '(none)')" ]; then
    echo "-- WARNING: $package is not available from any configured repository."
    echo "--          Skipping, the dashboard module may not render correctly."
    exit 0
fi

if ! sudo apt-get install -y "$package"; then
    echo "-- WARNING: failed to install $package, continuing"
    exit 0
fi

if php -m 2>/dev/null | grep -qx "dom"; then
    echo "-- DOM extension installed"
else
    echo "-- WARNING: $package installed but the DOM extension is still not loaded"
fi

exit 0
