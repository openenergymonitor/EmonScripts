#!/bin/bash
# --------------------------------------------------------------------------------
# Verify an emonSD / emoncms build
#
# Read only: checks the result of install/main.sh and changes nothing.
# Run after the post-build reboot, before preparing and imaging the card:
#
#     cd /opt/openenergymonitor/EmonScripts/install
#     ./verify.sh
#
# Exit status is 1 if any check failed, 0 otherwise. Warnings are
# things to look at but do not fail the build.
# --------------------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"
source load_config.sh

fails=0
warns=0

pass() { echo "  PASS  $1"; }
warn() { echo "  WARN  $1"; warns=$((warns+1)); }
fail() { echo "  FAIL  $1"; fails=$((fails+1)); }
section() { echo; echo "-- $1"; }

unit_exists() {
    [ -n "$(systemctl list-unit-files "$1.service" --no-legend 2>/dev/null)" ]
}

check_service() {
    local service=$1 required=$2
    if ! unit_exists "$service"; then
        if [ "$required" = "required" ]; then fail "$service: not installed"; else warn "$service: not installed"; fi
        return
    fi
    local active enabled
    active=$(systemctl is-active "$service" 2>/dev/null)
    enabled=$(systemctl is-enabled "$service" 2>/dev/null)
    if [ "$active" = "active" ] && [ "$enabled" = "enabled" ]; then
        pass "$service: active, enabled"
    elif [ "$required" = "required" ]; then
        fail "$service: $active, $enabled"
    else
        warn "$service: $active, $enabled"
    fi
}

echo "-------------------------------------------------------------"
echo "emonSD build verification: $(date)"
echo "-------------------------------------------------------------"
if [ -f /etc/os-release ]; then
    echo "OS: $(. /etc/os-release && echo "$PRETTY_NAME"), $(dpkg --print-architecture)"
fi

# --------------------------------------------------------------------------------
section "Services"
[ "$install_apache" = true ] && check_service apache2 required
[ "$install_mysql" = true ] && check_service mariadb required
[ "$install_redis" = true ] && check_service redis-server required
[ "$install_mosquitto_server" = true ] && check_service mosquitto required
if [ "$install_redis" = true ]; then
    check_service feedwriter required
    check_service service-runner required
    [ "$install_mosquitto_client" = true ] && check_service emoncms_mqtt required
fi
if [ "$emonSD_pi_env" = "1" ]; then
    [ "$install_emonhub" = true ] && check_service emonhub required
    # Only runs usefully on emonPi hardware, so not a build failure
    [ "$install_emonpilcd" = true ] && check_service emonPiLCD optional
fi

failed_units=$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}' | tr '\n' ' ')
if [ -z "$failed_units" ]; then
    pass "no failed systemd units"
else
    warn "failed systemd units: $failed_units"
fi

