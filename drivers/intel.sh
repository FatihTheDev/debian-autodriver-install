#!/bin/bash
set -e
CODENAME=$1

echo "Configuring Intel GPU to use the modern modesetting driver..."

# Remove legacy Intel Xorg driver (deprecated)
sudo apt remove -y xserver-xorg-video-intel || true

# Prompt user for VAAPI driver choice
echo ""
echo "Intel VAAPI Hardware Acceleration Driver Options:"
echo "1) intel-media-va-driver (Free, default)"
echo "2) intel-media-va-driver-non-free (Proprietary, better codec support)"
read -p "Choose VAAPI driver [1-2, default=1]: " choice

DRIVER="intel-media-va-driver"
if [[ "$choice" == "2" ]]; then
    DRIVER="intel-media-va-driver-non-free"
fi

echo "Installing: $DRIVER from $CODENAME-backports..."

# Install selected driver + helper tools
sudo apt install -y -t $CODENAME-backports "$DRIVER" libva-drm2 libva-x11-2 vainfo

echo "Intel GPU configured with '$DRIVER' and using modesetting driver."
echo "Run 'vainfo' to verify VAAPI support."

