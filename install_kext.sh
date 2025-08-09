#!/bin/bash

# Maschine Mikro Driver Kext Installer
# This script compiles, installs, and loads the kernel extension

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
KEXT_NAME="com.nativeinstruments.MaschineMikroDriver"
KEXT_BUNDLE="MaschineMikroDriver.kext"
BUILD_DIR="build"
INSTALL_DIR="/Library/Extensions"

echo -e "${BLUE}=== Maschine Mikro Driver Kext Installer ===${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
   echo "This is required to install and load kernel extensions."
   exit 1
fi

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
echo -e "${BLUE}macOS Version: ${MACOS_VERSION}${NC}"

# Check SIP status
echo -e "${BLUE}Checking System Integrity Protection (SIP) status...${NC}"
SIP_STATUS=$(csrutil status | grep -o "enabled\|disabled")
if [[ "$SIP_STATUS" == "enabled" ]]; then
    echo -e "${YELLOW}Warning: SIP is enabled. You may need to disable it to install kexts.${NC}"
    echo -e "${YELLOW}To disable SIP:${NC}"
    echo -e "${YELLOW}1. Restart and hold Cmd+R to enter Recovery Mode${NC}"
    echo -e "${YELLOW}2. Open Terminal and run: csrutil disable${NC}"
    echo -e "${YELLOW}3. Restart normally${NC}"
    echo
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}SIP is disabled - good!${NC}"
fi

# Create build directory
echo -e "${BLUE}Creating build directory...${NC}"
mkdir -p "$BUILD_DIR"

# Check if Makefile.kext exists
if [[ ! -f "Makefile.kext" ]]; then
    echo -e "${RED}Error: Makefile.kext not found${NC}"
    exit 1
fi

# Compile the kext
echo -e "${BLUE}Compiling kernel extension...${NC}"
if make -f Makefile.kext; then
    echo -e "${GREEN}✓ Compilation successful${NC}"
else
    echo -e "${RED}✗ Compilation failed${NC}"
    exit 1
fi

# Check if kext was created
if [[ ! -d "$BUILD_DIR/$KEXT_BUNDLE" ]]; then
    echo -e "${RED}Error: Kext bundle not found in build directory${NC}"
    exit 1
fi

# Backup existing kext if it exists
if [[ -d "$INSTALL_DIR/$KEXT_BUNDLE" ]]; then
    echo -e "${BLUE}Backing up existing kext...${NC}"
    mv "$INSTALL_DIR/$KEXT_BUNDLE" "$INSTALL_DIR/${KEXT_BUNDLE}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Install the kext
echo -e "${BLUE}Installing kext to $INSTALL_DIR...${NC}"
cp -R "$BUILD_DIR/$KEXT_BUNDLE" "$INSTALL_DIR/"
chown -R root:wheel "$INSTALL_DIR/$KEXT_BUNDLE"
chmod -R 755 "$INSTALL_DIR/$KEXT_BUNDLE"

# Update kext cache
echo -e "${BLUE}Updating kext cache...${NC}"
kextcache -i /

# Load the kext
echo -e "${BLUE}Loading kernel extension...${NC}"
if kextload "$INSTALL_DIR/$KEXT_BUNDLE"; then
    echo -e "${GREEN}✓ Kext loaded successfully${NC}"
else
    echo -e "${RED}✗ Failed to load kext${NC}"
    echo -e "${YELLOW}Check the logs with: log show --predicate 'process == \"kernel\"' --last 1m${NC}"
    exit 1
fi

# Verify kext is loaded
echo -e "${BLUE}Verifying kext is loaded...${NC}"
if kextstat | grep -q "$KEXT_NAME"; then
    echo -e "${GREEN}✓ Kext is loaded and running${NC}"
else
    echo -e "${RED}✗ Kext is not loaded${NC}"
    exit 1
fi

# Show kext info
echo -e "${BLUE}Kext information:${NC}"
kextstat | grep "$KEXT_NAME"

# Create uninstall script
echo -e "${BLUE}Creating uninstall script...${NC}"
cat > uninstall_kext.sh << 'EOF'
#!/bin/bash
# Uninstall script for Maschine Mikro Driver Kext

set -e

KEXT_NAME="com.nativeinstruments.MaschineMikroDriver"
KEXT_BUNDLE="MaschineMikroDriver.kext"
INSTALL_DIR="/Library/Extensions"

echo "Uninstalling Maschine Mikro Driver Kext..."

# Unload kext if loaded
if kextstat | grep -q "$KEXT_NAME"; then
    echo "Unloading kext..."
    kextunload -b "$KEXT_NAME" || true
fi

# Remove kext files
if [[ -d "$INSTALL_DIR/$KEXT_BUNDLE" ]]; then
    echo "Removing kext files..."
    rm -rf "$INSTALL_DIR/$KEXT_BUNDLE"
fi

# Update kext cache
echo "Updating kext cache..."
kextcache -i /

echo "Uninstall complete!"
EOF

chmod +x uninstall_kext.sh

# Create monitoring script
echo -e "${BLUE}Creating monitoring script...${NC}"
cat > monitor_kext.sh << 'EOF'
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
EOF

chmod +x monitor_kext.sh

echo
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo
echo -e "${BLUE}What was installed:${NC}"
echo "• Kernel extension: $INSTALL_DIR/$KEXT_BUNDLE"
echo "• Uninstall script: ./uninstall_kext.sh"
echo "• Monitor script: ./monitor_kext.sh"
echo
echo -e "${BLUE}Next steps:${NC}"
echo "1. Connect your Maschine Mikro device"
echo "2. Run: ./monitor_kext.sh"
echo "3. Test the device in your DAW"
echo
echo -e "${BLUE}To uninstall:${NC}"
echo "sudo ./uninstall_kext.sh"
echo
echo -e "${BLUE}To monitor logs:${NC}"
echo "./monitor_kext.sh"
echo
echo -e "${GREEN}Installation successful!${NC}" 