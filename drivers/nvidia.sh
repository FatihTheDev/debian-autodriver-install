#!/bin/bash
set -e
CODENAME=$1

echo "🔧 Installing NVIDIA proprietary drivers from $CODENAME-backports..."
sudo apt install -y -t $CODENAME-backports \
    nvidia-driver \
    nvidia-settings \
    nvidia-vdpau-driver \

# Check for Intel iGPU (Optimus detection)
if lspci | grep -i "vga" | grep -qi "intel"; then
  echo "Optimus system detected (Intel + NVIDIA). Setting up PRIME offloading..."

  # Create a wrapper script for offloading apps
  cat <<'EOF' | sudo tee /usr/local/bin/nvidia-run >/dev/null
#!/bin/bash
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only "$@"
EOF

  sudo chmod +x /usr/local/bin/nvidia-run

  echo "✅ Use 'nvidia-run <app>' to launch apps using the NVIDIA GPU"
else
  echo "ℹ️ This system does not appear to use Optimus (hybrid GPU setup)"
fi

echo "⚠️ A reboot is recommended to apply driver and kernel module changes."
