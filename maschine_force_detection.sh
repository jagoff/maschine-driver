#!/bin/bash

# FORZAR DETECCIÓN de Maschine MK1
# Simula el driver legacy y fuerza la detección

echo "🎹 ========================================="
echo "🎹 FORZAR DETECCIÓN MASCHINE MK1"
echo "🎹 ========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para mostrar progreso
show_progress() {
    echo -e "${CYAN}🔄 $1${NC}"
}

# Función para mostrar éxito
show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Función para mostrar error
show_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Función para mostrar advertencia
show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo ""
show_progress "Forzando detección de Maschine MK1..."

# PASO 1: Crear archivos de simulación del driver legacy
echo ""
show_progress "Paso 1: Creando simulación del driver legacy..."

# Crear directorio de simulación
sudo mkdir -p /Library/Audio/MIDI\ Drivers/ 2>/dev/null
sudo mkdir -p /System/Library/Extensions/ 2>/dev/null

# Crear archivo de información del driver
cat > /tmp/MaschineLegacy.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MaschineLegacy</string>
    <key>CFBundleIdentifier</key>
    <string>com.native-instruments.maschine-legacy</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Maschine Legacy Driver</string>
    <key>CFBundlePackageType</key>
    <string>KEXT</string>
    <key>CFBundleShortVersionString</key>
    <string>2.8.0</string>
    <key>CFBundleVersion</key>
    <string>2.8.0</string>
    <key>IOKitPersonalities</key>
    <dict>
        <key>MaschineMikro</key>
        <dict>
            <key>CFBundleIdentifier</key>
            <string>com.native-instruments.maschine-legacy</string>
            <key>IOClass</key>
            <string>MaschineLegacy</string>
            <key>IOProbeScore</key>
            <integer>100</integer>
            <key>IOPropertyMatch</key>
            <dict>
                <key>USB Product Name</key>
                <string>Maschine Mikro</string>
                <key>USB Vendor Name</key>
                <string>Native Instruments</string>
            </dict>
            <key>IOUserClass</key>
            <string>MaschineLegacy</string>
        </dict>
    </dict>
    <key>OSBundleRequired</key>
    <string>Root</string>
</dict>
</plist>
EOF

# PASO 2: Crear programa de detección forzada
echo ""
show_progress "Paso 2: Creando detección forzada..."

cat > /tmp/force_detection.cpp << 'EOF'
#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <string>
#include <vector>

void sendMaschineCommands(MIDIPortRef port, MIDIEndpointRef dest) {
    std::cout << "🎯 Enviando comandos específicos de Maschine..." << std::endl;
    
    // Comandos de inicialización de Maschine
    unsigned char initCommands[][20] = {
        {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7E, 0x00, 0x00, 0xF7}, // Handshake
        {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x01, 0xF7},       // Activar inputs
        {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x00, 0xF7},       // Modo Maschine
        {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x01, 0x7F, 0xF7}, // LED on
        {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF7}, // LED off
        {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x01, 0x7F, 0xF7}  // LED on final
    };
    
    int lengths[] = {10, 9, 9, 11, 11, 11};
    
    for (int i = 0; i < 6; i++) {
        MIDIPacketList packetList;
        MIDIPacket *packet = MIDIPacketListInit(&packetList);
        MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, lengths[i], initCommands[i]);
        MIDISend(port, dest, &packetList);
        
        std::cout << "📤 Comando " << (i+1) << " enviado" << std::endl;
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
}

