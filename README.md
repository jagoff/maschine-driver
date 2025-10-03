# Maschine Mikro MK1 Driver for macOS

A native macOS driver for Native Instruments Maschine Mikro MK1, providing full MIDI functionality and device control through CoreMIDI.

## ✅ Status

**Project is fully functional!** The driver successfully:
- ✅ Connects to Maschine Mikro MK1 via CoreMIDI
- ✅ Implements Native Instruments proprietary protocol
- ✅ Detects and processes 177+ physical inputs (pads, buttons, encoders)
- ✅ Provides bidirectional MIDI communication
- ✅ Supports native Maschine mode and MIDI compatibility mode

## Features

- **Native macOS driver** using CoreMIDI framework
- **Proprietary protocol implementation** for Maschine MK1
- **Full input detection**: 16 velocity-sensitive pads, buttons, and encoders
- **Bidirectional MIDI communication**
- **Group, sound, pattern, and scene control**
- **Transport and tempo control**
- **LED control support**
- **Comprehensive CLI interface**

## Prerequisites

- macOS 10.15 or later
- Xcode Command Line Tools
- Native Instruments Maschine Mikro MK1 device

## Quick Start

### 1. Build the Driver

```bash
# Clone the repository
git clone https://github.com/yourusername/maschine-driver.git
cd maschine-driver

# Build the driver
make
```

### 2. Install the Driver

```bash
# Install to /usr/local/bin (requires sudo)
sudo ./install.sh
```

### 3. Run the Driver

```bash
# Start the driver in Maschine native mode
maschine_driver

# Or run directly from build directory
./maschine_driver
```

### 4. Test with Your DAW

1. Connect your Maschine Mikro MK1 device
2. The driver will automatically detect it
3. Open your DAW (Logic, Ableton, etc.)
4. Configure "Maschine Mikro" in MIDI preferences
5. Test pads, buttons, and encoders

## Project Structure

```
maschine-driver/
├── MaschineMikroDriver_User.cpp    # Core driver implementation
├── MaschineMikroDriver_User.h      # Driver header file
├── maschine_native_driver.cpp      # CLI interface
├── MaschineMikroDriver.cpp         # Legacy kext source (reference)
├── MaschineMikroDriver.h           # Legacy kext header (reference)
├── Info.plist                      # Bundle configuration
├── Makefile                        # Build system
├── install.sh                      # Installation script
├── install_kext.sh                 # Legacy kext installer
├── monitor_kext.sh                 # Monitoring utility
├── status.sh                       # Status checker
├── ESTADO_FINAL_ACTUALIZADO.md     # Project status (Spanish)
└── README.md                       # This file
```

## Components

### Core Driver

- **MaschineMikroDriver_User.cpp**: Main driver implementation using CoreMIDI
- **MaschineMikroDriver_User.h**: Driver interface and protocol definitions
- **maschine_native_driver.cpp**: Command-line interface and interactive menu

### Legacy Components (Reference)

- **MaschineMikroDriver.cpp**: Original kernel extension implementation
- **MaschineMikroDriver.h**: Kernel extension headers
- **Info.plist**: Kext bundle configuration

### Build & Installation

- **Makefile**: Unified build system
- **install.sh**: Driver installation script
- **install_kext.sh**: Legacy kext installation (deprecated)

## Installation Details

### Build Process

The Makefile compiles the driver:

1. **Compilation**: Builds `MaschineMikroDriver_User.cpp` and `maschine_native_driver.cpp`
2. **Linking**: Links with CoreMIDI and CoreFoundation frameworks
3. **Output**: Creates `maschine_driver` executable

### Installation Process

The `install.sh` script:

1. **Builds** the driver using `make`
2. **Copies** the binary to `/usr/local/bin/maschine_driver`
3. **Sets** executable permissions
4. **Verifies** installation

## Usage

### Interactive Mode

```bash
# Start the driver with interactive menu
maschine_driver
```

The interactive menu provides:
- Initialize Maschine mode
- Connect with Maschine software
- Show Maschine state
- Test pads, buttons, encoders
- Control groups, sounds, patterns, scenes
- Transport and tempo control
- LED control
- MIDI compatibility mode

### Command Line Options

```bash
# List MIDI sources
maschine_driver --list-sources

# List MIDI destinations
maschine_driver --list-destinations

# Test connection
maschine_driver --test-connection

# Debug mode
maschine_driver --debug

# Maschine mode
maschine_driver --maschine-mode

# Show help
maschine_driver --help
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

#### Device Not Detected

```bash
# Check USB device
system_profiler SPUSBDataType | grep -i maschine

# Check MIDI devices
maschine_driver --list-sources
maschine_driver --list-destinations

# Or use system profiler
system_profiler SPMIDIDataType | grep -i maschine
```

#### MIDI Not Working

```bash
# Test connection
maschine_driver --test-connection

# Run in debug mode
maschine_driver --debug

# Check device status
./status.sh
```

#### Driver Not Found

```bash
# Verify installation
which maschine_driver

# Reinstall
sudo ./install.sh

# Or build and run locally
make
./maschine_driver
```

### Uninstallation

```bash
# Remove installed driver
sudo rm /usr/local/bin/maschine_driver

# Clean build artifacts
make clean
```

## Development

### Building from Source

```bash
# Build the driver
make

# Clean build artifacts
make clean

# Build and install
make
sudo ./install.sh
```

### Code Structure

The driver implements:

- **CoreMIDI integration** for device communication
- **Proprietary protocol** for Maschine MK1
- **State management** for groups, sounds, patterns, scenes
- **MIDI message handling** and routing
- **SysEx message** processing
- **Input event processing** for pads, buttons, encoders
- **LED control** via MIDI messages

### Key Components

**MaschineMikroDriver_User.cpp**:
- CoreMIDI client and port management
- Device connection and initialization
- Protocol implementation
- State tracking
- MIDI message processing

**maschine_native_driver.cpp**:
- CLI interface
- Interactive menu system
- User commands
- Testing utilities

## Technical Details

### Device Specifications

- **Vendor ID**: 0x17cc (Native Instruments)
- **Product ID**: 0x0815 (Maschine Mikro)
- **Interface**: USB HID + MIDI
- **Pads**: 16 velocity-sensitive pads
- **Buttons**: 8 function buttons
- **Encoders**: 2 rotary encoders

### Protocol Implementation

- **Proprietary SysEx messages**: Native Instruments Maschine protocol
- **State synchronization**: Groups, sounds, patterns, scenes
- **Transport control**: Play, stop, record
- **Tempo control**: BPM and swing
- **LED control**: Pad and button LEDs
- **Input detection**: 177+ physical inputs detected

### Driver Details

- **Framework**: CoreMIDI, CoreFoundation
- **Language**: C++
- **Architecture**: Universal (Intel + Apple Silicon)
- **Mode**: User-space driver (no kernel extension required)

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
2. Run `maschine_driver --debug` for detailed logs
3. Check MIDI device detection with `--list-sources`
4. Create an issue with detailed information

## Changelog

### Version 1.0.0
- Native macOS driver using CoreMIDI
- Proprietary Maschine MK1 protocol implementation
- 177+ physical inputs detected and working
- Full MIDI bidirectional communication
- Interactive CLI interface
- Group, sound, pattern, scene control
- Transport and tempo control
- LED control support 