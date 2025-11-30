#!/usr/bin/env bash 
set -eu

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Exiting..."
    exit 1
fi

echo "Installing necessary packages..."
apt update
apt install -y apt-transport-https ca-certificates curl software-properties-common mc tree wget dnsutils net-tools p7zip-full screen rsync htop iftop lsof bmon traceroute git vim dnsmasq-base bridge-utils iptables socat unattended-upgrades xterm nginx certbot python3-certbot-nginx iputils-ping iperf3

echo "Reconfiguring unattended-upgrades..."
dpkg-reconfigure -p low unattended-upgrades

echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | bash

echo "Adding Docker GPG key and repository..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Updating package lists..."
apt update

echo "Upgrading installed packages..."
apt upgrade -y

echo "Checking docker-ce policy..."
apt-cache policy docker-ce

echo "Installing Docker CE..."
apt install -y docker-ce

echo "Checking Docker service status..."
systemctl status docker --no-pager

# Add the original invoking user to the docker group.
# When run with sudo, SUDO_USER contains the non-root username.
TARGET_USER="${SUDO_USER:-$USER}"
echo "Adding user '${TARGET_USER}' to the docker group..."
usermod -aG docker "${TARGET_USER}"

echo "Installation complete. Please log out and log back in (or restart) to apply Docker group changes."
