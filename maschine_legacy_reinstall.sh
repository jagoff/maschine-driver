#!/bin/bash

echo "🎵 MASCHINE MK1 LEGACY DRIVER REINSTALLATION"
echo "============================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   echo "   Run: sudo ./maschine_legacy_reinstall.sh"
   exit 1
fi

echo "🔍 Step 1: Checking current system state..."
echo "-------------------------------------------"

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
echo "macOS Version: $MACOS_VERSION"

# Check if SIP is disabled (required for legacy drivers)
SIP_STATUS=$(csrutil status)
echo "SIP Status: $SIP_STATUS"

if [[ $SIP_STATUS == *"enabled"* ]]; then
    echo "⚠️  WARNING: SIP is enabled. Legacy drivers may not work properly."
    echo "   Consider booting into Recovery Mode and running: csrutil disable"
    echo ""
fi

echo ""
echo "🧹 Step 2: Cleaning up any existing installations..."
echo "---------------------------------------------------"

# Remove any existing Native Instruments kexts
echo "Removing existing Native Instruments kexts..."
find /System/Library/Extensions /Library/Extensions -name "*native*" -o -name "*maschine*" 2>/dev/null | while read kext; do
    echo "  Removing: $kext"
    rm -rf "$kext"
done

# Clear kext cache
echo "Clearing kext cache..."
kmutil clear-staging
kextcache -i /

echo ""
echo "📥 Step 3: Downloading legacy driver..."
echo "---------------------------------------"

# Create temporary directory
TEMP_DIR="/tmp/maschine_legacy_install"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo "⚠️  IMPORTANT: You need to manually download the legacy driver."
echo ""
echo "📋 Please download the following file:"
echo "   Maschine Mikro Driver 2.8.0 for Mac OS X 10.9 - 10.11"
echo "   From: https://www.native-instruments.com/en/support/downloads/"
echo ""
echo "📁 Save it to: $TEMP_DIR"
echo ""
echo "⏳ Waiting for driver file to be placed in $TEMP_DIR..."
echo "   (Press Enter when you've downloaded the file)"

read -p "Press Enter to continue..."

# Look for the downloaded file
DRIVER_FILE=$(find "$TEMP_DIR" -name "*.pkg" -o -name "*.dmg" | head -1)

if [[ -z "$DRIVER_FILE" ]]; then
    echo "❌ No driver file found in $TEMP_DIR"
    echo "   Please download the legacy driver and place it in the temp directory"
    exit 1
fi

echo "✅ Found driver file: $DRIVER_FILE"

echo ""
echo "🔧 Step 4: Installing legacy driver..."
echo "--------------------------------------"

# Extract and install based on file type
if [[ "$DRIVER_FILE" == *.dmg ]]; then
    echo "Mounting DMG file..."
    hdiutil attach "$DRIVER_FILE"
    
    # Find the mounted volume
    MOUNTED_VOLUME=$(hdiutil info | grep "/Volumes/" | tail -1 | awk '{print $3}')
    echo "Mounted volume: $MOUNTED_VOLUME"
    
    # Look for pkg file in mounted volume
    PKG_FILE=$(find "$MOUNTED_VOLUME" -name "*.pkg" | head -1)
    
    if [[ -n "$PKG_FILE" ]]; then
        echo "Installing package: $PKG_FILE"
        installer -pkg "$PKG_FILE" -target /
    else
        echo "❌ No package file found in mounted volume"
        hdiutil detach "$MOUNTED_VOLUME"
        exit 1
    fi
    
    # Unmount
    hdiutil detach "$MOUNTED_VOLUME"
    
elif [[ "$DRIVER_FILE" == *.pkg ]]; then
    echo "Installing package directly..."
    installer -pkg "$DRIVER_FILE" -target /
else
    echo "❌ Unsupported file format: $DRIVER_FILE"
    exit 1
fi

echo ""
echo "🔄 Step 5: Loading the driver..."
echo "--------------------------------"

# Look for installed kext
KEXT_PATH=$(find /System/Library/Extensions /Library/Extensions -name "*native*" -o -name "*maschine*" 2>/dev/null | head -1)

if [[ -n "$KEXT_PATH" ]]; then
    echo "Found kext: $KEXT_PATH"
    
    # Load the kext
    echo "Loading kext..."
    kmutil load -p "$KEXT_PATH"
    
    # Check if loaded
    if kmutil showloaded | grep -i native > /dev/null; then
        echo "✅ Native Instruments kext loaded successfully"
    else
        echo "⚠️  Kext may not be loaded yet - reboot required"
    fi
else
    echo "⚠️  No Native Instruments kext found - installation may have failed"
fi

echo ""
echo "🧹 Step 6: Cleaning up..."
echo "-------------------------"

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo ""
echo "🎯 Step 7: Final instructions..."
echo "-------------------------------"

echo "✅ Installation complete!"
echo ""
echo "📋 NEXT STEPS:"
echo "1. 🔄 REBOOT your Mac completely"
echo "2. 🔓 Go to System Preferences > Security & Privacy"
echo "3. ✅ Click 'Allow' for Native Instruments when prompted"
echo "4. 🎵 Test your Maschine MK1"
echo ""
echo "⚠️  IMPORTANT: If you still see 'turn on Maschine' message:"
echo "   - Make sure SIP is disabled (csrutil disable in Recovery Mode)"
echo "   - Try the driver version 2.8.0 specifically"
echo "   - Some users report success with version 2.7.0 as well"
echo ""

echo "🎵 Maschine MK1 Legacy Driver Installation Complete!" 