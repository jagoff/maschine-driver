# Maschine Mikro Driver for macOS

A custom kernel extension (kext) driver for Native Instruments Maschine Mikro on macOS, providing full MIDI functionality and device control.

## Features

- **Kernel-level USB driver** for Maschine Mikro
- **MIDI input/output** support
- **Pad detection** with velocity sensitivity
- **Button and encoder** support
- **Real-time monitoring** tools
- **User-space testing** utilities

## Prerequisites

- macOS 10.15 or later
- Xcode Command Line Tools
- System Integrity Protection (SIP) disabled (for kext installation)
- Root access (for kext installation)

## Quick Start

### 1. Install the Kernel Extension

```bash
# Clone or download this repository
cd maschine-driver

# Run the automated installer (requires sudo)
sudo ./install_kext.sh
```

### 2. Test the Installation

```bash
# Run comprehensive tests
./test_kext.sh

# Monitor real-time activity
./monitor_kext.sh
```

### 3. Test with Your DAW

1. Connect your Maschine Mikro device
2. Open your DAW (Logic, Ableton, etc.)
3. Check MIDI preferences for "Maschine Mikro"
4. Test pads, buttons, and encoders

## Project Structure

```
maschine-driver/
├── MaschineMikroDriver.cpp      # Main kext source code
├── MaschineMikroDriver.h        # Header file
├── Info.plist                   # Kext bundle configuration
├── Makefile.kext               # Build system for kext
├── install_kext.sh             # Automated installer
├── uninstall_kext.sh           # Uninstaller
├── test_kext.sh                # Test suite
├── monitor_kext.sh             # Real-time monitoring
├── user_driver.cpp             # User-space test driver
├── pad_monitor.cpp             # Visual pad monitor
├── pad_monitor.sh              # Shell-based pad monitor
└── README.md                   # This file
```

## Components

### Kernel Extension (kext)

The main driver that runs in kernel space:

- **MaschineMikroDriver.cpp**: Core driver implementation
- **MaschineMikroDriver.h**: Driver interface definitions
- **Info.plist**: Bundle configuration and device matching
- **Makefile.kext**: Build system

### User-Space Tools

Testing and monitoring utilities:

- **user_driver.cpp**: User-space driver for testing
- **pad_monitor.cpp**: Visual pad activity monitor
- **pad_monitor.sh**: Shell-based pad monitor

### Management Scripts

- **install_kext.sh**: Complete installation automation
- **uninstall_kext.sh**: Clean removal
- **test_kext.sh**: Comprehensive testing
- **monitor_kext.sh**: Real-time monitoring

## Installation Details

### System Requirements

- **macOS**: 10.15 (Catalina) or later
- **Architecture**: Intel or Apple Silicon
- **SIP**: Must be disabled for kext installation
- **Permissions**: Root access required

### SIP Disabling

System Integrity Protection must be disabled to install kernel extensions:

1. Restart and hold `Cmd+R` to enter Recovery Mode
2. Open Terminal and run: `csrutil disable`
3. Restart normally

### Installation Process

The installer performs these steps:

1. **Compilation**: Builds the kext using `Makefile.kext`
2. **Installation**: Copies kext to `/Library/Extensions`
3. **Permissions**: Sets proper ownership and permissions
4. **Cache Update**: Updates kext cache
5. **Loading**: Loads the kext into kernel
6. **Verification**: Confirms successful loading

## Usage

### Basic Testing

```bash
# Test kext installation
./test_kext.sh

# Monitor device activity
./monitor_kext.sh

# Test user-space driver
make user_driver
./user_driver
```

### Pad Monitoring

```bash
# Visual pad monitor (C++)
make pad_monitor
./pad_monitor

# Shell-based pad monitor
./pad_monitor.sh
```

### DAW Integration

1. **Logic Pro X**: 
   - Go to Logic Pro > Preferences > MIDI
   - Enable "Maschine Mikro" in Input/Output

2. **Ableton Live**:
   - Go to Preferences > Link/MIDI
   - Enable "Maschine Mikro" in Input/Output

3. **Other DAWs**:
   - Check MIDI preferences for "Maschine Mikro"
   - Enable the device for input/output

## Troubleshooting

### Common Issues

#### Kext Won't Load

```bash
# Check SIP status
csrutil status

# Check kext logs
log show --predicate 'process == "kernel"' --last 5m

# Reinstall kext
sudo ./install_kext.sh
```

#### Device Not Detected

```bash
# Check USB device
system_profiler SPUSBDataType | grep -i maschine

# Check MIDI devices
system_profiler SPMIDIDataType | grep -i maschine

# Monitor real-time
./monitor_kext.sh
```

#### MIDI Not Working

```bash
# Test user-space driver
./user_driver

# Check MIDI destinations
./user_driver --list-midi

# Test pad monitoring
./pad_monitor
```

### Log Analysis

```bash
# Kernel logs
log show --predicate 'process == "kernel"' --last 10m | grep -i maschine

# System logs
log show --predicate 'process == "kernel"' --last 10m | grep -i usb

# Real-time monitoring
./monitor_kext.sh
```

### Uninstallation

```bash
# Remove kext completely
sudo ./uninstall_kext.sh

# Or manual removal
sudo kextunload -b com.nativeinstruments.MaschineMikroDriver
sudo rm -rf /Library/Extensions/MaschineMikroDriver.kext
sudo kextcache -i /
```

## Development

### Building from Source

```bash
# Build kext
make -f Makefile.kext

# Build user-space tools
make user_driver
make pad_monitor

# Clean build
make -f Makefile.kext clean
make clean
```

### Debugging

```bash
# Enable debug logging
sudo log config --mode "level:debug" --subsystem com.nativeinstruments.MaschineMikroDriver

# Monitor debug logs
log stream --predicate 'process == "kernel"' | grep -i maschine
```

### Code Structure

The kext implements:

- **USB device matching** via Info.plist
- **Device initialization** and configuration
- **MIDI message handling** and routing
- **Pad/button/encoder** event processing
- **Kernel-user space communication**

## Technical Details

### Device Specifications

- **Vendor ID**: 0x17cc (Native Instruments)
- **Product ID**: 0x0815 (Maschine Mikro)
- **Interface**: USB HID + MIDI
- **Pads**: 16 velocity-sensitive pads
- **Buttons**: 8 function buttons
- **Encoders**: 2 rotary encoders

### MIDI Implementation

- **Note messages**: Pad presses (notes 36-51)
- **CC messages**: Encoder changes
- **Program changes**: Button presses
- **Channel**: 1 (configurable)

### Kernel Extension Details

- **Bundle ID**: com.nativeinstruments.MaschineMikroDriver
- **Version**: 1.0.0
- **Architecture**: Universal (Intel + Apple Silicon)
- **Dependencies**: IOKit, CoreMIDI

## License

This project is provided as-is for educational and development purposes. Use at your own risk.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues and questions:

1. Check the troubleshooting section
2. Run the test scripts
3. Check system logs
4. Create an issue with detailed information

## Changelog

### Version 1.0.0
- Initial release
- Basic kext functionality
- MIDI support
- Pad/button/encoder handling
- User-space testing tools
- Automated installation 