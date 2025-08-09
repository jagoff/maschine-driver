#!/bin/bash

# ACTIVACIÓN DIRIGIDA para Maschine MK1
# Solo se enfoca en dispositivos que realmente podrían ser la Maschine

echo "🎹 ========================================="
echo "🎹 ACTIVACIÓN DIRIGIDA MASCHINE MK1"
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
show_progress "Iniciando activación DIRIGIDA para Maschine MK1..."

# PASO 1: Verificar estado actual
echo ""
show_progress "Paso 1: Verificando estado actual..."

# Verificar si el driver nativo está instalado
if [ -f "/usr/local/bin/maschine_driver" ]; then
    show_success "Driver nativo encontrado en /usr/local/bin/maschine_driver"
else
    show_warning "Driver nativo no encontrado, instalando..."
    ./install_and_debug.sh
fi

# PASO 2: Crear programa de activación dirigida
echo ""
show_progress "Paso 2: Creando programa de activación dirigida..."

cat > /tmp/targeted_activation.cpp << 'EOF'
#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <string>
#include <vector>
#include <algorithm>

struct MaschineDevice {
    MIDIEndpointRef endpoint;
    std::string name;
    bool isSource;
    int index;
    bool isMaschine;
    int confidence;
};

// Función para verificar si un dispositivo podría ser Maschine
bool isLikelyMaschine(const std::string& name) {
    std::string lowerName = name;
    std::transform(lowerName.begin(), lowerName.end(), lowerName.begin(), ::tolower);
    
    // Palabras clave específicas de Maschine
    std::vector<std::string> maschineKeywords = {
        "maschine", "mikro", "mk1", "mk2", "mk3", "native", "instruments"
    };
    
    // Dispositivos que NO son Maschine
    std::vector<std::string> excludeKeywords = {
        "axe-fx", "axe fx", "fractal", "bus", "i/o", "midi", "audio", "interface"
    };
    
    // Verificar exclusiones primero
    for (const auto& exclude : excludeKeywords) {
        if (lowerName.find(exclude) != std::string::npos) {
            return false;
        }
    }
    
    // Verificar palabras clave de Maschine
    for (const auto& keyword : maschineKeywords) {
        if (lowerName.find(keyword) != std::string::npos) {
            return true;
        }
    }
    
    // Si no tiene palabras clave específicas, verificar si parece ser un controlador
    if (lowerName.find("controller") != std::string::npos || 
        lowerName.find("pad") != std::string::npos ||
        lowerName.find("drum") != std::string::npos) {
        return true;
    }
    
    return false;
}

// Función para calcular confianza de que es Maschine
int calculateConfidence(const std::string& name) {
    std::string lowerName = name;
    std::transform(lowerName.begin(), lowerName.end(), lowerName.begin(), ::tolower);
    
    int confidence = 0;
    
    // Palabras clave de alta confianza
    if (lowerName.find("maschine") != std::string::npos) confidence += 50;
    if (lowerName.find("mikro") != std::string::npos) confidence += 30;
    if (lowerName.find("mk1") != std::string::npos) confidence += 20;
    if (lowerName.find("native") != std::string::npos) confidence += 15;
    if (lowerName.find("instruments") != std::string::npos) confidence += 10;
    
    // Palabras clave de media confianza
    if (lowerName.find("controller") != std::string::npos) confidence += 5;
    if (lowerName.find("pad") != std::string::npos) confidence += 3;
    if (lowerName.find("drum") != std::string::npos) confidence += 3;
    
    return confidence;
}

