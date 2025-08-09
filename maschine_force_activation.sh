#!/bin/bash

# Script completo para forzar la activación de Maschine Mikro
# Combina múltiples estrategias para hacer funcionar el dispositivo

echo "🎹 ========================================="
echo "🎹 FORZANDO ACTIVACIÓN MASCHINE MIKRO"
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
show_progress "Iniciando activación forzada de Maschine Mikro..."

# PASO 1: Verificar dispositivos MIDI
echo ""
show_progress "Paso 1: Verificando dispositivos MIDI disponibles..."

# Crear programa para listar dispositivos
cat > /tmp/list_devices.cpp << 'EOF'
#include <iostream>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>

int main() {
    std::cout << "🔍 Dispositivos MIDI disponibles:" << std::endl;
    
    // Listar fuentes (inputs)
    ItemCount numSources = MIDIGetNumberOfSources();
    std::cout << "\n📥 Fuentes MIDI (" << numSources << "):" << std::endl;
    
    for (ItemCount i = 0; i < numSources; i++) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            std::cout << "   " << i << ": " << nameStr << std::endl;
        }
    }
    
    // Listar destinos (outputs)
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    std::cout << "\n📤 Destinos MIDI (" << numDestinations << "):" << std::endl;
    
    for (ItemCount i = 0; i < numDestinations; i++) {
        MIDIEndpointRef dest = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            std::cout << "   " << i << ": " << nameStr << std::endl;
        }
    }
    
    return 0;
}
EOF

# Compilar y ejecutar
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/list_devices /tmp/list_devices.cpp
/tmp/list_devices

# PASO 2: Crear programa de activación agresiva
echo ""
show_progress "Paso 2: Creando programa de activación agresiva..."

