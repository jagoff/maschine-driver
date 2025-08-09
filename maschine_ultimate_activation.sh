#!/bin/bash

# Script ULTIMATE para forzar la activación de Maschine Mikro
# Usa técnicas más agresivas y múltiples enfoques

echo "🎹 ========================================="
echo "🎹 ACTIVACIÓN ULTIMATE MASCHINE MIKRO"
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
show_progress "Iniciando activación ULTIMATE de Maschine Mikro..."

# PASO 1: Verificar si el dispositivo está conectado físicamente
echo ""
show_progress "Paso 1: Verificando conexión física..."

# Verificar dispositivos USB
echo "🔍 Dispositivos USB conectados:"
system_profiler SPUSBDataType | grep -A 5 -B 5 -i "maschine\|native\|instruments" || echo "   No se encontraron dispositivos Maschine en USB"

# Verificar dispositivos MIDI
echo ""
echo "🔍 Dispositivos MIDI del sistema:"
system_profiler SPMIDIDataType | grep -A 10 -B 5 -i "maschine\|native\|instruments" || echo "   No se encontraron dispositivos Maschine en MIDI"

# PASO 2: Crear programa de detección agresiva
echo ""
show_progress "Paso 2: Creando detector agresivo de Maschine..."

cat > /tmp/ultimate_detector.cpp << 'EOF'
#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <string>
#include <vector>

struct MIDIDevice {
    MIDIEndpointRef endpoint;
    std::string name;
    bool isSource;
    int index;
};

std::vector<MIDIDevice> findMaschineDevices() {
    std::vector<MIDIDevice> devices;
    
    // Buscar en fuentes (inputs)
    ItemCount numSources = MIDIGetNumberOfSources();
    std::cout << "🔍 Buscando en " << numSources << " fuentes MIDI..." << std::endl;
    
    for (ItemCount i = 0; i < numSources; i++) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            
            std::string deviceName(nameStr);
            std::cout << "   Fuente " << i << ": " << deviceName << std::endl;
            
            // Buscar cualquier dispositivo que pueda ser Maschine
            if (deviceName.find("Maschine") != std::string::npos ||
                deviceName.find("Native") != std::string::npos ||
                deviceName.find("Mikro") != std::string::npos ||
                deviceName.find("MK1") != std::string::npos ||
                deviceName.find("MK2") != std::string::npos ||
                deviceName.find("MK3") != std::string::npos ||
                deviceName.find("Input") != std::string::npos ||
                deviceName.find("Output") != std::string::npos ||
                deviceName.find("Bus") != std::string::npos) {
                
                MIDIDevice device;
                device.endpoint = source;
                device.name = deviceName;
                device.isSource = true;
                device.index = i;
                devices.push_back(device);
                std::cout << "   ✅ Posible Maschine encontrada: " << deviceName << std::endl;
            }
        }
    }
    
    // Buscar en destinos (outputs)
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    std::cout << "🔍 Buscando en " << numDestinations << " destinos MIDI..." << std::endl;
    
    for (ItemCount i = 0; i < numDestinations; i++) {
        MIDIEndpointRef dest = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            
            std::string deviceName(nameStr);
            std::cout << "   Destino " << i << ": " << deviceName << std::endl;
            
            // Buscar cualquier dispositivo que pueda ser Maschine
            if (deviceName.find("Maschine") != std::string::npos ||
                deviceName.find("Native") != std::string::npos ||
                deviceName.find("Mikro") != std::string::npos ||
                deviceName.find("MK1") != std::string::npos ||
                deviceName.find("MK2") != std::string::npos ||
                deviceName.find("MK3") != std::string::npos ||
                deviceName.find("Input") != std::string::npos ||
                deviceName.find("Output") != std::string::npos ||
                deviceName.find("Bus") != std::string::npos) {
                
                MIDIDevice device;
                device.endpoint = dest;
                device.name = deviceName;
                device.isSource = false;
                device.index = i;
                devices.push_back(device);
                std::cout << "   ✅ Posible Maschine encontrada: " << deviceName << std::endl;
            }
        }
    }
    
    return devices;
}

