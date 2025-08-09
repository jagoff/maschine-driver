#!/bin/bash
# Uninstall script for Maschine Mikro Driver (Complete)

set -e

BIN_DIR="/usr/local/bin"

echo "Uninstalling Maschine Mikro Driver (Complete)..."

# Remove executables
if [[ -f "$BIN_DIR/maschine-mikro-driver" ]]; then
    echo "Removing maschine-mikro-driver..."
    sudo rm -f "$BIN_DIR/maschine-mikro-driver"
fi

if [[ -f "$BIN_DIR/maschine-native-driver" ]]; then
    echo "Removing maschine-native-driver..."
    sudo rm -f "$BIN_DIR/maschine-native-driver"
fi

if [[ -f "$BIN_DIR/maschine-pad-monitor" ]]; then
    echo "Removing maschine-pad-monitor..."
    sudo rm -f "$BIN_DIR/maschine-pad-monitor"
fi

# Remove desktop shortcuts
if [[ -f ~/Desktop/Maschine\ Mikro\ Driver\ \(MIDI\).command ]]; then
    echo "Removing desktop shortcuts..."
    rm -f ~/Desktop/Maschine\ Mikro\ Driver\ \(MIDI\).command
    rm -f ~/Desktop/Maschine\ Mikro\ Driver\ \(Native\).command
    rm -f ~/Desktop/Maschine\ Pad\ Monitor.command
fi

# Remove symlinks
rm -f ./maschine-driver
rm -f ./maschine-native
rm -f ./maschine-monitor

echo "Uninstall complete!"
