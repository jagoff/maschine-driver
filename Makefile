# Makefile for Maschine Mikro Driver
# Provides easy build, install, and development commands

# Project configuration
PROJECT_NAME = MaschineMikroDriver
PROJECT_FILE = MaschineMikroDriver.xcodeproj
TARGET_NAME = MaschineMikroDriver
CONFIGURATION = Release
BUILD_DIR = build
INSTALL_DIR = /Library/Extensions
DRIVER_NAME = $(PROJECT_NAME).kext
BUNDLE_ID = com.nativeinstruments.maschine-mikro-driver

# Xcode build settings
XCODEBUILD = xcodebuild
XCODEBUILD_FLAGS = -project $(PROJECT_FILE) -target $(TARGET_NAME) -configuration $(CONFIGURATION)

# Default target
.PHONY: all
all: build

# Build the driver
.PHONY: build
build:
	@echo "Building $(PROJECT_NAME)..."
	$(XCODEBUILD) $(XCODEBUILD_FLAGS) build
	@echo "Build completed successfully"

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	$(XCODEBUILD) $(XCODEBUILD_FLAGS) clean
	rm -rf $(BUILD_DIR)
	@echo "Clean completed"

# Install the driver
.PHONY: install
install: build
	@echo "Installing $(PROJECT_NAME)..."
	@if [ ! -d "$(BUILD_DIR)/$(CONFIGURATION)/$(DRIVER_NAME)" ]; then \
		echo "Error: Driver not found. Run 'make build' first."; \
		exit 1; \
	fi
	sudo rm -rf $(INSTALL_DIR)/$(DRIVER_NAME)
	sudo cp -R $(BUILD_DIR)/$(CONFIGURATION)/$(DRIVER_NAME) $(INSTALL_DIR)/
	sudo chown -R root:wheel $(INSTALL_DIR)/$(DRIVER_NAME)
	sudo chmod -R 755 $(INSTALL_DIR)/$(DRIVER_NAME)
	@echo "Installation completed"

# Load the driver
.PHONY: load
load:
	@echo "Loading $(PROJECT_NAME)..."
	@if [ ! -d "$(INSTALL_DIR)/$(DRIVER_NAME)" ]; then \
		echo "Error: Driver not installed. Run 'make install' first."; \
		exit 1; \
	fi
	sudo kextunload -b $(BUNDLE_ID) 2>/dev/null || true
	sudo kextload $(INSTALL_DIR)/$(DRIVER_NAME)
	@echo "Driver loaded successfully"

# Unload the driver
.PHONY: unload
unload:
	@echo "Unloading $(PROJECT_NAME)..."
	sudo kextunload -b $(BUNDLE_ID) 2>/dev/null || true
	@echo "Driver unloaded"

# Uninstall the driver
.PHONY: uninstall
uninstall: unload
	@echo "Uninstalling $(PROJECT_NAME)..."
	sudo rm -rf $(INSTALL_DIR)/$(DRIVER_NAME)
	@echo "Driver uninstalled"

# Check driver status
.PHONY: status
status:
	@echo "Checking $(PROJECT_NAME) status..."
	@if kextstat | grep -q "$(PROJECT_NAME)"; then \
		echo "✓ Driver is loaded"; \
	else \
		echo "✗ Driver is not loaded"; \
	fi
	@if [ -d "$(INSTALL_DIR)/$(DRIVER_NAME)" ]; then \
		echo "✓ Driver is installed"; \
	else \
		echo "✗ Driver is not installed"; \
	fi

# Show system information
.PHONY: info
info:
	@echo "System Information:"
	@echo "  macOS Version: $(shell sw_vers -productVersion)"
	@echo "  Architecture: $(shell uname -m)"
	@echo "  Kernel Version: $(shell uname -r)"
	@echo "  Xcode Version: $(shell xcodebuild -version 2>/dev/null | head -1 || echo 'Not installed')"
	@echo "  SIP Status: $(shell csrutil status 2>/dev/null | grep -o 'enabled\|disabled' || echo 'unknown')"

# Check for device
.PHONY: device
device:
	@echo "Checking for Maschine Mikro device..."
	@if system_profiler SPUSBDataType | grep -q "Maschine Mikro"; then \
		echo "✓ Maschine Mikro device detected"; \
	else \
		echo "✗ Maschine Mikro device not detected"; \
	fi

# Show kernel logs
.PHONY: logs
logs:
	@echo "Recent kernel logs for $(PROJECT_NAME):"
	@log show --predicate 'process == "kernel"' --last 5m 2>/dev/null | grep "$(PROJECT_NAME)" || echo "No driver logs found"

# Development helpers
.PHONY: dev
dev: clean build install load status

# Quick rebuild and reload
.PHONY: reload
reload: unload build install load status

# Test the driver
.PHONY: test
test:
	@echo "Running driver tests..."
	@./test_driver.sh

# Open in Xcode
.PHONY: xcode
xcode:
	@echo "Opening project in Xcode..."
	open $(PROJECT_FILE)

# Show help
.PHONY: help
help:
	@echo "Maschine Mikro Driver Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  build      - Build the driver"
	@echo "  clean      - Clean build artifacts"
	@echo "  install    - Install the driver to system"
	@echo "  load       - Load the driver into kernel"
	@echo "  unload     - Unload the driver from kernel"
	@echo "  uninstall  - Uninstall the driver from system"
	@echo "  status     - Check driver status"
	@echo "  info       - Show system information"
	@echo "  device     - Check for Maschine Mikro device"
	@echo "  logs       - Show recent kernel logs"
	@echo "  dev        - Development workflow (clean, build, install, load, status)"
	@echo "  reload     - Quick rebuild and reload"
	@echo "  test       - Run driver tests"
	@echo "  xcode      - Open project in Xcode"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make dev        # Full development workflow"
	@echo "  make reload     # Quick rebuild and reload"
	@echo "  make test       # Run tests"
	@echo "  sudo make install # Install driver"

# Default target
.DEFAULT_GOAL := help 