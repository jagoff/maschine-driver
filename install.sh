#!/bin/bash

# Maschine Mikro Driver Installation Script
# For macOS compatibility with Native Instruments Maschine Mikro

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check macOS version
check_macos_version() {
    local version=$(sw_vers -productVersion)
    local major=$(echo $version | cut -d. -f1)
    local minor=$(echo $version | cut -d. -f2)
    
    print_status "Detected macOS version: $version"
    
    if [[ $major -lt 10 ]] || ([[ $major -eq 10 ]] && [[ $minor -lt 15 ]]); then
        print_error "This driver requires macOS 10.15 (Catalina) or later"
        exit 1
    fi
    
    if [[ $major -ge 11 ]]; then
        print_warning "macOS 11+ (Big Sur) requires additional security settings"
        print_warning "You may need to disable System Integrity Protection (SIP) or sign the driver"
    fi
}

# Check if Xcode command line tools are installed
check_xcode_tools() {
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode command line tools are not installed"
        print_status "Please install them by running: xcode-select --install"
        exit 1
    fi
    print_success "Xcode command line tools found"
}

# Build the driver
build_driver() {
    print_status "Building Maschine Mikro driver..."
    
    if [ ! -d "MaschineMikroDriver.xcodeproj" ]; then
        print_error "Xcode project not found. Please run this script from the driver directory"
        exit 1
    fi
    
    # Build the driver
    xcodebuild -project MaschineMikroDriver.xcodeproj -target MaschineMikroDriver -configuration Release build
    
    if [ $? -ne 0 ]; then
        print_error "Failed to build driver"
        exit 1
    fi
    
    print_success "Driver built successfully"
}

# Install the driver
install_driver() {
    print_status "Installing Maschine Mikro driver..."
    
    local driver_path="build/Release/MaschineMikroDriver.kext"
    local install_path="/Library/Extensions/MaschineMikroDriver.kext"
    
    if [ ! -d "$driver_path" ]; then
        print_error "Built driver not found at $driver_path"
        exit 1
    fi
    
    # Remove existing installation
    if [ -d "$install_path" ]; then
        print_status "Removing existing driver installation..."
        rm -rf "$install_path"
    fi
    
    # Copy driver to system location
    cp -R "$driver_path" "$install_path"
    
    # Set proper permissions
    chown -R root:wheel "$install_path"
    chmod -R 755 "$install_path"
    
    print_success "Driver installed to $install_path"
}

# Load the driver
load_driver() {
    print_status "Loading Maschine Mikro driver..."
    
    # Unload existing driver if present
    if kextstat | grep -q "MaschineMikroDriver"; then
        print_status "Unloading existing driver..."
        kextunload -b com.nativeinstruments.maschine-mikro-driver 2>/dev/null || true
    fi
    
    # Load the driver
    kextload "/Library/Extensions/MaschineMikroDriver.kext"
    
    if [ $? -eq 0 ]; then
        print_success "Driver loaded successfully"
    else
        print_error "Failed to load driver"
        print_warning "You may need to disable System Integrity Protection (SIP)"
        print_warning "Or sign the driver with a valid developer certificate"
        exit 1
    fi
}

# Check if device is connected
check_device() {
    print_status "Checking for Maschine Mikro device..."
    
    if system_profiler SPUSBDataType | grep -q "Maschine Mikro"; then
        print_success "Maschine Mikro device detected"
    else
        print_warning "Maschine Mikro device not detected"
        print_status "Please connect your Maschine Mikro and try again"
    fi
}

# Create uninstall script
create_uninstall_script() {
    local uninstall_script="/usr/local/bin/uninstall-maschine-mikro-driver.sh"
    
    cat > "$uninstall_script" << 'EOF'
#!/bin/bash

# Uninstall script for Maschine Mikro Driver

set -e

echo "Uninstalling Maschine Mikro Driver..."

# Unload driver if loaded
if kextstat | grep -q "MaschineMikroDriver"; then
    echo "Unloading driver..."
    kextunload -b com.nativeinstruments.maschine-mikro-driver 2>/dev/null || true
fi

# Remove driver files
if [ -d "/Library/Extensions/MaschineMikroDriver.kext" ]; then
    echo "Removing driver files..."
    rm -rf "/Library/Extensions/MaschineMikroDriver.kext"
fi

# Remove this uninstall script
rm -f "$0"

echo "Maschine Mikro Driver uninstalled successfully"
EOF
    
    chmod +x "$uninstall_script"
    print_success "Uninstall script created at $uninstall_script"
}

# Main installation process
main() {
    echo "=========================================="
    echo "Maschine Mikro Driver Installation Script"
    echo "=========================================="
    echo ""
    
    check_root
    check_macos_version
    check_xcode_tools
    build_driver
    install_driver
    load_driver
    check_device
    create_uninstall_script
    
    echo ""
    echo "=========================================="
    print_success "Installation completed successfully!"
    echo "=========================================="
    echo ""
    echo "Your Maschine Mikro should now be recognized as a MIDI device."
    echo "You can verify this in Audio MIDI Setup or your DAW."
    echo ""
    echo "To uninstall the driver, run:"
    echo "sudo /usr/local/bin/uninstall-maschine-mikro-driver.sh"
    echo ""
    echo "Note: You may need to restart your computer for all changes to take effect."
}

# Run main function
main "$@" 