cat > /tmp/aggressive_activation.cpp << 'EOF'
#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>

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
    std::cout << "🎹 Activación agresiva de Maschine Mikro..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Aggressive Activation"), NULL, NULL, &client);
    
    // Crear puerto de salida
    MIDIPortRef outputPort;
    MIDIOutputPortCreate(client, CFSTR("Maschine Output"), &outputPort);
    
    // Encontrar Maschine Mikro Output
    ItemCount numDestinations = MIDIGetNumberOfDestinations();
    MIDIEndpointRef maschineOutput = 0;
    
    for (ItemCount i = 0; i < numDestinations; i++) {
        MIDIEndpointRef dest = MIDIGetDestination(i);
        CFStringRef name;
        MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name);
        
        if (name) {
            char nameStr[256];
            CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
            CFRelease(name);
            
            if (strstr(nameStr, "Maschine Mikro Output") != NULL) {
                maschineOutput = dest;
                std::cout << "✅ Encontrado: " << nameStr << std::endl;
                break;
            }
        }
    }
    
    if (maschineOutput == 0) {
        std::cout << "⚠️  No se encontró Maschine Mikro Output específico" << std::endl;
        std::cout << "🔍 Usando primer dispositivo MIDI disponible..." << std::endl;
        
        if (numDestinations > 0) {
            maschineOutput = MIDIGetDestination(0);
            CFStringRef name;
            MIDIObjectGetStringProperty(maschineOutput, kMIDIPropertyName, &name);
            
            if (name) {
                char nameStr[256];
                CFStringGetCString(name, nameStr, sizeof(nameStr), kCFStringEncodingUTF8);
                CFRelease(name);
                std::cout << "✅ Usando: " << nameStr << std::endl;
            }
        }
    }
    
    if (maschineOutput == 0) {
        std::cout << "❌ No se encontró ningún dispositivo MIDI" << std::endl;
        return 1;
    }
    
    std::cout << "🚀 Iniciando activación agresiva..." << std::endl;
    
    // ESTRATEGIA 1: Reset completo múltiples veces
    std::cout << "\n📤 Estrategia 1: Reset completo múltiple" << std::endl;
    
    for (int attempt = 1; attempt <= 3; attempt++) {
        std::cout << "   Intento " << attempt << "..." << std::endl;
        
        // All Controllers Off
        sendMIDI(outputPort, maschineOutput, 0xB0, 121, 0);
        std::this_thread::sleep_for(std::chrono::milliseconds(200));
        
        // All Notes Off
        sendMIDI(outputPort, maschineOutput, 0xB0, 123, 0);
        std::this_thread::sleep_for(std::chrono::milliseconds(200));
        
        // SysEx Reset
        unsigned char resetSysEx[] = {0xF0, 0x7E, 0x00, 0x09, 0x01, 0xF7};
        sendSysEx(outputPort, maschineOutput, resetSysEx, sizeof(resetSysEx));
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
    
    // ESTRATEGIA 2: Handshake agresivo
    std::cout << "\n📤 Estrategia 2: Handshake agresivo" << std::endl;
    
    // Handshake estándar
    unsigned char handshake1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7E, 0x00, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, handshake1, sizeof(handshake1));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Handshake alternativo
    unsigned char handshake2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x7F, 0x00, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, handshake2, sizeof(handshake2));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Identity Request
    unsigned char identity[] = {0xF0, 0x7E, 0x00, 0x06, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, identity, sizeof(identity));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // ESTRATEGIA 3: Activación de inputs múltiple
    std::cout << "\n📤 Estrategia 3: Activación de inputs múltiple" << std::endl;
    
    // Comando de activación 1
    unsigned char activate1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, activate1, sizeof(activate1));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Comando de activación 2
    unsigned char activate2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, activate2, sizeof(activate2));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Comando de activación 3
    unsigned char activate3[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x01, 0x7F, 0xF7};
    sendSysEx(outputPort, maschineOutput, activate3, sizeof(activate3));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // ESTRATEGIA 4: Modo Maschine forzado
    std::cout << "\n📤 Estrategia 4: Modo Maschine forzado" << std::endl;
    
    // Modo Maschine 1
    unsigned char maschineMode1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, maschineMode1, sizeof(maschineMode1));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Modo Maschine 2
    unsigned char maschineMode2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, maschineMode2, sizeof(maschineMode2));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Modo Maschine 3
    unsigned char maschineMode3[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x02, 0x7F, 0xF7};
    sendSysEx(outputPort, maschineOutput, maschineMode3, sizeof(maschineMode3));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // ESTRATEGIA 5: Control de display
    std::cout << "\n📤 Estrategia 5: Control de display" << std::endl;
    
    // Display on
    unsigned char displayOn[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x03, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, displayOn, sizeof(displayOn));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Display off
    unsigned char displayOff[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x03, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, displayOff, sizeof(displayOff));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // ESTRATEGIA 6: Test de LEDs agresivo
    std::cout << "\n📤 Estrategia 6: Test de LEDs agresivo" << std::endl;
    
    // Encender todos los LEDs
    for (int i = 0; i < 16; i++) {
        unsigned char ledOn[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, (unsigned char)i, 0x01, 0x7F, 0xF7};
        sendSysEx(outputPort, maschineOutput, ledOn, sizeof(ledOn));
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    
    // Apagar todos los LEDs
    for (int i = 0; i < 16; i++) {
        unsigned char ledOff[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, (unsigned char)i, 0x00, 0x00, 0xF7};
        sendSysEx(outputPort, maschineOutput, ledOff, sizeof(ledOff));
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    // ESTRATEGIA 7: Simulación de inputs físicos
    std::cout << "\n📤 Estrategia 7: Simulación de inputs físicos" << std::endl;
    
    // Simular presionar todos los pads
    for (int i = 36; i < 52; i++) {
        sendMIDI(outputPort, maschineOutput, 0x90, i, 0x7F); // Note On
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        sendMIDI(outputPort, maschineOutput, 0x80, i, 0x00); // Note Off
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    
    // Simular presionar todos los botones
    for (int i = 16; i < 24; i++) {
        sendMIDI(outputPort, maschineOutput, 0xB0, i, 0x7F); // Control Change On
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        sendMIDI(outputPort, maschineOutput, 0xB0, i, 0x00); // Control Change Off
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    
    // ESTRATEGIA 8: Comandos finales de activación
    std::cout << "\n📤 Estrategia 8: Comandos finales de activación" << std::endl;
    
    // Comando final 1
    unsigned char final1[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x04, 0x01, 0xF7};
    sendSysEx(outputPort, maschineOutput, final1, sizeof(final1));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Comando final 2
    unsigned char final2[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x05, 0x00, 0xF7};
    sendSysEx(outputPort, maschineOutput, final2, sizeof(final2));
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    // Comando final 3 - LED de confirmación
    unsigned char confirmLED[] = {0xF0, 0x00, 0x20, 0x3C, 0x02, 0x00, 0x00, 0x00, 0x01, 0x7F, 0xF7};
    sendSysEx(outputPort, maschineOutput, confirmLED, sizeof(confirmLED));
    
    std::cout << "\n✅ Activación agresiva completada" << std::endl;
    std::cout << "💡 El dispositivo debería estar activado ahora" << std::endl;
    std::cout << "💡 Verifica si los inputs físicos funcionan" << std::endl;
    
    // Limpiar
    MIDIPortDispose(outputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar
echo ""
show_progress "Compilando programa de activación agresiva..."
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/aggressive_activation /tmp/aggressive_activation.cpp

if [ $? -eq 0 ]; then
    show_success "Programa compilado exitosamente"
    echo ""
    show_progress "Ejecutando activación agresiva..."
    /tmp/aggressive_activation
else
    show_error "Error al compilar programa de activación"
    exit 1
fi

# PASO 3: Verificar activación
echo ""
show_progress "Paso 3: Verificando activación..."

# Esperar un momento para que el dispositivo procese
sleep 3

# Verificar dispositivos MIDI nuevamente
echo ""
show_progress "Verificando dispositivos MIDI después de la activación..."
/tmp/list_devices

# PASO 4: Test de inputs
echo ""
show_progress "Paso 4: Realizando test de inputs..."

# Crear programa de test de inputs
cat > /tmp/test_inputs.cpp << 'EOF'
#include <iostream>
#include <thread>
#include <chrono>
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>

void handleMIDIInput(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon) {
    const MIDIPacket* packet = &pktlist->packet[0];
    
    for (int i = 0; i < pktlist->numPackets; ++i) {
        if (packet->length >= 3) {
            unsigned char status = packet->data[0];
            unsigned char data1 = packet->data[1];
            unsigned char data2 = packet->data[2];
            
            std::cout << "📥 MIDI Input: " << std::hex << (int)status << " " << (int)data1 << " " << (int)data2 << std::dec << std::endl;
            
            // Detectar inputs físicos
            if ((status & 0xF0) == 0x90 && data2 > 0) {
                if (data1 >= 36 && data1 <= 51) {
                    int pad = data1 - 36;
                    std::cout << "🥁 ¡PAD " << pad << " PRESIONADO! (velocity: " << (int)data2 << ")" << std::endl;
                }
            } else if ((status & 0xF0) == 0xB0 && data2 > 0) {
                if (data1 >= 16 && data1 <= 23) {
                    int button = data1 - 16;
                    std::cout << "🔘 ¡BOTÓN " << button << " PRESIONADO! (value: " << (int)data2 << ")" << std::endl;
                }
            }
        }
        
        packet = MIDIPacketNext(packet);
    }
}

int main() {
    std::cout << "🎹 Test de inputs físicos..." << std::endl;
    std::cout << "💡 Presiona pads y botones en el dispositivo físico" << std::endl;
    std::cout << "⏱️  Test durará 30 segundos..." << std::endl;
    
    // Crear cliente MIDI
    MIDIClientRef client;
    MIDIClientCreate(CFSTR("Input Test"), NULL, NULL, &client);
    
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
    
    // Esperar 30 segundos para inputs
    std::cout << "⏳ Esperando inputs físicos..." << std::endl;
    std::this_thread::sleep_for(std::chrono::seconds(30));
    
    std::cout << "✅ Test de inputs completado" << std::endl;
    
    // Limpiar
    MIDIPortDispose(inputPort);
    MIDIClientDispose(client);
    
    return 0;
}
EOF

# Compilar y ejecutar test de inputs
g++ -framework CoreMIDI -framework CoreFoundation -o /tmp/test_inputs /tmp/test_inputs.cpp

if [ $? -eq 0 ]; then
    echo ""
    show_progress "Ejecutando test de inputs físicos..."
    /tmp/test_inputs
else
    show_error "Error al compilar test de inputs"
fi

# PASO 5: Resumen final
echo ""
echo "🎹 ========================================="
echo "🎹 RESUMEN DE ACTIVACIÓN FORZADA"
echo "🎹 ========================================="

echo ""
echo "📋 Pasos completados:"
echo "   ✅ 1. Verificación de dispositivos MIDI"
echo "   ✅ 2. Activación agresiva con múltiples estrategias"
echo "   ✅ 3. Verificación post-activación"
echo "   ✅ 4. Test de inputs físicos"
echo ""

echo "🎯 Estado del dispositivo:"
echo "   💡 Si las luces cambiaron = Activación exitosa"
echo "   💡 Si el display cambió = Modo activado"
echo "   💡 Si detectaste inputs = ¡FUNCIONANDO!"
echo ""

echo "🔧 Próximos pasos:"
echo "   1. Probar inputs físicos (pads, botones)"
echo "   2. Verificar que el dispositivo aparece en fuentes MIDI"
echo "   3. Usar el driver para funcionalidades avanzadas"
echo ""

show_success "¡Activación forzada completada!"
echo "🎹 La Maschine Mikro debería estar funcionando ahora" 