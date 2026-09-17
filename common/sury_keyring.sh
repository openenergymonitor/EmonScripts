#!/bin/bash
# Shared helpers for the third party sury PHP apt repository
# (https://packages.sury.org/php), used by both install/ and update/.
#
# Source this file, then call sury_repair before any apt-get install that may
# need a package from sury. Nothing here changes the system unless sury is
# actually configured and actually broken.
#
# The keyring sury publishes is re-signed periodically. Images built before a
# re-signing carry an expired copy, so "apt-get update" reports EXPKEYSIG and
# apt then refuses to use the repository at all. Very old images added the key
# with apt-key instead, which modern apt no longer reads. Both cases are fixed
# by installing a fresh keyring and pointing the source line at it.

SURY_KEYRING="/usr/share/keyrings/suryphp-archive-keyring.gpg"
SURY_KEY_URL="https://packages.sury.org/php/apt.gpg"

# sudo is used throughout EmonScripts, but these helpers also run from scripts
# that are already root (and some minimal systems have no sudo at all).
if [ "$(id -u)" = "0" ]; then
    SURY_SUDO=""
else
    SURY_SUDO="sudo"
fi

# List the apt source files that reference sury. Empty output means the
# repository is not configured and there is nothing for us to do.
sury_sources() {
    grep -rlE '^[^#]*packages\.sury\.org' \
        /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null
}

sury_configured() {
    [ -n "$(sury_sources)" ]
}

# Download the current sury key and install it as a binary keyring.
# Everything is done in a temp file and validated before the live keyring is
# replaced, so a failed or hijacked download leaves the system as it was.
sury_install_keyring() {
    local tmpdir key
    tmpdir=$(mktemp -d) || return 1

    if ! curl -fsSL --retry 3 --connect-timeout 15 "$SURY_KEY_URL" -o "$tmpdir/apt.gpg"; then
        echo "-- WARNING: could not download the sury signing key from $SURY_KEY_URL"
        rm -rf "$tmpdir"
        return 1
    fi

    if [ ! -s "$tmpdir/apt.gpg" ]; then
        echo "-- WARNING: downloaded sury signing key is empty, ignoring"
        rm -rf "$tmpdir"
        return 1
    fi

    # A captive portal or an error page would otherwise be installed as a keyring
    if head -c 512 "$tmpdir/apt.gpg" | grep -qi '<html\|<!doctype'; then
        echo "-- WARNING: downloaded sury signing key is not a key, ignoring"
        rm -rf "$tmpdir"
        return 1
    fi

    key="$tmpdir/apt.gpg"

    # sury has published the key both armoured and binary over the years.
    # apt needs binary in a .gpg keyring, so dearmour if needed.
    if grep -q 'BEGIN PGP PUBLIC KEY BLOCK' "$tmpdir/apt.gpg"; then
        if ! command -v gpg >/dev/null 2>&1; then
            echo "-- WARNING: sury key is armoured but gpg is not installed, ignoring"
            rm -rf "$tmpdir"
            return 1
        fi
        if ! gpg --dearmor < "$tmpdir/apt.gpg" > "$tmpdir/apt.bin" 2>/dev/null || [ ! -s "$tmpdir/apt.bin" ]; then
            echo "-- WARNING: could not dearmour the sury signing key, ignoring"
            rm -rf "$tmpdir"
            return 1
        fi
        key="$tmpdir/apt.bin"
    fi

    # Final check that what we are about to install really is a public key
    if command -v gpg >/dev/null 2>&1; then
        if ! gpg --show-keys --with-colons "$key" 2>/dev/null | grep -q '^pub:'; then
            echo "-- WARNING: downloaded sury signing key did not validate, ignoring"
            rm -rf "$tmpdir"
            return 1
        fi
    fi

    $SURY_SUDO install -m 0644 "$key" "$SURY_KEYRING"
    local result=$?
    rm -rf "$tmpdir"

    if [ $result -ne 0 ]; then
        echo "-- WARNING: could not write $SURY_KEYRING"
        return 1
    fi

    echo "-- Installed current sury signing key at $SURY_KEYRING"
    return 0
}