# --------------------------------------------------------------------------------
if [ "$install_php" = true ]; then
    section "PHP"
    if ! command -v php >/dev/null 2>&1; then
        fail "php not installed"
    else
        php_ver=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
        echo "        PHP $php_ver"

        apache_php=$(a2query -m 2>/dev/null | sed -nE 's/^php([0-9]+\.[0-9]+).*/\1/p' | head -n1)
        if [ -z "$apache_php" ]; then
            warn "no php module enabled in apache"
        elif [ "$apache_php" = "$php_ver" ]; then
            pass "apache and CLI both use PHP $php_ver"
        else
            fail "apache uses PHP $apache_php but CLI uses PHP $php_ver"
        fi

        php_modules=$(php -m 2>/dev/null)
        expected="redis dom gd curl mbstring"
        [ "$install_mysql" = true ] && expected="$expected mysqli"
        [ "$install_mosquitto_client" = true ] && expected="$expected mosquitto"
        for module in $expected; do
            if printf '%s\n' "$php_modules" | grep -qix "$module"; then
                pass "php extension: $module"
            else
                fail "php extension missing: $module"
            fi
        done

        # The extension packages are versioned per PHP, check apache has them too
        for module in redis mosquitto; do
            ini=$(ls /etc/php/$php_ver/apache2/conf.d/*-$module.ini 2>/dev/null | head -n1)
            if printf '%s\n' "$php_modules" | grep -qix "$module" && [ -z "$ini" ]; then
                warn "php extension $module loaded in CLI but not enabled for apache"
            fi
        done
    fi

    if grep -rqsE '^[^#]*packages\.sury\.org' /etc/apt/sources.list /etc/apt/sources.list.d/; then
        warn "sury apt repository is configured, new builds use the distribution's PHP"
    else
        pass "no sury apt repository"
    fi
fi

# --------------------------------------------------------------------------------
section "Python"
python_lib_dir=$(python3 -c 'import sysconfig; print(sysconfig.get_paths()["stdlib"])' 2>/dev/null)
echo "        $(python3 --version 2>&1)"
if [ -e "$python_lib_dir/EXTERNALLY-MANAGED" ]; then
    fail "pip external management marker still present: $python_lib_dir/EXTERNALLY-MANAGED"
else
    pass "pip external management marker removed"
fi

python_modules="redis"
if [ "$emonSD_pi_env" = "1" ] && [ "$install_emonhub" = true ]; then
    python_modules="$python_modules paho.mqtt.client serial configobj"
fi
for module in $python_modules; do
    if python3 -c "import $module" >/dev/null 2>&1; then
        pass "python module: $module"
    else
        fail "python module missing: $module"
    fi
done

# --------------------------------------------------------------------------------
section "Backends"
if [ "$install_redis" = true ]; then
    if [ "$(redis-cli ping 2>/dev/null)" = "PONG" ]; then pass "redis responds"; else fail "redis does not respond"; fi
fi

if [ "$install_mysql" = true ]; then
    if MYSQL_PWD="$mysql_password" mysql -u "$mysql_user" "$mysql_database" -e "SELECT 1" >/dev/null 2>&1; then
        pass "mysql: $mysql_user can connect to $mysql_database"
        tables=$(MYSQL_PWD="$mysql_password" mysql -N -u "$mysql_user" "$mysql_database" -e "SHOW TABLES" 2>/dev/null | wc -l)
        if [ "$tables" -gt 0 ]; then pass "mysql: $tables tables in $mysql_database"; else fail "mysql: $mysql_database has no tables"; fi
    else
        fail "mysql: $mysql_user cannot connect to $mysql_database"
    fi
fi

if [ "$install_mosquitto_server" = true ] && command -v mosquitto_pub >/dev/null 2>&1; then
    if mosquitto_pub -h localhost -u "$mqtt_user" -P "$mqtt_password" -t emonsd/verify -m test >/dev/null 2>&1; then
        pass "mosquitto accepts $mqtt_user"
    else
        fail "mosquitto rejects $mqtt_user or is not listening"
    fi
fi

# --------------------------------------------------------------------------------
if [ "$install_emoncms_core" = true ]; then
    section "Emoncms"
    if [ -f "$emoncms_www/settings.ini" ]; then pass "settings.ini present"; else fail "settings.ini missing"; fi

    for engine in phpfina phptimeseries; do
        owner=$(stat -c %U "$emoncms_datadir/$engine" 2>/dev/null)
        if [ "$owner" = "www-data" ]; then pass "$emoncms_datadir/$engine owned by www-data"; else fail "$emoncms_datadir/$engine owner: ${owner:-missing}"; fi
    done

    if [ "$install_apache" = true ]; then
        code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 http://localhost/emoncms/ 2>/dev/null)
        if [ "$code" = "200" ]; then pass "http://localhost/emoncms/ returns 200"; else fail "http://localhost/emoncms/ returns ${code:-no response}"; fi

        body=$(curl -s --max-time 15 http://localhost/emoncms/ 2>/dev/null)
        if printf '%s' "$body" | grep -qiE 'fatal error|warning:|parse error'; then
            fail "emoncms page contains a PHP error"
        fi
    fi

    # Ignore routine access errors (not logged in, bad API key, failed login)
    log_errors=""
    if [ -s "$emoncms_log_location/emoncms.log" ]; then
        log_errors=$(grep -E '\|(ERROR|CRITICAL)\|' "$emoncms_log_location/emoncms.log" | \
            grep -vE 'Not Admin|Not Authenticated|Invalid API key|Login: ')
    fi
    if [ -n "$log_errors" ]; then
        warn "errors in $emoncms_log_location/emoncms.log:"
        printf '%s\n' "$log_errors" | tail -n 5 | sed 's/^/          /'
    fi
fi

# --------------------------------------------------------------------------------
# Repositories with local changes are skipped by update_component.sh, so a
# device built from this image would silently never update them.
section "Repositories"
repos="$emoncms_www"
for path in "$emoncms_www"/Modules/* "$emoncms_dir"/modules/* "$openenergymonitor_dir"/*; do
    [ -d "$path/.git" ] && repos="$repos $path"
done
for repo in $repos; do
    [ -d "$repo/.git" ] || continue
    branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)
    changes=$(git -C "$repo" diff-index -G. HEAD -- 2>/dev/null)
    if [ -n "$changes" ]; then
        fail "$repo ($branch): local changes, updates will skip it"
    elif [ "$branch" != "stable" ] && [ "$branch" != "master" ] && [ "$branch" != "main" ]; then
        warn "$repo is on branch $branch"
    else
        pass "$repo ($branch)"
    fi
done

# --------------------------------------------------------------------------------
if [ "$emonSD_pi_env" = "1" ]; then
    section "emonSD"
    image_version=$(ls /boot 2>/dev/null | grep '^emonSD-' | head -n1)
    if [ -z "$image_version" ]; then
        fail "no /boot/emonSD-* version file"
    else
        pass "image version: $image_version"
        if [ -d /boot/firmware ] && [ ! -e "/boot/firmware/$image_version" ]; then
            fail "$image_version missing from /boot/firmware"
        fi
        if grep -qx "$image_version" "$openenergymonitor_dir/EmonScripts/safe-update" 2>/dev/null; then
            pass "$image_version is in safe-update"
        else
            warn "$image_version is not in safe-update, add it on master before release or devices cannot update"
        fi
        count=$(ls /boot 2>/dev/null | grep -c '^emonSD-')
        [ "$count" -gt 1 ] && warn "more than one emonSD-* version file in /boot"
    fi

    if mountpoint -q "$emoncms_datadir"; then
        pass "$emoncms_datadir is a separate partition ($(findmnt -no FSTYPE "$emoncms_datadir"))"
    else
        warn "$emoncms_datadir is not a separate partition"
    fi

    if sudo -n true 2>/dev/null; then
        for file in /etc/sudoers.d/*; do
            [ -f "$file" ] || continue
            if sudo -n visudo -cqf "$file" >/dev/null 2>&1; then pass "sudoers: $file"; else fail "sudoers invalid: $file"; fi
        done
    else
        warn "sudoers not checked, needs passwordless sudo"
    fi

    if [ "$install_emonsd" = true ]; then
        if ! command -v ufw >/dev/null 2>&1; then
            fail "ufw not installed"
        elif ! sudo -n true 2>/dev/null; then
            warn "firewall not checked, needs passwordless sudo"
        else
            ufw_status=$(sudo -n ufw status 2>/dev/null)
            if printf '%s\n' "$ufw_status" | grep -q '^Status: active'; then
                pass "firewall active"
            elif grep -q '^ENABLED=yes' /etc/ufw/ufw.conf 2>/dev/null; then
                fail "firewall enabled in ufw.conf but not running, reboot and check again"
            else
                fail "firewall not enabled"
            fi
            for rule in 80/tcp 22/tcp 1883/tcp 5353/udp '67/udp on ap0' '53 on ap0'; do
                if printf '%s\n' "$ufw_status" | grep -q "^$rule "; then
                    pass "firewall allows $rule"
                else
                    fail "firewall rule missing: $rule"
                fi
            done
        fi
    fi

    if [ "$install_docker" = true ]; then
        if command -v docker >/dev/null 2>&1; then
            pass "docker installed ($(systemctl is-enabled docker 2>/dev/null))"
        else
            fail "docker not installed"
        fi
    fi
fi

# --------------------------------------------------------------------------------
section "Build log"
for log in ~/init.sh.log ~/main.sh.log; do
    [ -f "$log" ] || continue
    hits=$(grep -inE '^E: |error:|errors were encountered|command not found|no such file|unable to locate package|externally-managed-environment' "$log" | grep -viE 'error_log|errors\.php|liberror|-error|error-' )
    if [ -z "$hits" ]; then
        pass "$log: no errors found"
    else
        warn "$log: $(printf '%s\n' "$hits" | wc -l) possible errors, last few:"
        printf '%s\n' "$hits" | tail -n 8 | sed 's/^/          /'
    fi
done

# --------------------------------------------------------------------------------
echo
echo "-------------------------------------------------------------"
echo "Result: $fails failed, $warns warnings"
echo "-------------------------------------------------------------"
[ "$fails" -eq 0 ]