std::vector<MaschineDevice> findMaschineDevices() {
    std::vector<MaschineDevice> devices;
    
    // Buscar en fuentes (inputs)
    ItemCount numSources = MIDIGetNumberOfSources();
    std::cout << "🔍 Analizando " << numSources << " fuentes MIDI..." << std::endl;
    
    for (ItemCount i = 0; i < numSources; i++) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            
            std::string deviceName(nameStr);
            bool isMaschine = isLikelyMaschine(deviceName);
            int confidence = calculateConfidence(deviceName);
            
            if (isMaschine) {
                std::cout << "🎯 Fuente " << i << ": " << deviceName << " (confianza: " << confidence << "%)" << std::endl;
                
                MaschineDevice device;
                device.endpoint = source;
                device.name = deviceName;
                device.isSource = true;
                device.index = i;
                device.isMaschine = true;
                device.confidence = confidence;
                devices.push_back(device);
            } else {
                std::cout << "   Fuente " << i << ": " << deviceName << " (ignorado)" << std::endl;
            }
        }
    }
    
    // Buscar en destinos (outputs)
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    std::cout << "🔍 Analizando " << numDestinations << " destinos MIDI..." << std::endl;
    
    for (ItemCount i = 0; i < numDestinations; i++) {
        MIDIEndpointRef dest = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            
            std::string deviceName(nameStr);
            bool isMaschine = isLikelyMaschine(deviceName);
            int confidence = calculateConfidence(deviceName);
            
            if (isMaschine) {
                std::cout << "🎯 Destino " << i << ": " << deviceName << " (confianza: " << confidence << "%)" << std::endl;
                
                MaschineDevice device;
                device.endpoint = dest;
                device.name = deviceName;
                device.isSource = false;
                device.index = i;
                device.isMaschine = true;
                device.confidence = confidence;
                devices.push_back(device);
            } else {
                std::cout << "   Destino " << i << ": " << deviceName << " (ignorado)" << std::endl;
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

void activateMaschineDevice(MIDIPortRef port, const MaschineDevice& device) {
    std::cout << "\n🎯 Activando Maschine: " << device.name << " (confianza: " << device.confidence << "%)" << std::endl;
    
    // SECUENCIA 1: Reset completo
    std::cout << "📤 Secuencia 1: Reset completo" << std::endl;
    
    // All Controllers Off
    sendMIDI(port, device.endpoint, 0xB0, 121, 0);
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    
    // All Notes Off
    sendMIDI(port, device.endpoint, 0xB0, 123, 0);
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    
    // SysEx Reset
    unsigned char resetSysEx[] = {0xF0, 0x7E, 0x00, 0x09, 0x01, 0xF7};
    sendSysEx(port, device.endpoint, resetSysEx, sizeof(resetSysEx));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // SECUENCIA 2: Handshake específico de Maschine
    std::cout << "📤 Secuencia 2: Handshake Maschine" << std::endl;
    
    // Handshake estándar de Maschine
    unsigned char handshake1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7E, 0x00, 0x00, 0xF7};
    sendSysEx(port, device.endpoint, handshake1, sizeof(handshake1));
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    
    // Handshake alternativo
    unsigned char handshake2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7F, 0x00, 0x00, 0xF7};
    sendSysEx(port, device.endpoint, handshake2, sizeof(handshake2));
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    
    // Identity Request
    unsigned char identity[] = {0xF0, 0x7E, 0x00, 0x06, 0x01, 0xF7};
    sendSysEx(port, device.endpoint, identity, sizeof(identity));
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    
    // SECUENCIA 3: Activación de inputs
    std::cout << "📤 Secuencia 3: Activación de inputs" << std::endl;
    
    // Comando de activación 1
    unsigned char activate1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x01, 0xF7};
    sendSysEx(port, device.endpoint, activate1, sizeof(activate1));
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    
    // Comando de activación 2
    unsigned char activate2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x00, 0xF7};
    sendSysEx(port, device.endpoint, activate2, sizeof(activate2));
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    
    // Comando de activación 3
    unsigned char activate3[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x7F, 0xF7};
    sendSysEx(port, device.endpoint, activate3, sizeof(activate3));
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    
    // SECUENCIA 4: Modo Maschine
    std::cout << "📤 Secuencia 4: Modo Maschine" << std::endl;
    
    // Modo Maschine 1
    unsigned char maschineMode1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x00, 0xF7};
    sendSysEx(port, device.endpoint, maschineMode1, sizeof(maschineMode1));
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    
    // Modo Maschine 2
    unsigned char maschineMode2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x01, 0xF7};
    sendSysEx(port, device.endpoint, maschineMode2, sizeof(maschineMode2));
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    
    // Modo Maschine 3
    unsigned char maschineMode3[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x7F, 0xF7};
    sendSysEx(port, device.endpoint, maschineMode3, sizeof(maschineMode3));
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    
    // SECUENCIA 5: Test de LEDs
    std::cout << "📤 Secuencia 5: Test de LEDs" << std::endl;
    
    // Encender LED 0
    unsigned char ledOn[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x01, 0x7F, 0xF7};
    sendSysEx(port, device.endpoint, ledOn, sizeof(ledOn));
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // Apagar LED 0
    unsigned char ledOff[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF7};
    sendSysEx(port, device.endpoint, ledOff, sizeof(ledOff));
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    
    // SECUENCIA 6: Comandos finales
    std::cout << "📤 Secuencia 6: Comandos finales" << std::endl;
    
    // Comando final - LED de confirmación
    unsigned char confirmLED[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x01, 0x7F, 0xF7};
    sendSysEx(port, device.endpoint, confirmLED, sizeof(confirmLED));
    
    std::cout << "✅ Maschine " << device.name << " activada" << std::endl;
}

