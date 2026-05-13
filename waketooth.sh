#!/bin/bash
# Installer for automated Bluetooth fix after sleep (Bazzite / SteamOS Game Mode)

echo "Installing Bluetooth auto-fix..."

# Step 1: Create the main fix script
cat << 'EOF' | sudo tee /usr/local/bin/fix-bluetooth.sh > /dev/null
#!/bin/bash

echo "Attempting Bluetooth fix (Step 2: reload modules)..."

sudo systemctl stop bluetooth.service
sudo modprobe -r btusb bluetooth
sudo modprobe bluetooth btusb
sudo systemctl start bluetooth.service

if bluetoothctl list | grep -q "Controller"; then
    echo "Bluetooth restored successfully after module reload."
    exit 0
else
    echo "Step 2 failed. Trying Step 3: rfkill unblock..."
    sudo rfkill unblock bluetooth

    if bluetoothctl list | grep -q "Controller"; then
        echo "Bluetooth restored successfully after rfkill unblock."
        exit 0
    else
        echo "Bluetooth still not working. A reboot may be required."
        exit 1
    fi
fi
EOF

# Make it executable
sudo chmod +x /usr/local/bin/fix-bluetooth.sh

# Step 2: Create the systemd sleep hook
cat << 'EOF' | sudo tee /lib/systemd/system-sleep/bluetooth-fix.sh > /dev/null
#!/bin/bash

case $1/$2 in
  post/*)
    logger "bluetooth-fix: running after sleep"
    /usr/local/bin/fix-bluetooth.sh
    ;;
esac
EOF

# Make it executable
sudo chmod +x /lib/systemd/system-sleep/bluetooth-fix.sh

echo "Bluetooth auto-fix installed successfully."
echo "Test by suspending and resuming your system, then check logs with:"
echo "  journalctl -b | grep bluetooth-fix"
