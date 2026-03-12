#!/bin/bash

echo "-- Installing Docker"
# 1. Update package list and install initial dependencies
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# 2. Add Docker's official GPG key (Updated to use .asc as per current docs)
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 3. Set up Docker's APT repository using the 'debian' path (which supports Trixie)
echo "-- set up docker's APT repository"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Install Docker Engine and related plugins
sudo apt-get update
echo "-- apt-get install docker & dependencies"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Handle user group permissions
echo "-- add user to docker group"
# Check if 'pi' exists; if not, use the current logged-in user
if id "pi" &>/dev/null; then
    sudo usermod -aG docker pi
    echo "User 'pi' added to docker group."
else
    sudo usermod -aG docker $USER
    echo "Current user '$USER' added to docker group."
fi

# 6. Service Management
echo "-- disable docker.service for now"
sudo systemctl disable --now docker.service

echo "Done! Restart your session (log out and back in) to use docker without sudo."
