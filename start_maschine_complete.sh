#!/bin/bash
# Quick start script for Maschine Mikro Driver (Complete)

echo "🎹 Maschine Mikro Driver - Instalación Completa"
echo "==============================================="
echo
echo "Choose an option:"
echo "1. Start Driver (MIDI Mode)"
echo "2. Start Driver (Native Maschine Mode)"
echo "3. Start Pad Monitor"
echo "4. Show device status"
echo "5. Exit"
echo
read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo "Starting Maschine Mikro Driver (MIDI mode)..."
        maschine-mikro-driver
        ;;
    2)
        echo "Starting Maschine Mikro Driver (Native mode)..."
        maschine-native-driver
        ;;
    3)
        if command -v maschine-pad-monitor >/dev/null 2>&1; then
            echo "Starting Pad Monitor..."
            maschine-pad-monitor
        else
            echo "Pad Monitor not available"
        fi
        ;;
    4)
        echo "Checking device status..."
        system_profiler SPUSBDataType | grep -A 10 -B 5 -i "maschine\|native instruments" || echo "No Maschine device found"
        system_profiler SPMIDIDataType | grep -A 5 -B 5 -i "maschine\|native instruments" || echo "No Maschine MIDI device found"
        ;;
    5)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