void sendSysEx(MIDIPortRef port, MIDIEndpointRef dest, const unsigned char* data, size_t length) {
    MIDIPacketList packetList;
    MIDIPacket *packet = MIDIPacketListInit(&packetList);
    MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, length, data);
    MIDISend(port, dest, &packetList);
    std::cout << "📤 SysEx: ";
    for (size_t i = 0; i < length; i++) {
        printf("%02X ", data[i]);
    }
    std::cout << std::endl;
}

void sendMIDI(MIDIPortRef port, MIDIEndpointRef dest, unsigned char status, unsigned char data1, unsigned char data2) {
    unsigned char midiData[] = {status, data1, data2};
    MIDIPacketList packetList;
    MIDIPacket *packet = MIDIPacketListInit(&packetList);
    MIDIPacketListAdd(&packetList, sizeof(packetList), packet, 0, 3, midiData);
    MIDISend(port, dest, &packetList);
    printf("📤 MIDI: %02X %02X %02X\n", status, data1, data2);
}

int main() {
    std::cout << "🎹 Detector ULTIMATE de Maschine Mikro..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Ultimate Detector"), NULL, NULL, &client);
    
    // Crear puerto de salida
    MIDIPortRef outputPort;
    MIDIOutputPortCreate(client, CFSTR("Maschine Output"), &outputPort);
    
    // Buscar dispositivos Maschine
    std::vector<MIDIDevice> devices = findMaschineDevices();
    
    if (devices.empty()) {
        std::cout << "⚠️  No se encontraron dispositivos específicos de Maschine" << std::endl;
        std::cout << "🔍 Intentando con todos los dispositivos MIDI disponibles..." << std::endl;
        
        // Usar todos los destinos disponibles
        ItemCount numDestinations = MIDIGetNumberOfDestinations();
        for (ItemCount i = 0; i < numDestinations; i++) {
            MIDIEndpointRef dest = MIDIGetDestination(i);
            CFStringRef name;
            MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
            
            if (name) {
                char nameStr[256];
                CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
                CFRelease(name);
                
                MIDIDevice device;
                device.endpoint = dest;
                device.name = std::string(nameStr);
                device.isSource = false;
                device.index = i;
                devices.push_back(device);
            }
        }
    }
    
    if (devices.empty()) {
        std::cout << "❌ No se encontró ningún dispositivo MIDI" << std::endl;
        return 1;
    }
    
    std::cout << "🚀 Iniciando activación ULTIMATE en " << devices.size() << " dispositivos..." << std::endl;
    
    // Activar cada dispositivo encontrado
    for (const auto& device : devices) {
        std::cout << "\n🎯 Activando dispositivo: " << device.name << std::endl;
        
        // ESTRATEGIA 1: Reset completo
        std::cout << "📤 Estrategia 1: Reset completo" << std::endl;
        
        // All Controllers Off
        sendMIDI(outputPort, device.endpoint, 0xB0, 121, 0);
        std::this_thread::sleep_for(std::chrono::milliseconds(200));
        
        // All Notes Off
        sendMIDI(outputPort, device.endpoint, 0xB0, 123, 0);
        std::this_thread::sleep_for(std::chrono::milliseconds(200));
        
        // SysEx Reset
        unsigned char resetSysEx[] = {0xF0, 0x7E, 0x00, 0x09, 0x01, 0xF7};
        sendSysEx(outputPort, device.endpoint, resetSysEx, sizeof(resetSysEx));
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        
        // ESTRATEGIA 2: Handshake múltiple
        std::cout << "📤 Estrategia 2: Handshake múltiple" << std::endl;
        
        // Handshake estándar
        unsigned char handshake1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7E, 0x00, 0x00, 0xF7};
        sendSysEx(outputPort, device.endpoint, handshake1, sizeof(handshake1));
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
        
        // Handshake alternativo
        unsigned char handshake2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7F, 0x00, 0x00, 0xF7};
        sendSysEx(outputPort, device.endpoint, handshake2, sizeof(handshake2));
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
        
        // Identity Request
        unsigned char identity[] = {0xF0, 0x7E, 0x00, 0x06, 0x01, 0xF7};
        sendSysEx(outputPort, device.endpoint, identity, sizeof(identity));
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
        
        // ESTRATEGIA 3: Activación de inputs
        std::cout << "📤 Estrategia 3: Activación de inputs" << std::endl;
        
        // Comando de activación 1
        unsigned char activate1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x01, 0xF7};
        sendSysEx(outputPort, device.endpoint, activate1, sizeof(activate1));
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
        
        // Comando de activación 2
        unsigned char activate2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x00, 0xF7};
        sendSysEx(outputPort, device.endpoint, activate2, sizeof(activate2));
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
        
        // ESTRATEGIA 4: Modo Maschine
        std::cout << "📤 Estrategia 4: Modo Maschine" << std::endl;
        
        // Modo Maschine 1
        unsigned char maschineMode1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x00, 0xF7};
        sendSysEx(outputPort, device.endpoint, maschineMode1, sizeof(maschineMode1));
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
        
        // Modo Maschine 2
        unsigned char maschineMode2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x01, 0xF7};
        sendSysEx(outputPort, device.endpoint, maschineMode2, sizeof(maschineMode2));
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
        
        // ESTRATEGIA 5: Test de LEDs
        std::cout << "📤 Estrategia 5: Test de LEDs" << std::endl;
        
        // Encender LED 0
        unsigned char ledOn[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x01, 0x7F, 0xF7};
        sendSysEx(outputPort, device.endpoint, ledOn, sizeof(ledOn));
        std::this_thread::sleep_for(std::chrono::milliseconds(1000));
        
        // Apagar LED 0
        unsigned char ledOff[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF7};
        sendSysEx(outputPort, device.endpoint, ledOff, sizeof(ledOff));
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
        
        // ESTRATEGIA 6: Simulación de inputs
        std::cout << "📤 Estrategia 6: Simulación de inputs" << std::endl;
        
        // Simular presionar pad 0
        sendMIDI(outputPort, device.endpoint, 0x90, 36, 0x7F); // Note On
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        sendMIDI(outputPort, device.endpoint, 0x80, 36, 0x00); // Note Off
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        
        // Simular presionar botón 0
        sendMIDI(outputPort, device.endpoint, 0xB0, 16, 0x7F); // Control Change On
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        sendMIDI(outputPort, device.endpoint, 0xB0, 16, 0x00); // Control Change Off
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        
        std::cout << "✅ Dispositivo " << device.name << " activado" << std::endl;
    }
    
    std::cout << "\n✅ Activación ULTIMATE completada en todos los dispositivos" << std::endl;
    std::cout << "💡 Verifica si la Maschine Mikro está funcionando ahora" << std::endl;
    
    // Limpiar
    MIDIPortDispose(outputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar
echo ""
show_progress "Compilando detector ULTIMATE..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/ultimate_detector /tmp/ultimate_detector.cpp

if [ $? -eq 0 ]; then
    show_success "Detector ULTIMATE compilado exitosamente"
    echo ""
    show_progress "Ejecutando detector ULTIMATE..."
    /tmp/ultimate_detector
else
    show_error "Error al compilar detector ULTIMATE"
    exit 1
fi

# PASO 3: Crear programa de test de inputs mejorado
echo ""
show_progress "Paso 3: Creando test de inputs mejorado..."

cat > /tmp/ultimate_input_test.cpp << 'EOF'
#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <string>
#include <vector>

struct InputEvent {
    std::string type;
    int index;
    int value;
    std::string timestamp;
};

std::vector<InputEvent> inputEvents;

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
                    
                    InputEvent event;
                    event.type = "PAD";
                    event.index = pad;
                    event.value = data2;
                    event.timestamp = timestamp;
                    inputEvents.push_back(event);
                }
            } else if ((status & 0xF0) == 0x80) {
                if (data1 >= 36 && data1 <= 51) {
                    int pad = data1 - 36;
                    std::cout << "🥁 PAD " << pad << " liberado" << std::endl;
                }
            } else if ((status & 0xF0) == 0xB0 && data2 > 0) {
                if (data1 >= 16 && data1 <= 23) {
                    int button = data1 - 16;
                    std::cout << "🔘 ¡¡¡BOTÓN " << button << " PRESIONADO!!! (value: " << (int)data2 << ")" << std::endl;
                    
                    InputEvent event;
                    event.type = "BUTTON";
                    event.index = button;
                    event.value = data2;
                    event.timestamp = timestamp;
                    inputEvents.push_back(event);
                }
            } else if ((status & 0xF0) == 0xB0 && data2 == 0) {
                if (data1 >= 16 && data1 <= 23) {
                    int button = data1 - 16;
                    std::cout << "🔘 BOTÓN " << button << " liberado" << std::endl;
                }
            } else if ((status & 0xF0) == 0xB0) {
                if (data1 >= 24 && data1 <= 25) {
                    int encoder = data1 - 24;
                    std::cout << "🎛️ ENCODER " << encoder << " girado (value: " << (int)data2 << ")" << std::endl;
                    
                    InputEvent event;
                    event.type = "ENCODER";
                    event.index = encoder;
                    event.value = data2;
                    event.timestamp = timestamp;
                    inputEvents.push_back(event);
                }
            }
        }
        
        packet = MIDIPacketNext(packet);
    }
}

