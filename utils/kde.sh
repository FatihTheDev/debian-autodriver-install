#!/bin/bash
set -e
CODENAME=$1

echo "Installing KDE Plasma environment..."

sudo apt install -y -t "$CODENAME-backports" \
    kde-plasma-desktop \
    sddm \
    network-manager \
    network-manager-openvpn \
    plasma-nm \
    konsole \
    dolphin \
    firefox-esr

# Install printing support
echo "Installing printing support (CUPS and drivers)..."

sudo apt install -y \
    cups \
    system-config-printer \
    printer-driver-all

# Configure /etc/network/interfaces for NetworkManager
echo "Configuring /etc/network/interfaces for NetworkManager..."

sudo cp /etc/network/interfaces /etc/network/interfaces.bak

sudo sed -i '/^\s*iface\s\+\(lo\|lo0\)\b/! s/^\s*/# /' /etc/network/interfaces
sudo sed -i '/^\s*auto\s\+\(lo\|lo0\)\b/! s/^\s*/# /' /etc/network/interfaces

echo "/etc/network/interfaces adjusted for NetworkManager."

# Enable necessary services
sudo systemctl enable sddm
sudo systemctl enable NetworkManager
sudo systemctl enable cups

echo "KDE Plasma desktop installed and configured with printing support."