# Point sury source lines at the keyring above. Images that added the key with
# apt-key have no signed-by, and apt will not fall back to the new keyring on
# its own. Only lines mentioning sury are touched, and the file is backed up.
sury_fix_signed_by() {
    local file line keypath changed=0
    for file in $(sury_sources); do
        case "$file" in
            *.sources)
                # deb822 format, only used by images that configured sury by
                # hand. Left alone rather than guessed at.
                grep -qi '^Signed-By:' "$file" || \
                    echo "-- NOTE: $file has no Signed-By, not modifying deb822 source automatically"
                continue
                ;;
        esac

        # Any uncommented sury line with no signed-by at all
        if awk '$0 !~ /^[[:space:]]*#/ && /packages\.sury\.org/ && !/signed-by=/ { found = 1 }
                END { exit !found }' "$file"; then
            echo "-- Adding signed-by=$SURY_KEYRING to $file"
            $SURY_SUDO cp -a "$file" "$file.emonscripts.bak" 2>/dev/null
            $SURY_SUDO sed -i -E \
                -e "\|^[^#]*packages\.sury\.org|{/signed-by=/!{
                        s|^(deb(-src)?)[[:space:]]+\[([^]]*)\][[:space:]]+|\\1 [\\3 signed-by=$SURY_KEYRING] |
                        s|^(deb(-src)?)[[:space:]]+(https?://)|\\1 [signed-by=$SURY_KEYRING] \\3|
                    }}" \
                "$file"
            changed=1
        fi

        # Or a signed-by pointing at a keyring that is no longer there, which
        # happens when an old image referenced a key added with apt-key
        while read -r keypath; do
            [ -n "$keypath" ] || continue
            [ -e "$keypath" ] && continue
            [ "$keypath" = "$SURY_KEYRING" ] && continue
            echo "-- $file references missing keyring $keypath, repointing at $SURY_KEYRING"
            [ -e "$file.emonscripts.bak" ] || $SURY_SUDO cp -a "$file" "$file.emonscripts.bak" 2>/dev/null
            $SURY_SUDO sed -i "\|^[^#]*packages\.sury\.org|s|signed-by=$keypath|signed-by=$SURY_KEYRING|" "$file"
            changed=1
        done < <(grep -E '^[^#]*packages\.sury\.org' "$file" \
                 | grep -oE 'signed-by=[^],[:space:]]+' | cut -d= -f2- | sort -u)
    done
    return $((1 - changed))
}

# True if the last apt-get update output shows sury failing to verify.
# A signing problem on some other repository is deliberately not our business.
sury_update_failed() {
    awk 'tolower($0) ~ /sury\.org/ &&
         /GPG error|NO_PUBKEY|EXPKEYSIG|KEYEXPIRED|is not signed|no longer signed|signatures were invalid/ \
             { found = 1 }
         END { exit !found }' "$1"
}

# Run apt-get update and, if sury is the thing that failed, refresh the key and
# try once more. Returns 0 if apt lists are usable for sury (or sury is not
# configured at all), 1 if the repository is still broken afterwards.
#
# Never aborts the caller: an unreachable network or an unrelated broken
# repository is reported and left alone.
sury_repair() {
    local log
    log=$(mktemp) || return 1

    $SURY_SUDO apt-get update 2>&1 | tee "$log"

    if ! sury_configured; then
        rm -f "$log"
        return 0
    fi

    if ! sury_update_failed "$log"; then
        rm -f "$log"
        return 0
    fi

    echo "-------------------------------------------------------------"
    echo "The sury PHP repository failed to verify, refreshing its key"
    echo "-------------------------------------------------------------"

    if ! sury_install_keyring; then
        echo "-- WARNING: sury repository is still unusable"
        rm -f "$log"
        return 1
    fi

    sury_fix_signed_by

    $SURY_SUDO apt-get update 2>&1 | tee "$log"

    if sury_update_failed "$log"; then
        echo "-- WARNING: sury repository still fails to verify after refreshing the key"
        rm -f "$log"
        return 1
    fi

    echo "-- sury repository verifies correctly again"
    rm -f "$log"
    return 0
}
