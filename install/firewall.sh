#!/bin/bash
# --------------------------------------------------------------------------------
# emonSD firewall: deny incoming connections except for the services below.
# Outgoing connections (updates, remote emoncms, sync) are not restricted.
#
# Run as root. Called by install/emonsd.sh, and at boot by
# emonsd-firewall.service when it could not be applied during the build
# (no usable iptables yet, e.g. the kernel was upgraded and not rebooted, or
# the image is being built in a container).
#
# Exits non-zero if any step fails. It never leaves ufw enabled without its
# allow rules: that would block the web interface and SSH.
# --------------------------------------------------------------------------------
set -e

ufw default deny incoming
ufw default allow outgoing
ufw allow 80/tcp comment 'emoncms web'
ufw allow 22/tcp comment 'ssh'
ufw allow 1883/tcp comment 'mqtt'
# emonpi.local name lookup (avahi)
ufw allow 5353/udp comment 'mdns'
# WiFi access point: NetworkManager's dnsmasq gives out addresses and answers
# DNS for the captive portal on ap0. Without these, setting up WiFi through
# the access point fails.
ufw allow in on ap0 to any port 67 proto udp comment 'access point dhcp'
ufw allow in on ap0 to any port 53 comment 'access point dns'

ufw --force enable
