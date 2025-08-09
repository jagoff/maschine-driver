#!/bin/bash
# Quick start script for Maschine Mikro Driver

echo "🎹 Maschine Mikro Driver Quick Start"
echo "====================================="
echo
echo "Choose an option:"
echo "1. Start Driver Test Program"
echo "2. Start Pad Monitor"
echo "3. Show device status"
echo "4. Exit"
echo
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo "Starting Maschine Mikro Driver..."
        maschine-mikro-driver
        ;;
    2)
        echo "Starting Pad Monitor..."
        maschine-pad-monitor
        ;;
    3)
        echo "Checking device status..."
        system_profiler SPUSBDataType | grep -A 10 -B 5 -i "maschine\|native instruments" || echo "No Maschine device found"
        system_profiler SPMIDIDataType | grep -A 5 -B 5 -i "maschine\|native instruments" || echo "No Maschine MIDI device found"
        ;;
    4)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
