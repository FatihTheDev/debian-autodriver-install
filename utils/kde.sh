#!/bin/bash
set -e
CODENAME=$1

echo "🎨 Installing KDE Plasma environment..."

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

# Enable necessary services
sudo systemctl enable sddm
sudo systemctl enable NetworkManager
sudo systemctl enable cups

echo "✅ KDE Plasma desktop installed and configured with printing support."