int main() {
    std::cout << "🎹 Activación DIRIGIDA de Maschine MK1..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Targeted Activation"), NULL, NULL, &client);
    
    // Crear puerto de salida
    MIDIPortRef outputPort;
    MIDIOutputPortCreate(client, CFSTR("Maschine Output"), &outputPort);
    
    // Buscar solo dispositivos Maschine
    std::vector<MaschineDevice> devices = findMaschineDevices();
    
    if (devices.empty()) {
        std::cout << "❌ No se encontró ningún dispositivo que parezca ser Maschine MK1" << std::endl;
        std::cout << "💡 Verifica que la Maschine esté conectada y sea reconocida por macOS" << std::endl;
        return 1;
    }
    
    std::cout << "🚀 Iniciando activación DIRIGIDA en " << devices.size() << " dispositivos Maschine..." << std::endl;
    
    // Activar cada dispositivo Maschine encontrado
    for (const auto& device : devices) {
        activateMaschineDevice(outputPort, device);
    }
    
    std::cout << "\n✅ Activación DIRIGIDA completada en todos los dispositivos Maschine" << std::endl;
    std::cout << "💡 Verifica si la Maschine MK1 está funcionando ahora" << std::endl;
    
    // Limpiar
    MIDIPortDispose(outputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar
echo ""
show_progress "Compilando programa de activación dirigida..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/targeted_activation /tmp/targeted_activation.cpp

if [ $? -eq 0 ]; then
    show_success "Programa de activación dirigida compilado exitosamente"
    echo ""
    show_progress "Ejecutando activación dirigida..."
    /tmp/targeted_activation
else
    show_error "Error al compilar programa de activación dirigida"
    exit 1
fi

# PASO 3: Iniciar driver nativo
echo ""
show_progress "Paso 3: Iniciando driver nativo..."

# Verificar si el driver está ejecutándose
DRIVER_PID=$(pgrep -f "maschine_driver")
if [ -n "$DRIVER_PID" ]; then
    show_success "Driver ya ejecutándose (PID: $DRIVER_PID)"
else
    show_progress "Iniciando driver nativo..."
    ./maschine_driver_control.sh start
    sleep 3
    DRIVER_PID=$(pgrep -f "maschine_driver")
    if [ -n "$DRIVER_PID" ]; then
        show_success "Driver iniciado exitosamente (PID: $DRIVER_PID)"
    else
        show_warning "No se pudo iniciar el driver automáticamente"
    fi
fi

# PASO 4: Test de inputs dirigido
echo ""
show_progress "Paso 4: Realizando test de inputs dirigido..."

cat > /tmp/targeted_input_test.cpp << 'EOF'
#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <string>
#include <vector>
#include <algorithm>

struct InputEvent {
    std::string type;
    int index;
    int value;
    std::string timestamp;
    std::string deviceName;
};

std::vector<InputEvent> inputEvents;

// Función para verificar si un dispositivo podría ser Maschine
bool isLikelyMaschine(const std::string& name) {
    std::string lowerName = name;
    std::transform(lowerName.begin(), lowerName.end(), lowerName.begin(), ::tolower);
    
    // Palabras clave específicas de Maschine
    std::vector<std::string> maschineKeywords = {
        "maschine", "mikro", "mk1", "mk2", "mk3", "native", "instruments"
    };
    
    // Dispositivos que NO son Maschine
    std::vector<std::string> excludeKeywords = {
        "axe-fx", "axe fx", "fractal", "bus", "i/o", "midi", "audio", "interface"
    };
    
    // Verificar exclusiones primero
    for (const auto& exclude : excludeKeywords) {
        if (lowerName.find(exclude) != std::string::npos) {
            return false;
        }
    }
    
    // Verificar palabras clave de Maschine
    for (const auto& keyword : maschineKeywords) {
        if (lowerName.find(keyword) != std::string::npos) {
            return true;
        }
    }
    
    return false;
}

void handleMIDIInput(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon) {
    const MIDIPacket* packet = &pktlist->packet[0];
    
    // Obtener nombre del dispositivo fuente
    std::string deviceName = "Unknown";
    if (srcConnRefCon) {
        MIDIEndpointRef source = (MIDIEndpointRef)srcConnRefCon;
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            deviceName = std::string(nameStr);
        }
    }
    
    // Solo procesar si parece ser Maschine
    if (!isLikelyMaschine(deviceName)) {
        return; // Ignorar dispositivos que no son Maschine
    }
    
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
            
            std::cout << "📥 [" << timestamp << "] " << deviceName << " - MIDI: " << std::hex << (int)status << " " << (int)data1 << " " << (int)data2 << std::dec << std::endl;
            
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
                    event.deviceName = deviceName;
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
                    event.deviceName = deviceName;
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
                    event.deviceName = deviceName;
                    inputEvents.push_back(event);
                }
            }
        }
        
        packet = MIDIPacketNext(packet);
    }
}

