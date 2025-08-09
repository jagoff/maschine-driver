#!/bin/bash

# Instalador completo para Maschine Mikro Driver
# Incluye modo MIDI y modo Maschine nativo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Instalador Completo Maschine Mikro Driver ===${NC}"
echo

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
echo -e "${BLUE}macOS Version: ${MACOS_VERSION}${NC}"

# Check if Xcode Command Line Tools are installed
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo -e "${RED}Error: Xcode Command Line Tools not found${NC}"
    echo "Please install them with: xcode-select --install"
    exit 1
fi

echo -e "${GREEN}✓ Xcode Command Line Tools found${NC}"

# Create bin directory
BIN_DIR="/usr/local/bin"
echo -e "${BLUE}Creating bin directory...${NC}"
sudo mkdir -p "$BIN_DIR"

# Build user-space driver (MIDI mode)
echo -e "${BLUE}Building user-space driver (MIDI mode)...${NC}"
if make -f Makefile.test; then
    echo -e "${GREEN}✓ User-space driver built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build user-space driver${NC}"
    exit 1
fi

# Build Maschine native driver
echo -e "${BLUE}Building Maschine native driver...${NC}"
if make -f Makefile.maschine; then
    echo -e "${GREEN}✓ Maschine native driver built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build Maschine native driver${NC}"
    exit 1
fi

# Build pad monitor
echo -e "${BLUE}Building pad monitor...${NC}"
if make -f Makefile.monitor; then
    echo -e "${GREEN}✓ Pad monitor built successfully${NC}"
else
    echo -e "${YELLOW}⚠ Pad monitor build failed (continuing anyway)${NC}"
fi

# Install the executables
echo -e "${BLUE}Installing executables...${NC}"
sudo cp test_driver_user "$BIN_DIR/maschine-mikro-driver"
sudo cp maschine_native_driver "$BIN_DIR/maschine-native-driver"
if [[ -f "pad_monitor" ]]; then
    sudo cp pad_monitor "$BIN_DIR/maschine-pad-monitor"
fi
sudo chmod +x "$BIN_DIR/maschine-mikro-driver"
sudo chmod +x "$BIN_DIR/maschine-native-driver"
if [[ -f "pad_monitor" ]]; then
    sudo chmod +x "$BIN_DIR/maschine-pad-monitor"
fi

# Create symlinks in current directory
ln -sf "$BIN_DIR/maschine-mikro-driver" ./maschine-driver
ln -sf "$BIN_DIR/maschine-native-driver" ./maschine-native
if [[ -f "pad_monitor" ]]; then
    ln -sf "$BIN_DIR/maschine-pad-monitor" ./maschine-monitor
fi

echo -e "${GREEN}✓ Executables installed to $BIN_DIR${NC}"

# Create desktop shortcuts
echo -e "${BLUE}Creating desktop shortcuts...${NC}"
cat > ~/Desktop/Maschine\ Mikro\ Driver\ \(MIDI\).command << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "Starting Maschine Mikro Driver (MIDI mode)..."
maschine-mikro-driver
EOF

cat > ~/Desktop/Maschine\ Mikro\ Driver\ \(Native\).command << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "Starting Maschine Mikro Driver (Native mode)..."
maschine-native-driver
EOF

if [[ -f "pad_monitor" ]]; then
cat > ~/Desktop/Maschine\ Pad\ Monitor.command << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "Starting Maschine Pad Monitor..."
maschine-pad-monitor
EOF
fi

chmod +x ~/Desktop/Maschine\ Mikro\ Driver\ \(MIDI\).command
chmod +x ~/Desktop/Maschine\ Mikro\ Driver\ \(Native\).command
if [[ -f "pad_monitor" ]]; then
    chmod +x ~/Desktop/Maschine\ Pad\ Monitor.command
fi

echo -e "${GREEN}✓ Desktop shortcuts created${NC}"

