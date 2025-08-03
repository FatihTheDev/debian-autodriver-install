#!/bin/bash
set -e

CODENAME=$(lsb_release -cs)
ARCH=$(dpkg --print-architecture)

echo "Detected Debian codename: $CODENAME"
echo "Architecture: $ARCH"

# Add contrib, non-free, and non-free-firmware to all repos
echo "Adding contrib, non-free, and non-free-firmware components to all Debian repos..."

sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

sudo sed -i -r 's/^(deb\s+[^ ]+\s+[^ ]+)(\s+main)(.*)$/\1 main contrib non-free non-free-firmware\3/' /etc/apt/sources.list

for f in /etc/apt/sources.list.d/*.list; do
    [ -f "$f" ] || continue
    sudo sed -i -r 's/^(deb\s+[^ ]+\s+[^ ]+)(\s+main)(.*)$/\1 main contrib non-free non-free-firmware\3/' "$f"
done

echo "Done updating Debian repos."

# Enable backports
echo "Adding backports repo..."
echo "deb http://deb.debian.org/debian $CODENAME-backports main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/backports.list
sudo apt update

# Install latest kernel, headers and firmware from backports
echo "Installing latest kernel, headers and firmware from backports..."
sudo apt install -y -t "$CODENAME-backports" linux-image-amd64 linux-headers-amd64 firmware-misc-nonfree

# Detect GPUs present
GPU_INTEL=$(lspci | grep -i 'vga\|3d\|display' | grep -i intel || true)
GPU_NVIDIA=$(lspci | grep -i 'vga\|3d\|display' | grep -i nvidia || true)
GPU_AMD=$(lspci | grep -i 'vga\|3d\|display' | grep -i 'amd\|ati' || true)

echo "Detected GPUs:"
[[ -n "$GPU_INTEL" ]] && echo " - Intel GPU found"
[[ -n "$GPU_NVIDIA" ]] && echo " - NVIDIA GPU found"
[[ -n "$GPU_AMD" ]] && echo " - AMD GPU found"

# Logic for GPU combinations
if [[ -n "$GPU_INTEL" ]] && [[ -n "$GPU_NVIDIA" ]]; then
    echo "Optimus detected (Intel + NVIDIA)"
    bash drivers/intel.sh "$CODENAME"
    bash drivers/nvidia.sh "$CODENAME"
elif [[ -n "$GPU_AMD" ]] && [[ $(echo "$GPU_AMD" | wc -l) -ge 2 ]]; then
    # More than one AMD GPU (possible hybrid AMD iGPU+dGPU)
    echo "AMD hybrid graphics detected (multiple AMD GPUs)"
    bash drivers/amd.sh "$CODENAME"
elif [[ -n "$GPU_INTEL" ]]; then
    echo "Intel GPU detected"
    bash drivers/intel.sh "$CODENAME"
elif [[ -n "$GPU_NVIDIA" ]]; then
    echo "NVIDIA GPU detected"
    bash drivers/nvidia.sh "$CODENAME"
elif [[ -n "$GPU_AMD" ]]; then
    echo "AMD GPU detected"
    bash drivers/amd.sh "$CODENAME"
else
    echo "No supported GPU detected!"
    exit 1
fi

# Install KDE and networking tools
bash utils/kde.sh "$CODENAME"

# Generate reinstall-gpu.sh (also reinstalls kernel, headers and firmware)
cat <<EOF > ~/reinstall-gpu.sh
#!/bin/bash
set -e
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y -t $CODENAME-backports linux-image-amd64 linux-headers-amd64 firmware-misc-nonfree
EOF

# Append driver reinstall commands based on detected GPUs
if [[ -n "$GPU_INTEL" ]]; then
    echo "bash ~/.setup/debian-autodriver-install/drivers/intel.sh $CODENAME" >> ~/reinstall-gpu.sh
fi
if [[ -n "$GPU_NVIDIA" ]]; then
    echo "bash ~/.setup/debian-autodriver-install/drivers/nvidia.sh $CODENAME" >> ~/reinstall-gpu.sh
fi
if [[ -n "$GPU_AMD" ]]; then
    echo "bash ~/.setup/debian-autodriver-install/drivers/amd.sh $CODENAME" >> ~/reinstall-gpu.sh
fi

chmod +x ~/reinstall-gpu.sh

# Alias
if ! grep -q "alias full-update=" ~/.bashrc; then
    echo "alias full-update='bash ~/reinstall-gpu.sh'" >> ~/.bashrc
    echo "Added 'full-update' alias to ~/.bashrc"
else
    echo "Alias 'full-update' already exists"
fi

echo "Setup complete. Run 'full-update' to upgrade everything and refresh drivers."