int main() {
    std::cout << "🎹 Test DIRIGIDO de inputs físicos de Maschine MK1..." << std::endl;
    std::cout << "💡 Presiona pads, botones y encoders en la Maschine MK1" << std::endl;
    std::cout << "⏱️  Test durará 45 segundos..." << std::endl;
    std::cout << "🎯 Solo monitoreando dispositivos que parecen ser Maschine..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Targeted Input Test"), NULL, NULL, &client);
    
    // Crear puerto de entrada
    MIDIPortRef inputPort;
    MIDIInputPortCreate(client, CFSTR("Maschine Input"), handleMIDIInput, NULL, &inputPort);
    
    // Conectar solo a fuentes que parecen ser Maschine
    ItemCount numSources = MIDIGetNumberOfSources();
    std::cout << "🔍 Analizando " << numSources << " fuentes MIDI..." << std::endl;
    
    int connectedCount = 0;
    for (ItemCount i = 0; i < numSources; i++) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            
            std::string deviceName(nameStr);
            
            if (isLikelyMaschine(deviceName)) {
                std::cout << "📥 Conectando a Maschine: " << deviceName << std::endl;
                MIDIPortConnectSource(inputPort, source, (void*)source);
                connectedCount++;
            } else {
                std::cout << "   Ignorando: " << deviceName << std::endl;
            }
        }
    }
    
    if (connectedCount == 0) {
        std::cout << "❌ No se encontró ningún dispositivo que parezca ser Maschine MK1" << std::endl;
        std::cout << "💡 Verifica que la Maschine esté conectada y sea reconocida por macOS" << std::endl;
        return 1;
    }
    
    std::cout << "✅ Conectado a " << connectedCount << " dispositivos Maschine" << std::endl;
    
    // Esperar 45 segundos para inputs
    std::cout << "⏳ Esperando inputs físicos de Maschine (45 segundos)..." << std::endl;
    std::this_thread::sleep_for(std::chrono::seconds(45));
    
    // Mostrar resumen
    std::cout << "\n📊 RESUMEN DIRIGIDO DE INPUTS DETECTADOS:" << std::endl;
    std::cout << "=========================================" << std::endl;
    
    if (inputEvents.empty()) {
        std::cout << "❌ No se detectaron inputs físicos de Maschine" << std::endl;
        std::cout << "💡 Esto puede indicar que:" << std::endl;
        std::cout << "   1. La Maschine no está conectada correctamente" << std::endl;
        std::cout << "   2. Los inputs físicos están deshabilitados" << std::endl;
        std::cout << "   3. Se requiere el driver legacy para macOS 10.15+" << std::endl;
        std::cout << "   4. Se requiere reiniciar la máquina" << std::endl;
    } else {
        std::cout << "✅ Se detectaron " << inputEvents.size() << " inputs físicos de Maschine:" << std::endl;
        
        for (const auto& event : inputEvents) {
            std::cout << "   [" << event.timestamp << "] " << event.deviceName << " - " 
                      << event.type << " " << event.index << " (value: " << event.value << ")" << std::endl;
        }
        
        std::cout << "\n🎉 ¡LA MASCHINE MK1 ESTÁ FUNCIONANDO!" << std::endl;
    }
    
    std::cout << "\n✅ Test DIRIGIDO de inputs completado" << std::endl;
    
    // Limpiar
    MIDIPortDispose(inputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar test de inputs dirigido
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/targeted_input_test /tmp/targeted_input_test.cpp

if [ $? -eq 0 ]; then
    echo ""
    show_progress "Ejecutando test DIRIGIDO de inputs físicos..."
    /tmp/targeted_input_test
else
    show_error "Error al compilar test DIRIGIDO de inputs"
fi

# PASO 5: Resumen final
echo ""
echo "🎹 ========================================="
echo "🎹 RESUMEN ACTIVACIÓN DIRIGIDA"
echo "🎹 ========================================="

echo ""
echo "📋 Pasos completados:"
echo "   ✅ 1. Verificación del estado actual"
echo "   ✅ 2. Activación dirigida (solo Maschine)"
echo "   ✅ 3. Inicio del driver nativo"
echo "   ✅ 4. Test dirigido de inputs físicos"
echo ""

echo "🎯 Estado del dispositivo:"
echo "   💡 Si detectaste inputs = ¡MASCHINE FUNCIONANDO!"
echo "   💡 Si no detectaste inputs = Verificar conexión/driver legacy"
echo "   💡 Si las luces cambiaron = Activación parcial exitosa"
echo ""

echo "🔧 Próximos pasos:"
echo "   1. Si funcionó: Usar el driver para funcionalidades avanzadas"
echo "   2. Si no funcionó: Verificar que la Maschine esté conectada"
echo "   3. Si funcionó parcialmente: Considerar driver legacy"
echo ""

show_success "¡ACTIVACIÓN DIRIGIDA completada!"
echo "🎹 Solo se activaron dispositivos que parecen ser Maschine MK1" 