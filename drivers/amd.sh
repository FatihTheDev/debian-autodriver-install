#!/bin/bash
set -e
CODENAME=$1

echo "Installing AMD GPU drivers from $CODENAME-backports..."

sudo apt install -y vainfo

sudo apt install -y -t $CODENAME-backports firmware-amd-graphics libgl1-mesa-dri libglx-mesa0 mesa-vulkan-drivers mesa-va-drivers mesa-vdpau-drivers xserver-xorg-video-all


