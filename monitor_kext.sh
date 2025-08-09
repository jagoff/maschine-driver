#!/bin/bash

# Monitor kext logs and status

KEXT_NAME="com.nativeinstruments.MaschineMikroDriver"

echo "=== Maschine Mikro Driver Kext Monitor ==="
echo

echo "Kext Status:"
kextstat | grep "$KEXT_NAME" || echo "Kext not loaded"

echo
echo "Recent kernel logs (last 2 minutes):"
log show --predicate 'process == "kernel"' --last 2m | grep -i "maschine\|mikro\|$KEXT_NAME" || echo "No relevant logs found"

echo
echo "USB Device Status:"
system_profiler SPUSBDataType | grep -A 10 -B 5 -i "maschine\|native instruments" || echo "No Maschine devices found"

echo
echo "MIDI Devices:"
system_profiler SPMIDIDataType | grep -A 5 -B 5 -i "maschine\|native instruments" || echo "No Maschine MIDI devices found" 