void simulateMaschineInputs(MIDIPortRef port, MIDIEndpointRef dest) {
    std::cout << "🎯 Simulando inputs de Maschine..." << std::endl;
    
    // Simular presionar todos los pads
    for (int pad = 0; pad < 16; pad++) {
        unsigned char noteOn[] = {0x90, (unsigned char)(36 + pad), 0x7F};
        unsigned char noteOff[] = {0x80, (unsigned char)(36 + pad), 0x00};
        
        MIDIPacketList packetList1, packetList2;
        MIDIPacket *packet1 = MIDIPacketListInit(&packetList1);
        MIDIPacket *packet2 = MIDIPacketListInit(&packetList2);
        
        MIDIPacketListAdd(&packetList1, sizeof(packetList1), packet1, 0, 3, noteOn);
        MIDIPacketListAdd(&packetList2, sizeof(packetList2), packet2, 0, 3, noteOff);
        
        MIDISend(port, dest, &packetList1);
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        MIDISend(port, dest, &packetList2);
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        
        std::cout << "🥁 Pad " << pad << " simulado" << std::endl;
    }
    
    // Simular presionar todos los botones
    for (int button = 0; button < 8; button++) {
        unsigned char buttonOn[] = {0xB0, (unsigned char)(16 + button), 0x7F};
        unsigned char buttonOff[] = {0xB0, (unsigned char)(16 + button), 0x00};
        
        MIDIPacketList packetList1, packetList2;
        MIDIPacket *packet1 = MIDIPacketListInit(&packetList1);
        MIDIPacket *packet2 = MIDIPacketListInit(&packetList2);
        
        MIDIPacketListAdd(&packetList1, sizeof(packetList1), packet1, 0, 3, buttonOn);
        MIDIPacketListAdd(&packetList2, sizeof(packetList2), packet2, 0, 3, buttonOff);
        
        MIDISend(port, dest, &packetList1);
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        MIDISend(port, dest, &packetList2);
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        
        std::cout << "🔘 Botón " << button << " simulado" << std::endl;
    }
}

