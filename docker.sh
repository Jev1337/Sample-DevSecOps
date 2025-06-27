#!/bin/bash

# This script automates the installation of Docker on Debian-based Linux distributions (like Ubuntu)
# based on the official Docker repository.
# It's crucial to run this script with sudo privileges.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- 1. PREPARATION ---

# Update the apt package index to make sure we have the latest list of available packages.
echo "[+] Updating package list..."
sudo apt-get update

# Install prerequisite packages which allow apt to use a repository over HTTPS.
echo "[+] Installing prerequisite packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# --- 2. ADD DOCKER'S OFFICIAL GPG KEY ---

# Create the directory for keyring if it doesn't exist
sudo install -m 0755 -d /etc/apt/keyrings

# Download Docker's official GPG key to ensure the downloads are authentic.
echo "[+] Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# --- 3. SET UP THE DOCKER REPOSITORY ---

# Add the official Docker repository to your system's APT sources.
# This ensures you get the latest version of Docker directly from the source.
echo "[+] Setting up the Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# --- 4. INSTALL DOCKER ENGINE ---

# Update the apt package index again to include the packages from the new Docker repository.
echo "[+] Updating package list again for Docker repository..."
sudo apt-get update

# Install the latest version of Docker Engine, containerd, and Docker Compose.
echo "[+] Installing Docker Engine..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# --- 5. POST-INSTALLATION STEPS ---

# Verify that the Docker service is running.
echo "[+] Verifying Docker service status..."
sudo systemctl status docker

# Add the current user to the 'docker' group to run docker commands without sudo.
# This avoids having to type 'sudo' for every docker command.
echo "[+] Adding current user (${USER}) to the 'docker' group..."
sudo usermod -aG docker ${USER}

# --- 6. FINAL VERIFICATION ---

echo ""
echo "✅ Docker has been successfully installed!"
echo "🚀 You can verify the installation by running: docker --version"
echo ""
echo "❗ IMPORTANT: You need to log out and log back in for the group changes to take effect."
echo "After logging back in, you'll be able to run 'docker' commands without 'sudo'."


