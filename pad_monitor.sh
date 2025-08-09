#!/bin/bash

# Monitor script for Maschine Mikro pad signals
# This script monitors MIDI input and displays pad activity in real-time

echo "🎹 Maschine Mikro Pad Monitor"
echo "=============================="
echo "Monitoring for pad signals..."
echo "Press Ctrl+C to stop monitoring"
echo ""

# Function to display pad info
show_pad_info() {
    local pad_num=$1
    local velocity=$2
    local note=$((36 + pad_num))  # C2 (36) + pad number
    
    # Pad layout (4x4 grid)
    local row=$((pad_num / 4 + 1))
    local col=$((pad_num % 4 + 1))
    
    # Velocity indicator
    local intensity=""
    if [ $velocity -gt 100 ]; then
        intensity="🔴 HARD"
    elif [ $velocity -gt 70 ]; then
        intensity="🟡 MED"
    elif [ $velocity -gt 40 ]; then
        intensity="🟢 SOFT"
    else
        intensity="⚪ LIGHT"
    fi
    
    echo "🎯 Pad $pad_num (Row $row, Col $col) - Note $note - $intensity (Velocity: $velocity)"
}

# Function to display timestamp
timestamp() {
    date '+%H:%M:%S.%3N'
}

# Monitor MIDI input using system_profiler and log show
echo "$(timestamp) - Starting MIDI monitoring..."

# Monitor system logs for MIDI activity
log stream --predicate 'process == "MIDIServer"' --style compact | while read line; do
    if echo "$line" | grep -q "Maschine\|MIDI\|note"; then
        echo "$(timestamp) - MIDI Activity: $line"
    fi
done &

# Monitor USB device activity
while true; do
    # Check for USB device activity
    if system_profiler SPUSBDataType | grep -A 5 "Maschine Mikro" | grep -q "Product ID"; then
        echo "$(timestamp) - Maschine Mikro detected and active"
    fi
    
    # Check MIDI destinations
    midi_destinations=$(system_profiler SPMIDIDataType 2>/dev/null | grep -A 10 "Maschine Mikro" | grep "Destination" | wc -l)
    if [ $midi_destinations -gt 0 ]; then
        echo "$(timestamp) - MIDI destinations available: $midi_destinations"
    fi
    
    sleep 1
done &

# Main monitoring loop
echo "$(timestamp) - Ready to capture pad signals..."
echo "Waiting for pad input..."

# Keep the script running
while true; do
    sleep 0.1
done 