# Create quick start script
echo -e "${BLUE}Creating quick start script...${NC}"
cat > start_maschine_complete.sh << 'EOF'
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
EOF

chmod +x start_maschine_complete.sh

# Create uninstall script
echo -e "${BLUE}Creating uninstall script...${NC}"
cat > uninstall_maschine_complete.sh << 'EOF'
#!/bin/bash
# Uninstall script for Maschine Mikro Driver (Complete)

set -e

BIN_DIR="/usr/local/bin"

echo "Uninstalling Maschine Mikro Driver (Complete)..."

# Remove executables
if [[ -f "$BIN_DIR/maschine-mikro-driver" ]]; then
    echo "Removing maschine-mikro-driver..."
    sudo rm -f "$BIN_DIR/maschine-mikro-driver"
fi

if [[ -f "$BIN_DIR/maschine-native-driver" ]]; then
    echo "Removing maschine-native-driver..."
    sudo rm -f "$BIN_DIR/maschine-native-driver"
fi

if [[ -f "$BIN_DIR/maschine-pad-monitor" ]]; then
    echo "Removing maschine-pad-monitor..."
    sudo rm -f "$BIN_DIR/maschine-pad-monitor"
fi

# Remove desktop shortcuts
if [[ -f ~/Desktop/Maschine\ Mikro\ Driver\ \(MIDI\).command ]]; then
    echo "Removing desktop shortcuts..."
    rm -f ~/Desktop/Maschine\ Mikro\ Driver\ \(MIDI\).command
    rm -f ~/Desktop/Maschine\ Mikro\ Driver\ \(Native\).command
    rm -f ~/Desktop/Maschine\ Pad\ Monitor.command
fi

# Remove symlinks
rm -f ./maschine-driver
rm -f ./maschine-native
rm -f ./maschine-monitor

echo "Uninstall complete!"
EOF

chmod +x uninstall_maschine_complete.sh

echo
echo -e "${GREEN}=== Instalación Completa Exitosa! ===${NC}"
echo
echo -e "${BLUE}Componentes instalados:${NC}"
echo "• Driver MIDI: $BIN_DIR/maschine-mikro-driver"
echo "• Driver Nativo: $BIN_DIR/maschine-native-driver"
if [[ -f "pad_monitor" ]]; then
    echo "• Monitor de Pads: $BIN_DIR/maschine-pad-monitor"
fi
echo "• Accesos directos: ~/Desktop/"
echo "• Script de inicio: ./start_maschine_complete.sh"
echo "• Script de desinstalación: ./uninstall_maschine_complete.sh"
echo
echo -e "${BLUE}Modos disponibles:${NC}"
echo "🎵 Modo MIDI: Compatibilidad completa con DAWs"
echo "🎹 Modo Nativo: Funciones completas de Maschine (grupos, escenas, patrones, LEDs)"
echo
echo -e "${BLUE}Cómo usar:${NC}"
echo "1. Conecta tu Maschine Mikro"
echo "2. Ejecuta: ./start_maschine_complete.sh"
echo "3. O usa los accesos directos del escritorio"
echo "4. O ejecuta directamente:"
echo "   - maschine-mikro-driver (modo MIDI)"
echo "   - maschine-native-driver (modo nativo)"
echo
echo -e "${BLUE}Características del modo nativo:${NC}"
echo "• Gestión de grupos (16 grupos)"
echo "• Gestión de sonidos (16 por grupo)"
echo "• Gestión de patrones (16 por grupo)"
echo "• Gestión de escenas (16 escenas)"
echo "• Control de transport (play, record, etc.)"
echo "• Control de tempo y swing"
echo "• Control de LEDs (pads, botones, encoders)"
echo "• Modos especiales (solo, mute, automation)"
echo
echo -e "${BLUE}Para desinstalar:${NC}"
echo "./uninstall_maschine_complete.sh"
echo
echo -e "${GREEN}¡Instalación completada exitosamente!${NC}" 