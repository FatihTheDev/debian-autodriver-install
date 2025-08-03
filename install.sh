#!/bin/bash
set -e

CODENAME=$(lsb_release -cs)
ARCH=$(dpkg --print-architecture)

echo "Detected Debian codename: $CODENAME"
echo "Architecture: $ARCH"

# Enable backports
echo "Adding backports repo..."
echo "deb http://deb.debian.org/debian $CODENAME-backports main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/backports.list
sudo apt update

# Install latest kernel and headers from backports
echo "Installing latest kernel and headers from backports..."
sudo apt install -y -t "$CODENAME-backports" linux-image-amd64 linux-headers-amd64

# Detect GPU
GPU_VENDOR=$(lspci | grep -i 'vga\|3d\|display' | head -n1 | awk '{print tolower($0)}')
if echo "$GPU_VENDOR" | grep -q "intel"; then
    GPU_TYPE="intel"
elif echo "$GPU_VENDOR" | grep -E -q "amd|ati"; then
    GPU_TYPE="amd"
elif echo "$GPU_VENDOR" | grep -q "nvidia"; then
    GPU_TYPE="nvidia"
else
    echo "Unknown GPU vendor"
    exit 1
fi

echo "Detected GPU vendor: $GPU_TYPE"
bash "drivers/$GPU_TYPE.sh" "$CODENAME"

# Install KDE and networking tools
bash utils/kde.sh "$CODENAME"

# Generate reinstall-gpu.sh (also reinstalls kernel)
cat <<EOF > ~/reinstall-gpu.sh
#!/bin/bash
set -e
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y -t $CODENAME-backports linux-image-amd64 linux-headers-amd64
bash ~/debian-gpu-kde-install/drivers/$GPU_TYPE.sh $CODENAME
EOF

chmod +x ~/reinstall-gpu.sh

# Alias
if ! grep -q "alias full-update=" ~/.bashrc; then
    echo "alias full-update='bash ~/reinstall-gpu.sh'" >> ~/.bashrc
    echo "Added 'full-update' alias to ~/.bashrc"
else
    echo "Alias 'full-update' already exists"
fi

echo "Setup complete. Run 'full-update' to do a full dist-upgrade and refresh drivers."

