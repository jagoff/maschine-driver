#!/bin/bash

# Status script for Maschine Mikro Driver Project
# Shows the current state of all components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Maschine Mikro Driver Project Status ===${NC}"
echo

# Check project files
echo -e "${BLUE}Project Files:${NC}"
files=(
    "MaschineMikroDriver.cpp"
    "MaschineMikroDriver.h"
    "Info.plist"
    "Makefile.kext"
    "install_kext.sh"
    "test_kext.sh"
    "monitor_kext.sh"
    "user_driver.cpp"
    "pad_monitor.cpp"
    "pad_monitor.sh"
    "README.md"
)

for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file (missing)"
    fi
done

echo

# Check build artifacts
echo -e "${BLUE}Build Artifacts:${NC}"
if [[ -d "build" ]]; then
    echo -e "  ${GREEN}✓${NC} build/ directory exists"
    if [[ -d "build/MaschineMikroDriver.kext" ]]; then
        echo -e "  ${GREEN}✓${NC} build/MaschineMikroDriver.kext"
    else
        echo -e "  ${YELLOW}⚠${NC} build/MaschineMikroDriver.kext (not built)"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} build/ directory (not created)"
fi

if [[ -f "user_driver" ]]; then
    echo -e "  ${GREEN}✓${NC} user_driver executable"
else
    echo -e "  ${YELLOW}⚠${NC} user_driver (not built)"
fi

if [[ -f "pad_monitor" ]]; then
    echo -e "  ${GREEN}✓${NC} pad_monitor executable"
else
    echo -e "  ${YELLOW}⚠${NC} pad_monitor (not built)"
fi

echo

# Check kext installation
echo -e "${BLUE}Kernel Extension Status:${NC}"
KEXT_NAME="com.nativeinstruments.MaschineMikroDriver"
KEXT_BUNDLE="MaschineMikroDriver.kext"

if kextstat | grep -q "$KEXT_NAME"; then
    echo -e "  ${GREEN}✓${NC} Kext is loaded and running"
    kextstat | grep "$KEXT_NAME"
else
    echo -e "  ${RED}✗${NC} Kext is not loaded"
fi

if [[ -d "/Library/Extensions/$KEXT_BUNDLE" ]]; then
    echo -e "  ${GREEN}✓${NC} Kext installed in /Library/Extensions"
else
    echo -e "  ${YELLOW}⚠${NC} Kext not installed"
fi

echo

# Check device detection
echo -e "${BLUE}Device Detection:${NC}"
USB_DEVICE=$(system_profiler SPUSBDataType | grep -A 5 -B 5 -i "maschine\|native instruments" | grep -E "(Product ID|Vendor ID)" || true)
if [[ -n "$USB_DEVICE" ]]; then
    echo -e "  ${GREEN}✓${NC} Maschine device detected via USB"
    echo "    $USB_DEVICE"
else
    echo -e "  ${YELLOW}⚠${NC} No Maschine USB device detected"
fi

MIDI_DEVICE=$(system_profiler SPMIDIDataType | grep -A 3 -B 3 -i "maschine\|native instruments" || true)
if [[ -n "$MIDI_DEVICE" ]]; then
    echo -e "  ${GREEN}✓${NC} Maschine device detected via MIDI"
else
    echo -e "  ${YELLOW}⚠${NC} No Maschine MIDI device detected"
fi

echo

# Check system requirements
echo -e "${BLUE}System Requirements:${NC}"
MACOS_VERSION=$(sw_vers -productVersion)
echo -e "  ${GREEN}✓${NC} macOS $MACOS_VERSION"

if command -v xcodebuild >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Xcode Command Line Tools"
else
    echo -e "  ${RED}✗${NC} Xcode Command Line Tools (missing)"
fi

SIP_STATUS=$(csrutil status | grep -o "enabled\|disabled")
if [[ "$SIP_STATUS" == "disabled" ]]; then
    echo -e "  ${GREEN}✓${NC} SIP is disabled (kext installation possible)"
else
    echo -e "  ${YELLOW}⚠${NC} SIP is enabled (may block kext installation)"
fi

echo

# Show recent activity
echo -e "${BLUE}Recent Activity:${NC}"
RECENT_LOGS=$(log show --predicate 'process == "kernel"' --last 2m | grep -i "maschine\|mikro\|$KEXT_NAME" | tail -3 || true)
if [[ -n "$RECENT_LOGS" ]]; then
    echo "Recent kernel logs:"
    echo "$RECENT_LOGS"
else
    echo "No recent kext activity in logs"
fi

echo

# Show next steps
echo -e "${BLUE}Next Steps:${NC}"
if ! kextstat | grep -q "$KEXT_NAME"; then
    echo "1. Install kext: sudo ./install_kext.sh"
fi

if [[ ! -f "user_driver" ]]; then
    echo "2. Build user tools: make user_driver"
fi

if [[ ! -f "pad_monitor" ]]; then
    echo "3. Build pad monitor: make pad_monitor"
fi

echo "4. Test installation: ./test_kext.sh"
echo "5. Monitor activity: ./monitor_kext.sh"
echo "6. Test with DAW: Connect device and check MIDI preferences"

echo
echo -e "${BLUE}Available Commands:${NC}"
echo "  sudo ./install_kext.sh    - Install kext"
echo "  ./test_kext.sh           - Test installation"
echo "  ./monitor_kext.sh        - Monitor activity"
echo "  sudo ./uninstall_kext.sh - Uninstall kext"
echo "  make user_driver         - Build user-space driver"
echo "  make pad_monitor         - Build pad monitor"
echo "  ./user_driver            - Test user-space driver"
echo "  ./pad_monitor            - Visual pad monitor"
echo "  ./pad_monitor.sh         - Shell-based pad monitor"

echo
echo -e "${GREEN}Status check complete!${NC}" 