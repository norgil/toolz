#!/usr/bin/env bash
set -eu

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Please run with sudo or as the root user."
  exit 1
fi

# Update package lists
echo "Updating package lists..."
apt update

# (Optional) Install wget and net-tools if not already installed
echo "Installing wget and net-tools..."
apt install -y wget net-tools

# Install fontconfig and OpenJDK 21
echo "Installing fontconfig and OpenJDK 21..."
apt install -y fontconfig openjdk-21-jre

# Install certbot, Nginx, and the certbot Nginx plugin
echo "Installing certbot, nginx, and python3-certbot-nginx..."
apt install -y certbot nginx python3-certbot-nginx

# Add the Jenkins repository key
echo "Downloading and installing the Jenkins repository key..."
wget -q -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian/jenkins.io-2023.key

# Add the Jenkins repository
echo "Adding the Jenkins repository..."
cat <<EOF >/etc/apt/sources.list.d/jenkins.list
deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/
EOF

# Update package lists after adding the Jenkins repository
echo "Updating package lists after adding Jenkins repository..."
apt update

# Install Jenkins
echo "Installing Jenkins..."
apt install -y jenkins

# Check Jenkins service status
echo "Initial Jenkins service status:"
systemctl status jenkins --no-pager

# Display network listening ports
echo "Current listening ports and services:"
netstat -lntp

# Create a systemd override directory for Jenkins (if it doesn't exist)
echo "Creating systemd override directory for Jenkins (if not already present)..."
mkdir -p /etc/systemd/system/jenkins.service.d

# Create an override configuration file for Jenkins' listen address.
# Adjust the configuration as needed for your environment.
echo "Creating systemd override configuration file for Jenkins..."
cat <<'EOF' >/etc/systemd/system/jenkins.service.d/10-listen-address-override.conf
[Service]
# Override Jenkins listening address
Environment="JENKINS_LISTEN_ADDRESS=127.0.0.1"
EOF

# Reload systemd to pick up the new configuration
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Restart Jenkins to apply any changes
echo "Restarting Jenkins..."
systemctl restart jenkins

# Check Jenkins service status after restart
echo "Jenkins service status after restart:"
systemctl status jenkins --no-pager

# Display network listening ports after Jenkins restart
echo "Listening ports and services after Jenkins restart:"
netstat -lntp

echo "Installation and configuration complete. Install certificates and configure nginx reverse proxy."