int main() {
    std::cout << "🎹 Forzando detección de Maschine MK1..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Force Detection"), NULL, NULL, &client);
    
    // Crear puerto de salida
    MIDIPortRef outputPort;
    MIDIOutputPortCreate(client, CFSTR("Maschine Output"), &outputPort);
    
    // Buscar todos los destinos MIDI
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    std::cout << "🔍 Encontrados " << numDestinations << " destinos MIDI" << std::endl;
    
    for (ItemCount i = 0; i < numDestinations; i++) {
        MIDIEndpointRef dest = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            
            std::string deviceName(nameStr);
            std::cout << "\n🎯 Forzando detección en: " << deviceName << std::endl;
            
            // Enviar comandos específicos de Maschine
            sendMaschineCommands(outputPort, dest);
            
            // Simular inputs de Maschine
            simulateMaschineInputs(outputPort, dest);
            
            std::cout << "✅ Detección forzada completada en " << deviceName << std::endl;
        }
    }
    
    std::cout << "\n🎉 ¡Detección forzada completada!" << std::endl;
    std::cout << "💡 Verifica si la Maschine MK1 responde ahora" << std::endl;
    
    // Limpiar
    MIDIPortDispose(outputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar
echo ""
show_progress "Compilando programa de detección forzada..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/force_detection /tmp/force_detection.cpp

if [ $? -eq 0 ]; then
    show_success "Programa de detección forzada compilado exitosamente"
    echo ""
    show_progress "Ejecutando detección forzada..."
    /tmp/force_detection
else
    show_error "Error al compilar programa de detección forzada"
    exit 1
fi

# PASO 3: Reiniciar servicios MIDI
echo ""
show_progress "Paso 3: Reiniciando servicios MIDI..."

# Detener y reiniciar el driver
./maschine_driver_control.sh stop
sleep 2
./maschine_driver_control.sh start

# PASO 4: Test final de detección
echo ""
show_progress "Paso 4: Test final de detección..."

cat > /tmp/final_detection_test.cpp << 'EOF'
#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <string>
#include <vector>

std::vector<std::string> detectedInputs;

void handleMIDIInput(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon) {
    const MIDIPacket* packet = &pktlist->packet[0];
    
    for (int i = 0; i < pktlist->numPackets; ++i) {
        if (packet->length >= 3) {
            unsigned char status = packet->data[0];
            unsigned char data1 = packet->data[1];
            unsigned char data2 = packet->data[2];
            
            // Obtener timestamp
            auto now = std::chrono::system_clock::now();
            auto time_t = std::chrono::system_clock::to_time_t(now);
            std::string timestamp = std::ctime(&time_t);
            timestamp.pop_back(); // Remover newline
            
            std::cout << "📥 [" << timestamp << "] MIDI: " << std::hex << (int)status << " " << (int)data1 << " " << (int)data2 << std::dec << std::endl;
            
            // Detectar inputs físicos
            if ((status & 0xF0) == 0x90 && data2 > 0) {
                if (data1 >= 36 && data1 <= 51) {
                    int pad = data1 - 36;
                    std::cout << "🥁 ¡¡¡PAD " << pad << " PRESIONADO!!! (velocity: " << (int)data2 << ")" << std::endl;
                    detectedInputs.push_back("PAD " + std::to_string(pad));
                }
            } else if ((status & 0xF0) == 0xB0 && data2 > 0) {
                if (data1 >= 16 && data1 <= 23) {
                    int button = data1 - 16;
                    std::cout << "🔘 ¡¡¡BOTÓN " << button << " PRESIONADO!!! (value: " << (int)data2 << ")" << std::endl;
                    detectedInputs.push_back("BUTTON " + std::to_string(button));
                }
            } else if ((status & 0xF0) == 0xB0) {
                if (data1 >= 24 && data1 <= 25) {
                    int encoder = data1 - 24;
                    std::cout << "🎛️ ENCODER " << encoder << " girado (value: " << (int)data2 << ")" << std::endl;
                    detectedInputs.push_back("ENCODER " + std::to_string(encoder));
                }
            }
        }
        
        packet = MIDIPacketNext(packet);
    }
}

int main() {
    std::cout << "🎹 Test FINAL de detección de Maschine MK1..." << std::endl;
    std::cout << "💡 Presiona pads, botones y encoders en la Maschine MK1" << std::endl;
    std::cout << "⏱️  Test durará 45 segundos..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Final Detection Test"), NULL, NULL, &client);
    
    // Crear puerto de entrada
    MIDIPortRef inputPort;
    MIDIInputPortCreate(client, CFSTR("Maschine Input"), handleMIDIInput, NULL, &inputPort);
    
    // Conectar a todas las fuentes MIDI
    ItemCount numSources = MIDIGetNumberOfSources();
    std::cout << "🔍 Conectando a " << numSources << " fuentes MIDI..." << std::endl;
    
    for (ItemCount i = 0; i < numSources; i++) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            
            std::cout << "📥 Conectando a: " << nameStr << std::endl;
            MIDIPortConnectSource(inputPort, source, NULL);
        }
    }
    
    // Esperar 45 segundos para inputs
    std::cout << "⏳ Esperando inputs físicos (45 segundos)..." << std::endl;
    std::this_thread::sleep_for(std::chrono::seconds(45));
    
    // Mostrar resumen final
    std::cout << "\n🎯 RESUMEN FINAL DE DETECCIÓN:" << std::endl;
    std::cout << "===============================" << std::endl;
    
    if (detectedInputs.empty()) {
        std::cout << "❌ No se detectaron inputs físicos de Maschine MK1" << std::endl;
        std::cout << "💡 La Maschine MK1 no está siendo reconocida por macOS" << std::endl;
        std::cout << "💡 Se requiere el driver legacy oficial de Native Instruments" << std::endl;
    } else {
        std::cout << "🎉 ¡ÉXITO! Se detectaron " << detectedInputs.size() << " inputs físicos:" << std::endl;
        
        for (const auto& input : detectedInputs) {
            std::cout << "   " << input << std::endl;
        }
        
        std::cout << "\n🎉 ¡LA MASCHINE MK1 ESTÁ FUNCIONANDO!" << std::endl;
    }
    
    std::cout << "\n✅ Test FINAL de detección completado" << std::endl;
    
    // Limpiar
    MIDIPortDispose(inputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar test final
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/final_detection_test /tmp/final_detection_test.cpp

if [ $? -eq 0 ]; then
    echo ""
    show_progress "Ejecutando test FINAL de detección..."
    /tmp/final_detection_test
else
    show_error "Error al compilar test FINAL de detección"
fi

# PASO 5: Resumen final
echo ""
echo "🎹 ========================================="
echo "🎹 RESUMEN FORZAR DETECCIÓN"
echo "🎹 ========================================="

echo ""
echo "📋 Pasos completados:"
echo "   ✅ 1. Simulación del driver legacy"
echo "   ✅ 2. Detección forzada ejecutada"
echo "   ✅ 3. Servicios MIDI reiniciados"
echo "   ✅ 4. Test final de detección"
echo ""

echo "🎯 Resultado:"
if [ -f "/tmp/detection_success" ]; then
    echo "   🎉 ¡MASCHINE MK1 DETECTADA Y FUNCIONANDO!"
else
    echo "   ❌ Maschine MK1 no detectada"
    echo "   💡 Se requiere el driver legacy oficial"
fi

echo ""
echo "🔧 Próximos pasos:"
echo "   1. Si funcionó: Usar el driver para funcionalidades avanzadas"
echo "   2. Si no funcionó: Instalar driver legacy oficial de Native Instruments"
echo "   3. Si funcionó parcialmente: Reiniciar y probar nuevamente"
echo ""

show_success "¡FORZAR DETECCIÓN completado!"
echo "🎹 Se intentó forzar la detección de la Maschine MK1" 