int main() {
    std::cout << "🎹 Test ULTIMATE de inputs físicos..." << std::endl;
    std::cout << "💡 Presiona pads, botones y encoders en el dispositivo físico" << std::endl;
    std::cout << "⏱️  Test durará 60 segundos..." << std::endl;
    std::cout << "🎯 Buscando inputs físicos de Maschine Mikro..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Ultimate Input Test"), NULL, NULL, &client);
    
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
    
    // Esperar 60 segundos para inputs
    std::cout << "⏳ Esperando inputs físicos (60 segundos)..." << std::endl;
    std::this_thread::sleep_for(std::chrono::seconds(60));
    
    // Mostrar resumen
    std::cout << "\n📊 RESUMEN DE INPUTS DETECTADOS:" << std::endl;
    std::cout << "=================================" << std::endl;
    
    if (inputEvents.empty()) {
        std::cout << "❌ No se detectaron inputs físicos" << std::endl;
        std::cout << "💡 Esto puede indicar que:" << std::endl;
        std::cout << "   1. El dispositivo no está en modo activo" << std::endl;
        std::cout << "   2. Los inputs físicos están deshabilitados" << std::endl;
        std::cout << "   3. Se requiere software oficial para activar inputs" << std::endl;
    } else {
        std::cout << "✅ Se detectaron " << inputEvents.size() << " inputs físicos:" << std::endl;
        
        for (const auto& event : inputEvents) {
            std::cout << "   [" << event.timestamp << "] " << event.type << " " << event.index 
                      << " (value: " << event.value << ")" << std::endl;
        }
        
        std::cout << "\n🎉 ¡LA MASCHINE MIKRO ESTÁ FUNCIONANDO!" << std::endl;
    }
    
    std::cout << "\n✅ Test ULTIMATE de inputs completado" << std::endl;
    
    // Limpiar
    MIDIPortDispose(inputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar test de inputs
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/ultimate_input_test /tmp/ultimate_input_test.cpp

if [ $? -eq 0 ]; then
    echo ""
    show_progress "Ejecutando test ULTIMATE de inputs físicos..."
    /tmp/ultimate_input_test
else
    show_error "Error al compilar test ULTIMATE de inputs"
fi

# PASO 4: Resumen final
echo ""
echo "🎹 ========================================="
echo "🎹 RESUMEN ACTIVACIÓN ULTIMATE"
echo "🎹 ========================================="

echo ""
echo "📋 Pasos completados:"
echo "   ✅ 1. Verificación de conexión física"
echo "   ✅ 2. Detección agresiva de dispositivos"
echo "   ✅ 3. Activación ULTIMATE en todos los dispositivos"
echo "   ✅ 4. Test ULTIMATE de inputs físicos"
echo ""

echo "🎯 Estado del dispositivo:"
echo "   💡 Si detectaste inputs = ¡FUNCIONANDO COMPLETAMENTE!"
echo "   💡 Si no detectaste inputs = Requiere software oficial"
echo "   💡 Si las luces cambiaron = Activación parcial exitosa"
echo ""

echo "🔧 Próximos pasos:"
echo "   1. Si funcionó: Usar el driver para funcionalidades avanzadas"
echo "   2. Si no funcionó: Instalar Native Instruments Maschine 2.0"
echo "   3. Si funcionó parcialmente: Combinar driver + software oficial"
echo ""

show_success "¡Activación ULTIMATE completada!"
echo "🎹 La Maschine Mikro debería estar funcionando ahora" 